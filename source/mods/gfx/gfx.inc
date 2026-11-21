// Graphics settings for an old game (Dadmod > Graphics, pause menu > dadmod, THUGPro Manager > Offline UI).
// All client-side visuals, safe online. Settings live in <game>\dadmod\gfx.ini as "gfx_xxx = N" lines; the
// menus read/write them through THUGRECOMP_SettingLoad/Save (keys starting with gfx_ are redirected here) and
// the game re-reads the file when THUGPro Manager changes it.
//
// How it hooks D3D9 (the game draws with the fixed-function pipeline, no vertex shaders):
//   IDirect3D9::CreateDevice (shared d3d9.dll vtable, patched from a probe IDirect3D9 at start): MSAA, v-sync.
//   The game's own device (its vtable differs from a probe device's, so it is patched right after creation):
//     SetSamplerState   anisotropic filtering, mip LOD bias, smooth 2D graphics
//     SetTransform      camera (view) and lens (projection); a projection with _43 == 0 marks the sky pass
//     DrawIndexedPrimitive  skipped during the sky pass when the galaxy sky is on
//     DrawPrimitiveUP   the first one in a frame is the HUD/menus starting: scene effects run just before it
//     SetDepthStencilSurface  swaps in a readable INTZ depth buffer when a depth effect is on (not with MSAA)
//     Present / swap chain Present  screen effects, FPS counter, screenshots;  Reset  frees our resources
// Stages: galaxy (at the sky pass) -> scene effects (at the HUD boundary, or at Present if nothing 2D was drawn)
//         -> screen effects (Present; these cover the HUD too: CRT, grain, chromatic aberration, vignette).
#include <d3d9.h>
#include <tlhelp32.h>
namespace gfx {

// ---- settings -----------------------------------------------------------------------------------
struct Setting { const char* key; int def, lo, hi; const char* help; };
static const Setting kSettings[] = {
    {"gfx_aniso", 4, 0, 4, "anisotropic filtering: 0 off, 1 2x, 2 4x, 3 8x, 4 16x"},
    {"gfx_lodbias", 0, 0, 4, "texture sharpness (mip LOD bias): 0 normal .. 4 sharpest (may shimmer)"},
    {"gfx_uismooth", 0, 0, 1, "smooth scaled menu/HUD graphics: 0 off, 1 on"},
    {"gfx_msaa", 0, 0, 3, "MSAA anti-aliasing (restart): 0 off, 1 2x, 2 4x, 3 8x"},
    {"gfx_vsync", 0, 0, 2, "v-sync (restart): 0 game default, 1 on, 2 off"},
    {"gfx_fxaa", 0, 0, 2, "FXAA anti-aliasing: 0 off, 1 fast, 2 high quality"},
    {"gfx_sharpen", 0, 0, 10, "sharpening (contrast adaptive): 0 off .. 10 strong"},
    {"gfx_bloom", 0, 0, 10, "bloom (glow around bright areas): 0 off .. 10 strong"},
    {"gfx_ssao", 0, 0, 10, "ambient occlusion (soft shadows in corners; not with MSAA): 0 off .. 10 strong"},
    {"gfx_fog", 0, 0, 10, "distance haze (not with MSAA): 0 off .. 10 thick"},
    {"gfx_dof", 0, 0, 10, "depth of field, far blur (not with MSAA): 0 off .. 10 strong"},
    {"gfx_outline", 0, 0, 2, "outlines: 0 off, 1 outlines, 2 cel-shaded (outlines need no MSAA)"},
    {"gfx_mblur", 0, 0, 10, "motion blur (frame blend): 0 off .. 10 heavy"},
    {"gfx_pixelate", 0, 0, 3, "pixelate (retro): 0 off, 1 2x, 2 3x, 3 4x pixels"},
    {"gfx_vignette", 0, 0, 10, "vignette (darker corners): 0 off .. 10 strong"},
    {"gfx_grain", 0, 0, 10, "film grain: 0 off .. 10 heavy"},
    {"gfx_chroma", 0, 0, 10, "chromatic aberration (color fringe at the edges): 0 off .. 10"},
    {"gfx_crt", 0, 0, 2, "CRT TV: 0 off, 1 scanlines, 2 scanlines and curved screen"},
    {"gfx_preset", 0, 0, 10, "color look: 0 none, 1 vivid, 2 warm, 3 cool, 4 film, 5 black and white, 6 retro, 7 night, 8 sunset, 9 overcast, 10 VHS"},
    {"gfx_bright", 0, -10, 10, "brightness: -10 .. 10, 0 normal"},
    {"gfx_contrast", 0, -10, 10, "contrast: -10 .. 10, 0 normal"},
    {"gfx_sat", 0, -10, 10, "saturation: -10 (grey) .. 10, 0 normal"},
    {"gfx_vibrance", 0, 0, 10, "vibrance (boosts dull colors, leaves strong ones): 0 off .. 10"},
    {"gfx_gamma", 0, -10, 10, "gamma (midtones): -10 darker .. 10 brighter, 0 normal"},
    {"gfx_temp", 0, -10, 10, "color temperature: -10 cool .. 10 warm, 0 normal"},
    {"gfx_tint", 0, -10, 10, "tint: -10 green .. 10 magenta, 0 normal"},
    {"gfx_galaxy", 0, 0, 14, "sky (replaces the level sky): 0 off, 1 milky way, 2 nebula, 3 deep space, 4 matrix, 5 aurora, 6 synthwave, "
                                "7 storm, 8 golden hour, 9 vaporwave, 10 hellfire, 11 underwater, 12 rainbow, 13 black hole, 14 cotton candy"},
    {"gfx_tod", 0, 0, 6, "time of day: 0 level default, 1 morning, 2 day, 3 sunset, 4 night, 5 evening with the lights on, 6 dawn (sun coming up, lights still on)"},
    {"gfx_daylen", 2, 0, 4, "unused since 2026-11-21 (the Dynamic time of day was removed); kept so old files load"},
    {"gfx_weather", 0, 0, 4, "weather: 0 off, 1 rain, 2 heavy rain with lightning, 3 snow, 4 random (clear, rain, storm or snow, changes every few minutes)"},
    {"gfx_wxclear", 1, 0, 1, "unused since 2026-11-21 (Random weather picks from clear, rain, storm and snow); kept so old files load"},
    {"gfx_wxrain", 1, 0, 1, "unused since 2026-11-21 (Random weather picks from clear, rain, storm and snow); kept so old files load"},
    {"gfx_wxstorm", 1, 0, 1, "unused since 2026-11-21 (Random weather picks from clear, rain, storm and snow); kept so old files load"},
    {"gfx_wxsnow", 1, 0, 1, "unused since 2026-11-21 (Random weather picks from clear, rain, storm and snow); kept so old files load"},
    {"gfx_wxfog", 1, 0, 1, "unused since 2026-11-21 (Random weather picks from clear, rain, storm and snow); kept so old files load"},
    {"gfx_wxamt", 6, 1, 10, "weather intensity: 1 light .. 10 heavy"},
    {"gfx_todfog", 0, 0, 4, "ground mist: 0 off, 1 knee high, 2 head high, 3 first floor, 4 rooftops"},
    {"gfx_fogamt", 5, 1, 10, "ground mist intensity: 1 light .. 10 thick"},
    {"gfx_fireworks", 0, 0, 5, "fireworks: 0 off, 1 when someone wins a game, 2-5 on wins and every 1 / 3 / 5 / 10 minutes"},
    {"gfx_fwevery", 2, 0, 3, "unused since 2026-11-21 (Fireworks picks the interval itself); kept so old files load"},
    {"gfx_skywxver", 1, 0, 1, "settings version of the Sky & weather page (old weather / fireworks values were converted once)"},
    {"gfx_lamps", 0, 0, 10, "street lights at night (no menu row since 2026-11-21, off by default): lamps in the level glow and light up around them in the evening and at night: 0 off .. 10 bright"},
    {"gfx_skypop", 5, 0, 10, "sky boost (richer sky colors to match the time of day, stars at night): 0 off .. 10 strong"},
    {"gfx_fps", 0, 0, 2, "FPS counter in the top left corner: 0 off, 1 on, 2 tiny (just the number, right in the corner)"},
    {"gfx_shotkey", 1, 0, 1, "F11 saves a screenshot to dadmod\\screenshots: 0 off, 1 on"},
    {"gfx_shothud", 0, 0, 1, "screenshots: 0 clean (no menus or HUD), 1 as on screen"},
    {"gfx_mirror", 0, 0, 1, "mirror mode: 0 off, 1 the 3D view is flipped left to right and left/right steering is swapped (menus, HUD and text stay normal)"},
    {"gfx_bginput", 1, 0, 1, "background input: 0 controller only works while the game window is in front, 1 it keeps working when another program has focus"},
    {"gfx_deadzone", 0, 0, 10, "stick dead zone: 0 off, 1..10 ignores small stick movements (3%..30% of the stick range) so a worn stick stops drifting"},
    {"gfx_abswap", 0, 0, 1, "swap A/B and X/Y: 0 off, 1 on (for Nintendo-style controllers)"},
    {"gfx_tricksfx", 100, 0, 100, "special trick sounds volume: 0 off .. 100 full (the sound clips some special tricks play, like the guitar grind; 1 from older files means full)"},
    {"gfx_levelsfx", 100, 0, 100, "level sounds volume: 0 off .. 100 full (water, crowds, machines, cars and other sounds that come from things in a map; skaters' own sounds are not changed; 1 from older files means full)"},
    {"gfx_telesfx", 100, 0, 100, "teleporter sounds volume: 0 off .. 100 full (the sounds level teleporters and teleporting elevators play; mods/soundlog)"},
    {"gfx_soundlog", 0, 0, 1, "sound logger: 0 off, 1 writes every sound the game plays (and any that fail or get cut off) to dadmod\\soundlog.txt (mods/soundlog)"},
    {"gfx_padpopup", 1, 0, 1,"controller popups: 0 off, 1 a short on-screen message when a controller is plugged in or unplugged"},
    {"gfx_launchbinds", 0, 0, 1, "use launcher button layout: 0 dadmod standard Xbox-style layout, 1 the bindings set in the THUG Pro launcher"},
    {"gfx_debug", 0, 0, 2, "developer view: 0 off, 1 depth, 2 raw depth"},
    {"gfx_postfx", 0, 0, 1, "graphics effects when ReShade is installed: 0 dadmod's own effects, 1 ReShade's (dadmod skips its screen effects; sky, weather, mirror, FPS counter and screenshots keep working)"},
    {"gfx_postfxset", 0, 0, 1, "set by dadmod once the Graphics effects row is used: from then on dadmod also switches ReShade's own effects with that row (0 = leave ReShade's effects alone)"},
};
static const int kCount = sizeof kSettings / sizeof kSettings[0];
static int g_val[kCount];
static volatile LONG g_dirtyPost = 1;
static FILETIME g_iniTime = {};

static int Index(const char* key) {
    for (int i = 0; i < kCount; ++i) if (!_stricmp(kSettings[i].key, key)) return i;
    return -1;
}
// ReShade (Noah 2026-11-19): with gfx_postfx = 1 ("ReShade") every screen effect below reads as off, so dadmod draws none
// of them (and needs no depth swap for them) and only ReShade's effects show. Sky, time of day, weather, fireworks,
// street lights, texture filtering, MSAA, v-sync, FPS counter, screenshots and mirror mode are not screen effects and
// keep working. The menus read the stored values (GetKey), so a player's settings are untouched and come back with 0.
static const char* const kScreenFx[] = { "gfx_fxaa", "gfx_sharpen", "gfx_bloom", "gfx_ssao", "gfx_fog", "gfx_dof",
    "gfx_outline", "gfx_mblur", "gfx_pixelate", "gfx_vignette", "gfx_grain", "gfx_chroma", "gfx_crt", "gfx_preset",
    "gfx_bright", "gfx_contrast", "gfx_sat", "gfx_vibrance", "gfx_gamma", "gfx_temp", "gfx_tint", "gfx_debug" };
static bool IsScreenFx(int i) {
    static signed char fx[kCount];
    static bool init = false;
    if (!init) {
        for (int k = 0; k < kCount; ++k) {
            fx[k] = 0;
            for (const char* n : kScreenFx) if (!_stricmp(kSettings[k].key, n)) fx[k] = 1;
        }
        init = true;
    }
    return fx[i] != 0;
}
static bool g_reshadeLoaded = false;   // set once after the device exists (SyncReShadeEffects -> DetectReShade)
static int V(const char* key) {
    int i = Index(key);
    if (i < 0) return 0;
    static const int postfx = Index("gfx_postfx");
    // only while ReShade is loaded: if a player removes ReShade, dadmod's own effects come back without the (hidden) row
    if (postfx >= 0 && g_val[postfx] && g_reshadeLoaded && IsScreenFx(i)) return 0;
    return g_val[i];
}
// Level sounds (Noah 2026-11-17 on/off, 2026-11-19 "a volume slider that turns all the way off"): the engine's SpawnSound
// starts the sound scripts maps run from spots in the level; their loops then live as positional sounds on objects.
// SpawnSound is no longer gated (so sounds come back at once when the slider goes up from 0); the volume is applied
// where the engine sets each positional sound's volume every frame (InstallLevelSoundHooks below). The gate stays
// installed as a pass-through on the engine's own CFunc table (RegisterCFuncsHook in thugrecomp.cpp and the client loader).
static bool (__cdecl* g_spawnSoundOrig)(void*, void*) = nullptr;
static bool __cdecl CF_SpawnSoundGate(void* params, void* script) {
    return g_spawnSoundOrig ? g_spawnSoundOrig(params, script) : true;
}
// Every frame the engine works out each positional sound's left/right volume from the listener distance (0x47BE10) and
// hands it on: object sounds (Obj_PlaySound) at 0x47C545 (thiscall 0x47B7C0(handle, vol*, pitch), ESI = the sound
// component) and object streams (Obj_PlayStream) at 0x450D31 (cdecl 0x453DF0(vol*, handle), EBX = the stream's
// component). Both calls are routed through ScaleLevelSound, which multiplies volL/volR by the slider unless the
// component's object (component+0xC) is a skater (object id at +0x14 is 0..15 for skaters, a node checksum otherwise),
// so every skater's own sounds, local and online, keep their volume.
static DWORD g_levelApplyObj = 0x47B7C0, g_levelApplyStream = 0x453DF0;
static void __cdecl ScaleLevelSound(float* vol, BYTE* comp) {
    int pct = V("gfx_levelsfx");
    if (pct >= 100 || !vol || !comp) return;
    BYTE* obj = *(BYTE**)(comp + 0xC);
    DWORD id = obj ? *(DWORD*)(obj + 0x14) : 0xFFFFFFFF;
    {   // log each sound owner once (up to 32), so a log shows what the slider touches and what it leaves alone
        static DWORD seen[32]; static int n;
        bool known = false;
        for (int i = 0; i < n; ++i) if (seen[i] == id) known = true;
        if (!known && n < 32) { seen[n++] = id; mmenu::Log("gfx: level sounds at %d%%: %s sound from object id %08lX", pct, id < 16 ? "kept (skater)" : "scaled", id); }
    }
    if (id < 16) return;   // a skater's own sound
    float f = pct / 100.0f;
    vol[0] *= f; vol[1] *= f;
}
static __declspec(naked) void LevelObjSoundStub() {
    __asm {
        push ecx
        mov eax, [esp + 12]
        push esi
        push eax
        call ScaleLevelSound
        add esp, 8
        pop ecx
        jmp dword ptr [g_levelApplyObj]
    }
}
static __declspec(naked) void LevelStreamStub() {
    __asm {
        mov eax, [esp + 4]
        push ebx
        push eax
        call ScaleLevelSound
        add esp, 8
        jmp dword ptr [g_levelApplyStream]
    }
}
static void PatchLevelCall(DWORD at, DWORD target, void* stub, const char* what) {
    BYTE* p = (BYTE*)at;
    if (p[0] != 0xE8 || (DWORD)(at + 5 + *(int*)(p + 1)) != target) { mmenu::Log("gfx: level sound volume: %s call not found, left alone", what); return; }
    DWORD old;
    if (!VirtualProtect(p, 5, PAGE_EXECUTE_READWRITE, &old)) return;
    *(int*)(p + 1) = (int)((DWORD)stub - (at + 5));
    VirtualProtect(p, 5, old, &old);
    FlushInstructionCache(GetCurrentProcess(), p, 5);
    mmenu::Log("gfx: level sound volume hooked (%s)", what);
}
static void InstallLevelSoundHooks() {
    PatchLevelCall(0x47C545, g_levelApplyObj, (void*)&LevelObjSoundStub, "object sounds");
    PatchLevelCall(0x450D31, g_levelApplyStream, (void*)&LevelStreamStub, "object streams");
}
// Special trick sounds off (Noah 2026-11-17): air, grind and manual special tricks play their clip with
// PlayStream ... id = SFXSpecialStream (airtricks/grindscripts/manualtricks); while gfx_tricksfx = 0 those are skipped
static bool (__cdecl* g_playStreamOrig)(void*, void*) = nullptr;
// Volume slider (Noah 2026-11-19: "a volume slider that turns all the way off"): the clip starts as the trick asked, then
// the engine's own SetStreamParams sets its volume to the trick's vol x slider%; moving the slider re-applies it live.
static bool (__cdecl* g_setStreamParamsOrig)(void*, void*) = nullptr;
static float g_trickBaseVol = 100.0f;   // vol the last special trick clip asked for
static void SetSpecialStreamVolume(float vol) {
    if (!g_setStreamParamsOrig) return;
    BYTE st[16] = {0};
    typedef void (__thiscall* CtorFn)(void*);
    typedef void (__thiscall* AddSumFn)(void*, DWORD, DWORD);
    typedef void (__thiscall* AddFloatFn)(void*, DWORD, float);
    ((CtorFn)0x476410)(st);                                                     // CStruct::CStruct
    ((AddSumFn)mmenu::kAddChecksum)(st, 0, QbKey("SFXSpecialStream"));         // unnamed: the stream id
    ((AddFloatFn)mmenu::kAddFloat)(st, QbKey("vol"), vol);
    bool ok = g_setStreamParamsOrig(st, nullptr);
    mmenu::Log("gfx: special trick clip volume -> %.0f (%s)", vol, ok ? "set" : "no clip playing");
    ((CtorFn)0x477130)(st);                                                     // CStruct::~CStruct
}
static bool __cdecl CF_PlayStreamGate(void* params, void* script) {
    bool special = params && mmenu::ChecksumParam(params, "id") == QbKey("SFXSpecialStream");
    int pct = V("gfx_tricksfx");
    if (special && !pct) return true;
    bool r = g_playStreamOrig ? g_playStreamOrig(params, script) : true;
    if (special) {
        float vol = mmenu::FloatParam(params, "vol", -1.0f);
        if (vol < 0) vol = (float)::IntParam(params, "vol", 100);
        g_trickBaseVol = vol;
        if (pct < 100) SetSpecialStreamVolume(vol * pct / 100.0f);
    }
    return r;
}
// Noah 2026-11-19: switching special trick sounds off also stops the clip playing right now. Runs the stock script
// HandleStoppingAStream with Name = SFXSpecialStream (game thread only: called from SetKey, which a script calls, or
// from the next frame after THUGPro Manager changed gfx.ini).
static volatile LONG g_trickStopPending, g_trickVolPending;
static void StopSpecialStream(const char* why) {
    BYTE st[16] = {0};
    typedef void (__thiscall* CtorFn)(void*);
    typedef void (__thiscall* AddSumFn)(void*, DWORD, DWORD);
    typedef int (__cdecl* RunFn)(DWORD, void*, int, int, int);
    ((CtorFn)0x476410)(st);                                                       // CStruct::CStruct
    ((AddSumFn)mmenu::kAddChecksum)(st, QbKey("Name"), QbKey("SFXSpecialStream")); // CStruct::AddChecksum
    ((RunFn)0x475790)(QbKey("HandleStoppingAStream"), st, 0, 0, 0);              // RunScript
    ((CtorFn)0x477130)(st);                                                       // CStruct::~CStruct
    mmenu::Log("gfx: special trick sounds off (%s): stopped the special trick clip", why);
}
static void PatchEngineCFuncs(void* table, unsigned count) {
    struct E { const char* n; bool (__cdecl* f)(void*, void*); };
    E* e = (E*)table;
    for (unsigned i = 0; i < count; ++i) {
        if (e[i].n && !strcmp(e[i].n, "SpawnSound") && e[i].f != CF_SpawnSoundGate) {
            DWORD old; VirtualProtect(&e[i].f, sizeof(e[i].f), PAGE_READWRITE, &old);
            g_spawnSoundOrig = e[i].f; e[i].f = CF_SpawnSoundGate;
            VirtualProtect(&e[i].f, sizeof(e[i].f), old, &old);
        }
        if (e[i].n && !strcmp(e[i].n, "SetStreamParams")) g_setStreamParamsOrig = e[i].f;
        if (e[i].n && !strcmp(e[i].n, "PlayStream") && e[i].f != CF_PlayStreamGate) {
            DWORD old; VirtualProtect(&e[i].f, sizeof(e[i].f), PAGE_READWRITE, &old);
            g_playStreamOrig = e[i].f; e[i].f = CF_PlayStreamGate;
            VirtualProtect(&e[i].f, sizeof(e[i].f), old, &old);
        }
    }
}
static void SyncInput() {  // Dadmod > Controls -> padhub
    InterlockedExchange(&padhub::g_bgInput, V("gfx_bginput") ? 1 : 0);
    InterlockedExchange(&padhub::g_deadzone, V("gfx_deadzone"));
    InterlockedExchange(&padhub::g_abSwap, V("gfx_abswap") ? 1 : 0);
    InterlockedExchange(&padhub::g_padPopup, V("gfx_padpopup") ? 1 : 0);
    padhub::SetLaunchBinds(V("gfx_launchbinds") != 0);
}

static FILETIME IniTime() {
    WIN32_FILE_ATTRIBUTE_DATA a;
    if (GetFileAttributesExA(ExeDirFile("gfx.ini").c_str(), GetFileExInfoStandard, &a)) return a.ftLastWriteTime;
    return FILETIME{};
}

static std::string g_shotDir;  // gfx_shotdir = folder for F11 screenshots (THUGPro Manager); empty = dadmod\\screenshots
static void Save();
static void Load() {
    for (int i = 0; i < kCount; ++i) g_val[i] = kSettings[i].def;
    g_shotDir.clear();
    std::string data;
    int rawWeather = -1, rawFw = -1, rawVer = 0;
    bool migrate = false;
    if (ReadWholeFile(ExeDirFile("gfx.ini"), data)) {
        size_t s = 0;
        while (s < data.size()) {
            size_t e = data.find_first_of("\r\n", s);
            std::string line = data.substr(s, e == std::string::npos ? std::string::npos : e - s);
            s = e == std::string::npos ? data.size() : e + 1;
            if (!line.compare(0, 11, "gfx_shotdir")) {  // a path: read before ';' comments are cut
                size_t q = line.find('=');
                if (q != std::string::npos) g_shotDir = mmenu::Trim(line.substr(q + 1));
                continue;
            }
            size_t c = line.find(';');
            if (c != std::string::npos) line = line.substr(0, c);
            size_t eq = line.find('=');
            if (eq == std::string::npos) continue;
            std::string k = mmenu::Trim(line.substr(0, eq));
            int v = atoi(line.c_str() + eq + 1);
            if (k == "anisotropy") {  // first version of gfx.ini: anisotropy = 0/2/4/8/16
                k = "gfx_aniso";
                v = v >= 16 ? 4 : v >= 8 ? 3 : v >= 4 ? 2 : v >= 2 ? 1 : 0;
            }
            if (k == "gfx_weather") rawWeather = v;
            if (k == "gfx_fireworks") rawFw = v;
            if (k == "gfx_skywxver") rawVer = v;
            int i = Index(k.c_str());
            if (i >= 0) g_val[i] = v < kSettings[i].lo ? kSettings[i].lo : v > kSettings[i].hi ? kSettings[i].hi : v;
        }
        // one Sky & weather page (2026-11-21): convert old weather / fireworks values once
        if (rawVer < 1) {
            std::string what;
            int iw = Index("gfx_weather"), ifw = Index("gfx_fireworks"), ifog = Index("gfx_todfog"), iev = Index("gfx_fwevery"), iver = Index("gfx_skywxver");
            if (rawWeather == 5) { g_val[iw] = 4; what += " weather Dynamic->Random"; }
            else if (rawWeather == 4) {
                g_val[iw] = 0; what += " weather Fog->Off";
                if (g_val[ifog] == 0) { g_val[ifog] = 2; what += ", Fog->Head high"; }
            }
            if (rawFw == 2) { g_val[ifw] = 2 + g_val[iev]; what += " fireworks Auto->every interval " + std::to_string(g_val[ifw]); }
            g_val[iver] = 1;
            mmenu::Log("gfx: sky & weather settings converted:%s", what.empty() ? " nothing to change" : what.c_str());
            migrate = true;
        }
    }
    // Noah 2026-10-26: mirror mode starts off every time the game starts (later gfx.ini reloads keep it)
    static bool first = true;
    for (const char* k : { "gfx_tricksfx", "gfx_levelsfx" }) {   // were On/Off (0/1) before they became 0..100 volumes: 1 = full
        int t = Index(k);
        if (t >= 0 && g_val[t] == 1) g_val[t] = 100;
    }
    if (first) {
        first = false;
        int m = Index("gfx_mirror");
        if (m >= 0 && g_val[m]) { g_val[m] = 0; migrate = true; }
    }
    if (migrate) Save();
    g_iniTime = IniTime();
    SyncInput();
    InterlockedExchange(&g_dirtyPost, 1);
}

static void Save() {
    std::string out = "; Dadmod graphics settings (Dadmod > Graphics in game, or THUGPro Manager). Changes apply live\r\n"
                      "; except MSAA and v-sync, which need a restart. Delete this file for the defaults.\r\n";
    for (int i = 0; i < kCount; ++i)
        out += std::string("; ") + kSettings[i].help + "\r\n" + kSettings[i].key + " = " + std::to_string(g_val[i]) + "\r\n";
    out += "; folder for F11 screenshots (empty = dadmod\\screenshots)\r\ngfx_shotdir = " + g_shotDir + "\r\n";
    WriteWholeFile(ExeDirFile("gfx.ini"), out);
    g_iniTime = IniTime();
}

static int TodNow();
// Online, with Time of day on "Level / server": the state the server put us in (QB dadmod_tod_server_state)
static int g_serverTod = 0;
static int TodSetting();
static bool g_trickSwap = false;  // left/right steering is swapped right now (trick button names swap back)
static bool g_balancing = false;  // grind / manual / lip balance (QB sends gfx_balancing): mirror steering pauses
static bool g_menuUp = true;  // a menu is open (QB dadmod_mirror_watch sends gfx_menuup); mirror steering waits for none
// Noah 2026-10-26: the main menu is never mirrored (view or steering). QB dadmod_mirror_watch sends gfx_mainmenu;
// until it does (boot), assume the main menu.
static bool g_mainMenu = true;
static void FireworksShow(double seconds, const char* why);
static void SetLevel(const char* name);
static void LampMark(bool add);
// THUGRECOMP_SettingSave/Load redirect for gfx_ keys (declared in modes.inc)
bool SetKey(const char* key, int value) {
#ifdef DADMOD_PADINJECT
    if (!_stricmp(key, "gfx_padinject_go")) { if (padhub::g_injGo) SetEvent(padhub::g_injGo); return true; }  // test builds only
#endif
    if (!_stricmp(key, "gfx_fwnow")) { FireworksShow(12, "menu"); return true; }
    if (!_strnicmp(key, "gfx_level_", 10)) { SetLevel(key + 10); return true; }
    if (!_stricmp(key, "gfx_lampadd")) { LampMark(true); return true; }
    if (!_stricmp(key, "gfx_lampdel")) { LampMark(false); return true; }
    if (!_stricmp(key, "gfx_servertod")) { g_serverTod = value < 0 || value > 5 ? 0 : value; return true; }
    if (!_stricmp(key, "gfx_balancing")) { g_balancing = value != 0; return true; }
    if (!_stricmp(key, "gfx_balancelock")) { balancelock::Set(value != 0); return true; }
    if (!_stricmp(key, "gfx_mainmenu")) { g_mainMenu = value != 0; return true; }
    if (!_stricmp(key, "gfx_menuup")) {
        static int n = 0;
        if ((value != 0) != g_menuUp && n < 6) { ++n; mmenu::Log("gfx: menu %s (mirror steering %s)", value ? "open" : "closed", value ? "paused" : "on if mirror mode is on"); }
        g_menuUp = value != 0;
        return true;
    }
    int i = Index(key);
    if (i < 0) return false;
    int was = g_val[i];
    g_val[i] = value < kSettings[i].lo ? kSettings[i].lo : value > kSettings[i].hi ? kSettings[i].hi : value;
    if (!_stricmp(key, "gfx_tricksfx") && was && !g_val[i]) StopSpecialStream("menu");
    if (!_stricmp(key, "gfx_tricksfx") && g_val[i] && was != g_val[i]) SetSpecialStreamVolume(g_trickBaseVol * g_val[i] / 100.0f);
    if (!_stricmp(key, "gfx_postfx")) {
        int set = Index("gfx_postfxset");
        if (set >= 0) g_val[set] = 1;   // the row was used: dadmod now switches ReShade's own effects with it
        if (was != g_val[i]) mmenu::Log("gfx: graphics effects -> %s (menu)", g_val[i] ? "ReShade (dadmod's screen effects skipped)" : "dadmod");
    }
    Save();
    SyncInput();
    InterlockedExchange(&g_dirtyPost, 1);
    return true;
}
bool GetKey(const char* key, int* value) {
    if (!_stricmp(key, "gfx_todnow")) { *value = TodNow(); return true; }
    int i = Index(key);
    if (i < 0) return false;
    *value = g_val[i];
    return true;
}
// THUGRECOMP_GfxReset: every graphics setting back to its default. Weather and fireworks have their own
// menu (dadmod > Weather), so they keep their values.
static bool __cdecl CF_GfxReset(void*, void*) {
    for (int i = 0; i < kCount; ++i) {
        const char* k = kSettings[i].key;
        if (!_strnicmp(k, "gfx_wx", 6) || !_stricmp(k, "gfx_weather") || !_stricmp(k, "gfx_fireworks") || !_stricmp(k, "gfx_fwevery") || !_stricmp(k, "gfx_bginput") || !_stricmp(k, "gfx_deadzone") || !_stricmp(k, "gfx_abswap") || !_stricmp(k, "gfx_launchbinds") || !_stricmp(k, "gfx_padpopup")) continue;
        g_val[i] = kSettings[i].def;
    }
    Save();
    InterlockedExchange(&g_dirtyPost, 1);
    return true;
}

// ---- ReShade detection (Noah 2026-11-19: "if someone has reshade installed there should be a toggle for it in dadmod")
// ReShade can sit in the game as d3d9.dll, dxgi.dll, an .asi loaded by an ASI loader (dinput8.dll), or any other name,
// so loaded modules are checked by their version resource (ProductName "ReShade", every version) and, for 5.x and later,
// by the exports of its add-on API. Nothing is read from or written to ReShade's files except its ReShade.ini [INPUT]
// KeyEffects (read only), to name the key that switches ReShade's own effects on and off.
struct ReShadeFound { bool found; int major, minor, patch; bool addonApi; char module[MAX_PATH]; char key[64]; int vk, ctrl, shift, alt; };
static ReShadeFound g_reshade;
static bool ResHasUtf16(const BYTE* p, DWORD n, const wchar_t* w) {
    size_t len = wcslen(w) * 2;
    for (DWORD i = 0; i + len <= n; i += 2) if (!memcmp(p + i, w, len)) return true;
    return false;
}
static bool ModuleIsReShade(HMODULE m, int* major, int* minor, int* patch) {
    HRSRC r = FindResourceW(m, MAKEINTRESOURCEW(1), MAKEINTRESOURCEW(16));  // VS_VERSION_INFO, RT_VERSION
    if (!r) return false;
    HGLOBAL g = LoadResource(m, r);
    const BYTE* p = g ? (const BYTE*)LockResource(g) : nullptr;
    DWORD n = SizeofResource(m, r);
    if (!p || n < 64 || !ResHasUtf16(p, n, L"ReShade")) return false;
    for (DWORD i = 0; i + 52 <= n; i += 4) {
        if (*(const DWORD*)(p + i) != 0xFEEF04BD) continue;   // VS_FIXEDFILEINFO
        DWORD ms = *(const DWORD*)(p + i + 16), ls = *(const DWORD*)(p + i + 20);  // dwProductVersionMS / LS
        *major = HIWORD(ms); *minor = LOWORD(ms); *patch = HIWORD(ls);
        return true;
    }
    *major = *minor = *patch = 0;
    return true;
}
static int g_rsVk, g_rsCtrl, g_rsShift, g_rsAlt;   // the effects key read by the last ReShadeKeyName that found one
static void ReShadeKeyName(const char* iniDir, char* out, size_t outLen) {
    char ini[MAX_PATH], val[64] = "";
    _snprintf(ini, sizeof ini, "%sReShade.ini", iniDir); ini[sizeof ini - 1] = 0;
    GetPrivateProfileStringA("INPUT", "KeyEffects", "", val, sizeof val, ini);
    int vk = 0, ctrl = 0, shift = 0, alt = 0;
    if (!val[0] || sscanf(val, "%d,%d,%d,%d", &vk, &ctrl, &shift, &alt) < 1 || vk <= 0 || vk > 255) { out[0] = 0; return; }
    g_rsVk = vk; g_rsCtrl = ctrl; g_rsShift = shift; g_rsAlt = alt;
    char name[48] = "";
    UINT sc = MapVirtualKeyA((UINT)vk, 0);  // MAPVK_VK_TO_VSC
    LONG lp = (LONG)(sc << 16);
    if ((vk >= VK_PRIOR && vk <= VK_DOWN) || vk == VK_INSERT || vk == VK_DELETE || vk == VK_DIVIDE || vk == VK_NUMLOCK) lp |= 1 << 24;
    if (!GetKeyNameTextA(lp, name, sizeof name)) _snprintf(name, sizeof name, "key %d", vk);
    _snprintf(out, outLen, "%s%s%s%s", ctrl ? "Ctrl+" : "", shift ? "Shift+" : "", alt ? "Alt+" : "", name);
    out[outLen - 1] = 0;
}
static const ReShadeFound& DetectReShade() {
    if (g_reshade.found) return g_reshade;
    HANDLE snap = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE | TH32CS_SNAPMODULE32, GetCurrentProcessId());
    if (snap == INVALID_HANDLE_VALUE) return g_reshade;
    MODULEENTRY32 me; me.dwSize = sizeof me;
    for (BOOL ok = Module32First(snap, &me); ok; ok = Module32Next(snap, &me)) {
        int a, b, c;
        bool api = GetProcAddress(me.hModule, "ReShadeRegisterAddon") != nullptr;
        if (!ModuleIsReShade(me.hModule, &a, &b, &c) && !api) continue;
        g_reshade.found = true; g_reshade.major = a; g_reshade.minor = b; g_reshade.patch = c; g_reshade.addonApi = api;
        if (api && !a) g_reshade.major = 5;   // has the add-on API but no readable version: 5.0 or later
        GetModuleFileNameA(me.hModule, g_reshade.module, MAX_PATH);
        char dir[MAX_PATH]; strcpy(dir, g_reshade.module);
        char* sl = strrchr(dir, '\\'); if (sl) sl[1] = 0; else dir[0] = 0;
        ReShadeKeyName(dir, g_reshade.key, sizeof g_reshade.key);
        if (!g_reshade.key[0]) {   // ReShade 5/6 keep ReShade.ini next to the game exe
            GetModuleFileNameA(nullptr, dir, MAX_PATH);
            sl = strrchr(dir, '\\'); if (sl) sl[1] = 0;
            ReShadeKeyName(dir, g_reshade.key, sizeof g_reshade.key);
        }
        if (g_reshade.key[0]) { g_reshade.vk = g_rsVk; g_reshade.ctrl = g_rsCtrl; g_reshade.shift = g_rsShift; g_reshade.alt = g_rsAlt; }
        mmenu::Log("gfx: ReShade %d.%d.%d found (%s)%s; effects key: %s", g_reshade.major, g_reshade.minor, g_reshade.patch,
                   g_reshade.module, api ? ", add-on API present" : "", g_reshade.key[0] ? g_reshade.key : "not set in ReShade.ini");
        break;
    }
    CloseHandle(snap);
    return g_reshade;
}
// THUGRECOMP_ReShadeInfo -> false when no ReShade is loaded; else true with version = "4.2.1", major (int),
// addon_api (int), effects_key = the effects key from ReShade.ini ("" if none), desc = the text for the menu row.
static bool __cdecl CF_ReShadeInfo(void*, void* script) {
    const ReShadeFound& r = DetectReShade();
    if (!r.found) return false;
    char ver[32], desc[400];
    _snprintf(ver, sizeof ver, "%d.%d.%d", r.major, r.minor, r.patch); ver[sizeof ver - 1] = 0;
    char keyPart[120];
    if (r.key[0]) _snprintf(keyPart, sizeof keyPart, "This row also switches ReShade's own effects (its key: %s).", r.key);
    else _snprintf(keyPart, sizeof keyPart, "ReShade's own effects go on and off with its effects key (none set in ReShade.ini).");
    keyPart[sizeof keyPart - 1] = 0;
    _snprintf(desc, sizeof desc, "ReShade %s is installed. dadmod: dadmod's graphics effects. ReShade: only ReShade's; dadmod skips "
              "its screen effects (color, bloom, FXAA, CRT and the rest); sky, weather, mirror mode, FPS and screenshots keep "
              "working. %s", ver, keyPart);
    desc[sizeof desc - 1] = 0;
    ::RetStr(script, "version", ver);
    ::RetInt(script, "major", r.major);
    ::RetInt(script, "addon_api", r.addonApi ? 1 : 0);
    ::RetStr(script, "effects_key", r.key);
    ::RetStr(script, "desc", desc);
    return true;
}

