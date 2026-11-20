// Sound logger (Noah 2026-11-19: "create a sound logger", to chase a sound glitch in stock THUG Pro).
// While Dadmod > Graphics > Sound > "Sound logger" is On (gfx.ini gfx_soundlog = 1), every sound the game plays is
// written to <exe>\dadmod\soundlog.txt with a time stamp:
//   PLAY / FAIL  every sound effect the engine starts (Sfx PlaySound 0x47BD20, all 9 callers), with volume, pitch,
//                the voice it got, how many of the voices were busy, and who asked (script, object, terrain, skater code)
//   STEAL        all voices were busy, so the engine cut off the sound playing on the oldest voice to start the new one
//   END          a voice finished (the engine noticed the DirectSound buffer stopped), with how long it played
//   SCRIPT       script calls to the stream/music/sound CFuncs (PlayStream, StopStream, SetSoundParams, ...) with params
//   DSOUND       any DirectSound call that failed (buffer create, Play, Lock) or a lost buffer
//   STATUS       every 10 s: busy voices, loaded sounds (permanent / level), sound system state
// Sound names come from dadmod\soundlog_names.txt (mods/soundlog/gen_names.py); unknown ones print as #XXXXXXXX.
// Engine layout (Ghidra 2026-11-19): voices at 0x6F85C8 stride 0x18 (+0 IDirectSoundBuffer*, +0x10 byte busy,
// +0x14 wave data), voice count 0x6F8A50 (DSCAPS free static buffers - 4, max 48), round robin cursor 0x6F8A54,
// handle per voice 0x6F7A68 stride 0x3C, loaded sounds 7 dwords each: permanent 0x6F4268 (count 0x6F85B4),
// level 0x6F5E68 (count 0x6F85B8); IDirectSound8* at 0x7D6A38; 0x7CEFA8 = 2 or 6 means no sound.
// The voice picker 0x47C720 takes a free voice; when none is free it takes cursor+1 and 0x47D130 Stops what plays there.
// SOUNDLOG_LIVE (native/live_soundlog): built as a small DLL loaded into a running game; there the script CFuncs are
// already registered, so the SCRIPT lines only appear after a restart with the full binkw32.dll.
#include <windows.h>
#include <intrin.h>
#include <stdio.h>
#include <math.h>
#include <string>
#include <unordered_map>

