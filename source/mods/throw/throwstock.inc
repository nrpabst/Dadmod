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
    throwsend::AddType(t);   // the client-side hook (throwsend.inc) needs the same list
    throwsend::Patch();
    return true;
}

// THUGRECOMP_ThrowStockOn            true when the option is on; also returns dadmod_tsn = next copy number (0..15)
// THUGRECOMP_ThrowStockOn set=0|1    changes it and saves dadmod\throwstock.txt
static bool __cdecl CF_ThrowStockOn(void* params, void* script) {
    int set = IntParam(params, "set", -1);
    if (set == 0 || set == 1) {
        g_on = set;
        throwsend::SetOn(set);
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

// ---- Look refresh (Noah 2026-11-24, "do 1 2 and 6" #6): a dadmod player did a mid-game Load Skater; players without
// dadmod only had the join look. Stock has no "change look" message and RefreshSkaterModel on a remote skater crashes
// them (0x522410), so the host drops that player on their games (0x2D, like DropPlayer 0x53CB70) and ~0.75 s later
// re-adds him with the new profile (0x22, the "existing player" message 0x53D9D0 sends to a joiner). Players marked
// as dadmod get the look on 0xD7 (skinsync) and are left out. Plan: work\notes\carstock_test\look_refresh_plan.md.
static const DWORD kMsgCtor   = 0x4549F0;   // MsgDesc::MsgDesc()
static const DWORD kScoreOf   = 0x5436E0;   // int __cdecl (skater id): the score the 0x22 header carries
static const DWORD kLookDelay = 750;        // ms between the drop and the re-add
struct LookJob { char* player; int skaterId; char name[17]; DWORD due; int handles[16]; int count; };
static LookJob g_look[4];

static int LookReason() {   // 0 quit (default); dadmod\throwstock_lookreason.txt (one digit) overrides, test aid
    std::string data;
    if (ReadWholeFile(ExeDirFile("throwstock_lookreason.txt"), data) && !data.empty() && data[0] >= '0' && data[0] <= '9')
        return data[0] - '0';
    return 0;
}
static void SendRaw(int handle, BYTE id, void* data, int len, int f8, int fC, int f10, int f1C) {
    char* mgr = skin::Mgr();
    void* app = mgr ? *(void**)(mgr + 4) : nullptr;
    if (!app || !handle) return;
    BYTE desc[0x20];
    memset(desc, 0, sizeof desc);
    typedef void (__thiscall* CtorFn)(void*);
    ((CtorFn)kMsgCtor)(desc);
    desc[0] = id;
    *(WORD*)(desc + 2) = (WORD)len;
    *(void**)(desc + 4) = data;
    if (f8 >= 0) *(int*)(desc + 8) = f8;
    *(int*)(desc + 0xC) = fC;
    desc[0x10] = (BYTE)f10;
    desc[0x1C] = (BYTE)f1C;
    typedef void (__thiscall* Fn)(void*, int, BYTE*);
    ((Fn)kEnqueue)(app, handle, desc);
}
static int HandleOf(char* p) {
    char* conn = p ? *(char**)(p + skin::kPlayerConn) : nullptr;
    return conn ? *(int*)(conn + 0x3C) : 0;
}

// 2026-11-27: untested on real players, so OFF unless dadmod\lookrefresh.txt starts with 1 (no menu row).
static int g_lookOn = -1;
static bool LookOn() {
    if (g_lookOn < 0) {
        std::string data;
        g_lookOn = (ReadWholeFile(ExeDirFile("lookrefresh.txt"), data) && !data.empty() && data[0] == '1') ? 1 : 0;
        if (!g_lookOn) TLog("look refresh: off (dadmod/lookrefresh.txt = 1 turns it on)");
    }
    return g_lookOn == 1;
}
static void LookChanged(char* player) {
    if (!player || !skin::OnServer() || !On() || !LookOn()) return;
    int id = skin::PlayerSkaterId(player);
    if (id < 0 || id > 255) return;
    LookJob* job = nullptr;
    for (LookJob& j : g_look) if (j.player == player || !j.player) { job = &j; break; }
    if (!job) { TLog("look refresh: busy, " + skin::PlayerName(player) + " skipped"); return; }
    memset(job, 0, sizeof *job);
    int reason = LookReason();
    BYTE drop[2] = { (BYTE)id, (BYTE)reason };
    skin::ForEachPlayer([&](char* p) {
        if (p == player || (*(DWORD*)(p + 0x1D0) & 1) || skin::IsMarked(p)) return true;
        int h = HandleOf(p);
        if (!h || job->count >= 16) return true;
        SendRaw(h, 0x2D, drop, 2, -1, 2, 8, 0);
        job->handles[job->count++] = h;
        return true;
    });
    std::string n = skin::PlayerName(player);
    if (!job->count) { TLog("look refresh: " + n + " has a new look, no player without dadmod to refresh"); return; }
    job->player = player; job->skaterId = id; job->due = GetTickCount() + kLookDelay;
    strncpy(job->name, n.c_str(), 16);
    TLog("look refresh: " + n + " (skater " + std::to_string(id) + ") dropped on " + std::to_string(job->count)
         + " game(s) without dadmod, reason " + std::to_string(reason) + ", re-add in " + std::to_string(kLookDelay) + " ms");
}

static void LookTick() {
    for (LookJob& j : g_look) {
        if (!j.player || (int)(GetTickCount() - j.due) < 0) continue;
        char* p = j.player;
        j.player = nullptr;
        if (!skin::PlayerHere(p) || skin::PlayerSkaterId(p) != j.skaterId || skin::PlayerName(p) != j.name) {
            TLog(std::string("look refresh: ") + j.name + " left before the re-add");
            continue;
        }
        void* prof = *(void**)(p + skin::kPlayerProf);
        if (!prof) { TLog(std::string("look refresh: ") + j.name + " has no profile, not re-added"); continue; }
        static BYTE msg[0x30 + skin::kMaxProfile + 16];
        memset(msg, 0, 0x30);
        *(int*)(msg + 0x00) = *(int*)(p + 0x28);
        *(int*)(msg + 0x04) = *(int*)(p + 0x2C);
        *(DWORD*)(msg + 0x08) = *(DWORD*)(p + 0x1D0) & 0x27880;
        typedef int (__cdecl* ScoreFn)(int);
        *(int*)(msg + 0x0C) = ((ScoreFn)kScoreOf)(j.skaterId);
        *(int*)(msg + 0x10) = *(int*)(p + 0x1C);
        *(int*)(msg + 0x14) = *(int*)(p + 0x20);
        msg[0x18] = (BYTE)j.skaterId;
        msg[0x19] = *(BYTE*)(p + 0x30);
        *(int*)(msg + 0x1C) = *(int*)(p + 0x48);
        memcpy(msg + 0x20, p + skin::kPlayerName, 16);
        int n = skin::PackProfile(prof, msg + 0x30, skin::kMaxProfile);
        if (n <= 0 || n > skin::kMaxProfile) { TLog(std::string("look refresh: ") + j.name + " profile did not pack"); continue; }
        int sent = 0;
        skin::ForEachPlayer([&](char* q) {
            int h = HandleOf(q);
            for (int i = 0; i < j.count; ++i)
                if (j.handles[i] == h && h) { SendRaw(h, 0x22, msg, n + 0x30, 0x80, 2, 8, 2); ++sent; break; }
            return true;
        });
        TLog(std::string("look refresh: ") + j.name + " re-added with the new look on " + std::to_string(sent)
             + " game(s) (" + std::to_string(n) + " profile bytes)");
    }
}
static struct LookInit { LookInit() { skin::g_stockLook = &LookChanged; skin::g_stockTick = &LookTick; } } g_lookInit;

}  // namespace throwstock