static float g_nightLift = 0;  // Night time of day: how much ps_look lifts the darks (eases in and out)
static bool WeatherOn();
static bool FireworksLive();
static bool LampsOn();
static bool MistOn() { return V("gfx_todfog") > 0 && !g_mainMenu; }  // Fog row: ground mist (2026-11-21)
static bool DepthWanted() { return MistOn() || V("gfx_debug") || V("gfx_ssao") || V("gfx_fog") || V("gfx_dof") || V("gfx_outline") || WeatherOn() || FireworksLive() || LampsOn(); }
static bool SceneWanted() {
    return V("gfx_fxaa") || V("gfx_sharpen") || V("gfx_bloom") || V("gfx_bright") || V("gfx_contrast") || V("gfx_sat") ||
           V("gfx_vibrance") || V("gfx_gamma") || V("gfx_preset") || V("gfx_temp") || V("gfx_tint") || DepthWanted() ||
           V("gfx_mblur") || V("gfx_pixelate") || WeatherOn() || FireworksLive() || LampsOn() || g_nightLift > 0.01f;
}
static bool ScreenWanted() { return V("gfx_vignette") || V("gfx_grain") || V("gfx_chroma") || V("gfx_crt"); }

// ---- hook plumbing --------------------------------------------------------------------------------
typedef HRESULT(STDMETHODCALLTYPE* SetSamplerState_t)(IDirect3DDevice9*, DWORD, D3DSAMPLERSTATETYPE, DWORD);
typedef HRESULT(STDMETHODCALLTYPE* Present_t)(IDirect3DDevice9*, const RECT*, const RECT*, HWND, const RGNDATA*);
typedef HRESULT(STDMETHODCALLTYPE* Reset_t)(IDirect3DDevice9*, D3DPRESENT_PARAMETERS*);
typedef HRESULT(STDMETHODCALLTYPE* CreateDevice_t)(IDirect3D9*, UINT, D3DDEVTYPE, HWND, DWORD, D3DPRESENT_PARAMETERS*, IDirect3DDevice9**);
typedef HRESULT(STDMETHODCALLTYPE* SCPresent_t)(IDirect3DSwapChain9*, const RECT*, const RECT*, HWND, const RGNDATA*, DWORD);
typedef HRESULT(STDMETHODCALLTYPE* SetTransform_t)(IDirect3DDevice9*, D3DTRANSFORMSTATETYPE, const D3DMATRIX*);
typedef HRESULT(STDMETHODCALLTYPE* DIP_t)(IDirect3DDevice9*, D3DPRIMITIVETYPE, INT, UINT, UINT, UINT, UINT);
typedef HRESULT(STDMETHODCALLTYPE* DPUP_t)(IDirect3DDevice9*, D3DPRIMITIVETYPE, UINT, const void*, UINT);
typedef HRESULT(STDMETHODCALLTYPE* SetDS_t)(IDirect3DDevice9*, IDirect3DSurface9*);
typedef HRESULT(STDMETHODCALLTYPE* SetFVF_t)(IDirect3DDevice9*, DWORD);
typedef HRESULT(STDMETHODCALLTYPE* DP_t)(IDirect3DDevice9*, D3DPRIMITIVETYPE, UINT, UINT);
typedef HRESULT(STDMETHODCALLTYPE* SetRS_t)(IDirect3DDevice9*, D3DRENDERSTATETYPE, DWORD);
static SetSamplerState_t g_origSSS = nullptr;
static Present_t g_origPresent = nullptr;
static Reset_t g_origReset = nullptr;
static CreateDevice_t g_origCreate = nullptr;
static SCPresent_t g_origSCPresent = nullptr;
static SetTransform_t g_origST = nullptr;
static DIP_t g_origDIP = nullptr;
static DPUP_t g_origDPUP = nullptr;
static SetDS_t g_origDS = nullptr;
static SetFVF_t g_origFVF = nullptr;
static DP_t g_origDP = nullptr;
static SetRS_t g_origRS = nullptr;
// Mirror mode (Noah 2026-10-20): the 3D camera itself is mirrored (projection X flipped, culling swapped while
// the 3D scene draws), so everything the game draws in 3D is mirrored no matter when it is drawn. 2D (HUD,
// menus, text) is untouched. Replaces the old flip of the finished picture, which missed late 3D draws.
static DWORD g_cullWant = D3DCULL_CCW;  // the cull mode the game asked for
static bool MirrorOn();
static DWORD SwapCull(DWORD c);

static bool g_inPost = false;     // our own draws: hooks pass straight through
static DWORD g_presents = 0;
static bool g_sceneDone = false;  // scene effects already ran this frame (so 2D drawing has started)
static bool g_galaxyDone = false;
static bool g_galaxyOff = false;  // set when this card has no shader for the galaxy: the game's own sky is kept (2026-11-21)
static bool GalaxyOn() { return V("gfx_galaxy") != 0 && !g_galaxyOff; }
static bool g_skyGraded = false;  // the game's own sky was graded this frame
static bool g_skyPass = false;
static D3DMATRIX g_view = {}, g_proj = {};
static bool g_haveProj = false;

// ProbeD3D9 (on the loading thread) and PatchThread can patch the same vtable slot at the same time;
// without the lock the second one could read our own hook back as "original" and recurse until the
// stack overflows (Dev boot crash 0xC00000FD in HookCreate, 2026-10-21).
static volatile LONG g_patchLock = 0;
static void Patch(void** vt, int idx, void* hook, void** orig) {
    while (InterlockedExchange(&g_patchLock, 1)) Sleep(0);
    DWORD old;
    if (vt[idx] != hook && VirtualProtect(&vt[idx], sizeof(void*), PAGE_EXECUTE_READWRITE, &old)) {
        *orig = vt[idx];
        vt[idx] = hook;
        VirtualProtect(&vt[idx], sizeof(void*), old, &old);
    }
    InterlockedExchange(&g_patchLock, 0);
}

// ---- texture filtering ------------------------------------------------------------------------
static HRESULT STDMETHODCALLTYPE HookSSS(IDirect3DDevice9* dev, DWORD s, D3DSAMPLERSTATETYPE type, DWORD v) {
    if (!g_inPost) {
        static const int kAniso[] = {0, 2, 4, 8, 16};
        int a = kAniso[V("gfx_aniso")];
        if (g_sceneDone && V("gfx_uismooth") && (type == D3DSAMP_MINFILTER || type == D3DSAMP_MAGFILTER) && v == D3DTEXF_POINT)
            v = D3DTEXF_LINEAR;
        if (type == D3DSAMP_MINFILTER && a > 1 && (v == D3DTEXF_LINEAR || v == D3DTEXF_POINT)) {
            g_origSSS(dev, s, D3DSAMP_MAXANISOTROPY, (DWORD)a);
            v = D3DTEXF_ANISOTROPIC;
        }
        if (type == D3DSAMP_MINFILTER || type == D3DSAMP_MIPFILTER) {
            float b = -0.25f * V("gfx_lodbias");
            g_origSSS(dev, s, D3DSAMP_MIPMAPLODBIAS, *(DWORD*)&b);
        }
    }
    return g_origSSS(dev, s, type, v);
}

// ---- MSAA / v-sync at device creation ----------------------------------------------------------
static IDirect3D9* g_d3d = nullptr;
static HWND g_devWnd = nullptr;   // the game's device window (ReShade reads its keys from this window's messages)
static UINT g_adapter = 0;
static D3DDEVTYPE g_devType = D3DDEVTYPE_HAL;
static bool g_msaaOn = false;

static void AdjustPP(IDirect3D9* d3d, UINT adapter, D3DDEVTYPE type, D3DPRESENT_PARAMETERS* pp) {
    int vs = V("gfx_vsync");
    if (vs == 1) pp->PresentationInterval = D3DPRESENT_INTERVAL_ONE;
    if (vs == 2) pp->PresentationInterval = D3DPRESENT_INTERVAL_IMMEDIATE;
    static const D3DMULTISAMPLE_TYPE kMs[] = {D3DMULTISAMPLE_NONE, D3DMULTISAMPLE_2_SAMPLES, D3DMULTISAMPLE_4_SAMPLES, D3DMULTISAMPLE_8_SAMPLES};
    D3DMULTISAMPLE_TYPE ms = kMs[V("gfx_msaa")];
    if (ms == D3DMULTISAMPLE_NONE || !d3d) return;
    if (pp->Flags & D3DPRESENTFLAG_LOCKABLE_BACKBUFFER) { mmenu::Log("gfx: MSAA skipped (lockable back buffer)"); return; }
    D3DFORMAT bb = pp->BackBufferFormat == D3DFMT_UNKNOWN ? D3DFMT_X8R8G8B8 : pp->BackBufferFormat;
    DWORD q = 0;
    if (FAILED(d3d->CheckDeviceMultiSampleType(adapter, type, bb, pp->Windowed, ms, &q)) ||
        (pp->EnableAutoDepthStencil && FAILED(d3d->CheckDeviceMultiSampleType(adapter, type, pp->AutoDepthStencilFormat, pp->Windowed, ms, &q)))) {
        mmenu::Log("gfx: MSAA %dx not supported here", (int)ms);
        return;
    }
    pp->MultiSampleType = ms;
    pp->MultiSampleQuality = 0;
    pp->SwapEffect = D3DSWAPEFFECT_DISCARD;
}

static void PatchDevice(IDirect3DDevice9* dev);
static HRESULT STDMETHODCALLTYPE HookCreate(IDirect3D9* d3d, UINT adapter, D3DDEVTYPE type, HWND w, DWORD flags,
                                            D3DPRESENT_PARAMETERS* pp, IDirect3DDevice9** out) {
    D3DPRESENT_PARAMETERS orig = *pp;
    g_d3d = d3d; g_adapter = adapter; g_devType = type;
    g_devWnd = pp->hDeviceWindow ? pp->hDeviceWindow : w;
    AdjustPP(d3d, adapter, type, pp);
    HRESULT hr = g_origCreate(d3d, adapter, type, w, flags, pp, out);
    if (FAILED(hr) && memcmp(&orig, pp, sizeof orig)) {
        mmenu::Log("gfx: device with MSAA/v-sync failed (0x%08lX), using the game's own settings", hr);
        *pp = orig;
        hr = g_origCreate(d3d, adapter, type, w, flags, pp, out);
    }
    if (SUCCEEDED(hr) && out && *out) {
        g_msaaOn = pp->MultiSampleType != D3DMULTISAMPLE_NONE;
        PatchDevice(*out);
        mmenu::Log("gfx: device %ux%u %s, MSAA %d, present interval 0x%lX", pp->BackBufferWidth, pp->BackBufferHeight,
                   pp->Windowed ? "windowed" : "fullscreen", (int)pp->MultiSampleType, pp->PresentationInterval);
    }
    return hr;
}

// ---- shaders ------------------------------------------------------------------------------------
struct XBuf : IUnknown { virtual void* STDMETHODCALLTYPE GetBufferPointer() = 0; virtual DWORD STDMETHODCALLTYPE GetBufferSize() = 0; };
typedef HRESULT(WINAPI* CompileShader_t)(LPCSTR, UINT, const void*, void*, LPCSTR, LPCSTR, DWORD, XBuf**, XBuf**, void**);
typedef HRESULT(WINAPI* SaveSurface_t)(LPCWSTR, DWORD, IDirect3DSurface9*, const PALETTEENTRY*, const RECT*);   // the wide one (2026-11-19: a PC where ANSI full-path file opens fail)

static const char kShaders[] = R"HLSL(
sampler2D s0 : register(s0);
sampler2D s1 : register(s1);
sampler2D s2 : register(s2);
sampler2D s3 : register(s3);
sampler2D s4 : register(s4);  // ambient occlusion (scene pass)
float4 px : register(c0);    // 1/w, 1/h, w, h
float4 p1 : register(c1);    // sharpen, bloom, vignette, time (s)
float4 p2 : register(c2);    // brightness, contrast, saturation, gamma exponent
float4 p3 : register(c3);    // vibrance, grey, lift, -
float4 p4 : register(c4);    // tint rgb
float4 dir : register(c5);   // blur direction (texels)
float4 p6 : register(c6);    // ssao, fog, dof, outline mode
float4 pj : register(c7);    // projection _11 _22 _33 _43
float4 p8 : register(c8);    // pixel size, motion blur weight, grain, chroma
float4 p9 : register(c9);    // crt, galaxy style, depth available, -
float4 vr : register(c10);   // camera right
float4 vu : register(c11);   // camera up
float4 vb : register(c12);   // camera back
float4 fogc : register(c13); // haze color
float4 tx0 : register(c14);  // FPS text glyphs 0-3 (-1 = blank)
float4 tx1 : register(c15);  // glyphs 4-6, screenshot flash
float4 sk : register(c16);   // sky pass: time of day (0-5), sky boost (0-1), next time of day, blend; screen pass: -, -, tiny FPS, -
float4 wx : register(c17);   // weather amounts: rain, snow, fog, storm (0-1+)
float4 wx2 : register(c18);  // light level (1 day .. 0.3 night), lightning threshold, wet, -
float4 wxc : register(c19);  // fog / overcast color
float4 fw[8] : register(c20); // fireworks shells: azimuth, elevation, age (s, < 0 = rising), hue
struct V { float4 pos : POSITION; float2 uv : TEXCOORD0; };
V vs_main(V v) { return v; }
static const float3 L = float3(0.299, 0.587, 0.114);