namespace soundlog {

static CRITICAL_SECTION g_cs;
static HANDLE g_file = INVALID_HANDLE_VALUE;
static volatile LONG g_on = 0;
static DWORD g_t0;
static int g_lines;
static std::unordered_map<DWORD, std::string> g_names;
static bool g_namesLoaded;
static int g_sfxHooks, g_pauseHooks, g_cfuncHooks;

static std::string DadmodFile(const char* name) {
    char exe[MAX_PATH] = {0};
    GetModuleFileNameA(nullptr, exe, MAX_PATH);
    std::string d(exe);
    size_t s = d.find_last_of("\\/");
    d = (s == std::string::npos ? std::string(".") : d.substr(0, s)) + "\\dadmod";
    CreateDirectoryA(d.c_str(), nullptr);
    return d + "\\" + name;
}

static void LoadNames() {
    if (g_namesLoaded) return;
    g_namesLoaded = true;
    FILE* f = fopen(DadmodFile("soundlog_names.txt").c_str(), "r");
    if (!f) return;
    char line[256];
    while (fgets(line, sizeof line, f)) {
        unsigned c; char n[200];
        if (sscanf(line, "%x %199s", &c, n) == 2) g_names.emplace((DWORD)c, n);
    }
    fclose(f);
}
static std::string Name(DWORD c) {
    auto it = g_names.find(c);
    if (it != g_names.end()) return it->second;
    char b[16]; sprintf(b, "#%08lX", c);
    return b;
}

static void WriteLine(const char* s) {
    if (g_file == INVALID_HANDLE_VALUE) {
        g_file = CreateFileA(DadmodFile("soundlog.txt").c_str(), FILE_APPEND_DATA, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
                             nullptr, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
        if (g_file == INVALID_HANDLE_VALUE) return;
    }
    DWORD w; WriteFile(g_file, s, (DWORD)strlen(s), &w, nullptr);
    if (++g_lines % 500 == 0 && GetFileSize(g_file, nullptr) > 20u * 1024 * 1024) {   // keep it to ~40 MB: one old file
        CloseHandle(g_file); g_file = INVALID_HANDLE_VALUE;
        MoveFileExA(DadmodFile("soundlog.txt").c_str(), DadmodFile("soundlog.old.txt").c_str(), MOVEFILE_REPLACE_EXISTING);
    }
}
static void Log(const char* fmt, ...) {
    char msg[900];
    va_list ap; va_start(ap, fmt); _vsnprintf(msg, sizeof msg - 1, fmt, ap); va_end(ap);
    msg[sizeof msg - 1] = 0;
    SYSTEMTIME t; GetLocalTime(&t);
    char line[1000];
    _snprintf(line, sizeof line - 1, "%02d:%02d:%02d.%03d %9.3f  %s\r\n", t.wHour, t.wMinute, t.wSecond, t.wMilliseconds,
              (GetTickCount() - g_t0) / 1000.0, msg);
    line[sizeof line - 1] = 0;
    EnterCriticalSection(&g_cs);
    WriteLine(line);
    LeaveCriticalSection(&g_cs);
}

// ---------------------------------------------------------------- engine sound tables
static const DWORD kVoices = 0x6F85C8, kVoiceCount = 0x6F8A50, kCursor = 0x6F8A54, kHandles = 0x6F7A68;
static const DWORD kPermSounds = 0x6F4268, kPermCount = 0x6F85B4, kLevelSounds = 0x6F5E68, kLevelCount = 0x6F85B8;
static const DWORD kDevice = 0x7D6A38, kSoundState = 0x7CEFA8, kSfxPlay = 0x47BD20;
static const int kMaxVoices = 48;
static int VoiceCount() { int n = *(int*)kVoiceCount; return n < 0 ? 0 : n > kMaxVoices ? kMaxVoices : n; }
static bool VoiceBusy(int k) { return *(BYTE*)(kVoices + k * 0x18 + 0x10) != 0; }
static int BusyCount() { int b = 0, n = VoiceCount(); for (int k = 0; k < n; ++k) b += VoiceBusy(k); return b; }
static const char* Loaded(DWORD sum) {
    int n = *(int*)kPermCount;
    for (int i = 0; i < n && i < 1024; ++i) if (*(DWORD*)(kPermSounds + i * 28) == sum) return "permanent";
    n = *(int*)kLevelCount;
    for (int i = 0; i < n && i < 1024; ++i) if (*(DWORD*)(kLevelSounds + i * 28) == sum) return "level";
    return nullptr;
}

// what each voice is playing, as far as the logger saw it start
static DWORD g_vSum[kMaxVoices], g_vStart[kMaxVoices];
static const char* g_vWho[kMaxVoices];
static bool g_vTracked[kMaxVoices];

static const char* Caller(DWORD ret) {
    switch (ret) {
    case 0x44DD2B: return "script PlaySound";
    case 0x47C301: return "object sound";
    case 0x444E6B: return "terrain";
    case 0x43CB56: case 0x43CDE4: return "engine 43C";
    case 0x513EBA: return "skater 513";
    case 0x51B34C: case 0x51B5ED: return "skater 51B";
    case 0x575339: return "engine 575";
    }
    return "other";
}

// Teleporter sounds slider (Noah 2026-11-20: "we need a toggle for teleporter sounds. all sound toggles should kick in
// immediately"): gfx.ini gfx_telesfx 0..100 (Dadmod > Graphics > Sound > Teleporter sounds). The sounds the levels' teleporters
// and teleporting elevators play are scaled when they start (0 = not played); read every time, so a change applies to the
// very next teleport. Names from the level scripts: Oil Rig elevators (z_oi), elevator dings, Hawaii warp flush stream.
static DWORD Crc(const char* t) {
    DWORD c = 0xFFFFFFFF;
    for (; *t; ++t) {
        char ch = *t == '/' ? (char)0x5C : (char)tolower((unsigned char)*t);
        c ^= (BYTE)ch;
        for (int k = 0; k < 8; ++k) c = (c >> 1) ^ ((c & 1) ? 0xEDB88320 : 0);
    }
    return c;
}
static const char* kTeleNames[] = { "Elevator_Teleport1", "Elevator_Teleport2", "Elevator_Teleport3", "Elevator_Teleport4",
                                     "ElevatorDing", "VC_ElevatorDing02", "HI_WarpFlush" };
static bool IsTeleSound(DWORD sum) {
    static DWORD sums[sizeof kTeleNames / sizeof kTeleNames[0]];
    static bool init;
    if (!init) { for (int i = 0; i < (int)(sizeof sums / sizeof sums[0]); ++i) sums[i] = Crc(kTeleNames[i]); init = true; }
    for (DWORD x : sums) if (x == sum) return true;
    return false;
}
static int LevelPct() {
#ifndef SOUNDLOG_LIVE
    return gfx::V("gfx_levelsfx");
#else
    return 100;
#endif
}
static int TelePct() {
#ifndef SOUNDLOG_LIVE
    return gfx::V("gfx_telesfx");
#else
    return 100;
#endif
}

typedef DWORD (__thiscall* SfxPlayFn)(void*, DWORD, float*, float, DWORD, DWORD, DWORD);
static DWORD __fastcall SfxPlayHook(void* self, void*, DWORD sum, float* vol, float pitch, DWORD id, DWORD a5, DWORD a6) {
    SfxPlayFn orig = (SfxPlayFn)kSfxPlay;
    float scaled[2];
    if (IsTeleSound(sum)) {
        int pct = TelePct();
        if (pct <= 0) { if (g_on) Log("SKIP   %-28s teleporter sounds are off", Name(sum).c_str()); return 0; }
        if (pct < 100 && vol) { scaled[0] = vol[0] * pct / 100.0f; scaled[1] = vol[1] * pct / 100.0f; vol = scaled; }
    }
    if (!g_on) return orig(self, sum, vol, pitch, id, a5, a6);
    const char* who = Caller((DWORD)_ReturnAddress());
    int n = VoiceCount(), busy = BusyCount();
    int steal = -1;
    if (n > 0 && busy >= n) steal = (int)((*(DWORD*)kCursor + 1) % (DWORD)n);
    const char* where = Loaded(sum);
    float vl = vol ? vol[0] : -1, vr = vol ? vol[1] : -1;
    DWORD stolenSum = steal >= 0 && g_vTracked[steal] ? g_vSum[steal] : 0;
    DWORD stolenAge = steal >= 0 && g_vTracked[steal] ? GetTickCount() - g_vStart[steal] : 0;
    DWORD h = orig(self, sum, vol, pitch, id, a5, a6);
    std::string nm = Name(sum);
    std::string idn = id && id != sum ? " id=" + Name(id) : "";
    if (!h) {
        int state = *(int*)kSoundState;
        const char* why = !*(void**)kDevice ? "no sound device" : (state == 2 || state == 6) ? "sound system paused/off"
                        : !where ? "sound not loaded" : "no voice or DirectSound buffer failed";
        Log("FAIL   %-28s vol=%.0f/%.0f pitch=%.0f%s  from %s: %s (busy %d/%d)", nm.c_str(), vl, vr, pitch, idn.c_str(), who, why, busy, n);
        return h;
    }
    int voice = -1;
    for (int k = 0; k < n; ++k) if (*(DWORD*)(kHandles + k * 0x3C) == h) { voice = k; break; }
    if (steal >= 0 && voice == steal)
        Log("STEAL  voice %d: all %d voices busy, cut off %s (playing %lu ms) to start %s", steal, n,
            stolenSum ? Name(stolenSum).c_str() : "(started before logging)", stolenAge, nm.c_str());
    Log("PLAY   %-28s vol=%.0f/%.0f pitch=%.0f%s  from %s -> voice %d (busy %d/%d, %s)", nm.c_str(), vl, vr, pitch, idn.c_str(),
        who, voice, BusyCount(), n, where ? where : "?");
    if (voice >= 0) { g_vSum[voice] = sum; g_vStart[voice] = GetTickCount(); g_vWho[voice] = who; g_vTracked[voice] = true; }
    return h;
}

static const DWORD kSfxCallers[] = { 0x47C2FC, 0x43CB51, 0x43CDDF, 0x444E66, 0x44DD26, 0x513EB5, 0x51B347, 0x51B5E8, 0x575334 };
static int PatchSfxCallers() {
    int ok = 0;
    for (DWORD at : kSfxCallers) {
        BYTE* p = (BYTE*)at;
        if (p[0] != 0xE8 || (DWORD)(at + 5 + *(int*)(p + 1)) != kSfxPlay) continue;
        DWORD old;
        if (!VirtualProtect(p, 5, PAGE_EXECUTE_READWRITE, &old)) continue;
        *(int*)(p + 1) = (int)((DWORD)&SfxPlayHook - (at + 5));
        VirtualProtect(p, 5, old, &old);
        FlushInstructionCache(GetCurrentProcess(), p, 5);
        ++ok;
    }
    return ok;
}

// ---------------------------------------------------------------- script CFuncs (full DLL only: patched before registration)
typedef bool (__cdecl* CFn)(void*, void*);
struct Wrapped { DWORD at; const char* name; CFn orig; DWORD sec, n, dropped; };
static Wrapped g_wrap[] = {
    {0x67FBA8, "LoadSound"}, {0x67FBB8, "StopSound"}, {0x67FBC0, "StopAllSounds"}, {0x67FBC8, "SetSoundParams"},
    {0x67FBF8, "SetSfxVolume"}, {0x67FC50, "SetMusicVolume"}, {0x67FC58, "SetMusicStreamVolume"}, {0x67FC68, "PlayMusicStream"},
    {0x67FC70, "SkipMusicTrack"}, {0x67FC78, "PauseMusic"}, {0x67FC80, "StopMusic"}, {0x67FCA8, "LoadStreamHeader"},
    {0x67FCE0, "PlayStream"}, {0x67FD00, "StopStream"}, {0x67FD08, "PauseStream"}, {0x67FD10, "SetStreamParams"},
    {0x680008, "SpawnSound"}, {0x681820, "PlaySkaterStream"}, {0x681860, "StartPreLoadedStream"},
};
static const int kWrapCount = sizeof g_wrap / sizeof g_wrap[0];

static int DumpParams(void* params, char* out, int cap) {
    int len = 0;
    {
        BYTE* c = params ? *(BYTE**)((BYTE*)params + 4) : nullptr;
        for (int guard = 0; c && guard < 16 && len < cap - 60; ++guard, c = *(BYTE**)(c + 0xC)) {
            int type = c[0] >> 1;
            DWORD key = *(DWORD*)(c + 4), val = *(DWORD*)(c + 8);
            char v[160];
            switch (type) {
            case 1: sprintf(v, "%d", (int)val); break;
            case 2: sprintf(v, "%g", *(float*)(c + 8)); break;
            case 3: case 4: _snprintf(v, 100, "\"%s\"", val ? (const char*)val : ""); v[100] = 0; break;
            case 0xD: _snprintf(v, 100, "%s", Name(val).c_str()); v[100] = 0; break;
            case 0xA: case 0xB: strcpy(v, "{...}"); break;
            case 0xC: strcpy(v, "[...]"); break;
            case 6: { float* f = (float*)val; if (f) sprintf(v, "(%g,%g,%g)", f[0], f[1], f[2]); else strcpy(v, "(vec)"); break; }
            default: sprintf(v, "<type %d>", type); break;
            }
            int w = key ? _snprintf(out + len, cap - len - 1, " %s=%s", Name(key).c_str(), v) : _snprintf(out + len, cap - len - 1, " %s", v);
            if (w < 0) break;
            len += w;
            out[len] = 0;
        }
    }
    return len;
}
static void DumpParamsSafe(void* params, char* out, int cap) {
    out[0] = 0;
    __try { DumpParams(params, out, cap); }
    __except (EXCEPTION_EXECUTE_HANDLER) { strcat(out, " <bad params>"); }
    out[cap - 1] = 0;
}
static bool CallWrapped(int i, void* params, void* script) {
    Wrapped& w = g_wrap[i];
    if (!strcmp(w.name, "PlayStream") && params && TelePct() <= 0) {   // teleporter streams (HI_WarpFlush) off
        BYTE* c = *(BYTE**)((BYTE*)params + 4);
        for (int guard = 0; c && guard < 16; ++guard, c = *(BYTE**)(c + 0xC))
            if ((c[0] >> 1) == 0xD && !*(DWORD*)(c + 4) && IsTeleSound(*(DWORD*)(c + 8))) {
                if (g_on) Log("SKIP   stream %s: teleporter sounds are off", Name(*(DWORD*)(c + 8)).c_str());
                return true;
            }
    }
    if (!strcmp(w.name, "PauseStream") && params) {
        // Noah 2026-11-20: pausing stopped the level's looping sound streams for good ("i went to the level noise and hit pause
        // and then the level noise stopped, and when i unpaused it was still gone"; "i didnt want to pause the music, wanted
        // the state of the music to continue"). The pause menu runs PauseStream 1, the stream code then frees the paused
        // stream (0x453940) and the level script never starts it again. PauseStream 1 is skipped, so streams keep playing
        // through the pause menu; PauseMusic (the soundtrack) is left as it is.
        int v = 1;
        BYTE* c = *(BYTE**)((BYTE*)params + 4);
        for (int guard = 0; c && guard < 16; ++guard, c = *(BYTE**)(c + 0xC))
            if ((c[0] >> 1) == 1 && !*(DWORD*)(c + 4)) { v = *(int*)(c + 8); break; }
        if (v == 1) { if (g_on) Log("SKIP   PauseStream 1: level sound streams keep playing through the pause"); return true; }
    }
    bool r = w.orig ? w.orig(params, script) : true;
    if (!g_on) return r;
    DWORD sec = GetTickCount() / 1000;
    if (sec != w.sec) {
        if (w.dropped) Log("SCRIPT %s: %lu more calls in that second not shown", w.name, w.dropped);
        w.sec = sec; w.n = 0; w.dropped = 0;
    }
    if (++w.n > 15) { ++w.dropped; return r; }   // SetSoundParams/SetStreamParams can run every frame
    char p[600]; p[0] = 0;
    DumpParamsSafe(params, p, sizeof p);
    Log("SCRIPT %s%s -> %s", w.name, p, r ? "true" : "false");
    return r;
}
template <int I> static bool __cdecl Wrap(void* p, void* s) { return CallWrapped(I, p, s); }
template <int I> struct WrapList { static void Fill(CFn* f) { f[I] = &Wrap<I>; WrapList<I - 1>::Fill(f); } };
template <> struct WrapList<-1> { static void Fill(CFn*) {} };

static int PatchCFuncTable() {
    CFn fns[kWrapCount];
    WrapList<kWrapCount - 1>::Fill(fns);
    int ok = 0;
    for (int i = 0; i < kWrapCount; ++i) {
        DWORD* e = (DWORD*)g_wrap[i].at;
        const char* n = (const char*)e[0];
        if (IsBadReadPtr(n, 32) || strcmp(n, g_wrap[i].name)) continue;
        DWORD old;
        if (!VirtualProtect(&e[1], 4, PAGE_READWRITE, &old)) continue;
        g_wrap[i].orig = (CFn)e[1];
        e[1] = (DWORD)fns[i];
        VirtualProtect(&e[1], 4, old, &old);
        ++ok;
    }
    return ok;
}

// ---------------------------------------------------------------- DirectSound failures
typedef HRESULT (WINAPI* CreateBufFn)(void*, const DWORD*, void**, void*);
typedef HRESULT (WINAPI* PlayFn)(void*, DWORD, DWORD, DWORD);
typedef HRESULT (WINAPI* LockFn)(void*, DWORD, DWORD, void**, DWORD*, void**, DWORD*, DWORD);
typedef HRESULT (WINAPI* StatusFn)(void*, DWORD*);
static CreateBufFn g_createOrig;
static PlayFn g_playOrig;
static LockFn g_lockOrig;
static StatusFn g_statusOrig;
static void** g_bufVt;
static volatile LONG g_bufCount, g_bufFail;
static DWORD g_lostAt;

static HRESULT WINAPI DsPlayHook(void* b, DWORD r, DWORD p, DWORD f) {
    HRESULT hr = g_playOrig(b, r, p, f);
    if (FAILED(hr) && g_on) Log("DSOUND Play failed hr=%08lX buffer %p%s", hr, b, hr == (HRESULT)0x88780096 ? " (buffer lost)" : "");
    return hr;
}
static HRESULT WINAPI DsLockHook(void* b, DWORD o, DWORD n, void** p1, DWORD* n1, void** p2, DWORD* n2, DWORD f) {
    HRESULT hr = g_lockOrig(b, o, n, p1, n1, p2, n2, f);
    if (FAILED(hr) && g_on) Log("DSOUND Lock failed hr=%08lX buffer %p%s", hr, b, hr == (HRESULT)0x88780096 ? " (buffer lost)" : "");
    return hr;
}
static HRESULT WINAPI DsStatusHook(void* b, DWORD* st) {
    HRESULT hr = g_statusOrig(b, st);
    if (g_on && (FAILED(hr) || (st && (*st & 2)))) {   // DSBSTATUS_BUFFERLOST
        DWORD now = GetTickCount();
        if (now - g_lostAt > 1000) { g_lostAt = now; Log("DSOUND GetStatus hr=%08lX status=%lX buffer %p%s", hr, st ? *st : 0, b, st && (*st & 2) ? " (buffer lost)" : ""); }
    }
    return hr;
}
static void PatchVt(void** vt, int idx, void* hook, void** orig) {
    if (vt[idx] == hook) return;
    DWORD old;
    if (!VirtualProtect(&vt[idx], 4, PAGE_EXECUTE_READWRITE, &old)) return;
    *orig = vt[idx];
    vt[idx] = hook;
    VirtualProtect(&vt[idx], 4, old, &old);
}
static void HookBufferVt(void* buf) {
    if (g_bufVt || !buf) return;
    void** vt = *(void***)buf;
    PatchVt(vt, 12, (void*)&DsPlayHook, (void**)&g_playOrig);
    PatchVt(vt, 11, (void*)&DsLockHook, (void**)&g_lockOrig);
    PatchVt(vt, 9, (void*)&DsStatusHook, (void**)&g_statusOrig);
    g_bufVt = vt;
}
static HRESULT WINAPI DsCreateHook(void* ds, const DWORD* desc, void** out, void* outer) {
    HRESULT hr = g_createOrig(ds, desc, out, outer);
    InterlockedIncrement(&g_bufCount);
    if (FAILED(hr)) {
        InterlockedIncrement(&g_bufFail);
        if (g_on) Log("DSOUND CreateSoundBuffer failed hr=%08lX (%lu bytes, flags %lX)", hr, desc ? desc[2] : 0, desc ? desc[1] : 0);
    } else if (out && *out && desc && !(desc[1] & 1)) {
        HookBufferVt(*out);
    }
    return hr;
}

// ---------------------------------------------------------------- toggle + watcher thread
static int ReadToggle() {
#ifdef SOUNDLOG_LIVE
    static int liveDefault = 1;   // the live test DLL logs from the moment it loads, until gfx.ini says gfx_soundlog = 0
#else
    static int liveDefault = 0;
#endif
    static FILETIME last; static int val = -1;
    WIN32_FILE_ATTRIBUTE_DATA a;
    std::string ini = DadmodFile("gfx.ini");
    if (!GetFileAttributesExA(ini.c_str(), GetFileExInfoStandard, &a)) return val < 0 ? liveDefault : val;
    if (val >= 0 && !CompareFileTime(&a.ftLastWriteTime, &last)) return val;
    last = a.ftLastWriteTime;
    int v = liveDefault;
    FILE* f = fopen(ini.c_str(), "r");
    if (f) {
        char line[256];
        while (fgets(line, sizeof line, f)) {
            int x;
            if (sscanf(line, " gfx_soundlog = %d", &x) == 1) v = x ? 1 : 0;
        }
        fclose(f);
    }
    val = v;
    return v;
}

static void Status(const char* why) {
    int state = *(int*)kSoundState;
    Log("STATUS %s: voices busy %d/%d, active count %d, sounds loaded permanent %d level %d, sound state %d%s, DS buffers made %ld (failed %ld)",
        why, BusyCount(), VoiceCount(), *(int*)0x6F8A48, *(int*)kPermCount, *(int*)kLevelCount, state,
        state == 2 || state == 6 ? " (no sound)" : "", g_bufCount, g_bufFail);
}

static DWORD g_lastStatus; static int g_lastState = -12345;
static void WatchTick() {
    DWORD& lastStatus = g_lastStatus; int& lastState = g_lastState;
    {
        {
            void* dev = *(void**)kDevice;
            if (dev && !g_createOrig) {   // chain on top of whatever is there (padhub's focus hook)
                void** vt = *(void***)dev;
                PatchVt(vt, 3, (void*)&DsCreateHook, (void**)&g_createOrig);
            }
            if (!g_bufVt) {
                for (int k = 0; k < VoiceCount(); ++k) {
                    void* b = *(void**)(kVoices + k * 0x18);
                    if (b) { HookBufferVt(b); break; }
                }
            }
            static int tick = 0;
            if (++tick % 5 == 0) {
                int want = ReadToggle();
                if (want && !g_on) {
                    LoadNames();
                    for (int k = 0; k < kMaxVoices; ++k) g_vTracked[k] = false;
                    InterlockedExchange(&g_on, 1);
                    Log("==== sound logger on (%s, %d names) ====",
#ifdef SOUNDLOG_LIVE
                        "live DLL: script lines need a restart",
#else
                        "full",
#endif
                        (int)g_names.size());
                    Log("hooks: sound effect callers %d/9, pause fix + teleporter loops %d/3, script functions %d/%d", g_sfxHooks, g_pauseHooks, g_cfuncHooks, kWrapCount);
                    Status("start");
                    lastStatus = GetTickCount();
                } else if (!want && g_on) {
                    Status("stop");
                    Log("==== sound logger off ====");
                    InterlockedExchange(&g_on, 0);
                    EnterCriticalSection(&g_cs);
                    if (g_file != INVALID_HANDLE_VALUE) { CloseHandle(g_file); g_file = INVALID_HANDLE_VALUE; }
                    LeaveCriticalSection(&g_cs);
                }
            }
            if (!g_on) return;
            int n = VoiceCount();
            for (int k = 0; k < n; ++k) {
                if (g_vTracked[k] && !VoiceBusy(k)) {
                    g_vTracked[k] = false;
                    Log("END    %-28s voice %d after %lu ms (%s)", Name(g_vSum[k]).c_str(), k, GetTickCount() - g_vStart[k], g_vWho[k] ? g_vWho[k] : "");
                }
            }
            { static int lv = -1, tv = -1; int l = LevelPct(), t = TelePct();
              if (l != lv || t != tv) { Log("SETTING level sounds %d%%, teleporter sounds %d%%", l, t); lv = l; tv = t; } }
            {   // stream channels (0x6EDFB8 stride 0x14: +0/+4 stream objects, +0xC left volume the engine last set)
                static float lastVol[3] = { -1, -1, -1 }; static int lastOn[3];
                for (int ch = 0; ch < 3; ++ch) {
                    DWORD base = 0x6EDFB8 + ch * 0x14;
                    int on = *(DWORD*)base || *(DWORD*)(base + 4);
                    float v = *(float*)(base + 0xC);
                    if (on != lastOn[ch]) { Log("STREAM channel %d %s", ch, on ? "playing" : "stopped"); lastOn[ch] = on; }
                    if (on && (v - lastVol[ch] > 2 || lastVol[ch] - v > 2)) { Log("STREAM channel %d volume %.0f (level sounds %d%%)", ch, v, LevelPct()); lastVol[ch] = v; }
                }
            }
            int state = *(int*)kSoundState;
            if (state != lastState) { if (lastState != -12345) Log("STATE  sound state %d -> %d", lastState, state); lastState = state; }
            if (GetTickCount() - lastStatus > 10000) { lastStatus = GetTickCount(); Status("every 10 s"); }
        }
    }
}
static DWORD WINAPI Watch(void*) {
    for (;;) {
        Sleep(50);
        __try { WatchTick(); }
        __except (EXCEPTION_EXECUTE_HANDLER) {}
    }
    return 0;
}

// ---------------------------------------------------------------- pause fix (Noah 2026-11-20: "the level sounds seem to play until
// i hit pause and then they stop"). Stock pause (PauseGame -> 0x54F960 -> 0x564F60(1) -> 0x47D390) sets every playing voice
// to volume 0, and unpause (0x564F60(0)) does nothing, so a looping sound that is not re-placed every frame by its object
// (level ambience started with PlaySound, SpawnSound loops) stays silent until it is played again. The two calls are routed
// here: at pause each playing voice's DirectSound volume, pan and frequency are saved; at unpause they are put back on
// every voice that still plays the same buffer. Positional sounds are re-placed by the engine on the next frame anyway.
// Always on. Online games never call PauseGame, so this only changes offline pausing.
struct VoiceSave { void* buf; LONG vol, pan; DWORD freq; bool ok; };
static VoiceSave g_saved[kMaxVoices];
static const DWORD kPauseSfxCall = 0x54F999, kUnpauseSfxCall = 0x54FA6D, kPauseSfx = 0x564F60;
typedef void (__thiscall* PauseSfxFn)(void*, char);
typedef HRESULT (WINAPI* GetLongFn)(void*, LONG*);
typedef HRESULT (WINAPI* SetLongFn)(void*, LONG);
static void __fastcall PauseSfxHook(void* self, void*, char pause) {
    int n = VoiceCount();
    if (pause) {
        int saved = 0;
        for (int k = 0; k < n; ++k) {
            VoiceSave& v = g_saved[k];
            v.ok = false;
            void* b = *(void**)(kVoices + k * 0x18);
            if (!b || !VoiceBusy(k)) continue;
            void** vt = *(void***)b;
            v.buf = b;
            v.ok = SUCCEEDED(((GetLongFn)vt[6])(b, &v.vol)) && SUCCEEDED(((GetLongFn)vt[7])(b, &v.pan))
                && SUCCEEDED(((GetLongFn)vt[8])(b, (LONG*)&v.freq));
            saved += v.ok;
        }
        ((PauseSfxFn)kPauseSfx)(self, pause);
        if (g_on) Log("PAUSE  game paused: the engine set %d playing voices to volume 0 (saved %d to put back)", BusyCount(), saved);
        return;
    }
    ((PauseSfxFn)kPauseSfx)(self, pause);
    int back = 0, gone = 0;
    for (int k = 0; k < n; ++k) {
        VoiceSave& v = g_saved[k];
        if (!v.ok) continue;
        v.ok = false;
        void* b = *(void**)(kVoices + k * 0x18);
        if (b != v.buf || !VoiceBusy(k)) { ++gone; continue; }
        void** vt = *(void***)b;
        ((SetLongFn)vt[15])(b, v.vol);
        ((SetLongFn)vt[16])(b, v.pan);
        ((SetLongFn)vt[17])(b, (LONG)v.freq);
        ++back;
        if (g_on) Log("UNPAUSE voice %d %s back to volume %ld", k, g_vTracked[k] ? Name(g_vSum[k]).c_str() : "(started before logging)", v.vol);
    }
    if (g_on) Log("UNPAUSE game unpaused: put %d sounds back to their volume (%d had ended or changed)", back, gone);
}
// Teleporter loops (Noah 2026-11-20: "the volume change doesnt kick in until you walk away and come back"): some teleporters
// play their sound as a looping positional sound on an object, and the engine recomputes its volume every frame in 0x47C360
// (called from 0x47C5F0, thiscall, 3 stack args, the 2nd = the voice's slot in the 0x6F7A68 table: +4 sound id, +8 sound).
// Scaling only at start missed those, so after the engine sets the frame's volume the teleporter slider is applied on top,
// every frame: a change is heard at once, even on a loop that is already playing.
static const DWORD kObjUpdateCall = 0x47C5F0, kObjUpdate = 0x47C360;
typedef char (__thiscall* ObjUpdateFn)(void*, DWORD, DWORD*, DWORD);
static char __fastcall ObjUpdateHook(void* self, void*, DWORD a, DWORD* slot, DWORD t) {
    char r = ((ObjUpdateFn)kObjUpdate)(self, a, slot, t);
    int k = (int)(((DWORD)slot - kHandles) / 0x3C);
    if (k < 0 || k >= VoiceCount()) return r;
    if (g_on) {   // level sound volume trace: what DirectSound volume the engine left on this voice this frame
        static LONG last[kMaxVoices]; static DWORD lastAt[kMaxVoices];
        void* b = *(void**)(kVoices + k * 0x18);
        LONG cur = 0;
        if (b && SUCCEEDED(((GetLongFn)(*(void***)b)[6])(b, &cur))) {
            LONG d = cur - last[k];
            DWORD now = GetTickCount();
            if ((d > 300 || d < -300) && now - lastAt[k] > 250) {
                last[k] = cur; lastAt[k] = now;
                DWORD sound = slot[2] ? *(DWORD*)slot[2] : slot[1];
                BYTE* X = (BYTE*)a; BYTE* o = *(BYTE**)(X + 0xC);
                Log("VOLUME voice %d %-26s obj %p [+8 %08lX +0x10 %08lX +0x14 %08lX] owner %p id %08lX: DirectSound volume %ld (%s, level sounds %d%%)", k, Name(sound).c_str(),
                    X, *(DWORD*)(X + 8), *(DWORD*)(X + 0x10), *(DWORD*)(X + 0x14), o, o && !IsBadReadPtr(o + 0x14, 4) ? *(DWORD*)(o + 0x14) : 0, cur, *(BYTE*)0x6F8A4C && *(void**)(kVoices + k * 0x18 + 4) ? "3D" : "2D", LevelPct());
            }
        }
    }
    DWORD sound = slot[2] ? *(DWORD*)slot[2] : 0;
    if (!IsTeleSound(slot[1]) && !IsTeleSound(sound)) return r;
    int pct = TelePct();
    if (pct >= 100) return r;
    void* b = *(void**)(kVoices + k * 0x18);
    if (!b) return r;
    void** vt = *(void***)b;
    LONG cur = 0;
    if (FAILED(((GetLongFn)vt[6])(b, &cur))) return r;
    LONG v = pct <= 0 ? -10000 : cur + (LONG)(2000.0 * log10(pct / 100.0));
    if (v < -10000) v = -10000;
    ((SetLongFn)vt[15])(b, v);
    return r;
}
static int PatchObjUpdate() {
    BYTE* p = (BYTE*)kObjUpdateCall;
    if (p[0] != 0xE8 || (DWORD)(kObjUpdateCall + 5 + *(int*)(p + 1)) != kObjUpdate) return 0;
    DWORD old;
    if (!VirtualProtect(p, 5, PAGE_EXECUTE_READWRITE, &old)) return 0;
    *(int*)(p + 1) = (int)((DWORD)&ObjUpdateHook - (kObjUpdateCall + 5));
    VirtualProtect(p, 5, old, &old);
    FlushInstructionCache(GetCurrentProcess(), p, 5);
    return 1;
}
static int PatchPauseCalls() {
    int ok = 0;
    for (DWORD at : { kPauseSfxCall, kUnpauseSfxCall }) {
        BYTE* p = (BYTE*)at;
        if (p[0] != 0xE8 || (DWORD)(at + 5 + *(int*)(p + 1)) != kPauseSfx) continue;
        DWORD old;
        if (!VirtualProtect(p, 5, PAGE_EXECUTE_READWRITE, &old)) continue;
        *(int*)(p + 1) = (int)((DWORD)&PauseSfxHook - (at + 5));
        VirtualProtect(p, 5, old, &old);
        FlushInstructionCache(GetCurrentProcess(), p, 5);
        ++ok;
    }
    return ok;
}

static void Install() {
    static bool done;
    if (done) return;
    done = true;
    InitializeCriticalSection(&g_cs);
    g_t0 = GetTickCount();
#ifndef SOUNDLOG_LIVE
    g_cfuncHooks = PatchCFuncTable();
#endif
    g_sfxHooks = PatchSfxCallers();
    g_pauseHooks = PatchPauseCalls();
    g_pauseHooks += PatchObjUpdate();
    CloseHandle(CreateThread(nullptr, 0, Watch, nullptr, 0, nullptr));
}

}  // namespace soundlog
