// cars 2.0 horn, server build only (needs obsspawn.inc's SendScriptToPlayer and skinsync.inc's dadmod marks).
//
// THUGRECOMP_CarsHornPushStock run=<script> params={...}  Host only: like THUGRECOMP_AllPlayersScript skaters_only,
// but skips players whose game said hello as dadmod (skin::IsMarked): those hear the horn from the car through the
// 0x39 horn message (skinsync.inc HornHandler), so they must not also get the flat stock horn.
namespace carshost {

static bool __cdecl CF_CarsHornPushStock(void* params, void*) {
    char* mgr = *(char**)kNetManagerPtr;
    typedef bool (__thiscall* BoolFn)(void*);
    if (!mgr || !((BoolFn)kIsServer)(mgr)) return false;
    typedef bool (__thiscall* SumFn)(void*, DWORD, DWORD*, bool);
    DWORD script = 0;
    if (!((SumFn)kStructGetChecksum)(params, QbKey("run"), &script, false) || !script) return false;
    char* me = LocalPlayer();
    DWORD node = *(DWORD*)(mgr + kPlayerList);
    int sent = 0;
    while (node && *(int*)(node + 4) != -1) {
        char* player = *(char**)(node + 4);
        node = *(DWORD*)(node + 0xC);
        if (!player || player == me) continue;
        if ((*(DWORD*)(player + kObsPlayerFlags) & 4) || !*(void**)(player + 0x14)) continue;
        if (skin::IsMarked(player)) continue;
        SendScriptToPlayer(mgr, player, script, false, params);
        ++sent;
    }
    return true;
}

}  // namespace carshost