float hash13(float3 p) { p = frac(p * 0.1031); p += dot(p, p.zyx + 31.32); return frac((p.x + p.y) * p.z); }
float hash12(float2 p) { float3 q = frac(float3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return frac((q.x + q.y) * q.z); }
float noise3(float3 x) {
    float3 i = floor(x), f = frac(x);
    f = f * f * (3 - 2 * f);
    return lerp(lerp(lerp(hash13(i), hash13(i + float3(1, 0, 0)), f.x), lerp(hash13(i + float3(0, 1, 0)), hash13(i + float3(1, 1, 0)), f.x), f.y),
                lerp(lerp(hash13(i + float3(0, 0, 1)), hash13(i + float3(1, 0, 1)), f.x), lerp(hash13(i + float3(0, 1, 1)), hash13(i + float3(1, 1, 1)), f.x), f.y), f.z);
}
float fbm(float3 p) { float a = 0.5, s = 0; [loop] for (int i = 0; i < 5; i++) { s += a * noise3(p); p = p * 2.03 + 1.7; a *= 0.5; } return s; }

float3 fxaa(float2 uv) {
    float3 nw = tex2D(s0, uv + float2(-1, -1) * px.xy).rgb, ne = tex2D(s0, uv + float2(1, -1) * px.xy).rgb;
    float3 sw = tex2D(s0, uv + float2(-1, 1) * px.xy).rgb, se = tex2D(s0, uv + float2(1, 1) * px.xy).rgb;
    float3 m = tex2D(s0, uv).rgb;
    float lnw = dot(nw, L), lne = dot(ne, L), lsw = dot(sw, L), lse = dot(se, L), lm = dot(m, L);
    float lmin = min(lm, min(min(lnw, lne), min(lsw, lse))), lmax = max(lm, max(max(lnw, lne), max(lsw, lse)));
    float2 d = float2(-((lnw + lne) - (lsw + lse)), (lnw + lsw) - (lne + lse));
    float red = max((lnw + lne + lsw + lse) * (0.25 / 8.0), 1.0 / 128.0);
    float rcp = 1.0 / (min(abs(d.x), abs(d.y)) + red);
    d = clamp(d * rcp, -8.0, 8.0) * px.xy;
    float3 a = 0.5 * (tex2D(s0, uv + d * (1.0 / 3.0 - 0.5)).rgb + tex2D(s0, uv + d * (2.0 / 3.0 - 0.5)).rgb);
    float3 b = a * 0.5 + 0.25 * (tex2D(s0, uv - d * 0.5).rgb + tex2D(s0, uv + d * 0.5).rgb);
    float lb = dot(b, L);
    return (lb < lmin || lb > lmax) ? a : b;
}
float4 ps_fxaa(float2 uv : TEXCOORD0) : COLOR { return float4(fxaa(uv), 1); }
float4 ps_mirror(float2 uv : TEXCOORD0) : COLOR { return float4(tex2D(s0, float2(1 - uv.x, uv.y)).rgb, 1); }

float4 ps_bright(float2 uv : TEXCOORD0) : COLOR {
    float3 c = 0.25 * (tex2D(s0, uv + px.xy * float2(-1, -1)).rgb + tex2D(s0, uv + px.xy * float2(1, -1)).rgb +
                       tex2D(s0, uv + px.xy * float2(-1, 1)).rgb + tex2D(s0, uv + px.xy * float2(1, 1)).rgb);
    return float4(c * saturate((dot(c, L) - 0.6) * 2.5), 1);
}
float4 ps_down(float2 uv : TEXCOORD0) : COLOR {
    return float4(0.25 * (tex2D(s0, uv + px.xy * float2(-1, -1)).rgb + tex2D(s0, uv + px.xy * float2(1, -1)).rgb +
                          tex2D(s0, uv + px.xy * float2(-1, 1)).rgb + tex2D(s0, uv + px.xy * float2(1, 1)).rgb), 1);
}
float4 ps_blur(float2 uv : TEXCOORD0) : COLOR {
    float3 c = tex2D(s0, uv).rgb * 0.227;
    c += (tex2D(s0, uv + dir.xy * 1.385).rgb + tex2D(s0, uv - dir.xy * 1.385).rgb) * 0.316;
    c += (tex2D(s0, uv + dir.xy * 3.231).rgb + tex2D(s0, uv - dir.xy * 3.231).rgb) * 0.070;
    return float4(c, 1);
}

// scene: s0 color, s1 depth (INTZ), s2 previous frame, s3 blurred quarter-res scene
float dist(float d) { return d >= 0.99999 ? 100000.0 : pj.w / min(d + pj.z, -0.000001); }  // view distance: _43 / (depth + _33)
float4 ps_scene(float2 uv : TEXCOORD0) : COLOR {
    if (p8.x > 1) uv = (floor(uv * px.zw / p8.x) + 0.5) * p8.x / px.zw;
    float3 c = tex2D(s0, uv).rgb;
    if (p9.z > 0) {
        float d0 = tex2D(s1, uv).r, z = dist(d0);
        if (p9.w > 1.5) return float4(frac(d0 * 10), frac(d0 * 100), frac(d0 * 1000), 1);
        if (p9.w > 0.5) return float4(saturate(z / 3000.0).xxx, 1);
        bool sky = d0 >= 0.99999;
        if (p6.x > 0 && !sky) c *= tex2D(s4, uv).r;
        if (p6.w > 0) {  // outlines from depth edges, cel bands
            float zr = dist(tex2D(s1, uv + float2(px.x, 0)).r), zl = dist(tex2D(s1, uv - float2(px.x, 0)).r);
            float zu = dist(tex2D(s1, uv - float2(0, px.y)).r), zd = dist(tex2D(s1, uv + float2(0, px.y)).r);
            float lap = abs(zr + zl + zu + zd - 4 * min(z, 20000.0)) / min(z, 20000.0);
            c *= 1 - 0.85 * saturate((lap - 0.06) * 6);
            if (p6.w > 1.5) { float l = dot(c, L); float q = floor(l * 4 + 0.5) / 4 + 0.08; c *= q / max(l, 0.02); }
        }
        if (p6.y > 0 && !sky) c = lerp(c, fogc.rgb, 1 - exp(-z * p6.y * 0.00006));
        if (p6.z > 0) c = lerp(c, tex2D(s3, uv).rgb, saturate((z - 900.0) / 2500.0) * min(1.0, p6.z * 0.12));
    }
    if (p8.y > 0) c = lerp(c, tex2D(s2, uv).rgb, p8.y);
    return float4(c, 1);
}

// ambient occlusion: s1 depth. Samples are compared with the surface's own plane (1/distance is linear on
// screen), so flat floors and walls do not shadow themselves; only real creases and nearby objects do.
float4 ps_ao(float2 uv : TEXCOORD0) : COLOR {
    float d0 = tex2D(s1, uv).r;
    if (d0 >= 0.99999) return float4(1, 1, 1, 1);
    float z = dist(d0), iz = 1.0 / z;
    float izx = 1.0 / dist(tex2D(s1, uv + float2(px.x, 0)).r) - iz, izy = 1.0 / dist(tex2D(s1, uv + float2(0, px.y)).r) - iz;
    float izx2 = iz - 1.0 / dist(tex2D(s1, uv - float2(px.x, 0)).r), izy2 = iz - 1.0 / dist(tex2D(s1, uv - float2(0, px.y)).r);
    if (abs(izx2) < abs(izx)) izx = izx2;  // the smaller slope avoids stepping over edges
    if (abs(izy2) < abs(izy)) izy = izy2;
    float rad = clamp(36.0 * pj.y * 0.5 * px.w / z, 4.0, 48.0);
    float ang = hash12(floor(uv * px.zw)) * 6.2832, occ = 0;
    for (int i = 0; i < 12; i++) {
        float a = ang + i * 2.3999, r = rad * (0.2 + 0.8 * frac(i * 0.618 + 0.13));
        float2 o = float2(cos(a), sin(a)) * r;
        float zs = dist(tex2D(s1, uv + o * px.xy).r);
        float zp = 1.0 / max(iz + izx * o.x + izy * o.y, 0.000001);  // the plane's distance there
        float dz = zp - zs;
        occ += saturate((dz - 3.0) / 12.0) * saturate(1.0 - dz / 90.0);
    }
    return float4((1.0 - saturate(occ / 12.0 * p6.x * 0.24)).xxx, 1);
}
float4 ps_aoblur(float2 uv : TEXCOORD0) : COLOR {  // depth-aware blur of the AO, direction in dir
    float z = dist(tex2D(s1, uv).r), sum = 0, w = 0;
    for (int i = -4; i <= 4; i++) {
        float2 o = dir.xy * i;
        float zs = dist(tex2D(s1, uv + o).r);
        float k = exp(-i * i / 8.0) * saturate(1.0 - abs(zs - z) / (z * 0.05 + 2.0));
        sum += tex2D(s0, uv + o).r * k;
        w += k;
    }
    return float4((sum / max(w, 0.0001)).xxx, 1);
}

// look: s0 color, s1 bloom
float4 ps_look(float2 uv : TEXCOORD0) : COLOR {
    float3 c = tex2D(s0, uv).rgb;
    if (p1.x > 0) {  // contrast adaptive sharpening (after AMD CAS)
        float3 n = tex2D(s0, uv + float2(0, -px.y)).rgb, s = tex2D(s0, uv + float2(0, px.y)).rgb;
        float3 e = tex2D(s0, uv + float2(px.x, 0)).rgb, w = tex2D(s0, uv + float2(-px.x, 0)).rgb;
        float3 mn = min(min(min(n, s), min(e, w)), c), mx = max(max(max(n, s), max(e, w)), c);
        float3 amp = sqrt(saturate(min(mn, 1 - mx) / max(mx, 0.0001)));
        float3 wt = amp * (-1.0 / lerp(8.0, 4.0, p1.x));
        c = saturate((c + (n + s + e + w) * wt) / (1 + 4 * wt));
    }
    if (p1.y > 0) c += tex2D(s1, uv).rgb * p1.y;
    c = c + p2.x;
    c = (c - 0.5) * p2.y + 0.5;
    float l = dot(c, L);
    c = lerp(float3(l, l, l), c, p2.z);
    if (p3.x > 0) {
        float sat = max(c.r, max(c.g, c.b)) - min(c.r, min(c.g, c.b));
        c = lerp(float3(l, l, l), c, 1 + p3.x * (1 - sat));
    }
    c = lerp(c, float3(l, l, l), p3.y) * p4.rgb;
    c = c * (1 - p3.z) + p3.z;
    if (p3.w > 0) c = pow(saturate(c), 1.0 / (1.0 + p3.w));  // Night: lift the darks so the level stays visible
    c = pow(saturate(c), p2.w);
    return float4(saturate(c), 1);
}

// 3x5 pixel font: 0-9, F (10), P (11), S (12); bits row by row from the top left
float gmask(float g) {
    float m = 0;
    if (g < 0.5) m = 31599; else if (g < 1.5) m = 11415; else if (g < 2.5) m = 29671; else if (g < 3.5) m = 29647;
    else if (g < 4.5) m = 23497; else if (g < 5.5) m = 31183; else if (g < 6.5) m = 31215; else if (g < 7.5) m = 29330;
    else if (g < 8.5) m = 31727; else if (g < 9.5) m = 31695; else if (g < 10.5) m = 31140; else if (g < 11.5) m = 31716;
    else if (g < 12.5) m = 31183;
    return m;
}
float textAt(float2 p) {  // p in screen pixels; 1 where a lit font cell is
    bool tiny = sk.z > 0.5;
    float2 o = p - (tiny ? float2(2, 2) : float2(14, 14));
    float sc = tiny ? 2 : 4;
    if (o.x < 0 || o.y < 0 || o.y >= 5 * sc || o.x >= 7 * 4 * sc) return 0;
    float slot = floor(o.x / (4 * sc));
    float2 cell = floor(float2(o.x - slot * 4 * sc, o.y) / sc);
    if (cell.x > 2) return 0;
    float g = slot < 0.5 ? tx0.x : slot < 1.5 ? tx0.y : slot < 2.5 ? tx0.z : slot < 3.5 ? tx0.w : slot < 4.5 ? tx1.x : slot < 5.5 ? tx1.y : tx1.z;
    if (g < -0.5) return 0;
    float bit = 14 - (cell.y * 3 + cell.x);
    return fmod(floor(gmask(g) / exp2(bit)), 2);
}
// screen: s0 the whole frame (HUD included)
float4 ps_screen(float2 uv : TEXCOORD0) : COLOR {
    float2 q = uv - 0.5;
    if (p9.x > 1.5) {  // curved screen
        q *= 1 + dot(q, q) * 0.18;
        uv = q + 0.5;
        if (any(uv < 0) || any(uv > 1)) return float4(0, 0, 0, 1);
    }
    float3 c;
    if (p8.w > 0) {
        float2 o = q * p8.w * 0.0035;
        c = float3(tex2D(s0, uv + o).r, tex2D(s0, uv).g, tex2D(s0, uv - o).b);
    } else c = tex2D(s0, uv).rgb;
    if (p9.x > 0) {
        float scan = 0.78 + 0.22 * sin(uv.y * px.w * 3.14159);
        float mask = 0.92 + 0.08 * sin(uv.x * px.z * 2.0944);
        c *= scan * mask * 1.12;
    }
    if (p8.z > 0) c += (hash12(uv * px.zw + frac(p1.w * 7.13) * 431.0) - 0.5) * p8.z * 0.035;
    if (p1.z > 0) c *= 1 - p1.z * smoothstep(0.25, 0.75, dot(q, q) * 2.2);
    if (tx0.x > -0.5 || tx0.y > -0.5 || tx0.z > -0.5) {
        float2 sp = uv * px.zw;
        if (sk.z > 0.5) { if (sp.x < 2 + 3 * 8 + 1 && sp.y < 2 + 10 + 1) c *= 0.45; }
        else if (sp.x < 14 + 7 * 16 + 6 && sp.y < 14 + 20 + 6 && sp.x > 8 && sp.y > 8) c *= 0.35;
        float t = textAt(sp);
        c = lerp(c, float3(0.49, 0.99, 0.49), t);
    }
    c = lerp(c, float3(1, 1, 1), tx1.w);
    return float4(saturate(c), 1);
}

// matrix code rain: columns around the horizon, glyphs fall toward the ground
float3 matrixsky(float3 d, float t) {
    float az = atan2(d.x, d.z), el = asin(clamp(d.y, -1, 1));
    const float cols = 190.0;
    float cw = 6.2831853 / cols;
    float u = (az / 6.2831853 + 0.5) * cols, v = el / (cw * 1.35);
    float ci = floor(u), row = floor(v);
    float2 f = float2(frac(u), frac(v));
    float3 col = float3(0.0, 0.018, 0.006);
    float lit = 0, head = 0;
    for (int k = 0; k < 2; k++) {
        float h1 = hash12(float2(ci, 3.7 + k * 11.0)), h2 = hash12(float2(ci, 9.1 + k * 5.0));
        float speed = 4.0 + h1 * 9.0, len = 7.0 + h2 * 20.0, span = 46.0 + len;
        float hd = 32.0 - fmod(t * speed + h2 * 97.0 + k * 23.0, span);
        float dist = row - hd;
        if (dist >= 0 && dist < len) { lit = max(lit, 1 - dist / len); if (dist < 1) head = 1; }
    }
    float gid = floor(hash12(float2(ci, row)) * 50.0 + t * (0.5 + hash12(float2(row, ci)) * 3.0));
    float2 g = floor(f * float2(7, 8));
    float gx = abs(g.x - 3);  // mirrored, so each cell reads as a glyph
    float bit = (g.x < 6 && g.y < 7 && g.x > 0) ? step(0.45, hash12(float2(gid * 7.31 + gx, g.y * 3.17 + ci * 0.13))) : 0;
    float fade = saturate((1.45 - abs(el)) * 2.5);
    col += bit * fade * (lit * lit * float3(0.10, 1.0, 0.35) * 1.4 + head * float3(0.75, 1.0, 0.8));
    col += bit * fade * 0.05 * float3(0.0, 0.6, 0.2);
    return col;
}
// galaxy sky: s-less, direction from the camera
float3 galaxy(float3 d, float style, float t) {
    if (style > 3.5) return matrixsky(d, t);
    float3 col = 0;
    float3 bandN = normalize(float3(0.35, 0.85, 0.25));
    float band = exp(-pow(dot(d, bandN) * 3.2, 2));
    float n1 = fbm(d * 2.6 + style * 3.1), n2 = fbm(d * 5.3 + 11.0);
    float3 a, b;
    if (style < 1.5) { a = float3(0.55, 0.62, 0.85); b = float3(0.95, 0.80, 0.65); }       // milky way
    else if (style < 2.5) { a = float3(0.75, 0.25, 0.95); b = float3(0.15, 0.75, 0.95); }  // nebula
    else { a = float3(0.10, 0.18, 0.55); b = float3(0.45, 0.20, 0.60); }                   // deep space
    float neb = style < 1.5 ? band * pow(n1, 1.8) * 2.8 : pow(saturate(n1 * 1.35 - 0.25), 2.5) * (style < 2.5 ? 2.2 : 1.5);
    col += lerp(a, b, n2) * neb;
    col += float3(0.02, 0.02, 0.05);
    for (int k = 0; k < 3; k++) {
        float sc = k == 0 ? 70.0 : (k == 1 ? 160.0 : 330.0);
        float3 p = d * sc, ci = floor(p);
        float h = hash13(ci + k * 17.0);
        float3 r = float3(hash13(ci + 1.7), hash13(ci + 3.1), hash13(ci + 5.3));
        float dd = length(frac(p) - r);
        float thr = k == 2 ? 0.78 - band * 0.30 : 0.86;
        float s = step(thr, h) * pow(saturate(1 - dd * (k == 0 ? 2.2 : 3.0)), 10.0);
        float tw = 0.75 + 0.25 * sin(t * (1.5 + h * 3.0) + h * 40.0);
        col += s * tw * lerp(float3(0.75, 0.82, 1.0), float3(1.0, 0.85, 0.7), hash13(ci + 9.0)) * (k == 0 ? 3.0 : 1.8);
    }
    return col;
}
float4 ps_galaxy(float2 uv : TEXCOORD0) : COLOR {
    float2 ndc = float2(uv.x * 2 - 1, 1 - uv.y * 2);
    float3 d = normalize(vr.xyz * (ndc.x / pj.x) + vu.xyz * (ndc.y / pj.y) - vb.xyz);
    return float4(galaxy(d, p9.y, p1.w), 1);
}
// ---- extra animated skies (styles 5-14): own shader, so a compile problem can't take the other effects down
float3 hsv2rgb(float h, float s, float v) { float3 k = saturate(abs(frac(h + float3(0, 2.0 / 3, 1.0 / 3)) * 6 - 3) - 1); return v * lerp(1, k, s); }
float3 starfield(float3 d, float t, float dens) {
    float3 col = 0;
    [loop] for (int k = 0; k < 2; k++) {
        float sc = k == 0 ? 90.0 : 210.0;
        float3 p = d * sc, ci = floor(p);
        float h = hash13(ci + k * 17.0);
        float3 r = float3(hash13(ci + 1.7), hash13(ci + 3.1), hash13(ci + 5.3));
        float s = step(1 - dens * (k == 0 ? 0.10 : 0.22), h) * pow(saturate(1 - length(frac(p) - r) * 2.6), 10.0);
        col += s * (0.75 + 0.25 * sin(t * (1.5 + h * 3.0) + h * 40.0)) * (k == 0 ? 2.6 : 1.5);
    }
    return col * float3(0.85, 0.9, 1.0);
}
// starfield(d, t, 1.0) and starfield(d, t, 0.6) in one pass: the same cells and twinkle, two densities (2026-11-21, smaller shaders)
void starfield2(float3 d, float t, out float3 a, out float3 b) {
    a = 0; b = 0;
    [loop] for (int k = 0; k < 2; k++) {
        float sc = k == 0 ? 90.0 : 210.0;
        float3 p = d * sc, ci = floor(p);
        float h = hash13(ci + k * 17.0);
        float3 r = float3(hash13(ci + 1.7), hash13(ci + 3.1), hash13(ci + 5.3));
        float g = pow(saturate(1 - length(frac(p) - r) * 2.6), 10.0) * (0.75 + 0.25 * sin(t * (1.5 + h * 3.0) + h * 40.0)) * (k == 0 ? 2.6 : 1.5);
        a += step(1 - 1.0 * (k == 0 ? 0.10 : 0.22), h) * g;
        b += step(1 - 0.6 * (k == 0 ? 0.10 : 0.22), h) * g;
    }
    a *= float3(0.85, 0.9, 1.0); b *= float3(0.85, 0.9, 1.0);
}// the golden sky keeps the unrolled fbm3: as a loop its clouds come out in other places (2026-11-21 pixel compare)
float fbm3u(float3 p) { float a = 0.5, s = 0; [unroll] for (int i = 0; i < 3; i++) { s += a * noise3(p); p = p * 2.07 + 1.3; a *= 0.5; } return s / 0.875; }
// clouds on a flat ceiling over the camera: where the ray meets it
float2 dome(float3 d, float lift) { return d.xz / (max(d.y, 0) + lift); }
float fbm3(float3 p) { float a = 0.5, s = 0; [loop] for (int i = 0; i < 3; i++) { s += a * noise3(p); p = p * 2.07 + 1.3; a *= 0.5; } return s / 0.875; }

float3 sky_aurora(float3 d, float t, float az, float el) {
    float3 col = lerp(float3(0.02, 0.05, 0.08), float3(0.0, 0.01, 0.04), saturate(el * 1.4)) + starfield(d, t, 1.0) * 0.8;
    [loop] for (int i = 0; i < 3; i++) {
        float y0 = 0.22 + i * 0.13 + 0.07 * sin(az * 2.0 + i * 2.1 + t * 0.07) + 0.06 * (noise3(float3(az * 4.0, t * 0.12, i * 7.0)) - 0.5);
        float c = el - y0;
        float shape = c < 0 ? exp(-c * c * 900.0) : exp(-c * (9.0 - i * 2.0));
        float rays = 0.45 + 0.55 * noise3(float3(az * 55.0 + i * 13.0, t * 0.45, i));
        float pulse = 0.65 + 0.35 * noise3(float3(az * 3.0 - t * 0.2, i * 5.0, t * 0.05));
        float3 tint = lerp(float3(0.10, 1.0, 0.45), float3(0.65, 0.20, 0.95), saturate(c * 5.0 + i * 0.25));
        col += tint * shape * rays * pulse * (0.9 - i * 0.18);
    }
    return col;
}
float3 sky_synthwave(float3 d, float t, float az, float el) {
    float3 col = lerp(float3(1.0, 0.28, 0.55), float3(0.10, 0.02, 0.22), pow(saturate(el * 1.6), 0.7));
    col += starfield(d, t, 0.6) * saturate(el * 2.5 - 0.6);
    float2 sp = float2(az, el - 0.16) / 0.20;
    float r = length(sp);
    if (r < 1) {
        float stripes = sp.y > 0.05 ? 1 : step(0.5 + (0.05 - sp.y) * 0.75, frac(sp.y * 5.0 + t * 0.35));
        col = lerp(col, lerp(float3(1.0, 0.15, 0.55), float3(1.0, 0.92, 0.25), saturate(sp.y * 0.6 + 0.5)) * 1.3, stripes * smoothstep(1, 0.96, r));
    }
    col += float3(1.0, 0.3, 0.6) * exp(-max(r - 1, 0) * 3.0) * 0.35;
    if (el < 0.02) {
        float2 g = d.xz / max(-d.y + 0.03, 0.03);
        g.y += t * 2.0;
        float2 f = abs(frac(g * 0.5) - 0.5);
        float gl = saturate(1 - min(f.x, f.y) * 14.0);
        col = lerp(float3(0.05, 0.0, 0.10), float3(1.0, 0.2, 0.9), gl * saturate(-el * 8.0 + 0.3)) + float3(0.9, 0.2, 0.6) * exp(-abs(el) * 60.0) * 0.6;
    }
    return col;
}
float3 sky_storm(float3 d, float t, float az, float el) {
    float2 q = dome(d, 0.25) * 0.6;
    float n = fbm(float3(q + float2(t * 0.06, t * 0.025), t * 0.04));
    float n2 = noise3(float3(q * 3.0 - t * 0.1, t * 0.2));
    float3 col = lerp(float3(0.30, 0.32, 0.38), float3(0.03, 0.035, 0.05), smoothstep(0.30, 0.70, n + n2 * 0.2));
    col *= 0.7 + 0.3 * saturate(1 - el);
    float slot = floor(t * 1.7), ph = frac(t * 1.7);
    float hit = step(0.74, hash12(float2(slot, 4.1)));
    float flash = hit * (exp(-ph * 9.0) + 0.6 * exp(-abs(ph - 0.22) * 25.0));
    float faz = (hash12(float2(slot, 9.7)) - 0.5) * 6.2831853;
    float da = fmod(abs(az - faz) + 3.14159, 6.2831853) - 3.14159;
    col += flash * (0.25 + exp(-da * da * 1.5) * 1.4) * float3(0.75, 0.80, 1.0) * (0.4 + (1 - n));
    float bx = da * 18.0 + (noise3(float3(el * 14.0, slot, 1)) - 0.5) * 3.0;
    col += hit * exp(-ph * 14.0) * exp(-bx * bx * 8.0) * step(el, 0.5) * float3(0.9, 0.95, 1.0) * 2.0;
    return col;
}
float3 sky_golden(float3 d, float t, float az, float el) {
    float3 sd = normalize(float3(0.6, 0.07, 0.8));
    float3 col = lerp(float3(1.0, 0.62, 0.30), float3(0.30, 0.45, 0.78), pow(saturate(el * 1.7), 0.8));
    float sun = saturate(dot(d, sd));
    col += pow(sun, 6.0) * float3(1.0, 0.55, 0.20) * 0.6 + smoothstep(0.9993, 0.9996, sun) * float3(1.0, 0.92, 0.7) * 2.0;
    float2 q = dome(d, 0.18) * 0.45 + float2(t * 0.02, t * 0.008);
    float c = smoothstep(0.48, 0.78, fbm3u(float3(q, 0.3)) + noise3(float3(q * 4.0, t * 0.03)) * 0.12);
    float3 cl = lerp(float3(0.95, 0.55, 0.40), float3(1.0, 0.85, 0.60), pow(sun, 3.0));
    return lerp(col, cl, c * 0.85 * saturate(el * 6.0));
}
float3 sky_vapor(float3 d, float t, float az, float el) {
    float3 col = lerp(float3(1.0, 0.68, 0.84), float3(0.36, 0.82, 0.84), pow(saturate(el * 1.4), 0.9));
    float3 sd = normalize(float3(-0.2, 0.22, 1));
    float sun = saturate(dot(d, sd));
    col = lerp(col, float3(1.0, 0.95, 0.92), smoothstep(0.985, 0.99, sun) * 0.85) + pow(sun, 20.0) * float3(1.0, 0.75, 0.85) * 0.35;
    col += 0.05 * sin(el * 90.0 - t * 0.8) * saturate(1 - el * 3.0);
    float2 q = dome(d, 0.3) * 0.5 + t * 0.01;
    col = lerp(col, float3(0.98, 0.88, 0.96), smoothstep(0.55, 0.8, noise3(float3(q * 1.5, t * 0.02))) * 0.35);
    return col;
}
float3 sky_hell(float3 d, float t, float az, float el) {
    float2 q = dome(d, 0.3) * 0.7;
    float w = noise3(float3(q * 2.0, t * 0.15));
    float n = fbm(float3(q + w * 0.7 + float2(0, t * 0.08), t * 0.12));
    float h = saturate(n * 1.5 - 0.25) * (1.15 - saturate(el) * 0.5);
    float3 col = h < 0.5 ? lerp(float3(0.08, 0.0, 0.0), float3(0.75, 0.08, 0.0), h * 2) : lerp(float3(0.75, 0.08, 0.0), float3(1.0, 0.6, 0.12), h * 2 - 1);
    col += float3(1.0, 0.25, 0.0) * exp(-max(el, 0) * 5.0) * 0.35;
    float2 e = float2(az * 30.0, el * 30.0 - t * 1.2);
    float2 ec = floor(e);
    float eh = hash12(ec);
    float2 ep = float2(hash12(ec + 3.3), hash12(ec + 7.7)) + float2(sin(t * 1.3 + eh * 20.0) * 0.2, 0);
    col += step(0.8, eh) * pow(saturate(1 - length(frac(e) - ep) * 4.0), 6.0) * float3(1.0, 0.55, 0.12) * (0.8 + 0.5 * sin(t * 6.0 + eh * 50.0));
    return col;
}
float3 sky_water(float3 d, float t, float az, float el) {
    float3 col = lerp(float3(0.0, 0.10, 0.20), float3(0.05, 0.45, 0.65), pow(saturate(el * 1.2 + 0.25), 1.3));
    float2 q = dome(d, 0.35) * 1.6;
    float c1 = 1 - abs(noise3(float3(q, t * 0.45)) * 2 - 1), c2 = 1 - abs(noise3(float3(q * 1.7 + 4.0, t * 0.55)) * 2 - 1);
    float caus = pow(c1, 8.0) + pow(c2, 8.0) * 0.7;
    col += caus * float3(0.55, 0.95, 1.0) * saturate(el * 2.0) * 0.9;
    float rays = pow(noise3(float3(az * 9.0, t * 0.25, 0)), 3.0) * saturate(1 - abs(el - 0.35) * 1.5);
    col += rays * float3(0.3, 0.7, 0.8) * 0.5;
    float2 b = float2(az * 25.0, el * 25.0 - t * 1.5);
    float2 bc = floor(b);
    float bh = hash12(bc + 1.9);
    float bd = length(frac(b) - float2(0.5 + 0.25 * sin(t * 2.0 + bh * 30.0), 0.5));
    col += step(0.9, bh) * smoothstep(0.16, 0.12, bd) * smoothstep(0.06, 0.12, bd) * 0.6;
    return col;
}
float3 sky_rainbow(float3 d, float t, float az, float el) {
    float hue = frac(az / 6.2831853 * 2.0 + el * 0.8 + t * 0.025);
    float3 col = hsv2rgb(hue, 0.62, 0.95);
    float bands = 0.88 + 0.12 * sin((az * 2.0 + el * 5.0 + t * 0.157) * 6.0);
    return lerp(float3(1, 1, 1), col, saturate(0.55 + el * 0.8)) * bands;
}
float3 sky_blackhole(float3 d, float t, float az, float el) {
    float3 bz = normalize(float3(0.15, 0.32, 1));
    float3 bx = normalize(cross(float3(0, 1, 0), bz)), by = cross(bz, bx);
    float2 p = float2(dot(d, bx), dot(d, by)) / max(dot(d, bz), 0.05);
    const float R = 0.10;
    float r = max(length(p), 1e-4);
    float bend = R * R * 1.6 / r;
    float3 dd = normalize(d - (bx * p.x + by * p.y) / r * bend);
    float2 dp = float2(p.x, p.y / 0.22);
    float dr = length(dp), ang = atan2(dp.y, dp.x);
    float2 hp = float2(p.x, (p.y - R * 0.05) / 0.85);
    float hr = length(hp);
    // the three noise3 lookups share one loop body (2026-11-21: three inlined copies put this sky over 512 slots)
    float3 na = dd * 4.0, nb = float3(dr * 60.0, ang * 3.0 - t * 1.6 + 30.0 / (dr * 40.0 + 1.0), t * 0.2), nc = float3(hr * 70.0, atan2(hp.y, hp.x) * 3.0 + t * 1.4, 4.0);
    float3 nz = 0;
    [loop] for (int k = 0; k < 3; k++) nz += noise3(k == 0 ? na : (k == 1 ? nb : nc)) * float3(k == 0, k == 1, k == 2);
    float3 col = starfield(dd, t, 1.4) + float3(0.02, 0.02, 0.05) + lerp(float3(0.10, 0.18, 0.55), float3(0.45, 0.20, 0.60), nz.x) * pow(saturate(fbm3(dd * 2.5) * 1.3 - 0.3), 2.0) * 0.8;
    float disk = smoothstep(R * 1.6, R * 2.0, dr) * smoothstep(R * 5.0, R * 2.6, dr);
    float swirl = 0.55 + 0.45 * nz.y;
    float3 dcol = lerp(float3(1.0, 0.45, 0.10), float3(1.0, 0.92, 0.75), saturate(1.8 - dr / R * 0.45)) * swirl * (0.4 + (0.55 + 0.45 * cos(ang)) * 1.4);
    float front = step(0, -p.y);
    float halo = smoothstep(R * 2.6, R * 1.7, hr) * smoothstep(R * 1.25, R * 1.45, hr) * step(0, p.y);
    float hswirl = 0.6 + 0.4 * nz.z;
    if (r < R) col = 0;
    col += exp(-pow((r - R * 1.08) / (R * 0.05), 2)) * float3(1.0, 0.8, 0.55) * 1.2;
    col += float3(1.0, 0.6, 0.25) * halo * hswirl * 1.2 * step(R, r);
    col = lerp(col, dcol, disk * (front + (1 - front) * step(R * 1.05, r)));
    return col;
}
float3 sky_candy(float3 d, float t, float az, float el) {
    float3 col = lerp(float3(1.0, 0.72, 0.85), float3(0.55, 0.72, 1.0), pow(saturate(el * 1.5), 0.8));
    float2 q = dome(d, 0.22) * 0.5 + float2(t * 0.015, t * 0.005);
    float n = fbm3(float3(q, 1.7)) + noise3(float3(q * 4.0, t * 0.02)) * 0.15;
    float c = smoothstep(0.42, 0.72, n);
    float lit = saturate((n - 0.45) * 3.0);
    float3 cl = lerp(lerp(float3(0.98, 0.62, 0.82), float3(0.62, 0.78, 1.0), noise3(float3(q * 0.7, 9.0))), float3(1.0, 0.98, 1.0), lit * 0.8);
    return lerp(col, cl, c * saturate(el * 5.0 + 0.2));
}
float3 skies(float3 d, float style, float t) {
    float az = atan2(d.x, d.z), el = d.y;
    [branch] if (style < 5.5) return sky_aurora(d, t, az, el);
    [branch] if (style < 6.5) return sky_synthwave(d, t, az, el);
    [branch] if (style < 7.5) return sky_storm(d, t, az, el);
    [branch] if (style < 8.5) return sky_golden(d, t, az, el);
    [branch] if (style < 9.5) return sky_vapor(d, t, az, el);
    [branch] if (style < 10.5) return sky_hell(d, t, az, el);
    [branch] if (style < 11.5) return sky_water(d, t, az, el);
    [branch] if (style < 12.5) return sky_rainbow(d, t, az, el);
    [branch] if (style < 13.5) return sky_blackhole(d, t, az, el);
    return sky_candy(d, t, az, el);
}
// time of day + sky boost for the extra skies; sky boost 5 (the default) leaves them as designed
float3 skylook(float3 c, float3 d, float style, float t, float tod, float3 st10, float3 st06) {
    float pop = sk.y, el = d.y;
    bool bright = (style > 7.5 && style < 9.5) || (style > 11.5 && style < 12.5) || style > 13.5;  // golden, vapor, rainbow, candy
    float lum = dot(c, L);
    c = max(lerp(lum.xxx, c, 1 + (pop - 0.5) * 1.1), 0) * (1 + (pop - 0.5) * 0.25);
    if (tod > 0.5 && tod < 1.5) c = c * float3(1.06, 0.98, 0.92) * 1.04 + float3(1.0, 0.6, 0.45) * exp(-abs(el) * 7.0) * 0.08;
    else if (tod > 1.5 && tod < 2.5) c = c * float3(0.98, 1.0, 1.04) * 1.10;
    else if (tod > 2.5 && tod < 3.5) c = c * float3(1.10, 0.92, 0.82) + float3(1.0, 0.42, 0.12) * exp(-abs(el) * 5.0) * 0.18;
    else if (tod > 3.5 && tod < 4.5) {
        c = c * (bright ? float3(0.22, 0.26, 0.42) : float3(0.75, 0.80, 0.95));
        if (bright) c += st10 * saturate(el * 4.0) * 0.8;
    } else if (tod > 4.5) {  // evening lights (5) or dawn (6): same shape, dawn pinker with fewer stars
        bool dawn = tod > 5.5;
        c = c * (bright ? (dawn ? float3(0.42, 0.38, 0.56) : float3(0.55, 0.42, 0.55)) : (dawn ? float3(0.84, 0.82, 0.94) : float3(0.88, 0.85, 0.92)))
            + (dawn ? float3(1.0, 0.50, 0.45) : float3(0.85, 0.32, 0.14)) * exp(-abs(el) * 6.0) * 0.15;
        if (bright) c += st06 * saturate(el * 3.0 - (dawn ? 0.9 : 0.3)) * (dawn ? 0.3 : 0.6);
    }
    return c;
}
// One small shader per extra sky (2026-11-21: all ten in one ps_skies came to ~4,900 then ~3,300 instruction slots;
// D3D9 only promises 512 for ps_3_0, so each sky is its own shader, chosen by gfx_galaxy in DrawGalaxy)
float3 skydir(float2 uv) {
    float2 ndc = float2(uv.x * 2 - 1, 1 - uv.y * 2);
    return normalize(vr.xyz * (ndc.x / pj.x) + vu.xyz * (ndc.y / pj.y) - vb.xyz);
}
float4 skyout(float3 c, float3 d, float style) {
    float3 st10 = 0, st06 = 0;  // the night/evening stars, made once
    bool bright = (style > 7.5 && style < 9.5) || (style > 11.5 && style < 12.5) || style > 13.5;
    [branch] if (bright && (sk.x > 3.5 || (sk.w > 0.001 && sk.z > 3.5))) starfield2(d, p1.w, st10, st06);
    float3 a = 0, b = 0;  // the look for this time of day and, while it fades, the next one: one loop body (2026-11-21, smaller shaders)
    [loop] for (int i = 0; i < 2; i++) {
        if (i == 1 && sk.w <= 0.001) break;
        float3 l = skylook(c, d, style, p1.w, i == 0 ? sk.x : sk.z, st10, st06);
        if (i == 0) a = l; else b = l;
    }
    [branch] if (sk.w > 0.001) a = lerp(a, b, sk.w);
    return float4(saturate(a), 1);
}
#define DADMOD_SKY(n, fn) float4 ps_sky##n(float2 uv : TEXCOORD0) : COLOR { float3 d = skydir(uv); return skyout(fn(d, p1.w, atan2(d.x, d.z), d.y), d, n); }
DADMOD_SKY(5, sky_aurora)
DADMOD_SKY(6, sky_synthwave)
DADMOD_SKY(7, sky_storm)
DADMOD_SKY(8, sky_golden)
DADMOD_SKY(9, sky_vapor)
DADMOD_SKY(10, sky_hell)
DADMOD_SKY(11, sky_water)
DADMOD_SKY(12, sky_rainbow)
DADMOD_SKY(13, sky_blackhole)
DADMOD_SKY(14, sky_candy)
// the game's own sky, graded right after it is drawn: richer colors and a look that matches the time of day
float3 skygrade(float3 c, float3 d, float tod, float3 gx) {
    float el = d.y, pop = sk.y;
    float lum = dot(c, L);
    c = lerp(lum.xxx, c, 1 + pop * 0.9);
    c = saturate((c - 0.45) * (1 + pop * 0.35) + 0.45);
    float3 sunD = normalize(float3(0.6, 0.06, 0.8));
    float sun = saturate(dot(d, sunD));
    float mixv = 0.35 + pop * 0.45;
    if (tod > 0.5 && tod < 1.5) {        // morning: soft peach horizon, pale blue above
        float3 g = lerp(float3(1.0, 0.62, 0.48), float3(0.42, 0.62, 0.92), saturate(el * 1.8));
        c = lerp(c, g * (0.55 + lum * 0.9), mixv * 0.7) + pow(sun, 16) * float3(1.0, 0.75, 0.5) * 0.5;
    } else if (tod > 1.5 && tod < 2.5) { // day: deep blue at the top, bright near the horizon
        float3 g = lerp(float3(0.78, 0.88, 1.0), float3(0.18, 0.42, 0.95), saturate(el * 1.5));
        c = lerp(c, g * (0.6 + lum * 0.8), mixv * 0.55) * (1 + pop * 0.08);
    } else if (tod > 2.5 && tod < 3.5) { // sunset: orange horizon into purple
        float3 g = lerp(float3(1.0, 0.42, 0.12), float3(0.30, 0.12, 0.42), saturate(el * 1.7));
        c = lerp(c, g * (0.45 + lum * 1.2), mixv) + pow(sun, 10) * float3(1.0, 0.55, 0.2) * 0.35 + pow(sun, 300) * float3(1.0, 0.85, 0.6) * 0.5;
    } else if (tod > 3.5 && tod < 4.5) { // night: deep blue-black with stars and a faint milky way
        c = c * float3(0.30, 0.38, 0.62) * (0.6 - pop * 0.2);
        c += gx * (0.55 + pop * 0.5) * saturate(el * 5 + 0.4);
    } else if (tod > 4.5) {              // evening, lights on (5): dusk glow low down, first stars up high
        bool dawn = tod > 5.5;           // dawn (6): deep blue overhead, pink-orange glow toward the sun, stars fading
        float3 g = lerp(dawn ? float3(0.95, 0.50, 0.45) : float3(0.85, 0.32, 0.14), dawn ? float3(0.05, 0.08, 0.24) : float3(0.07, 0.06, 0.20), saturate(el * 2.0));
        c = lerp(c, g * (0.4 + lum), mixv) + pow(sun, 8) * (dawn ? float3(1.0, 0.55, 0.45) : float3(0.9, 0.4, 0.15)) * 0.35;
        c += gx * (dawn ? 0.25 : 0.35) * saturate(el * 3 - (dawn ? 1.0 : 0.4));
    }
    return c;
}
float4 ps_sky(float2 uv : TEXCOORD0) : COLOR {
    float3 c = tex2D(s0, uv).rgb;
    float2 ndc = float2(uv.x * 2 - 1, 1 - uv.y * 2);
    float3 d = normalize(vr.xyz * (ndc.x / pj.x) + vu.xyz * (ndc.y / pj.y) - vb.xyz);
    float3 gx = 0;  // the milky way for night/evening, made once (2026-11-21: four inlined copies put ps_sky over NVIDIA's slot limit)
    [branch] if (sk.x > 3.5 || (sk.w > 0.001 && sk.z > 3.5)) gx = galaxy(d, 1.0, p1.w);
    // one copy of skygrade in a loop (2026-11-21: two inlined copies + dawn went over 512 slots)
    float3 a = 0;
    [loop] for (int i = 0; i < 2; i++) {
        if (i == 1 && sk.w <= 0.001) break;
        float3 r = skygrade(c, d, i == 0 ? sk.x : sk.z, gx);
        a = i == 0 ? r : lerp(a, r, sk.w);
    }
    return float4(saturate(a), 1);
}
// ---- night tint (scene pass, before lamps/weather): darkens buildings the game's TOD manager leaves at day brightness.
// Drawn at the far plane with ZFUNC GREATER so only geometry (not the sky) is tinted; very bright pixels stay lit.
float3 nighttint(float tod) { return tod > 3.5 && tod < 4.5 ? float3(0.22, 0.26, 0.40) : (tod > 5.5 ? float3(0.40, 0.40, 0.52) : (tod > 4.5 ? float3(0.62, 0.55, 0.60) : float3(1, 1, 1))); }  // night, dawn, evening lights
float4 ps_nighttint(float2 uv : TEXCOORD0) : COLOR {
    float3 c = tex2D(s0, uv).rgb;
    float3 t = lerp(nighttint(sk.x), nighttint(sk.z), sk.w);
    float br = max(c.r, max(c.g, c.b)), sat = br - min(c.r, min(c.g, c.b));  // keep the level's lights lit: bright or strongly colored pixels
    t = lerp(t, 1, saturate(smoothstep(0.45, 0.85, br) + smoothstep(0.25, 0.6, sat) * smoothstep(0.3, 0.6, br)));
    return float4(c * t, 1);
}
// ---- weather (scene pass, before the HUD): s0 color, s1 depth when p9.z > 0
// lightning: the same slots and hash as the Storm sky, so with threshold 0.74 the two flash together
float lightning(float t, float thr) {
    float slot = floor(t * 1.7), ph = frac(t * 1.7);
    float hit = step(thr, hash12(float2(slot, 4.1)));
    return hit * (exp(-ph * 9.0) + 0.6 * exp(-abs(ph - 0.22) * 25.0));
}
// particles live on spheres around the camera, so turning the camera moves them the right way;
// a layer is hidden where the scene is closer than the layer
float rainlayer(float az, float el, float t, float k, float z, float amt) {
    float D = k < 0.5 ? 160.0 : (k < 1.5 ? 450.0 : 1200.0);
    if (z < D) return 0;
    float n = k < 0.5 ? 70.0 : (k < 1.5 ? 140.0 : 260.0);
    float v = el * n * 0.25 + t * (k < 0.5 ? 9.0 : (k < 1.5 ? 7.0 : 5.0));
    float u = az * n / 6.2831853 * 6.2831853 + v * 0.10;
    float2 c = floor(float2(u, v)), f = frac(float2(u, v));
    float h = hash12(c + k * 31.0);
    if (h > amt * 0.55) return 0;
    float x = hash12(c + 7.3 + k), y0 = hash12(c + 3.1 + k) * 0.5;
    float w = k < 0.5 ? 0.035 : (k < 1.5 ? 0.03 : 0.025);
    float s = smoothstep(w, 0, abs(f.x - (0.1 + x * 0.8))) * smoothstep(y0, y0 + 0.08, f.y) * smoothstep(y0 + 0.5, y0 + 0.3, f.y);
    return s * (k < 0.5 ? 0.9 : (k < 1.5 ? 0.6 : 0.4));
}
float snowlayer(float az, float el, float t, float k, float z, float amt) {
    float D = k < 0.5 ? 120.0 : (k < 1.5 ? 350.0 : 900.0);
    if (z < D) return 0;
    float n = k < 0.5 ? 45.0 : (k < 1.5 ? 90.0 : 160.0);
    float v = el * n + t * (k < 0.5 ? 1.3 : (k < 1.5 ? 1.0 : 0.8));
    float u = az * n + sin(t * 0.7 + floor(v) * 1.3 + k) * 0.35;
    float2 c = floor(float2(u, v)), f = frac(float2(u, v));
    float h = hash12(c + k * 17.0);
    if (h > amt * 0.45) return 0;
    float2 pos = float2(hash12(c + 2.7), hash12(c + 5.9)) * 0.7 + 0.15;
    float r = (k < 0.5 ? 0.11 : (k < 1.5 ? 0.09 : 0.07)) * (0.6 + 0.4 * hash12(c + 9.1));
    return smoothstep(r, r * 0.35, length(f - pos)) * (k < 0.5 ? 0.95 : (k < 1.5 ? 0.75 : 0.5));
}
float4 ps_weather(float2 uv : TEXCOORD0) : COLOR {
    float3 c = tex2D(s0, uv).rgb;
    float2 ndc = float2(uv.x * 2 - 1, 1 - uv.y * 2);
    float3 d = normalize(vr.xyz * (ndc.x / pj.x) + vu.xyz * (ndc.y / pj.y) - vb.xyz);
    float z = 100000.0;
    bool sky = false;
    if (p9.z > 0) { float d0 = tex2D(s1, uv).r; z = dist(d0); sky = d0 >= 0.99999; }
    float rain = wx.x, snow = wx.y, fog = wx.z, storm = wx.w, lite = wx2.x, t = p1.w;
    float lum = dot(c, L);
    float wetness = saturate(rain + storm * 0.6);
    float over = saturate(rain * 0.8 + storm * 0.5 + snow * 0.5 + fog * 0.35);
    if (sky) c = lerp(c, wxc.rgb * (0.55 + 0.45 * lum), over * 0.75);
    else {
        c = lerp(c, lum.xxx * float3(0.9, 0.94, 1.0), wetness * 0.35) * (1 - 0.22 * wetness);
        c += pow(saturate(lum), 2.5) * wetness * wx2.z * saturate(-d.y * 4) * 0.35;  // wet shine on the ground
        // the distance fog itself is the game's own per-draw fog now (ApplyWeatherFog), which also fogs
        // see-through draws (fences, signs, glass, leaves) that a depth-based pass can't
    }
    float fl = lightning(t, wx2.y) * saturate(storm);
    c += fl * (sky ? 0.6 : 0.3) * float3(0.8, 0.85, 1.0) * (0.5 + lite * 0.5);
    float az = atan2(d.x, d.z), el = asin(clamp(d.y, -1, 1));
    [branch] if (wetness > 0.01) {
        float r = 0;
        [loop] for (int k = 0; k < 3; k++) r += rainlayer(az, el, t, k, z, wetness);
        c = lerp(c, float3(0.75, 0.8, 0.88) * (0.4 + 0.6 * lite) + fl * 0.5, saturate(r) * 0.45);
    }
    [branch] if (snow > 0.01) {
        float sn = 0;
        [loop] for (int k = 0; k < 3; k++) sn += snowlayer(az, el, t, k, z, saturate(snow));
        c = lerp(c, float3(0.95, 0.97, 1.0) * (0.45 + 0.55 * lite), saturate(sn));
    }
    return float4(c, 1);
}
// ---- fireworks (drawn additively right after the sky, so the level covers them)
float4 ps_fireworks(float2 uv : TEXCOORD0) : COLOR {
    if (p9.z > 0 && tex2D(s1, uv).r < 0.99999) return float4(0, 0, 0, 1);
    float2 ndc = float2(uv.x * 2 - 1, 1 - uv.y * 2);
    float3 d = normalize(vr.xyz * (ndc.x / pj.x) + vu.xyz * (ndc.y / pj.y) - vb.xyz);
    float3 col = 0;
    [loop] for (int i = 0; i < 8; i++) {
        float4 f = fw[i];
        [branch] if (f.z > -1.2 && f.z < 3.2) {
            if (f.z < 0) {  // the rocket going up
                float e = f.y - 0.35 * (-f.z / 1.2);
                float3 rd = float3(sin(f.x) * cos(e), sin(e), cos(f.x) * cos(e));
                float q = 1 - dot(d, rd);
                col += exp(-q * 4e5) * float3(1.0, 0.8, 0.5) * 2.0 + exp(-q * 3e4) * float3(1.0, 0.6, 0.3) * 0.15;
            } else {
                float3 cd = float3(sin(f.x) * cos(f.y), sin(f.y), cos(f.x) * cos(f.y));
                float dz = dot(d, cd);
                if (dz < 0.8) continue;
                float3 bx = normalize(cross(float3(0, 1, 0), cd)), by = cross(cd, bx);
                float2 p = float2(dot(d, bx), dot(d, by)) / dz;
                if (dot(p, p) > 0.16) continue;
                float age = f.z, fade = saturate(1 - age / 2.8);
                fade *= fade;
                float spread = 0.17 * (1 - exp(-age * 2.6)), fall = 0.02 * age * age;
                float acc = 0;
                [loop] for (int j = 0; j < 36; j++) {
                    float h = hash12(float2(j, f.w * 91.7));
                    float ang = j * 0.17453 + h * 0.2;
                    float sp = spread * (0.75 + 0.25 * h);
                    float2 dir2 = float2(cos(ang), sin(ang));
                    float2 a = dir2 * sp * 0.82 - float2(0, fall * 0.8), b = dir2 * sp - float2(0, fall);
                    float2 ab = b - a, ap = p - a;
                    float tt = saturate(dot(ap, ab) / max(dot(ab, ab), 1e-8));
                    float2 dd = ap - ab * tt;
                    acc += exp(-dot(dd, dd) * 2.5e5) * (0.35 + 0.65 * tt);
                }
                float3 base = hsv2rgb(f.w, 0.7, 1);
                float tw = 0.75 + 0.25 * sin(age * 40 + dot(p, float2(300, 170)));
                col += base * acc * fade * tw * 1.6 + float3(1, 0.95, 0.85) * exp(-age * 7) * exp(-dot(p, p) * 400) * 1.5 +
                       base * exp(-dot(p, p) * 25) * fade * 0.08;
            }
        }
    }
    return float4(col, 1);
}
// ---- street lights at night (scene pass): s0 color, s1 depth. lp: per lamp position + radius, then color
float4 lampc : register(c28);  // amount, count
float4 camp : register(c29);   // camera position (world)
float4 lp[48] : register(c30);
float4 ps_lamps(float2 uv : TEXCOORD0) : COLOR {
    float3 c = tex2D(s0, uv).rgb;
    float d0 = tex2D(s1, uv).r;
    float2 ndc = float2(uv.x * 2 - 1, 1 - uv.y * 2);
    float3 dv = vr.xyz * (ndc.x / pj.x) + vu.xyz * (ndc.y / pj.y) - vb.xyz;  // one unit of view depth
    bool sky = d0 >= 0.99999;
    float z = sky ? 50000.0 : dist(d0);
    float3 P = camp.xyz + dv * z;
    float3 dn = normalize(dv);
    float far = length(dv) * z;
    float3 light = 0, halo = 0;
    [loop] for (int i = 0; i < 24; i++) {
        if (i >= lampc.y) break;
        float4 a = lp[i * 2], col = lp[i * 2 + 1];
        float3 dl = P - a.xyz;
        float x = saturate(1 - dot(dl, dl) / (a.w * a.w));
        light += col.rgb * x * x * (sky ? 0 : 1);
        float tl = dot(a.xyz - camp.xyz, dn);
        if (tl > 0 && tl < far + 40) {
            float3 q = camp.xyz + dn * tl - a.xyz;
            float r2 = dot(q, q);
            float s = 1 + tl * 0.0015;  // keep far bulbs visible
            halo += col.rgb * (exp(-r2 / (14.0 * 14.0 * s * s)) * 0.9 + exp(-r2 / (80.0 * 80.0 * s)) * 0.12);
        }
    }
    c += (c * light * 2.4 + light * 0.05 + halo * 0.7) * lampc.x;
    return float4(c, 1);
}
// ---- ground mist (scene pass, after the night tint): s0 color, s1 depth. camp = camera position (c29)
// density(h) = D * exp(-(h - ground) / Hs), integrated along the view ray; drifting 2-octave patches
float4 gm : register(c80);   // D, Hs, ground height, cap
float4 gmc : register(c81);  // mist color
float vnoise(float2 p) {
    float2 i = floor(p), f = frac(p);
    f = f * f * (3 - 2 * f);
    return lerp(lerp(hash12(i), hash12(i + float2(1, 0)), f.x), lerp(hash12(i + float2(0, 1)), hash12(i + float2(1, 1)), f.x), f.y);
}
float4 ps_groundmist(float2 uv : TEXCOORD0) : COLOR {
    float3 c = tex2D(s0, uv).rgb;
    float d0 = tex2D(s1, uv).r;
    float2 ndc = float2(uv.x * 2 - 1, 1 - uv.y * 2);
    float3 dv = vr.xyz * (ndc.x / pj.x) + vu.xyz * (ndc.y / pj.y) - vb.xyz;
    float3 dn = normalize(dv);
    float len = d0 >= 0.99999 ? 11800.0 : length(dv) * dist(d0);  // sky: as if 300 m away, so the horizon blends
    float3 P = camp.xyz + dn * len;
    float hs = gm.y, hc = max(camp.y - gm.z, -hs), hp = max(P.y - gm.z, -hs), dh = hp - hc;
    float ec = exp(-hc / hs), ep = exp(-hp / hs);
    float k = abs(dh) > 0.01 ? hs * (ec - ep) / dh : ec;
    float2 q = lerp(camp.xz, P.xz, 0.5) / 400.0 + p1.w * float2(0.011, 0.007);
    float n = vnoise(q) * 0.67 + vnoise(q * 2.03 + 5.2) * 0.33;
    float od = gm.x * len * k * (0.6 + 0.8 * n);
    float a = min(1 - exp(-od), gm.w);
    return float4(lerp(c, gmc.rgb, a), 1);
}
)HLSL";

