// padhub: plug-and-play controllers for player 1, no launcher setup needed.
//
// The stock engine opens one DirectInput device per local player at startup (the one whose
// instance GUID the launcher saved as pad0/pad1) and never looks for devices again, so a pad
// plugged in later, or any pad other than the saved one, does nothing. padhub replaces the
// engine's per-frame pad read (0x5F2E00) for player 1 with a merged state built from every
// connected controller:
//   - XInput pads (Xbox 360/One/Series, and anything Steam Input or DS4Windows presents as one)
//   - every other DirectInput game controller (PlayStation, Switch Pro, 8BitDo, generic USB...),
//     translated to a standard Xbox-style layout. The mapping comes from gamecontrollerdb.txt next
//     to THUGPro.exe when that file has a line for the pad (SDL format, optional), else from the
//     built-in table below, else from a generic guess.
//   - Switch Pro Controllers, read directly (Nintendo handshake, so USB works too; calibrated
//     full-resolution sticks). See the Switch Pro section.
// Controllers are picked up and dropped while the game runs. The state the engine sees always has
// the Xbox 360 DirectInput layout (A B X Y LB RB Back Start LS RS = buttons 1-10, LT = 11, RT = 12,
// Guide = 13, triggers also on the Z axis, D-pad on POV 1), and player 1's pad bindings are set to
// the launcher's Xbox preset for that layout (LT/RT on buttons 11/12).
//
// padhub.ini next to THUGPro.exe (optional):
//   [padhub]
//   enabled=0                  turn padhub off (stock behaviour)
//   use_launcher_bindings=1    keep player 1's pad bindings from the launcher instead of the preset
// Connects and disconnects are written to padhub.log next to THUGPro.exe.
#define DIRECTINPUT_VERSION 0x0800
#include <dinput.h>
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#pragma comment(lib, "dinput8.lib")
#pragma comment(lib, "dxguid.lib")
#include <ctype.h>
#include <setupapi.h>
extern "C" {
#include <hidsdi.h>
}
#pragma comment(lib, "setupapi.lib")
#pragma comment(lib, "hid.lib")

