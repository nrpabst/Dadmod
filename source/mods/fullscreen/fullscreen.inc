// Alt+Enter fullscreen toggle and the live Display menu (Noah 2026-11-20: "can we make alt+enter to toggle
// fullscreen work with dadmod?"; then "can we make fullscreen actually just borderless windowed and can it apply
// immediately? the resolution should apply immediately too" + "we should have a confirm button in the menu").
// Our own code, no server or Kali needed.
// - "Fullscreen" is a borderless window that covers the whole monitor the game is on; Windows stretches the game's
//   picture to it, so switching needs no device reset.
// - Resolution: the engine's own device-reset path does it live. We change the backbuffer size in its present params
//   (0x786A7C: +0 width, +4 height, +0x20 Windowed, +0x30 refresh) and set its reset flag 0x786AB4; the main loop
//   0x44EEF0 releases its resources, Resets, rebuilds them and 0x4D8420 copies the new size into the screen struct
//   (0x786D6C width, 0x786D70 height). The 2D menu mapping (0x786D80 x scale, 0x786D84 y scale, 0x786D88 x offset,
//   0x786D8C y offset; set once at startup and by thugpro.dll's widescreen code) is scaled by the same ratio.
// - THUG Pro's own exclusive fullscreen (launcher setting windowed_mode=0) is left the first time anything changes:
//   the same reset as windowed. The menu writes windowed_mode=1 so later starts are windowed (then borderless if
//   dadmod\fullscreen.ini says fullscreen=1), and the sizes into width/height/window_width/window_height.
// - Display menu: Display mode and Resolution only pick values; Apply makes them happen, then "Keep" must be pressed
//   within kConfirmSec seconds or everything goes back (done here, so it works even if the menu is closed).
// - Alt+Enter: WndProc 0x4E16B0 sends WM_SYSKEYDOWN to DefWindowProc (only F10 is eaten), so it did nothing before.
//   The DirectInput keyboard is read into 0x7D6670 by 0x5F3400 (one caller, 0x5F5BCD): we wrap that call and hide
//   Enter (DIK 0x1C / 0x9C) while Alt is held and after Alt+Enter until Enter is let go (never also presses Accept).
#include <windows.h>
#include <stdio.h>
#include <string>