static IDirect3DVertexShader9* g_vs = nullptr;
static IDirect3DPixelShader9 *g_psFxaa = nullptr, *g_psBright = nullptr, *g_psDown = nullptr, *g_psBlur = nullptr, *g_psScene = nullptr,
                             *g_psLook = nullptr, *g_psScreen = nullptr, *g_psGalaxy = nullptr,
                             *g_psAO = nullptr, *g_psAOBlur = nullptr, *g_psSky = nullptr,
                             *g_psSkyN[10] = {},  // skies 5-14, one small shader each (optional: a missing one shows the milky way)
                             *g_psWeather = nullptr, *g_psFireworks = nullptr, *g_psLamps = nullptr,  // optional too
                             *g_psMirror = nullptr,  // optional: without it mirror mode does nothing
                             *g_psGroundMist = nullptr,  // optional: the Fog row (ground mist)
                             *g_psNightTint = nullptr;  // optional: without it night/evening buildings keep the game's lighting
static IDirect3DVertexDeclaration9* g_decl = nullptr;
static IDirect3DTexture9 *g_texA = nullptr, *g_texB = nullptr, *g_texC = nullptr, *g_texD = nullptr, *g_texE = nullptr, *g_texF = nullptr, *g_texPrev = nullptr,
                         *g_texG = nullptr, *g_texH = nullptr;  // G/H: ambient occlusion
static IDirect3DStateBlock9* g_sb = nullptr;
static IDirect3DTexture9* g_intz = nullptr;
static IDirect3DSurface9 *g_intzSurf = nullptr, *g_autoDS = nullptr;
static bool g_intzFail = false, g_intzBound = false, g_prevValid = false, g_intzUsed = false;  // used = the 3D scene drew into it this frame
static UINT g_w = 0, g_h = 0;
static bool g_shaderFail = false;
static HMODULE g_dx = nullptr;

static void FreeTargets() {
    IUnknown** list[] = {(IUnknown**)&g_texA, (IUnknown**)&g_texB, (IUnknown**)&g_texC, (IUnknown**)&g_texD, (IUnknown**)&g_texE,
                         (IUnknown**)&g_texF, (IUnknown**)&g_texPrev, (IUnknown**)&g_texG, (IUnknown**)&g_texH, (IUnknown**)&g_sb,
                         (IUnknown**)&g_intzSurf, (IUnknown**)&g_intz,
                         (IUnknown**)&g_autoDS};
    for (auto p : list) if (*p) { (*p)->Release(); *p = nullptr; }
    g_w = g_h = 0;
    g_prevValid = false;
    g_intzBound = false;
}

// Compiled shader cache (Noah 2026-10-20: boot got ~10 s slower once the sky/weather/fog shaders grew;
// D3DXCompileShader ran for every shader on every start). Bytecode is kept in
// dadmod\shadercache\<entry>_<hash of the shader source>.bin and reused until the source changes.
static unsigned long long ShaderSourceHash() {
    static unsigned long long h = 0;
    if (h) return h;
    h = 1469598103934665603ULL;
    for (size_t i = 0; i < sizeof kShaders - 1; ++i) { h ^= (unsigned char)kShaders[i]; h *= 1099511628211ULL; }
    return h;
}
static bool CachedShaderCode(CompileShader_t compile, const char* fn, const char* prof, std::string& out, std::string& err) {
    char name[160];
    wsprintfA(name, "shadercache\\%s_%s_%08X%08X.bin", fn, prof, (DWORD)(ShaderSourceHash() >> 32), (DWORD)ShaderSourceHash());
    std::string path = ExeDirFile(name);
    if (ReadWholeFile(path, out) && out.size() >= 4 && out.size() % 4 == 0) return true;
    out.clear();
    if (!compile) { err = "d3dx9_43.dll not found"; return false; }
    XBuf *code = nullptr, *e = nullptr;
    HRESULT hr = compile(kShaders, sizeof kShaders - 1, nullptr, nullptr, fn, prof, 0, &code, &e, nullptr);
    if (e) { err = (const char*)e->GetBufferPointer(); e->Release(); }
    if (FAILED(hr) || !code) { if (code) code->Release(); if (err.empty()) err = "?"; return false; }
    out.assign((const char*)code->GetBufferPointer(), code->GetBufferSize());
    code->Release();
    CreateDirectoryA(ExeDirFile("shadercache").c_str(), nullptr);
    WriteWholeFile(path, out);
    return true;
}