namespace padhub {

static_assert(sizeof(DIJOYSTATE2) == 0x110, "engine pad state size");

// ---- engine addresses (THUGPro.exe 2004-09-14 build, no ASLR)
static const DWORD kPadStateFn = 0x5F2E00;  // DIJOYSTATE2* __cdecl GetPadState(int slot)
static const DWORD kCallDI8    = 0x5F45AF;  // call DirectInput8Create thunk, right after the registry read
static const DWORD kDI8Thunk   = 0x5F8130;
static const DWORD kPadDevices = 0x7D6318;  // IDirectInputDevice8A*[2]
static const DWORD kPadCur     = 0x7D60F8;  // DIJOYSTATE2[2], this frame
static const DWORD kPadPrev    = 0x7D6448;  // DIJOYSTATE2[2], last frame
static const DWORD kPad0Guid   = 0x7D67D0;  // pad0 instance GUID read from the registry
static const DWORD kPad0Binds  = 0x7D67E0;  // gp0_0..gp0_23
static const int   kStateSize  = 0x110;     // sizeof(DIJOYSTATE2)
static const DWORD kPad1Guid   = 0x7D6900;  // pad1 instance GUID (player 2 keeps that device)

// Launcher "XBOX" preset, with LT/RT on buttons 11/12 instead of the XInput-only codes 90/91.
static const int kPreset[24] = { 2, 2, 1, 1, 7, 7, 6, 6, 11, 12, 13, 14, 18, 17, 15, 16, 21, 22, 19, 20, 5, 5, 4, 4 };

enum { B_A, B_B, B_X, B_Y, B_LB, B_RB, B_BACK, B_START, B_LS, B_RS, B_LT, B_RT, B_GUIDE,
       B_UP, B_DOWN, B_LEFT, B_RIGHT, B_COUNT };
enum { A_LX, A_LY, A_RX, A_RY, A_LT, A_RT, A_COUNT };
static const char* kButtonNames[B_COUNT] = { "a", "b", "x", "y", "leftshoulder", "rightshoulder", "back",
    "start", "leftstick", "rightstick", "lefttrigger", "righttrigger", "guide", "dpup", "dpdown", "dpleft", "dpright" };
static const char* kAxisNames[A_COUNT] = { "leftx", "lefty", "rightx", "righty", "lefttrigger", "righttrigger" };

struct PadOut { float axis[A_COUNT]; DWORD buttons; };

// One mapping input: button n, axis n (whole, or one half: half = +1/-1, optionally inverted)
// or a direction of hat n (hatMask 1 up, 2 right, 4 down, 8 left).
struct Src { char kind, idx, half, invert; BYTE hatMask; };  // kind 0 = none, 'b', 'a', 'h'
struct Mapping { Src button[B_COUNT]; Src axis[A_COUNT]; };

struct DiPad {
    IDirectInputDevice8A* dev;
    GUID instance;
    WORD vid, pid;
    int axisOfs[8], numAxes;  // DIJOYSTATE2 offsets of the axes the pad has, in offset order
    int numButtons, numHats;
    Mapping map;
    char name[64];
    int fails;
    volatile LONG dead;
    DWORD since;     // when it was found
    bool announced;  // its connect popup was shown (only then does it get a disconnect popup)
    bool checked;    // the connect popup was decided
    DWORD seenPass;  // last worker scan that DirectInput still listed it (reconnect fix 2026-11-19)
    const char* why; // why it was dropped (for the log)
};

struct XState { DWORD packet; WORD buttons; BYTE lt, rt; SHORT lx, ly, rx, ry; };
typedef DWORD (WINAPI* XGetStateFn)(DWORD, XState*);

static bool g_enabled = true, g_launcherBinds = false;
static volatile LONG g_started = 0;
static char g_dir[MAX_PATH];
static CRITICAL_SECTION g_lock;
static DiPad* g_pads[8];
static int g_numPads;
static GUID g_skip[16];  // XInput pads as DirectInput sees them (read through XInput instead)
static DWORD g_skipSeen[16];  // last scan that listed each g_skip entry (unlisted ones are forgotten)
static int g_numSkip;
static DWORD g_pass = 1;  // worker scan counter
// Reconnect fix (Noah 2026-11-19, "sometimes when my controller disconnects i can't reconnect", DS4 + DS4Windows +
// HidHide): a DirectInput pad was only dropped after 3 failed reads. A raw pad that HidHide hides again, or a Bluetooth
// pad that drops, can keep answering with frozen data and no error, and its GUID then stopped it from ever being opened
// again. Now a pad DirectInput no longer lists for kGoneScans scans in a row is dropped and opened fresh when it returns.
static const DWORD kGoneScans = 2;
static XGetStateFn g_xget;
static volatile LONG g_xconn[4];  // XInput slot connected
static volatile LONG g_xlost[4];  // game thread saw the slot drop (logged by the worker)
static char* g_db;                // gamecontrollerdb.txt contents, or null
static volatile LONG g_padButtons;
static volatile LONG g_padActive;   // a pad button is down or a stick/trigger is pushed past 60% (button prompts)  // merged buttons last frame (Xbox layout bits), for THUGRECOMP_PadPressed
// Dadmod > Controls (gfx.ini, kept in step by gfx.inc SyncInput, Noah 2026-11-16)
static volatile LONG g_deadzone;  // Stick dead zone: 0 off, 1..10 = 3%..30% radial dead zone on both sticks
static volatile LONG g_abSwap;    // Swap A/B and X/Y (Nintendo-style labels)
static volatile LONG g_padPopup = 1;  // Controller popups: on-screen note when a pad is plugged in or unplugged
static char* volatile g_popupMsg;     // worker -> game thread hand-off (latest message wins)
static volatile DWORD g_workerStart;  // pads found in the first seconds are the startup scan: no popup
static bool g_xseen;  // an XInput pad was connected at some point
static void Popup(const char* verb, const char* name) {
    if (!g_padPopup || GetTickCount() - g_workerStart < 8000) return;
    char buf[128];
    _snprintf(buf, sizeof buf, "Controller %s", verb); (void)name;  // short line, top right (Noah 2026-11-16) buf[sizeof buf - 1] = 0;
    char* old = (char*)InterlockedExchangePointer((PVOID volatile*)&g_popupMsg, _strdup(buf));
    free(old);
}
// Game thread (PadStateHook): runs dadmod_pad_popup, which spawns the stock panel message.
static void ShowPopup() {
    if (!g_popupMsg) return;
    char* m = (char*)InterlockedExchangePointer((PVOID volatile*)&g_popupMsg, nullptr);
    if (!m) return;
    BYTE st[16] = {0};
    typedef void (__thiscall* CtorFn)(void*);
    typedef void (__thiscall* AddStrFn)(void*, DWORD, int, const char*);
    typedef int (__cdecl* RunFn)(DWORD, void*, int, int, int);
    ((CtorFn)0x476410)(st);                                   // CStruct::CStruct
    ((AddStrFn)0x478390)(st, QbKey("text"), 3, m);           // CStruct::AddString
    ((RunFn)0x475790)(QbKey("dadmod_pad_popup"), st, 0, 0, 0); // RunScript
    ((CtorFn)0x477130)(st);                                   // CStruct::~CStruct
    free(m);
}

static void Log(const char* fmt, ...) {
    char path[MAX_PATH + 16], line[512];
    _snprintf(path, sizeof path, "%spadhub.log", g_dir); path[sizeof path - 1] = 0;
    SYSTEMTIME t; GetLocalTime(&t);
    int n = _snprintf(line, sizeof line, "%04d-%02d-%02d %02d:%02d:%02d ", t.wYear, t.wMonth, t.wDay, t.wHour, t.wMinute, t.wSecond);
    va_list ap; va_start(ap, fmt);
    _vsnprintf(line + n, sizeof line - n - 3, fmt, ap);
    va_end(ap);
    line[sizeof line - 3] = 0;
    strcat(line, "\r\n");
    HANDLE f = CreateFileA(path, FILE_APPEND_DATA, FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr, OPEN_ALWAYS, 0, nullptr);
    if (f == INVALID_HANDLE_VALUE) return;
    DWORD w; WriteFile(f, line, (DWORD)strlen(line), &w, nullptr);
    CloseHandle(f);
}

// ---- mappings (SDL gamecontrollerdb syntax; aN = Nth axis the pad has, in DIJOYSTATE order)

static void ParseSrc(const char* s, Src* out) {
    memset(out, 0, sizeof *out);
    if (*s == '+') { out->half = 1; ++s; } else if (*s == '-') { out->half = -1; ++s; }
    if (*s == 'b') { out->kind = 'b'; out->idx = (char)atoi(s + 1); }
    else if (*s == 'a') { out->kind = 'a'; out->idx = (char)atoi(s + 1); out->invert = strchr(s, '~') != nullptr; }
    else if (*s == 'h') { const char* dot = strchr(s, '.'); if (dot) { out->kind = 'h'; out->idx = (char)atoi(s + 1); out->hatMask = (BYTE)atoi(dot + 1); } }
}

// Fills `m` from the "key:value,..." part of an SDL mapping line.
static void ParseMapping(const char* fields, Mapping* m) {
    memset(m, 0, sizeof *m);
    const char* p = fields;
    while (*p && *p != '\r' && *p != '\n') {
        const char* end = p;
        while (*end && *end != ',' && *end != '\r' && *end != '\n') ++end;
        char item[64]; size_t len = end - p < 63 ? end - p : 63;
        memcpy(item, p, len); item[len] = 0;
        char* colon = strchr(item, ':');
        if (colon) {
            *colon = 0;
            const char* key = item;
            for (int i = 0; i < B_COUNT; ++i)
                if (!strcmp(key, kButtonNames[i])) ParseSrc(colon + 1, &m->button[i]);
            for (int i = 0; i < A_COUNT; ++i)
                if (!strcmp(key, kAxisNames[i])) ParseSrc(colon + 1, &m->axis[i]);
        }
        p = *end == ',' ? end + 1 : end;
    }
    // Triggers are read as axes; a trigger mapped to a button counts as fully pressed.
    for (int i = 0; i < 2; ++i)
        if (m->axis[A_LT + i].kind == 'b' || m->axis[A_LT + i].kind == 'h') m->button[B_LT + i] = m->axis[A_LT + i];
}

static int HexByte(const char* s) {
    int v = 0;
    for (int i = 0; i < 2; ++i) {
        char c = s[i]; v <<= 4;
        if (c >= '0' && c <= '9') v |= c - '0';
        else if (c >= 'a' && c <= 'f') v |= c - 'a' + 10;
        else if (c >= 'A' && c <= 'F') v |= c - 'A' + 10;
        else return -1;
    }
    return v;
}

// Vendor/product from an SDL joystick GUID (32 hex digits), both the current
// bus/crc/vendor/product layout and the old DirectInput "...PIDVID" one.
static bool GuidVidPid(const char* g, WORD* vid, WORD* pid) {
    BYTE b[16];
    for (int i = 0; i < 16; ++i) { int v = HexByte(g + i * 2); if (v < 0) return false; b[i] = (BYTE)v; }
    if (!memcmp(b + 10, "PIDVID", 6)) { *vid = (WORD)(b[0] | b[1] << 8); *pid = (WORD)(b[2] | b[3] << 8); return true; }
    if (b[6] == 0 && b[7] == 0 && b[10] == 0 && b[11] == 0) { *vid = (WORD)(b[4] | b[5] << 8); *pid = (WORD)(b[8] | b[9] << 8); return true; }
    return false;
}

struct BuiltIn { WORD vid, pid; const char* name; const char* map; };
static const char kSony[] = "a:b1,b:b2,x:b0,y:b3,back:b8,start:b9,guide:b12,leftshoulder:b4,rightshoulder:b5,"
    "leftstick:b10,rightstick:b11,leftx:a0,lefty:a1,rightx:a2,righty:a5,lefttrigger:a3,righttrigger:a4,"
    "dpup:h0.1,dpright:h0.2,dpdown:h0.4,dpleft:h0.8";
static const char kSwitchPro[] = "a:b0,b:b1,x:b2,y:b3,back:b8,start:b9,guide:b12,leftshoulder:b4,rightshoulder:b5,"
    "leftstick:b10,rightstick:b11,leftx:a0,lefty:a1,rightx:a2,righty:a3,lefttrigger:b6,righttrigger:b7,"
    "dpup:h0.1,dpright:h0.2,dpdown:h0.4,dpleft:h0.8";
static const char kLogitech[] = "a:b1,b:b2,x:b0,y:b3,back:b8,start:b9,leftshoulder:b4,rightshoulder:b5,"
    "leftstick:b10,rightstick:b11,leftx:a0,lefty:a1,rightx:a2,righty:a3,lefttrigger:b6,righttrigger:b7,"
    "dpup:h0.1,dpright:h0.2,dpdown:h0.4,dpleft:h0.8";
static const BuiltIn kBuiltIn[] = {
    { 0x054C, 0x05C4, "DualShock 4", kSony }, { 0x054C, 0x09CC, "DualShock 4", kSony },
    { 0x054C, 0x0BA0, "DualShock 4 adapter", kSony }, { 0x054C, 0x0CE6, "DualSense", kSony },
    { 0x054C, 0x0DF2, "DualSense Edge", kSony },
    { 0x057E, 0x2009, "Switch Pro Controller", kSwitchPro },
    { 0x046D, 0xC216, "Logitech Dual Action / F310 (D)", kLogitech }, { 0x046D, 0xC218, "Logitech RumblePad 2", kLogitech },
    { 0x046D, 0xC219, "Logitech F710 (D)", kLogitech },
};

static int AxisIndexOf(const DiPad* p, int ofs) {
    for (int i = 0; i < p->numAxes; ++i) if (p->axisOfs[i] == ofs) return i;
    return -1;
}

// Most DirectInput pads put the face buttons in PlayStation order (left, bottom, right, top),
// then L1 R1 L2 R2 Select Start L3 R3, the left stick on X/Y and the right stick on Z/Rz or Rx/Ry.
static void GenericMapping(const DiPad* p, Mapping* m) {
    char s[512];
    strcpy(s, "x:b0,a:b1,b:b2,y:b3,leftshoulder:b4,rightshoulder:b5,lefttrigger:b6,righttrigger:b7,"
              "back:b8,start:b9,leftstick:b10,rightstick:b11,guide:b12,dpup:h0.1,dpright:h0.2,dpdown:h0.4,dpleft:h0.8");
    char extra[96];
    int x = AxisIndexOf(p, DIJOFS_X), y = AxisIndexOf(p, DIJOFS_Y);
    int z = AxisIndexOf(p, DIJOFS_Z), rx = AxisIndexOf(p, DIJOFS_RX), ry = AxisIndexOf(p, DIJOFS_RY), rz = AxisIndexOf(p, DIJOFS_RZ);
    if (x >= 0 && y >= 0) { _snprintf(extra, sizeof extra, ",leftx:a%d,lefty:a%d", x, y); strcat(s, extra); }
    if (z >= 0 && rz >= 0) {
        _snprintf(extra, sizeof extra, ",rightx:a%d,righty:a%d", z, rz); strcat(s, extra);
        if (rx >= 0 && ry >= 0) { _snprintf(extra, sizeof extra, ",lefttrigger:a%d,righttrigger:a%d", rx, ry); strcat(s, extra); }
    } else if (rx >= 0 && ry >= 0) {
        _snprintf(extra, sizeof extra, ",rightx:a%d,righty:a%d", rx, ry); strcat(s, extra);
    } else if (z >= 0 && rx >= 0) {
        _snprintf(extra, sizeof extra, ",rightx:a%d,righty:a%d", z, rx); strcat(s, extra);
    }
    ParseMapping(s, m);
}

// Picks the mapping for a pad; returns where it came from (for the log).
static const char* ChooseMapping(DiPad* p) {
    if (g_db) {
        const char* line = g_db;
        while (*line) {
            const char* next = line;
            while (*next && *next != '\n') ++next;
            WORD vid, pid;
            if (*line != '#' && next - line > 40 && line[32] == ',' && GuidVidPid(line, &vid, &pid)
                && vid == p->vid && pid == p->pid) {
                // Only Windows lines (the same pad maps differently on other platforms).
                const char* plat = strstr(line, "platform:");
                if (plat && plat < next && !strncmp(plat + 9, "Windows", 7)) {
                    const char* fields = strchr(line + 33, ',');
                    if (fields && fields < next) { ParseMapping(fields + 1, &p->map); return "gamecontrollerdb.txt"; }
                }
            }
            line = *next ? next + 1 : next;
        }
    }
    for (int i = 0; i < (int)(sizeof kBuiltIn / sizeof kBuiltIn[0]); ++i)
        if (kBuiltIn[i].vid == p->vid && kBuiltIn[i].pid == p->pid) { ParseMapping(kBuiltIn[i].map, &p->map); return kBuiltIn[i].name; }
    GenericMapping(p, &p->map);
    return "generic layout";
}

// ---- reading pads

static float ReadSrc(const Src& s, const DIJOYSTATE2& st, const DiPad* p) {
    switch (s.kind) {
    case 'b':
        return s.idx >= 0 && s.idx < 128 && (st.rgbButtons[(int)s.idx] & 0x80) ? 1.0f : 0.0f;
    case 'a': {
        if (s.idx < 0 || s.idx >= p->numAxes) return 0.0f;
        LONG raw = *(const LONG*)((const BYTE*)&st + p->axisOfs[(int)s.idx]);
        float v = raw >= 0 ? raw / 32767.0f : raw / 32768.0f;
        if (s.invert) v = -v;
        if (s.half > 0) return v > 0 ? v : 0.0f;
        if (s.half < 0) return v < 0 ? -v : 0.0f;
        return v;
    }
    case 'h': {
        if (s.idx < 0 || s.idx > 3) return 0.0f;
        DWORD pov = st.rgdwPOV[(int)s.idx];
        if (LOWORD(pov) == 0xFFFF) return 0.0f;
        BYTE dirs = 0;
        if (pov >= 29250 || pov <= 6750) dirs |= 1;
        if (pov >= 2250 && pov <= 15750) dirs |= 2;
        if (pov >= 11250 && pov <= 24750) dirs |= 4;
        if (pov >= 20250 && pov <= 33750) dirs |= 8;
        return dirs & s.hatMask ? 1.0f : 0.0f;
    }
    }
    return 0.0f;
}

static void ReadDiPad(const DiPad* p, const DIJOYSTATE2& st, PadOut* out) {
    memset(out, 0, sizeof *out);
    for (int i = 0; i < B_COUNT; ++i)
        if (p->map.button[i].kind && ReadSrc(p->map.button[i], st, p) > 0.5f) out->buttons |= 1u << i;
    for (int i = 0; i < A_COUNT; ++i) {
        const Src& s = p->map.axis[i];
        float v = ReadSrc(s, st, p);
        // A trigger on a whole axis rests at one end: -1..1 -> 0..1.
        if (i >= A_LT && s.kind == 'a' && !s.half) v = (v + 1.0f) * 0.5f;
        out->axis[i] = v;
    }
    if (out->axis[A_LT] > 0.3f) out->buttons |= 1u << B_LT;
    if (out->axis[A_RT] > 0.3f) out->buttons |= 1u << B_RT;
    if (out->buttons & (1u << B_LT) && out->axis[A_LT] < 0.3f) out->axis[A_LT] = 1.0f;
    if (out->buttons & (1u << B_RT) && out->axis[A_RT] < 0.3f) out->axis[A_RT] = 1.0f;
}

static void ReadXPad(const XState& x, PadOut* out) {
    static const WORD kBits[B_COUNT] = { 0x1000, 0x2000, 0x4000, 0x8000, 0x0100, 0x0200, 0x0020, 0x0010,
        0x0040, 0x0080, 0, 0, 0x0400, 0x0001, 0x0002, 0x0004, 0x0008 };
    memset(out, 0, sizeof *out);
    for (int i = 0; i < B_COUNT; ++i) if (kBits[i] && (x.buttons & kBits[i])) out->buttons |= 1u << i;
    out->axis[A_LX] = x.lx / 32767.0f;
    out->axis[A_LY] = -(x.ly / 32767.0f);  // XInput up is positive, DirectInput down is
    out->axis[A_RX] = x.rx / 32767.0f;
    out->axis[A_RY] = -(x.ry / 32767.0f);
    out->axis[A_LT] = x.lt / 255.0f;
    out->axis[A_RT] = x.rt / 255.0f;
    if (x.lt > 77) out->buttons |= 1u << B_LT;
    if (x.rt > 77) out->buttons |= 1u << B_RT;
}

static float Clamp1(float v) { return v > 1.0f ? 1.0f : v < -1.0f ? -1.0f : v; }

// Merges pads: buttons are OR'd, each stick comes from whichever pad pushes it furthest
// (ignoring rest drift), triggers take the highest value.
static void Merge(PadOut* acc, const PadOut& p) {
    acc->buttons |= p.buttons;
    for (int s = 0; s < 2; ++s) {
        float px = p.axis[s * 2], py = p.axis[s * 2 + 1];
        float ax = acc->axis[s * 2], ay = acc->axis[s * 2 + 1];
        float pm = px * px + py * py;
        if (pm > 0.15f * 0.15f && pm > ax * ax + ay * ay) { acc->axis[s * 2] = px; acc->axis[s * 2 + 1] = py; }
    }
    for (int i = A_LT; i <= A_RT; ++i) if (p.axis[i] > acc->axis[i]) acc->axis[i] = p.axis[i];
}

// ---- Nintendo Switch Pro Controller (and pads that copy its USB IDs), read directly over HID
//
// Windows' own driver only shows a Pro Controller in its basic Bluetooth mode (coarse sticks) and,
// over USB, not at all until a program sends Nintendo's handshake. So padhub opens it itself: the
// USB handshake when wired, then full input-report mode (0x30: 12-bit sticks at 60-120 Hz) with the
// stick calibration read from the controller's flash. While padhub drives a Pro Controller, the
// DirectInput view of it is ignored.

static const WORD kNintendoVid = 0x057E, kSwitchProPid = 0x2009;

struct SwitchPad {
    char path[512];
    volatile LONG active;     // reader thread running
    volatile LONG connected;  // handshake done, reports arriving
    HANDLE dev;
    int outLen, inLen;
    BYTE counter;
    bool usb;
    int cal[2][6];            // per stick: x center, y center, x above, y above, x below, y below
    CRITICAL_SECTION lock;
    PadOut out;
    DWORD lastTick;
};
static SwitchPad g_switch[4];
static volatile LONG g_switchActive;  // Pro Controllers currently driven
static char g_switchFailed[4][512];   // paths that did not answer the handshake (left to DirectInput)
static int g_numSwitchFailed;

static bool HidIo(SwitchPad* s, bool write, BYTE* buf, int len, DWORD timeoutMs) {
    OVERLAPPED ov; memset(&ov, 0, sizeof ov);
    ov.hEvent = CreateEventA(nullptr, TRUE, FALSE, nullptr);
    DWORD n = 0;
    BOOL ok = write ? WriteFile(s->dev, buf, len, &n, &ov) : ReadFile(s->dev, buf, len, &n, &ov);
    if (!ok && GetLastError() == ERROR_IO_PENDING) {
        if (WaitForSingleObject(ov.hEvent, timeoutMs) != WAIT_OBJECT_0) { CancelIo(s->dev); WaitForSingleObject(ov.hEvent, 100); CloseHandle(ov.hEvent); return false; }
        ok = GetOverlappedResult(s->dev, &ov, &n, FALSE);
    }
    CloseHandle(ov.hEvent);
    return ok && n > 0;
}

// Reads until a report starting with `id` (and, if sub >= 0, carrying that subcommand reply) arrives.
static bool WaitReport(SwitchPad* s, BYTE id, int sub, BYTE* buf, DWORD timeoutMs) {
    DWORD end = GetTickCount() + timeoutMs;
    while ((int)(end - GetTickCount()) > 0) {
        memset(buf, 0, s->inLen);
        if (!HidIo(s, false, buf, s->inLen, end - GetTickCount())) continue;
        if (buf[0] != id) continue;
        if (sub < 0 || buf[14] == (BYTE)sub) return true;
    }
    return false;
}

static bool UsbCommand(SwitchPad* s, BYTE cmd, bool waitReply) {
    BYTE out[512] = { 0x80, cmd }, in[512];
    if (!HidIo(s, true, out, s->outLen, 200)) return false;
    return !waitReply || WaitReport(s, 0x81, -1, in, 300);
}

static bool Subcommand(SwitchPad* s, BYTE id, const BYTE* args, int argLen, BYTE* reply) {
    static const BYTE kNeutralRumble[8] = { 0x00, 0x01, 0x40, 0x40, 0x00, 0x01, 0x40, 0x40 };
    for (int attempt = 0; attempt < 3; ++attempt) {
        BYTE out[512]; memset(out, 0, sizeof out);
        out[0] = 0x01; out[1] = (BYTE)(s->counter++ & 0x0F);
        memcpy(out + 2, kNeutralRumble, 8);
        out[10] = id;
        if (argLen) memcpy(out + 11, args, argLen);
        if (!HidIo(s, true, out, s->outLen, 200)) continue;
        if (WaitReport(s, 0x21, id, reply, 400)) return true;
    }
    return false;
}

// Factory stick calibration from SPI flash (0x603D left, 0x6046 right; the two are laid out differently).
static void ReadCalibration(SwitchPad* s) {
    for (int st = 0; st < 2; ++st) {
        int* c = s->cal[st];
        c[0] = c[1] = 2048; c[2] = c[3] = c[4] = c[5] = 1400;  // typical values if the read fails
        BYTE args[5] = { (BYTE)(st ? 0x46 : 0x3D), 0x60, 0, 0, 9 }, r[512];
        if (!Subcommand(s, 0x10, args, 5, r)) continue;
        const BYTE* d = r + 20;
        int v[6];
        for (int i = 0; i < 3; ++i) {
            v[i * 2] = ((d[i * 3 + 1] << 8) & 0xF00) | d[i * 3];
            v[i * 2 + 1] = (d[i * 3 + 2] << 4) | (d[i * 3 + 1] >> 4);
        }
        bool blank = true;
        for (int i = 0; i < 9; ++i) if (d[i] != 0xFF) blank = false;
        if (blank) continue;
        if (st == 0) { c[2] = v[0]; c[3] = v[1]; c[0] = v[2]; c[1] = v[3]; c[4] = v[4]; c[5] = v[5]; }  // above, center, below
        else         { c[0] = v[0]; c[1] = v[1]; c[4] = v[2]; c[5] = v[3]; c[2] = v[4]; c[3] = v[5]; }  // center, below, above
        for (int i = 2; i < 6; ++i) if (c[i] < 400) c[i] = 1400;
    }
}

static float StickAxis(int raw, int center, int above, int below) {
    float v = raw >= center ? (raw - center) / (float)above : (raw - center) / (float)below;
    return Clamp1(v);
}

static void ParseFullReport(SwitchPad* s, const BYTE* r, PadOut* o) {
    memset(o, 0, sizeof *o);
    struct { BYTE byte, mask; int button; } const kMap[] = {
        // By position: Switch B (bottom) = Xbox A, A (right) = B, Y (left) = X, X (top) = Y.
        { 3, 0x04, B_A }, { 3, 0x08, B_B }, { 3, 0x01, B_X }, { 3, 0x02, B_Y },
        { 5, 0x40, B_LB }, { 3, 0x40, B_RB }, { 5, 0x80, B_LT }, { 3, 0x80, B_RT },
        { 4, 0x01, B_BACK }, { 4, 0x02, B_START }, { 4, 0x08, B_LS }, { 4, 0x04, B_RS }, { 4, 0x10, B_GUIDE },
        { 5, 0x02, B_UP }, { 5, 0x01, B_DOWN }, { 5, 0x08, B_LEFT }, { 5, 0x04, B_RIGHT },
    };
    for (int i = 0; i < (int)(sizeof kMap / sizeof kMap[0]); ++i)
        if (r[kMap[i].byte] & kMap[i].mask) o->buttons |= 1u << kMap[i].button;
    for (int st = 0; st < 2; ++st) {
        const BYTE* d = r + 6 + st * 3;
        int x = d[0] | ((d[1] & 0x0F) << 8), y = (d[1] >> 4) | (d[2] << 4);
        const int* c = s->cal[st];
        o->axis[st * 2] = StickAxis(x, c[0], c[2], c[4]);
        o->axis[st * 2 + 1] = -StickAxis(y, c[1], c[3], c[5]);  // Switch up is positive, DirectInput down is
    }
    o->axis[A_LT] = (o->buttons >> B_LT) & 1 ? 1.0f : 0.0f;
    o->axis[A_RT] = (o->buttons >> B_RT) & 1 ? 1.0f : 0.0f;
}

static void DropDirectInputCopies() {
    EnterCriticalSection(&g_lock);
    for (int i = 0; i < g_numPads; ++i)
        if (g_pads[i]->vid == kNintendoVid && g_pads[i]->pid == kSwitchProPid) InterlockedExchange(&g_pads[i]->dead, 1);
    LeaveCriticalSection(&g_lock);
}

static DWORD WINAPI SwitchReader(LPVOID arg) {
    SwitchPad* s = (SwitchPad*)arg;
    BYTE buf[512];
    // Wired pads answer the 0x80 status command; Bluetooth ones ignore it.
    s->usb = UsbCommand(s, 0x01, true);
    if (s->usb) {
        UsbCommand(s, 0x02, true);   // handshake
        UsbCommand(s, 0x03, true);   // 3 Mbit
        UsbCommand(s, 0x02, true);   // handshake again at the new speed
        UsbCommand(s, 0x04, false);  // HID only from now on, no timeout
    }
    ReadCalibration(s);
    BYTE mode = 0x30, light = 0x01;
    bool ok = Subcommand(s, 0x03, &mode, 1, buf);  // full input reports
    if (ok) {
        Subcommand(s, 0x30, &light, 1, buf);  // player 1 light
        InterlockedExchange(&s->connected, 1);
        InterlockedIncrement(&g_switchActive);
        DropDirectInputCopies();
        Log("connected: Switch Pro Controller (%s, native, stick centres %d/%d %d/%d)",
            s->usb ? "USB" : "Bluetooth", s->cal[0][0], s->cal[0][1], s->cal[1][0], s->cal[1][1]);
        Popup("connected", "Switch Pro Controller");
        int misses = 0;
        while (misses < 20) {  // ~2 s without a report: unplugged or switched off
            memset(buf, 0, s->inLen);
            if (!HidIo(s, false, buf, s->inLen, 100)) { ++misses; continue; }
            if (buf[0] != 0x30) continue;
            misses = 0;
            PadOut o; ParseFullReport(s, buf, &o);
            EnterCriticalSection(&s->lock);
            s->out = o; s->lastTick = GetTickCount();
            LeaveCriticalSection(&s->lock);
        }
        InterlockedExchange(&s->connected, 0);
        InterlockedDecrement(&g_switchActive);
        Log("disconnected: Switch Pro Controller");
        Popup("disconnected", "Switch Pro Controller");
    } else {
        Log("Switch Pro Controller found but did not answer the handshake; using DirectInput for it");
        if (g_numSwitchFailed < 4) strcpy(g_switchFailed[g_numSwitchFailed++], s->path);
    }
    CloseHandle(s->dev); s->dev = nullptr;
    InterlockedExchange(&s->active, 0);
    return 0;
}

// Worker thread, every pass: opens Pro Controllers nobody is reading yet.
static void SwitchScan() {
    GUID hidGuid; HidD_GetHidGuid(&hidGuid);
    HDEVINFO set = SetupDiGetClassDevsA(&hidGuid, nullptr, nullptr, DIGCF_PRESENT | DIGCF_DEVICEINTERFACE);
    if (set == INVALID_HANDLE_VALUE) return;
    SP_DEVICE_INTERFACE_DATA ifd; ifd.cbSize = sizeof ifd;
    for (DWORD i = 0; SetupDiEnumDeviceInterfaces(set, nullptr, &hidGuid, i, &ifd); ++i) {
        BYTE detailBuf[sizeof(SP_DEVICE_INTERFACE_DETAIL_DATA_A) + 512];
        SP_DEVICE_INTERFACE_DETAIL_DATA_A* detail = (SP_DEVICE_INTERFACE_DETAIL_DATA_A*)detailBuf;
        detail->cbSize = sizeof(SP_DEVICE_INTERFACE_DETAIL_DATA_A);
        if (!SetupDiGetDeviceInterfaceDetailA(set, &ifd, detail, sizeof detailBuf, nullptr, nullptr)) continue;
        // Cheap filter before opening: the path carries the IDs ("vid_057e&pid_2009", or for
        // Bluetooth "_vid&0002057e_pid&2009").
        char lower[512]; strncpy(lower, detail->DevicePath, sizeof lower - 1); lower[sizeof lower - 1] = 0;
        for (char* c = lower; *c; ++c) *c = (char)tolower((unsigned char)*c);
        if (!strstr(lower, "057e") || !strstr(lower, "2009")) continue;
        bool known = false;
        int freeSlot = -1;
        for (int k = 0; k < 4; ++k) {
            if (g_switch[k].active && !_stricmp(g_switch[k].path, detail->DevicePath)) known = true;
            if (!g_switch[k].active && freeSlot < 0) freeSlot = k;
        }
        for (int k = 0; k < g_numSwitchFailed; ++k) if (!_stricmp(g_switchFailed[k], detail->DevicePath)) known = true;
        if (known || freeSlot < 0) continue;
        HANDLE h = CreateFileA(detail->DevicePath, GENERIC_READ | GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE,
                               nullptr, OPEN_EXISTING, FILE_FLAG_OVERLAPPED, nullptr);
        if (h == INVALID_HANDLE_VALUE) continue;
        HIDD_ATTRIBUTES attr; attr.Size = sizeof attr;
        PHIDP_PREPARSED_DATA pp = nullptr; HIDP_CAPS caps; memset(&caps, 0, sizeof caps);
        bool match = HidD_GetAttributes(h, &attr) && attr.VendorID == kNintendoVid && attr.ProductID == kSwitchProPid
                     && HidD_GetPreparsedData(h, &pp);
        if (match) { HidP_GetCaps(pp, &caps); HidD_FreePreparsedData(pp); }
        if (!match || caps.OutputReportByteLength < 49 || caps.InputReportByteLength < 49
            || caps.OutputReportByteLength > 512 || caps.InputReportByteLength > 512) { CloseHandle(h); continue; }
        SwitchPad* s = &g_switch[freeSlot];
        strncpy(s->path, detail->DevicePath, sizeof s->path - 1);
        s->dev = h; s->outLen = caps.OutputReportByteLength; s->inLen = caps.InputReportByteLength;
        s->counter = 0; s->connected = 0; s->lastTick = 0;
        InterlockedExchange(&s->active, 1);
        HANDLE t = CreateThread(nullptr, 0, SwitchReader, s, 0, nullptr);
        if (t) CloseHandle(t); else { CloseHandle(h); s->dev = nullptr; InterlockedExchange(&s->active, 0); }
    }
    SetupDiDestroyDeviceInfoList(set);
}

static void SwitchInit() { for (int k = 0; k < 4; ++k) InitializeCriticalSection(&g_switch[k].lock); }

// Game thread: adds every Pro Controller that reported in the last half second.
static void SwitchMerge(PadOut* acc, bool* any) {
    DWORD now = GetTickCount();
    for (int k = 0; k < 4; ++k) {
        SwitchPad* s = &g_switch[k];
        if (!s->connected) continue;
        EnterCriticalSection(&s->lock);
        PadOut o = s->out; DWORD t = s->lastTick;
        LeaveCriticalSection(&s->lock);
        if (now - t > 500) continue;
        Merge(acc, o); *any = true;
    }
}

// Called on the game thread every frame. False when no controller is connected.
#ifdef DADMOD_PADINJECT
// Test builds only (never shipped): <game>\dadmod\padinject.txt holds tokens separated by spaces; the file is
// renamed padinject.done once read. Lets an automated test press controller buttons.
//   a b x y lb rb back start ls rs guide up down left right   press for 120 ms, then 450 ms gap ("x:300" = hold 300 ms)
//   down:<b>   start holding <b>          release:<b>   let go of <b>
//   press:<b>:<ms>   hold <b> for <ms>, no gap afterwards      wait:<ms>   pause
//   waitgo     wait (max 15 s) for the next time QB sets the gfx_padinject_go pseudo-key (gfx::SetKey), then clear it
// "lt" / "rt" drive the trigger axis and the trigger button bit (see InjSet).
// Each step is logged to padhub.log with GetTickCount ms (CF_Log adds the same tick to thugrecomp_debug.log).
static volatile LONG g_injButtons, g_injLT, g_injRT, g_injBusy;
HANDLE g_injGo;  // auto-reset event, set by gfx::SetKey("gfx_padinject_go")
static void InjSleep(DWORD ms) {  // ms-accurate: Sleep(1) can take 15 ms without timeBeginPeriod
    LARGE_INTEGER f, t0, t; QueryPerformanceFrequency(&f); QueryPerformanceCounter(&t0);
    LONGLONG end = t0.QuadPart + f.QuadPart * ms / 1000;
    for (;;) {
        QueryPerformanceCounter(&t);
        if (t.QuadPart >= end) return;
        LONGLONG left = (end - t.QuadPart) * 1000 / f.QuadPart;
        Sleep(left > 20 ? 1 : 0);
    }
}
static void InjSet(const char* b, bool on) {
    // "lt"/"rt" set the trigger axis AND the trigger button bit, like a real pad (ReadXPad sets the bit past 0.3);
    // dadmod's Xbox preset binds L2/R2 to DirectInput buttons 11/12. "lta"/"rta" = axis only, "ltb"/"rtb" = bit only.
    if (!_stricmp(b, "rt") || !_stricmp(b, "rta")) InterlockedExchange(&g_injRT, on);
    if (!_stricmp(b, "lt") || !_stricmp(b, "lta")) InterlockedExchange(&g_injLT, on);
    if (!_stricmp(b, "rta") || !_stricmp(b, "lta")) return;
    if (!_stricmp(b, "rtb")) b = "rt";
    if (!_stricmp(b, "ltb")) b = "lt";
    static const char* names[] = { "a", "b", "x", "y", "lb", "rb", "back", "start", "ls", "rs", "lt", "rt", "guide", "up", "down", "left", "right" };
    for (int i = 0; i < B_COUNT; ++i) if (!_stricmp(b, names[i])) {
        LONG v, n;
        do { v = g_injButtons; n = on ? (v | (1 << i)) : (v & ~(1 << i)); } while (InterlockedCompareExchange(&g_injButtons, n, v) != v);
        return;
    }
    Log("padinject: unknown button '%s'", b);
}
static DWORD WINAPI PadInjectWorker(LPVOID) {
    std::string path = std::string(g_dir) + "padinject.txt", done = std::string(g_dir) + "padinject.done";
    for (;;) {
        Sleep(20);
        HANDLE h = CreateFileA(path.c_str(), GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, nullptr, OPEN_EXISTING, 0, nullptr);
        if (h == INVALID_HANDLE_VALUE) continue;
        char buf[4096]; DWORD n = 0;
        ReadFile(h, buf, sizeof buf - 1, &n, nullptr);
        CloseHandle(h);
        buf[n] = 0;
        MoveFileExA(path.c_str(), done.c_str(), MOVEFILE_REPLACE_EXISTING);
        Log("padinject: [%lu] start: %s", GetTickCount(), buf);
        InterlockedExchange(&g_injBusy, 1);
        if (g_injGo) ResetEvent(g_injGo);
        for (char* t = strtok(buf, " \t\r\n,"); t; t = strtok(nullptr, " \t\r\n,")) {
            char* c1 = strchr(t, ':'); char* arg = nullptr; char* arg2 = nullptr;
            if (c1) { *c1 = 0; arg = c1 + 1; char* c2 = strchr(arg, ':'); if (c2) { *c2 = 0; arg2 = c2 + 1; } }
            if (!_stricmp(t, "waitgo")) {
                if (g_injGo) ResetEvent(g_injGo);  // only a signal sent after this point counts
                DWORD r = g_injGo ? WaitForSingleObject(g_injGo, 15000) : WAIT_FAILED;
                Log("padinject: [%lu] waitgo %s", GetTickCount(), r == WAIT_OBJECT_0 ? "GO" : "TIMEOUT (sequence stopped)");
                if (r != WAIT_OBJECT_0) break;
            } else if (!_stricmp(t, "wait") && arg) {
                InjSleep((DWORD)atoi(arg));
            } else if (!_stricmp(t, "down") && arg) {
                InjSet(arg, true); Log("padinject: [%lu] down %s", GetTickCount(), arg);
            } else if (!_stricmp(t, "release") && arg) {
                InjSet(arg, false); Log("padinject: [%lu] release %s", GetTickCount(), arg);
            } else if (!_stricmp(t, "press") && arg) {
                int ms = arg2 ? atoi(arg2) : 120; if (ms < 1) ms = 120;
                InjSet(arg, true); Log("padinject: [%lu] press %s %d ms", GetTickCount(), arg, ms);
                InjSleep(ms); InjSet(arg, false); Log("padinject: [%lu] release %s", GetTickCount(), arg);
            } else {
                int ms = arg ? atoi(arg) : 120; if (ms < 1) ms = 120;
                InjSet(t, true); InjSleep(ms); InjSet(t, false); InjSleep(450);
            }
        }
        InterlockedExchange(&g_injButtons, 0); InterlockedExchange(&g_injLT, 0); InterlockedExchange(&g_injRT, 0);
        InterlockedExchange(&g_injBusy, 0);
        Log("padinject: [%lu] sequence done", GetTickCount());
    }
}
static DWORD PadInjectButtons(PadOut* acc, bool* any) {
    static LONG started;
    if (!InterlockedExchange(&started, 1)) {
        g_injGo = CreateEventA(nullptr, FALSE, FALSE, nullptr);
        HANDLE t = CreateThread(nullptr, 0, PadInjectWorker, nullptr, 0, nullptr); if (t) CloseHandle(t);
    }
    if (g_injLT) acc->axis[A_LT] = 1.0f;
    if (g_injRT) acc->axis[A_RT] = 1.0f;
    if (g_injBusy || g_injLT || g_injRT || g_injButtons) *any = true;
    return (DWORD)g_injButtons;
}
#endif
static bool ReadAll(DIJOYSTATE2* st) {
    PadOut acc; memset(&acc, 0, sizeof acc);
    bool any = false, xinput = false;
    if (g_xget) {
        for (DWORD i = 0; i < 4; ++i) {
            if (!g_xconn[i]) continue;
            XState x;
            if (g_xget(i, &x) != 0) { if (InterlockedExchange(&g_xconn[i], 0)) InterlockedExchange(&g_xlost[i], 1); continue; }
            PadOut p; ReadXPad(x, &p); Merge(&acc, p); any = true; xinput = true;
        }
    }
    SwitchMerge(&acc, &any);
    EnterCriticalSection(&g_lock);
    for (int i = 0; i < g_numPads; ++i) {
        DiPad* p = g_pads[i];
        if (p->dead) continue;
        // Noah 2026-11-16 (stick pushing right): a DS4 / DualSense run through DS4Windows-style remappers shows up
        // twice, as the virtual Xbox pad (XInput) and as the raw Sony pad, whose DirectInput reading goes stale once
        // the remapper owns it (HidHide stops hiding it after a Bluetooth reconnect). Skip raw Sony pads while an XInput pad is in.
        // (if the raw pad drops or HidHide hides it meanwhile, the worker's sweep drops it and it is opened fresh later)
        if (xinput && p->vid == 0x054C) continue;
        DIJOYSTATE2 js;
        p->dev->Poll();
        HRESULT hr = p->dev->GetDeviceState(sizeof js, &js);
        if (FAILED(hr)) {
            p->dev->Acquire(); p->dev->Poll();
            hr = p->dev->GetDeviceState(sizeof js, &js);
        }
        if (FAILED(hr)) { if (++p->fails >= 3) { p->why = "3 failed reads in a row"; InterlockedExchange(&p->dead, 1); } continue; }
        p->fails = 0;
        PadOut o; ReadDiPad(p, js, &o); Merge(&acc, o); any = true;
    }
    LeaveCriticalSection(&g_lock);
#ifdef DADMOD_PADINJECT
    acc.buttons |= PadInjectButtons(&acc, &any);
#endif
    if (g_abSwap) {  // swapped before g_padButtons so menu shortcuts match what the game sees
        DWORD b = acc.buttons, m = (1u << B_A) | (1u << B_B) | (1u << B_X) | (1u << B_Y);
        acc.buttons = (b & ~m) | (((b >> B_A) & 1) << B_B) | (((b >> B_B) & 1) << B_A) | (((b >> B_X) & 1) << B_Y) | (((b >> B_Y) & 1) << B_X);
    }
    if (LONG dz = g_deadzone) {  // radial, rescaled so full tilt still reaches full value
        float d = dz * 0.03f;
        for (int k = 0; k < 2; ++k) {
            float& x = acc.axis[k ? A_RX : A_LX]; float& y = acc.axis[k ? A_RY : A_LY];
            float cx = Clamp1(x), cy = Clamp1(y), m = sqrtf(cx * cx + cy * cy);
            if (m <= d) { x = y = 0; continue; }
            float s = ((m > 1 ? 1 : m) - d) / (1 - d) / m;
            x = cx * s; y = cy * s;
        }
    }
    InterlockedExchange(&g_padButtons, any ? (LONG)acc.buttons : 0);
    {   // button prompts: the pad counts as "in use" only for a button or a stick/trigger pushed well past any drift
        float m = 0;
        for (int k = 0; k < A_COUNT; ++k) { float a = fabsf(acc.axis[k]); if (a > m) m = a; }
        InterlockedExchange(&g_padActive, any && (acc.buttons || m > 0.6f) ? 1 : 0);
    }
    if (!any) return false;

    memset(st, 0, sizeof *st);
    st->lX = (LONG)(Clamp1(acc.axis[A_LX]) * 1000);
    st->lY = (LONG)(Clamp1(acc.axis[A_LY]) * 1000);
    st->lRx = (LONG)(Clamp1(acc.axis[A_RX]) * 1000);
    st->lRy = (LONG)(Clamp1(acc.axis[A_RY]) * 1000);
    st->lZ = (LONG)(Clamp1(acc.axis[A_LT] - acc.axis[A_RT]) * 1000);
    for (int i = 0; i <= B_GUIDE; ++i) if (acc.buttons & (1u << i)) st->rgbButtons[i] = 0x80;
    bool up = (acc.buttons >> B_UP) & 1, down = (acc.buttons >> B_DOWN) & 1;
    bool left = (acc.buttons >> B_LEFT) & 1, right = (acc.buttons >> B_RIGHT) & 1;
    if (up && down) up = down = false;
    if (left && right) left = right = false;
    static const DWORD kPov[3][3] = { { 31500, 0, 4500 }, { 27000, 0xFFFFFFFF, 9000 }, { 22500, 18000, 13500 } };
    st->rgdwPOV[0] = kPov[up ? 0 : down ? 2 : 1][left ? 0 : right ? 2 : 1];
    st->rgdwPOV[1] = st->rgdwPOV[2] = st->rgdwPOV[3] = 0xFFFFFFFF;
    return true;
}

// ---- worker thread: finds new pads, drops unplugged ones

struct EnumCtx { IDirectInput8A* di; };

static BOOL CALLBACK CountObject(LPCDIDEVICEOBJECTINSTANCEA obj, LPVOID ctx) {
    DiPad* p = (DiPad*)ctx;
    DWORD type = DIDFT_GETTYPE(obj->dwType);
    // obj->dwOfs is not the DIJOYSTATE2 offset on every device (a Bluetooth DS4 reports its own
    // order: 0 = Rz, 4 = Z, 8 = Y, 0xC = X...), so the offset comes from the axis type instead.
    static const GUID* kAxisTypes[6] = { &GUID_XAxis, &GUID_YAxis, &GUID_ZAxis, &GUID_RxAxis, &GUID_RyAxis, &GUID_RzAxis };
    if (type & DIDFT_AXIS) {
        int ofs = -1;
        for (int i = 0; i < 6 && ofs < 0; ++i) if (IsEqualGUID(obj->guidType, *kAxisTypes[i])) ofs = i * 4;
        if (ofs < 0 && IsEqualGUID(obj->guidType, GUID_Slider)) {
            ofs = DIJOFS_SLIDER(0);
            for (int i = 0; i < p->numAxes; ++i) if (p->axisOfs[i] == ofs) ofs = DIJOFS_SLIDER(1);
        }
        for (int i = 0; i < p->numAxes && ofs >= 0; ++i) if (p->axisOfs[i] == ofs) ofs = -1;
        if (ofs >= 0 && p->numAxes < 8) p->axisOfs[p->numAxes++] = ofs;
    }
    else if (type & DIDFT_POV) ++p->numHats;
    else if (type & DIDFT_BUTTON) ++p->numButtons;
    return DIENUM_CONTINUE;
}

static bool KnownGuid(const GUID& g) {
    if (IsEqualGUID(*(const GUID*)kPad1Guid, g)) return true;
    for (int i = 0; i < g_numSkip; ++i) if (IsEqualGUID(g_skip[i], g)) return true;
    EnterCriticalSection(&g_lock);
    bool found = false;
    for (int i = 0; i < g_numPads && !found; ++i) found = IsEqualGUID(g_pads[i]->instance, g);
    LeaveCriticalSection(&g_lock);
    return found;
}

static BOOL CALLBACK FoundDevice(LPCDIDEVICEINSTANCEA inst, LPVOID ctx) {
    IDirectInput8A* di = ((EnumCtx*)ctx)->di;
    // still listed this scan: keep it (pads and XInput copies DirectInput stops listing are dropped by the sweep)
    EnterCriticalSection(&g_lock);
    for (int i = 0; i < g_numPads; ++i) if (IsEqualGUID(g_pads[i]->instance, inst->guidInstance)) g_pads[i]->seenPass = g_pass;
    LeaveCriticalSection(&g_lock);
    for (int i = 0; i < g_numSkip; ++i) if (IsEqualGUID(g_skip[i], inst->guidInstance)) g_skipSeen[i] = g_pass;
    if (KnownGuid(inst->guidInstance) || g_numPads >= 8) return DIENUM_CONTINUE;
    if (g_switchActive > 0 && LOWORD(inst->guidProduct.Data1) == kNintendoVid && HIWORD(inst->guidProduct.Data1) == kSwitchProPid)
        return DIENUM_CONTINUE;  // read natively (Switch Pro section)
    IDirectInputDevice8A* dev = nullptr;
    if (FAILED(di->CreateDevice(inst->guidInstance, &dev, nullptr)) || !dev) return DIENUM_CONTINUE;

    // XInput pads also show up here (their device path has "IG_"); they are read through XInput.
    DIPROPGUIDANDPATH gp; memset(&gp, 0, sizeof gp);
    gp.diph.dwSize = sizeof gp; gp.diph.dwHeaderSize = sizeof gp.diph; gp.diph.dwHow = DIPH_DEVICE;
    if (SUCCEEDED(dev->GetProperty(DIPROP_GUIDANDPATH, &gp.diph)) && (wcsstr(gp.wszPath, L"IG_") || wcsstr(gp.wszPath, L"ig_"))) {
        dev->Release();
        if (g_numSkip < 16) { g_skipSeen[g_numSkip] = g_pass; g_skip[g_numSkip++] = inst->guidInstance; }
        return DIENUM_CONTINUE;
    }
    if (FAILED(dev->SetDataFormat(&c_dfDIJoystick2))) { dev->Release(); return DIENUM_CONTINUE; }
    DIPROPRANGE range; memset(&range, 0, sizeof range);
    range.diph.dwSize = sizeof range; range.diph.dwHeaderSize = sizeof range.diph; range.diph.dwHow = DIPH_DEVICE;
    range.lMin = -32768; range.lMax = 32767;
    dev->SetProperty(DIPROP_RANGE, &range.diph);

    DiPad* p = (DiPad*)calloc(1, sizeof(DiPad));
    p->dev = dev;
    p->instance = inst->guidInstance;
    p->vid = LOWORD(inst->guidProduct.Data1);
    p->pid = HIWORD(inst->guidProduct.Data1);
    strncpy(p->name, inst->tszProductName, sizeof p->name - 1);
    dev->EnumObjects(CountObject, p, DIDFT_AXIS | DIDFT_POV | DIDFT_BUTTON);
    for (int i = 1; i < p->numAxes; ++i)  // offset order, as SDL numbers them
        for (int j = i; j > 0 && p->axisOfs[j - 1] > p->axisOfs[j]; --j) { int t = p->axisOfs[j]; p->axisOfs[j] = p->axisOfs[j - 1]; p->axisOfs[j - 1] = t; }
    const char* source = ChooseMapping(p);
    dev->Acquire();

    EnterCriticalSection(&g_lock);
    g_pads[g_numPads++] = p;
    LeaveCriticalSection(&g_lock);
    Log("connected: %s (%04X:%04X, DirectInput, %d axes %d buttons %d hats, mapping: %s)",
        p->name, p->vid, p->pid, p->numAxes, p->numButtons, p->numHats, source);
    p->since = GetTickCount();
    p->seenPass = g_pass;
    return DIENUM_CONTINUE;
}

static void LoadDb() {
    char path[MAX_PATH + 32];
    _snprintf(path, sizeof path, "%sgamecontrollerdb.txt", g_dir); path[sizeof path - 1] = 0;
    HANDLE f = CreateFileA(path, GENERIC_READ, FILE_SHARE_READ, nullptr, OPEN_EXISTING, 0, nullptr);
    if (f == INVALID_HANDLE_VALUE) return;
    DWORD size = GetFileSize(f, nullptr), got = 0;
    if (size != INVALID_FILE_SIZE && size < 8 * 1024 * 1024) {
        g_db = (char*)malloc(size + 1);
        if (g_db && ReadFile(f, g_db, size, &got, nullptr)) g_db[got] = 0;
        else { free(g_db); g_db = nullptr; }
    }
    CloseHandle(f);
    if (g_db) Log("loaded gamecontrollerdb.txt");
}

static DWORD WINAPI Worker(LPVOID) {
    static const char* kXInputDlls[] = { "xinput1_4.dll", "xinput1_3.dll", "xinput9_1_0.dll" };
    for (int i = 0; i < 3 && !g_xget; ++i) {
        HMODULE x = LoadLibraryA(kXInputDlls[i]);
        if (!x) continue;
        g_xget = (XGetStateFn)GetProcAddress(x, (LPCSTR)100);  // XInputGetStateEx: also reports Guide
        if (!g_xget) g_xget = (XGetStateFn)GetProcAddress(x, "XInputGetState");
    }
    g_workerStart = GetTickCount();
    LoadDb();
    SwitchInit();
    IDirectInput8A* di = nullptr;
    DirectInput8Create(GetModuleHandleA(nullptr), DIRECTINPUT_VERSION, IID_IDirectInput8A, (void**)&di, nullptr);
    Log("started (XInput %s, DirectInput %s)", g_xget ? "ok" : "missing", di ? "ok" : "missing");

    for (;;) {
        if (g_xget) {
            for (DWORD i = 0; i < 4; ++i) {
                if (InterlockedExchange(&g_xlost[i], 0)) { Log("disconnected: XInput pad %u (stopped answering)", i + 1); Popup("disconnected", "Xbox controller"); }
                XState x;
                bool answers = g_xget(i, &x) == 0;
                if (g_xconn[i]) {
                    // also checked here: the game thread only reads pads while it has input (not with another THUG Pro in front)
                    if (!answers && InterlockedExchange(&g_xconn[i], 0)) { Log("disconnected: XInput pad %u (stopped answering, found by the background check)", i + 1); Popup("disconnected", "Xbox controller"); }
                    continue;
                }
                if (answers) { InterlockedExchange(&g_xconn[i], 1); g_xseen = true; Log("connected: XInput pad %u", i + 1); Popup("connected", "Xbox controller"); }
            }
        }
        // Drop unplugged DirectInput pads so they are picked up again when plugged back in.
        DiPad* gone[8]; int numGone = 0;
        EnterCriticalSection(&g_lock);
        for (int i = 0; i < g_numPads; ) {
            if (g_pads[i]->dead) { gone[numGone++] = g_pads[i]; g_pads[i] = g_pads[--g_numPads]; }
            else ++i;
        }
        LeaveCriticalSection(&g_lock);
        for (int i = 0; i < numGone; ++i) {
            Log("disconnected: %s (%s; opened fresh when DirectInput lists it again)", gone[i]->name, gone[i]->why ? gone[i]->why : "dropped");
            if (gone[i]->announced) Popup("disconnected", gone[i]->name);
            gone[i]->dev->Unacquire(); gone[i]->dev->Release(); free(gone[i]);
        }
        EnterCriticalSection(&g_lock);
        for (int i = 0; i < g_numPads; ++i) {
            DiPad* p = g_pads[i];
            if (p->checked || p->dead || GetTickCount() - p->since < 5000) continue;
            p->checked = true;
            if (p->since - g_workerStart < 3000) continue;  // there at startup
            if (p->vid == 0x054C && g_xseen) continue;  // DS4Windows' raw copy of the pad
            if (p->vid == kNintendoVid && p->pid == kSwitchProPid && g_switchActive) continue;  // read natively instead
            p->announced = true;
            Popup("connected", p->name);
        }
        LeaveCriticalSection(&g_lock);
        SwitchScan();
        if (di) {
            ++g_pass;
            EnumCtx ctx = { di };
            if (SUCCEEDED(di->EnumDevices(DI8DEVCLASS_GAMECTRL, FoundDevice, &ctx, DIEDFL_ATTACHEDONLY))) {
                // sweep: a pad DirectInput stopped listing (unplugged, Bluetooth dropped, or hidden by HidHide) may still
                // answer with frozen data and no error; drop it so the same pad is opened fresh when it comes back
                EnterCriticalSection(&g_lock);
                for (int i = 0; i < g_numPads; ++i) {
                    DiPad* p = g_pads[i];
                    if (p->dead || g_pass - p->seenPass < kGoneScans) continue;
                    p->why = "no longer listed by DirectInput: unplugged, Bluetooth dropped, or hidden by HidHide";
                    InterlockedExchange(&p->dead, 1);
                }
                LeaveCriticalSection(&g_lock);
                for (int i = 0; i < g_numSkip; ) {
                    if (g_pass - g_skipSeen[i] >= kGoneScans) {
                        Log("XInput pad's DirectInput copy is gone (%d left to ignore)", g_numSkip - 1);
                        g_skip[i] = g_skip[g_numSkip - 1]; g_skipSeen[i] = g_skipSeen[g_numSkip - 1]; --g_numSkip;
                    } else ++i;
                }
            }
        }
        // which pad drives player 1 right now (logged when it changes, so a reconnect that picks the wrong pad shows up)
        {
            static int lastX = -1, lastRaw = -1;
            int x = 0, raw = 0;
            for (int i = 0; i < 4; ++i) x += g_xconn[i] ? 1 : 0;
            EnterCriticalSection(&g_lock);
            for (int i = 0; i < g_numPads; ++i) raw += (!g_pads[i]->dead && g_pads[i]->vid == 0x054C) ? 1 : 0;
            LeaveCriticalSection(&g_lock);
            if (x != lastX || raw != lastRaw) {
                if (raw && x) Log("input: %d XInput pad(s) in use; %d raw Sony pad(s) ignored while an XInput pad is in (remapper's copy)", x, raw);
                else if (raw) Log("input: no XInput pad; using %d raw Sony pad(s) directly", raw);
                else Log("input: %d XInput pad(s), %d other DirectInput pad(s)", x, g_numPads);
                lastX = x; lastRaw = raw;
            }
        }
        Sleep(1500);
    }
}

static void Start() {
    if (InterlockedExchange(&g_started, 1)) return;
    HANDLE t = CreateThread(nullptr, 0, Worker, nullptr, 0, nullptr);
    if (t) { SetThreadPriority(t, THREAD_PRIORITY_BELOW_NORMAL); CloseHandle(t); }
}

// The pad keeps driving the game when another program has focus, so clicking over to a browser or
// Discord doesn't drop input. The one exception is another THUG Pro window: when that's in front,
// this game lets go so one controller doesn't play both. Checked at most 4 times a second.
// Dadmod > Background input (gfx_bginput in gfx.ini, Noah 2026-11-16) set to Off: input only while
// this game's window is in front, like the stock game. gfx.inc keeps g_bgInput in step with the setting.
static volatile LONG g_bgInput = 1;
static bool InputAllowed() {
    static DWORD lastTick, lastPid;
    static bool lastResult = true;
    DWORD pid = 0;
    HWND fg = GetForegroundWindow();
    if (fg) GetWindowThreadProcessId(fg, &pid);
    if (!pid || pid == GetCurrentProcessId()) return true;
    if (!g_bgInput) return false;
    DWORD now = GetTickCount();
    if (pid == lastPid && now - lastTick < 250) return lastResult;
    lastPid = pid; lastTick = now; lastResult = true;
    HANDLE h = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pid);
    if (h) {
        char path[MAX_PATH]; DWORD len = sizeof path;
        if (QueryFullProcessImageNameA(h, 0, path, &len)) {
            const char* base = strrchr(path, '\\');
            base = base ? base + 1 : path;
            if (_stricmp(base, "THUGPro.exe") == 0) lastResult = false;
        }
        CloseHandle(h);
    }
    return lastResult;
}

