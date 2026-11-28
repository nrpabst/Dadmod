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
#include <algorithm>
namespace gfx {

// ---- settings -----------------------------------------------------------------------------------
struct Setting { const char* key; int def, lo, hi; const char* help; };
static const Setting kSettings[] = {
    {"gfx_aniso", 4, 0, 4, "anisotropic filtering: 0 off, 1 2x, 2 4x, 3 8x, 4 16x"},
    {"gfx_lodbias", 0, 0, 4, "texture sharpness (mip LOD bias): 0 normal .. 4 sharpest (may shimmer)"},
    {"gfx_uismooth", 0, 0, 1, "smooth scaled menu/HUD graphics: 0 off, 1 on"},
    {"gfx_msaa", 0, 0, 3, "MSAA anti-aliasing (restart): 0 off, 1 2x, 2 4x, 3 8x"},
    {"gfx_vsync", 0, 0, 2, "v-sync (Display > Apply): 0 game default, 1 on, 2 off"},
    {"gfx_framegen", 0, 0, 6, "frame generation (in-between frames; the game itself still runs at 60; framegen.inc): 0 off, 1 auto (your monitor), 2 120 Hz, 3 144 Hz, 4 165 Hz, 5 180 Hz, 6 240 Hz"},
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
    {"gfx_tod", 0, 0, 6, "time of day: 0 level default, 1 morning, 2 day, 3 evening, 4 night, 5 evening with the lights on, 6 dawn (sun coming up, lights still on)"},
    {"gfx_daylen", 2, 0, 4, "unused since 2026-11-21 (the Dynamic time of day was removed); kept so old files load"},
    {"gfx_weather", 0, 0, 5, "weather: 0 off, 1 rain, 2 thunderstorm, 3 snow, 4 fog, 5 random (clear, rain, storm, snow or fog, changes every few minutes)"},
    {"gfx_wxnow", 0, 0, 4, "the weather shown right now (set by the game; Random picks it): 0 clear, 1 rain, 2 storm, 3 snow, 4 fog"},
    {"gfx_wxsrv", 0, 0, 4, "weather the server runs (set by the game from a server ?rain etc; wins over the Weather row): 0 none, 1 rain, 2 storm, 3 snow, 4 blizzard"},
    {"gfx_wxclear", 1, 0, 1, "unused since 2026-11-21 (Random weather picks from clear, rain, storm and snow); kept so old files load"},
    {"gfx_wxrain", 1, 0, 1, "unused since 2026-11-21 (Random weather picks from clear, rain, storm and snow); kept so old files load"},
    {"gfx_wxstorm", 1, 0, 1, "unused since 2026-11-21 (Random weather picks from clear, rain, storm and snow); kept so old files load"},
    {"gfx_wxsnow", 1, 0, 1, "unused since 2026-11-21 (Random weather picks from clear, rain, storm and snow); kept so old files load"},
    {"gfx_wxfog", 1, 0, 1, "unused since 2026-11-21 (Random weather picks from clear, rain, storm and snow); kept so old files load"},
    {"gfx_wxamt", 5, 1, 10, "weather intensity: 1 light .. 10 heavy (rain, storm, snow and fog)"},
    {"gfx_todfog", 0, 0, 4, "unused since 2026-11-23 (fog is a Weather choice now); kept so old files load"},
    {"gfx_fogamt", 5, 1, 10, "unused since 2026-11-23 (Intensity covers fog now); kept so old files load"},
    {"gfx_fireworks", 0, 0, 5, "fireworks: 0 off, 1 when someone wins a game, 2-5 on wins and every 1 / 3 / 5 / 10 minutes"},
    {"gfx_fwevery", 2, 0, 3, "unused since 2026-11-21 (Fireworks picks the interval itself); kept so old files load"},
    {"gfx_skywxver", 2, 0, 2, "settings version of the Sky & weather page (old weather / fireworks values were converted once)"},
    {"gfx_lamps", 0, 0, 10, "street lights at night (no menu row since 2026-11-21, off by default): lamps in the level glow and light up around them in the evening and at night: 0 off .. 10 bright"},
    {"gfx_windows", 1, 0, 3, "lit windows at night (mods/lamplights): 1 on, 0 off, 2 = check: marked panes green, 3 = check: hidden window pixels red"},
    {"gfx_windowstr", 10, 0, 20, "lit windows brightness x0.1"},
    {"gfx_windowshare", 3, 0, 10, "lit windows: share of windows lit x10%"},
    {"gfx_windowspill", 0, 0, 20, "lit windows: soft warm light spilling around them x0.1"},
    {"gfx_moonlight", 0, 0, 20, "moonlight: cool light on surfaces facing the moon at night x0.1 (default 0: Noah did not accept it, 2026-11-22)"},
    {"gfx_moonaz", 135, 0, 359, "moonlight: direction the moon light comes from (degrees around)"},
    {"gfx_lampbulbs", 1, 0, 1, "lamp bulbs and pools (mods/lamplights): 1 on, 0 off (for testing)"},
    {"gfx_lamplights", 1, 0, 1, "Lamp lights (Sky & weather, Noah 2026-11-23): our night lamp light (bulbs, pools, the engine lights we add) 1 on, 0 off"},
    {"gfx_lamptiles", 1, 0, 1, "lamp lights drawn by screen tile (speed, 2026-11-23): 1 on, 0 = one pass per lamp as before (for comparing)"},
    {"gfx_lampposts", 1, 0, 1, "Extra lamp posts (Sky & weather, Noah 2026-11-23): the added lamp post models and their light 1 show, 0 hide"},
    {"gfx_bulbsize", 8, 1, 30, "lamp bulb glow size x0.1 (10 = normal)"},
    {"gfx_bulbstr", 7, 0, 30, "lamp bulb glow brightness x0.1 (10 = normal, 0 = no bulbs, pools stay)"},
    {"gfx_lampreach", 1000, 200, 3000, "lamp engine lights (amber wash on the level around each lamp): reach; applied within a second"},
    {"gfx_lamppool", 10, 2, 40, "lamp light pools (mods/lamplights): radius x0.1 (16 = 1.6x the lamp list radius)"},
    {"gfx_lampstr", 10, 0, 60, "lamp light pools: strength x0.1 (lights the ground by its own brightness)"},
    {"gfx_lamplift", 3, 0, 60, "lamp light pools: amber lift x0.01 added even on dark ground"},
    {"gfx_skypop", 0, 0, 10, "sky boost (richer sky colors to match the time of day, stars at night): 0 off .. 10 strong"},
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
static int g_fileVal[kCount];  // multi-instance (2026-11-23): each value as gfx.ini held it when this game last read or wrote it
static bool g_mine[kCount];    // changed in this game since its last save: a save writes these and keeps the file's other values

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

// lamp settings: written together at the end of gfx.ini under their own header (Noah 2026-11-22)
struct LampKeyInfo { const char* key; const char* text; };
static const LampKeyInfo kLampKeys[] = {
    {"gfx_lamplights", "Lamp lights: our street lamp light at night (bulbs, light pools, light on walls): 1 on, 0 off"},
    {"gfx_lampposts", "Extra lamp posts: the lamp posts added to some maps, with their light: 1 show, 0 hide"},
    {"gfx_lampbulbs", "lamp bulbs and light pools at night: 1 on, 0 off"},
    {"gfx_bulbsize", "size of the glow around each bulb: 1 .. 30, 8 = normal"},
    {"gfx_bulbstr", "brightness of the bulb glow: 0 .. 30, 7 = normal, 0 = no bulb glow (the pools stay)"},
    {"gfx_lamppool", "size of the light pool on the ground under each lamp: 2 .. 40, 10 = normal"},
    {"gfx_lampstr", "how much the light pool brightens the ground: 0 .. 60, 10 = normal"},
    {"gfx_lamplift", "amber added to the pool even where the ground is very dark: 0 .. 60, 3 = normal (high looks foggy)"},
    {"gfx_lampreach", "how far each lamp's amber light reaches onto walls and buildings: 200 .. 3000, 1000 = normal"},
    {"gfx_windows", "lit windows at night (warm light in building windows): 1 on, 0 off, 2 = check mode (marked panes green, unmarked blue), 3 = check mode (window pixels hidden behind something show red)"},
    {"gfx_windowstr", "brightness of the lit windows: 0 .. 20, 10 = normal"},
    {"gfx_windowshare", "how many windows are lit: 0 .. 10, 3 = 30%"},
    {"gfx_windowspill", "soft warm light spilling around lit windows (not finished, off): 0 .. 20, 0 = off"},
    {"gfx_moonlight", "moonlight: cool light on walls and ground facing the moon at night: 0 .. 20, 0 = off (default)"},
    {"gfx_moonaz", "direction the moonlight comes from: 0 .. 359 degrees (turn it until the lit sides match the moon)"},
    {"gfx_lamps", "the OLD street light glow from before (its positions are off): 0 off .. 10 bright"},
};
static bool IsLampKey(const char* k) {
    for (const auto& l : kLampKeys) if (!_stricmp(k, l.key)) return true;
    return false;
}
// ---- two games open from one folder (Noah 2026-11-23: "the graphics settings change both instances"; one save file) ----
// Both games share dadmod\gfx.ini and dadmod\panel_settings.txt. Every save a game writes starts with
// "; dadmod game <pid> <hash>" (hash = FNV-1a of the rest of the file). A change with a good stamp came from a game,
// so a running game ignores it and keeps its own values; anything else (THUGPro Manager, a text editor) still applies
// live, but only the values that actually changed. A save writes only what this game changed, so the file always holds
// the latest change from either game and the next launch starts with that.
static unsigned StampHash(const char* p, size_t n) {
    unsigned h = 2166136261u;
    for (size_t i = 0; i < n; ++i) { h ^= (unsigned char)p[i]; h *= 16777619u; }
    return h;
}
static std::string Stamped(const std::string& body) {
    char s[64];
    _snprintf(s, sizeof s, "; dadmod game %lu %08x\r\n", (unsigned long)GetCurrentProcessId(), StampHash(body.data(), body.size()));
    s[sizeof s - 1] = 0;
    return s + body;
}
static bool StampOk(const std::string& data) {
    if (data.compare(0, 14, "; dadmod game ")) return false;
    size_t e = data.find('\n');
    if (e == std::string::npos) return false;
    unsigned long pid = 0; unsigned h = 0;
    if (sscanf(data.c_str() + 14, "%lu %x", &pid, &h) != 2) return false;
    return h == StampHash(data.data() + e + 1, data.size() - e - 1);
}
static std::string StripStamp(const std::string& data) {
    if (data.compare(0, 14, "; dadmod game ")) return data;
    size_t e = data.find('\n');
    return e == std::string::npos ? std::string() : data.substr(e + 1);
}
// the values in a gfx.ini text (has[i] = the file names that setting)
static void ParseVals(const std::string& data, int* v, bool* has, std::string* shot, bool* hasShot) {
    for (int i = 0; i < kCount; ++i) { v[i] = kSettings[i].def; has[i] = false; }
    *hasShot = false;
    size_t s = 0;
    while (s < data.size()) {
        size_t e = data.find_first_of("\r\n", s);
        std::string line = data.substr(s, e == std::string::npos ? std::string::npos : e - s);
        s = e == std::string::npos ? data.size() : e + 1;
        if (!line.compare(0, 11, "gfx_shotdir")) {
            size_t q = line.find('=');
            if (q != std::string::npos) { *shot = mmenu::Trim(line.substr(q + 1)); *hasShot = true; }
            continue;
        }
        size_t c = line.find(';');
        if (c != std::string::npos) line = line.substr(0, c);
        size_t eq = line.find('=');
        if (eq == std::string::npos) continue;
        int i = Index(mmenu::Trim(line.substr(0, eq)).c_str());
        if (i < 0) continue;
        int x = atoi(line.c_str() + eq + 1);
        v[i] = x < kSettings[i].lo ? kSettings[i].lo : x > kSettings[i].hi ? kSettings[i].hi : x;
        has[i] = true;
    }
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
        // one Weather row + one Intensity row (2026-11-23): Random moves from 4 to 5, the old Fog row becomes Weather Fog
        if (rawVer < 2) {
            std::string what;
            int iw = Index("gfx_weather"), ifog = Index("gfx_todfog"), ifa = Index("gfx_fogamt"), ia = Index("gfx_wxamt"), iver = Index("gfx_skywxver");
            if (g_val[iw] == 4) { g_val[iw] = 5; what += " Random 4->5"; }
            else if (g_val[iw] == 0 && g_val[ifog] > 0) { g_val[iw] = 4; g_val[ia] = g_val[ifa]; what += " Fog row -> Weather Fog, Intensity " + std::to_string(g_val[ia]); }
            g_val[ifog] = 0;
            g_val[iver] = 2;
            mmenu::Log("gfx: weather settings converted to one Weather row:%s", what.empty() ? " nothing to change" : what.c_str());
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
        int ws = Index("gfx_wxsrv");  // server weather never carries over from the last session
        if (ws >= 0 && g_val[ws]) { g_val[ws] = 0; migrate = true; }
    }
    for (int i = 0; i < kCount; ++i) { g_fileVal[i] = g_val[i]; g_mine[i] = migrate; }
    if (migrate) Save();
    g_iniTime = IniTime();
    SyncInput();
    InterlockedExchange(&g_dirtyPost, 1);
}

static void Save() {
    // only what this game changed; every other value stays as the file has it (another open game may have changed it)
    std::string cur, fshot;
    int fv[kCount], w[kCount];
    bool fh[kCount], fhs = false;
    if (ReadWholeFile(ExeDirFile("gfx.ini"), cur)) ParseVals(cur, fv, fh, &fshot, &fhs);
    else for (int i = 0; i < kCount; ++i) fh[i] = false;
    for (int i = 0; i < kCount; ++i) w[i] = g_mine[i] || !fh[i] ? g_val[i] : fv[i];
    std::string shotDir = fhs ? fshot : g_shotDir;
    std::string out = "; Dadmod graphics settings (Dadmod > Graphics in game, or THUGPro Manager). Changes apply live\r\n"
                      "; except MSAA and v-sync, which need a restart. Delete this file for the defaults.\r\n";
    for (int i = 0; i < kCount; ++i)
        if (!IsLampKey(kSettings[i].key))
            out += std::string("; ") + kSettings[i].help + "\r\n" + kSettings[i].key + " = " + std::to_string(w[i]) + "\r\n";
    out += "; folder for F11 screenshots (empty = dadmod\\screenshots)\r\ngfx_shotdir = " + shotDir + "\r\n";
    out += "\r\n; ---- Street lamps ----\r\n";
    for (const auto& l : kLampKeys) {
        int i = Index(l.key);
        if (i >= 0) out += std::string("; ") + l.text + "\r\n" + l.key + " = " + std::to_string(w[i]) + "\r\n";
    }
    WriteWholeFile(ExeDirFile("gfx.ini"), Stamped(out));
    for (int i = 0; i < kCount; ++i) { g_fileVal[i] = w[i]; g_mine[i] = false; }
    g_iniTime = IniTime();
}
// gfx.ini changed while this game runs: another open game's save is ignored (this game keeps its own settings);
// an edit from THUGPro Manager or a text editor applies the values it changed. A deleted file means defaults (as before).
static void ReloadChanged() {
    std::string data, shot;
    if (!ReadWholeFile(ExeDirFile("gfx.ini"), data)) { Load(); return; }
    int fv[kCount];
    bool fh[kCount], hs = false;
    ParseVals(data, fv, fh, &shot, &hs);
    if (!StampOk(data)) {
        int n = 0;
        for (int i = 0; i < kCount; ++i)
            if (fh[i] && fv[i] != g_fileVal[i]) { g_val[i] = fv[i]; ++n; }
        if (hs) g_shotDir = shot;
        mmenu::Log("gfx: gfx.ini edited outside the game: %d setting(s) applied", n);
    }
    for (int i = 0; i < kCount; ++i) if (fh[i]) g_fileVal[i] = fv[i];
    g_iniTime = IniTime();
    SyncInput();
    InterlockedExchange(&g_dirtyPost, 1);
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
static int g_keepLit = 1;  // night tint spares bright / colored pixels (THUG2-era maps' own lights); QB sends 0 for THPS1-4 maps (lamplights.q)
static void FireworksShow(double seconds, const char* why);
static void SetLevel(const char* name);
static void WinPollLevel(const char* lv);  // lit windows follow the level (2026-11-23)
static void LampMark(bool add);
// ---- THUG Pro launcher settings in Dadmod > Graphics (Noah 2026-11-22: "the launcher settings should just be
// incorporated into the dadmod graphics menu"). Pseudo-keys: nothing goes into gfx.ini; each value lives where the
// THUG Pro launcher keeps it (HKCU\Software\THUG Pro\Settings, mmenu::DispGet/DispSet), so the launcher and dadmod
// always show the same thing and a new install starts on the launcher's own defaults. Live where the engine reads the
// value while playing (exe bytes the exe and thugpro.dll fill in once at start); the rest is read by thugpro.dll at
// start and its menu row says "Takes effect after a restart."
//   gfx_skshadow     SkaterShadowQuality 0 Low (circle) .. 3 Very High. Live: exe byte 0x7D6435 (1 = the local skater gets
//                    the full-body shadow when it spawns, FUN_00565bf0) and the texture size pushed at 0x4A19E5/0x4A19EA
//                    (256, 512 for High, 1024 for Very High, as thugpro.dll patches it at start); QB dadmod_shadow_refresh
//                    then rebuilds the skater's shadow
//   gfx_shadowdetail read only: 1 when the local skater should get the full-body shadow (exe byte 0x7D6435)
//   gfx_clip         options bit 0x100, exe byte 0x7D643A        gfx_clipfog  options bit 0x1, exe byte 0x7D6436
//   gfx_clipdist     distance 1..100, exe 0x7D6440 = distance, 0x7D6444 = distance * 5 + 95 (as the exe works it out at 0x5F3559)
//   gfx_particles    NoParticles (row shows On = 0), restart     gfx_skaterlights  SkaterLightType 1 = on, restart
//   gfx_levellights  DisableLevelLights (row shows On = 0). Live: thugpro.dll NOPs the 5-byte call at 0x490756 in
//                    AddLevelLight at start; we put the call back (from the exe file) or NOP it; shows from the next level load
//   gfx_tpscreenfx   ScreenEffectsEnabled 1 = on, restart (thugpro.dll makes its shader effects at device creation)
namespace tp {
static DWORD Opt() { return mmenu::DispGet("options", 0); }
static void SetOpt(DWORD bit, bool on) { DWORD o = Opt(); mmenu::DispSet("options", on ? (o | bit) : (o & ~bit)); }
static int Clamp(int v, int lo, int hi) { return v < lo ? lo : v > hi ? hi : v; }
static void WriteCode(BYTE* at, const BYTE* bytes, int n) {
    DWORD old;
    if (!VirtualProtect(at, n, PAGE_EXECUTE_READWRITE, &old)) return;
    memcpy(at, bytes, n);
    VirtualProtect(at, n, old, &old);
    FlushInstructionCache(GetCurrentProcess(), at, n);
}
static int Shadow() { return Clamp((int)mmenu::DispGet("SkaterShadowQuality", 0), 0, 3); }
static void ShadowApply(int q) {
    *(volatile BYTE*)0x7D6435 = q > 0 ? 1 : 0;
    BYTE* p = (BYTE*)0x4A19E5;   // push 0x100 ; push 0x100 (width, height of the full-body shadow texture)
    DWORD size = q >= 3 ? 0x400 : q == 2 ? 0x200 : 0x100;
    DWORD w = *(DWORD*)(p + 1), h = *(DWORD*)(p + 6);
    bool known = (w == 0x100 || w == 0x200 || w == 0x400) && (h == 0x100 || h == 0x200 || h == 0x400);
    if (p[0] == 0x68 && p[5] == 0x68 && known && (w != size || h != size)) {
        BYTE b[10] = { 0x68, 0, 0, 0, 0, 0x68, 0, 0, 0, 0 };
        memcpy(b + 1, &size, 4); memcpy(b + 6, &size, 4);
        WriteCode(p, b, 10);
    }
    mmenu::Log("gfx: skater shadow %d (%s, %ux%u)", q, q ? "full body" : "circle", size, size);
}
static int Dist() { DWORD v = mmenu::DispGet("distance", 100); return v < 1 ? 1 : v > 100 ? 100 : (int)v; }
// the call AddLevelLight makes at 0x490756, as it is in THUGPro.exe on disk (thugpro.dll may have NOPed it in memory)
static bool LevelLightCall(BYTE out[5]) {
    BYTE* mem = (BYTE*)0x490756;
    if (mem[0] == 0xE8) { memcpy(out, mem, 5); return true; }
    BYTE* base = (BYTE*)0x400000;
    IMAGE_NT_HEADERS* nt = (IMAGE_NT_HEADERS*)(base + ((IMAGE_DOS_HEADER*)base)->e_lfanew);
    IMAGE_SECTION_HEADER* s = IMAGE_FIRST_SECTION(nt);
    DWORD rva = 0x90756, off = 0;
    for (int i = 0; i < nt->FileHeader.NumberOfSections; ++i)
        if (rva >= s[i].VirtualAddress && rva < s[i].VirtualAddress + s[i].SizeOfRawData) off = s[i].PointerToRawData + rva - s[i].VirtualAddress;
    char path[MAX_PATH];
    if (!off || !GetModuleFileNameA(NULL, path, MAX_PATH)) return false;
    HANDLE f = CreateFileA(path, GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL);
    if (f == INVALID_HANDLE_VALUE) return false;
    DWORD got = 0;
    bool ok = SetFilePointer(f, off, NULL, FILE_BEGIN) == off && ReadFile(f, out, 5, &got, NULL) && got == 5 && out[0] == 0xE8;
    CloseHandle(f);
    return ok;
}
static void LevelLightsApply(bool on) {
    BYTE* mem = (BYTE*)0x490756;
    static const BYTE nops[5] = { 0x90, 0x90, 0x90, 0x90, 0x90 };
    BYTE call[5];
    if (on && !memcmp(mem, nops, 5) && LevelLightCall(call)) WriteCode(mem, call, 5);
    else if (!on && mem[0] == 0xE8) WriteCode(mem, nops, 5);
    mmenu::Log("gfx: level lights %s (from the next level load)", mem[0] == 0xE8 ? "on" : "off");
}
static bool Set(const char* key, int v) {
    if (!_stricmp(key, "gfx_skshadow")) {
        v = Clamp(v, 0, 3);
        mmenu::DispSet("SkaterShadowQuality", v);
        if (!v) SetOpt(0x2, false);   // the launcher's old "quality shadows" bit would turn the full-body shadow back on
        ShadowApply(v);
        return true;
    }
    if (!_stricmp(key, "gfx_clip")) { SetOpt(0x100, v != 0); *(volatile BYTE*)0x7D643A = v ? 1 : 0; mmenu::Log("gfx: distance clipping %s", v ? "on" : "off"); return true; }
    if (!_stricmp(key, "gfx_clipfog")) { SetOpt(0x1, v != 0); *(volatile BYTE*)0x7D6436 = v ? 1 : 0; mmenu::Log("gfx: distance fog %s", v ? "on" : "off"); return true; }
    if (!_stricmp(key, "gfx_clipdist")) {
        v = Clamp(v, 1, 100);
        mmenu::DispSet("distance", v);
        *(volatile int*)0x7D6440 = v;
        *(volatile int*)0x7D6444 = (int)((float)v * 5.0f + 95.0f);
        mmenu::Log("gfx: clip distance %d", v);
        return true;
    }
    if (!_stricmp(key, "gfx_particles")) { mmenu::DispSet("NoParticles", v ? 0 : 1); return true; }
    if (!_stricmp(key, "gfx_levellights")) { mmenu::DispSet("DisableLevelLights", v ? 0 : 1); LevelLightsApply(v != 0); return true; }
    if (!_stricmp(key, "gfx_skaterlights")) { mmenu::DispSet("SkaterLightType", v ? 1 : 0); return true; }
    if (!_stricmp(key, "gfx_tpscreenfx")) { mmenu::DispSet("ScreenEffectsEnabled", v ? 1 : 0); return true; }
    return false;
}
static bool Get(const char* key, int* v) {
    if (!_stricmp(key, "gfx_skshadow")) { *v = Shadow(); return true; }
    if (!_stricmp(key, "gfx_shadowdetail")) { *v = *(volatile BYTE*)0x7D6435 ? 1 : 0; return true; }
    if (!_stricmp(key, "gfx_clip")) { *v = (Opt() & 0x100) ? 1 : 0; return true; }
    if (!_stricmp(key, "gfx_clipfog")) { *v = (Opt() & 0x1) ? 1 : 0; return true; }
    if (!_stricmp(key, "gfx_clipdist")) { *v = Dist(); return true; }
    if (!_stricmp(key, "gfx_particles")) { *v = mmenu::DispGet("NoParticles", 0) ? 0 : 1; return true; }
    if (!_stricmp(key, "gfx_levellights")) { *v = mmenu::DispGet("DisableLevelLights", 0) ? 0 : 1; return true; }
    if (!_stricmp(key, "gfx_skaterlights")) { *v = mmenu::DispGet("SkaterLightType", 0) == 1 ? 1 : 0; return true; }
    if (!_stricmp(key, "gfx_tpscreenfx")) { *v = mmenu::DispGet("ScreenEffectsEnabled", 0) == 1 ? 1 : 0; return true; }
    return false;
}
}  // namespace tp
// THUGRECOMP_SettingSave/Load redirect for gfx_ keys (declared in modes.inc)
bool SetKey(const char* key, int value) {
    if (tp::Set(key, value)) return true;
#ifdef DADMOD_PADINJECT
    if (!_stricmp(key, "gfx_padinject_go")) { if (padhub::g_injGo) SetEvent(padhub::g_injGo); return true; }  // test builds only
#endif
    if (!_stricmp(key, "gfx_fwnow")) { FireworksShow(12, "menu"); return true; }
    if (!_strnicmp(key, "gfx_level_", 10)) { SetLevel(key + 10); return true; }
    if (!_stricmp(key, "gfx_lampadd")) { LampMark(true); return true; }
    if (!_stricmp(key, "gfx_lampdel")) { LampMark(false); return true; }
    if (!_stricmp(key, "gfx_keeplit")) { g_keepLit = value ? 1 : 0; return true; }
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
    g_mine[i] = true;
    if (!_stricmp(key, "gfx_tricksfx") && was && !g_val[i]) StopSpecialStream("menu");
    if (!_stricmp(key, "gfx_tricksfx") && g_val[i] && was != g_val[i]) SetSpecialStreamVolume(g_trickBaseVol * g_val[i] / 100.0f);
    if (!_stricmp(key, "gfx_postfx")) {
        int set = Index("gfx_postfxset");
        if (set >= 0) { g_val[set] = 1; g_mine[set] = true; }   // the row was used: dadmod now switches ReShade's own effects with it
        if (was != g_val[i]) mmenu::Log("gfx: graphics effects -> %s (menu)", g_val[i] ? "ReShade (dadmod's screen effects skipped)" : "dadmod");
    }
    Save();
    SyncInput();
    InterlockedExchange(&g_dirtyPost, 1);
    return true;
}
// ---- dadmod\panel_settings.txt (THUGRECOMP_SettingSave/Load keys that are not gfx_*; modes.inc / client common.inc call
// these). Read once, then answered from memory; a save changes only its own key in the file; a change another open game
// made is ignored and one from a tool (panel tuner, THUGPro Manager) applies its changed keys (see StampOk above).
typedef std::vector<std::pair<std::string, int>> PanelList;
static PanelList g_panel, g_panelFile;
static FILETIME g_panelTime = {};
static bool g_panelRead = false;
static FILETIME PanelTime() {
    WIN32_FILE_ATTRIBUTE_DATA a;
    if (GetFileAttributesExA(ExeDirFile("panel_settings.txt").c_str(), GetFileExInfoStandard, &a)) return a.ftLastWriteTime;
    return FILETIME{};
}
static int* PanelFind(PanelList& l, const std::string& k) {
    for (auto& e : l) if (e.first == k) return &e.second;
    return nullptr;
}
static void PanelPut(PanelList& l, const std::string& k, int v) {
    if (int* p = PanelFind(l, k)) *p = v; else l.push_back(std::make_pair(k, v));
}
static void PanelParse(const std::string& data, PanelList& out) {   // "key value" lines; the first line for a key counts
    out.clear();
    size_t s = 0;
    while (s < data.size()) {
        size_t e = data.find_first_of("\r\n", s);
        std::string line = data.substr(s, e == std::string::npos ? std::string::npos : e - s);
        s = e == std::string::npos ? data.size() : e + 1;
        size_t sp = line.find(' ');
        if (line.empty() || line[0] == ';' || sp == std::string::npos) continue;
        std::string k = line.substr(0, sp);
        if (!PanelFind(out, k)) out.push_back(std::make_pair(k, atoi(line.c_str() + sp + 1)));
    }
}
static void PanelSync() {
    FILETIME t = PanelTime();
    if (g_panelRead && !CompareFileTime(&t, &g_panelTime)) return;
    std::string data;
    bool ok = ReadWholeFile(ExeDirFile("panel_settings.txt"), data);
    PanelList f;
    if (ok) PanelParse(data, f);
    if (!g_panelRead) g_panel = f;
    else if (ok && !StampOk(data))
        for (auto& e : f) { int* old = PanelFind(g_panelFile, e.first); if (!old || *old != e.second) PanelPut(g_panel, e.first, e.second); }
    g_panelFile = f;
    g_panelTime = t;
    g_panelRead = true;
}
bool PanelGet(const char* key, int* value) {
    PanelSync();
    int* p = PanelFind(g_panel, key);
    if (!p) return false;
    *value = *p;
    return true;
}
bool PanelSet(const char* key, int value) {
    PanelSync();
    PanelPut(g_panel, key, value);
    std::string path = ExeDirFile("panel_settings.txt"), data, out;
    ReadWholeFile(path, data);
    data = StripStamp(data);
    size_t s = 0;
    while (s < data.size()) {
        size_t e = data.find_first_of("\r\n", s);
        std::string line = data.substr(s, e == std::string::npos ? std::string::npos : e - s);
        s = e == std::string::npos ? data.size() : e + 1;
        if (line.empty()) continue;
        size_t sp = line.find(' ');
        if (sp != std::string::npos && line.substr(0, sp) == key) continue;
        out += line + "\r\n";
    }
    out += std::string(key) + " " + std::to_string(value) + "\r\n";
    bool ok = WriteWholeFile(path, Stamped(out));
    PanelParse(out, g_panelFile);
    g_panelTime = PanelTime();
    return ok;
}
bool GetKey(const char* key, int* value) {
    if (tp::Get(key, value)) return true;
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
        g_mine[i] = true;
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
static bool BulbsOn();
static bool MoonOn();
static bool WinLayerReady();
static bool WindowsOn();
static float g_wxMist = 0;  // ground mist amount from the weather (Fog weather 1, rain / storm / snow a little), eased
static bool MistOn() { return g_wxMist > 0.004f && !g_mainMenu; }  // ground mist (2026-11-21), from the Weather row since 2026-11-23
static bool DepthWanted() { return MistOn() || V("gfx_debug") || V("gfx_ssao") || V("gfx_fog") || V("gfx_dof") || V("gfx_outline") || WeatherOn() || FireworksLive() || LampsOn() || BulbsOn() || MoonOn() || WindowsOn(); }  // windows: hidden behind closer things (2026-11-23)
static bool SceneWanted() {
    return V("gfx_fxaa") || V("gfx_sharpen") || V("gfx_bloom") || V("gfx_bright") || V("gfx_contrast") || V("gfx_sat") ||
           V("gfx_vibrance") || V("gfx_gamma") || V("gfx_preset") || V("gfx_temp") || V("gfx_tint") || DepthWanted() ||
           V("gfx_mblur") || V("gfx_pixelate") || WeatherOn() || FireworksLive() || LampsOn() || BulbsOn() || WinLayerReady() || g_nightLift > 0.01f;
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
static bool g_skySeen = false;  // the replacement sky drew on this level (2026-11-22, MapLookNow)
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

static void FgFullscreenRefresh(IDirect3D9* d3d, UINT adapter, D3DPRESENT_PARAMETERS* pp);  // framegen.inc
static void AdjustPP(IDirect3D9* d3d, UINT adapter, D3DDEVTYPE type, D3DPRESENT_PARAMETERS* pp) {
    int vs = V("gfx_vsync");
    static DWORD s_gameInterval = 0xFFFFFFFF;  // what the game asked for, so "Game default" can go back to it after a live change
    if (s_gameInterval == 0xFFFFFFFF) s_gameInterval = pp->PresentationInterval;
    if (vs == 0) pp->PresentationInterval = s_gameInterval;
    if (vs == 1) pp->PresentationInterval = D3DPRESENT_INTERVAL_ONE;
    if (vs == 2) pp->PresentationInterval = D3DPRESENT_INTERVAL_IMMEDIATE;
    FgFullscreenRefresh(d3d, adapter, pp);
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
float4 wx : register(c17);   // weather amounts: rain, snow, lightning flash, storm (0-1)
float4 wx2 : register(c18);  // light level (1 day .. 0.3 night), lightning bolt azimuth, wet, -
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
    // Night: lift the darks so the level stays visible. 2026-11-23: not on the bright replacement skies (golden hour,
    // vaporwave, rainbow, cotton candy; s2 = depth when p9.z > 0): the lift washed them out to grey on a night server
    bool brightSky = p9.z > 0 && (abs(p9.y - 8) < 0.5 || abs(p9.y - 9) < 0.5 || abs(p9.y - 12) < 0.5 || abs(p9.y - 14) < 0.5)
                     && tex2D(s2, uv).r >= 0.99999;
    if (p3.w > 0 && !brightSky) c = pow(saturate(c), 1.0 / (1.0 + p3.w));
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
    // the 3 cloud octaves and the fine noise share one noise3 in a loop (2026-11-22: four inlined copies were 589 slots,
    // over D3D9's 512; the octave inputs are worked out up front the same way fbm3u does)
    float3 o0 = float3(q, 0.3), o1 = o0 * 2.07 + 1.3, o2 = o1 * 2.07 + 1.3, o3 = float3(q * 4.0, t * 0.03);
    float cs = 0;
    [loop] for (int k = 0; k < 4; k++) cs += noise3(k == 0 ? o0 : (k == 1 ? o1 : (k == 2 ? o2 : o3))) * (k == 0 ? 0.5 / 0.875 : (k == 1 ? 0.25 / 0.875 : (k == 2 ? 0.125 / 0.875 : 0.12)));
    float c = smoothstep(0.48, 0.78, cs);
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
    if (bright) return c;  // 2026-11-22 Noah: golden, vapor, rainbow and candy keep their daytime colors at every time of day
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
    } else if (tod > 2.5 && tod < 3.5) { // evening (was sunset; 2026-11-22 softer, like stock Evening): warm band low, slate blue above
        float3 g = lerp(float3(0.95, 0.60, 0.38), float3(0.22, 0.32, 0.46), saturate(el * 2.2));
        c = lerp(c, g * (0.5 + lum), mixv * 0.75) + pow(sun, 10) * float3(1.0, 0.6, 0.3) * 0.2 + pow(sun, 300) * float3(1.0, 0.85, 0.6) * 0.4;
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
float3 nighttint(float tod) { return tod > 3.5 && tod < 4.5 ? float3(0.22, 0.26, 0.40) : (tod > 5.5 ? float3(0.40, 0.40, 0.52) : (tod > 4.5 ? float3(0.92, 0.86, 0.90) : float3(1, 1, 1))); }  // night, dawn, evening lights (reference only since 2026-11-22: ps_nighttint takes the tint from kLooks via c18)
float4 ps_nighttint(float2 uv : TEXCOORD0) : COLOR {
    float3 c = tex2D(s0, uv).rgb;
    float3 t = wx2.rgb;  // 2026-11-22: the tint comes from the CPU (MapLook: time of day, or a dark sky's lighting)
    float br = max(c.r, max(c.g, c.b)), sat = br - min(c.r, min(c.g, c.b));  // keep the level's lights lit: bright or strongly colored pixels
    t = lerp(t, 1, saturate(smoothstep(0.45, 0.85, br) + smoothstep(0.25, 0.6, sat) * smoothstep(0.3, 0.6, br)) * wx.x);  // wx.x here = keep lit (0 on THPS1-4 maps: no real lights)
    return float4(c * t, 1);
}
// ---- weather (scene pass, before the HUD): s0 color, s1 depth when p9.z > 0
// lightning: the same slots and hash as the Storm sky, so with threshold 0.74 the two flash together
float lightning(float t, float thr) {
    float slot = floor(t * 1.7), ph = frac(t * 1.7);
    float hit = step(thr, hash12(float2(slot, 4.1)));
    return hit * (exp(-ph * 9.0) + 0.6 * exp(-abs(ph - 0.22) * 25.0));
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
// ---- lamp bulbs (mods/lamplights, 2026-11-22): soft glow at each lamp head + a warm round pool under it, after the night tint
// lp[i*2] = bulb position (world), lp[i*2+1] = color rgb, pool radius. lampc: amount, count, pool strength
float4 ps_bulbs(float2 uv : TEXCOORD0) : COLOR {
    float3 c = tex2D(s0, uv).rgb;
    float d0 = tex2D(s1, uv).r;
    float2 ndc = float2(uv.x * 2 - 1, 1 - uv.y * 2);
    float3 dv = vr.xyz * (ndc.x / pj.x) + vu.xyz * (ndc.y / pj.y) - vb.xyz;
    bool sky = d0 >= 0.99999;
    float z = sky ? 50000.0 : dist(d0);
    float3 P = camp.xyz + dv * z;
    float3 dn = normalize(dv);
    float far = length(dv) * z;
    float3 light = 0, halo = 0;
    [loop] for (int i = 0; i < 24; i++) {
        if (i >= lampc.y) break;
        float4 a = lp[i * 2], col = lp[i * 2 + 1];
        float3 dl = P - (a.xyz - float3(0, a.w, 0));
        float x = saturate(1 - dot(dl, dl) / (col.w * col.w));
        light += x * x * (sky ? 0 : 1);
        float tl = dot(a.xyz - camp.xyz, dn);
        if (tl > 0 && tl < far + 30) {
            float3 q = camp.xyz + dn * tl - a.xyz;
            float r2 = dot(q, q);
            float nr = saturate(tl / 600.0), fs = 1 + tl * 0.0015;
            float cs = 100.0 * lerp(0.35, 1.0, nr) * fs * fs * camp.w * camp.w, hs = (1250.0 * nr * nr + 40.0) * fs * camp.w * camp.w;
            halo += col.rgb * exp(-r2 / cs) * 0.9 + col.rgb * float3(1.0, 0.85, 0.62) * exp(-r2 / hs) * 0.2 * nr;
        }
    }
    float3 warm = float3(1.0, 0.55, 0.16);
    float lum = dot(c, float3(0.3, 0.5, 0.2));
    float pl = saturate(light.x) * lampc.x;
    c = lerp(c, c * float3(1.2, 0.95, 0.7), pl);
    c += warm * pl * (lum * lampc.z + lampc.w) + halo * lampc.x;
    return float4(c, 1);
}
// moonlight (after the night tint): lampc.x amount, lp[0].xyz direction to the moon; normals from the depth
// 2026-11-23 (Noah: a dotted dark ring around the skater's shadow at night): the shadow decal's rim sits a little off
// the ground in the depth buffer, so the normal worked out there (ddx/ddy) tipped sideways and those pixels lost or
// gained moonlight: a broken ring around every skater shadow. Now each pixel takes the middle value (median) of the
// moonlight at itself and at 4 points 3 pixels away, every one from a normal over 2-pixel spans (moon_ndl): a ring a
// pixel or two wide is outvoted by the ground around it, while floors, walls and their edges keep their own light.
// Tested in a College test copy (work/notes/shadow_rim): ring with the old shader at Moonlight 20, none at 0.
float3 moon_p(float2 q) {
    float d = tex2D(s1, q).r;
    float2 ndc = float2(q.x * 2 - 1, 1 - q.y * 2);
    float3 dv = vr.xyz * (ndc.x / pj.x) + vu.xyz * (ndc.y / pj.y) - vb.xyz;
    return camp.xyz + dv * dist(d);
}
// one axis of the surface slope at P from the points 2 pixels to either side: across a thin raised sliver both halves
// bend the opposite way by the same amount, so the whole span is used; across a real edge (floor to wall) one half is
// much longer, so the shorter half is
float3 moon_axis(float2 uv, float3 P, float2 o) {
    float3 a = moon_p(uv + o) - P, b = P - moon_p(uv - o);
    float la = dot(a, a), lb = dot(b, b);
    if (la < lb * 4 && lb < la * 4) return a + b;
    return la < lb ? a : b;
}
// moonlight at one screen point: 0 for the sky, else how much its surface faces the moon
float moon_ndl(float2 q) {
    float d = tex2D(s1, q).r;
    if (d >= 0.99999) return 0;
    float3 P = moon_p(q);
    float3 n = normalize(cross(moon_axis(q, P, float2(0, px.y * 2)), moon_axis(q, P, float2(px.x * 2, 0))));
    if (dot(n, camp.xyz - P) < 0) n = -n;
    return saturate(dot(n, lp[0].xyz));
}
float med5(float a, float b, float c, float d, float e) {
    float t;
    t = min(a, b); b = max(a, b); a = t;
    t = min(d, e); e = max(d, e); d = t;
    t = min(a, d); d = max(a, d); a = t;
    t = min(b, e); e = max(b, e); b = t;
    t = min(c, d); d = max(c, d); c = t;
    t = min(b, c); c = max(b, c); b = t;
    t = min(c, d); d = max(c, d); c = t;
    return min(max(b, c), d);
}
float4 ps_moon(float2 uv : TEXCOORD0) : COLOR {
    float3 c = tex2D(s0, uv).rgb;
    float2 ox = float2(px.x * 3, 0), oy = float2(0, px.y * 3);
    float ndl = med5(moon_ndl(uv), moon_ndl(uv + ox), moon_ndl(uv - ox), moon_ndl(uv + oy), moon_ndl(uv - oy));
    if (tex2D(s1, uv).r >= 0.99999) ndl = 0;
    c += (c * 0.9 + 0.03) * float3(0.55, 0.63, 0.78) * ndl * lampc.x;
    return float4(c, 1);
}
// ps_btile (2026-11-23 speed review): every lamp entry touching one screen tile in ONE pass (up to 24; more = another
// pass on that tile), the same maths as ps_bpool / ps_bhalo in the same order. Entries split in two arrays so the
// loop counter can index them: tA = lp[0] (position, drop), tB = lp[1] (colour or flood stretch, pool radius)
float4 tA[24] : register(c30);
float4 tB[24] : register(c54);
float4 ps_btile(float2 uv : TEXCOORD0) : COLOR {
    float3 c = tex2D(s0, uv).rgb;
    float d0 = tex2D(s1, uv).r;
    float2 ndc = float2(uv.x * 2 - 1, 1 - uv.y * 2);
    float3 dv = vr.xyz * (ndc.x / pj.x) + vu.xyz * (ndc.y / pj.y) - vb.xyz;
    float dd = dist(d0);
    float far = length(dv) * dd;
    float3 dn = normalize(dv);
    float3 P = camp.xyz + dv * dd;
    bool sky = d0 >= 0.99999;
    [loop] for (int i = 0; i < 24; ++i) {
        if (i >= lampc.y) break;
        float4 A = tA[i];
        float4 B = tB[i];
        if (B.w > 1.0) {
            if (!sky) {
                float3 dl = P - (A.xyz - float3(0, A.w, 0));
                float st = length(B.xyz);
                if (st > 1.01) { float3 sn = B.xyz / st; dl -= sn * dot(dl, sn) * (1 - 1 / st); }
                float x = saturate(1 - dot(dl, dl) / (B.w * B.w + 0.001));
                float pl = x * x * lampc.x;
                float lum = dot(c, float3(0.3, 0.5, 0.2));
                c = lerp(c, c * float3(1.2, 0.95, 0.7), pl);
                c += float3(1.0, 0.55, 0.16) * pl * (lum * lampc.z + lampc.w);
            }
        } else {
            float tl = dot(A.xyz - camp.xyz, dn);
            if (tl > 0 && tl < far + 30) {
                float3 q = camp.xyz + dn * tl - A.xyz;
                float r2 = dot(q, q);
                float nr = saturate(tl / 600.0), fs = 1 + tl * 0.0015;
                float cs = 100.0 * lerp(0.35, 1.0, nr) * fs * fs * camp.w * camp.w, hs = (1250.0 * nr * nr + 40.0) * fs * camp.w * camp.w;
                c += (B.rgb * exp(-r2 / cs) * 0.9 + B.rgb * float3(1.0, 0.85, 0.62) * exp(-r2 / hs) * 0.2 * nr) * lampc.x;
            }
        }
    }
    return float4(c, 1);
}
// one lamp entry per pass (lp[0] position, lp[1] color + pool radius): ps_bhalo = bulb glow only, ps_bpool = light pool only
// lamp editor probe (dev only): the world spot at the middle of the screen (the editor camera looks at its cursor;
// the editor object's own position is the camera, 2026-11-23); a = 1 when something solid is there
// 2026-11-23 (Noah: the lamp looked raised off the ground at times): only a floor counts (the surface's normal from
// two neighbours lampc.xy apart points up); a wall or a ledge's edge keeps the last floor spot
float3 probe_at(float2 q, out float d0) {
    d0 = tex2D(s1, q).r;
    float2 ndc = float2(q.x * 2 - 1, 1 - q.y * 2);
    float3 dv = vr.xyz * (ndc.x / pj.x) + vu.xyz * (ndc.y / pj.y) - vb.xyz;
    return camp.xyz + dv * dist(d0);
}
float4 ps_lampprobe(float2 uv : TEXCOORD0) : COLOR {
    float d0, d1, d2;
    float3 P = probe_at(float2(0.5, 0.5), d0);
    float3 A = probe_at(float2(0.5 + lampc.x, 0.5), d1);
    float3 B = probe_at(float2(0.5, 0.5 + lampc.y), d2);
    float3 n = normalize(cross(A - P, B - P));
    bool floor_ = abs(n.y) > 0.75 && d0 < 0.99999 && d1 < 0.99999 && d2 < 0.99999;
    return float4(d0, floor_ ? 1 : 0, 0, 1);  // the spot itself is unprojected on the CPU with the full matrices
}
// lamp editor marks (mods/lampeditor, dev only): lp[0] = cursor ground spot + bulb height (cyan), lp[1..] = placed
// lamps (amber); a beam from the ground up to the bulb and a ring on the ground, dimmed (not hidden) behind walls
float4 ps_lampcur(float2 uv : TEXCOORD0) : COLOR {
    float3 c = tex2D(s0, uv).rgb;
    float d0 = tex2D(s1, uv).r;
    float2 ndc = float2(uv.x * 2 - 1, 1 - uv.y * 2);
    float3 dv = vr.xyz * (ndc.x / pj.x) + vu.xyz * (ndc.y / pj.y) - vb.xyz;
    float far = length(dv) * dist(d0);
    float3 dn = normalize(dv);
    float3 P = camp.xyz + dn * far;
    float2 dxz = dn.xz;
    float dd = dot(dxz, dxz) + 0.000001;
    float3 add = float3(0, 0, 0);
    for (int i = 0; i < 33; ++i) {
        if (i >= lampc.y) break;
        float4 L = lp[i];
        float cur = i == 0 ? 1.0 : 0.0;
        float3 col = lerp(float3(1.0, 0.62, 0.2), float3(0.25, 0.85, 1.0), cur);
        float rr = lerp(45.0, 70.0, cur);
        float hr = length(P.xz - L.xz);
        float lw = 3 + far * 0.002;
        bool near_ = d0 < 0.99999 && abs(P.y - L.y) < 4 + far * 0.003;  // only the surface the lamp stands on (never up a wall)
        float ring = near_ ? saturate(1 - abs(hr - rr) / lw) : 0;
        float2 dq = abs(P.xz - L.xz);  // a small cross on the exact spot (cursor only)
        float armd = min(dq.x < 30 ? dq.y : 1000.0, dq.y < 30 ? dq.x : 1000.0);
        float cross_ = near_ && cur > 0.5 ? saturate(1 - armd / lw) : 0;
        ring = max(ring, cross_);
        float t = dot(L.xz - camp.xz, dxz) / dd;
        float3 Q = camp.xyz + dn * t;
        float e = length(Q.xz - L.xz);
        float w = 2.5 + t * 0.0025;
        float beam = (t > 0 && Q.y > min(L.y, L.y + L.w) && Q.y < max(L.y, L.y + L.w)) ? saturate(1 - e / w) : 0;
        if (t > far + 15) beam *= 0.35;
        add += col * (ring + beam) * lerp(0.6, 1.0, cur);
    }
    return float4(c + add, 1);
}
float4 ps_bhalo(float2 uv : TEXCOORD0) : COLOR {
    float3 c = tex2D(s0, uv).rgb;
    float d0 = tex2D(s1, uv).r;
    float2 ndc = float2(uv.x * 2 - 1, 1 - uv.y * 2);
    float3 dv = vr.xyz * (ndc.x / pj.x) + vu.xyz * (ndc.y / pj.y) - vb.xyz;
    float far = length(dv) * dist(d0);
    float3 dn = normalize(dv);
    float tl = dot(lp[0].xyz - camp.xyz, dn);
    if (tl <= 0 || tl >= far + 30) return float4(c, 1);
    float3 q = camp.xyz + dn * tl - lp[0].xyz;
    float r2 = dot(q, q);
    float nr = saturate(tl / 600.0), fs = 1 + tl * 0.0015;
    float cs = 100.0 * lerp(0.35, 1.0, nr) * fs * fs * camp.w * camp.w, hs = (1250.0 * nr * nr + 40.0) * fs * camp.w * camp.w;
    float3 halo = lp[1].rgb * exp(-r2 / cs) * 0.9 + lp[1].rgb * float3(1.0, 0.85, 0.62) * exp(-r2 / hs) * 0.2 * nr;
    return float4(c + halo * lampc.x, 1);
}
float4 ps_bpool(float2 uv : TEXCOORD0) : COLOR {
    float3 c = tex2D(s0, uv).rgb;
    float d0 = tex2D(s1, uv).r;
    if (d0 >= 0.99999) return float4(c, 1);
    float2 ndc = float2(uv.x * 2 - 1, 1 - uv.y * 2);
    float3 dv = vr.xyz * (ndc.x / pj.x) + vu.xyz * (ndc.y / pj.y) - vb.xyz;
    float3 dl = camp.xyz + dv * dist(d0) - (lp[0].xyz - float3(0, lp[0].w, 0));
    float st = length(lp[1].xyz);  // flood (lamp editor models): the pool is stretched st times along lp[1].xyz
    if (st > 1.01) { float3 sn = lp[1].xyz / st; dl -= sn * dot(dl, sn) * (1 - 1 / st); }
    float x = saturate(1 - dot(dl, dl) / (lp[1].w * lp[1].w + 0.001));
    float pl = x * x * lampc.x;
    float lum = dot(c, float3(0.3, 0.5, 0.2));
    c = lerp(c, c * float3(1.2, 0.95, 0.7), pl);
    c += float3(1.0, 0.55, 0.16) * pl * (lum * lampc.z + lampc.w);
    return float4(c, 1);
}
// ---- lit windows (mods/lamplights, 2026-11-22). ps_window: drawn (ps_2_0, with the game's own fixed-function vertices)
// over the game's window-texture draws into a separate target; glass = dark / bluish texels, every window cell on or off
float4 ps_window(float2 uv : TEXCOORD0, float3 cp : TEXCOORD1) : COLOR {  // cp = camera-space position (stage 1 texcoord)
    clip(tex2D(s0, uv).a - px.y);  // px.y = the game's alpha-test cut (-1 = none): see-through parts of the texture stay dark
    float4 pm = tex2D(s1, uv);  // pane color map (rgb = this pane's lit color, a = pane), filtered + mipmapped
    float tv = frac(sin(dot(floor(uv), float2(12.9898, 78.233))) * 43758.5453);  // a little brightness change per texture repeat
    float3 o = pm.rgb * (0.85 + 0.15 * tv) * px.x * 0.6;
    if (px.w > 0.5) o = px.z > 0.5 ? float3(0, pm.a * 0.8, 0) : float3(0, 0, 0.5);  // gfx_windows 2: marked panes green, unmarked blue
    // alpha = 1 - this pixel's depth-buffer value incl. the game's DEPTHBIAS, so the composite compares depth with depth
    // (2026-11-23 flicker: comparing view distances failed on depth-biased far windows). Worked out as
    // (a z + b) / (_34 z + _44) - bias with a = _34 - _33, b = _44 - _43 made on the CPU in double: no 1 - 0.9999.. rounding far away
    float u = (p1.x * cp.z + p1.y) / (p1.z * cp.z + p1.w) - p2.x;
    return float4(o, saturate(u));  // no pane map = not drawn (2026-11-23: the old cell look lit brick)
}
// ps_winvis: quarter-res copy of only the windows that are really visible (depth checked), the source of the spill:
// r = glow, g = glow x window depth (log2(z) / 16), so after the blur g / r is the glow-weighted depth of the windows
// a window pixel is hidden when the depth buffer holds something else there: layer alpha u = 1 - window depth vs 1 - INTZ depth,
// allowed 0.2 % of u (half-float rounding, about 6 units at 3000 away) + 3e-7 (24-bit depth steps) + the depth's own slope per
// pixel x (1 + the largest SLOPESCALEDEPTHBIAS a window draw used, |lampc.w|): the game slope-biases some window meshes
bool winhid(float u, float d0) {
    float u0 = 1 - d0, sl = max(abs(ddx(d0)), abs(ddy(d0)));
    return abs(u - u0) > 3e-7 + u0 * 0.002 + sl * (1 + abs(lampc.w));
}
float2 winvis1(float2 uv) {
    float4 w = tex2D(s2, uv);
    float d0 = tex2D(s1, uv).r, z = dist(d0);
    float i = winhid(w.a, d0) ? 0 : dot(w.rgb, float3(0.4, 0.4, 0.2));
    return float2(i, i * log2(max(z, 1.0)) / 16.0);
}
float4 ps_winvis(float2 uv : TEXCOORD0) : COLOR {
    float2 a = 0.25 * (winvis1(uv + px.xy * float2(-1, -1)) + winvis1(uv + px.xy * float2(1, -1)) +
                       winvis1(uv + px.xy * float2(-1, 1)) + winvis1(uv + px.xy * float2(1, 1)));
    return float4(a, 0, 1);
}
// ps_wincomp (scene pass, after the night tint): adds the lit windows (s1)
float4 ps_wincomp(float2 uv : TEXCOORD0) : COLOR {
    float3 c = tex2D(s0, uv).rgb;
    float4 w = tex2D(s2, uv);
    if (lampc.y > 0.5) {  // the layer knows each window pixel's depth: only where that window is still the nearest thing
        if (winhid(w.a, tex2D(s1, uv).r)) w.rgb = lampc.w < 0 && dot(w.rgb, 1) > 0 ? float3(1.5, 0, 0) / max(lampc.x, 0.05) : 0;  // gfx_windows 3: hidden = red
    }
    float2 sp = tex2D(s3, uv).rg;  // blurred quarter-res copy of the visible windows: soft warm light around them
    float zl = log2(max(dist(tex2D(s1, uv).r), 1.0)), wl = sp.g / max(sp.r, 0.0001) * 16.0;
    float near = saturate(1 - (abs(zl - wl) - 0.15) / 0.15);  // only surfaces at about the windows' own depth (not buildings in front)
    float3 spill = sp.r * near * float3(1.0, 0.72, 0.42);
    return float4(c + (w.rgb + spill * lampc.z) * lampc.x, 1);
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
// ---- weather (2026-11-23 rework, Noah: "the effects look like ass"): drops and flakes sit in the world. The view ray
// walks a grid of vertical columns around the camera (one drop line per column), so drops move past as you skate,
// keep their perspective when you look up or down, stop at walls and have no screen pattern. Two grids: near (fine)
// and far (coarse, fainter) for reach. The game's own weather adds splashes. s0 color, s1 depth when p9.z > 0.
// wx: rain, snow, lightning flash, storm; wx2: light level, bolt azimuth, wet, -; wxc: overcast color; camp: camera
float wxcols(float3 o, float3 d, float rl, float cs, float t, float fill, float snow, float far) {
    float2 dxz = d.xz;
    float hl = length(dxz);
    if (hl < 0.03) return 0;
    float2 cell = floor(o.xz / cs);
    float2 st = float2(dxz.x >= 0 ? 1 : -1, dxz.y >= 0 ? 1 : -1);
    float2 inv = 1.0 / max(abs(dxz), 0.0001);
    float2 tm = abs((cell + max(st, 0)) * cs - o.xz) * inv;
    float2 td = cs * inv;
    float acc = 0;
    [loop] for (int i = 0; i < 12; i++) {  // 2026-11-23: 20 steps cost ~14 fps (60 -> 46); 12 near + 12 far is plenty
        float h = hash12(cell);
        [branch] if (h < fill) {
            float2 p = (cell + 0.15 + 0.7 * float2(hash12(cell + 7.1), hash12(cell + 3.3))) * cs;
            if (snow > 0.5) p += float2(sin(t * 0.9 + h * 40.0), cos(t * 0.7 + h * 23.0)) * cs * 0.12;
            float tc = dot(p - o.xz, dxz) / (hl * hl);
            [branch] if (tc > 16.0 && tc < rl) {
                float lat = length(o.xz + dxz * tc - p);
                float w = max(0.35, tc * 0.0018);
                float y = o.y + d.y * tc;
                float a;
                if (snow > 0.5) {
                    float v = (y + t * 34.0 + h * 977.0) / 70.0;
                    float fy = (frac(v) - 0.5) * 70.0;
                    float r = 1.1 + 0.8 * hash12(cell + floor(v));
                    a = smoothstep(r + w, r * 0.3, length(float2(lat, fy))) * min(1.0, 1.6 / w);
                } else {
                    float v = (y + t * 300.0 + h * 977.0) / 150.0;
                    float fy = frac(v) * 150.0;
                    float ls = 26.0 + far * 18.0;
                    a = smoothstep(w, 0, lat) * step(fy, ls) * (1 - fy / ls) * min(1.0, 0.7 / w);
                }
                acc += a * saturate(1.3 - tc / rl) * saturate((tc - 16.0) / 40.0);
            }
        }
        if (tm.x < tm.y) { cell.x += st.x; tm.x += td.x; } else { cell.y += st.y; tm.y += td.y; }
        if (min(tm.x, tm.y) > rl) break;
    }
    return acc;
}
float4 ps_weather(float2 uv : TEXCOORD0) : COLOR {
    float3 c = tex2D(s0, uv).rgb;
    float2 ndc = float2(uv.x * 2 - 1, 1 - uv.y * 2);
    float3 dv = vr.xyz * (ndc.x / pj.x) + vu.xyz * (ndc.y / pj.y) - vb.xyz;
    float3 d = normalize(dv);
    float rl = 600.0;  // no depth (MSAA): keep the drops close and treat everything as ground
    bool sky = false;
    if (p9.z > 0) { float d0 = tex2D(s1, uv).r; sky = d0 >= 0.99999; rl = sky ? 4000.0 : dist(d0) * length(dv); }
    float rain = wx.x, snow = wx.y, fl = wx.z, storm = wx.w, lite = wx2.x, t = p1.w;
    if (wx2.w > 0.5) fl = lightning(t, 0.74) * saturate(storm);  // Storm sky: flash with its strikes
    float wet = saturate(rain + storm * 0.6);
    float over = saturate(rain * 0.6 + storm * 0.6 + snow * 0.45);
    float lum = dot(c, L);
    if (sky) {
        c = lerp(c, wxc.rgb * (0.6 + 0.4 * lum), over * 0.6);
        float az = atan2(d.x, d.z), el = asin(clamp(d.y, -1, 1));
        float da = az - wx2.y; da -= 6.2831853 * round(da / 6.2831853);
        float jag = (hash12(float2(floor(el * 40.0), wx2.y)) - 0.5) * 0.025 + (hash12(float2(floor(el * 9.0), wx2.y + 1.0)) - 0.5) * 0.06;
        float bolt = exp(-abs(da - jag) * 600.0) * smoothstep(0.02, 0.12, el) * smoothstep(0.75, 0.45, el) * (1 - wx2.w);
        c += fl * (bolt * 1.6 * float3(0.85, 0.9, 1.0) + 0.35 * float3(0.75, 0.8, 1.0));
    } else {
        c *= 1 - 0.1 * over;
        c += pow(saturate(lum), 2.5) * wet * wx2.z * saturate(-d.y * 4) * 0.2;
        c += fl * 0.18 * float3(0.8, 0.85, 1.0) * (0.4 + 0.6 * lite);
    }
    float3 o = camp.xyz;
    float sn = snow > wet ? 1 : 0, amt = max(saturate(rain), saturate(snow));  // one kind at a time (they cross-fade through clear)
    [branch] if (amt > 0.01) {
        float f = 0.02 + 0.85 * amt;
        float a = 0;
        [loop] for (int g = 0; g < 2; g++) {  // near grid, then the far one (one copy of the loop keeps the shader small)
            float fr = g;
            a += wxcols(o, d, min(rl, lerp(700.0 - 100.0 * sn, 2400.0 - 600.0 * sn, fr)), lerp(30.0 - 2.0 * sn, 140.0 - 30.0 * sn, fr), t, f, sn, fr) * (1.0 - 0.4 * fr);
        }
        float3 dc = sn > 0.5 ? float3(0.95, 0.97, 1.0) * (0.45 + 0.55 * lite) : float3(0.85, 0.88, 0.95) * (0.45 + 0.55 * lite) + fl * 0.4;
        c = lerp(c, dc, saturate(a) * (sn > 0.5 ? 0.45 + 0.45 * amt : 0.12 + 0.4 * amt + 0.1 * storm));
    }
    return float4(c, 1);
}
)HLSL";

static IDirect3DVertexShader9* g_vs = nullptr;
static IDirect3DPixelShader9 *g_psFxaa = nullptr, *g_psBright = nullptr, *g_psDown = nullptr, *g_psBlur = nullptr, *g_psScene = nullptr,
                             *g_psLook = nullptr, *g_psScreen = nullptr, *g_psGalaxy = nullptr,
                             *g_psAO = nullptr, *g_psAOBlur = nullptr, *g_psSky = nullptr,
                             *g_psSkyN[10] = {},  // skies 5-14, one small shader each (optional: a missing one shows the milky way)
                             *g_psWeather = nullptr, *g_psFireworks = nullptr, *g_psLamps = nullptr, *g_psBulbs = nullptr, *g_psWindow = nullptr, *g_psWinComp = nullptr, *g_psBHalo = nullptr, *g_psBPool = nullptr, *g_psMoon = nullptr, *g_psWinVis = nullptr, *g_psLampCur = nullptr, *g_psLampProbe = nullptr, *g_psBTile = nullptr,  // optional too
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

static IDirect3DTexture9* g_winTex = nullptr;  // lit windows layer (back buffer size)
static IDirect3DSurface9* g_winSurf = nullptr;
static UINT g_winW = 0, g_winH = 0;
static bool g_winDepth = false;  // the layer is half-float: its alpha holds each window pixel's depth
static DWORD g_winFrame = 0xFFFFFFFF;
static float g_winSlopeMax = 0;  // largest SLOPESCALEDEPTHBIAS seen on a window draw (the composite allows for it)
static int g_winDraws = 0, g_winDrawsLast = 0;  // window redraws this frame / last frame (logged with the lamp passes)  // g_presents of the frame the layer was cleared in
static void FreeTargets() {
    IUnknown** list[] = {(IUnknown**)&g_texA, (IUnknown**)&g_texB, (IUnknown**)&g_texC, (IUnknown**)&g_texD, (IUnknown**)&g_texE,
                         (IUnknown**)&g_texF, (IUnknown**)&g_texPrev, (IUnknown**)&g_texG, (IUnknown**)&g_texH, (IUnknown**)&g_sb,
                         (IUnknown**)&g_intzSurf, (IUnknown**)&g_intz,
                         (IUnknown**)&g_autoDS, (IUnknown**)&g_winSurf, (IUnknown**)&g_winTex};
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
// The compiler and the cache files are shared with frame generation's startup compile thread (framegen.inc).
static CRITICAL_SECTION* CompileLock() {
    static CRITICAL_SECTION cs;
    static bool init = (InitializeCriticalSection(&cs), true);
    (void)init;
    return &cs;
}
static bool CachedShaderCodeLocked(CompileShader_t compile, const char* fn, const char* prof, std::string& out, std::string& err);
static bool CachedShaderCode(CompileShader_t compile, const char* fn, const char* prof, std::string& out, std::string& err) {
    EnterCriticalSection(CompileLock());
    bool ok = CachedShaderCodeLocked(compile, fn, prof, out, err);
    LeaveCriticalSection(CompileLock());
    return ok;
}
static bool CachedShaderCodeLocked(CompileShader_t compile, const char* fn, const char* prof, std::string& out, std::string& err) {
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
        {"ps_fireworks", &g_psFireworks, "fireworks"}, {"ps_lamps", &g_psLamps, "street lamps"}, {"ps_bulbs", &g_psBulbs, "lamp bulbs"}, {"ps_wincomp", &g_psWinComp, "lit windows"}, {"ps_bhalo", &g_psBHalo, "lamp bulb glow"}, {"ps_bpool", &g_psBPool, "lamp light pools"}, {"ps_moon", &g_psMoon, "moonlight"}, {"ps_winvis", &g_psWinVis, "window light spill"}, {"ps_lampcur", &g_psLampCur, "lamp editor marks"}, {"ps_lampprobe", &g_psLampProbe, "lamp editor cursor probe"}, {"ps_btile", &g_psBTile, "lamp lights by screen tile"}, {"ps_mirror", &g_psMirror, "mirror picture"},
        {"ps_nighttint", &g_psNightTint, "night tint"}, {"ps_groundmist", &g_psGroundMist, "ground mist"}};
    for (auto& o : optional)
        if (!MakeOneShader(dev, compile, o.fn, "ps_3_0", false, (void**)o.out)) mmenu::Log("gfx: %s unavailable on this card", o.lose);
    if (!MakeOneShader(dev, compile, "ps_window", "ps_2_0", false, (void**)&g_psWindow)) mmenu::Log("gfx: lit windows unavailable on this card");
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

static const RECT* g_passScissor = nullptr;  // lamp bulb passes: the bulb's screen rect (2026-11-22: was full screen)
static void Pass(IDirect3DDevice9* dev, IDirect3DPixelShader9* ps, IDirect3DSurface9* dst, UINT sw, UINT sh, UINT dw, UINT dh,
                 IDirect3DBaseTexture9* t0, IDirect3DBaseTexture9* t1 = nullptr, IDirect3DBaseTexture9* t2 = nullptr, IDirect3DBaseTexture9* t3 = nullptr) {
    if (!ps || !dst) return;  // a shader this card didn't get: skip the pass instead of drawing with none
    dev->SetRenderTarget(0, dst);
    D3DVIEWPORT9 vp = {0, 0, dw, dh, 0, 1};
    dev->SetViewport(&vp);
    if (g_passScissor) dev->SetScissorRect(g_passScissor);  // SetRenderTarget reset it to the whole target
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
// QB's gfx_todnow stays the picked setting only: feeding the server's state back would make dadmod_tod_value
// force that state and then read its own choice back as the server's.
// The sky grade: the picked time of day, or the server's when it is night (4 and up)
static int SkySetting() { int t = V("gfx_tod"); return t ? t : (g_serverTod >= 4 ? g_serverTod : 0); }

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
    WinPollLevel(lv.c_str());
    g_skySeen = false;  // a new level: no sky drawn on it yet (indoor levels never draw one)
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
// lamp bulbs (mods/lamplights): head positions sent by QB per level (THUGRECOMP_LampBulb), game coordinates = D3D world
static std::vector<Lamp> g_bulbs;
static std::vector<float> g_bulbDrop;  // pool center = bulb - drop (height)
static std::vector<char> g_bulbPost;  // per g_bulbs entry: 1 = it belongs to an added lamp post (Extra lamp posts hides it)
static std::vector<Lamp> g_edBulbs;     // lamp editor (dev only): the placed lamps' bulb + pool entries, kept apart from
static std::vector<float> g_edDrop;     // the level's list so editing never has to rebuild it (set by lampeditor.inc)
static std::vector<float> g_edAll;      // the placed lamps for the editor marks: ground x y z, bulb height
static bool g_bulbNight = false;     // evening lights / night / dawn: QB turns the level lamps' engine lights on
static float g_bulbAmt = 0;
static const int kBulbMax = 192;   // drawn in passes of 24 (ps_bulbs loop)
static float g_bulbC[2 + 2 * kBulbMax][4];
static int g_bulbN = 0;
static void WinCacheClear();
static void BulbClear() { g_bulbs.clear(); g_bulbDrop.clear(); g_bulbPost.clear(); g_edBulbs.clear(); g_edDrop.clear(); g_edAll.clear(); WinCacheClear(); }
// lamplights' level hook (2026-11-23): loading = a level load is starting (windows off until the level is known),
// else the level that just loaded (nullptr = the last level SetLevel saw)
static void WinLevelHook(const char* lv, bool loading);
static void BulbAdd(float x, float y, float z, float pool, float drop, float r, float g, float b, bool post = false) {
    if (g_bulbs.size() >= 4096) return;  // 2026-11-23: room for every map getting lamps (was 1024)
    g_bulbDrop.push_back(drop);
    g_bulbPost.resize(g_bulbs.size(), 0);
    g_bulbPost.push_back(post ? 1 : 0);
    Lamp l; l.x = x; l.y = y; l.z = z; l.r = pool; l.cr = r; l.cg = g; l.cb = b;
    g_bulbs.push_back(l);
}
// screen rectangle (pixels) that a sphere covers; false = off screen. Any corner behind the camera = whole screen.
static bool SphereRect(float x, float y, float z, float r, int w, int h, RECT& out) {
    // project the sphere's center; its screen radius is at most r * scale / (depth - r) (tighter than the 8 box corners)
    float p[3] = {x, y, z}, v[4], c[4];
    const D3DMATRIX& m = g_view;
    for (int k = 0; k < 4; ++k) v[k] = p[0] * m.m[0][k] + p[1] * m.m[1][k] + p[2] * m.m[2][k] + m.m[3][k];
    const D3DMATRIX& q = g_proj;
    for (int k = 0; k < 4; ++k) c[k] = v[0] * q.m[0][k] + v[1] * q.m[1][k] + v[2] * q.m[2][k] + v[3] * q.m[3][k];
    if (c[3] + r <= 1.0f) return false;  // wholly behind the camera
    if (c[3] - r <= 1.0f) { out.left = 0; out.top = 0; out.right = w; out.bottom = h; return true; }  // around the camera
    float nx = c[0] / c[3], ny = c[1] / c[3];
    float rx = r * fabsf(q._11) / (c[3] - r), ry = r * fabsf(q._22) / (c[3] - r);
    float x0 = (nx - rx) * 0.5f + 0.5f, x1 = (nx + rx) * 0.5f + 0.5f, y0 = 0.5f - (ny + ry) * 0.5f, y1 = 0.5f - (ny - ry) * 0.5f;
    out.left = x0 <= 0 ? 0 : (LONG)(x0 * w); out.right = x1 >= 1 ? w : (LONG)(x1 * w) + 1;
    out.top = y0 <= 0 ? 0 : (LONG)(y0 * h); out.bottom = y1 >= 1 ? h : (LONG)(y1 * h) + 1;
    return out.right > out.left && out.bottom > out.top;
}
static void UnionRect2(RECT& a, const RECT& b) {
    if (b.left < a.left) a.left = b.left; if (b.top < a.top) a.top = b.top;
    if (b.right > a.right) a.right = b.right; if (b.bottom > a.bottom) a.bottom = b.bottom;
}
// GPU time of the lamp passes (timestamp queries, every few seconds into mainmenu.log; skipped if the card can't)
static IDirect3DQuery9 *g_lqDis = nullptr, *g_lqFreq = nullptr, *g_lqA = nullptr, *g_lqB = nullptr, *g_lqM = nullptr, *g_lqW = nullptr;  // start, after moon, after lamps, after windows
static int g_lqState = 0, g_lqDrawn = 0;
static double g_lqArea = 0, g_lqAreaNow = 0;  // screens of pixels the lamp passes covered
static double g_lqNext = 0;
// 2026-11-22: unreleased queries made the device Reset fail (0x8876086C) and the game crash (frame generation off);
// they are freed before every Reset and on a new device, and made again when the timing next runs
static void LampQueriesFree() {
    IDirect3DQuery9** q[] = {&g_lqDis, &g_lqFreq, &g_lqA, &g_lqB, &g_lqM, &g_lqW};
    for (auto p : q) if (*p) { (*p)->Release(); *p = nullptr; }
    g_lqState = 0;
}
// lamp editor (mods/lampeditor, dev only): a cyan preview lamp at the cursor (shown by day too while it's on), the
// placed lamps' lights, and the marks ps_lampcur draws (cursor beam + ring, an amber beam + ring per placed lamp)
static bool g_bulbCursorOn = false;
static Lamp g_bulbCursor, g_bulbCursorPool;
static float g_edMark[33][4];  // per frame: [0] cursor ground spot + bulb height, [1..] the 32 placed lamps nearest to it
static int g_edMarkN = 0;
static const float kEdAmber[3] = {1.0f, 176 / 255.0f, 80 / 255.0f};
// placed lamps: v = n x (ground x, y, z, bulb height, pool radius, bulb x, y, z); pool center 150 over the ground
// under the bulb (a lamp model's bulb hangs at its arm, not over the base)
// lamp editor lights, v = n x (bulb x y z, pool centre x y z, pool radius, stretch x y z): the stretch (length > 1)
// makes a flood's pool long along its aim (ps_bpool); zero = an ordinary round pool
static void EdLamps10(const float* v, int n, std::vector<Lamp>& bl, std::vector<float>* drop) {
    bl.clear(); if (drop) drop->clear();
    for (int i = 0; i < n; ++i) {
        const float* l = v + i * 10;
        bl.push_back(Lamp{l[0], l[1], l[2], 0, kEdAmber[0], kEdAmber[1], kEdAmber[2]});
        bl.push_back(Lamp{l[3], l[4], l[5], l[6], l[7], l[8], l[9]});
        if (drop) { drop->push_back(0); drop->push_back(0); }
    }
}
static std::vector<Lamp> g_curLamps;  // the cursor lamp's lights (every head, floods aimed), drawn instead of g_bulbCursor
static void EdLampsSet(const float* v, int n) { g_edAll.clear(); EdLamps10(v, n, g_edBulbs, &g_edDrop); }
static void CursorLamps(const float* v, int n) {
    EdLamps10(v, n, g_curLamps, nullptr);
    for (size_t i = 0; i + 1 < g_curLamps.size(); i += 2) { g_curLamps[i].cr = 0.5f; g_curLamps[i].cg = 0.9f; g_curLamps[i].cb = 1.0f; }
}
static void EdLamps(const float* v, int n) {
    g_edBulbs.clear(); g_edDrop.clear(); g_edAll.clear();
    for (int i = 0; i < n; ++i) {
        const float* l = v + i * 8;
        g_edBulbs.push_back(Lamp{l[5], l[6], l[7], 0, kEdAmber[0], kEdAmber[1], kEdAmber[2]}); g_edDrop.push_back(0);
        g_edBulbs.push_back(Lamp{l[5], l[1] + 150, l[7], l[4], 0, 0, 0}); g_edDrop.push_back(0);
        for (int k = 0; k < 4; ++k) g_edAll.push_back(l[k]);
    }
}
// bulb = the bulb's spot (else over the cursor at height h); beam = 0: only the ground ring (a lamp model is shown)
static void BulbCursor(bool on, float x, float ground, float z, float h, float pool, const float* bulb = nullptr, bool beam = true) {
    g_bulbCursorOn = on;
    g_edMark[0][0] = x; g_edMark[0][1] = ground; g_edMark[0][2] = z; g_edMark[0][3] = beam ? h : 0;
    float bx = bulb ? bulb[0] : x, by = bulb ? bulb[1] : ground + h, bz = bulb ? bulb[2] : z;
    g_bulbCursor = Lamp{bx, by, bz, 0, 0.5f, 0.9f, 1.0f};
    g_bulbCursorPool = Lamp{bx, ground + (bulb && beam ? h : 0) + 150, bz, pool, 0, 0, 0};  // a raised / lowered model lamp: the pool follows its base
}
// the cursor lamp's other heads (a two-headed model: Noah 2026-11-23 saw one head lit and the other doubled once
// placed): bulb + pool for each, v = n x (x y z), pool centre 150 over poolY
static std::vector<Lamp> g_curExtra;
static void BulbCursorExtra(const float* v, int n, float poolY, float pool) {
    g_curExtra.clear();
    for (int i = 0; i < n; ++i) {
        g_curExtra.push_back(Lamp{v[i * 3], v[i * 3 + 1], v[i * 3 + 2], 0, 0.5f, 0.9f, 1.0f});
        g_curExtra.push_back(Lamp{v[i * 3], poolY + 150, v[i * 3 + 2], pool, 0, 0, 0});
    }
}
// lamp models (mods/lampeditor/lampmodels.inc, dev build only): drawn at the end of the 3D scene, the editor's
// preview after the HUD, their state block let go before a device reset
static void (*g_lmScene)(IDirect3DDevice9*) = nullptr;
static void (*g_lmFrameEnd)(IDirect3DDevice9*) = nullptr;
static void (*g_lmFree)() = nullptr;
// the lamp editor's cursor spot: the world point at the screen's middle, read back from a 1x1 float target each frame
static IDirect3DTexture9* g_probeTex = nullptr;
static IDirect3DSurface9 *g_probeRT = nullptr, *g_probeSys = nullptr;
static float g_probe[4] = {0, 0, 0, 0};  // x y z, w = 1 valid
static DWORD g_probeTick = 0;           // GetTickCount of the last good read
static void LampProbeFree() {
    if (g_probeRT) { g_probeRT->Release(); g_probeRT = nullptr; }
    if (g_probeTex) { g_probeTex->Release(); g_probeTex = nullptr; }
    if (g_probeSys) { g_probeSys->Release(); g_probeSys = nullptr; }
}
static void LampProbe(IDirect3DDevice9* dev) {
    if (!g_psLampProbe || !g_intz) return;
    if (!g_probeTex) {
        if (FAILED(dev->CreateTexture(1, 1, 1, D3DUSAGE_RENDERTARGET, D3DFMT_A32B32G32R32F, D3DPOOL_DEFAULT, &g_probeTex, nullptr))) {
            g_probeTex = nullptr; return;
        }
        if (FAILED(g_probeTex->GetSurfaceLevel(0, &g_probeRT)) ||
            FAILED(dev->CreateOffscreenPlainSurface(1, 1, D3DFMT_A32B32G32R32F, D3DPOOL_SYSTEMMEM, &g_probeSys, nullptr))) {
            LampProbeFree(); return;
        }
    }
    float off[4] = {4.0f / g_w, 4.0f / g_h, 0, 0};  // neighbours 4 pixels away (the floor check)
    dev->SetPixelShaderConstantF(28, off, 1);
    Pass(dev, g_psLampProbe, g_probeRT, g_w, g_h, 1, 1, nullptr, g_intz);
    D3DLOCKED_RECT lr;
    if (SUCCEEDED(dev->GetRenderTargetData(g_probeRT, g_probeSys)) && SUCCEEDED(g_probeSys->LockRect(&lr, nullptr, D3DLOCK_READONLY))) {
        const float* f = (const float*)lr.pBits;
        float d0 = f[0];
        bool floor_ = f[1] > 0.5f;
        g_probeSys->UnlockRect();
        // 2026-11-23 (Noah: after zooming the lamp left the ground): the shaders' quick reconstruction assumes a
        // centred projection and drifted with distance (64 units at 900 away); here the screen's middle at depth d0
        // goes back through the inverse of the exact view x projection the scene used
        float vp[4][4], inv[4][4];
        for (int r = 0; r < 4; ++r) for (int c = 0; c < 4; ++c) {
            float a = 0;
            for (int k = 0; k < 4; ++k) a += g_view.m[r][k] * g_proj.m[k][c];
            vp[r][c] = a;
        }
        bool ok = floor_ && d0 == d0 && d0 < 0.99999f;
        {   // Gauss-Jordan inverse
            float a[4][8];
            for (int r = 0; r < 4; ++r) for (int c = 0; c < 8; ++c) a[r][c] = c < 4 ? vp[r][c] : (c - 4 == r ? 1.0f : 0.0f);
            for (int c = 0; c < 4 && ok; ++c) {
                int piv = c;
                for (int r = c + 1; r < 4; ++r) if (fabsf(a[r][c]) > fabsf(a[piv][c])) piv = r;
                if (fabsf(a[piv][c]) < 1e-12f) { ok = false; break; }
                if (piv != c) for (int k = 0; k < 8; ++k) { float t = a[c][k]; a[c][k] = a[piv][k]; a[piv][k] = t; }
                float d = a[c][c];
                for (int k = 0; k < 8; ++k) a[c][k] /= d;
                for (int r = 0; r < 4; ++r) if (r != c) { float m = a[r][c]; for (int k = 0; k < 8; ++k) a[r][k] -= m * a[c][k]; }
            }
            for (int r = 0; r < 4; ++r) for (int c = 0; c < 4; ++c) inv[r][c] = a[r][c + 4];
        }
        if (ok) {
            float q[4] = {0, 0, d0, 1}, w[4];
            for (int c = 0; c < 4; ++c) w[c] = q[0] * inv[0][c] + q[1] * inv[1][c] + q[2] * inv[2][c] + q[3] * inv[3][c];
            if (fabsf(w[3]) > 1e-9f) {
                float x = w[0] / w[3], y = w[1] / w[3], z = w[2] / w[3];
                if (fabsf(x) < 1e6f && fabsf(y) < 1e6f && fabsf(z) < 1e6f) {
                    g_probe[0] = x; g_probe[1] = y; g_probe[2] = z; g_probe[3] = 1; g_probeTick = GetTickCount();
                }
            }
        }
    }
}
static void EdPickMarks() {  // the 32 placed lamps nearest to the cursor get marks
    static std::vector<std::pair<float, int>> nb;
    nb.clear();
    for (size_t i = 0; i + 3 < g_edAll.size(); i += 4) {
        float dx = g_edAll[i] - g_edMark[0][0], dz = g_edAll[i + 2] - g_edMark[0][2];
        nb.push_back(std::make_pair(dx * dx + dz * dz, (int)i));
    }
    if (nb.size() > 32) { std::partial_sort(nb.begin(), nb.begin() + 32, nb.end()); nb.resize(32); }
    for (size_t j = 0; j < nb.size(); ++j) for (int k = 0; k < 4; ++k) g_edMark[1 + j][k] = g_edAll[nb[j].second + k];
    g_edMarkN = (int)nb.size();
}
static bool BulbsOn() { return g_bulbAmt > 0.01f && g_bulbN > 0 && V("gfx_lampbulbs") && g_psBHalo && g_psBPool; }
// ---- map lighting (2026-11-22, Noah: "dark skies light the map"): one look for the scene tint (NightTint), the dark
// lift, lamps/bulbs/windows, light level and fog/mist color. A picked time of day wins as before. On Level / server the
// DARKER of the server's time and the replacement sky's lighting is used: space skies light the map like Night,
// synthwave and hellfire like Evening lights, storm and underwater like a dim Evening; the bright skies, Sky Off, the
// main menu, levels where no sky drew (indoor) and cards without the sky shader change nothing. When the time of day
// wins under storm, underwater or hellfire, the tint keeps that sky's color at the time's strength. Local only: the
// game's own time of day (gfx_todnow / Kali) and other players are untouched. The skies themselves are as 0.10.1.
static bool g_lookSnap = false;  // the player just changed Sky or Time of day: lift, lamps and tint fade in ~0.3 s, not ~3 s
struct MapLook { float tint[3]; float lift; int lampTod; float lite; float fog[3]; float night, dawn; };
static MapLook g_mapLook = {{1, 1, 1}, 0, 0, 1, {0.62f, 0.66f, 0.72f}, 0, 0};
// 0-6 = the time of day looks (as before); 7 storm, 8 underwater, 9 hellfire, 10 synthwave: a dark sky on a lit level
static const MapLook kLooks[11] = {
    {{1, 1, 1}, 0, 0, 1, {0.62f, 0.66f, 0.72f}, 0, 0},
    {{1, 1, 1}, 0, 1, 0.85f, {0.78f, 0.72f, 0.68f}, 0, 0},
    {{1, 1, 1}, 0, 2, 1, {0.68f, 0.72f, 0.78f}, 0, 0},
    {{1, 1, 1}, 0, 3, 0.7f, {0.62f, 0.58f, 0.56f}, 0, 0},
    {{0.22f, 0.26f, 0.40f}, 0.4f, 4, 0.3f, {0.10f, 0.12f, 0.18f}, 1, 0},
    {{0.92f, 0.86f, 0.90f}, 0.15f, 5, 0.45f, {0.30f, 0.24f, 0.30f}, 1, 0},
    {{0.40f, 0.40f, 0.52f}, 0.3f, 6, 0.4f, {0.17f, 0.16f, 0.20f}, 0, 1},  // dawn: cold blue-pink (0.42, 0.40, 0.50) x light 0.4
    {{0.68f, 0.68f, 0.70f}, 0, 0, 0.7f, {0.55f, 0.57f, 0.60f}, 0, 0},     // storm: dim grey daylight, lamps off
    {{0.52f, 0.68f, 0.78f}, 0, 0, 0.7f, {0.30f, 0.50f, 0.58f}, 0, 0},     // underwater: dim blue, lamps off
    {{0.80f, 0.56f, 0.48f}, 0.15f, 5, 0.45f, {0.40f, 0.22f, 0.16f}, 1, 0}, // hellfire: evening lights, red
    {{0.74f, 0.66f, 0.72f}, 0.15f, 5, 0.45f, {0.30f, 0.24f, 0.30f}, 1, 0}, // synthwave: evening lights on a lit level
};
static int LookRank(int i) {  // darkness: day / level's own, morning, evening (storm, underwater), evening lights, dawn, night
    static const int r[11] = {0, 1, 0, 2, 5, 3, 4, 2, 2, 3, 3};
    return i >= 0 && i < 11 ? r[i] : 0;
}
static int SkyLook() {  // the look a replacement sky gives the map, -1 = none
    switch (V("gfx_galaxy")) {
        case 1: case 2: case 3: case 4: case 5: case 13: return 4;
        case 6: return 10;
        case 7: return 7;
        case 10: return 9;
        case 11: return 8;
    }
    return -1;
}
static const MapLook& MapLookNow(float dt) {
    int tod = TodSetting();
    if (tod < 0 || tod > 6) tod = 0;
    MapLook want = kLooks[tod];
    int sky = V("gfx_tod") == 0 && !g_mainMenu && GalaxyOn() && g_skySeen ? SkyLook() : -1;
    if (sky >= 0) {
        if (LookRank(sky) > LookRank(tod)) want = kLooks[sky];
        else if (sky >= 7 && sky <= 9) {  // the time wins: keep the sky's color at its strength
            const float* h = kLooks[sky].tint;
            float hl = h[0] * 0.299f + h[1] * 0.587f + h[2] * 0.114f;
            float tl = want.tint[0] * 0.299f + want.tint[1] * 0.587f + want.tint[2] * 0.114f;
            for (int k = 0; k < 3; ++k) { float v = tl * h[k] / hl; want.tint[k] = v > 1 ? 1 : v; }
        }
    }
    static bool first = true;
    static int lastSky = -2, lastTod = -2;
    int skyNow = V("gfx_galaxy"), todNow = V("gfx_tod");
    // Noah 2026-11-22: the player's own Sky or Time of day change relights the map at once; only a server/level time
    // change (g_serverTod mid-game) still eases in
    static double fastUntil = 0;  // Noah: "or maybe make the fade super fast"
    if (!first && (skyNow != lastSky || todNow != lastTod)) fastUntil = NowS() + 0.6;
    g_lookSnap = NowS() < fastUntil;
    lastSky = skyNow; lastTod = todNow;
    MapLook& m = g_mapLook;
    m.lift = want.lift; m.lampTod = want.lampTod;  // the lift and the lamps fade on their own (faster with g_lookSnap)
    float f = first ? 1.0f : (dt / (g_lookSnap ? 0.3f : 3.0f) > 1 ? 1 : dt / (g_lookSnap ? 0.3f : 3.0f));  // about 3 s from one look to the next (0.3 s for the player's own change)
    first = false;
    auto ease = [f](float& v, float to) { float d = to - v; v = fabsf(d) <= f ? to : v + (d > 0 ? f : -f); };
    for (int k = 0; k < 3; ++k) { ease(m.tint[k], want.tint[k]); ease(m.fog[k], want.fog[k]); }
    ease(m.lite, want.lite); ease(m.night, want.night); ease(m.dawn, want.dawn);
    return m;
}
static void UpdateBulbs(int todA, int todB, float blend, float dt) {
    auto w = [](int t) { return t == 4 || t == 5 || t == 6 ? 1.0f : t == 3 ? 0.25f : 0.0f; };
    float want = g_mainMenu ? 0.0f : w(todA) + (w(todB) - w(todA)) * blend;
    g_bulbNight = want > 0.5f;
    if (!V("gfx_lamplights")) want = 0.0f;  // Lamp lights Off: nothing to draw, the passes stop (BulbsOn)
    if (g_bulbCursorOn) want = 1.0f;  // lamp editor open: preview by day too
    bool postsOn = V("gfx_lampposts") != 0;
    struct EdPush {  // the editor's placed lamps and its cursor lamp (bulb + pool) join the list for this update only
        size_t n0;
        EdPush() : n0(g_bulbs.size()) {
            if (V("gfx_lampposts")) {  // the editor's placed lamps are extra posts too
                g_bulbs.insert(g_bulbs.end(), g_edBulbs.begin(), g_edBulbs.end());
                g_bulbDrop.insert(g_bulbDrop.end(), g_edDrop.begin(), g_edDrop.end());
            }
            if (g_bulbCursorOn) {
                if (g_curLamps.empty()) { g_bulbs.push_back(g_bulbCursor); g_bulbs.push_back(g_bulbCursorPool); g_bulbDrop.push_back(0); g_bulbDrop.push_back(0); }
                for (const auto& e : g_curLamps) { g_bulbs.push_back(e); g_bulbDrop.push_back(0); }
            }
        }
        ~EdPush() { g_bulbs.resize(n0); g_bulbDrop.resize(n0); }
    } edPush;
    float step = dt / 3.0f + 0.0001f;
    if (g_lookSnap) step = dt / 0.3f + 0.0001f;
    g_bulbAmt = g_bulbAmt < want ? (g_bulbAmt + step > want ? want : g_bulbAmt + step) : (g_bulbAmt - step < want ? want : g_bulbAmt - step);
    g_bulbN = 0;
    if (g_bulbAmt <= 0.01f || g_bulbs.empty()) return;
    const D3DMATRIX& m = g_view;
    float cx = -(m._41 * m._11 + m._42 * m._12 + m._43 * m._13);
    float cy = -(m._41 * m._21 + m._42 * m._22 + m._43 * m._23);
    float cz = -(m._41 * m._31 + m._42 * m._32 + m._43 * m._33);
    // every bulb within 20000 (nearest first, up to kBulbMax): the glow never cuts off while a lamp is in sight
    static std::vector<std::pair<float, int>> bnear;
    bnear.clear();
    for (size_t i = 0; i < g_bulbs.size(); ++i) {
        if (!postsOn && i < g_bulbPost.size() && g_bulbPost[i]) continue;  // Extra lamp posts: Hide
        const Lamp& l = g_bulbs[i];
        float d = (l.x - cx) * (l.x - cx) + (l.y - cy) * (l.y - cy) + (l.z - cz) * (l.z - cz);
        if (d < 20000.0f * 20000.0f) bnear.push_back(std::make_pair(d, (int)i));
    }
    if ((int)bnear.size() > kBulbMax) {
        std::partial_sort(bnear.begin(), bnear.begin() + kBulbMax, bnear.end());
        bnear.resize(kBulbMax);
    }
    g_bulbN = (int)bnear.size();
    g_bulbC[0][0] = g_bulbAmt; g_bulbC[0][1] = (float)g_bulbN; g_bulbC[0][2] = V("gfx_lampstr") / 10.0f; g_bulbC[0][3] = V("gfx_lamplift") / 100.0f;
    g_bulbC[1][0] = cx; g_bulbC[1][1] = cy; g_bulbC[1][2] = cz; g_bulbC[1][3] = V("gfx_bulbsize") / 10.0f;
    for (int i = 0; i < g_bulbN; ++i) {
        int bi = bnear[i].second;
        const Lamp& l = g_bulbs[bi];
        float* a = g_bulbC[2 + i * 2];
        float* c = g_bulbC[3 + i * 2];
        float dist = sqrtf(bnear[i].first);
        float poolFade = dist < 6000.0f ? 1.0f : dist > 9000.0f ? 0.0f : (9000.0f - dist) / 3000.0f;  // far pools shrink away
        a[0] = l.x; a[1] = l.y; a[2] = l.z; a[3] = g_bulbDrop[bi];
        float bs = V("gfx_bulbstr") / 10.0f;  // the halo uses the color, the pool its own amber
        c[0] = l.cr * bs; c[1] = l.cg * bs; c[2] = l.cb * bs; c[3] = l.r * V("gfx_lamppool") / 10.0f * poolFade;
        if (l.r > 0) { c[0] = l.cr; c[1] = l.cg; c[2] = l.cb; }  // a pool's colour slots hold its flood stretch, unscaled
    }
}
// lamps light up in the evening and at night (a little at sunset); picks the 24 nearest to the camera
// Noah 2026-10-20: lamps fade on/off instead of popping: the glow eases toward its target over ~4 s.
static void UpdateLamps(int todA, int todB, float blend, float dt) {
    auto w = [](int t) { return t == 4 || t == 5 || t == 6 ? 1.0f : t == 3 ? 0.25f : 0.0f; };  // 6 dawn: lights still on
    float want = (w(todA) + (w(todB) - w(todA)) * blend) * V("gfx_lamps") / 6.0f;
    static float shown = -1.0f;
    if (shown < 0) shown = want;  // first frame: no fade
    float step = dt / (g_lookSnap ? 0.3f : 4.0f) + 0.0001f;  // 2026-11-22: was scaled by gfx_lamps, so with 0 it took minutes to fade out; 0.3 s for the player's own change
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
    const MapLook& look = MapLookNow(dt);
    {   // Night (Noah 2026-10-12: "night mode is waaaay too dark"): ease the dark lift in/out over ~3 s
        // 2026-11-22: also on the server's night (shibe's dark Chicago: tint without the lift), and under a dark sky (MapLookNow)
        float want = look.lift;  // night 0.4, dawn 0.3, evening lights 0.15
        float step = dt / 3.0f * 0.4f;
        if (g_lookSnap) step = dt / 0.3f * 0.4f;
        g_nightLift = g_nightLift < want ? (g_nightLift + step > want ? want : g_nightLift + step)
                                         : (g_nightLift - step < want ? want : g_nightLift - step);
    }
    static double hitchLog = 0;  // frame stalls (e.g. while the lighting fades) go to the log, at most once a second
    if (last && now - last > 0.1 && now - hitchLog > 1.0) { hitchLog = now; mmenu::Log("gfx: slow frame %d ms", (int)((now - last) * 1000)); }
    last = now;

    // time of day: a fixed look (the Dynamic cycle was removed 2026-11-21; 6 is now dawn)
    // 2026-11-22: on "Level / server" the server's state counts too (lamps, light level, fog color); the sky grade
    // follows the server only at night (SkySetting), so a server day keeps the game's own sky as before
    int tod = TodSetting();
    int a = tod, b = tod;
    float blend = 0;
    int st = SkySetting();
    g_sky[0] = (float)st; g_sky[1] = V("gfx_skypop") / 10.0f; g_sky[2] = (float)st; g_sky[3] = blend;
    (void)a; (void)b; (void)blend;
    UpdateLamps(look.lampTod, look.lampTod, 0, dt);  // lamps follow the server and dark skies too (they fade on their own)
    UpdateBulbs(look.lampTod, look.lampTod, 0, dt);
    float lite = look.lite;  // light level and fog color: faded in MapLookNow
    for (int k = 0; k < 3; ++k) g_wx[2][k] = look.fog[k];
    g_wx[2][3] = 1;

    // weather (2026-11-23 rework): 0 off, 1 rain, 2 thunderstorm, 3 snow, 4 fog, 5 Random (a new pick every 3-6
    // minutes from clear, rain, storm, snow and fog). One Intensity (gfx_wxamt 1-10) drives every kind, fog included.
    // The kind shown now goes to gfx_wxnow, which the QB side reads to run the game's own weather (splashes, far drops).
    int w = V("gfx_weather"), type = w;
    if (w == 5) {
        if (now >= g_dynNext) {
            static const int weights[5] = {35, 20, 10, 12, 10};  // clear, rain, storm, snow, fog
            int r = rand() % (35 + 20 + 10 + 12 + 10), pick = 0;
            while (r >= weights[pick]) r -= weights[pick++];
            g_dynType = pick;
            g_dynNext = now + 180 + rand() % 180;
            static const char* kNames[] = {"clear", "rain", "storm", "snow", "fog"};
            mmenu::Log("gfx: random weather -> %s", kNames[pick]);
        }
        type = g_dynType;
    } else g_dynNext = 0;
    int srv = V("gfx_wxsrv");  // a server ?rain / ?storm / ?snow / ?blizzard wins (the game runs its drops; we match the look)
    if (srv > 0) type = srv == 4 ? 3 : srv;
    if (g_mainMenu) type = 0;
    { int iw = Index("gfx_wxnow"); if (iw >= 0) g_val[iw] = srv > 0 ? 0 : type; }
    int I = V("gfx_wxamt");
    float A = I / 10.0f, target[4] = {}, mist = 0;
    if (srv > 0) { static const float kSrv[5] = {0, 0.6f, 0.7f, 0.5f, 0.95f}; A = kSrv[srv]; }
    switch (type) {
        case 1: target[0] = A; mist = 0.25f; break;
        case 2: target[0] = 0.2f + 0.8f * A; target[3] = 1; mist = 0.35f; break;
        case 3: target[1] = A; mist = 0.4f; break;
        case 4: mist = 1; break;
    }
    // one kind at a time: rain and snow cross-fade through clear (Random can jump straight from one to the other)
    if (target[1] > 0 && (g_wxCur[0] > 0.02f || g_wxCur[3] > 0.02f)) target[1] = 0;
    if ((target[0] > 0 || target[3] > 0) && g_wxCur[1] > 0.02f) { target[0] = 0; target[3] = 0; }
    float step = dt / 12.0f;  // a full change takes about 12 seconds
    for (int k = 0; k < 4; ++k) {
        float d = target[k] - g_wxCur[k];
        float sk = target[k] > 0 && g_wxCur[k] > 0.02f ? dt : step;  // same kind, new Intensity: about 1 s (a new kind still fades in 12 s)
        g_wxCur[k] += d > sk ? sk : d < -sk ? -sk : d;
        g_wx[0][k] = g_wxCur[k];
    }
    { float d = mist - g_wxMist; g_wxMist += d > step ? step : d < -step ? -step : d; }
    // lightning: random gaps (heavier storms strike more often), a double flicker, and a bolt somewhere in the sky
    static double strike = 0, nextStrike = 0;
    static float boltAz = 0;
    if (g_wxCur[3] > 0.3f) {
        if (!nextStrike) nextStrike = now + 4 + Rnd() * 6;
        if (now >= nextStrike) {
            strike = now;
            float fx = -g_view._13, fz = -g_view._33;  // somewhere in front of the camera, mostly
            boltAz = atan2f(fx, fz) + (Rnd() - 0.5f) * 2.2f;
            float gap = 26.0f - 1.8f * I;  // Intensity 1: about 24 s apart .. 10: about 8 s
            nextStrike = now + gap * (0.6 + Rnd() * 0.8);
        }
    } else nextStrike = 0;
    float ph = (float)(now - strike), flash = 0;
    if (strike && ph < 1.0f) flash = (expf(-ph * 9.0f) + 0.6f * expf(-fabsf(ph - 0.22f) * 25.0f)) * g_wxCur[3];
    bool stormSky = GalaxyOn() && V("gfx_galaxy") == 7;  // the Storm sky flashes on its own beat: the weather follows it
    if (stormSky) flash = 0;
    g_wx[0][2] = flash;
    g_wx[1][0] = lite; g_wx[1][1] = boltAz; g_wx[1][2] = 1; g_wx[1][3] = stormSky ? 1.0f : 0.0f;

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
    int lv = 2;  // head high (2026-11-23: the height choice went with the Fog row; Fog weather uses head high)
    const D3DMATRIX& m = g_view;
    float camY = -(m._41 * m._21 + m._42 * m._22 + m._43 * m._23);
    float ground = MistFloor(camY);
    // Fog intensity: 6 = the original thickness, default 5; above 6 it climbs fast (Noah 2026-11-21: "10 needs to be much
    // more dense", then "even the scale out"): every step is 1.75x the one before: 1 = 0.06x, 4 = 0.33x, 6 = 1x, 8 = 3.1x, 10 = 9.4x;
    // the mist may cover more above 6 (cap 0.92 at 6 .. 0.985 at 10)
    int fa = V("gfx_wxamt");  // the weather Intensity (2026-11-23)
    if (V("gfx_wxnow") != 4 && fa > 6) fa = 6;  // rain / storm / snow add a light mist: only Fog gets the very thick top end
    float amt = powf(1.75f, (float)(fa - 6)) * g_wxMist;
    float cap = fa <= 6 ? 0.92f : 0.92f + (fa - 6) * 0.01625f;
    out[0][0] = kD[lv] * amt; out[0][1] = kHs[lv]; out[0][2] = ground; out[0][3] = cap;
    // color: the time of day fog color; at Night / Evening lights a dark blue-gray scaled by the light level
    float night = g_mapLook.night, dawn = g_mapLook.dawn;  // night / evening lights, dawn (MapLookNow, faded)
    static const float kNight[3] = {0.30f, 0.34f, 0.44f}, kDawn[3] = {0.42f, 0.40f, 0.50f};
    float lite = g_wx[1][0] > 0 ? g_wx[1][0] : 1.0f;
    for (int i = 0; i < 3; ++i) out[1][i] = g_wx[2][i] + (kNight[i] * lite - g_wx[2][i]) * night + (kDawn[i] * lite - g_wx[2][i]) * dawn;
    out[1][3] = 1;
}

static void NightTint(IDirect3DDevice9* dev, IDirect3DSurface9* bb) {
    if (g_mainMenu || g_inPost) return;
    const float* tn = g_mapLook.tint;  // the map tint now (time of day or a dark sky, faded; MapLookNow)
    if (tn[0] > 0.999f && tn[1] > 0.999f && tn[2] > 0.999f) return;
    float k[4] = {g_sky[0], g_sky[1], g_sky[2], g_sky[3]};
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
    float keep[4] = {(float)g_keepLit, 0, 0, 0};
    dev->SetPixelShaderConstantF(17, keep, 1);  // ps_nighttint reads c17 (wx) .x as keep lit; the weather pass sets its own c17
    float tint[4] = {tn[0], tn[1], tn[2], 1};
    dev->SetPixelShaderConstantF(18, tint, 1);  // and c18 (wx2) .rgb as the tint (2026-11-22)
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

static void FgCaptureScene(IDirect3DDevice9* dev);  // framegen.inc
static bool g_fgRunning = false;      // frame generation is running (framegen.inc): dadmod's motion blur stays off
static bool g_fgBbGenerated = false;  // the back buffer holds a generated in-between frame: screenshots wait for a real one
static void RunScene(IDirect3DDevice9* dev, bool atPresent = false) {
    if (!atPresent) {  // only when the screen itself is being drawn to (not an offscreen texture)
        IDirect3DSurface9* t = nullptr;
        if (!BackBufferIsTarget(dev, &t)) return;
        t->Release();
    }
    g_sceneDone = true;
    if (g_lmScene) g_lmScene(dev);  // lamp models (dev build): part of the 3D scene, before the night tint
    struct FgAfterScene { IDirect3DDevice9* d; ~FgAfterScene() { FgCaptureScene(d); } } fgAfter = {dev};  // frame generation keeps the finished 3D picture (every return below)
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
        if (!g_prevValid || g_fgRunning) { g_c[8][1] = 0; dev->SetPixelShaderConstantF(8, g_c[8], 1); }  // frame generation already blends frames
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
        if (!once) { once = true; mmenu::Log("gfx: ground mist on 3D scene (weather %d)", V("gfx_wxnow")); }
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
    bool timing = false;  // GPU time of moonlight / lamps / windows, every 5 s into mainmenu.log
    {
        static IDirect3DDevice9* lqDev = nullptr;
        if (lqDev != dev) { lqDev = dev; LampQueriesFree(); }  // new device: let go of the old one's queries
        if (g_lqState == 0 && NowS() > g_lqNext && (MoonOn() || BulbsOn() || WinLayerReady())) {
            if (!g_lqDis && FAILED(dev->CreateQuery(D3DQUERYTYPE_TIMESTAMPDISJOINT, &g_lqDis))) g_lqState = 9;
            if (g_lqState == 0 && !g_lqFreq && FAILED(dev->CreateQuery(D3DQUERYTYPE_TIMESTAMPFREQ, &g_lqFreq))) g_lqState = 9;
            IDirect3DQuery9** ts[] = {&g_lqA, &g_lqM, &g_lqB, &g_lqW};
            for (auto q : ts) if (g_lqState == 0 && !*q && FAILED(dev->CreateQuery(D3DQUERYTYPE_TIMESTAMP, q))) g_lqState = 9;
            if (g_lqState == 0) { timing = true; g_lqDis->Issue(D3DISSUE_BEGIN); g_lqA->Issue(D3DISSUE_END); g_lqDrawn = 0; g_lqArea = 0; }
        }
    }
    if (MoonOn() && g_intzUsed && !g_msaaOn) {  // moonlight, before the lamps
        float az = V("gfx_moonaz") * 3.14159265f / 180.0f, el = 0.70f;
        float hdr[4] = {g_bulbAmt * V("gfx_moonlight") / 20.0f, 0, 0, 0};
        float dir[4] = {cosf(el) * sinf(az), sinf(el), cosf(el) * cosf(az), 0};
        float cam[4] = {g_bulbC[1][0], g_bulbC[1][1], g_bulbC[1][2], 1};
        const D3DMATRIX& m = g_view;
        cam[0] = -(m._41 * m._11 + m._42 * m._12 + m._43 * m._13); cam[1] = -(m._41 * m._21 + m._42 * m._22 + m._43 * m._23);
        cam[2] = -(m._41 * m._31 + m._42 * m._32 + m._43 * m._33);
        dev->SetPixelShaderConstantF(28, hdr, 1);
        dev->SetPixelShaderConstantF(29, cam, 1);
        dev->SetPixelShaderConstantF(30, dir, 1);
        IDirect3DTexture9* dst = cur == g_texA ? g_texB : g_texA;
        Pass(dev, g_psMoon, cur == g_texA ? sB : sA, g_w, g_h, g_w, g_h, cur, g_intz);
        cur = dst;
    }
    if (timing) g_lqM->Issue(D3DISSUE_END);
    if (BulbsOn() && g_psBulbs && g_intzUsed && !g_msaaOn) {
        static bool once = false;
        if (!once) { once = true; mmenu::Log("gfx: lamp bulbs on 3D scene (%d near)", g_bulbN); }
        // one bulb per pass, only inside the screen rectangle its glow and pool can touch (scissor);
        // src always holds the whole picture: each pass writes dst inside the rectangle, then that rectangle is copied back
        IDirect3DTexture9* srcT = cur;
        IDirect3DTexture9* dstT = cur == g_texA ? g_texB : g_texA;
        IDirect3DSurface9* srcS = cur == g_texA ? sA : sB;
        IDirect3DSurface9* dstS = cur == g_texA ? sB : sA;
        int drawn = 0;
        double area = 0;
        float hdr[4] = {g_bulbC[0][0], 1.0f, g_bulbC[0][2], g_bulbC[0][3]};
        dev->SetPixelShaderConstantF(28, hdr, 1);
        dev->SetPixelShaderConstantF(29, g_bulbC[1], 1);
        // 2026-11-23 speed review: one pass per screen tile with every entry touching it (ps_btile), instead of one
        // pass + copy-back per entry (35-160 a frame, 15-30 screens of pixels). Same maths, same order per pixel.
        // gfx_lamptiles 0 (or a card without ps_btile) = the old per-entry path below.
        bool tiled = g_psBTile && V("gfx_lamptiles");
        if (tiled) {
            const int TX = 8, TY = 6;
            static std::vector<int> bin[TX * TY];
            static std::vector<RECT> erect;
            for (auto& b : bin) b.clear();
            erect.assign(g_bulbN, RECT{0, 0, 0, 0});
            for (int i = 0; i < g_bulbN; ++i) {
                const float* a = g_bulbC[2 + i * 2];
                const float* c = g_bulbC[3 + i * 2];
                float dx = a[0] - g_bulbC[1][0], dy = a[1] - g_bulbC[1][1], dz = a[2] - g_bulbC[1][2];
                float tl = sqrtf(dx * dx + dy * dy + dz * dz), fs = 1 + tl * 0.0015f;
                float hr = (2.2f * sqrtf((1250.0f + 40.0f) * fs) + 2.2f * sqrtf(100.0f) * fs) * g_bulbC[1][3];
                bool pool = c[3] > 1.0f;
                if (!pool && c[0] + c[1] + c[2] <= 0.001f) continue;
                RECT r;
                bool any = !g_haveProj ? (r = RECT{0, 0, (LONG)g_w, (LONG)g_h}, true)
                         : pool ? SphereRect(a[0], a[1] - a[3], a[2], c[3] * (std::max)(1.0f, sqrtf(c[0] * c[0] + c[1] * c[1] + c[2] * c[2])), g_w, g_h, r) : SphereRect(a[0], a[1], a[2], hr, g_w, g_h, r);
                if (!any) continue;
                erect[i] = r;
                int x0 = (int)(r.left * TX / (LONG)g_w), x1 = (int)((r.right - 1) * TX / (LONG)g_w);
                int y0 = (int)(r.top * TY / (LONG)g_h), y1 = (int)((r.bottom - 1) * TY / (LONG)g_h);
                for (int ty = (std::max)(0, y0); ty <= (std::min)(TY - 1, y1); ++ty)
                    for (int tx = (std::max)(0, x0); tx <= (std::min)(TX - 1, x1); ++tx) bin[ty * TX + tx].push_back(i);
            }
            dev->StretchRect(srcS, nullptr, dstS, nullptr, D3DTEXF_NONE);  // tiles with no lamp stay as they were
            static float ta[24][4], tb[24][4];
            for (int t = 0; t < TX * TY; ++t) {
                const auto& list = bin[t];
                if (list.empty()) continue;
                RECT tr = {(LONG)((t % TX) * g_w / TX), (LONG)((t / TX) * g_h / TY), (LONG)((t % TX + 1) * g_w / TX), (LONG)((t / TX + 1) * g_h / TY)};
                RECT u = erect[list[0]];  // only the part of the tile the lamps reach
                for (int k : list) { const RECT& e = erect[k]; u.left = (std::min)(u.left, e.left); u.top = (std::min)(u.top, e.top); u.right = (std::max)(u.right, e.right); u.bottom = (std::max)(u.bottom, e.bottom); }
                RECT r = {(std::max)(tr.left, u.left), (std::max)(tr.top, u.top), (std::min)(tr.right, u.right), (std::min)(tr.bottom, u.bottom)};
                if (r.right <= r.left || r.bottom <= r.top) continue;
                for (size_t s0 = 0; s0 < list.size(); s0 += 24) {
                    int n = (int)(std::min)((size_t)24, list.size() - s0);
                    for (int k = 0; k < n; ++k) { memcpy(ta[k], g_bulbC[2 + list[s0 + k] * 2], 16); memcpy(tb[k], g_bulbC[3 + list[s0 + k] * 2], 16); }
                    float h2[4] = {hdr[0], (float)n, hdr[2], hdr[3]};
                    dev->SetPixelShaderConstantF(28, h2, 1);
                    dev->SetPixelShaderConstantF(30, ta[0], n);
                    dev->SetPixelShaderConstantF(54, tb[0], n);
                    if (s0) dev->StretchRect(dstS, &r, srcS, &r, D3DTEXF_NONE);  // a second batch on this tile builds on the first
                    dev->SetScissorRect(&r);
                    dev->SetRenderState(D3DRS_SCISSORTESTENABLE, TRUE);
                    g_passScissor = &r;
                    Pass(dev, g_psBTile, dstS, g_w, g_h, g_w, g_h, srcT, g_intz);
                    g_passScissor = nullptr;
                    dev->SetRenderState(D3DRS_SCISSORTESTENABLE, FALSE);
                    ++drawn;
                    area += (double)(r.right - r.left) * (r.bottom - r.top) / ((double)g_w * g_h);
                }
            }
            dev->SetPixelShaderConstantF(28, hdr, 1);
            static bool once2 = false;
            if (!once2) { once2 = true; mmenu::Log("gfx: lamp lights drawn by screen tile (ps_btile)"); }
        }
        for (int i = 0; i < (tiled ? 0 : g_bulbN); ++i) {
            const float* a = g_bulbC[2 + i * 2];
            const float* c = g_bulbC[3 + i * 2];
            float dx = a[0] - g_bulbC[1][0], dy = a[1] - g_bulbC[1][1], dz = a[2] - g_bulbC[1][2];
            float tl = sqrtf(dx * dx + dy * dy + dz * dz), fs = 1 + tl * 0.0015f;
            float hr = (2.2f * sqrtf((1250.0f + 40.0f) * fs) + 2.2f * sqrtf(100.0f) * fs) * g_bulbC[1][3];  // halo reach in world units
            RECT r;
            bool pool = c[3] > 1.0f;  // pool entry (no glow) or bulb entry (glow only)
            if (!pool && c[0] + c[1] + c[2] <= 0.001f) continue;
            bool any = !g_haveProj ? (r = RECT{0, 0, (LONG)g_w, (LONG)g_h}, true)
                     : pool ? SphereRect(a[0], a[1] - a[3], a[2], c[3] * (std::max)(1.0f, sqrtf(c[0] * c[0] + c[1] * c[1] + c[2] * c[2])), g_w, g_h, r) : SphereRect(a[0], a[1], a[2], hr, g_w, g_h, r);
            if (!any) continue;
            dev->SetPixelShaderConstantF(30, a, 2);
            dev->SetScissorRect(&r);
            dev->SetRenderState(D3DRS_SCISSORTESTENABLE, TRUE);
            g_passScissor = &r;
            Pass(dev, pool ? g_psBPool : g_psBHalo, dstS, g_w, g_h, g_w, g_h, srcT, g_intz);
            g_passScissor = nullptr;
            dev->SetRenderState(D3DRS_SCISSORTESTENABLE, FALSE);
            dev->StretchRect(dstS, &r, srcS, &r, D3DTEXF_NONE);
            ++drawn;
            area += (double)(r.right - r.left) * (r.bottom - r.top) / ((double)g_w * g_h);
        }
        cur = tiled ? dstT : srcT;
        if (timing) { g_lqDrawn = drawn; g_lqArea = area; }
    }
    if (timing) g_lqB->Issue(D3DISSUE_END);
    if (WinLayerReady() && g_psWinComp) {  // lit windows (drawn during the scene into g_winTex), after the night tint
        bool depthOk = g_winDepth && g_intzUsed && !g_msaaOn;
        float spill = depthOk && g_psWinVis ? V("gfx_windowspill") / 10.0f : 0.0f;  // only windows that are really visible spill
        if (spill > 0) {  // quarter-res, blurred twice: a soft warm patch around the lit windows
            Pass(dev, g_psWinVis, sE, g_w, g_h, qw, qh, nullptr, g_intz, g_winTex);
            for (int k = 0; k < 2; ++k) {
                dev->SetPixelShaderConstantF(5, dx, 1); Pass(dev, g_psBlur, sF, qw, qh, qw, qh, g_texE);
                dev->SetPixelShaderConstantF(5, dy, 1); Pass(dev, g_psBlur, sE, qw, qh, qw, qh, g_texF);
            }
        }
        float hdr[4] = {g_bulbAmt, depthOk ? 1.0f : 0.0f, spill * 1.6f, (V("gfx_windows") == 3 ? -1.0f : 1.0f) * (g_winSlopeMax + 0.001f)};  // w: slope allowance, < 0 = check mode 3
        dev->SetPixelShaderConstantF(28, hdr, 1);
        IDirect3DTexture9* dst = cur == g_texA ? g_texB : g_texA;
        Pass(dev, g_psWinComp, cur == g_texA ? sB : sA, g_w, g_h, g_w, g_h, cur, depthOk ? g_intz : nullptr, g_winTex, spill > 0 ? g_texE : nullptr);
        cur = dst;
    }
    if (g_bulbCursorOn && g_psLampCur && g_intzUsed && !g_msaaOn) {  // lamp editor: cursor beam + ring, placed lamp marks
        const D3DMATRIX& vm = g_view;
        float cam[4] = {-(vm._41 * vm._11 + vm._42 * vm._12 + vm._43 * vm._13), -(vm._41 * vm._21 + vm._42 * vm._22 + vm._43 * vm._23),
                        -(vm._41 * vm._31 + vm._42 * vm._32 + vm._43 * vm._33), 1};
        int n = 1;  // the cursor's ring (+ beam); placed lamps show their models now
        float hdr[4] = {1, (float)n, 0, 0};
        dev->SetPixelShaderConstantF(28, hdr, 1);
        dev->SetPixelShaderConstantF(29, cam, 1);
        dev->SetPixelShaderConstantF(30, g_edMark[0], n);
        IDirect3DTexture9* dst = cur == g_texA ? g_texB : g_texA;
        Pass(dev, g_psLampCur, cur == g_texA ? sB : sA, g_w, g_h, g_w, g_h, cur, g_intz);
        cur = dst;
        // LampProbe(dev) is not run any more: the editor reads the stock editor camera's own cursor (lampeditor.inc)
    }
    if (timing) { g_lqW->Issue(D3DISSUE_END); g_lqDis->Issue(D3DISSUE_END); g_lqFreq->Issue(D3DISSUE_END); g_lqState = 1; }
    if (g_lqState == 1) {
        BOOL dis = TRUE; UINT64 f = 0, t0 = 0, tm = 0, tb = 0, tw = 0;
        if (g_lqDis->GetData(&dis, sizeof dis, 0) == S_OK && g_lqFreq->GetData(&f, sizeof f, 0) == S_OK &&
            g_lqA->GetData(&t0, sizeof t0, 0) == S_OK && g_lqM->GetData(&tm, sizeof tm, 0) == S_OK &&
            g_lqB->GetData(&tb, sizeof tb, 0) == S_OK && g_lqW->GetData(&tw, sizeof tw, 0) == S_OK) {
            if (!dis && f)
                mmenu::Log("gfx: GPU ms: moonlight %.2f, lamps %.2f (%d of %d bulbs, %.2f screens), windows+spill %.2f (%d window redraws in the scene)",
                           (tm - t0) * 1000.0 / f, (tb - tm) * 1000.0 / f, g_lqDrawn, g_bulbN, g_lqArea, (tw - tb) * 1000.0 / f, g_winDrawsLast);
            g_lqState = 0; g_lqNext = NowS() + 5.0;
        }
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
        {
            const D3DMATRIX& m = g_view;
            float cam[4] = {-(m._41 * m._11 + m._42 * m._12 + m._43 * m._13), -(m._41 * m._21 + m._42 * m._22 + m._43 * m._23),
                            -(m._41 * m._31 + m._42 * m._32 + m._43 * m._33), 1};
            dev->SetPixelShaderConstantF(29, cam, 1);  // ps_weather's drops sit in the world around the camera
        }
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
    // s2 = depth (when readable) so ps_look can keep the night lift off the bright replacement skies
    Pass(dev, g_psLook, bb, g_w, g_h, g_w, g_h, cur, V("gfx_bloom") ? g_texC : nullptr, g_c[9][2] > 0 ? g_intz : nullptr);
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
    g_skySeen = true;  // the replacement sky really drew on this level (MapLookNow: only then may it darken the map)
}

static bool SkyWanted() { return SkySetting() || V("gfx_skypop"); }
// runs when the sky pass ends: only the sky is on the screen, so it can be graded as a whole
static void SkyGrade(IDirect3DDevice9* dev) {
    g_skyGraded = true;
    IDirect3DSurface9* bb = nullptr;
    if (!BackBufferIsTarget(dev, &bb)) return;
    D3DSURFACE_DESC d;
    bb->GetDesc(&d);
    if (!MakeShaders(dev) || !g_psSky || !EnsureTargets(dev, d.Width, d.Height)) { bb->Release(); return; }
    static bool once = false;
    if (!once) { once = true; mmenu::Log("gfx: sky grading (time of day %d, server %d, boost %d)", V("gfx_tod"), g_serverTod, V("gfx_skypop")); }
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
    if (g_shotPending && !g_fgBbGenerated) SaveShot(dev, bb);
    bb->Release();
}

static void NoteDeviceLost(HRESULT hr);  // used by framegen.inc, defined below
#include "framegen.inc"  // frame generation (Noah 2026-11-21)

// ---- per-frame hooks ---------------------------------------------------------------------------
static void CheckKeysAndIni() {
    if ((g_presents & 63) == 0) {  // ~once a second: pick up edits THUGPro Manager made to gfx.ini
        FILETIME t = IniTime();
        if (CompareFileTime(&t, &g_iniTime)) {
            int trick = V("gfx_tricksfx"), postfx = V("gfx_postfx");
            ReloadChanged();
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
    bool shift = (GetAsyncKeyState(VK_SHIFT) & 0x8000) != 0;
    if (now && !down && shift) FgDebugAsk();  // Shift+F11: frame generation debugger records the next frames (framegen.inc)
    else if (now && !down && V("gfx_shotkey")) g_shotPending = true;
    if ((g_presents & 31) == 0) {  // dadmod\gfx_shot.txt: a tool (or THUGPro Manager) asks for a screenshot
        std::string req = ExeDirFile("gfx_shot.txt");
        if (GetFileAttributesA(req.c_str()) != INVALID_FILE_ATTRIBUTES) { DeleteFileA(req.c_str()); g_shotPending = true; }
        std::string fq = ExeDirFile("fgdebug.txt");  // ... or a frame generation recording
        if (GetFileAttributesA(fq.c_str()) != INVALID_FILE_ATTRIBUTES) { DeleteFileA(fq.c_str()); FgDebugAsk(); }
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
// 2026-11-22: online the TOD manager's state (g_serverTod) is almost never 0, so only a server night counts here
// (SkySetting); before, every online level at its normal time lost its stock fog.
static bool PixelFogOn() { return g_cardPixFog && !g_mainMenu && (SkySetting() != 0 || g_fogOver); }
// Fog with our time of day is its own option, off by default (Noah 2026-11-21): while our time of day is on and
// the Fog row is off, the game's fog stays switched off (weather fog still works: it turns this off while it shows).
static bool g_todFogOff = false;
static bool TodFogOff() { return !g_mainMenu && SkySetting() != 0 && !g_fogOver; }  // our time of day never shows the game's faint TOD fog (Fog row = ground mist now)
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
    float fd = g_wxCur[2] * 0.0007f; (void)wet;  // 2026-11-23: weather no longer adds the game fog (ground mist does it); [2] stays 0
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
    g_winDrawsLast = g_winDraws; g_winDraws = 0;
    if (++g_presents == 1) mmenu::Log("gfx: first frame presented");
    g_fgInEnd = true;
    if (!g_sceneDone) {  // nothing 2D was drawn this frame
        dev->BeginScene();
        RunScene(dev, true);
        dev->EndScene();
    }
    FgFrame(dev);  // frame generation: keeps this frame back and puts the first in-between frame in its place
    g_fgInEnd = false;
    RunScreen(dev);
    if (g_lmFrameEnd) g_lmFrameEnd(dev);  // lamp editor's model preview (dev build), over the HUD
    CheckKeysAndIni();
    UpdateWorld();
    ApplyWeatherFog(dev);
    CardCheck(dev);
    FgStartup(dev);  // frame generation's shaders: compiled in the background from the first frame, loaded at startup
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
    bool ours = !g_inPost;
    if (ours) { FgClear(); EndFrame(dev); FgBeforePresent(dev); }  // frame generation: wait for this frame's refresh
    HRESULT hr = g_origPresent(dev, a, b, w, r);
    NoteDeviceLost(hr);
    if (ours) FgQueue(dev, nullptr, a, b, w, r, 0, hr);  // frame generation: the rest of this frame's frames
    return hr;
}

static HRESULT STDMETHODCALLTYPE HookSCPresent(IDirect3DSwapChain9* sc, const RECT* a, const RECT* b, HWND w, const RGNDATA* r, DWORD f) {
    IDirect3DDevice9* dev = nullptr;
    bool ours = !g_inPost && SUCCEEDED(sc->GetDevice(&dev)) && dev;
    if (ours) { FgClear(); EndFrame(dev); FgBeforePresent(dev); }
    HRESULT hr = g_origSCPresent(sc, a, b, w, r, f);
    NoteDeviceLost(hr);
    if (ours) { FgQueue(dev, sc, a, b, w, r, f, hr); dev->Release(); }
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

// ---- lit windows: the game's own window-texture draws are drawn a second time into g_winTex with ps_window
struct WinTex { UINT w, h, dxt, hash; std::string lvl; };
static std::vector<WinTex> g_winList;
static bool g_winListRead = false;
static std::map<void*, bool> g_winSeen;  // texture -> is a window texture (cleared at every level load)
static std::map<void*, IDirect3DTexture9*> g_winMask;  // window texture -> its pane mask (dadmod\lampwindows\<hash>.raw, L8)
static std::map<void*, UINT> g_winHash;  // window texture -> its hash (the pane maps are remade from it when the share changes)
// the level the windows are matched for (lampwindows.txt column 1; 2026-11-23): set by lamplights' level hook at the end of
// load_level, empty (= windows off, nothing gets cached) from the start of a level load until then
static std::string g_winLevel;
static bool g_winLoading = false;
static void WinMasksRelease() {
    for (auto& m : g_winMask) if (m.second) m.second->Release();
    g_winMask.clear();
}
static void WinCacheClear() {
    g_winSeen.clear(); g_winHash.clear(); g_winListRead = false;
    WinMasksRelease();
}
static void WinSetLevelNow(const std::string& lv) {
    if (lv == g_winLevel) return;
    g_winLevel = lv;
    WinCacheClear();
    mmenu::Log("gfx: lit windows: level \"%s\"", lv.c_str());
}
static std::string WinLower(const char* lv) {
    std::string o = lv ? lv : "";
    for (auto& ch : o) ch = (char)tolower((unsigned char)ch);
    return o;
}
static void WinLevelHook(const char* lv, bool loading) {
    g_winLoading = loading;
    if (loading) { g_winLevel.clear(); WinCacheClear(); return; }
    WinSetLevelNow(WinLower(lv && *lv ? lv : g_level.c_str()));
}
static void WinPollLevel(const char* lv) { if (!g_winLoading) WinSetLevelNow(WinLower(lv)); }  // fallback: the 30-frame level poll
static int g_winShareLoaded = -1;  // gfx_windowshare the pane colors were made with (a change reloads them)
static void WinLoadMask(IDirect3DTexture9* t, UINT w, UINT h, UINT hash) {
    // 2026-11-23 (far towers shimmered): each pane's lit color is worked out here once, so the map holds colors, not
    // pane numbers; its smaller levels are plain averages and far facades blend into an even glow instead of flipping
    char name[64];
    snprintf(name, sizeof name, "lampwindows\\%08x.raw", hash);
    std::string data;
    if (!ReadWholeFile(ExeDirFile(name), data) || data.size() != (size_t)w * h) {
        mmenu::Log("gfx: lit windows: no pane map for %08x (%ux%u, file %u bytes)", hash, w, h, (unsigned)data.size());
        return;
    }
    IDirect3DDevice9* dev = nullptr;
    t->GetDevice(&dev);
    if (!dev) return;
    float share = V("gfx_windowshare") / 10.0f;
    g_winShareLoaded = V("gfx_windowshare");
    DWORD pal[256];
    for (int id = 0; id < 256; ++id) {
        UINT hh = 0x811C9DC5;
        for (UINT v : {hash, (UINT)id * 2654435761u}) for (int k = 0; k < 4; ++k) hh = (hh ^ ((v >> (k * 8)) & 0xFF)) * 0x01000193;
        float a = (hh & 0xFFFF) / 65535.0f, kk = ((hh >> 16) & 0xFF) / 255.0f, lv = 0.6f + 0.4f * ((hh >> 24) & 0xFF) / 255.0f;
        bool lit = id > 0 && a >= 1.0f - share;
        float r = 1.0f, g = 0.745f, b = 0.47f;
        if (kk >= 0.94f) { r = 0.3f; g = 0.36f; b = 0.5f; } else if (kk >= 0.7f) { r = 0.6f; g = 0.36f; b = 0.17f; }
        float m = lit ? lv * 0.9f : 0.0f;
        pal[id] = ((DWORD)(id ? 255 : 0) << 24) | ((DWORD)(r * m * 255) << 16) | ((DWORD)(g * m * 255) << 8) | (DWORD)(b * m * 255);
    }
    IDirect3DTexture9* m = nullptr;
    if (SUCCEEDED(dev->CreateTexture(w, h, 0, 0, D3DFMT_A8R8G8B8, D3DPOOL_MANAGED, &m, nullptr))) {
        std::vector<DWORD> cur(w * h);
        for (UINT k = 0; k < w * h; ++k) cur[k] = pal[(unsigned char)data[k]];
        UINT pw = w, ph = h;
        bool ok = true;
        for (DWORD lv = 0; lv < m->GetLevelCount() && ok; ++lv) {
            if (lv) {  // average each 2x2 block, channel by channel
                UINT nw = pw > 1 ? pw / 2 : 1, nh = ph > 1 ? ph / 2 : 1;
                std::vector<DWORD> nx(nw * nh);
                for (UINT y = 0; y < nh; ++y)
                    for (UINT x = 0; x < nw; ++x) {
                        UINT sum[4] = {0, 0, 0, 0}, n = 0;
                        for (UINT k = 0; k < 4; ++k) {
                            UINT sx = x * 2 + (k & 1), sy = y * 2 + (k >> 1);
                            if (sx >= pw || sy >= ph) continue;
                            DWORD c = cur[sy * pw + sx];
                            for (int ch = 0; ch < 4; ++ch) sum[ch] += (c >> (ch * 8)) & 0xFF;
                            ++n;
                        }
                        DWORD o = 0;
                        for (int ch = 0; ch < 4; ++ch) o |= (DWORD)(sum[ch] / (n ? n : 1)) << (ch * 8);
                        nx[y * nw + x] = o;
                    }
                cur.swap(nx); pw = nw; ph = nh;
            }
            D3DLOCKED_RECT lr;
            if (SUCCEEDED(m->LockRect(lv, &lr, nullptr, 0))) {
                for (UINT y = 0; y < ph; ++y) memcpy((char*)lr.pBits + y * lr.Pitch, cur.data() + y * pw, pw * 4);
                m->UnlockRect(lv);
            } else ok = false;
        }
        if (ok) {
            g_winMask[t] = m;
            mmenu::Log("gfx: lit windows: pane map %08x loaded (%ux%u)", hash, w, h);
        } else m->Release();
    }
    dev->Release();
}
static void WinReadList() {
    g_winListRead = true;
    g_winList.clear();
    std::string data;
    if (!ReadWholeFile(ExeDirFile("lampwindows.txt"), data)) return;
    size_t s0 = 0;
    while (s0 < data.size()) {
        size_t e = data.find_first_of("\r\n", s0);
        std::string line = data.substr(s0, e == std::string::npos ? std::string::npos : e - s0);
        s0 = e == std::string::npos ? data.size() : e + 1;
        char lvl[64]; WinTex t;
        if (line.empty() || line[0] == ';') continue;
        if (sscanf(line.c_str(), "%63s %u %u %u %x", lvl, &t.w, &t.h, &t.dxt, &t.hash) == 5) { t.lvl = WinLower(lvl); g_winList.push_back(t); }
    }
    mmenu::Log("gfx: lit windows: %d window textures listed", (int)g_winList.size());
}
static bool IsWindowTex(IDirect3DBaseTexture9* bt) {
    auto it = g_winSeen.find(bt);
    if (it != g_winSeen.end()) return it->second;
    bool yes = false;
    if (bt->GetType() == D3DRTYPE_TEXTURE) {
        IDirect3DTexture9* t = (IDirect3DTexture9*)bt;
        D3DSURFACE_DESC d;
        UINT dxt = 0;
        if (SUCCEEDED(t->GetLevelDesc(0, &d))) {
            dxt = d.Format == D3DFMT_DXT1 ? 1 : d.Format == D3DFMT_DXT2 ? 2 : d.Format == D3DFMT_DXT3 ? 3 : d.Format == D3DFMT_DXT4 ? 4 : d.Format == D3DFMT_DXT5 ? 5 : 0;
            bool cand = false;
            for (const auto& w : g_winList) if (w.w == d.Width && w.h == d.Height && w.dxt == dxt && w.lvl == g_winLevel) cand = true;  // this level's rows only
            D3DLOCKED_RECT lr;
            if (cand && dxt && SUCCEEDED(t->LockRect(0, &lr, nullptr, D3DLOCK_READONLY))) {
                UINT rowBytes = (d.Width / 4 ? d.Width / 4 : 1) * (dxt == 1 ? 8 : 16), rows = d.Height / 4 ? d.Height / 4 : 1;
                UINT h = 0x811C9DC5, n = 0;
                for (UINT r = 0; r < rows; ++r) {  // all of mip 0 (2026-11-23: the first 128 bytes matched ~130 other textures)
                    const unsigned char* p = (const unsigned char*)lr.pBits + r * lr.Pitch;
                    for (UINT i = 0; i < rowBytes; ++i, ++n) h = (h ^ p[i]) * 0x01000193;
                }
                t->UnlockRect(0);
                for (const auto& w : g_winList) if (w.w == d.Width && w.h == d.Height && w.dxt == dxt && w.hash == h && w.lvl == g_winLevel) yes = true;
                if (yes) { g_winHash[t] = h; WinLoadMask(t, d.Width, d.Height, h); }
            }
        }
    }
    g_winSeen[bt] = yes;
    if (yes) {
        static int n = 0;
        if (n < 40) { ++n; mmenu::Log("gfx: lit windows: window texture found (%d so far)", n); }
    }
    return yes;
}
static bool MoonOn() { return V("gfx_moonlight") > 0 && g_bulbAmt > 0.01f && g_psMoon && !g_mainMenu; }
static bool WinLayerReady() { return g_winTex && g_winFrame == g_presents; }
static bool WindowsOn() { return V("gfx_windows") && g_bulbAmt > 0.01f && g_psWindow && !g_msaaOn && g_w && !g_mainMenu && !g_winLevel.empty(); }
// share changed (2026-11-23): remake only the pane color maps; which textures are windows stays known
static void WinRemakeMasks() {
    WinMasksRelease();
    g_winShareLoaded = -1;
    for (const auto& e : g_winHash) {
        IDirect3DTexture9* t = (IDirect3DTexture9*)e.first;
        D3DSURFACE_DESC d;
        if (SUCCEEDED(t->GetLevelDesc(0, &d))) WinLoadMask(t, d.Width, d.Height, e.second);
    }
    g_winShareLoaded = V("gfx_windowshare");
}
// the game's draw this window texture came from: indexed (DrawIndexedPrimitive), plain (DrawPrimitive) or user pointer (DrawPrimitiveUP)
struct WinDraw { int kind; D3DPRIMITIVETYPE pt; INT b; UINT mi, nv, si, pc; const void* up; UINT upst; };
static void DrawWindowGlow(IDirect3DDevice9* dev, IDirect3DBaseTexture9* tex, const WinDraw& wd) {
    if (g_winShareLoaded >= 0 && g_winShareLoaded != V("gfx_windowshare")) WinRemakeMasks();
    auto mk = g_winMask.find(tex);
    IDirect3DTexture9* mask = mk == g_winMask.end() ? nullptr : mk->second;
    if (!mask && V("gfx_windows") != 2) return;  // no pane map: no light at all (check mode still shows it blue)
    if (g_winW != g_w || g_winH != g_h || !g_winSurf) {
        if (g_winSurf) { g_winSurf->Release(); g_winSurf = nullptr; }
        if (g_winTex) { g_winTex->Release(); g_winTex = nullptr; }
        g_winW = g_w; g_winH = g_h;
        g_winDepth = SUCCEEDED(dev->CreateTexture(g_w, g_h, 1, D3DUSAGE_RENDERTARGET, D3DFMT_A16B16G16R16F, D3DPOOL_DEFAULT, &g_winTex, nullptr));
        if (!g_winDepth) mmenu::Log("gfx: lit windows: no half-float layer on this card, windows are not hidden behind closer things");
        if ((!g_winDepth && FAILED(dev->CreateTexture(g_w, g_h, 1, D3DUSAGE_RENDERTARGET, D3DFMT_A8R8G8B8, D3DPOOL_DEFAULT, &g_winTex, nullptr))) ||
            FAILED(g_winTex->GetSurfaceLevel(0, &g_winSurf))) {
            if (g_winTex) { g_winTex->Release(); g_winTex = nullptr; }
            g_winSurf = nullptr;
            return;
        }
    }
    IDirect3DSurface9* rt = nullptr;
    if (FAILED(dev->GetRenderTarget(0, &rt)) || !rt) return;
    D3DSURFACE_DESC d;
    bool full = SUCCEEDED(rt->GetDesc(&d)) && d.Width == g_w && d.Height == g_h;  // only the main 3D view, same size as our layer
    if (!full) { rt->Release(); return; }
    D3DVIEWPORT9 vp;
    dev->GetViewport(&vp);
    IDirect3DPixelShader9* oldPS = nullptr;
    dev->GetPixelShader(&oldPS);
    DWORD ab, sb, db, zw, zf, fog, bo;
    if (FAILED(dev->GetRenderState(D3DRS_ALPHABLENDENABLE, &ab)) || FAILED(dev->GetRenderState(D3DRS_SRCBLEND, &sb)) ||
        FAILED(dev->GetRenderState(D3DRS_DESTBLEND, &db)) || FAILED(dev->GetRenderState(D3DRS_ZWRITEENABLE, &zw)) ||
        FAILED(dev->GetRenderState(D3DRS_ZFUNC, &zf)) || FAILED(dev->GetRenderState(D3DRS_FOGENABLE, &fog)) ||
        FAILED(dev->GetRenderState(D3DRS_BLENDOP, &bo))) {  // a pure device can't report its states: no lit windows
        static bool once = false;
        if (!once) { once = true; mmenu::Log("gfx: lit windows off (render states unreadable)"); }
        if (oldPS) oldPS->Release();
        rt->Release();
        return;
    }
    float oldC0[12];
    dev->GetPixelShaderConstantF(0, oldC0, 3);
    dev->SetRenderTarget(0, g_winSurf);
    dev->SetViewport(&vp);
    if (g_winFrame != g_presents) {
        D3DVIEWPORT9 all = {0, 0, g_w, g_h, 0, 1};
        dev->SetViewport(&all);
        dev->Clear(0, nullptr, D3DCLEAR_TARGET, 0, 1.0f, 0);
        dev->SetViewport(&vp);
        g_winFrame = g_presents;
    }
    // no blending: the nearest window drawn so far wins each pixel (the game's own draw of it already wrote the depth),
    // so windows farther back never add their glow onto nearer ones
    g_origRS(dev, D3DRS_ALPHABLENDENABLE, FALSE); g_origRS(dev, D3DRS_SRCBLEND, D3DBLEND_ONE); g_origRS(dev, D3DRS_DESTBLEND, D3DBLEND_ZERO);
    g_origRS(dev, D3DRS_BLENDOP, D3DBLENDOP_ADD); g_origRS(dev, D3DRS_ZWRITEENABLE, FALSE); g_origRS(dev, D3DRS_ZFUNC, D3DCMP_LESSEQUAL);
    g_origRS(dev, D3DRS_FOGENABLE, FALSE);
    DWORD sab = 0, sba = 0, dba = 0, tci = 0, ttf = 0;
    dev->GetRenderState(D3DRS_SEPARATEALPHABLENDENABLE, &sab); dev->GetRenderState(D3DRS_SRCBLENDALPHA, &sba); dev->GetRenderState(D3DRS_DESTBLENDALPHA, &dba);
    dev->GetTextureStageState(1, D3DTSS_TEXCOORDINDEX, &tci); dev->GetTextureStageState(1, D3DTSS_TEXTURETRANSFORMFLAGS, &ttf);
    D3DMATRIX tm1;
    dev->GetTransform(D3DTS_TEXTURE1, &tm1);
    g_origRS(dev, D3DRS_SEPARATEALPHABLENDENABLE, FALSE);
    dev->SetTextureStageState(1, D3DTSS_TEXCOORDINDEX, D3DTSS_TCI_CAMERASPACEPOSITION | 1);
    dev->SetTextureStageState(1, D3DTSS_TEXTURETRANSFORMFLAGS, D3DTTFF_COUNT3);
    D3DMATRIX ident = {};
    ident._11 = ident._22 = ident._33 = ident._44 = 1;
    g_origST(dev, D3DTS_TEXTURE1, &ident);
    D3DMATRIX pr = g_proj;  // this draw's own projection: ps_window works out its depth-buffer value from it
    dev->GetTransform(D3DTS_PROJECTION, &pr);
    IDirect3DBaseTexture9* oldT1 = nullptr;
    dev->GetTexture(1, &oldT1);
    DWORD s1min = 0, s1mag = 0, s1mip = 0, s1u = 0, s1v = 0;
    dev->GetSamplerState(1, D3DSAMP_MINFILTER, &s1min); dev->GetSamplerState(1, D3DSAMP_MAGFILTER, &s1mag); dev->GetSamplerState(1, D3DSAMP_MIPFILTER, &s1mip);
    dev->GetSamplerState(1, D3DSAMP_ADDRESSU, &s1u); dev->GetSamplerState(1, D3DSAMP_ADDRESSV, &s1v);
    dev->SetTexture(1, mask);
    g_origSSS(dev, 1, D3DSAMP_MINFILTER, D3DTEXF_LINEAR); g_origSSS(dev, 1, D3DSAMP_MAGFILTER, D3DTEXF_LINEAR); g_origSSS(dev, 1, D3DSAMP_MIPFILTER, D3DTEXF_LINEAR);
    g_origSSS(dev, 1, D3DSAMP_ADDRESSU, D3DTADDRESS_WRAP); g_origSSS(dev, 1, D3DSAMP_ADDRESSV, D3DTADDRESS_WRAP);
    DWORD ate = 0, afn = D3DCMP_ALWAYS, aref = 0;
    dev->GetRenderState(D3DRS_ALPHATESTENABLE, &ate); dev->GetRenderState(D3DRS_ALPHAFUNC, &afn); dev->GetRenderState(D3DRS_ALPHAREF, &aref);
    float cut = ate && (afn == D3DCMP_GREATER || afn == D3DCMP_GREATEREQUAL) ? (aref & 0xFF) / 255.0f + (afn == D3DCMP_GREATER ? 0.002f : 0.0f) : -1.0f;
    g_origRS(dev, D3DRS_ALPHATESTENABLE, FALSE);  // our alpha is the window depth, not a cut-out
    float c0[4] = {V("gfx_windowstr") / 10.0f, cut, mask ? 1.0f : 0.0f, V("gfx_windows") == 2 ? 1.0f : 0.0f};
    ++g_winDraws;
    DWORD dbias = 0, sbias = 0;
    dev->GetRenderState(D3DRS_DEPTHBIAS, &dbias); dev->GetRenderState(D3DRS_SLOPESCALEDEPTHBIAS, &sbias);
    float slopeb = *(float*)&sbias;
    if (slopeb > g_winSlopeMax && slopeb < 1000.0f) { g_winSlopeMax = slopeb; mmenu::Log("gfx: lit windows: a window draw uses slope depth bias %.4f", slopeb); }
    float c1[4] = {(float)((double)pr._34 - pr._33), (float)((double)pr._44 - pr._43), pr._34, pr._44};
    float c2[4] = {*(float*)&dbias, 0, 0, 0};  // the game's depth bias (-2.6e-5 on some meshes, THUGPro.exe 0x4DC438)
    dev->SetPixelShaderConstantF(0, c0, 1);
    dev->SetPixelShaderConstantF(1, c1, 1);
    dev->SetPixelShaderConstantF(2, c2, 1);
    dev->SetPixelShader(g_psWindow);
    if (wd.kind == 0) g_origDIP(dev, wd.pt, wd.b, wd.mi, wd.nv, wd.si, wd.pc);
    else if (wd.kind == 1) g_origDP(dev, wd.pt, wd.si, wd.pc);
    else g_origDPUP(dev, wd.pt, wd.pc, wd.up, wd.upst);
    dev->SetPixelShader(oldPS);
    if (oldPS) oldPS->Release();
    dev->SetPixelShaderConstantF(0, oldC0, 3);
    g_origRS(dev, D3DRS_SEPARATEALPHABLENDENABLE, sab); g_origRS(dev, D3DRS_SRCBLENDALPHA, sba); g_origRS(dev, D3DRS_DESTBLENDALPHA, dba);
    dev->SetTextureStageState(1, D3DTSS_TEXCOORDINDEX, tci); dev->SetTextureStageState(1, D3DTSS_TEXTURETRANSFORMFLAGS, ttf);
    dev->SetTexture(1, oldT1);
    if (oldT1) oldT1->Release();
    g_origSSS(dev, 1, D3DSAMP_MINFILTER, s1min); g_origSSS(dev, 1, D3DSAMP_MAGFILTER, s1mag); g_origSSS(dev, 1, D3DSAMP_MIPFILTER, s1mip);
    g_origSSS(dev, 1, D3DSAMP_ADDRESSU, s1u); g_origSSS(dev, 1, D3DSAMP_ADDRESSV, s1v);
    g_origST(dev, D3DTS_TEXTURE1, &tm1);
    g_origRS(dev, D3DRS_ALPHABLENDENABLE, ab); g_origRS(dev, D3DRS_SRCBLEND, sb); g_origRS(dev, D3DRS_DESTBLEND, db);
    g_origRS(dev, D3DRS_BLENDOP, bo); g_origRS(dev, D3DRS_ZWRITEENABLE, zw); g_origRS(dev, D3DRS_ZFUNC, zf); g_origRS(dev, D3DRS_FOGENABLE, fog);
    g_origRS(dev, D3DRS_ALPHATESTENABLE, ate);
    dev->SetRenderTarget(0, rt);
    dev->SetViewport(&vp);
    rt->Release();
}
static bool ScreenSpaceDraw(IDirect3DDevice9* dev);
// after each game draw of the 3D scene: a window texture is drawn again into the lit windows layer (all three draw calls, 2026-11-23)
static void WinAfterDraw(IDirect3DDevice9* dev, const WinDraw& wd) {
    if (g_inPost || g_sceneDone || g_skyPass || !WindowsOn()) return;
    if (!g_winListRead) WinReadList();
    IDirect3DBaseTexture9* tex = nullptr;
    if (!g_winList.empty() && SUCCEEDED(dev->GetTexture(0, &tex)) && tex) {
        if (IsWindowTex(tex)) DrawWindowGlow(dev, tex, wd);
        tex->Release();
    }
}
static HRESULT STDMETHODCALLTYPE HookDIP(IDirect3DDevice9* dev, D3DPRIMITIVETYPE t, INT b, UINT mi, UINT nv, UINT si, UINT pc) {
    if (g_skyPass && !g_inPost && GalaxyOn()) return D3D_OK;  // the galaxy replaces the game's sky
    if (!g_inPost && !g_sceneDone && ScreenSpaceDraw(dev)) RunScene(dev);
    HRESULT hr = g_origDIP(dev, t, b, mi, nv, si, pc);
    WinAfterDraw(dev, {0, t, b, mi, nv, si, pc, nullptr, 0});
    return hr;
}

static HRESULT STDMETHODCALLTYPE HookDP(IDirect3DDevice9* dev, D3DPRIMITIVETYPE t, UINT sv, UINT pc) {
    if (g_skyPass && !g_inPost && GalaxyOn()) return D3D_OK;
    if (!g_inPost && !g_sceneDone && ScreenSpaceDraw(dev)) RunScene(dev);
    HRESULT hr = g_origDP(dev, t, sv, pc);
    WinAfterDraw(dev, {1, t, 0, 0, 0, sv, pc, nullptr, 0});
    return hr;
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
    HRESULT hr = g_origDPUP(dev, t, n, v, st);
    WinAfterDraw(dev, {2, t, 0, 0, 0, 0, n, v, st});
    return hr;
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
    FreeTargets();  // also the lit windows layer (g_winTex / g_winSurf)
    LampQueriesFree();  // lamp GPU timing queries
    if (g_lmFree) g_lmFree();  // lamp models' state block (dev build)
    LampProbeFree();  // lamp editor's cursor probe target
    FgClear(); FgFree();  // frame generation's textures
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
    Patch(vt, 41, (void*)&HookBS, (void**)&g_origBS);  // BeginScene: frame generation shows a held-back frame before the next one starts
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
    if (player == 1) cars2::Remap(out);  // cars2.inc: while driving, up/down also press gas/brake
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

// d3dHooks = false: client safe start (loader.cpp): no CreateDevice import hook and no probe thread; KeepDeviceHooks
// (controller read) still adopts the game device later, so graphics hooks come in anyway. oneProbe: see PatchThread.
// The server build calls Install() and keeps both probes as before.
static void Install(bool d3dHooks = true, bool oneProbe = false) {
    Load();
    InstallMirrorInput();
    InstallLevelSoundHooks();
    if (!d3dHooks) { mmenu::Log("gfx: safe start, early Direct3D hook skipped (the device is picked up later, graphics still work)"); return; }
    g_oneProbe = oneProbe;
    InstallCreateHook();
    CloseHandle(CreateThread(nullptr, 0, PatchThread, nullptr, 0, nullptr));
}

}  // namespace gfx