// ---- what this graphics card can do (2026-11-21) ---------------------------------------------------
// A player's NVIDIA card refused ps_sky (~4000 instruction slots); the old MakeShaders then stopped halfway
// without a log line, reported "ready" on the next call (it only checked g_vs) and the galaxy sky drew with
// no vertex declaration: an access violation inside d3d9/the driver on every start. Now every card's limits
// are read once and logged, shaders over the card's slot limit are skipped, and the shader set is
// all-or-nothing. dadmod\gfx_test.ini (test builds only, never shipped) can fake a weak card:
//   failshader = ps_sky      that shader's create is treated as failed
//   weakcard = 1             pretend: 512 pixel/vertex shader slots, no readable depth (INTZ)
static bool g_cardChecked = false, g_cardSM3 = true, g_cardIntz = true, g_cardPixFog = false;
static UINT g_cardPsSlots = 32768, g_cardVsSlots = 32768;
static std::string g_testFailShader;
static bool g_testWeak = false;
static void ReadGfxTest() {
    std::string s;
    if (!ReadWholeFile(ExeDirFile("gfx_test.ini"), s)) return;
    size_t p = 0;
    while (p < s.size()) {
        size_t e = s.find('\n', p);
        if (e == std::string::npos) e = s.size();
        std::string line = s.substr(p, e - p);
        p = e + 1;
        size_t sc = line.find(';');
        if (sc != std::string::npos) line.resize(sc);
        size_t eq = line.find('=');
        if (eq == std::string::npos) continue;
        auto trim = [](std::string t) {
            size_t a = t.find_first_not_of(" \t\r"), b = t.find_last_not_of(" \t\r");
            return a == std::string::npos ? std::string() : t.substr(a, b - a + 1);
        };
        std::string k = trim(line.substr(0, eq)), v = trim(line.substr(eq + 1));
        if (k == "failshader") g_testFailShader = v;
        else if (k == "weakcard") g_testWeak = atoi(v.c_str()) != 0;
    }
}
static void CardCheck(IDirect3DDevice9* dev) {
    if (g_cardChecked) return;
    g_cardChecked = true;
    ReadGfxTest();
    D3DCAPS9 c = {};
    bool haveCaps = SUCCEEDED(dev->GetDeviceCaps(&c));
    D3DADAPTER_IDENTIFIER9 id = {};
    IDirect3D9* d3d = nullptr;
    D3DDEVICE_CREATION_PARAMETERS cp = {};
    D3DDISPLAYMODE mode = {};
    bool haveId = SUCCEEDED(dev->GetDirect3D(&d3d)) && d3d && SUCCEEDED(dev->GetCreationParameters(&cp)) &&
                  SUCCEEDED(d3d->GetAdapterIdentifier(cp.AdapterOrdinal, 0, &id));
    if (haveCaps) {
        g_cardSM3 = (c.PixelShaderVersion & 0xFFFF) >= 0x0300 && (c.VertexShaderVersion & 0xFFFF) >= 0x0300;
        if (c.MaxPixelShader30InstructionSlots) g_cardPsSlots = c.MaxPixelShader30InstructionSlots;
        if (c.MaxVertexShader30InstructionSlots) g_cardVsSlots = c.MaxVertexShader30InstructionSlots;
    }
    if (d3d) {
        const D3DFORMAT kIntz = (D3DFORMAT)MAKEFOURCC('I', 'N', 'T', 'Z');
        d3d->GetAdapterDisplayMode(cp.AdapterOrdinal, &mode);
        D3DFORMAT fmt = mode.Format ? mode.Format : D3DFMT_X8R8G8B8;
        g_cardIntz = SUCCEEDED(d3d->CheckDeviceFormat(cp.AdapterOrdinal, cp.DeviceType, fmt, D3DUSAGE_DEPTHSTENCIL, D3DRTYPE_TEXTURE, kIntz));
        bool rt = SUCCEEDED(d3d->CheckDeviceFormat(cp.AdapterOrdinal, cp.DeviceType, fmt, D3DUSAGE_RENDERTARGET, D3DRTYPE_TEXTURE, D3DFMT_A8R8G8B8));
        if (!rt) { g_cardSM3 = false; mmenu::Log("gfx: card can't render to A8R8G8B8 textures, effects off"); }
        d3d->Release();
    }
    if (g_testWeak) { g_cardPsSlots = g_cardVsSlots = 512; g_cardIntz = false; }
    unsigned drv = (unsigned)id.DriverVersion.HighPart, drl = (unsigned)id.DriverVersion.LowPart;
    mmenu::Log("gfx: card %s (vendor 0x%04lX device 0x%04lX, driver %u.%u.%u.%u): ps %lu.%lu, vs %lu.%lu, ps slots %u, vs slots %u, "
               "max texture %lux%lu, render targets %lu, readable depth %s%s%s",
               haveId ? id.Description : "?", id.VendorId, id.DeviceId, drv >> 16, drv & 0xFFFF, drl >> 16, drl & 0xFFFF,
               (c.PixelShaderVersion >> 8) & 0xFF, c.PixelShaderVersion & 0xFF, (c.VertexShaderVersion >> 8) & 0xFF, c.VertexShaderVersion & 0xFF,
               g_cardPsSlots, g_cardVsSlots, c.MaxTextureWidth, c.MaxTextureHeight, c.NumSimultaneousRTs, g_cardIntz ? "yes" : "no",
               g_testWeak ? " [TEST: weak card]" : "", g_testFailShader.empty() ? "" : " [TEST: failing a shader]");
    if (!g_cardSM3) mmenu::Log("gfx: card has no shader model 3.0, graphics effects off");
    // per-pixel (table) fog measured on eye distance: our time of day / weather fog uses it (2026-11-21)
    g_cardPixFog = haveCaps && (c.RasterCaps & D3DPRASTERCAPS_FOGTABLE) && (c.RasterCaps & D3DPRASTERCAPS_WFOG);
    mmenu::Log("gfx: per-pixel fog %s", g_cardPixFog ? "available" : "not available, the game's per-corner fog stays");
}
// instruction slots a compiled shader takes (opcode tokens, without declarations/constants/comments)
static UINT ShaderSlots(const std::string& code) {
    const DWORD* t = (const DWORD*)code.data();
    size_t n = code.size() / 4, i = 1, slots = 0;
    while (i < n) {
        DWORD tok = t[i], op = tok & 0xFFFF;
        if (op == 0xFFFF) break;                                    // end
        if (op == 0xFFFE) { i += 1 + ((tok >> 16) & 0x7FFF); continue; }  // comment block
        size_t len = (tok >> 24) & 0x0F;
        if (op != 31 && op != 81 && op != 82 && op != 83) ++slots;  // dcl, def, defi, defb take no slot
        i += 1 + len;
    }
    return (UINT)slots;
}
// one shader: compile/cache, check against the card, create. Every failure is logged with its reason.
static bool MakeOneShader(IDirect3DDevice9* dev, CompileShader_t compile, const char* fn, const char* prof, bool vs, void** out) {
    std::string code, err;
    if (!CachedShaderCode(compile, fn, prof, code, err)) { mmenu::Log("gfx: shader %s failed to compile: %s", fn, err.c_str()); return false; }
    UINT slots = ShaderSlots(code), limit = vs ? g_cardVsSlots : g_cardPsSlots;
    if (slots > limit) { mmenu::Log("gfx: shader %s skipped: %u instruction slots, this card allows %u", fn, slots, limit); return false; }
    HRESULT hr = g_testFailShader == fn ? D3DERR_INVALIDCALL
                 : vs ? dev->CreateVertexShader((const DWORD*)code.data(), (IDirect3DVertexShader9**)out)
                      : dev->CreatePixelShader((const DWORD*)code.data(), (IDirect3DPixelShader9**)out);
    if (FAILED(hr) || !*out) {
        if (*out) { ((IUnknown*)*out)->Release(); *out = nullptr; }
        mmenu::Log("gfx: shader %s rejected by the card (hr 0x%08lX, %u slots)%s", fn, hr, slots, g_testFailShader == fn ? " [TEST]" : "");
        return false;
    }
    return true;
}
// All-or-nothing: the core set (vertex shader, declaration, the post-process chain) either all exists or none
// of it does. Optional shaders (galaxy, extra skies, sky grading, weather, fireworks, lamps, mirror) can each be
// missing; every user checks its own pointer.
static bool g_shadersReady = false;
static bool AnySkyN() { for (auto p : g_psSkyN) if (p) return true; return false; }
static bool MakeShaders(IDirect3DDevice9* dev) {
    if (g_shadersReady) return true;
    if (g_shaderFail) return false;
    CardCheck(dev);
    if (!g_cardSM3) { g_shaderFail = true; return false; }
    if (!g_dx) g_dx = LoadLibraryA("d3dx9_43.dll");
    auto compile = g_dx ? (CompileShader_t)GetProcAddress(g_dx, "D3DXCompileShader") : nullptr;
    struct { const char* fn; const char* prof; bool vs; void** out; } core[] = {
        {"vs_main", "vs_3_0", true, (void**)&g_vs}, {"ps_fxaa", "ps_3_0", false, (void**)&g_psFxaa},
        {"ps_bright", "ps_3_0", false, (void**)&g_psBright}, {"ps_down", "ps_3_0", false, (void**)&g_psDown},
        {"ps_blur", "ps_3_0", false, (void**)&g_psBlur}, {"ps_scene", "ps_3_0", false, (void**)&g_psScene},
        {"ps_look", "ps_3_0", false, (void**)&g_psLook}, {"ps_screen", "ps_3_0", false, (void**)&g_psScreen},
        {"ps_ao", "ps_3_0", false, (void**)&g_psAO}, {"ps_aoblur", "ps_3_0", false, (void**)&g_psAOBlur}};
    bool ok = true;
    for (auto& s : core) if (!MakeOneShader(dev, compile, s.fn, s.prof, s.vs, s.out)) { ok = false; break; }
    if (ok) {
        D3DVERTEXELEMENT9 el[] = {{0, 0, D3DDECLTYPE_FLOAT4, 0, D3DDECLUSAGE_POSITION, 0},
                                  {0, 16, D3DDECLTYPE_FLOAT2, 0, D3DDECLUSAGE_TEXCOORD, 0}, D3DDECL_END()};
        HRESULT hr = dev->CreateVertexDeclaration(el, &g_decl);
        if (FAILED(hr) || !g_decl) { g_decl = nullptr; mmenu::Log("gfx: vertex declaration rejected by the card (hr 0x%08lX)", hr); ok = false; }
    }
    if (!ok) {
        for (auto& s : core) if (*s.out) { ((IUnknown*)*s.out)->Release(); *s.out = nullptr; }
        if (g_decl) { g_decl->Release(); g_decl = nullptr; }
        g_shaderFail = true;
        mmenu::Log("gfx: graphics effects off on this card (the game itself is unchanged)");
        return false;
    }
    struct { const char* fn; IDirect3DPixelShader9** out; const char* lose; } optional[] = {
        {"ps_galaxy", &g_psGalaxy, "galaxy skies 1-4"},
        {"ps_sky", &g_psSky, "time of day / sky boost on the game's sky"}, {"ps_weather", &g_psWeather, "weather"},
        {"ps_fireworks", &g_psFireworks, "fireworks"}, {"ps_lamps", &g_psLamps, "street lamps"}, {"ps_mirror", &g_psMirror, "mirror picture"},
        {"ps_nighttint", &g_psNightTint, "night tint"}, {"ps_groundmist", &g_psGroundMist, "ground mist"}};
    for (auto& o : optional)
        if (!MakeOneShader(dev, compile, o.fn, "ps_3_0", false, (void**)o.out)) mmenu::Log("gfx: %s unavailable on this card", o.lose);
    for (int i = 0; i < 10; ++i) {
        char fn[16];
        wsprintfA(fn, "ps_sky%d", i + 5);
        if (!MakeOneShader(dev, compile, fn, "ps_3_0", false, (void**)&g_psSkyN[i])) mmenu::Log("gfx: galaxy sky %d unavailable on this card (the milky way shows instead)", i + 5);
    }
    g_shadersReady = true;
    mmenu::Log("gfx: effects ready");
    return true;
}

static void Quad(IDirect3DDevice9* dev, UINT w, UINT h, float z = 0) {
    if (!g_shadersReady || !g_vs || !g_decl) return;  // never draw with a half-made shader set
    // clip-space quad with the D3D9 half-pixel offset
    float ox = -1.0f / w, oy = 1.0f / h;
    float v[4][6] = {{-1 + ox, 1 + oy, z, 1, 0, 0}, {1 + ox, 1 + oy, z, 1, 1, 0}, {-1 + ox, -1 + oy, z, 1, 0, 1}, {1 + ox, -1 + oy, z, 1, 1, 1}};
    g_origDPUP(dev, D3DPT_TRIANGLESTRIP, 2, v, sizeof v[0]);
}

static void Pass(IDirect3DDevice9* dev, IDirect3DPixelShader9* ps, IDirect3DSurface9* dst, UINT sw, UINT sh, UINT dw, UINT dh,
                 IDirect3DBaseTexture9* t0, IDirect3DBaseTexture9* t1 = nullptr, IDirect3DBaseTexture9* t2 = nullptr, IDirect3DBaseTexture9* t3 = nullptr) {
    if (!ps || !dst) return;  // a shader this card didn't get: skip the pass instead of drawing with none
    dev->SetRenderTarget(0, dst);
    D3DVIEWPORT9 vp = {0, 0, dw, dh, 0, 1};
    dev->SetViewport(&vp);
    dev->SetPixelShader(ps);
    dev->SetTexture(0, t0); dev->SetTexture(1, t1); dev->SetTexture(2, t2); dev->SetTexture(3, t3);
    float px[4] = {1.0f / sw, 1.0f / sh, (float)sw, (float)sh};
    dev->SetPixelShaderConstantF(0, px, 1);
    Quad(dev, dw, dh);
}

static float g_c[14][4];
static void BuildConstants() {
    // presets: tint rgb, grey, lift, extra contrast, extra saturation, brightness
    struct P { float r, g, b, grey, lift, con, sat, br; };
    static const P kP[] = {
        {1, 1, 1, 0, 0, 0, 0, 0},                    {1, 1, 1, 0, 0, 0.10f, 0.30f, 0},        {1.06f, 1.0f, 0.90f, 0, 0, 0.03f, 0.05f, 0},
        {0.92f, 1.0f, 1.08f, 0, 0, 0.03f, 0, 0},     {1.03f, 1.0f, 0.94f, 0, 0.04f, 0.08f, -0.25f, 0},
        {1, 1, 1, 1, 0, 0.08f, 0, 0},                {1.08f, 1.02f, 0.88f, 0.15f, 0.05f, -0.05f, -0.10f, 0},
        {0.70f, 0.82f, 1.10f, 0.25f, 0, 0.05f, -0.20f, -0.10f},   // night
        {1.15f, 0.95f, 0.78f, 0, 0.02f, 0.06f, 0.10f, 0.02f},      // sunset
        {0.96f, 0.98f, 1.02f, 0.30f, 0.03f, -0.10f, -0.20f, 0},    // overcast
        {1.04f, 0.98f, 1.04f, 0.10f, 0.06f, -0.12f, -0.15f, 0.01f} // VHS
    };
    const P& p = kP[V("gfx_preset")];
    float temp = 0.02f * V("gfx_temp"), tint = 0.015f * V("gfx_tint");
    float sat = 1 + 0.08f * V("gfx_sat") + p.sat;
    float con = 1 + 0.05f * V("gfx_contrast") + p.con;
    static const float kPix[] = {0, 2, 3, 4};
    int crt = V("gfx_crt");
    float c[14][4] = {{0, 0, 0, 0},
                      {V("gfx_sharpen") / 10.0f, 0.12f * V("gfx_bloom"), 0.06f * V("gfx_vignette"), 0},
                      {0.025f * V("gfx_bright") + p.br, con, sat, powf(2.0f, -0.08f * V("gfx_gamma"))},
                      {0.12f * V("gfx_vibrance"), p.grey, p.lift, 0},
                      {p.r * (1 + temp) * (1 + tint), p.g * (1 - tint), p.b * (1 - temp) * (1 + tint), 1},
                      {0, 0, 0, 0},
                      {(float)V("gfx_ssao"), (float)V("gfx_fog"), (float)V("gfx_dof"), (float)V("gfx_outline")},
                      {1, 1, -1, -2},
                      {kPix[V("gfx_pixelate")], 0.06f * V("gfx_mblur"), (float)V("gfx_grain") + (V("gfx_preset") == 10 ? 3.0f : 0),
                       (float)V("gfx_chroma") + (V("gfx_preset") == 10 ? 3.0f : 0)},
                      {(float)crt, (float)V("gfx_galaxy"), 0, (float)V("gfx_debug")},
                      {1, 0, 0, 0}, {0, 1, 0, 0}, {0, 0, 1, 0},
                      {0.62f, 0.66f, 0.72f, 1}};
    memcpy(g_c, c, sizeof c);
}

static void UpdateCamera() {
    if (g_haveProj) { g_c[7][0] = g_proj._11; g_c[7][1] = g_proj._22; g_c[7][2] = g_proj._33; g_c[7][3] = g_proj._43; }
    // D3D row-vector view matrix: camera right/up/back are its first three columns
    float r[3] = {g_view._11, g_view._21, g_view._31}, u[3] = {g_view._12, g_view._22, g_view._32}, b[3] = {g_view._13, g_view._23, g_view._33};
    memcpy(g_c[10], r, sizeof r); memcpy(g_c[11], u, sizeof u); memcpy(g_c[12], b, sizeof b);
    g_c[1][3] = (GetTickCount() % 600000) / 1000.0f;
}

static bool EnsureTargets(IDirect3DDevice9* dev, UINT w, UINT h) {
    if (w == g_w && h == g_h && g_texA) return true;
    IUnknown** list[] = {(IUnknown**)&g_texA, (IUnknown**)&g_texB, (IUnknown**)&g_texC, (IUnknown**)&g_texD, (IUnknown**)&g_texE,
                         (IUnknown**)&g_texF, (IUnknown**)&g_texPrev, (IUnknown**)&g_texG, (IUnknown**)&g_texH, (IUnknown**)&g_sb};
    for (auto p : list) if (*p) { (*p)->Release(); *p = nullptr; }
    UINT qw = w / 4 ? w / 4 : 1, qh = h / 4 ? h / 4 : 1;
    auto rt = [&](UINT a, UINT b, IDirect3DTexture9** t) {
        return SUCCEEDED(dev->CreateTexture(a, b, 1, D3DUSAGE_RENDERTARGET, D3DFMT_A8R8G8B8, D3DPOOL_DEFAULT, t, nullptr));
    };
    if (!rt(w, h, &g_texA) || !rt(w, h, &g_texB) || !rt(qw, qh, &g_texC) || !rt(qw, qh, &g_texD) || !rt(qw, qh, &g_texE) ||
        !rt(qw, qh, &g_texF) || !rt(w, h, &g_texPrev) || !rt(w, h, &g_texG) || !rt(w, h, &g_texH) || FAILED(dev->CreateStateBlock(D3DSBT_ALL, &g_sb))) {
        for (auto p : list) if (*p) { (*p)->Release(); *p = nullptr; }
        return false;
    }
    g_w = w; g_h = h;
    g_prevValid = false;
    return true;
}

static void CommonState(IDirect3DDevice9* dev) {
    DWORD rs[][2] = {{D3DRS_ZENABLE, FALSE}, {D3DRS_ZWRITEENABLE, FALSE}, {D3DRS_ALPHABLENDENABLE, FALSE}, {D3DRS_ALPHATESTENABLE, FALSE},
                     {D3DRS_CULLMODE, D3DCULL_NONE}, {D3DRS_FOGENABLE, FALSE}, {D3DRS_STENCILENABLE, FALSE}, {D3DRS_SCISSORTESTENABLE, FALSE},
                     {D3DRS_SRGBWRITEENABLE, FALSE}, {D3DRS_COLORWRITEENABLE, 0xF}, {D3DRS_FILLMODE, D3DFILL_SOLID}, {D3DRS_CLIPPLANEENABLE, 0}};
    for (auto& r : rs) dev->SetRenderState((D3DRENDERSTATETYPE)r[0], r[1]);
    for (DWORD s = 0; s < 5; ++s) {
        dev->SetSamplerState(s, D3DSAMP_ADDRESSU, D3DTADDRESS_CLAMP); dev->SetSamplerState(s, D3DSAMP_ADDRESSV, D3DTADDRESS_CLAMP);
        dev->SetSamplerState(s, D3DSAMP_MINFILTER, s == 1 && g_intzUsed ? D3DTEXF_POINT : D3DTEXF_LINEAR);
        dev->SetSamplerState(s, D3DSAMP_MAGFILTER, s == 1 && g_intzUsed ? D3DTEXF_POINT : D3DTEXF_LINEAR);
        dev->SetSamplerState(s, D3DSAMP_MIPFILTER, D3DTEXF_NONE); dev->SetSamplerState(s, D3DSAMP_SRGBTEXTURE, FALSE);
        dev->SetSamplerState(s, D3DSAMP_MIPMAPLODBIAS, 0);
    }
    dev->SetVertexShader(g_vs);
    dev->SetVertexDeclaration(g_decl);
}

// ---- screenshots ---------------------------------------------------------------------------------
static bool g_shotPending = false;
static DWORD g_shotMsgUntil = 0;
static char g_shotMsg[160] = "";
static void SaveShot(IDirect3DDevice9* dev, IDirect3DSurface9* bb) {
    g_shotPending = false;
    if (!g_dx) g_dx = LoadLibraryA("d3dx9_43.dll");
    auto save = g_dx ? (SaveSurface_t)GetProcAddress(g_dx, "D3DXSaveSurfaceToFileW") : nullptr;
    if (!save) return;
    D3DSURFACE_DESC d;
    bb->GetDesc(&d);
    IDirect3DSurface9 *plain = nullptr, *mem = nullptr;
    // resolve (MSAA) into a plain render target, then copy to system memory and save as PNG
    if (FAILED(dev->CreateRenderTarget(d.Width, d.Height, d.Format, D3DMULTISAMPLE_NONE, 0, FALSE, &plain, nullptr))) return;
    if (SUCCEEDED(dev->StretchRect(bb, nullptr, plain, nullptr, D3DTEXF_NONE)) &&
        SUCCEEDED(dev->CreateOffscreenPlainSurface(d.Width, d.Height, d.Format, D3DPOOL_SYSTEMMEM, &mem, nullptr)) &&
        SUCCEEDED(dev->GetRenderTargetData(plain, mem))) {
        std::string dir = g_shotDir;
        while (!dir.empty() && (dir.back() == '\\' || dir.back() == '/')) dir.pop_back();
        bool custom = !dir.empty() && (CreateDirectoryA(dir.c_str(), nullptr) || GetLastError() == ERROR_ALREADY_EXISTS);
        if (!custom) dir = ExeDirFile("screenshots");
        CreateDirectoryA(dir.c_str(), nullptr);
        SYSTEMTIME t; GetLocalTime(&t);
        char name[64];
        snprintf(name, sizeof name, "\\thugpro_%04d%02d%02d_%02d%02d%02d.png", t.wYear, t.wMonth, t.wDay, t.wHour, t.wMinute, t.wSecond);
        std::string path = dir + name;
        wchar_t wpath[1024];
        if (MultiByteToWideChar(CP_ACP, 0, path.c_str(), -1, wpath, 1024) > 0 && SUCCEEDED(save(wpath, 3 /*D3DXIFF_PNG*/, mem, nullptr, nullptr))) {
            if (custom) snprintf(g_shotMsg, sizeof g_shotMsg, "Screenshot saved: %s", path.c_str());
            else snprintf(g_shotMsg, sizeof g_shotMsg, "Screenshot saved: dadmod\\screenshots%s", name);
            g_shotMsgUntil = GetTickCount() + 400;
            mmenu::Log("gfx: screenshot %s", path.c_str());
        }
    }
    if (mem) mem->Release();
    plain->Release();
}

// ---- stages -------------------------------------------------------------------------------------
static bool BackBufferIsTarget(IDirect3DDevice9* dev, IDirect3DSurface9** bbOut) {
    IDirect3DSurface9 *bb = nullptr, *rt = nullptr;
    if (FAILED(dev->GetBackBuffer(0, 0, D3DBACKBUFFER_TYPE_MONO, &bb)) || !bb) return false;
    dev->GetRenderTarget(0, &rt);
    bool same = rt == bb;
    if (rt) rt->Release();
    if (!same) { bb->Release(); return false; }
    *bbOut = bb;
    return true;
}

// ---- dynamic time of day, weather and fireworks (updated once a frame by UpdateWorld) --------------
static double NowS() { return GetTickCount64() / 1000.0; }
static float g_sky[4] = {0, 0.5f, 0, 0};  // c16 for the sky passes: time of day, boost, next time of day, blend
static float g_wx[3][4] = {};             // c17-c19 for the weather pass
// the time of day the level lighting should use now (QB reads it as gfx_todnow)
static int TodSetting() { int t = V("gfx_tod"); return t ? t : g_serverTod; }
static int TodNow() { return V("gfx_tod"); }  // 2026-11-21: Dynamic (old 6) removed, 6 = dawn

static float g_wxCur[4] = {};  // rain, snow, fog, storm as shown (they ease toward the target)
static int g_dynType = 0;
static double g_dynNext = 0;
static bool WeatherOn() { return g_wxCur[0] > 0.004f || g_wxCur[1] > 0.004f || g_wxCur[2] > 0.004f || g_wxCur[3] > 0.004f; }

struct Shell { float az, el, hue; double burst; bool on; };
static Shell g_fw[8] = {};
static double g_showUntil = 0, g_nextLaunch = 0, g_nextAuto = 0;
static bool g_fwDone = false;
static FILETIME g_lastGame = {};
static bool g_lastGameInit = false;
static float Rnd() { return (rand() & 0x7fff) / 32767.0f; }

static void FireworksShow(double seconds, const char* why) {
    double now = NowS();
    if (g_showUntil < now + seconds) g_showUntil = now + seconds;
    if (g_nextLaunch < now) g_nextLaunch = now;
    mmenu::Log("gfx: fireworks (%s)", why);
}
static bool FireworksLive() {
    double now = NowS();
    if (now < g_showUntil) return true;
    for (auto& f : g_fw) if (f.on && now - f.burst < 3.2) return true;
    return false;
}