// thugpro.dll stops skater control (menus still work) whenever the game window isn't in front: its
// only two GetForegroundWindow calls compare against the game window. Its import is pointed here so
// it sees the game window in front unless another THUG Pro is.
static const DWORD kGameHwnd = 0x7D6A28;
static const DWORD kTpForegroundIat = 0x4029C;  // thugpro.dll RVA of its GetForegroundWindow import

static HWND WINAPI TpForegroundHook() {
    return InputAllowed() ? *(HWND*)kGameHwnd : GetForegroundWindow();
}

static void HookThugproForeground() {
    static bool done;
    if (done) return;
    BYTE* tp = (BYTE*)GetModuleHandleA("thugpro.dll");
    if (!tp) return;
    done = true;
    void** slot = (void**)(tp + kTpForegroundIat);
    void* real = (void*)GetProcAddress(GetModuleHandleA("user32.dll"), "GetForegroundWindow");
    if (*slot != real) return;  // another thugpro.dll build, or already pointed elsewhere
    DWORD old;
    VirtualProtect(slot, 4, PAGE_READWRITE, &old);
    *slot = (void*)&TpForegroundHook;
    VirtualProtect(slot, 4, old, &old);
}

// ---- engine hooks

// Replaces GetPadState (0x5F2E00). Slot 0 (player 1) reads every connected controller; slot 1
// keeps the stock code path (the launcher's pad1 device).
static void* __cdecl PadStateHook(int slot) {
    BYTE* cur = (BYTE*)(kPadCur + slot * kStateSize);
    BYTE* prev = (BYTE*)(kPadPrev + slot * kStateSize);
    if (slot == 0) {
        Start();
        HookThugproForeground();
        ShowPopup();
        DIJOYSTATE2 st;
        if (!InputAllowed() || !ReadAll(&st)) return nullptr;
        memcpy(prev, cur, kStateSize);
        memcpy(cur, &st, kStateSize);
        return cur;
    }
    IDirectInputDevice8A* dev = ((IDirectInputDevice8A**)kPadDevices)[slot];
    if (!dev) return nullptr;
    if (FAILED(dev->Poll()) && (FAILED(dev->Acquire()) || FAILED(dev->Poll()))) return nullptr;
    memcpy(prev, cur, kStateSize);
    if (FAILED(dev->GetDeviceState(kStateSize, cur))) return nullptr;
    return cur;
}

