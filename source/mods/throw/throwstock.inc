// Thrown props for players without dadmod (Noah 2026-11-23), server build: needs obsspawn.inc (SendScriptToPlayer),
// modes.inc (ExeDirFile, RetInt, IntParam), skinsync.inc (skin::IsMarked = the player's game said hello as dadmod).
//
// A throw is stock msg 0x83 (BroadcastProjectile, 0x38 bytes: +0x04 Pos, +0x14 vel, +0x24 Type, +0x28 ammo_type,
// +0x2C radius, +0x30 scale, +0x34 owner skater id). The host relays it in 0x56A000 to every other player, and each
// game picks the model from ammo_type in its own ClientLaunchProjectile:
//   - Kali games have no case for our types and show the COMBO O;
//   - plain THUG Pro games show nothing at all online (stock ClientLaunchProjectileReal: if InNetGame return).
// So the host now:
//   1. keeps relaying our types (registered by QB from dadmod_throw_all) only to dadmod players and itself
//      (the call to App::EnqueueMessage at 0x56A137 goes through RelayEnqueue);
//   2. sends every other player a 0x48 CreateCompositeObject with the real model (QB dadmod_throw_stock_send,
//      through THUGRECOMP_ThrowPushStock, which skips dadmod players).
// Off (Pause > dadmod > Throwables, saved in dadmod\throwstock.txt, default On): everything stays stock.
namespace throwstock {

static const DWORD kRelayCall = 0x56A137;   // call App::EnqueueMessage inside the relay loop of 0x56A000
static const DWORD kEnqueue   = 0x457EB0;   // void __thiscall App::EnqueueMessage(int handle, MsgDesc*)

static DWORD g_types[128];
static int   g_typeCount = 0;
static int   g_on = -1;                     // -1 = not read yet
static int   g_next = 0;                    // name counter for the copies on stock games
static bool  g_patched = false;
static int   g_dropped = 0;

static void TLog(const std::string& line) {
    std::string path = ExeDirFile("throwstock.log");
    if (path.empty()) return;
    FILE* f = fopen(path.c_str(), "a");
    if (!f) return;
    SYSTEMTIME t; GetLocalTime(&t);
    fprintf(f, "%02d:%02d:%02d %s\n", t.wHour, t.wMinute, t.wSecond, line.c_str());
    fclose(f);
}

static bool On() {
    if (g_on < 0) {
        std::string data;
        g_on = (ReadWholeFile(ExeDirFile("throwstock.txt"), data) && !data.empty() && data[0] == '0') ? 0 : 1;
    }
    return g_on == 1;
}

static bool OurType(DWORD t) {
    for (int i = 0; i < g_typeCount; ++i) if (g_types[i] == t) return true;
    return false;
}

static char* PlayerByHandle(int handle) {
    char* mgr = *(char**)kNetManagerPtr;
    if (!mgr) return nullptr;
    for (DWORD node = *(DWORD*)(mgr + kPlayerList); node && *(int*)(node + 4) != -1; node = *(DWORD*)(node + 0xC)) {
        char* p = *(char**)(node + 4);
        char* conn = p ? *(char**)(p + kObsPlayerConn) : nullptr;
        if (conn && *(int*)(conn + 0x3C) == handle) return p;
    }
    return nullptr;
}

// Replaces the relay's App::EnqueueMessage call (thiscall: ECX = app, stack = handle, desc; callee pops 8 bytes,
// which __fastcall with an unused EDX does too).
static void __fastcall RelayEnqueue(void* app, void*, int handle, BYTE* desc) {
    if (desc && desc[0] == 0x83 && g_typeCount && On()) {
        const BYTE* data = *(const BYTE**)(desc + 4);
        if (data && *(const WORD*)(desc + 2) >= 0x2C && OurType(*(const DWORD*)(data + 0x28))) {
            char* p = PlayerByHandle(handle);
            if (p && p != LocalPlayer() && !skin::IsMarked(p)) { ++g_dropped; return; }
        }
    }
    typedef void (__thiscall* Fn)(void*, int, BYTE*);
    ((Fn)kEnqueue)(app, handle, desc);
}

static void PatchOnce() {
    if (g_patched) return;
    g_patched = true;
    BYTE* site = (BYTE*)kRelayCall;
    DWORD want = kEnqueue - (kRelayCall + 5);
    if (site[0] != 0xE8 || *(DWORD*)(site + 1) != want) { TLog("relay call at 0x56A137 not as expected, hook skipped"); return; }
    DWORD old;
    if (!VirtualProtect(site, 5, PAGE_EXECUTE_READWRITE, &old)) { TLog("relay hook: VirtualProtect failed"); return; }
    *(DWORD*)(site + 1) = (DWORD)&RelayEnqueue - (kRelayCall + 5);
    VirtualProtect(site, 5, old, &old);
    FlushInstructionCache(GetCurrentProcess(), site, 5);
    TLog("relay hook in (dadmod throws reach players without dadmod as real models)");
}

// THUGRECOMP_ThrowStockType type=<ammo type>  registers one of our ammo types (QB loops dadmod_throw_all once).
// THUGRECOMP_ThrowStockType                     true when the types are registered already.
static bool __cdecl CF_ThrowStockType(void* params, void*) {
    PatchOnce();
    typedef bool (__thiscall* SumFn)(void*, DWORD, DWORD*, bool);
    DWORD t = 0;
    if (!((SumFn)kStructGetChecksum)(params, QbKey("type"), &t, false) || !t) return g_typeCount > 0;
    if (!OurType(t) && g_typeCount < 128) g_types[g_typeCount++] = t;
    return true;
}

// THUGRECOMP_ThrowStockOn            true when the option is on; also returns dadmod_tsn = next copy number (0..15)
// THUGRECOMP_ThrowStockOn set=0|1    changes it and saves dadmod\throwstock.txt
static bool __cdecl CF_ThrowStockOn(void* params, void* script) {
    int set = IntParam(params, "set", -1);
    if (set == 0 || set == 1) {
        g_on = set;
        WriteWholeFile(ExeDirFile("throwstock.txt"), set ? "1\r\n" : "0\r\n");
        TLog(set ? "option on" : "option off");
    }
    RetInt(script, "dadmod_tsn", g_next);
    g_next = (g_next + 1) % 16;
    return On();
}

// THUGRECOMP_ThrowPushStock run=<script> params={...}  Host only: the 0x48 to every player with a skater whose game
// is not dadmod (same set as THUGRECOMP_CarsHornPushStock).
static bool __cdecl CF_ThrowPushStock(void* params, void* script) {
    PatchOnce();
    return carshost::CF_CarsHornPushStock(params, script);
}

}  // namespace throwstock
