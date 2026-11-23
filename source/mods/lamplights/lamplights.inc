// lamplights: THUG2-style LevelLight lights added after a level has loaded (Noah 2026-11-22, first test: one lamp on hof).
//
// How the engine does it (THUGPro.exe 2004-09-14):
//   ParseNodeArray 0x5A34E0 first clears every light (0x48EF00 skater lights, 0x48FDA0 level lights), creates the nodes,
//   then calls 0x490570 AddLevelLight(CStruct* node) for every node with Class = LevelLight.
//   0x490570 reads Name, Pos (0x45C050), Brightness, InnerRadius, OuterRadius, Color [r g b], light_type, ExcludeSkater,
//   ExcludeLevel and ExcludeGeometry straight from the struct, so any struct works, not only a NodeArray node:
//     - no ExcludeSkater: 0x48FB80 takes a skater light slot (0x6FAAF0, count 0x6FAEF0, max 256)
//     - no ExcludeLevel:  0x490400 adds a level light (0x6FAF80 stride 0x24, count 0x6FAEF4, max 150), gathers the
//       scene sectors in range (0x48FFE0) and, if Brightness > 0, re-bakes their vertex colors (0x48FC00 -> 0x48F250)
//   FakeLights id = <Name> Percent = N (0x4901D0) changes the brightness of a light by its Name later.
// The next ParseNodeArray (next level load) frees our lights together with the level's own.
namespace lamplights {

static int Count(unsigned addr) { return *(volatile int*)addr; }

static bool CodeOk() {
    const unsigned char* a = (const unsigned char*)0x490570;
    const unsigned char* b = (const unsigned char*)0x45C050;
    return a[0] == 0x83 && a[1] == 0xEC && a[2] == 0x2C && a[3] == 0x53 && a[4] == 0x56 &&
           b[0] == 0x56 && b[1] == 0x8B && b[2] == 0x74 && b[3] == 0x24 && b[4] == 0x0C;
}

// THUGRECOMP_AddLevelLight Name = <checksum> Pos = (x,y,z) Brightness = 0-100 InnerRadius = r OuterRadius = r
//     color = [r g b] [ExcludeSkater] [ExcludeLevel]   (the same keys as a LevelLight node)
static bool __cdecl CF_AddLevelLight(void* params, void* script) {
    (void)script;
    if (!params) return false;
    if (!CodeOk()) { mmenu::Log("lamplights: engine code does not match, light not added"); return false; }
    int lv0 = Count(0x6FAEF4), sk0 = Count(0x6FAEF0);
    if (lv0 >= 150) { mmenu::Log("lamplights: level light table full (%d)", lv0); return false; }
    float pos[4] = { 0, 0, 0, 1 };
    ((void(__cdecl*)(void*, float*))0x45C050)(params, pos);
    ((void(__cdecl*)(void*))0x490570)(params);
    int lv1 = Count(0x6FAEF4), sk1 = Count(0x6FAEF0);
    mmenu::Log("lamplights: light created at %.0f %.0f %.0f (level lights %d->%d, skater lights %d->%d)",
               pos[0], pos[1], pos[2], lv0, lv1, sk0, sk1);
    return true;
}

// THUGRECOMP_LampBulbsClear: forget the lamp bulbs of the last level (gfx.inc draws them: glow at the head + warm pool)
// [loading = 1]: a level load is starting (lit windows off until it is done); [level = "hof"]: the level that just loaded
static bool __cdecl CF_LampBulbsClear(void* params, void* script) {
    (void)script;
    gfx::BulbClear();
    const char* lv = nullptr;
    bool loading = params && IntParam(params, "loading", 0) != 0;
    if (params && !loading) GetStringParam(params, "level", &lv);
    gfx::WinLevelHook(lv, loading);
    return true;
}
// THUGRECOMP_LampBulb Pos = (x,y,z) [pool = 450] [drop = 440] [r = 255 g = 176 b = 80]   (game coordinates of the bulb)
static bool __cdecl CF_LampBulb(void* params, void* script) {
    (void)script;
    if (!params || !CodeOk()) return false;
    float pos[4] = { 0, 0, 0, 1 };
    ((void(__cdecl*)(void*, float*))0x45C050)(params, pos);
    int pool = IntParam(params, "pool", 450);
    int r = IntParam(params, "r", 255), g = IntParam(params, "g", 176), b = IntParam(params, "b", 80);
    int drop = IntParam(params, "drop", 440);
    gfx::BulbAdd(pos[0], pos[1], pos[2], (float)pool, (float)drop, r / 255.0f, g / 255.0f, b / 255.0f, IntParam(params, "post", 0) != 0);
    return true;
}

// THUGRECOMP_LampNight -> <night> = 1 in the evening / at night / at dawn (gfx time of day or the server's), else 0
static bool __cdecl CF_LampNight(void* params, void* script) {
    (void)params;
    RetInt(script, "night", gfx::g_bulbNight ? 1 : 0);
    return true;
}

}  // namespace lamplights