// Player 1's launcher bindings, saved before the first overwrite so Dadmod > Controls >
// Use launcher button layout can switch between them and kPreset live.
static int g_launcherCopy[24];
static volatile LONG g_bindsSaved, g_launchBindsSetting;
// Dadmod > Controls > Keyboard / Controller bindings (Noah 2026-11-16): custom binds sit on top of the base
// layout (keyboard: the launcher's keys; controller: dadmod's Xbox preset or the launcher's, per Use launcher
// button layout). Only changed slots are stored, in dadmod\binds.ini; Reset to default clears them.
// The engine reads both tables every frame (ReadControls 0x5F5BC0), so changes apply on the next frame.
static const DWORD kKb0Binds = 0x7D6770;  // k0_0..k0_23, DirectInput scan codes, -1 none
static const DWORD kKeyState = 0x7D6670;  // engine's DirectInput keyboard state, 256 bytes
static const int kNoOvr = -1000;
static int g_kbLauncher[24];
static int g_kbOvr[24], g_padOvr[24];
static bool g_ovrLoaded;
static void LoadBindOverrides() {
    for (int i = 0; i < 24; ++i) g_kbOvr[i] = g_padOvr[i] = kNoOvr;
    char path[MAX_PATH + 16];
    _snprintf(path, sizeof path, "%sbinds.ini", g_dir); path[sizeof path - 1] = 0;
    FILE* f = fopen(path, "rb");
    if (!f) return;
    char line[128];
    while (fgets(line, sizeof line, f)) {
        int slot, v;
        if (sscanf(line, " k0_%d = %d", &slot, &v) == 2 && slot >= 0 && slot < 24) g_kbOvr[slot] = v;
        else if (sscanf(line, " gp0_%d = %d", &slot, &v) == 2 && slot >= 0 && slot < 24) g_padOvr[slot] = v;
    }
    fclose(f);
}
static void SaveBindOverrides() {
    char path[MAX_PATH + 16];
    _snprintf(path, sizeof path, "%sbinds.ini", g_dir); path[sizeof path - 1] = 0;
    FILE* f = fopen(path, "wb");
    if (!f) return;
    fputs("; Dadmod > Controls key and button bindings (only changed slots). Delete this file for the defaults.\r\n", f);
    fputs("; k0_N = DirectInput key code, gp0_N = controller code (11 A, 12 B, 13 X, 14 Y, 15 LB, 16 RB, 17 Back, 18 Start, 19 L3, 20 R3, 21 LT, 22 RT)\r\n", f);
    for (int i = 0; i < 24; ++i) if (g_kbOvr[i] != kNoOvr) fprintf(f, "k0_%d = %d\r\n", i, g_kbOvr[i]);
    for (int i = 0; i < 24; ++i) if (g_padOvr[i] != kNoOvr) fprintf(f, "gp0_%d = %d\r\n", i, g_padOvr[i]);
    fclose(f);
}
static void ApplyBindings() {
    int* binds = (int*)kPad0Binds;
    int* kb = (int*)kKb0Binds;
    if (!g_bindsSaved) {
        memcpy(g_launcherCopy, binds, sizeof g_launcherCopy);
        memcpy(g_kbLauncher, kb, sizeof g_kbLauncher);
        InterlockedExchange(&g_bindsSaved, 1);
    }
    if (!g_ovrLoaded) { g_ovrLoaded = true; LoadBindOverrides(); }
    if (!g_launcherBinds && !g_launchBindsSetting) memcpy(binds, kPreset, sizeof kPreset);  // padhub.ini use_launcher_bindings=1 forces On
    else for (int i = 0; i < 24; ++i) {  // launcher codes for XInput triggers -> our trigger buttons
        int b = g_launcherCopy[i];
        binds[i] = b == 90 ? 21 : b == 91 ? 22 : b;
    }
    for (int i = 0; i < 24; ++i) {
        if (g_padOvr[i] != kNoOvr) binds[i] = g_padOvr[i];
        kb[i] = g_kbOvr[i] != kNoOvr ? g_kbOvr[i] : g_kbLauncher[i];
    }
}
// From gfx.inc when the setting changes. Re-applies only once padhub has set the bindings itself
// (before that the launcher's registry values aren't loaded yet).
static void SetLaunchBinds(bool on) {
    LONG v = on ? 1 : 0;
    if (InterlockedExchange(&g_launchBindsSetting, v) == v) return;
    if (g_bindsSaved && g_enabled) ApplyBindings();
}