// ---- street lights: lamp positions per level from dadmod\levellights.txt (work/mods/gfx/gen_lamps.py)
struct Lamp { float x, y, z, r, cr, cg, cb; };
static std::vector<Lamp> g_lamps;
static std::string g_level;
static float g_lampAmt = 0;
static float g_lampC[2 + 48][4];  // c28 amount/count, c29 camera, c30.. lamps
static int g_lampN = 0;
static void SetLevel(const char* name) {
    std::string lv = name;
    for (auto& ch : lv) ch = (char)tolower((unsigned char)ch);
    if (lv == g_level) return;
    g_level = lv;
    g_lamps.clear();
    std::string data, mine;
    ReadWholeFile(ExeDirFile("levellights.txt"), data);
    if (ReadWholeFile(ExeDirFile("levellights_mine.txt"), mine)) data += "\n" + mine;
    bool in = false;
    size_t s0 = 0;
    while (s0 < data.size()) {
        size_t e = data.find_first_of("\r\n", s0);
        std::string line = data.substr(s0, e == std::string::npos ? std::string::npos : e - s0);
        s0 = e == std::string::npos ? data.size() : e + 1;
        if (line.empty() || line[0] == ';') continue;
        if (line[0] == '[') { in = line == "[" + lv + "]"; continue; }
        Lamp l;
        if (in && !line.compare(0, 4, "del ") && sscanf(line.c_str() + 4, "%f %f %f", &l.x, &l.y, &l.z) == 3) {
            for (size_t i = 0; i < g_lamps.size(); ++i)
                if (fabsf(g_lamps[i].x - l.x) < 2 && fabsf(g_lamps[i].y - l.y) < 2 && fabsf(g_lamps[i].z - l.z) < 2) { g_lamps.erase(g_lamps.begin() + i); break; }
            continue;
        }
        if (in && sscanf(line.c_str(), "%f %f %f %f %f %f %f", &l.x, &l.y, &l.z, &l.r, &l.cr, &l.cg, &l.cb) == 7) {
            l.cr /= 255; l.cg /= 255; l.cb /= 255;
            g_lamps.push_back(l);
        }
    }
    mmenu::Log("gfx: level %s, %d lamps", lv.c_str(), (int)g_lamps.size());
}
// Graphics > Sky "Add street light here" / "Remove nearest street light": at the camera (fly there with
// the free camera), saved per level in dadmod\levellights_mine.txt ("del" lines remove a generated lamp)
static void LampMark(bool add) {
    if (g_level.empty()) return;
    const D3DMATRIX& m = g_view;
    float cx = -(m._41 * m._11 + m._42 * m._12 + m._43 * m._13);
    float cy = -(m._41 * m._21 + m._42 * m._22 + m._43 * m._23);
    float cz = -(m._41 * m._31 + m._42 * m._32 + m._43 * m._33);
    char line[160];
    if (add) snprintf(line, sizeof line, "%.0f %.0f %.0f 550 255 200 140", cx, cy, cz);
    else {
        int best = -1; float bd = 500.0f * 500.0f;
        for (size_t i = 0; i < g_lamps.size(); ++i) {
            float d = (g_lamps[i].x - cx) * (g_lamps[i].x - cx) + (g_lamps[i].y - cy) * (g_lamps[i].y - cy) + (g_lamps[i].z - cz) * (g_lamps[i].z - cz);
            if (d < bd) { bd = d; best = (int)i; }
        }
        if (best < 0) return;
        snprintf(line, sizeof line, "del %.0f %.0f %.0f", g_lamps[best].x, g_lamps[best].y, g_lamps[best].z);
    }
    std::string mine;
    ReadWholeFile(ExeDirFile("levellights_mine.txt"), mine);
    mine += "[" + g_level + "]\r\n" + line + "\r\n";
    WriteWholeFile(ExeDirFile("levellights_mine.txt"), mine);
    mmenu::Log("gfx: street light %s (%s)", add ? "added" : "removed", line);
    std::string lv = g_level;
    g_level.clear();
    SetLevel(lv.c_str());
}
static bool LampsOn() { return g_lampAmt > 0.01f && g_lampN > 0; }
// lamps light up in the evening and at night (a little at sunset); picks the 24 nearest to the camera
// Noah 2026-10-20: lamps fade on/off instead of popping: the glow eases toward its target over ~4 s.
static void UpdateLamps(int todA, int todB, float blend, float dt) {
    auto w = [](int t) { return t == 4 || t == 5 || t == 6 ? 1.0f : t == 3 ? 0.25f : 0.0f; };  // 6 dawn: lights still on
    float want = (w(todA) + (w(todB) - w(todA)) * blend) * V("gfx_lamps") / 6.0f;
    static float shown = -1.0f;
    if (shown < 0) shown = want;  // first frame: no fade
    float step = dt * (V("gfx_lamps") / 6.0f) / 4.0f + 0.0001f;
    shown = shown < want ? (shown + step > want ? want : shown + step) : (shown - step < want ? want : shown - step);
    g_lampAmt = shown;
    g_lampN = 0;
    if (g_lampAmt <= 0.01f || g_lamps.empty()) return;
    const D3DMATRIX& m = g_view;
    float cx = -(m._41 * m._11 + m._42 * m._12 + m._43 * m._13);
    float cy = -(m._41 * m._21 + m._42 * m._22 + m._43 * m._23);
    float cz = -(m._41 * m._31 + m._42 * m._32 + m._43 * m._33);
    int best[24];
    float bd[24];
    for (size_t i = 0; i < g_lamps.size(); ++i) {
        const Lamp& l = g_lamps[i];
        float d = (l.x - cx) * (l.x - cx) + (l.y - cy) * (l.y - cy) + (l.z - cz) * (l.z - cz);
        if (d > 6000.0f * 6000.0f) continue;
        int k;
        if (g_lampN < 24) k = g_lampN++;
        else if (d >= bd[23]) continue;
        else k = 23;
        while (k > 0 && bd[k - 1] > d) { bd[k] = bd[k - 1]; best[k] = best[k - 1]; --k; }
        bd[k] = d; best[k] = (int)i;
    }
    g_lampC[0][0] = g_lampAmt; g_lampC[0][1] = (float)g_lampN; g_lampC[0][2] = 0; g_lampC[0][3] = 0;
    g_lampC[1][0] = cx; g_lampC[1][1] = cy; g_lampC[1][2] = cz; g_lampC[1][3] = 1;
    for (int i = 0; i < g_lampN; ++i) {
        const Lamp& l = g_lamps[best[i]];
        float* a = g_lampC[2 + i * 2];
        float* c = g_lampC[3 + i * 2];
        a[0] = l.x; a[1] = l.y; a[2] = l.z; a[3] = l.r;
        c[0] = l.cr; c[1] = l.cg; c[2] = l.cb; c[3] = 0;
    }
}
static void UpdateWorld() {
    static double last = 0;
    static bool seeded = false;
    if (!seeded) { seeded = true; srand(GetTickCount()); }
    double now = NowS();
    float dt = last ? (float)(now - last > 0.5 ? 0.5 : now - last) : 0;
    {   // Night (Noah 2026-10-12: "night mode is waaaay too dark"): ease the dark lift in/out over ~3 s
        float want = TodNow() == 4 ? 0.4f : TodNow() == 6 ? 0.3f : 0.0f;  // dawn lifts a little less
        float step = dt / 3.0f * 0.4f;
        g_nightLift = g_nightLift < want ? (g_nightLift + step > want ? want : g_nightLift + step)
                                         : (g_nightLift - step < want ? want : g_nightLift - step);
    }
    static double hitchLog = 0;  // frame stalls (e.g. while the lighting fades) go to the log, at most once a second
    if (last && now - last > 0.1 && now - hitchLog > 1.0) { hitchLog = now; mmenu::Log("gfx: slow frame %d ms", (int)((now - last) * 1000)); }
    last = now;

    // time of day: a fixed look (the Dynamic cycle was removed 2026-11-21; 6 is now dawn)
    int tod = V("gfx_tod");
    int a = tod, b = tod;
    float blend = 0;
    g_sky[0] = (float)a; g_sky[1] = V("gfx_skypop") / 10.0f; g_sky[2] = (float)b; g_sky[3] = blend;
    if (tod == 0 && g_serverTod > 0) UpdateLamps(g_serverTod, g_serverTod, 0, dt);  // lamps follow the server
    else UpdateLamps(a, b, blend, dt);
    static const float kLite[7] = {1, 0.85f, 1, 0.7f, 0.3f, 0.45f, 0.4f};  // [6] dawn
    static const float kFog[7][3] = {{0.62f, 0.66f, 0.72f}, {0.78f, 0.72f, 0.68f}, {0.68f, 0.72f, 0.78f},
                                     {0.75f, 0.55f, 0.45f}, {0.10f, 0.12f, 0.18f}, {0.30f, 0.24f, 0.30f},
                                     {0.17f, 0.16f, 0.20f}};  // dawn: cold blue-pink (0.42, 0.40, 0.50) x light 0.4
    float lite = kLite[a] + (kLite[b] - kLite[a]) * blend;
    for (int k = 0; k < 3; ++k) g_wx[2][k] = kFog[a][k] + (kFog[b][k] - kFog[a][k]) * blend;
    g_wx[2][3] = 1;

    // weather: a fixed kind, or Random (a new pick every 3-6 minutes from clear, rain, storm and snow; 2026-11-21
    // the old Dynamic picks and fog weather were dropped: the Fog row's ground mist does fog now)
    int w = V("gfx_weather"), type = w;
    if (w == 4) {
        if (now >= g_dynNext) {
            static const int weights[4] = {35, 20, 10, 12};  // clear, rain, storm, snow
            int r = rand() % (35 + 20 + 10 + 12), pick = 0;
            while (r >= weights[pick]) r -= weights[pick++];
            g_dynType = pick;
            g_dynNext = now + 180 + rand() % 180;
            static const char* kNames[] = {"clear", "rain", "storm", "snow"};
            mmenu::Log("gfx: random weather -> %s", kNames[pick]);
        }
        type = g_dynType;
    } else g_dynNext = 0;
    float A = V("gfx_wxamt") / 7.0f, target[4] = {};
    switch (type) {
        case 1: target[0] = A; target[2] = 0.15f * A; break;
        case 2: target[0] = 1.2f * A; target[2] = 0.2f * A; target[3] = A; break;
        case 3: target[1] = A; target[2] = 0.25f * A; break;
    }
    float step = dt / 12.0f;  // a full change takes about 12 seconds
    for (int k = 0; k < 4; ++k) {
        float d = target[k] - g_wxCur[k];
        g_wxCur[k] += d > step ? step : d < -step ? -step : d;
        g_wx[0][k] = g_wxCur[k];
    }
    g_wx[1][0] = lite; g_wx[1][1] = V("gfx_galaxy") == 7 ? 0.74f : 0.9f; g_wx[1][2] = 1; g_wx[1][3] = 0;

    // fireworks: a won game (last_game.txt is rewritten), THUGPro Manager's Launch now, or the timer
    int fwm = V("gfx_fireworks");
    if ((g_presents & 31) == 0) {
        WIN32_FILE_ATTRIBUTE_DATA fa;
        FILETIME t = {};
        if (GetFileAttributesExA(ExeDirFile("last_game.txt").c_str(), GetFileExInfoStandard, &fa)) t = fa.ftLastWriteTime;
        if (!g_lastGameInit) { g_lastGame = t; g_lastGameInit = true; }
        else if (CompareFileTime(&t, &g_lastGame)) { g_lastGame = t; if (fwm) FireworksShow(14, "game over"); }
        std::string req = ExeDirFile("gfx_fireworks.txt");
        if (GetFileAttributesA(req.c_str()) != INVALID_FILE_ATTRIBUTES) { DeleteFileA(req.c_str()); FireworksShow(12, "THUGPro Manager"); }
    }
    if (fwm >= 2) {  // 2-5: on wins and every 1 / 3 / 5 / 10 minutes
        static const int kEvery[] = {1, 3, 5, 10};
        double period = kEvery[fwm - 2] * 60.0;
        if (!g_nextAuto || g_nextAuto > now + period) g_nextAuto = now + period;
        if (now >= g_nextAuto) { FireworksShow(10, "timer"); g_nextAuto = now + period; }
    } else g_nextAuto = 0;
    if (now < g_showUntil && now >= g_nextLaunch) {
        for (auto& f : g_fw) {
            if (f.on && now - f.burst < 3.2) continue;
            float fx = -g_view._13, fz = -g_view._33;  // launch around where the camera looks
            f.az = atan2f(fx, fz) + (Rnd() - 0.5f) * 1.6f;
            f.el = 0.3f + Rnd() * 0.3f;
            f.hue = Rnd();
            f.burst = now + 1.2;
            f.on = true;
            break;
        }
        g_nextLaunch = now + 0.25 + Rnd() * 0.55;
    }
}

static void FireworksConsts(float c[8][4]) {
    double now = NowS();
    for (int i = 0; i < 8; ++i) {
        c[i][0] = g_fw[i].az; c[i][1] = g_fw[i].el; c[i][3] = g_fw[i].hue;
        c[i][2] = g_fw[i].on ? (float)(now - g_fw[i].burst) : 99.0f;
    }
}
// without readable depth (MSAA): additive pass right after the sky, so everything the level draws afterwards covers the fireworks
static void DrawFireworks(IDirect3DDevice9* dev) {
    g_fwDone = true;
    IDirect3DSurface9* bb = nullptr;
    if (!BackBufferIsTarget(dev, &bb)) return;
    D3DSURFACE_DESC d;
    bb->GetDesc(&d);
    if (!MakeShaders(dev) || !g_psFireworks || !EnsureTargets(dev, d.Width, d.Height)) { bb->Release(); return; }
    static bool once = false;
    if (!once) { once = true; mmenu::Log("gfx: fireworks drawing"); }
    if (InterlockedExchange(&g_dirtyPost, 0)) BuildConstants();
    UpdateCamera();
    float c[8][4];
    FireworksConsts(c);
    g_c[9][2] = 0;
    g_inPost = true;
    g_sb->Capture();
    IDirect3DSurface9* oldDS = nullptr;
    dev->GetDepthStencilSurface(&oldDS);
    dev->SetDepthStencilSurface(nullptr);
    CommonState(dev);
    dev->SetRenderState(D3DRS_ALPHABLENDENABLE, TRUE);
    dev->SetRenderState(D3DRS_BLENDOP, D3DBLENDOP_ADD);
    dev->SetRenderState(D3DRS_SRCBLEND, D3DBLEND_ONE);
    dev->SetRenderState(D3DRS_DESTBLEND, D3DBLEND_ONE);
    dev->SetPixelShaderConstantF(1, &g_c[1][0], 13);
    dev->SetPixelShaderConstantF(20, &c[0][0], 8);
    Pass(dev, g_psFireworks, bb, d.Width, d.Height, d.Width, d.Height, nullptr);
    dev->SetDepthStencilSurface(oldDS);
    g_sb->Apply();
    if (oldDS) oldDS->Release();
    bb->Release();
    g_inPost = false;
}

// Night tint on the 3D scene (2026-11-21): on many levels (New Orleans) the TOD manager only darkens the outdoor light
// group, so Night / Evening lights left buildings at day brightness. Tint everything with depth below the far plane
// (the sky keeps ps_sky's grade), before lamps, fireworks and weather so those draw on top untinted.
// Ground mist constants (Noah 2026-11-21, Fog row): heights in world units (skater ~72 tall).
// The ground is a per-level floor (Noah: "the fog follows the skater's camera"): sample = our own skater's feet height
// (local player's CSkater position +0x4C, the same read modes/sonic/tawhore use), or camera height - 60 without one.
// floor = the lowest sample over the last 20 s (per-second minimums), eased over ~3 s, so vert, rooftops, jumps and
// camera moves don't lift the mist; staying in a lower area lowers it. Reset at level load.
static bool LocalFeetY(float* y) {
    char* mgr = *(char**)kNetManagerPtr;
    if (!mgr) return false;
    int guard = 0;
    for (DWORD node = *(DWORD*)(mgr + kPlayerList); node && *(int*)(node + 4) != -1 && guard < 64; node = *(DWORD*)(node + 0xC), ++guard) {
        char* player = *(char**)(node + 4);
        if (!player || !(*(DWORD*)(player + kPlayerFlags) & 1)) continue;  // local player only
        char* skater = *(char**)(player + kPlayerSkater);
        if (!skater) return false;
        float v = ((float*)(skater + 0x4C))[1];
        if (!(v > -1e6f && v < 1e6f)) return false;
        *y = v;
        return true;
    }
    return false;
}
static float MistFloor(float camY) {
    static float ground = 0, ring[20], curMin = 0, logged = 0;
    static int ringN = 0, ringAt = 0;
    static double last = 0, secAt = 0;
    static std::string level;
    static bool usedSkater = false, loggedSrc = false;
    float s;
    bool sk = LocalFeetY(&s);
    if (!sk) s = camY - 60.0f;
    if (!loggedSrc || sk != usedSkater) { loggedSrc = true; usedSkater = sk; mmenu::Log("gfx: ground mist floor from %s", sk ? "the skater's feet" : "the camera (no local skater)"); }
    double now = NowS();
    if (!last || now - last > 5.0 || level != g_level) {  // first frame, level load, or the mist was off for a while
        level = g_level;
        ground = curMin = logged = s; ringN = 0; ringAt = 0; secAt = now; last = now;
        mmenu::Log("gfx: ground mist floor %.0f", ground);
        return ground;
    }
    if (s < curMin) curMin = s;
    if (now - secAt >= 1.0) {  // close this second's minimum
        ring[ringAt] = curMin; ringAt = (ringAt + 1) % 20; if (ringN < 20) ++ringN;
        curMin = s; secAt = now;
    }
    float target = curMin;
    for (int i = 0; i < ringN; ++i) if (ring[i] < target) target = ring[i];
    float k = (float)((now - last) / 3.0); if (k > 1) k = 1;
    ground += (target - ground) * k;
    last = now;
    if (fabsf(ground - logged) > 100.0f) { logged = ground; mmenu::Log("gfx: ground mist floor %.0f", ground); }
    return ground;
}
static void MistConsts(float out[2][4]) {
    static const float kHs[5] = {0, 0.45f * 20, 0.45f * 75, 0.45f * 170, 0.45f * 450};
    static const float kD[5] = {0, 0.0078f, 0.0029f, 0.00147f, 0.00084f};
    int lv = V("gfx_todfog");
    if (lv < 1) lv = 1;
    if (lv > 4) lv = 4;
    const D3DMATRIX& m = g_view;
    float camY = -(m._41 * m._21 + m._42 * m._22 + m._43 * m._23);
    float ground = MistFloor(camY);
    // Fog intensity: 6 = the original thickness, default 5; above 6 it climbs fast (Noah 2026-11-21: "10 needs to be much
    // more dense", then "even the scale out"): every step is 1.75x the one before: 1 = 0.06x, 4 = 0.33x, 6 = 1x, 8 = 3.1x, 10 = 9.4x;
    // the mist may cover more above 6 (cap 0.92 at 6 .. 0.985 at 10)
    int fa = V("gfx_fogamt");
    float amt = powf(1.75f, (float)(fa - 6));
    float cap = fa <= 6 ? 0.92f : 0.92f + (fa - 6) * 0.01625f;
    out[0][0] = kD[lv] * amt; out[0][1] = kHs[lv]; out[0][2] = ground; out[0][3] = cap;
    // color: the time of day fog color; at Night / Evening lights a dark blue-gray scaled by the light level
    float k[4] = {g_sky[0], g_sky[1], g_sky[2], g_sky[3]};
    if (V("gfx_tod") == 0) { k[0] = k[2] = (float)g_serverTod; k[3] = 0; }
    auto nw = [](float t) { return t > 3.5f && t < 5.5f ? 1.0f : 0.0f; };  // night / evening lights
    auto dw = [](float t) { return t > 5.5f ? 1.0f : 0.0f; };              // dawn
    float night = nw(k[0]) + (nw(k[2]) - nw(k[0])) * k[3], dawn = dw(k[0]) + (dw(k[2]) - dw(k[0])) * k[3];
    static const float kNight[3] = {0.30f, 0.34f, 0.44f}, kDawn[3] = {0.42f, 0.40f, 0.50f};
    float lite = g_wx[1][0] > 0 ? g_wx[1][0] : 1.0f;
    for (int i = 0; i < 3; ++i) out[1][i] = g_wx[2][i] + (kNight[i] * lite - g_wx[2][i]) * night + (kDawn[i] * lite - g_wx[2][i]) * dawn;
    out[1][3] = 1;
}

static void NightTint(IDirect3DDevice9* dev, IDirect3DSurface9* bb) {
    if (g_mainMenu || g_inPost) return;
    float k[4] = {g_sky[0], g_sky[1], g_sky[2], g_sky[3]};
    if (V("gfx_tod") == 0) {
        if (g_serverTod <= 0) return;
        k[0] = k[2] = (float)g_serverTod; k[3] = 0;
    }
    auto dark = [](float t) { return t > 3.5f; };
    if (!dark(k[0]) && !(k[3] > 0.001f && dark(k[2]))) return;
    if (!MakeShaders(dev) || !g_psNightTint) return;
    D3DSURFACE_DESC d;
    bb->GetDesc(&d);
    if (!EnsureTargets(dev, d.Width, d.Height)) return;
    IDirect3DSurface9* ds = nullptr;
    dev->GetDepthStencilSurface(&ds);
    if (!ds) return;  // no depth: can't tell the sky from geometry, leave it
    static bool once = false;
    if (!once) { once = true; mmenu::Log("gfx: night tint on 3D scene"); }
    g_inPost = true;
    g_sb->Capture();
    IDirect3DSurface9 *sA = nullptr, *oldRT = nullptr;
    dev->GetRenderTarget(0, &oldRT);
    g_texA->GetSurfaceLevel(0, &sA);
    dev->StretchRect(bb, nullptr, sA, nullptr, D3DTEXF_NONE);
    CommonState(dev);
    dev->SetRenderState(D3DRS_ZENABLE, TRUE);
    dev->SetRenderState(D3DRS_ZWRITEENABLE, FALSE);
    dev->SetRenderState(D3DRS_ZFUNC, D3DCMP_GREATER);
    dev->SetPixelShaderConstantF(16, k, 1);
    dev->SetRenderTarget(0, bb);
    dev->SetDepthStencilSurface(ds);
    D3DVIEWPORT9 vp = {0, 0, d.Width, d.Height, 0, 1};
    dev->SetViewport(&vp);
    dev->SetPixelShader(g_psNightTint);
    dev->SetTexture(0, g_texA); dev->SetTexture(1, nullptr); dev->SetTexture(2, nullptr); dev->SetTexture(3, nullptr);
    float px[4] = {1.0f / d.Width, 1.0f / d.Height, (float)d.Width, (float)d.Height};
    dev->SetPixelShaderConstantF(0, px, 1);
    Quad(dev, d.Width, d.Height, 1.0f);
    dev->SetTexture(0, nullptr);
    if (oldRT) { dev->SetRenderTarget(0, oldRT); oldRT->Release(); }
    dev->SetDepthStencilSurface(ds);
    g_sb->Apply();
    if (sA) sA->Release();
    ds->Release();
    g_inPost = false;
}

static void RunScene(IDirect3DDevice9* dev, bool atPresent = false) {
    if (!atPresent) {  // only when the screen itself is being drawn to (not an offscreen texture)
        IDirect3DSurface9* t = nullptr;
        if (!BackBufferIsTarget(dev, &t)) return;
        t->Release();
    }
    g_sceneDone = true;
    if (MirrorOn()) g_origRS(dev, D3DRS_CULLMODE, g_cullWant);  // 2D draws with the game's own culling
    {   // night tint first, whether or not the other scene effects are on
        IDirect3DSurface9* nb = nullptr;
        if (atPresent ? SUCCEEDED(dev->GetBackBuffer(0, 0, D3DBACKBUFFER_TYPE_MONO, &nb)) && nb : BackBufferIsTarget(dev, &nb)) {
            NightTint(dev, nb);
            nb->Release();
        }
    }
    bool wantScene = SceneWanted(), wantShot = g_shotPending && !V("gfx_shothud");
    if (!wantScene && !wantShot) return;
    IDirect3DSurface9* bb = nullptr;
    if (atPresent) {
        if (FAILED(dev->GetBackBuffer(0, 0, D3DBACKBUFFER_TYPE_MONO, &bb)) || !bb) return;
    } else if (!BackBufferIsTarget(dev, &bb)) return;
    if (!wantScene) { SaveShot(dev, bb); bb->Release(); return; }
    D3DSURFACE_DESC d;
    bb->GetDesc(&d);
    if (!MakeShaders(dev) || !EnsureTargets(dev, d.Width, d.Height)) { bb->Release(); return; }
    if (InterlockedExchange(&g_dirtyPost, 0)) BuildConstants();
    UpdateCamera();
    g_c[3][3] = g_nightLift > 0.01f ? g_nightLift : 0.0f;
    g_c[9][2] = g_intzUsed && !g_msaaOn ? 1.0f : 0.0f;
    UINT qw = g_w / 4 ? g_w / 4 : 1, qh = g_h / 4 ? g_h / 4 : 1;
    g_inPost = true;
    g_sb->Capture();
    IDirect3DSurface9 *oldDS = nullptr, *sA = nullptr, *sB = nullptr, *sC = nullptr, *sD = nullptr, *sE = nullptr, *sF = nullptr, *sP = nullptr,
                      *sG = nullptr, *sH = nullptr;
    dev->GetDepthStencilSurface(&oldDS);
    g_texA->GetSurfaceLevel(0, &sA); g_texB->GetSurfaceLevel(0, &sB); g_texC->GetSurfaceLevel(0, &sC);
    g_texD->GetSurfaceLevel(0, &sD); g_texE->GetSurfaceLevel(0, &sE); g_texF->GetSurfaceLevel(0, &sF); g_texPrev->GetSurfaceLevel(0, &sP);
    g_texG->GetSurfaceLevel(0, &sG); g_texH->GetSurfaceLevel(0, &sH);
    dev->StretchRect(bb, nullptr, sA, nullptr, D3DTEXF_NONE);
    dev->SetDepthStencilSurface(nullptr);
    CommonState(dev);
    dev->SetPixelShaderConstantF(1, &g_c[1][0], 13);
    float dx[4] = {1.0f / qw, 0, 0, 0}, dy[4] = {0, 1.0f / qh, 0, 0};
    IDirect3DTexture9* cur = g_texA;
    bool depthFx = g_intzUsed && DepthWanted();
    bool sceneFx = depthFx || V("gfx_mblur") || V("gfx_pixelate");
    static int dbg = 0;
    if (dbg < 1 && depthFx) { dbg++; mmenu::Log("gfx: depth effects running"); }
    if (sceneFx) {
        if (depthFx && V("gfx_dof")) {  // blurred quarter-res copy for depth of field
            Pass(dev, g_psDown, sE, g_w, g_h, qw, qh, g_texA);
            dev->SetPixelShaderConstantF(5, dx, 1); Pass(dev, g_psBlur, sF, qw, qh, qw, qh, g_texE);
            dev->SetPixelShaderConstantF(5, dy, 1); Pass(dev, g_psBlur, sE, qw, qh, qw, qh, g_texF);
        }
        if (depthFx && V("gfx_ssao")) {  // AO, then a depth-aware blur across and down
            Pass(dev, g_psAO, sG, g_w, g_h, g_w, g_h, nullptr, g_intz);
            float bx[4] = {1.0f / g_w, 0, 0, 0}, by[4] = {0, 1.0f / g_h, 0, 0};
            dev->SetPixelShaderConstantF(5, bx, 1); Pass(dev, g_psAOBlur, sH, g_w, g_h, g_w, g_h, g_texG, g_intz);
            dev->SetPixelShaderConstantF(5, by, 1); Pass(dev, g_psAOBlur, sG, g_w, g_h, g_w, g_h, g_texH, g_intz);
        }
        dev->SetTexture(4, depthFx && V("gfx_ssao") ? g_texG : nullptr);
        float mb = g_c[8][1];
        if (!g_prevValid) { g_c[8][1] = 0; dev->SetPixelShaderConstantF(8, g_c[8], 1); }
        Pass(dev, g_psScene, sB, g_w, g_h, g_w, g_h, g_texA, depthFx ? g_intz : nullptr, g_texPrev, g_texE);
        g_c[8][1] = mb; dev->SetPixelShaderConstantF(8, g_c[8], 1);
        cur = g_texB;
    }
    if (MistOn() && g_psGroundMist && g_intzUsed && !g_msaaOn) {  // ground mist, before lamps / fireworks / weather
        float mc[2][4];
        MistConsts(mc);
        const D3DMATRIX& m = g_view;
        float cam[4] = {-(m._41 * m._11 + m._42 * m._12 + m._43 * m._13), -(m._41 * m._21 + m._42 * m._22 + m._43 * m._23),
                        -(m._41 * m._31 + m._42 * m._32 + m._43 * m._33), 1};
        dev->SetPixelShaderConstantF(29, cam, 1);
        dev->SetPixelShaderConstantF(80, &mc[0][0], 2);
        static bool once = false;
        if (!once) { once = true; mmenu::Log("gfx: ground mist on 3D scene (level %d)", V("gfx_todfog")); }
        IDirect3DTexture9* dst = cur == g_texA ? g_texB : g_texA;
        Pass(dev, g_psGroundMist, cur == g_texA ? sB : sA, g_w, g_h, g_w, g_h, cur, g_intz);
        cur = dst;
    }
    if (LampsOn() && g_psLamps && g_intzUsed && !g_msaaOn) {
        dev->SetPixelShaderConstantF(28, &g_lampC[0][0], 2 + g_lampN * 2);
        IDirect3DTexture9* dst = cur == g_texA ? g_texB : g_texA;
        Pass(dev, g_psLamps, cur == g_texA ? sB : sA, g_w, g_h, g_w, g_h, cur, g_intz);
        cur = dst;
    }
    if (FireworksLive() && g_psFireworks && g_intzUsed && !g_msaaOn) {
        float c[8][4];
        FireworksConsts(c);
        dev->SetPixelShaderConstantF(20, &c[0][0], 8);
        dev->SetRenderState(D3DRS_ALPHABLENDENABLE, TRUE);
        dev->SetRenderState(D3DRS_BLENDOP, D3DBLENDOP_ADD);
        dev->SetRenderState(D3DRS_SRCBLEND, D3DBLEND_ONE);
        dev->SetRenderState(D3DRS_DESTBLEND, D3DBLEND_ONE);
        Pass(dev, g_psFireworks, cur == g_texA ? sA : sB, g_w, g_h, g_w, g_h, nullptr, g_intz);
        dev->SetRenderState(D3DRS_ALPHABLENDENABLE, FALSE);
    }
    if (WeatherOn() && g_psWeather) {
        dev->SetPixelShaderConstantF(17, &g_wx[0][0], 3);
        IDirect3DTexture9* dst = cur == g_texA ? g_texB : g_texA;
        Pass(dev, g_psWeather, cur == g_texA ? sB : sA, g_w, g_h, g_w, g_h, cur, g_intzUsed && !g_msaaOn ? g_intz : nullptr);
        cur = dst;
    }
    if (V("gfx_bloom")) {
        Pass(dev, g_psBright, sC, g_w, g_h, qw, qh, cur);
        dev->SetPixelShaderConstantF(5, dx, 1); Pass(dev, g_psBlur, sD, qw, qh, qw, qh, g_texC);
        dev->SetPixelShaderConstantF(5, dy, 1); Pass(dev, g_psBlur, sC, qw, qh, qw, qh, g_texD);
    }
    int fx = V("gfx_fxaa");
    for (int i = 0; i < fx; ++i) {  // high quality = two passes
        IDirect3DTexture9* dst = cur == g_texA ? g_texB : g_texA;
        IDirect3DSurface9* ds = cur == g_texA ? sB : sA;
        Pass(dev, g_psFxaa, ds, g_w, g_h, g_w, g_h, cur);
        cur = dst;
    }
    Pass(dev, g_psLook, bb, g_w, g_h, g_w, g_h, cur, V("gfx_bloom") ? g_texC : nullptr);
    if (V("gfx_mblur")) { dev->StretchRect(bb, nullptr, sP, nullptr, D3DTEXF_NONE); g_prevValid = true; }
    dev->SetDepthStencilSurface(oldDS);
    g_sb->Apply();
    dev->SetTexture(4, nullptr);
    IUnknown* rel[] = {oldDS, sA, sB, sC, sD, sE, sF, sP, sG, sH};
    for (auto r : rel) if (r) r->Release();
    g_inPost = false;
    if (wantShot) SaveShot(dev, bb);
    bb->Release();
}