namespace fullscreen {

static const DWORD kGameWnd   = 0x7D6A28;   // HWND of the game window
static const DWORD kPresent   = 0x786A7C;   // D3DPRESENT_PARAMETERS the engine Resets with
static const DWORD kResetFlag = 0x786AB4;   // main loop resets the device while this byte is set
static const DWORD kScreenW   = 0x786D6C;   // engine screen size (copied from the present params after a reset)
static const DWORD kMenuXs    = 0x786D80;   // 640x480 menu space -> pixels: x scale, y scale, x offset, y offset
static const DWORD kKeyState  = 0x7D6670;   // engine's DirectInput keyboard state, 256 bytes
static const DWORD kKbRead    = 0x5F3400;   // reads it
static const DWORD kKbCall    = 0x5F5BCD;   // the only call to it (e8 rel32)
static const UINT  kMsgApply  = WM_APP + 0x3D1;   // apply g_want* on the window's thread
static const int   kConfirmSec = 15;

static WNDPROC g_prev;
static HWND g_wnd;
static bool g_full;                 // borderless fullscreen right now
static LONG_PTR g_savedStyle, g_savedEx;   // the framed window's styles
static RECT g_savedRect;            // the framed window's position and size
static bool g_haveSaved;
static int g_winW, g_winH;          // the size the game draws at in a window (fullscreen always uses the monitor's)
static volatile LONG g_holdEnter;   // hide Enter until it is let go
static bool g_sizing;               // we are moving/sizing the window ourselves
// thugpro.dll's window procedure snaps the window back to "picture + frame" on every WM_SIZE (0x10038886 ->
// 0x100386E0), which made the borderless window 1940x1123 on a 1920x1080 monitor (Noah 2026-11-21: bottom cut off).
// While borderless, and while we size it, WM_SIZE does not reach it.
// thugpro.dll also keeps its own copies of the menu x / y scale (thugpro+0x8CCA0 / +0x8CCA4) and points the engine's
// sprite drawing at them (it patches the operands at 0x4D00E1 / 0x4D0096): after a live resolution change those
// must be scaled too, or boxes and the description panel are drawn at the old size (Noah 2026-11-21, broken HUD).
static const DWORD kTpXsRef = 0x4D00E1, kTpYsRef = 0x4D0096;
static float* TpScale(DWORD ref) {
    HMODULE tp = GetModuleHandleA("thugpro.dll");
    if (!tp || IsBadReadPtr((void*)ref, 4)) return nullptr;
    DWORD a = *(DWORD*)ref, lo = (DWORD)tp;
    IMAGE_NT_HEADERS* nt = (IMAGE_NT_HEADERS*)(lo + ((IMAGE_DOS_HEADER*)tp)->e_lfanew);
    if (a < lo || a >= lo + nt->OptionalHeader.SizeOfImage || IsBadWritePtr((void*)a, 4)) return nullptr;
    return (float*)a;
}

// a reset in flight: what the window should become once it is done
static volatile LONG g_waitReset;
static int g_rW, g_rH;              // size asked for
static float g_oXs, g_oYs; static int g_oXo, g_oYo, g_oW, g_oH;   // menu mapping before the reset
static bool g_afterFull;            // borderless after the reset

// Display menu: picked (pending) values, and what to go back to while waiting for Keep
static bool g_pendInit;
static bool g_pendFull; static int g_pendW, g_pendH;
static volatile LONG g_confirmUntil;        // GetTickCount when it reverts, 0 = nothing to confirm
static bool g_oldFull; static int g_oldW, g_oldH;
static volatile LONG g_wantFull, g_wantW, g_wantH;   // for kMsgApply
static volatile LONG g_reverted;            // set when the timer put things back (menu refreshes its rows)

static void Log(const char* fmt, ...) {
    char buf[300]; va_list a; va_start(a, fmt); _vsnprintf(buf, sizeof buf - 1, fmt, a); va_end(a); buf[sizeof buf - 1] = 0;
    mmenu::Log("fullscreen: %s", buf);
}
static std::string IniPath() {
    char exe[MAX_PATH] = { 0 };
    GetModuleFileNameA(nullptr, exe, MAX_PATH);
    std::string d(exe);
    size_t s = d.find_last_of("\\/");
    d = (s == std::string::npos ? std::string(".") : d.substr(0, s)) + "\\dadmod";
    CreateDirectoryA(d.c_str(), nullptr);
    return d + "\\fullscreen.ini";
}
static bool SavedFull() { return GetPrivateProfileIntA("fullscreen", "fullscreen", 0, IniPath().c_str()) != 0; }
static void SaveFull(bool on) {
    std::string p = IniPath();
    WritePrivateProfileStringA("fullscreen", "fullscreen", on ? "1" : "0", p.c_str());
}
static volatile DWORD& PP(int off) { return *(volatile DWORD*)(kPresent + off); }
static bool EngineWindowed() { return PP(0x20) != 0; }
static int CurW() { return (int)PP(0); }
static int CurH() { return (int)PP(4); }

// the monitor the game window is on
static bool MonitorSize(HWND h, int* w, int* hh) {
    MONITORINFO mi = { sizeof mi };
    if (!h || !GetMonitorInfoA(MonitorFromWindow(h, MONITOR_DEFAULTTONEAREST), &mi)) return false;
    *w = mi.rcMonitor.right - mi.rcMonitor.left; *hh = mi.rcMonitor.bottom - mi.rcMonitor.top;
    return *w > 0 && *hh > 0;
}
static void SaveFramed(HWND h) {
    g_savedStyle = GetWindowLongPtrA(h, GWL_STYLE);
    g_savedEx = GetWindowLongPtrA(h, GWL_EXSTYLE);
    GetWindowRect(h, &g_savedRect);
    g_haveSaved = true;
}
static void GoBorderless(HWND h) {
    if (!g_full) SaveFramed(h);
    MONITORINFO mi = { sizeof mi };
    if (!GetMonitorInfoA(MonitorFromWindow(h, MONITOR_DEFAULTTONEAREST), &mi)) return;
    SetWindowLongPtrA(h, GWL_STYLE, (g_savedStyle & ~(LONG_PTR)(WS_OVERLAPPEDWINDOW)) | WS_POPUP | WS_VISIBLE);
    SetWindowLongPtrA(h, GWL_EXSTYLE, g_savedEx & ~(LONG_PTR)(WS_EX_DLGMODALFRAME | WS_EX_WINDOWEDGE | WS_EX_CLIENTEDGE | WS_EX_STATICEDGE | WS_EX_TOPMOST));
    const RECT& r = mi.rcMonitor;
    g_sizing = true;
    SetWindowPos(h, HWND_NOTOPMOST, r.left, r.top, r.right - r.left, r.bottom - r.top, SWP_NOOWNERZORDER | SWP_FRAMECHANGED | SWP_SHOWWINDOW);
    MoveWindow(h, r.left, r.top, r.right - r.left, r.bottom - r.top, TRUE);   // thugpro.dll's SetWindowPos detour re-centers
    g_sizing = false;
    g_full = true;
    RECT cr; GetClientRect(h, &cr);
    if (cr.right != r.right - r.left || cr.bottom != r.bottom - r.top) Log("borderless client is %ldx%ld, not the monitor's size", cr.right, cr.bottom);
    Log("borderless %ldx%ld at %ld,%ld (game draws %dx%d)", r.right - r.left, r.bottom - r.top, r.left, r.top, CurW(), CurH());
}
// framed window whose inside is cw x ch, kept where it was (pulled back onto the screen if it would stick out)
static void GoWindow(HWND h, int cw, int ch) {
    LONG_PTR st, ex;
    if (g_haveSaved) { st = g_savedStyle; ex = g_savedEx; }
    else {   // never had a frame (started in exclusive fullscreen)
        st = (GetWindowLongPtrA(h, GWL_STYLE) & ~(LONG_PTR)WS_POPUP) | WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX | WS_VISIBLE;
        ex = GetWindowLongPtrA(h, GWL_EXSTYLE) & ~(LONG_PTR)WS_EX_TOPMOST;
    }
    if (st & WS_POPUP && !(st & WS_CAPTION)) st = (st & ~(LONG_PTR)WS_POPUP) | WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX;
    SetWindowLongPtrA(h, GWL_STYLE, st | WS_VISIBLE);
    SetWindowLongPtrA(h, GWL_EXSTYLE, ex & ~(LONG_PTR)WS_EX_TOPMOST);
    RECT r = { 0, 0, cw > 0 ? cw : 1280, ch > 0 ? ch : 720 };
    AdjustWindowRectEx(&r, (DWORD)(st | WS_VISIBLE), FALSE, (DWORD)(ex & ~(LONG_PTR)WS_EX_TOPMOST));
    int ww = r.right - r.left, wh = r.bottom - r.top;
    MONITORINFO mi = { sizeof mi };
    GetMonitorInfoA(MonitorFromWindow(h, MONITOR_DEFAULTTONEAREST), &mi);
    const RECT& wa = mi.rcWork;
    int x, y;
    if (g_haveSaved) { x = g_savedRect.left; y = g_savedRect.top; }
    else { x = wa.left + ((wa.right - wa.left) - ww) / 2; y = wa.top + ((wa.bottom - wa.top) - wh) / 2; }
    if (x + ww > wa.right) x = wa.right - ww;
    if (y + wh > wa.bottom) y = wa.bottom - wh;
    if (x < wa.left) x = wa.left;
    if (y < wa.top) y = wa.top;
    g_sizing = true;
    SetWindowPos(h, HWND_NOTOPMOST, x, y, ww, wh, SWP_NOOWNERZORDER | SWP_FRAMECHANGED | SWP_SHOWWINDOW);
    MoveWindow(h, x, y, ww, wh, TRUE);
    g_sizing = false;
    g_full = false;
    SaveFramed(h);
    Log("windowed %dx%d", cw, ch);
}

// window thread: make it full (borderless) or framed at w x h; resets the device when the size changes or the
// engine is still in exclusive fullscreen
static void ApplyNow(HWND h, bool full, int w, int hh) {
    if (g_waitReset) return;
    if (full) MonitorSize(h, &w, &hh);                 // fullscreen draws at the monitor's own size (sharp)
    else {
        if (w <= 0 || hh <= 0) { w = g_winW; hh = g_winH; }
        if (w > 0 && hh > 0) { g_winW = w; g_winH = hh; }
    }
    bool resize = w > 0 && hh > 0 && (w != CurW() || hh != CurH());
    if (resize || !EngineWindowed()) {
        if (!resize) { w = CurW(); hh = CurH(); }
        g_oXs = *(volatile float*)(kMenuXs); g_oYs = *(volatile float*)(kMenuXs + 4);
        g_oXo = *(volatile int*)(kMenuXs + 8); g_oYo = *(volatile int*)(kMenuXs + 12);
        g_oW = *(volatile int*)kScreenW; g_oH = *(volatile int*)(kScreenW + 4);
        g_rW = w; g_rH = hh; g_afterFull = full;
        if (!full && EngineWindowed()) GoWindow(h, w, hh);   // the window takes its new size now, the picture follows
        PP(0) = (DWORD)w; PP(4) = (DWORD)hh;
        PP(0x20) = 1;      // Windowed
        PP(0x30) = 0;      // FullScreen_RefreshRateInHz must be 0 when windowed
        InterlockedExchange(&g_waitReset, 1);
        *(volatile BYTE*)kResetFlag = 1;
        Log("device reset asked: %dx%d, %s", w, hh, full ? "fullscreen" : "windowed");
        return;
    }
    if (full) { if (!g_full) GoBorderless(h); }
    else if (g_full || !g_haveSaved) GoWindow(h, w > 0 ? w : CurW(), hh > 0 ? hh : CurH());
}
// watcher thread, once the engine's reset is done: fix the menu mapping, then the window on its own thread
static void AfterReset(HWND h) {
    int nw = *(volatile int*)kScreenW, nh = *(volatile int*)(kScreenW + 4);
    if (g_oW > 0 && g_oH > 0 && nw > 0 && nh > 0 && (nw != g_oW || nh != g_oH)) {
        float fx = (float)nw / g_oW, fy = (float)nh / g_oH;
        *(volatile float*)(kMenuXs) = g_oXs * fx;
        *(volatile float*)(kMenuXs + 4) = g_oYs * fy;
        *(volatile int*)(kMenuXs + 8) = (int)(g_oXo * fx + 0.5f);
        *(volatile int*)(kMenuXs + 12) = (int)(g_oYo * fy + 0.5f);
        Log("menu mapping %dx%d -> %dx%d: scale %.4f x %.4f, offset %d,%d", g_oW, g_oH, nw, nh,
            g_oXs * fx, g_oYs * fy, (int)(g_oXo * fx + 0.5f), (int)(g_oYo * fy + 0.5f));
        float* tx = TpScale(kTpXsRef); float* ty = TpScale(kTpYsRef);
        if (tx && ty) {
            float ox = *tx, oy = *ty;
            *tx = ox * fx; *ty = oy * fy;
            Log("thugpro.dll sprite scale %.4f x %.4f -> %.4f x %.4f", ox, oy, *tx, *ty);
        } else Log("thugpro.dll sprite scale not found");
    }
    Log("device reset done, now %dx%d", nw, nh);
    InterlockedExchange(&g_wantFull, g_afterFull ? 1 : 0);
    InterlockedExchange(&g_wantW, nw); InterlockedExchange(&g_wantH, nh);
    PostMessageA(h, kMsgApply, 0, 0);
}

static void ToggleAltEnter(HWND h) {
    bool full = !(g_full && EngineWindowed());
    if (!EngineWindowed()) full = false;          // out of exclusive fullscreen = a normal window first
    ApplyNow(h, full, 0, 0);                      // fullscreen at the monitor's size, the window at its own
    SaveFull(full);
    g_pendInit = false;                           // the Display menu shows what is on screen now
}

static LRESULT CALLBACK WndProc(HWND h, UINT m, WPARAM w, LPARAM l) {
    if ((m == WM_SYSKEYDOWN || m == WM_KEYDOWN) && w == VK_RETURN && (GetKeyState(VK_MENU) & 0x8000)) {
        InterlockedExchange(&g_holdEnter, 1);
        if (!(l & (1 << 30))) ToggleAltEnter(h);  // not a key repeat
        return 0;
    }
    if ((m == WM_SYSCHAR || m == WM_CHAR) && (w == '\r' || w == '\n') && (GetKeyState(VK_MENU) & 0x8000)) return 0;   // no beep
    if ((m == WM_SYSKEYUP || m == WM_KEYUP) && w == VK_RETURN && g_holdEnter) return 0;
    if (m == WM_SIZE && (g_full || g_sizing)) return DefWindowProcA(h, m, w, l);
    if (m == kMsgApply) {
        ApplyNow(h, g_wantFull != 0, (int)g_wantW, (int)g_wantH);
        return 0;
    }
    WNDPROC prev = g_prev;
    if (!prev) return DefWindowProcA(h, m, w, l);
    return IsWindowUnicode(h) ? CallWindowProcW(prev, h, m, w, l) : CallWindowProcA(prev, h, m, w, l);
}
static void PostApply(bool full, int w, int h) {
    HWND hw = g_wnd;
    if (!hw) return;
    InterlockedExchange(&g_wantFull, full ? 1 : 0);
    InterlockedExchange(&g_wantW, w); InterlockedExchange(&g_wantH, h);
    PostMessageA(hw, kMsgApply, 0, 0);
}

// wraps the engine's keyboard read: Enter is hidden while Alt is down and after Alt+Enter until it is let go
static void __cdecl KbReadWrap() {
    ((void(__cdecl*)())kKbRead)();
    BYTE* k = (BYTE*)kKeyState;
    bool alt = ((k[0x38] | k[0xB8]) & 0x80) != 0;
    bool enter = ((k[0x1C] | k[0x9C]) & 0x80) != 0;
    if (alt && enter) InterlockedExchange(&g_holdEnter, 1);
    if (g_holdEnter && !enter) InterlockedExchange(&g_holdEnter, 0);
    if (alt || g_holdEnter) { k[0x1C] = 0; k[0x9C] = 0; }
    if (padhub::HideDpad()) { k[0xC8] = k[0xD0] = k[0xCB] = k[0xCD] = 0; }  // Lamp Editor: arrows pick lamps, not move the camera
}
static bool PatchCall(DWORD at, void* to) {
    BYTE* p = (BYTE*)at;
    if (p[0] != 0xE8 || (DWORD)(at + 5 + *(LONG*)(p + 1)) != kKbRead) return false;
    DWORD old;
    if (!VirtualProtect(p, 5, PAGE_EXECUTE_READWRITE, &old)) return false;
    *(LONG*)(p + 1) = (LONG)((DWORD)to - (at + 5));
    VirtualProtect(p, 5, old, &old);
    FlushInstructionCache(GetCurrentProcess(), p, 5);
    return true;
}

// waits for the game window, chains its window procedure, applies the saved choice, finishes resets and runs the
// Keep countdown
static DWORD WINAPI Watch(void*) {
    for (;;) {
        Sleep(100);
        HWND h = *(volatile HWND*)kGameWnd;
        if (!h || !IsWindow(h)) continue;
        if (h != g_wnd) {
            if (!CurW() || !CurH()) continue;     // the device isn't made yet: its present params are still empty
            bool uni = IsWindowUnicode(h) != 0;
            LONG_PTR cur = uni ? GetWindowLongPtrW(h, GWLP_WNDPROC) : GetWindowLongPtrA(h, GWLP_WNDPROC);
            if (!cur || cur == (LONG_PTR)WndProc) continue;
            g_prev = (WNDPROC)cur;
            LONG_PTR old = uni ? SetWindowLongPtrW(h, GWLP_WNDPROC, (LONG_PTR)WndProc) : SetWindowLongPtrA(h, GWLP_WNDPROC, (LONG_PTR)WndProc);
            if (!old) { g_prev = nullptr; continue; }
            g_prev = (WNDPROC)old;
            g_wnd = h; g_full = false; g_haveSaved = false;
            Log("game window hooked (%s %dx%d)", EngineWindowed() ? "windowed" : "exclusive fullscreen", CurW(), CurH());
            if (EngineWindowed()) { SaveFramed(h); g_winW = CurW(); g_winH = CurH(); if (SavedFull()) PostApply(true, 0, 0); }
            else { g_winW = (int)mmenu::DispGet("window_width", 0); g_winH = (int)mmenu::DispGet("window_height", 0);
                   if (g_winW <= 0 || g_winH <= 0) { g_winW = CurW(); g_winH = CurH(); } }
        }
        if (g_waitReset && !*(volatile BYTE*)kResetFlag && EngineWindowed()) {
            InterlockedExchange(&g_waitReset, 0);
            AfterReset(h);
        }
        LONG until = g_confirmUntil;
        if (until && (LONG)(GetTickCount() - (DWORD)until) >= 0 && !g_waitReset) {
            InterlockedExchange(&g_confirmUntil, 0);
            Log("not kept: going back to %s %dx%d", g_oldFull ? "fullscreen" : "windowed", g_oldW, g_oldH);
            SaveFull(g_oldFull);
            mmenu::DispSetSize(g_oldW, g_oldH);
            g_pendFull = g_oldFull; g_pendW = g_oldW; g_pendH = g_oldH; g_pendInit = true;
            InterlockedExchange(&g_reverted, 1);
            PostApply(g_oldFull, g_oldW, g_oldH);
        }
    }
}

// ---- THUGRECOMP_DisplayLive key="mode"|"res"|"apply" step=N -> text (Dadmod > Graphics > Display)
//   mode / res: step picks the next value (nothing changes on screen yet); text = the picked value
//   apply: step=1 applies the picked values (or, while waiting, keeps them); text = what the row shows,
//          wait = seconds left to press Keep (0 = nothing to keep), changed = picked differs from now,
//          reverted = the timer just put things back (rows should be refreshed; cleared by reading it)
static bool NowFull() { return g_full && EngineWindowed(); }
static void PendSync() {
    if (g_pendInit) return;
    g_pendFull = NowFull(); g_pendW = g_winW; g_pendH = g_winH;
    if (g_pendW <= 0 || g_pendH <= 0) { g_pendW = (int)mmenu::DispGet("width", 1280); g_pendH = (int)mmenu::DispGet("height", 720); }
    g_pendInit = true;
}
// sizes offered: what the monitor can show; in a window only the ones that fit its work area
static std::vector<mmenu::DispMode> Sizes(bool full) {
    std::vector<mmenu::DispMode> v = mmenu::DispModes(!full);
    return v;
}
// V-sync (Noah 2026-11-21: "vsync should go in display and be applied with the apply button"): picked like the other
// Display rows; Apply stores gfx_vsync and has the engine reset its device, where gfx.inc AdjustPP sets the interval.
static int g_pendVs = -1;
static int VsyncNow() { int v = 0; gfx::GetKey("gfx_vsync", &v); return v < 0 || v > 2 ? 0 : v; }
static bool __cdecl CF_DisplayLive(void* params, void* script) {
    const char* key = nullptr;
    GetStringParam(params, "key", &key);
    if (!key) return false;
    int step = IntParam(params, "step", 0);
    PendSync();
    if (g_pendVs < 0) g_pendVs = VsyncNow();
    char buf[64];
    if (!strcmp(key, "vsync")) {
        static const char* const kVs[] = {"Game default", "On", "Off"};
        if (step) g_pendVs = (g_pendVs + (step > 0 ? 1 : 2)) % 3;
        RetStr(script, "text", kVs[g_pendVs]);
        return true;
    }
    if (!strcmp(key, "mode")) {
        if (step) g_pendFull = !g_pendFull;
        RetStr(script, "text", g_pendFull ? "Fullscreen" : "Windowed");
        return true;
    }
    if (!strcmp(key, "res")) {
        int mw, mh;
        if (g_pendFull && MonitorSize(g_wnd, &mw, &mh)) {   // fullscreen: always the monitor's size
            sprintf(buf, "%dx%d (monitor)", mw, mh);
            RetStr(script, "text", buf);
            return true;
        }
        if (step) {
            std::vector<mmenu::DispMode> v = Sizes(false);
            int at = -1;
            for (int i = 0; i < (int)v.size(); i++) if (v[i].w == g_pendW && v[i].h == g_pendH) at = i;
            if (at < 0) {   // a size not in the list: start from the nearest one
                at = 0;
                for (int i = 0; i < (int)v.size(); i++) if (v[i].w <= g_pendW) at = i;
                if (step < 0) step = 0;
            }
            at = (at + step + (int)v.size()) % (int)v.size();
            g_pendW = v[at].w; g_pendH = v[at].h;
        }
        sprintf(buf, "%dx%d", g_pendW, g_pendH);
        RetStr(script, "text", buf);
        return true;
    }
    if (!strcmp(key, "apply")) {
        bool changed = g_pendFull != NowFull() || (!g_pendFull && (g_pendW != CurW() || g_pendH != CurH()));
        bool vsChanged = g_pendVs != VsyncNow();
        if (step && vsChanged && !g_confirmUntil) {
            gfx::SetKey("gfx_vsync", g_pendVs);
            if (!g_waitReset) *(volatile BYTE*)kResetFlag = 1;   // the engine resets its device; AdjustPP sets the interval
            Log("apply v-sync %d", g_pendVs);
            vsChanged = false;
        }
        changed = changed || vsChanged;
        if (step) {
            if (g_confirmUntil) {
                InterlockedExchange(&g_confirmUntil, 0);
                Log("kept %s %dx%d", NowFull() ? "fullscreen" : "windowed", CurW(), CurH());
            } else if (changed && g_wnd && !g_waitReset) {
                g_oldFull = NowFull(); g_oldW = g_winW; g_oldH = g_winH;
                SaveFull(g_pendFull);
                mmenu::DispSet("windowed_mode", 1);
                mmenu::DispSetSize(g_pendW, g_pendH);
                Log("apply %s %dx%d (was %s %dx%d)", g_pendFull ? "fullscreen" : "windowed", g_pendW, g_pendH,
                    g_oldFull ? "fullscreen" : "windowed", g_oldW, g_oldH);
                InterlockedExchange(&g_confirmUntil, (LONG)(GetTickCount() + kConfirmSec * 1000));
                PostApply(g_pendFull, g_pendW, g_pendH);
                changed = false;
            }
        }
        int wait = 0;
        LONG until = g_confirmUntil;
        if (until) { LONG ms = (LONG)((DWORD)until - GetTickCount()); wait = ms > 0 ? (ms + 999) / 1000 : 0; }
        if (wait) sprintf(buf, "Keep? %ds", wait);
        else strcpy(buf, changed ? "Press to apply" : "No changes");
        RetStr(script, "text", buf);
        RetInt(script, "wait", wait);
        RetInt(script, "changed", changed ? 1 : 0);
        RetInt(script, "reverted", InterlockedExchange(&g_reverted, 0) ? 1 : 0);
        return true;
    }
    return false;
}

static void Install() {
    if (PatchCall(kKbCall, (void*)&KbReadWrap)) Log("keyboard read wrapped (Enter hidden while Alt is held)");
    else Log("keyboard read not wrapped (unexpected code at 0x5F5BCD)");
    HANDLE t = CreateThread(nullptr, 0, Watch, nullptr, 0, nullptr);
    if (t) CloseHandle(t);
}

}  // namespace fullscreen