// Runs where the engine calls DirectInput8Create, after it has read the launcher's registry
// settings and before it enumerates devices: forgets the launcher's pad0 device so the stock code
// (and thugpro.dll's XInput mode) never claims slot 0, and sets player 1's bindings.
static HRESULT WINAPI DI8CreateHook(HINSTANCE inst, DWORD version, REFIID riid, LPVOID* out, LPUNKNOWN outer) {
    memset((void*)kPad0Guid, 0, 16);
    ApplyBindings();
    return DirectInput8Create(inst, version, riid, out, outer);
}

static void Patch(DWORD addr, BYTE op, DWORD target) {
    BYTE* site = (BYTE*)addr;
    DWORD old;
    VirtualProtect(site, 5, PAGE_EXECUTE_READWRITE, &old);
    site[0] = op;
    *(int*)(site + 1) = (int)(target - (addr + 5));
    VirtualProtect(site, 5, old, &old);
    FlushInstructionCache(GetCurrentProcess(), site, 5);
}

static bool ReadConfig() {
    char exe[MAX_PATH];
    DWORD n = GetModuleFileNameA(nullptr, exe, MAX_PATH);
    if (!n || n >= MAX_PATH) return false;
    while (n && exe[n - 1] != '\\' && exe[n - 1] != '/') --n;
    exe[n] = 0;
    strcpy(g_dir, exe);
    strcat(g_dir, "dadmod\\");  // our files live in <game>\dadmod (Noah, 2026-10-11)
    char ini[MAX_PATH + 16];
    _snprintf(ini, sizeof ini, "%spadhub.ini", g_dir); ini[sizeof ini - 1] = 0;
    g_enabled = GetPrivateProfileIntA("padhub", "enabled", 1, ini) != 0;
    g_launcherBinds = GetPrivateProfileIntA("padhub", "use_launcher_bindings", 0, ini) != 0;
    return g_enabled;
}