static void DrawGalaxy(IDirect3DDevice9* dev) {
    g_galaxyDone = true;
    // no shader for it on this card: hand the sky back to the game (the hooks stop skipping its sky draws)
    if (!MakeShaders(dev) || !(g_psGalaxy || AnySkyN())) {
        if (!g_galaxyOff) { g_galaxyOff = true; mmenu::Log("gfx: galaxy sky off: this card has no shader for it, the game's own sky stays"); }
        return;
    }
    static bool once = false;
    if (!once) { once = true; mmenu::Log("gfx: galaxy sky drawing"); }
    IDirect3DSurface9* rt = nullptr;
    if (FAILED(dev->GetRenderTarget(0, &rt)) || !rt) return;
    D3DSURFACE_DESC d;
    rt->GetDesc(&d);
    rt->Release();
    if (!EnsureTargets(dev, d.Width, d.Height)) return;
    if (InterlockedExchange(&g_dirtyPost, 0)) BuildConstants();
    UpdateCamera();
    g_inPost = true;
    g_sb->Capture();
    CommonState(dev);
    // fill only the empty sky: depth test at the far plane, no depth writes
    dev->SetRenderState(D3DRS_ZENABLE, TRUE);
    dev->SetRenderState(D3DRS_ZFUNC, D3DCMP_LESSEQUAL);
    int style = V("gfx_galaxy");
    float save9 = g_c[9][1];
    IDirect3DPixelShader9* skyN = style >= 5 && style <= 14 ? g_psSkyN[style - 5] : nullptr;
    if (!skyN && !g_psGalaxy) for (int i = 0; i < 10 && !skyN; ++i) skyN = g_psSkyN[i];  // only some extra skies made it: the first of those
    IDirect3DPixelShader9* ps = skyN ? skyN : g_psGalaxy;
    if (!ps) { g_c[9][1] = save9; g_sb->Apply(); g_inPost = false; return; }
    dev->SetPixelShader(ps);
    dev->SetPixelShaderConstantF(1, &g_c[1][0], 13);
    g_c[9][1] = save9;
    dev->SetPixelShaderConstantF(16, g_sky, 1);
    float px[4] = {1.0f / d.Width, 1.0f / d.Height, (float)d.Width, (float)d.Height};
    dev->SetPixelShaderConstantF(0, px, 1);
    Quad(dev, d.Width, d.Height, 1.0f);
    g_sb->Apply();
    g_inPost = false;
}

static bool SkyWanted() { return V("gfx_tod") || V("gfx_skypop"); }
// runs when the sky pass ends: only the sky is on the screen, so it can be graded as a whole
static void SkyGrade(IDirect3DDevice9* dev) {
    g_skyGraded = true;
    IDirect3DSurface9* bb = nullptr;
    if (!BackBufferIsTarget(dev, &bb)) return;
    D3DSURFACE_DESC d;
    bb->GetDesc(&d);
    if (!MakeShaders(dev) || !g_psSky || !EnsureTargets(dev, d.Width, d.Height)) { bb->Release(); return; }
    static bool once = false;
    if (!once) { once = true; mmenu::Log("gfx: sky grading (time of day %d, boost %d)", V("gfx_tod"), V("gfx_skypop")); }
    if (InterlockedExchange(&g_dirtyPost, 0)) BuildConstants();
    UpdateCamera();
    g_inPost = true;
    g_sb->Capture();
    IDirect3DSurface9 *sA = nullptr, *oldDS = nullptr;
    g_texA->GetSurfaceLevel(0, &sA);
    dev->GetDepthStencilSurface(&oldDS);
    dev->StretchRect(bb, nullptr, sA, nullptr, D3DTEXF_NONE);
    CommonState(dev);
    dev->SetPixelShaderConstantF(1, &g_c[1][0], 13);
    dev->SetPixelShaderConstantF(16, g_sky, 1);
    // grade only the sky: the game draws some buildings before its sky (Noah 2026-11-21: stars and the milky way showed
    // on walls at Night). Like the galaxy, a depth test at the far plane passes only where nothing has been drawn yet.
    // Without a depth buffer the whole screen is graded, as before.
    if (oldDS) { dev->SetRenderState(D3DRS_ZENABLE, TRUE); dev->SetRenderState(D3DRS_ZFUNC, D3DCMP_LESSEQUAL); }
    dev->SetRenderTarget(0, bb);
    D3DVIEWPORT9 vp = {0, 0, g_w, g_h, 0, 1};
    dev->SetViewport(&vp);
    dev->SetPixelShader(g_psSky);
    dev->SetTexture(0, g_texA); dev->SetTexture(1, nullptr); dev->SetTexture(2, nullptr); dev->SetTexture(3, nullptr);
    float px[4] = {1.0f / g_w, 1.0f / g_h, (float)g_w, (float)g_h};
    dev->SetPixelShaderConstantF(0, px, 1);
    Quad(dev, g_w, g_h, 1.0f);
    dev->SetTexture(0, nullptr);
    dev->SetDepthStencilSurface(oldDS);
    g_sb->Apply();
    if (oldDS) oldDS->Release();
    if (sA) sA->Release();
    bb->Release();
    g_inPost = false;
}

static void RunScreen(IDirect3DDevice9* dev) {
    bool wantScreen = ScreenWanted(), wantFps = V("gfx_fps") != 0, wantMsg = (int)(g_shotMsgUntil - GetTickCount()) > 0;
    if (!wantScreen && !wantFps && !wantMsg && !g_shotPending) return;
    IDirect3DSurface9* bb = nullptr;
    if (FAILED(dev->GetBackBuffer(0, 0, D3DBACKBUFFER_TYPE_MONO, &bb)) || !bb) return;
    D3DSURFACE_DESC d;
    bb->GetDesc(&d);
    if (!MakeShaders(dev) || !EnsureTargets(dev, d.Width, d.Height)) { bb->Release(); return; }
    if (InterlockedExchange(&g_dirtyPost, 0)) BuildConstants();
    UpdateCamera();
    g_inPost = true;
    dev->BeginScene();
    g_sb->Capture();
    IDirect3DSurface9 *oldRT = nullptr, *oldDS = nullptr, *sA = nullptr;
    dev->GetRenderTarget(0, &oldRT);
    dev->GetDepthStencilSurface(&oldDS);
    // FPS digits and the screenshot flash are drawn by the screen shader
    float tx[2][4] = {{-1, -1, -1, -1}, {-1, -1, -1, 0}};
    if (wantFps) {
        static LARGE_INTEGER last = {}, freq = {};
        static double ms = 16.7;
        LARGE_INTEGER now;
        QueryPerformanceCounter(&now);
        if (!freq.QuadPart) QueryPerformanceFrequency(&freq);
        if (last.QuadPart) ms = ms * 0.92 + (double)(now.QuadPart - last.QuadPart) * 1000.0 / freq.QuadPart * 0.08;
        last = now;
        int fps = ms > 0 ? (int)(1000.0 / ms + 0.5) : 0;
        if (fps > 999) fps = 999;
        float* g = &tx[0][0];
        if (fps >= 100) g[0] = (float)(fps / 100);
        if (fps >= 10) g[1] = (float)(fps / 10 % 10);
        g[2] = (float)(fps % 10);
        if (V("gfx_fps") == 1) { g[4] = 10; g[5] = 11; g[6] = 12; }
    }
    if (wantMsg) tx[1][3] = 0.6f * ((int)(g_shotMsgUntil - GetTickCount()) / 400.0f);
    if (tx[1][3] < 0) tx[1][3] = 0;
    if (wantScreen || wantFps || wantMsg) {
        g_texA->GetSurfaceLevel(0, &sA);
        dev->StretchRect(bb, nullptr, sA, nullptr, D3DTEXF_NONE);
        dev->SetDepthStencilSurface(nullptr);
        CommonState(dev);
        dev->SetPixelShaderConstantF(1, &g_c[1][0], 13);
        dev->SetPixelShaderConstantF(14, &tx[0][0], 2);
        float sc16[4] = {0, 0, V("gfx_fps") == 2 ? 1.0f : 0.0f, 0};
        dev->SetPixelShaderConstantF(16, sc16, 1);
        Pass(dev, g_psScreen, bb, g_w, g_h, g_w, g_h, g_texA);
    }
    dev->SetRenderTarget(0, oldRT);
    dev->SetDepthStencilSurface(oldDS);
    g_sb->Apply();
    dev->EndScene();
    IUnknown* rel[] = {oldRT, oldDS, sA};
    for (auto r : rel) if (r) r->Release();
    g_inPost = false;
    if (g_shotPending) SaveShot(dev, bb);
    bb->Release();
}


// ---- per-frame hooks ---------------------------------------------------------------------------
static void CheckKeysAndIni() {
    if ((g_presents & 63) == 0) {  // ~once a second: pick up edits THUGPro Manager made to gfx.ini
        FILETIME t = IniTime();
        if (CompareFileTime(&t, &g_iniTime)) {
            int trick = V("gfx_tricksfx"), postfx = V("gfx_postfx");
            Load();
            if (trick && !V("gfx_tricksfx")) InterlockedExchange(&g_trickStopPending, 1);
            else if (V("gfx_tricksfx") && trick != V("gfx_tricksfx")) InterlockedExchange(&g_trickVolPending, 1);
            if (postfx != V("gfx_postfx"))
                mmenu::Log("gfx: graphics effects -> %s (gfx.ini changed)", V("gfx_postfx") ? "ReShade (dadmod's screen effects skipped)" : "dadmod");
        }
    }
    if (InterlockedExchange(&g_trickStopPending, 0)) StopSpecialStream("gfx.ini changed");
    if (InterlockedExchange(&g_trickVolPending, 0)) SetSpecialStreamVolume(g_trickBaseVol * V("gfx_tricksfx") / 100.0f);
    static bool down = false;
    DWORD pid = 0;
    HWND fg = GetForegroundWindow();
    if (fg) GetWindowThreadProcessId(fg, &pid);
    bool now = pid == GetCurrentProcessId() && (GetAsyncKeyState(VK_F11) & 0x8000) != 0;
    if (now && !down && V("gfx_shotkey")) g_shotPending = true;
    if ((g_presents & 31) == 0) {  // dadmod\gfx_shot.txt: a tool (or THUGPro Manager) asks for a screenshot
        std::string req = ExeDirFile("gfx_shot.txt");
        if (GetFileAttributesA(req.c_str()) != INVALID_FILE_ATTRIBUTES) { DeleteFileA(req.c_str()); g_shotPending = true; }
    }
    down = now;
}

static IDirect3DSurface9* MakeIntz(IDirect3DDevice9* dev);
// the game binds its depth buffer once, so the readable copy is swapped in and out here, between frames
static void UpdateDepthBinding(IDirect3DDevice9* dev) {
    bool want = DepthWanted() && !g_msaaOn && !g_intzFail;
    IDirect3DSurface9* cur = nullptr;
    dev->GetDepthStencilSurface(&cur);
    if (cur && cur != g_intzSurf && cur != g_autoDS) {  // the game's depth buffer (it may not be the automatic one)
        D3DSURFACE_DESC d, bd = {};
        cur->GetDesc(&d);
        IDirect3DSurface9* bb = nullptr;
        if (SUCCEEDED(dev->GetBackBuffer(0, 0, D3DBACKBUFFER_TYPE_MONO, &bb)) && bb) { bb->GetDesc(&bd); bb->Release(); }
        if (d.Width == bd.Width && d.Height == bd.Height) {
            if (g_autoDS) g_autoDS->Release();
            g_autoDS = cur;
            g_autoDS->AddRef();
            static int n = 0;
            if (n++ < 3) mmenu::Log("gfx: game depth buffer %ux%u format %d", d.Width, d.Height, (int)d.Format);
        }
    }
    if (want && cur && cur == g_autoDS && MakeIntz(dev)) { g_origDS(dev, g_intzSurf); g_intzBound = true; g_intzUsed = true; }
    else if (!want && cur && cur == g_intzSurf && g_autoDS) { g_origDS(dev, g_autoDS); g_intzBound = false; }
    else g_intzBound = cur && cur == g_intzSurf;
    if (g_intzBound) g_intzUsed = true;
    if (cur) cur->Release();
}

// ---- weather fog through the game's own fog (Noah 2026-10-12: fog made see-through objects look like sky) ----
// The engine keeps its fog in globals and sets the D3D fog states from them (vertex fog, linear, range based):
// SetFogEnable 0x4B8E40, SetFogDistance 0x4B8E80, SetFogColor 0x4B8EE0, and every frame's state setup. Writing the
// globals and the states once a frame makes every draw fogged per vertex, see-through ones included. The level's
// own values are kept and put back when the weather clears (or picked up again if the game changes them).
static const DWORD kFogOnVar = 0x787338, kFogColorVar = 0x78733C, kFogStartVar = 0x787340, kFogEndVar = 0x787344;
static bool g_fogOver = false;
static DWORD g_gameFogOn, g_gameFogColor, g_ourFogOn, g_ourFogColor;
static float g_gameFogStart, g_gameFogEnd, g_ourFogStart, g_ourFogEnd;
static DWORD FBits(float f) { DWORD d; memcpy(&d, &f, 4); return d; }
static void FogStates(IDirect3DDevice9* dev, DWORD on, DWORD color, float start, float end) {
    dev->SetRenderState(D3DRS_FOGENABLE, on);
    dev->SetRenderState(D3DRS_FOGTABLEMODE, D3DFOG_NONE);
    dev->SetRenderState(D3DRS_RANGEFOGENABLE, TRUE);
    dev->SetRenderState(D3DRS_FOGVERTEXMODE, D3DFOG_LINEAR);
    dev->SetRenderState(D3DRS_FOGCOLOR, color);
    dev->SetRenderState(D3DRS_FOGSTART, FBits(start));
    dev->SetRenderState(D3DRS_FOGEND, FBits(end));
}
// Per-pixel fog (Noah 2026-11-21: the night fog "clips through objects"). The game's fog is vertex fog: worked out
// at each corner and blended across the face, so a big wall or road that runs far away gets the far fog smeared
// onto its near part. While our own time of day or weather fog is on, the same fog values are used as table fog
// (eye distance per pixel) instead. The level at its normal time keeps the stock vertex fog (Noah's pick).
static bool g_pixFogSet = false;
static bool PixelFogOn() { return g_cardPixFog && !g_mainMenu && (TodSetting() != 0 || g_fogOver); }
// Fog with our time of day is its own option, off by default (Noah 2026-11-21): while our time of day is on and
// the Fog row is off, the game's fog stays switched off (weather fog still works: it turns this off while it shows).
static bool g_todFogOff = false;
static bool TodFogOff() { return !g_mainMenu && TodSetting() != 0 && !g_fogOver; }  // our time of day never shows the game's faint TOD fog (Fog row = ground mist now)
static void TodFogStates(IDirect3DDevice9* dev) {
    bool off = TodFogOff();
    if (off == g_todFogOff && !off) return;
    if (off != g_todFogOff) mmenu::Log("gfx: time of day fog %s", off ? "off (Fog row off)" : "back to the game's");
    g_todFogOff = off;
    g_origRS(dev, D3DRS_FOGENABLE, off ? FALSE : *(DWORD*)kFogOnVar);
}
static void PixelFogStates(IDirect3DDevice9* dev) {
    bool on = PixelFogOn();
    if (on == g_pixFogSet && !on) return;  // while on, set every frame (a device reset puts both states back to none)
    if (on != g_pixFogSet) mmenu::Log("gfx: fog %s", on ? "per pixel (our time of day / weather)" : "per corner (the game's own)");
    g_pixFogSet = on;
    g_origRS(dev, D3DRS_FOGVERTEXMODE, on ? D3DFOG_NONE : D3DFOG_LINEAR);
    g_origRS(dev, D3DRS_FOGTABLEMODE, on ? D3DFOG_LINEAR : D3DFOG_NONE);
}
static void ApplyWeatherFog(IDirect3DDevice9* dev) {
    DWORD* on = (DWORD*)kFogOnVar;
    DWORD* color = (DWORD*)kFogColorVar;
    float* start = (float*)kFogStartVar;
    float* end = (float*)kFogEndVar;
    float wet = g_wxCur[0] + g_wxCur[3] * 0.6f;
    if (wet > 1) wet = 1;
    float fd = g_wxCur[2] * 0.0007f + g_wxCur[1] * 0.00014f + wet * 0.00006f;  // same density the old pass used
    bool ours = g_fogOver && *on == g_ourFogOn && *color == g_ourFogColor && *start == g_ourFogStart && *end == g_ourFogEnd;
    if (fd > 0.00002f) {
        if (!ours) {  // first time, or the game set new fog (time of day / level): remember the game's
            g_gameFogOn = *on; g_gameFogColor = *color; g_gameFogStart = *start; g_gameFogEnd = *end;
        }
        float e = 3.0f / fd;  // about 95% fogged at e
        if (e < 600) e = 600;
        if (e > 60000) e = 60000;
        if (g_gameFogOn && g_gameFogEnd > 0 && g_gameFogEnd < e) e = g_gameFogEnd;  // never clearer than the level's own fog
        float st = e * 0.05f;
        auto ch = [](float v) { int i = (int)(v * 255.0f + 0.5f); return (DWORD)(i < 0 ? 0 : i > 255 ? 255 : i); };
        DWORD col = 0xFF000000 | (ch(g_wx[2][0]) << 16) | (ch(g_wx[2][1]) << 8) | ch(g_wx[2][2]);
        *on = 1; *color = col; *start = st; *end = e;
        g_ourFogOn = 1; g_ourFogColor = col; g_ourFogStart = st; g_ourFogEnd = e;
        FogStates(dev, 1, col, st, e);
        if (!g_fogOver) mmenu::Log("gfx: weather fog on the game's fog (end %.0f)", e);
        g_fogOver = true;
    } else if (g_fogOver) {
        if (ours) {  // put the level's fog back (unless the game already set its own since)
            *on = g_gameFogOn; *color = g_gameFogColor; *start = g_gameFogStart; *end = g_gameFogEnd;
        }
        FogStates(dev, *on, *color, *start, *end);
        g_fogOver = false;
    }
}

static void EndFrame(IDirect3DDevice9* dev) {
    if (++g_presents == 1) mmenu::Log("gfx: first frame presented");
    if (!g_sceneDone) {  // nothing 2D was drawn this frame
        dev->BeginScene();
        RunScene(dev, true);
        dev->EndScene();
    }
    RunScreen(dev);
    CheckKeysAndIni();
    UpdateWorld();
    ApplyWeatherFog(dev);
    CardCheck(dev);
    if (g_origRS) { PixelFogStates(dev); TodFogStates(dev); }
    g_fwDone = false;
    g_intzUsed = false;
    UpdateDepthBinding(dev);
    g_sceneDone = false;
    if (MirrorOn() && g_origRS) g_origRS(dev, D3DRS_CULLMODE, SwapCull(g_cullWant));  // next frame's 3D is mirrored again
    g_galaxyDone = false;
    g_skyGraded = false;
    g_skyPass = false;
}

// The game only starts its device reset (main loop 0x44EEF0: TestCooperativeLevel, then Reset with 0x786A7C)
// when its "device lost" flag 0x786AB4 is set, and only WM_ACTIVATE (inactive) sets it. padhub keeps the
// window running unfocused by skipping that handler, so a device really lost (monitor asleep, display
// change) was never reset: the window stayed black while the server ran (Noah 2026-10-21). Set the flag
// ourselves whenever Present reports the device lost.
static void NoteDeviceLost(HRESULT hr) {
    if (hr != D3DERR_DEVICELOST && hr != D3DERR_DEVICENOTRESET) return;
    if (!*(volatile BYTE*)0x786AB4) mmenu::Log("gfx: device lost (0x%08lX), asking the game to reset it", hr);
    *(volatile BYTE*)0x786AB4 = 1;
}
static HRESULT STDMETHODCALLTYPE HookPresent(IDirect3DDevice9* dev, const RECT* a, const RECT* b, HWND w, const RGNDATA* r) {
    if (!g_inPost) EndFrame(dev);
    HRESULT hr = g_origPresent(dev, a, b, w, r);
    NoteDeviceLost(hr);
    return hr;
}

static HRESULT STDMETHODCALLTYPE HookSCPresent(IDirect3DSwapChain9* sc, const RECT* a, const RECT* b, HWND w, const RGNDATA* r, DWORD f) {
    IDirect3DDevice9* dev = nullptr;
    if (!g_inPost && SUCCEEDED(sc->GetDevice(&dev)) && dev) {
        EndFrame(dev);
        dev->Release();
    }
    HRESULT hr = g_origSCPresent(sc, a, b, w, r, f);
    NoteDeviceLost(hr);
    return hr;
}

static HRESULT STDMETHODCALLTYPE HookST(IDirect3DDevice9* dev, D3DTRANSFORMSTATETYPE t, const D3DMATRIX* m) {
    if (!g_inPost && m) {
        if (t == D3DTS_VIEW) g_view = *m;
        if (t == D3DTS_PROJECTION) {
            bool sky = fabsf(m->_43) < 0.001f && m->_34 < -0.5f;
            if (sky && GalaxyOn() && !g_galaxyDone) { g_origST(dev, t, m); DrawGalaxy(dev); }
            if (!sky && g_skyPass && !g_skyGraded && !GalaxyOn() && SkyWanted()) SkyGrade(dev);
            if (!sky && g_skyPass && !g_fwDone && FireworksLive() && (g_msaaOn || g_intzFail)) DrawFireworks(dev);
            g_skyPass = sky;
            if (!sky && m->_34 < -0.5f) { g_proj = *m; g_haveProj = true; }
            bool flat = fabsf(m->_34) < 0.5f;  // orthographic: screen overlays such as the balance meter
            if (flat && MirrorOn() && !g_sceneDone) {
                static int n = 0;
                if (n < 3) { ++n; mmenu::Log("gfx: mirror leaves a flat (orthographic) overlay unmirrored"); }
            }
            if (!flat && MirrorOn() && !g_sceneDone) {
                D3DMATRIX mm = *m;
                mm._11 = -mm._11; mm._21 = -mm._21; mm._31 = -mm._31; mm._41 = -mm._41;
                // depth effects (street lamps, fog, weather, depth of field) project with the mirrored camera too
                if (m->_34 < -0.5f && fabsf(m->_43) >= 0.001f) g_proj = mm;
                return g_origST(dev, t, &mm);
            }
        }
    }
    return g_origST(dev, t, m);
}

static bool MirrorOn() { return V("gfx_mirror") != 0 && !g_mainMenu; }
static DWORD SwapCull(DWORD c) { return c == D3DCULL_CW ? D3DCULL_CCW : c == D3DCULL_CCW ? D3DCULL_CW : c; }
static HRESULT STDMETHODCALLTYPE HookRS(IDirect3DDevice9* dev, D3DRENDERSTATETYPE st, DWORD v) {
    if (st == D3DRS_CULLMODE && !g_inPost) {
        g_cullWant = v;
        if (MirrorOn() && !g_sceneDone) v = SwapCull(v);
    }
    if (g_todFogOff && !g_inPost && st == D3DRS_FOGENABLE) v = FALSE;  // Fog row off with our time of day
    if (g_pixFogSet && !g_inPost) {  // the game asks for vertex fog: keep it per pixel while ours is on
        if (st == D3DRS_FOGVERTEXMODE) v = D3DFOG_NONE;
        else if (st == D3DRS_FOGTABLEMODE) v = D3DFOG_LINEAR;
    }
    return g_origRS(dev, st, v);
}

static bool ScreenSpaceDraw(IDirect3DDevice9* dev);
static HRESULT STDMETHODCALLTYPE HookDIP(IDirect3DDevice9* dev, D3DPRIMITIVETYPE t, INT b, UINT mi, UINT nv, UINT si, UINT pc) {
    if (g_skyPass && !g_inPost && GalaxyOn()) return D3D_OK;  // the galaxy replaces the game's sky
    if (!g_inPost && !g_sceneDone && ScreenSpaceDraw(dev)) RunScene(dev);
    return g_origDIP(dev, t, b, mi, nv, si, pc);
}