static bool PadStateIsStock() {
    static const BYTE kStock[5] = { 0x53, 0x8B, 0x5C, 0x24, 0x08 };  // push ebx; mov ebx,[esp+8]
    return !memcmp((void*)kPadStateFn, kStock, 5);
}

// ---- keep running in the background
// Stock behaviour on losing focus: WM_ACTIVATE minimizes the window and clears the active flag,
// the main loop then skips drawing (online) or stalls in a Sleep(100) loop (offline), and
// DirectSound mutes every buffer. In a window none of that is needed, so the game carries on as if
// it still had focus. Exclusive fullscreen keeps the stock minimize: its D3D device is lost on
// alt-tab and only that path resets it.

static const DWORD kActivateOff = 0x4E1718;      // WndProc, WM_ACTIVATE with WA_INACTIVE
static const DWORD kMainLoopInactive = 0x44EFA4; // jne taken while active; else the stall
static const DWORD kDSCreate8Iat = 0x645028;     // DSOUND ordinal 11 (DirectSoundCreate8)
static const DWORD kDSound = 0x7D6A38;           // IDirectSound8*

static __declspec(naked) void ActivateOffStub() {
    __asm {
        cmp dword ptr ds:[0x786A9C], 0   // D3DPRESENT_PARAMETERS.Windowed
        je fullscreen
        xor eax, eax
        ret 10h
    fullscreen:
        mov eax, dword ptr ds:[0x7D6A28] // the instruction this patch replaced
        push 0x4E171D
        ret
    }
}

typedef HRESULT (WINAPI* CreateBufFn)(void* ds, const DWORD* desc, void** out, void* outer);
typedef HRESULT (WINAPI* DSCreate8Fn)(const GUID* dev, void** out, void* outer);
static CreateBufFn g_createBuf;
static DSCreate8Fn g_dsCreate8;

// Every secondary buffer gets DSBCAPS_GLOBALFOCUS (0x8000) so sound keeps playing unfocused.
static HRESULT WINAPI CreateBufHook(void* ds, const DWORD* desc, void** out, void* outer) {
    DWORD copy[16];
    if (desc && desc[0] <= sizeof copy && !(desc[1] & 1)) {  // 1 = DSBCAPS_PRIMARYBUFFER
        memcpy(copy, desc, desc[0]);
        copy[1] |= 0x8000;
        desc = copy;
    }
    return g_createBuf(ds, desc, out, outer);
}

static void HookDSound(void* ds) {
    void** vt = *(void***)ds;
    if (vt[3] == (void*)&CreateBufHook) return;
    DWORD old;
    VirtualProtect(&vt[3], 4, PAGE_EXECUTE_READWRITE, &old);
    g_createBuf = (CreateBufFn)vt[3];
    vt[3] = (void*)&CreateBufHook;
    VirtualProtect(&vt[3], 4, old, &old);
}

static HRESULT WINAPI DSCreate8Hook(const GUID* dev, void** out, void* outer) {
    HRESULT hr = g_dsCreate8(dev, out, outer);
    if (SUCCEEDED(hr) && out && *out) HookDSound(*out);
    return hr;
}

// Unpausing (0x54F960 with pause=0) always ran SetViewMode 0, so leaving the pause menu dropped
// free cam while the script's view_mode stayed 1. Offline the call is skipped and free cam
// survives the pause menu (dadmod Mark Menu Camera); online keeps the stock reset.
static const DWORD kUnpauseViewOff = 0x54FB09;  // call SetViewMode CFunc (0x59FD90)
static const DWORD kNetGame = 0x7CCDF8;

static int __cdecl UnpauseViewOffHook(void* params, void* script) {
    if (*(BYTE*)kNetGame) return ((int(__cdecl*)(void*, void*))0x59FD90)(params, script);
    return 1;
}

static void InstallBackground(bool live) {
    BYTE* call = (BYTE*)kUnpauseViewOff;
    if (call[0] == 0xE8) Patch(kUnpauseViewOff, 0xE8, (DWORD)&UnpauseViewOffHook);
    BYTE* site = (BYTE*)kActivateOff;
    if (site[0] == 0xA1 || site[0] == 0xE9) Patch(kActivateOff, 0xE9, (DWORD)&ActivateOffStub);
    BYTE* jne = (BYTE*)kMainLoopInactive;
    if (jne[0] == 0x75 && jne[1] == 0x14) {
        DWORD old;
        VirtualProtect(jne, 1, PAGE_EXECUTE_READWRITE, &old);
        jne[0] = 0xEB;
        VirtualProtect(jne, 1, old, &old);
        FlushInstructionCache(GetCurrentProcess(), jne, 1);
    }
    if (live) {
        if (*(void**)kDSound) HookDSound(*(void**)kDSound);
    } else {
        DSCreate8Fn* iat = (DSCreate8Fn*)kDSCreate8Iat;
        DWORD old;
        VirtualProtect(iat, 4, PAGE_READWRITE, &old);
        g_dsCreate8 = *iat;
        *iat = &DSCreate8Hook;
        VirtualProtect(iat, 4, old, &old);
    }
}

// binkw32.dll proxy: called from DllMain at process start.
static void InstallAtStartup() {
    InitializeCriticalSection(&g_lock);
    InstallBackground(false);
    if (!ReadConfig() || !PadStateIsStock()) return;
    BYTE* call = (BYTE*)kCallDI8;
    if (call[0] != 0xE8 || (DWORD)(kCallDI8 + 5 + *(int*)(call + 1)) != kDI8Thunk) return;
    Patch(kCallDI8, 0xE8, (DWORD)&DI8CreateHook);
    Patch(kPadStateFn, 0xE9, (DWORD)&PadStateHook);
}

// Live DLL loaded into a running game: devices were already enumerated, so only the bindings
// and the per-frame read change.
// A game already running an older padhub (0x5F2E00 already a jmp) is re-pointed to this copy.
static void InstallLive() {
    InitializeCriticalSection(&g_lock);
    InstallBackground(true);
    HookThugproForeground();
    if (!ReadConfig() || (!PadStateIsStock() && *(BYTE*)kPadStateFn != 0xE9)) return;
    ApplyBindings();
    Patch(kPadStateFn, 0xE9, (DWORD)&PadStateHook);
    Log("loaded into the running game");
}

// ---- press-to-bind capture (Dadmod > Controls > Keyboard / Controller bindings) ----
// Phases: 1 wait until every key and button is up (the press that opened it), 2 take the first new
// key / button (Esc or 6 s cancels), 3 wait until it is let go. While a capture runs, gfx.inc's
// ReadControlsHook blanks the control block (BindBlocking), so the press never reaches the menu.
static volatile LONG g_capPhase, g_capDev, g_capSlot;
static DWORD g_capStart;
static bool KeyAny() { const BYTE* k = (const BYTE*)kKeyState; for (int i = 0; i < 256; ++i) if (k[i]) return true; return false; }
static bool GameInFront() {
    DWORD pid = 0; HWND fg = GetForegroundWindow();
    if (fg) GetWindowThreadProcessId(fg, &pid);
    return pid == GetCurrentProcessId();
}
static void SetBind(int dev, int slot, int code) {
    int* live = (int*)(dev ? kPad0Binds : kKb0Binds);
    int* ovr = dev ? g_padOvr : g_kbOvr;
    int lo = dev ? 8 : 0, hi = dev ? 19 : 23;
    int old = live[slot];
    for (int t = lo; t <= hi; ++t)  // already used by another action: that action gets this one's old key (swap)
        if (t != slot && !(dev == 0 && t == 12) && live[t] == code) ovr[t] = old;
    ovr[slot] = code;
    ApplyBindings();
    SaveBindOverrides();
}
static void CaptureTick() {  // game thread, from ReadControlsHook (after the engine refreshed the key state)
    LONG ph = g_capPhase;
    if (!ph) return;
    const BYTE* k = (const BYTE*)kKeyState;
    bool any = KeyAny() || g_padButtons != 0;
    DWORD now = GetTickCount();
    if (ph == 1) {
        if (!any) { InterlockedExchange(&g_capPhase, 2); g_capStart = now; }
        else if (now - g_capStart > 6000) InterlockedExchange(&g_capPhase, 3);
        return;
    }
    if (ph == 2) {
        if (now - g_capStart > 6000 || (GameInFront() && k[1])) { InterlockedExchange(&g_capPhase, 3); return; }  // timeout or Esc
        if (!GameInFront()) return;
        int code = -1;
        if (g_capDev == 0) { for (int i = 2; i < 256 && code < 0; ++i) if (k[i]) code = i; }
        else { DWORD b = (DWORD)g_padButtons; for (int i = 0; i <= B_GUIDE && code < 0; ++i) if (b & (1u << i)) code = 11 + i; }
        if (code >= 0) { SetBind(g_capDev, g_capSlot, code); InterlockedExchange(&g_capPhase, 3); }
        return;
    }
    if (!any) InterlockedExchange(&g_capPhase, 0);
}
static bool BindBlocking() { return g_capPhase != 0; }
static void KeyName(int dik, char* out, int n) {
    if (dik < 0) { strcpy(out, "None"); return; }
    // the game's own key names first (Noah 2026-11-20: "KP7" like the stock menus, not Windows' "Num 7"): the stock
    // ButtonKeyName (0x5BCD50) reads them from 0x7D42F8 + key * 0x1E (wide text, up to 15 characters, by DIK code)
    if (dik < 256) {
        const wchar_t* w = (const wchar_t*)(0x7D42F8 + dik * 0x1E);
        if (w[0]) {
            wchar_t tmp[16];
            int k = 0;
            while (k < 15 && w[k]) { tmp[k] = w[k]; ++k; }
            tmp[k] = 0;
            if (WideCharToMultiByte(CP_ACP, 0, tmp, -1, out, n, nullptr, nullptr) > 1) { out[n - 1] = 0; return; }
        }
    }
    LONG lp =((dik & 0x7F) << 16) | ((dik & 0x80) ? (1 << 24) : 0);
    if (!GetKeyNameTextA(lp, out, n) || !out[0]) _snprintf(out, n, "Key %d", dik);
    out[n - 1] = 0;
}
static void PadName(int code, char* out, int n) {
    static const char* kBtn[] = { "A", "B", "X", "Y", "LB", "RB", "Back", "Start", "L3", "R3", "LT", "RT", "Guide" };
    static const char* kAx[] = { "", "Left stick X", "Left stick Y", "Triggers", "D-pad X", "D-pad Y", "Right stick X", "Right stick Y", "Axis 8", "D-pad 2 X", "D-pad 2 Y" };
    if (code == 90) code = 21; else if (code == 91) code = 22;
    if (code >= 11 && code <= 23) strcpy(out, kBtn[code - 11]);
    else if (code >= 1 && code <= 10) strcpy(out, kAx[code]);
    else if (code > 23 && code < 40) _snprintf(out, n, "Button %d", code - 10);
    else strcpy(out, "None");
    out[n - 1] = 0;
}
// THUGRECOMP_BindName dev=0 (keyboard) / 1 (controller) slot=N -> text = name of what is bound there now
static bool __cdecl CF_BindName(void* params, void* script) {
    int dev = IntParam(params, "dev", 0), slot = IntParam(params, "slot", 0);
    if (slot < 0 || slot > 23) return false;
    char name[64];
    int code = ((int*)(dev ? kPad0Binds : kKb0Binds))[slot];
    if (dev) PadName(code, name, sizeof name); else KeyName(code, name, sizeof name);
    RetStr(script, "text", name);
    return true;
}
// THUGRECOMP_BindCapture dev= slot= -> starts waiting for the next key / button for that slot
static bool __cdecl CF_BindCapture(void* params, void*) {
    int dev = IntParam(params, "dev", 0), slot = IntParam(params, "slot", -1);
    if (slot < 0 || slot > 23 || g_capPhase || !g_bindsSaved) return false;
    InterlockedExchange(&g_capDev, dev ? 1 : 0);
    InterlockedExchange(&g_capSlot, slot);
    g_capStart = GetTickCount();
    InterlockedExchange(&g_capPhase, 1);
    return true;
}
// THUGRECOMP_BindPoll -> true while a capture is still running
static bool __cdecl CF_BindPoll(void*, void*) { return g_capPhase != 0; }