static HRESULT STDMETHODCALLTYPE HookDP(IDirect3DDevice9* dev, D3DPRIMITIVETYPE t, UINT sv, UINT pc) {
    if (g_skyPass && !g_inPost && GalaxyOn()) return D3D_OK;
    if (!g_inPost && !g_sceneDone && ScreenSpaceDraw(dev)) RunScene(dev);
    return g_origDP(dev, t, sv, pc);
}

// true if the next draw uses screen-space (pre-transformed) vertices: HUD, menus, text
static bool ScreenSpaceDraw(IDirect3DDevice9* dev) {
    DWORD fvf = 0;
    if (SUCCEEDED(dev->GetFVF(&fvf)) && fvf) return (fvf & D3DFVF_POSITION_MASK) == D3DFVF_XYZRHW;
    IDirect3DVertexDeclaration9* decl = nullptr;
    if (FAILED(dev->GetVertexDeclaration(&decl)) || !decl) return false;
    D3DVERTEXELEMENT9 el[MAXD3DDECLLENGTH];
    UINT n = MAXD3DDECLLENGTH;
    bool screen = false;
    if (SUCCEEDED(decl->GetDeclaration(el, &n)))
        for (UINT i = 0; i < n && el[i].Stream != 0xFF; ++i) if (el[i].Usage == D3DDECLUSAGE_POSITIONT) screen = true;
    decl->Release();
    return screen;
}

static HRESULT STDMETHODCALLTYPE HookDPUP(IDirect3DDevice9* dev, D3DPRIMITIVETYPE t, UINT n, const void* v, UINT st) {
    if (g_skyPass && !g_inPost && GalaxyOn()) return D3D_OK;
    // Noah 2026-10-20 (mirror mode showed unflipped bits): the game also draws 3D effects (shadows,
    // particles, trails) with DrawPrimitiveUP, so only a screen-space draw ends the 3D scene.
    if (!g_inPost && !g_sceneDone && ScreenSpaceDraw(dev)) RunScene(dev);
    return g_origDPUP(dev, t, n, v, st);
}

static HRESULT STDMETHODCALLTYPE HookFVF(IDirect3DDevice9* dev, DWORD f) {
    // screen-space (pre-transformed) vertices: the HUD and menus are starting, the 3D scene is finished
    if (!g_inPost && (f & D3DFVF_POSITION_MASK) == D3DFVF_XYZRHW) {

        if (!g_sceneDone) RunScene(dev);
    }
    return g_origFVF(dev, f);
}

static IDirect3DSurface9* MakeIntz(IDirect3DDevice9* dev) {
    if (g_intzSurf) return g_intzSurf;
    if (g_intzFail || !g_autoDS) return nullptr;
    CardCheck(dev);
    if (!g_cardIntz) {  // the card has no readable depth format (or a weak-card test): depth effects stay off
        g_intzFail = true;
        mmenu::Log("gfx: readable depth (INTZ) not supported by this card, depth effects off");
        return nullptr;
    }
    D3DSURFACE_DESC d;
    g_autoDS->GetDesc(&d);
    const D3DFORMAT kIntz = (D3DFORMAT)MAKEFOURCC('I', 'N', 'T', 'Z');
    if (FAILED(dev->CreateTexture(d.Width, d.Height, 1, D3DUSAGE_DEPTHSTENCIL, kIntz, D3DPOOL_DEFAULT, &g_intz, nullptr)) ||
        FAILED(g_intz->GetSurfaceLevel(0, &g_intzSurf))) {
        if (g_intz) { g_intz->Release(); g_intz = nullptr; }
        g_intzFail = true;
        mmenu::Log("gfx: readable depth (INTZ) not available, depth effects off");
        return nullptr;
    }
    mmenu::Log("gfx: readable depth on (%ux%u)", d.Width, d.Height);
    return g_intzSurf;
}

static HRESULT STDMETHODCALLTYPE HookDS(IDirect3DDevice9* dev, IDirect3DSurface9* s) {
    if (!g_inPost && s) {
        if (!g_autoDS) {  // the first depth buffer the game binds is its main one
            D3DSURFACE_DESC d;
            s->GetDesc(&d);
            IDirect3DSurface9* bb = nullptr;
            D3DSURFACE_DESC bd = {};
            if (SUCCEEDED(dev->GetBackBuffer(0, 0, D3DBACKBUFFER_TYPE_MONO, &bb)) && bb) { bb->GetDesc(&bd); bb->Release(); }
            if (d.Width == bd.Width && d.Height == bd.Height) { g_autoDS = s; s->AddRef(); }
        }
        bool want = DepthWanted() && !g_msaaOn && !g_intzFail;
        if (want && s == g_autoDS) {
            MakeIntz(dev);
            if (g_intzSurf) { g_intzBound = true; g_intzUsed = true; return g_origDS(dev, g_intzSurf); }
        }
        g_intzBound = false;
    }
    return g_origDS(dev, s);
}

static HRESULT STDMETHODCALLTYPE HookReset(IDirect3DDevice9* dev, D3DPRESENT_PARAMETERS* pp) {
    if (g_autoDS && g_intzBound) g_origDS(dev, g_autoDS);  // our depth texture must not be bound across a reset
    FreeTargets();
    if (pp) AdjustPP(g_d3d, g_adapter, g_devType, pp);
    HRESULT hr = g_origReset(dev, pp);
    // the game retries a failed reset every frame (device lost after the monitor sleeps): log the first
    // failure and every 600th, and the recovery
    static int s_fails = 0;
    if (FAILED(hr)) { if (s_fails++ % 600 == 0) mmenu::Log("gfx: device reset failed (0x%08lX), try %d", hr, s_fails); }
    else { if (s_fails) mmenu::Log("gfx: device reset ok after %d failed tries", s_fails); else mmenu::Log("gfx: device reset ok"); s_fails = 0; }
    if (SUCCEEDED(hr) && pp) {
        g_msaaOn = pp->MultiSampleType != D3DMULTISAMPLE_NONE;
        dev->GetDepthStencilSurface(&g_autoDS);
    }
    return hr;
}

// the game's own device: patch its vtable (it differs from a probe device's) and its swap chain
static IDirect3DDevice9* g_gameDev = nullptr;
static void PatchDevice(IDirect3DDevice9* dev) {
    g_gameDev = dev;
    void** vt = *(void***)dev;
    Patch(vt, 69, (void*)&HookSSS, (void**)&g_origSSS);
    Patch(vt, 17, (void*)&HookPresent, (void**)&g_origPresent);
    Patch(vt, 16, (void*)&HookReset, (void**)&g_origReset);
    Patch(vt, 44, (void*)&HookST, (void**)&g_origST);
    Patch(vt, 82, (void*)&HookDIP, (void**)&g_origDIP);
    Patch(vt, 83, (void*)&HookDPUP, (void**)&g_origDPUP);
    Patch(vt, 39, (void*)&HookDS, (void**)&g_origDS);
    Patch(vt, 89, (void*)&HookFVF, (void**)&g_origFVF);
    Patch(vt, 81, (void*)&HookDP, (void**)&g_origDP);
    Patch(vt, 57, (void*)&HookRS, (void**)&g_origRS);
    if (!g_autoDS) dev->GetDepthStencilSurface(&g_autoDS);  // the game's main depth buffer
    IDirect3DSwapChain9* sc = nullptr;
    if (SUCCEEDED(dev->GetSwapChain(0, &sc)) && sc) {
        Patch(*(void***)sc, 3, (void*)&HookSCPresent, (void**)&g_origSCPresent);
        sc->Release();
    }
}

// ReShade 4.2.1 tested 2026-11-19 (a friend's install: d3d11.asi through an ASI loader, dinput8.dll): ReShade wraps
// the device dadmod patched, and while ReShade sets itself up Direct3D rebuilds that device's function table (it is
// per device, in the heap), which wipes every hook above about 3 seconds after creation. Present never reached
// dadmod again, so no effects, FPS counter, screenshots or ReShade row bypass. Patching again later sticks, so
// once a frame (game thread, from the controller read) the hooks are checked and put back if something undid them.
static int SafeHooksGone(IDirect3DDevice9* dev) {
    __try {
        void** vt = *(void***)dev;
        return vt[17] != (void*)&HookPresent || vt[82] != (void*)&HookDIP || vt[16] != (void*)&HookReset;
    } __except (EXCEPTION_EXECUTE_HANDLER) { return -1; }
}
// 2026-11-19 (player shibe: colors, sky and weather did nothing): on some starts the game makes its device before our
// IDirect3D9::CreateDevice hook is in (a race, seen on plain THUG Pro and on Kali), so HookCreate never runs and no
// device hook goes in for the whole session. The game keeps its device in 0x7D69E0 (the main loop 0x44EEF0 calls
// TestCooperativeLevel / Reset on it), so when no device came through HookCreate it is picked up from there and patched.
static const DWORD kGameDevicePtr = 0x7D69E0;
static IDirect3DDevice9* SafeGameDevice() {
    __try { return *(IDirect3DDevice9* volatile*)kGameDevicePtr; } __except (EXCEPTION_EXECUTE_HANDLER) { return nullptr; }
}
static void AdoptGameDevice() {
    IDirect3DDevice9* dev = SafeGameDevice();
    if (!dev) return;
    IDirect3D9* d3d = nullptr;
    if (FAILED(dev->GetDirect3D(&d3d)) || !d3d) return;
    D3DDEVICE_CREATION_PARAMETERS cp = {};
    dev->GetCreationParameters(&cp);
    g_d3d = d3d; g_adapter = cp.AdapterOrdinal; g_devType = cp.DeviceType;
    if (!g_devWnd) g_devWnd = cp.hFocusWindow;
    d3d->Release();   // the device keeps its own reference to it
    PatchDevice(dev);
    mmenu::Log("gfx: device picked up from the game (CreateDevice hook was bypassed), hooks in");
}
static void KeepDeviceHooks() {
    IDirect3DDevice9* dev = g_gameDev;
    if (!dev) { AdoptGameDevice(); return; }
    int gone = SafeHooksGone(dev);
    if (gone < 0) { g_gameDev = nullptr; return; }
    if (!gone) return;
    static int n = 0;
    if (n < 5) { ++n; mmenu::Log("gfx: device hooks were undone (%d frames presented so far), put back", (int)g_presents); }
    PatchDevice(dev);
}

// ReShade's own effects follow the Graphics effects row (Noah 2026-11-19, part 4 of the ReShade row). Works with every
// ReShade version that has an effects key in ReShade.ini [INPUT] KeyEffects, with no ReShade add-on: ReShade reads its
// keys from the game window's messages, so posting that key's down/up to the device window flips its effects, without
// focus and without the game seeing a key (THUG Pro reads the keyboard through DirectInput). Tested with ReShade 4.2.1.
// ReShade can't be asked whether its effects are on, so dadmod counts: they are on when ReShade starts, every key dadmod
// posts flips them, and so does the player pressing the key in the game window. Nothing is sent until the player has used
// the row once (gfx_postfxset), so updating dadmod leaves a ReShade player's setup as it was.
static bool g_rsFxOn = true;
static DWORD g_rsSince = 0;
static void PostReShadeKey(const ReShadeFound& r) {
    HWND w = g_devWnd;
    if (!w || !IsWindow(w)) return;
    auto post = [w](UINT msg, int vk, bool up) {
        UINT sc = MapVirtualKeyA((UINT)vk, 0);
        LPARAM lp = 1 | (LPARAM)(sc << 16);
        if ((vk >= VK_PRIOR && vk <= VK_DOWN) || vk == VK_INSERT || vk == VK_DELETE || vk == VK_DIVIDE || vk == VK_NUMLOCK) lp |= 1 << 24;
        if (up) lp |= 0xC0000000;
        PostMessageA(w, msg, (WPARAM)vk, lp);
    };
    if (r.ctrl) post(WM_KEYDOWN, VK_CONTROL, false);
    if (r.shift) post(WM_KEYDOWN, VK_SHIFT, false);
    if (r.alt) post(WM_SYSKEYDOWN, VK_MENU, false);
    post(r.alt ? WM_SYSKEYDOWN : WM_KEYDOWN, r.vk, false);
    post(r.alt ? WM_SYSKEYUP : WM_KEYUP, r.vk, true);
    if (r.alt) post(WM_SYSKEYUP, VK_MENU, true);
    if (r.shift) post(WM_KEYUP, VK_SHIFT, true);
    if (r.ctrl) post(WM_KEYUP, VK_CONTROL, true);
}
static void SyncReShadeEffects() {
    static bool checked = false;
    if (!checked) {   // once, on the game thread after the device exists (ReShade loads before the device is made)
        if (!g_gameDev) return;
        checked = true;
        g_reshadeLoaded = DetectReShade().found;
        InterlockedExchange(&g_dirtyPost, 1);
    }
    if (!g_reshadeLoaded) return;
    const ReShadeFound& r = g_reshade;
    if (!r.vk) return;
    // the player's own presses of ReShade's key (game window in front) flip ReShade's effects too
    static bool wasDown = false;
    DWORD pid = 0;
    HWND fg = GetForegroundWindow();
    if (fg) GetWindowThreadProcessId(fg, &pid);
    bool down = pid == GetCurrentProcessId() && (GetAsyncKeyState(r.vk) & 0x8000) != 0 &&
                ((GetAsyncKeyState(VK_CONTROL) & 0x8000) != 0) == (r.ctrl != 0) &&
                ((GetAsyncKeyState(VK_SHIFT) & 0x8000) != 0) == (r.shift != 0) &&
                ((GetAsyncKeyState(VK_MENU) & 0x8000) != 0) == (r.alt != 0);
    if (down && !wasDown) { g_rsFxOn = !g_rsFxOn; mmenu::Log("gfx: ReShade effects key pressed: ReShade effects now %s", g_rsFxOn ? "on" : "off"); }
    wasDown = down;
    int setI = Index("gfx_postfxset"), fxI = Index("gfx_postfx");
    if (setI < 0 || fxI < 0 || !g_val[setI]) return;
    bool want = g_val[fxI] != 0;
    if (want == g_rsFxOn) { g_rsSince = 0; return; }
    // ReShade needs to be up and drawing first: 3 seconds after the first frames at boot, then at most one key a second
    DWORD now = GetTickCount();
    if (g_presents < 60) return;
    if (!g_rsSince) { g_rsSince = now ? now : 1; if (g_presents < 600) return; }
    if (g_presents < 600 && now - g_rsSince < 3000) return;
    static DWORD last = 0;
    if (last && now - last < 1000) return;
    last = now ? now : 1;
    PostReShadeKey(r);
    g_rsFxOn = want;
    g_rsSince = 0;
    mmenu::Log("gfx: sent ReShade's effects key (%s): ReShade effects %s", r.key, want ? "on" : "off");
}

// Client build (Install(.., oneProbe = true), 2026-11-19): this thread goes through ProbeD3D9 too, so only one of
// our probe Direct3Ds is ever made. A player's game crashed inside d3d9 while this thread and the main thread's
// ProbeD3D9 each created one at the same moment. (Waiting for the main-thread probe alone is not enough: d3d9 often
// comes in through thugpro.dll's d3dx9_43.dll, whose LoadLibrary calls are not hooked, and then no probe ran.)
static volatile LONG g_probed = 0;
static bool g_oneProbe = false;
static void ProbeD3D9();
static DWORD WINAPI PatchThread(LPVOID) {
    if (g_oneProbe) {
        if (!LoadLibraryA("d3d9.dll")) return 0;
        ProbeD3D9();
        mmenu::Log("gfx: hooks in (anisotropic %d, msaa %d, galaxy %d)", V("gfx_aniso"), V("gfx_msaa"), V("gfx_galaxy"));
        return 0;
    }
    typedef IDirect3D9*(WINAPI* Create_t)(UINT);
    HMODULE d3d = LoadLibraryA("d3d9.dll");
    Create_t create = d3d ? (Create_t)GetProcAddress(d3d, "Direct3DCreate9") : nullptr;
    if (!create) return 0;
    IDirect3D9* d = create(D3D_SDK_VERSION);
    if (!d) return 0;
    Patch(*(void***)d, 16, (void*)&HookCreate, (void**)&g_origCreate);  // IDirect3D9::CreateDevice
    d->Release();
    mmenu::Log("gfx: hooks in (anisotropic %d, msaa %d, galaxy %d)", V("gfx_aniso"), V("gfx_msaa"), V("gfx_galaxy"));
    return 0;
}

// ---- mirror mode steering -------------------------------------------------------------------------
// The device read (0x5BD4E8) calls ReadControls (0x5F5BC0, cdecl (player + 1, block)), which merges the
// keyboard and the pad of one player into a control block: +4 WORD d-pad/buttons (1 up, 2 down, 4 left,
// 8 right), +0x0E left stick X, +0x10 left Y, +0x12 right stick X, +0x14 right Y (shorts). With mirror
// mode on and no menu open, both sticks' X and d-pad left/right are swapped before the engine uses them.
static const DWORD kReadControls = 0x5F5BC0, kReadControlsCall = 0x5BD4E8;
typedef int(__cdecl* ReadControls_t)(int, BYTE*);
static short Neg(short v) { return v == -32768 ? 32767 : (short)-v; }
static int __cdecl ReadControlsHook(int player, BYTE* out) {
    int r = ((ReadControls_t)kReadControls)(player, out);
    padhub::CaptureTick();  // Controls > bindings: press-to-bind
    if (player <= 1) KeepDeviceHooks();   // ReShade: its setup undoes the device hooks
    if (player <= 1) SyncReShadeEffects();   // ReShade's own effects follow the Graphics effects row
    // ReadControls gets player + 1, so the first local player is 1 here (it was "== 0" before, which never ran)
    if (player <= 1) padhub::DeviceTick();  // button prompts follow the device used last
    if (player <= 1) skin::Tick();          // live skater looks online (skinsync.inc)
    if (out && padhub::BindBlocking()) { memset(out + 4, 0, 0x12); return r; }  // the press only sets the binding
    static bool logged = false;
    if (!logged) { logged = true; mmenu::Log("gfx: controller read hooked (player %d)", player); }
    // On a rail or lip, left/right balances, so it stays as is. Only around a jump does the direction pick where you
    // ollie off, so it is swapped like everywhere else for 8 reads after jump (+6, cross) goes down or comes up.
    // Noah 2026-10-26 (mirror grinds still balanced backwards sometimes): this used to swap while any face button
    // (+6..+9) was held and 20 reads after, so the grind button pressed to get on the rail, grind taps and switches
    // (triangle/square/circle), or jump held to crouch for the ollie off all flipped the balance the wrong way.
    static int jumpHold = 0;
    static bool jumpWas = false;
    if (out) {
        bool jump = out[6] != 0;
        if (jump != jumpWas) jumpHold = 8; else if (jumpHold > 0) --jumpHold;
        jumpWas = jump;
    }
    bool balanceOnly = g_balancing && jumpHold == 0;
    g_trickSwap = out && MirrorOn() && !g_menuUp && !balanceOnly;
    // Shoulder buttons (+0x0A..+0x0D) are never touched: the player's bindings stay. Shoulder spins are mirrored
    // by swapping THUG Pro's spin_button_left/right physics params instead (QB dadmod_mirror_spin).
    if (out && MirrorOn() && !g_menuUp && !balanceOnly) {
        *(short*)(out + 0x0E) = Neg(*(short*)(out + 0x0E));
        *(short*)(out + 0x12) = Neg(*(short*)(out + 0x12));
        WORD b = *(WORD*)(out + 4);
        *(WORD*)(out + 4) = (WORD)((b & ~12) | (b & 4 ? 8 : 0) | (b & 8 ? 4 : 0));
    }
    return r;
}
// Tricks: the trick system records each button press under its name (0x51F958 calls GetButtonChecksum(index),
// 0x44E590) and checks Held by name (GetButtonIndex(checksum), 0x44E5A0, from 0x51ECF8 and 0x52435B). While the
// steering is swapped, left/right names are swapped back there, so trick inputs (and specials) use the real
// direction pressed. Up/down are never touched. Index 3 left, 4 right, 5 upleft, 6 upright, 7 downleft, 8 downright.
static int MirrorIdx(int i) {
    if (!g_trickSwap) return i;
    switch (i) { case 3: return 4; case 4: return 3; case 5: return 6; case 6: return 5; case 7: return 8; case 8: return 7; }
    return i;
}
static DWORD __cdecl TrickButtonChecksum(int idx) { return ((DWORD(__cdecl*)(int))0x44E590)(MirrorIdx(idx)); }
static int __cdecl TrickButtonIndex(DWORD checksum) { return MirrorIdx(((int(__cdecl*)(DWORD))0x44E5A0)(checksum)); }
static void PatchCall(DWORD site, DWORD expect, void* fn, const char* what) {
    BYTE* p = (BYTE*)site;
    if (p[0] != 0xE8 || (DWORD)(site + 5 + *(int*)(p + 1)) != expect) { mmenu::Log("gfx: %s call not found", what); return; }
    DWORD old;
    VirtualProtect(p, 5, PAGE_EXECUTE_READWRITE, &old);
    *(int*)(p + 1) = (int)((DWORD)fn - (site + 5));
    VirtualProtect(p, 5, old, &old);
    FlushInstructionCache(GetCurrentProcess(), p, 5);
}
static void InstallMirrorInput() {
    PatchCall(0x51F958, 0x44E590, (void*)&TrickButtonChecksum, "trick button record");
    PatchCall(0x51ECF8, 0x44E5A0, (void*)&TrickButtonIndex, "trick held");
    PatchCall(0x52435B, 0x44E5A0, (void*)&TrickButtonIndex, "trick held list");
    BYTE* site = (BYTE*)kReadControlsCall;
    if (site[0] != 0xE8 || (DWORD)(kReadControlsCall + 5 + *(int*)(site + 1)) != kReadControls) {
        mmenu::Log("gfx: controller read call not found, mirror steering off");
        return;
    }
    DWORD old;
    VirtualProtect(site, 5, PAGE_EXECUTE_READWRITE, &old);
    *(int*)(site + 1) = (int)((DWORD)&ReadControlsHook - (kReadControlsCall + 5));
    VirtualProtect(site, 5, old, &old);
    FlushInstructionCache(GetCurrentProcess(), site, 5);
}

// Noah 2026-10-21 (Dev: mirror mode and every effect missing in one run): PatchThread races the game, which
// can create its device before the thread has hooked IDirect3D9::CreateDevice. The game gets Direct3DCreate9
// through GetProcAddress, so that call is hooked in the modules' import tables right away (plain memory
// writes, safe at load time): the IDirect3D9 the game gets is patched before it can create a device.
typedef IDirect3D9*(WINAPI* Create9_t)(UINT);
// As soon as d3d9.dll is loaded (and before the LoadLibrary that loaded it returns, so before anyone can
// create a device), hook IDirect3D9::CreateDevice with the same probe PatchThread uses.
static void ProbeD3D9() {
    HMODULE d3d = GetModuleHandleA("d3d9.dll");
    if (!d3d || g_probed || InterlockedExchange(&g_probed, 1)) return;
    Create9_t create = (Create9_t)GetProcAddress(d3d, "Direct3DCreate9");
    IDirect3D9* d = create ? create(D3D_SDK_VERSION) : nullptr;
    if (!d) return;
    Patch(*(void***)d, 16, (void*)&HookCreate, (void**)&g_origCreate);
    d->Release();
    mmenu::Log("gfx: Direct3D hooked as soon as it loaded");
}
static void HookImport(HMODULE mod, const char* dll, void* real, void* hook) {
    if (!mod) return;
    BYTE* base = (BYTE*)mod;
    IMAGE_NT_HEADERS* nt = (IMAGE_NT_HEADERS*)(base + ((IMAGE_DOS_HEADER*)base)->e_lfanew);
    IMAGE_DATA_DIRECTORY dir = nt->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT];
    if (!dir.VirtualAddress) return;
    for (IMAGE_IMPORT_DESCRIPTOR* d = (IMAGE_IMPORT_DESCRIPTOR*)(base + dir.VirtualAddress); d->Name; ++d) {
        if (_stricmp((const char*)(base + d->Name), dll)) continue;
        for (IMAGE_THUNK_DATA* t = (IMAGE_THUNK_DATA*)(base + d->FirstThunk); t->u1.Function; ++t) {
            if ((void*)t->u1.Function != real) continue;
            DWORD old;
            if (VirtualProtect(&t->u1.Function, sizeof(void*), PAGE_READWRITE, &old)) {
                t->u1.Function = (ULONG_PTR)hook;
                VirtualProtect(&t->u1.Function, sizeof(void*), old, &old);
            }
        }
    }
}
static HMODULE(WINAPI* g_realLoadA)(LPCSTR) = nullptr;
static HMODULE(WINAPI* g_realLoadW)(LPCWSTR) = nullptr;
static HMODULE(WINAPI* g_realLoadExA)(LPCSTR, HANDLE, DWORD) = nullptr;
static HMODULE(WINAPI* g_realLoadExW)(LPCWSTR, HANDLE, DWORD) = nullptr;
static HMODULE WINAPI HookLoadA(LPCSTR n) { HMODULE m = g_realLoadA(n); if (m && !g_probed) ProbeD3D9(); return m; }
static HMODULE WINAPI HookLoadW(LPCWSTR n) { HMODULE m = g_realLoadW(n); if (m && !g_probed) ProbeD3D9(); return m; }
static HMODULE WINAPI HookLoadExA(LPCSTR n, HANDLE f, DWORD fl) { HMODULE m = g_realLoadExA(n, f, fl); if (m && !g_probed) ProbeD3D9(); return m; }
static HMODULE WINAPI HookLoadExW(LPCWSTR n, HANDLE f, DWORD fl) { HMODULE m = g_realLoadExW(n, f, fl); if (m && !g_probed) ProbeD3D9(); return m; }
// the game exe and THUG Pro's loader DLLs that are already in (never thugpro.dll: it checks its own imports)
static void InstallCreateHook() {
    HMODULE k32 = GetModuleHandleA("kernel32.dll");
    g_realLoadA = (HMODULE(WINAPI*)(LPCSTR))GetProcAddress(k32, "LoadLibraryA");
    g_realLoadW = (HMODULE(WINAPI*)(LPCWSTR))GetProcAddress(k32, "LoadLibraryW");
    g_realLoadExA = (HMODULE(WINAPI*)(LPCSTR, HANDLE, DWORD))GetProcAddress(k32, "LoadLibraryExA");
    g_realLoadExW = (HMODULE(WINAPI*)(LPCWSTR, HANDLE, DWORD))GetProcAddress(k32, "LoadLibraryExW");
    if (!g_realLoadA || !g_realLoadW || !g_realLoadExA || !g_realLoadExW) return;
    HMODULE mods[] = { GetModuleHandleA(nullptr), GetModuleHandleA("updt.dll"), GetModuleHandleA("binkw32_orig.dll") };
    for (HMODULE m : mods) {
        HookImport(m, "KERNEL32.dll", (void*)g_realLoadA, (void*)&HookLoadA);
        HookImport(m, "KERNEL32.dll", (void*)g_realLoadW, (void*)&HookLoadW);
        HookImport(m, "KERNEL32.dll", (void*)g_realLoadExA, (void*)&HookLoadExA);
        HookImport(m, "KERNEL32.dll", (void*)g_realLoadExW, (void*)&HookLoadExW);
    }
}

// d3dHooks = false: no Direct3D hooks at all (client safe start, loader.cpp); oneProbe: see PatchThread.
// The server build calls Install() and keeps both probes as before.
static void Install(bool d3dHooks = true, bool oneProbe = false) {
    Load();
    InstallMirrorInput();
    InstallLevelSoundHooks();
    if (!d3dHooks) { mmenu::Log("gfx: safe start, Direct3D hooks off (graphics settings do nothing)"); return; }
    g_oneProbe = oneProbe;
    InstallCreateHook();
    CloseHandle(CreateThread(nullptr, 0, PatchThread, nullptr, 0, nullptr));
}

}  // namespace gfx