// ---- button prompts: which device was used last (Noah 2026-11-19: "all menu buttons need to properly be telegraphed on
// screen with proper conversion for xbox layout or keyboard and mouse"). THUG Pro picks keyboard or controller prompts
// once, from the launcher's CtrlLayout (0 keyboard, 1 PlayStation, 2 Xbox): thugpro.dll keeps it (RVA 0x8C750) and draws
// key names instead of button glyphs while it is 0, and the scripts read GLOBAL_CtrlLayout. DeviceTick notes the device
// on a fresh press (a key, a mouse click, a pad button, or a stick/trigger pushed well past drift; mouse movement alone
// does not count); QB (dadmod_prompt_tick) applies it through THUGRECOMP_InputDevice when no typing or binding is going
// on, setting both values and rebuilding the helper bar. On a pad the launcher's PlayStation choice is kept; any other
// choice shows Xbox (the exe's button font is ButtonsXbox unless the launcher picked PlayStation).
static const DWORD kTpCtrlLayoutRva = 0x8C750, kTpCtrlLayoutUseRva = 0x7FB2;   // cmp dword ptr [CtrlLayout], 0 (text draw: key names vs glyphs)
static volatile LONG g_lastDevice = -1;   // 0 keyboard/mouse, 1 pad
static LONG g_appliedDevice = -1;
static int g_launcherLayout = -1;
static int* TpCtrlLayout() {
    static int* p; static bool tried;
    if (tried) return p;
    BYTE* tp = (BYTE*)GetModuleHandleA("thugpro.dll");
    if (!tp) return nullptr;   // not loaded yet: try again later
    tried = true;
    BYTE* use = tp + kTpCtrlLayoutUseRva;
    if (use[0] == 0x83 && use[1] == 0x3D && *(DWORD*)(use + 2) == (DWORD)(tp + kTpCtrlLayoutRva) && use[6] == 0x00) {
        p = (int*)(tp + kTpCtrlLayoutRva);
        g_launcherLayout = *p;
        Log("button prompts: launcher layout %d (%s)", *p, *p == 1 ? "PlayStation" : *p == 2 ? "Xbox" : "keyboard");
    } else Log("button prompts: thugpro.dll layout value not found (another thugpro.dll build), prompts stay as the launcher set them");
    return p;
}
// ---- key names for button codes in menus (Noah 2026-11-19: the on-screen keyboard bar read "=Cancel", "=Accept").
// Text like "\m0=Accept" goes \mN -> \bN through meta_button_map_xbox (\m0 -> \b3, \m1 -> \b2, \mf -> \bf,
// \mg -> \bg), and on keyboard prompts thugpro.dll draws \bN as the name 0x5BCD50 returns. In menus that function
// only names \bm (Enter) and \bn (Esc); for A, B and the shoulders/triggers it returns "" and nothing is drawn.
// While the prompts show keyboard (CtrlLayout 0) and the name came back empty, this fills it in: A -> the Enter name,
// B -> the Esc name (both from 0x5BCD50 itself), L1/R1/L2/R2 -> the keys bound to them. Controllers are untouched.
static const DWORD kKeyNameFn = 0x5BCD50;   // char* __cdecl ButtonKeyName(int button)
typedef char* (__cdecl* KeyNameFn_t)(int);
static KeyNameFn_t g_keyNameOrig = nullptr;   // trampoline: the 7 moved bytes + jmp 0x5BCD57
static char* __cdecl KeyNameHook(int button) {
    char* r = g_keyNameOrig(button);
    int* tp = TpCtrlLayout();
    if (!r || r[0] || !tp || *tp != 0) return r;
    int slot = -1;
    switch (button) {
    case 3: return g_keyNameOrig(0x16);   // A (accept) -> Enter
    case 2: return g_keyNameOrig(0x17);   // B (back) -> Esc
    case 0x10: slot = 14; break;          // L1 (\bg)
    case 0x11: slot = 15; break;          // R1 (\bh)
    case 0x0E: slot = 16; break;          // L2 (\be)
    case 0x0F: slot = 17; break;          // R2 (\bf)
    }
    if (slot < 0) return r;
    int dik = ((int*)kKb0Binds)[slot];
    if (dik < 0) return r;
    static char name[64];
    KeyName(dik, name, sizeof name);
    return name;
}
static void InstallKeyNameHook() {
    static bool done = false;
    if (done) return;
    done = true;
    static const BYTE orig[7] = { 0x6A, 0xFF, 0x68, 0xF8, 0x06, 0x64, 0x00 };   // push -1 / push 0x6406F8
    BYTE* site = (BYTE*)kKeyNameFn;
    if (memcmp(site, orig, 7) != 0) { Log("button prompts: 0x5BCD50 not as expected, key names in menus skipped"); return; }
    BYTE* t = (BYTE*)VirtualAlloc(nullptr, 32, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
    if (!t) return;
    memcpy(t, orig, 7);
    t[7] = 0xE9; *(DWORD*)(t + 8) = (kKeyNameFn + 7) - ((DWORD)t + 12);
    g_keyNameOrig = (KeyNameFn_t)t;
    DWORD old;
    VirtualProtect(site, 7, PAGE_EXECUTE_READWRITE, &old);
    site[0] = 0xE9; *(DWORD*)(site + 1) = (DWORD)&KeyNameHook - ((DWORD)site + 5);
    site[5] = 0x90; site[6] = 0x90;
    VirtualProtect(site, 7, old, &old);
    FlushInstructionCache(GetCurrentProcess(), site, 7);
    Log("button prompts: key names for A/B/shoulders in menus on keyboard");
}
static void DeviceTick() {   // game thread, every frame (ReadControlsHook)
    InstallKeyNameHook();
    static bool kbPrev, padPrev;
    bool kb = false;
    DWORD pid = 0; HWND fg = GetForegroundWindow();
    if (fg) GetWindowThreadProcessId(fg, &pid);
    if (pid == GetCurrentProcessId())
        kb = KeyAny() || (GetAsyncKeyState(VK_LBUTTON) & 0x8000) || (GetAsyncKeyState(VK_RBUTTON) & 0x8000) || (GetAsyncKeyState(VK_MBUTTON) & 0x8000);
    bool pad = g_padActive != 0;
    if (kb && !kbPrev) InterlockedExchange(&g_lastDevice, 0);
    if (pad && !padPrev) InterlockedExchange(&g_lastDevice, 1);
    kbPrev = kb; padPrev = pad;
}
// THUGRECOMP_InputDevice -> true when the device used last differs from the prompts on screen; device (0 keyboard,
// 1 pad), layout (the CtrlLayout value for it). apply=1 makes it the one on screen (sets thugpro.dll's value too).
// pretend=0|1 (testing) acts as if that device had just been used.
static bool __cdecl CF_InputDevice(void* params, void* script) {
    int* tp = TpCtrlLayout();
    if (!tp) return false;
    if (g_appliedDevice < 0) g_appliedDevice = g_launcherLayout == 0 ? 0 : 1;   // what the launcher set at start
    int force = IntParam(params, "pretend", -1);   // testing aid: pretend this device was just used (0 keyboard, 1 pad)
    if (force == 0 || force == 1) InterlockedExchange(&g_lastDevice, force);
    LONG dev = g_lastDevice;
    if (dev < 0) dev = g_appliedDevice;
    int layout = dev == 0 ? 0 : (g_launcherLayout == 1 ? 1 : 2);
    RetInt(script, "device", dev);
    RetInt(script, "layout", layout);
    if (IntParam(params, "apply", 0) && dev != g_appliedDevice) {
        *tp = layout;
        g_appliedDevice = dev;
        Log("button prompts: now %s", dev == 0 ? "keyboard and mouse" : layout == 1 ? "controller (PlayStation)" : "controller (Xbox)");
        return true;
    }
    return dev != g_appliedDevice;
}
// THUGRECOMP_ButtonText action=<ollie|grab|flip|grind|pause|select|l1|r1|l2|r2|l3|r3>   (a bindable action)
//                       or pad=<a|b|x|y|lb|rb|lt|rt|l3|r3|start|back> [key="F8"]   (a fixed pad button / keyboard key)
//   -> text = what to show for it on the device the prompts show now: the bound key's name on keyboard, the bound
//   button's glyph on a controller ( codes draw as Xbox or PlayStation buttons, following Swap A/B and X/Y).
static int SwapAB(int code) {
    if (!g_abSwap) return code;
    switch (code) { case 11: return 12; case 12: return 11; case 13: return 14; case 14: return 13; }
    return code;
}
static const char* PadGlyph(int code) {   // Xbox-layout button code (PadName numbering) -> glyph token
    switch (code) {
    case 11: return "\\b3"; case 12: return "\\b2"; case 13: return "\\b1"; case 14: return "\\b0";
    case 15: return "\\bg"; case 16: return "\\bh"; case 17: return "\\b9"; case 18: return "\\b8";
    case 19: return "\\bk"; case 20: return "\\bl"; case 21: case 90: return "\\be"; case 22: case 91: return "\\bf";
    }
    return nullptr;
}
static bool __cdecl CF_ButtonText(void* params, void* script) {
    static const char* kActions[] = { "ollie", "grab", "flip", "grind", "pause", "select", "l1", "r1", "l2", "r2", "l3", "r3" };
    static const char* kPads[] = { "a", "b", "x", "y", "lb", "rb", "back", "start", "l3", "r3", "lt", "rt" };
    const char* action = nullptr; const char* pad = nullptr; const char* key = nullptr;
    GetStringParam(params, "action", &action); GetStringParam(params, "pad", &pad); GetStringParam(params, "key", &key);
    // action / pad are usually written as names (checksums) in QB: action = ollie, pad = y
    typedef bool (__thiscall* GetSumFn)(void*, DWORD, DWORD*, bool);
    DWORD actSum = 0, padSum = 0;
    ((GetSumFn)0x476950)(params, QbKey("action"), &actSum, false);
    ((GetSumFn)0x476950)(params, QbKey("pad"), &padSum, false);
    if (g_appliedDevice < 0) { TpCtrlLayout(); g_appliedDevice = g_launcherLayout == 0 ? 0 : 1; }
    int forceDev = IntParam(params, "dev", -1);   // dev=0 keyboard / 1 controller: that device, whatever is on screen
    bool onPad = forceDev >= 0 ? forceDev == 1 : g_appliedDevice == 1;
    char out[64] = "";
    int slot = -1, padCode = -1;
    for (int i = 0; i < 12; ++i) if ((action && !_stricmp(action, kActions[i])) || (actSum && actSum == QbKey(kActions[i]))) slot = 8 + i;
    for (int i = 0; i < 12; ++i) if ((pad && !_stricmp(pad, kPads[i])) || (padSum && padSum == QbKey(kPads[i]))) padCode = 11 + i;
    bool padGiven = pad || padSum;
    if (slot >= 0) {
        if (onPad) {
            int code = ((int*)kPad0Binds)[slot];
            const char* g = PadGlyph(SwapAB(code));
            if (g) strcpy(out, g); else PadName(code, out, sizeof out);
        } else KeyName(((int*)kKb0Binds)[slot], out, sizeof out);
    } else if (padGiven && padCode >= 0 && (onPad || !key)) {
        const char* g = PadGlyph(SwapAB(padCode));
        if (g) strcpy(out, g);
    } else if (key) {
        _snprintf(out, sizeof out, "%s", key); out[sizeof out - 1] = 0;
    } else return false;
    RetStr(script, "text", out);
    return true;
}
// THUGRECOMP_BindReset dev= -> that device back to its default layout
static bool __cdecl CF_BindReset(void* params, void*) {
    int dev = IntParam(params, "dev", 0);
    if (!g_bindsSaved) return false;
    for (int i = 0; i < 24; ++i) (dev ? g_padOvr : g_kbOvr)[i] = kNoOvr;
    ApplyBindings();
    SaveBindOverrides();
    return true;
}

// THUGRECOMP_PadPressed button="y" -> true once per press of that controller button (Xbox names; Y = PlayStation triangle)
static bool __cdecl CF_PadPressed(void* params, void*) {
    const char* name = nullptr;
    GetStringParam(params, "button", &name);
    if (!name) return false;
    static DWORD prev;
    for (int i = 0; i < B_COUNT; ++i) {
        if (_stricmp(name, kButtonNames[i])) continue;
        DWORD now = (DWORD)g_padButtons, bit = 1u << i;
        bool pressed = (now & bit) && !(prev & bit);
        prev = (prev & ~bit) | (now & bit);
        return pressed;
    }
    return false;
}
// THUGRECOMP_PadHeld button="y" -> true while that controller button is down
static bool __cdecl CF_PadHeld(void* params, void*) {
    const char* name = nullptr;
    GetStringParam(params, "button", &name);
    if (!name) return false;
    for (int i = 0; i < B_COUNT; ++i)
        if (!_stricmp(name, kButtonNames[i])) return (((DWORD)g_padButtons >> i) & 1) != 0;
    return false;
}
}  // namespace padhub

static void InstallPadHubHooks() { padhub::InstallAtStartup(); }
