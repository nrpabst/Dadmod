// ---- Live skater look for online games (Noah 2026-11-19, Load Skater option 3 "Live update for everyone").
// Included by the server build (build/obsspawn_test_make.sh) and the client build (client/native/loader.cpp),
// before gfx.inc (gfx.inc's ReadControlsHook calls skin::Tick once a frame).
//
// Stock THUG Pro has no message that changes the look of a player already in the game: the look travels only
// at join (client -> host 0x50, host -> everyone 0x22 "new player"). Re-sending either one makes a second
// player / a second skater on stock games, so this never touches them. Instead, dadmod games talk on their own
// message id, and only to games that proved they run dadmod:
//
//   1. The host greets every joining player with a hidden panel block whose callback is THUGRECOMP_SkinHello
//      (modes.q thugpro_join_greet). A stock game has no such function, so the callback does nothing there.
//   2. A dadmod client that was greeted answers with a hello on kMsgId; the host marks that player as dadmod.
//   3. After a mid-game Load Skater, THUGRECOMP_SkinSend packs the player's profile (the same packing as the
//      join message) and sends it on kMsgId, only when this host greeted us (or we are the host).
//   4. The host checks the sender by its connection, copies the look into that player's PlayerInfo profile
//      (+0x4C, which the stock join code sends to anyone joining later), rebuilds its own view of the skater,
//      and forwards the look only to players marked as dadmod.
//   5. A dadmod viewer rebuilds that skater from the new profile (the body of RefreshSkaterModel, 0x5AFD80).
//
// Stock games only ever receive the greeting panel block and normal join data; nothing new reaches them.

#ifndef THISCALL
#define THISCALL __thiscall
#endif

namespace skin {

static const BYTE  kMsgId          = 0xD7;      // free in THUGPro.exe (handlers use 0x03..0x9A); checked at runtime
static const BYTE  kMagic          = 0x44;      // 'D'
static const BYTE  kSubHello       = 1;
static const BYTE  kSubSkin        = 2;
static const BYTE  kSubHorn        = 3;      // cars 2.0 horn (2026-11-21): a dadmod guest honked
static const int   kMaxProfile     = 0x1000;    // the stock join code packs into 0x1000 bytes too
static const int   kMaxSend        = 2400;      // the receive loop (0x45A830) copies a message into a 2600-byte stack buffer;
                                                // a packed look is about 1000 bytes, bigger ones fall back to a rejoin

static const DWORD kMgrPtr         = 0x7CCE14;  // Net manager*
static const DWORD kSkateModPtr    = 0x7CE478;  // Skate mod (skater list, local profiles)
static const DWORD kMemMgrPtr      = 0x7D1800;  // memory manager*
static const DWORD kGetLocalPlayerF= 0x537320;  // PlayerInfo* __thiscall Manager::GetLocalPlayer()
static const DWORD kAddHandler     = 0x45A5C0;  // node* __thiscall Dispatcher::AddHandler(id, fn, flags, data, pri)
static const DWORD kMsgDescCtorF   = 0x4549F0;  // MsgDesc::MsgDesc() (0x20 bytes)
static const DWORD kAppEnqueue     = 0x457EB0;  // void __thiscall App::EnqueueMessage(int conn_handle, MsgDesc*)
static const DWORD kClientSendF    = 0x459E50;  // void __thiscall ClientApp::Send(MsgDesc*)
static const DWORD kGetProfile     = 0x564FC0;  // CSkaterProfile* __thiscall SkateMod::GetProfile(int)
static const DWORD kGetSkater      = 0x5665C0;  // CSkater* __thiscall SkateMod::GetSkater(uint index)
static const DWORD kProfileCtor    = 0x586D60;  // CSkaterProfile::CSkaterProfile() (0x64 bytes)
static const DWORD kProfileDtor    = 0x543010;
static const DWORD kProfileWrite   = 0x587050;  // int __thiscall WriteToBuffer(buf, size, flag)
static const DWORD kProfileRead    = 0x586DC0;  // __thiscall ReadFromBuffer(buf)
static const DWORD kProfileAssign  = 0x585ED0;  // CSkaterProfile& __thiscall operator=(const CSkaterProfile&)
static const DWORD kAlloc          = 0x401CC0;  // void* __cdecl operator new(size)
static const DWORD kHeapPush       = 0x5BB0E0;  // void __thiscall MemMgr::PushContext(heap)
static const DWORD kHeapPop        = 0x5BB110;  // void __thiscall MemMgr::PopContext()
static const DWORD kHeapFree       = 0x5BABA0;  // void __thiscall MemMgr::Free(ptr)
static const DWORD kGetComponent   = 0x45DB90;  // component* __thiscall CObject::GetComponent(DWORD type)
static const DWORD kSkaterModelA   = 0x580BE0;  // __thiscall CSkater::(profile) - RefreshSkaterModel steps
static const DWORD kSkaterModelB   = 0x580EB0;
static const DWORD kBoardModel     = 0x522410;  // __thiscall component 0x270F56E1 ::(profile)
static const DWORD kTexDictMgr     = 0x6F0FB8;
static const DWORD kTexDictFind    = 0x4619F0;
static const DWORD kTexDictFlush   = 0x461AB0;

static const int kPlayerList  = 0x128;  // Manager player list head
static const int kPlayerConn  = 0x18;   // PlayerInfo -> connection (handle at +0x3C)
static const int kPlayerSkat  = 0x14;   // PlayerInfo -> CSkater*
static const int kPlayerProf  = 0x4C;   // PlayerInfo -> CSkaterProfile* (host: what late joiners receive)
static const int kPlayerName  = 0x38;
static const int kSkaterId    = 0x14;   // CSkater object id
static const int kSkaterNum   = 0x2B8;  // CSkater heap slot

static void SLog(const std::string& line) {
    std::string path = ExeDirFile("skinsync.log");
    if (path.empty()) return;
    FILE* f = fopen(path.c_str(), "a");
    if (!f) return;
    SYSTEMTIME t; GetLocalTime(&t);
    fprintf(f, "%02d:%02d:%02d %s\n", t.wHour, t.wMinute, t.wSecond, line.c_str());
    fclose(f);
}

static char* Mgr() { return *(char**)kMgrPtr; }
// The real "we are the server": [manager] & 1, what the script OnServer reads (0x533F90). The shared
// (IsHostServer() in modes.inc/common.inc is "host of a net game": 0x44E4F0 "in a net game" plus this test.)
static bool OnServer() { char* m = Mgr(); return m && (*(DWORD*)m & 1) != 0; }

static char* LocalPlayerInfo() {
    char* mgr = Mgr();
    if (!mgr) return nullptr;
    typedef char* (THISCALL* Fn)(void*);
    return ((Fn)kGetLocalPlayerF)(mgr);
}

template <typename F> static void ForEachPlayer(F f) {
    char* mgr = Mgr();
    if (!mgr) return;
    for (DWORD node = *(DWORD*)(mgr + kPlayerList); node && *(int*)(node + 4) != -1; node = *(DWORD*)(node + 0xC)) {
        char* p = *(char**)(node + 4);
        if (p && !f(p)) return;
    }
}

static bool PlayerHere(char* player) {
    bool here = false;
    ForEachPlayer([&](char* p) { if (p == player) { here = true; return false; } return true; });
    return here;
}

static int PlayerSkaterId(char* player) {
    char* s = player ? *(char**)(player + kPlayerSkat) : nullptr;
    return s ? *(int*)(s + kSkaterId) : -1;
}

static std::string PlayerName(char* player) {
    char n[17]; memcpy(n, player + kPlayerName, 16); n[16] = 0;
    return n;
}

// ---- profiles (allocated like the stock join code: in the net heap)
static void HeapPush(DWORD slotOffset) {
    char* mm = *(char**)kMemMgrPtr;
    typedef void (THISCALL* Fn)(void*, DWORD);
    ((Fn)kHeapPush)(mm, *(DWORD*)(mm + slotOffset));
}
static void HeapPop() {
    typedef void (THISCALL* Fn)(void*);
    ((Fn)kHeapPop)(*(void**)kMemMgrPtr);
}
static void* NewProfile() {
    HeapPush(0x5D4);
    typedef void* (__cdecl* AllocFn)(int);
    void* p = ((AllocFn)kAlloc)(0x64);
    if (p) { typedef void (THISCALL* Fn)(void*); ((Fn)kProfileCtor)(p); }
    HeapPop();
    return p;
}
static void FreeProfile(void* p) {
    if (!p) return;
    typedef void (THISCALL* Fn)(void*);
    ((Fn)kProfileDtor)(p);
    typedef void (THISCALL* FreeFn)(void*, void*);
    ((FreeFn)kHeapFree)(*(void**)kMemMgrPtr, p);
}
static int PackProfile(void* profile, BYTE* buf, int cap) {
    typedef int (THISCALL* Fn)(void*, void*, int, int);
    return ((Fn)kProfileWrite)(profile, buf, cap, 0);
}
static void* ReadProfile(const BYTE* data, int len) {
    if (!data || len < 8 || len > kMaxProfile) return nullptr;
    static BYTE copy[kMaxProfile + 16];   // the reader may look a little past the packed bytes
    memset(copy, 0, sizeof copy);
    memcpy(copy, data, len);
    void* p = NewProfile();
    if (!p) return nullptr;
    typedef void* (THISCALL* Fn)(void*, void*);
    ((Fn)kProfileRead)(p, copy);
    // sanity: packing it again must give the same size, else drop it
    static BYTE again[kMaxProfile + 16];
    int n = PackProfile(p, again, kMaxProfile);
    if (n != len) {
        SLog("dropped a look that did not read back (" + std::to_string(len) + " vs " + std::to_string(n) + " bytes)");
        FreeProfile(p);
        return nullptr;
    }
    return p;
}
static void AssignProfile(void* dst, void* src) {
    if (!dst || !src) return;
    HeapPush(0x5D4);
    typedef void* (THISCALL* Fn)(void*, void*);
    ((Fn)kProfileAssign)(dst, src);
    HeapPop();
}

// ---- rebuild one skater's model from a profile: the body of CF_RefreshSkaterModel (0x5AFD80)
static char* SkaterById(int id) {
    char* mod = *(char**)kSkateModPtr;
    if (!mod || id < 0) return nullptr;
    typedef char* (THISCALL* Fn)(void*, unsigned);
    for (unsigned i = 0; i < 16; ++i) {
        char* s = ((Fn)kGetSkater)(mod, i);
        if (!s) break;
        if (*(int*)(s + kSkaterId) == id) return s;
    }
    return nullptr;
}
static bool RebuildSkater(char* s, void* profile) {
    if (!s || !profile) return false;
    char* mm = *(char**)kMemMgrPtr;
    if (*(int*)(s + 0x2BC) == 0) {
        char* tm = *(char**)kTexDictMgr;
        typedef int* (THISCALL* FindFn)(void*, DWORD);
        int* d = tm ? ((FindFn)kTexDictFind)(tm, 0x884EF81B) : nullptr;
        if (d) {
            typedef void (THISCALL* VFn)(void*);
            ((VFn)(*(DWORD*)(*d + 0x18)))(d);
            ((VFn)kTexDictFlush)(*(void**)kTexDictMgr);
        }
    }
    int num = *(int*)(s + kSkaterNum);
    if (num < 0 || num > 15) return false;
    typedef void* (THISCALL* CompFn)(void*, DWORD);
    HeapPush(0x1C0 + num * 4);
    void* model = ((CompFn)kGetComponent)(s, 0x286A8D26);
    if (model) {
        typedef void (THISCALL* Fn)(void*, void*, int, int, int);
        ((Fn)(*(DWORD*)(*(DWORD*)model + 0x34)))(model, profile, 0, num, 0);
    }
    HeapPop();
    HeapPush(0x180 + num * 4);
    typedef void (THISCALL* PFn)(void*, void*);
    ((PFn)kSkaterModelA)(s, profile);
    void* board = ((CompFn)kGetComponent)(s, 0x270F56E1);
    if (board) ((PFn)kBoardModel)(board, profile);
    ((PFn)kSkaterModelB)(s, profile);
    HeapPop();
    (void)mm;
    return true;
}

// ---- host: which players run dadmod (they answered our greeting)
struct Mark { char* player; int conn; char name[17]; };
static Mark g_marks[16];

static bool IsMarked(char* player) {
    if (!player) return false;
    int conn = *(int*)(player + kPlayerConn);
    std::string name = PlayerName(player);
    for (Mark& m : g_marks)
        if (m.player == player && m.conn == conn && name == m.name) return true;
    return false;
}
static void MarkPlayer(char* player) {
    if (!player || IsMarked(player)) return;
    Mark* slot = nullptr;
    for (Mark& m : g_marks)
        if (!m.player || !PlayerHere(m.player)) { slot = &m; break; }
    if (!slot) return;
    slot->player = player;
    slot->conn = *(int*)(player + kPlayerConn);
    std::string n = PlayerName(player);
    strncpy(slot->name, n.c_str(), 16); slot->name[16] = 0;
    SLog("dadmod player checked in: " + n);
}

// ---- sending
// MsgDesc +0xC queue 2, +0x10 channel 0, +0x1C 0: what the stock chat send (0x537BD0) uses. Tested 2026-11-19: the
// 0x22 values (channel 8, +0x1C 2) never arrive for our id, and queue 1 / channel 8 keep arriving again every second.
static const int g_q = 2, g_ch = 0, g_big = 0;
static void InitDesc(BYTE* desc, int len, void* data) {
    typedef void (THISCALL* Fn)(void*);
    memset(desc, 0, 0x20);
    ((Fn)kMsgDescCtorF)(desc);
    desc[0] = kMsgId;
    *(WORD*)(desc + 2) = (WORD)len;
    *(void**)(desc + 4) = data;
    *(int*)(desc + 0xC) = g_q;
    desc[0x10] = (BYTE)g_ch;
    desc[0x1C] = (BYTE)g_big;
}
static void SendToServer(BYTE* data, int len) {
    char* mgr = Mgr();
    void* app = mgr ? *(void**)(mgr + 8) : nullptr;
    if (!app) return;
    BYTE desc[0x20];
    InitDesc(desc, len, data);
    typedef void (THISCALL* Fn)(void*, void*);
    ((Fn)kClientSendF)(app, desc);
}
// host: forward a look to every dadmod player except the one it is about and ourselves
static int Forward(char* about, const BYTE* profile, int len) {
    char* mgr = Mgr();
    void* app = mgr ? *(void**)(mgr + 4) : nullptr;
    if (!app) return 0;
    static BYTE data[kMaxProfile + 8];
    data[0] = kMagic; data[1] = kSubSkin; data[2] = (BYTE)PlayerSkaterId(about); data[3] = 0;
    memcpy(data + 4, profile, len);
    char* me = LocalPlayerInfo();
    int sent = 0, held = 0;
    ForEachPlayer([&](char* p) {
        if (p == about || p == me) return true;
        char* conn = *(char**)(p + kPlayerConn);
        if (!conn) return true;
        if (!IsMarked(p)) { ++held; return true; }
        BYTE desc[0x20];
        InitDesc(desc, len + 4, data);
        typedef void (THISCALL* Fn)(void*, int, void*);
        ((Fn)kAppEnqueue)(app, *(int*)(conn + 0x3C), desc);
        ++sent;
        return true;
    });
    SLog("look of " + PlayerName(about) + " sent to " + std::to_string(sent) + " dadmod player(s), not to "
         + std::to_string(held) + " without dadmod (they see it when they or that player rejoin)");
    return sent;
}

// ---- rebuilds wait for the next frame (handlers run inside the net code)
struct Pending { int id; int len; BYTE data[kMaxProfile]; bool fromHostProfile; };
static Pending g_pending[4];
static int g_pendingCount = 0;

static void Queue(int id, const BYTE* data, int len, bool fromHostProfile) {
    if (g_pendingCount >= 4) { SLog("queue full, look dropped"); return; }
    Pending& p = g_pending[g_pendingCount++];
    p.id = id; p.len = len; p.fromHostProfile = fromHostProfile;
    if (data && len > 0) memcpy(p.data, data, len);
}

static char* PlayerBySkaterId(int id) {
    char* found = nullptr;
    ForEachPlayer([&](char* p) { if (PlayerSkaterId(p) == id) { found = p; return false; } return true; });
    return found;
}

// Server build only (throwstock.inc sets them, 2026-11-24): players without dadmod see a new look by a stock
// drop (0x2D) and re-add (0x22) of that player. Null in the client build.
static void (*g_stockLook)(char* player) = nullptr;
static void (*g_stockTick)() = nullptr;

// host: a player has a new look (bytes = packed profile)
static void HostTakeLook(char* player, const BYTE* bytes, int len) {
    void* tmp = ReadProfile(bytes, len);
    if (!tmp) return;
    void* stored = *(void**)(player + kPlayerProf);
    if (stored) AssignProfile(stored, tmp);   // late joiners get this one through the stock join data
    FreeProfile(tmp);
    if (player != LocalPlayerInfo()) Queue(PlayerSkaterId(player), nullptr, 0, true);   // our own view
    Forward(player, bytes, len);
    if (g_stockLook) g_stockLook(player);
}

// ---- handlers: ctx[0] data, ctx[2] size, ctx[4] sender connection
// ---- host rate limit (2026-11-19): a modified client must not make the host rebuild skaters every frame.
// At most one look per player every kLookGap ms; kFloodStrikes ignored looks inside kFloodWindow ms block that
// connection until it leaves (its dadmod mark is dropped, so nothing is forwarded to it either). Hellos stay cheap:
// 4 bytes, one mark, no log line per message.
static const DWORD kLookGap = 2000, kFloodWindow = 10000;
static const int kFloodStrikes = 5;
struct Rate { int conn; char* player; DWORD last; DWORD strikeStart; int strikes; bool blocked; };
static Rate g_rate[16];
static Rate* RateFor(int conn) {
    Rate* free_ = nullptr;
    for (Rate& r : g_rate) {
        if (r.conn == conn) return &r;
        if (!free_ && !r.conn) free_ = &r;
    }
    if (!free_) {   // all slots used: reuse one whose connection has left
        for (Rate& r : g_rate) {
            bool here = false;
            ForEachPlayer([&](char* p) { if (*(int*)(p + kPlayerConn) == r.conn) { here = true; return false; } return true; });
            if (!here) { free_ = &r; break; }
        }
    }
    if (!free_) return nullptr;
    memset(free_, 0, sizeof *free_);
    free_->conn = conn;
    return free_;
}
static void UnmarkPlayer(char* player) {
    for (Mark& m : g_marks) if (m.player == player) m.player = nullptr;
}
// ---- cars 2.0 horn (Noah 2026-11-21: dadmod players hear each other's horns, from the car, on a dadmod host).
// A dadmod guest sends kSubHorn to the host; the host (rate limited, 1 per player per second) runs the QB script
// dadmod_cars_horn_remote id=<skater id> on the next frame, which plays the horn on that skater for the host and
// pushes the stock Auto_SFX_Car_Horn_Stream panel block to every player (it skips a player whose horn stream is
// already playing, so the guest who honked doesn't hear it twice). Nothing is forwarded on 0xD7 for horns.
static const DWORD kRunScriptF = 0x475790, kStructCtorF = 0x476410, kStructDtorF = 0x477130, kAddIntF = 0x477B80;
struct HornRate { int conn; DWORD last; };
static HornRate g_hornRate[16];
static int g_hornIds[4];
static int g_hornCount = 0;
static void HostHorn(char* sender) {
    int conn = *(int*)(sender + kPlayerConn);
    HornRate* r = nullptr;
    for (HornRate& h : g_hornRate) if (h.conn == conn) { r = &h; break; }
    if (!r) for (HornRate& h : g_hornRate) if (!h.conn) { r = &h; r->conn = conn; r->last = 0; break; }
    if (!r) { r = &g_hornRate[0]; r->conn = conn; r->last = 0; }
    DWORD now = GetTickCount();
    if (r->last && now - r->last < 1000) return;
    r->last = now;
    int id = PlayerSkaterId(sender);
    if (id < 0 || id > 15 || g_hornCount >= 4) return;
    g_hornIds[g_hornCount++] = id;
}
static void RunHorns() {
    for (int i = 0; i < g_hornCount; ++i) {
        BYTE st[16] = {0};
        typedef void (THISCALL* CtorFn)(void*);
        typedef void (THISCALL* AddIntFn)(void*, DWORD, int);
        typedef int (__cdecl* RunFn)(DWORD, void*, int, int, int);
        ((CtorFn)kStructCtorF)(st);
        ((AddIntFn)kAddIntF)(st, QbKey("id"), g_hornIds[i]);
        ((RunFn)kRunScriptF)(QbKey("dadmod_cars_horn_remote"), st, 0, 0, 0);
        ((CtorFn)kStructDtorF)(st);
    }
    g_hornCount = 0;
}

// ---- cars 2.0 horn on ANY server (Noah 2026-11-21 "lets try it"): stock message 0x39 is relayed by every stock host
// to all other players (0x56A000, registered next to 0x89) and the stock client handler for it (0x56B7E0) only looks
// the skater up by the first byte and returns, so plain THUG Pro / Kali players ignore it. thugpro.dll registers no
// net handlers at all (no 0x45A5C0 call), so Kali doesn't use it either. We send { skater id, 'D', 'H', 1 } on 0x39
// exactly like the stock 0x89 send (CF_BroadcastEnterVehicle 0x5B2260: MsgDesc +0xC queue 2, +0x10 channel 8) and add
// our own client handler next to the stock one: on the marker it queues dadmod_cars_horn_hear id=<skater> for the
// next frame. Short packets, other markers, our own id and more than 1 honk per second per skater are ignored.
static const BYTE kHornMsg = 0x39;
static DWORD g_hornHeardAt[16];
static int g_hearIds[4];
static int g_hearCount = 0;
static int __cdecl HornHandler(int* ctx) {
    if (!ctx || !ctx[0] || ctx[2] < 4) return 1;
    const BYTE* d = (const BYTE*)ctx[0];
    if (d[1] != 'D' || d[2] != 'H' || d[3] != 1) return 1;
    int id = (signed char)d[0];
    if (id < 0 || id > 15) return 1;
    char* me = LocalPlayerInfo();
    if (me && PlayerSkaterId(me) == id) return 1;
    DWORD now = GetTickCount();
    if (g_hornHeardAt[id] && now - g_hornHeardAt[id] < 900) return 1;
    g_hornHeardAt[id] = now;
    if (g_hearCount < 4) g_hearIds[g_hearCount++] = id;
    return 1;
}
static bool HasHandler2(void* app, int id, void* fn);
static void RegisterHorn(void* app) {
    if (!app || HasHandler2(app, kHornMsg, (void*)&HornHandler)) return;
    typedef void* (THISCALL* Fn)(void*, int, void*, int, int, int);
    ((Fn)kAddHandler)((char*)app + 0xC, kHornMsg, (void*)&HornHandler, 3, 0, 0x80);
    SLog("listening for dadmod horns (message 0x39)");
}
static void RunHears() {
    for (int i = 0; i < g_hearCount; ++i) {
        BYTE st[16] = {0};
        typedef void (THISCALL* CtorFn)(void*);
        typedef void (THISCALL* AddIntFn)(void*, DWORD, int);
        typedef int (__cdecl* RunFn)(DWORD, void*, int, int, int);
        ((CtorFn)0x476410)(st);
        ((AddIntFn)0x477B80)(st, QbKey("id"), g_hearIds[i]);
        ((RunFn)0x475790)(QbKey("dadmod_cars_horn_hear"), st, 0, 0, 0);
        ((CtorFn)0x477130)(st);
    }
    g_hearCount = 0;
}

static int __cdecl ServerHandler(int* ctx) {
    if (!ctx || !ctx[0] || ctx[2] < 2 || !ctx[4]) return 1;
    const BYTE* d = (const BYTE*)ctx[0];
    if (d[0] != kMagic) return 1;
    char* sender = nullptr;
    ForEachPlayer([&](char* p) { if (*(int*)(p + kPlayerConn) == ctx[4]) { sender = p; return false; } return true; });
    if (!sender) return 1;
    Rate* r = RateFor(ctx[4]);
    if (!r) return 1;
    if (r->player != sender) { memset(r, 0, sizeof *r); r->conn = ctx[4]; r->player = sender; }   // a new player on this connection
    if (r->blocked) return 1;
    if (d[1] == kSubHello) { MarkPlayer(sender); return 1; }
    if (d[1] == kSubHorn) { HostHorn(sender); return 1; }
    if (d[1] != kSubSkin || ctx[2] <= 4) return 1;
    DWORD now = GetTickCount();
    if (r->last && now - r->last < kLookGap) {
        if (!r->strikes || now - r->strikeStart > kFloodWindow) { r->strikes = 0; r->strikeStart = now; }
        if (++r->strikes >= kFloodStrikes) {
            r->blocked = true;
            UnmarkPlayer(sender);
            SLog("host: " + PlayerName(sender) + " sent looks too fast, ignoring them until they leave");
        }
        return 1;
    }
    r->last = now;
    MarkPlayer(sender);
    SLog("host got a new look from " + PlayerName(sender) + " (" + std::to_string(ctx[2] - 4) + " bytes)");
    HostTakeLook(sender, d + 4, ctx[2] - 4);
    return 1;
}
static int __cdecl ClientHandler(int* ctx) {
    if (!ctx || !ctx[0] || ctx[2] <= 4) return 1;
    const BYTE* d = (const BYTE*)ctx[0];
    char hdr[96];
    sprintf(hdr, "client got %d bytes (%02X %02X) for skater %d", ctx[2], d[0], d[1], d[2]);
    SLog(hdr);
    if (d[0] != kMagic || d[1] != kSubSkin) return 1;
    if (OnServer()) return 1;   // the host already applied it
    Queue(d[2], d + 4, ctx[2] - 4, false);
    return 1;
}

// ---- handler registration: lists per id at dispatcher (app + 0xC) + id * 0x14
static bool HasHandler(void* app, void* fn) {
    char* sentinel = (char*)app + 0xC + kMsgId * 0x14;
    for (char* n = *(char**)(sentinel + 0xC); n && *(int*)(n + 4) != -1; n = *(char**)(n + 0xC))
        if (*(void**)(n + 0x14) == fn) return true;
    return false;
}
static bool HasOtherHandler(void* app, void* fn) {
    char* sentinel = (char*)app + 0xC + kMsgId * 0x14;
    for (char* n = *(char**)(sentinel + 0xC); n && *(int*)(n + 4) != -1; n = *(char**)(n + 0xC))
        if (*(void**)(n + 0x14) != fn) return true;
    return false;
}
static bool HasHandler2(void* app, int id, void* fn) {
    char* sentinel = (char*)app + 0xC + id * 0x14;
    for (char* n = *(char**)(sentinel + 0xC); n && *(int*)(n + 4) != -1; n = *(char**)(n + 0xC))
        if (*(void**)(n + 0x14) == fn) return true;
    return false;
}
static void Register(void* app, void* fn, const char* what) {
    if (!app || HasHandler(app, fn)) return;
    if (HasOtherHandler(app, fn)) {
        static void* warned = nullptr;
        if (warned != app) { warned = app; SLog(std::string("message id taken on the ") + what + ", live looks off"); }
        return;
    }
    typedef void* (THISCALL* Fn)(void*, int, void*, int, int, int);
    // flags 3: the dispatcher (0x45A750) only calls a handler whose flags cover the message's flags, and messages
    // from players arrive with flag 2 set (the stock relays for 0x48/0x49/0x4C register 2, the skater update 3)
    ((Fn)kAddHandler)((char*)app + 0xC, kMsgId, fn, 3, 0, 0x80);
    SLog(std::string("listening on the ") + what);
}

static void* g_greetApp = nullptr;   // client: the client App of the server that greeted us

// ---- Load Skater online on a joining player (found 2026-11-19 while testing the live skater update):
// - Stock scripts say `Skater = 0` (load_pro_skater's RefreshSkaterModel, our RefreshSkaterScale/Visibility) and
//   CFuncs look that up as an index in the skater list (GetSkater 0x5665C0). On a joining player index 0 is the
//   host's skater, so the load rebuilt the host's skater with our look on our screen, and then crashed: 0x522410
//   (component 0x270F56E1 ::(profile)) has no null check and remote skaters have no such component.
// - Fix 1: while THUGRECOMP_SkinLocalZero on=1 is set (only around Load Skater online, off again after 3 s at most),
//   GetSkater(0) returns our own skater (GetLocalSkater 0x566520). On the host index 0 already is our own skater.
// - Fix 2: 0x522410 returns at once when that component pointer is null (the skater setup 0x581850 checks it too).
static volatile BYTE g_localZero = 0;
static DWORD g_localZeroTick = 0;
static bool g_patched = false;
static BYTE* MakeStub(const BYTE* code, int len) {
    BYTE* m = (BYTE*)VirtualAlloc(nullptr, 64, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
    if (m) memcpy(m, code, len);
    return m;
}
static void Rel32(BYTE* at, DWORD target) { *(DWORD*)at = target - ((DWORD)at + 4); }
static bool JumpAt(DWORD site, BYTE* to, int len, const BYTE* expect) {
    if (memcmp((void*)site, expect, len) != 0) return false;
    DWORD old;
    if (!VirtualProtect((void*)site, len, PAGE_EXECUTE_READWRITE, &old)) return false;
    BYTE* p = (BYTE*)site;
    p[0] = 0xE9; Rel32(p + 1, (DWORD)to);
    for (int i = 5; i < len; ++i) p[i] = 0x90;
    VirtualProtect((void*)site, len, old, &old);
    FlushInstructionCache(GetCurrentProcess(), (void*)site, len);
    return true;
}
static void PatchOnce() {
    if (g_patched) return;
    g_patched = true;
    // 0x522410: test ecx,ecx / jnz +3 / ret 4 / (mov eax,fs:[0]) / jmp 0x522416
    static const BYTE guardOrig[6] = { 0x64, 0xA1, 0x00, 0x00, 0x00, 0x00 };
    BYTE guard[] = { 0x85, 0xC9, 0x75, 0x03, 0xC2, 0x04, 0x00, 0x64, 0xA1, 0, 0, 0, 0, 0xE9, 0, 0, 0, 0 };
    BYTE* g = MakeStub(guard, sizeof guard);
    if (g) { Rel32(g + 14, 0x522416); SLog(JumpAt(0x522410, g, 6, guardOrig) ? "guard at 0x522410 in" : "0x522410 not as expected, guard skipped"); }
    // 0x5665C0: if (g_localZero && index == 0) { local = GetLocalSkater(); if (local) return local; } then the original
    static const BYTE getOrig[6] = { 0x8B, 0x41, 0x34, 0x83, 0xC1, 0x28 };
    BYTE get[] = {
        0x80, 0x3D, 0, 0, 0, 0, 0x00,   //  0 cmp byte ptr [g_localZero], 0
        0x74, 0x15,                     //  7 je orig
        0x83, 0x7C, 0x24, 0x04, 0x00,   //  9 cmp dword ptr [esp+4], 0
        0x75, 0x0E,                     // 14 jne orig
        0x51,                           // 16 push ecx
        0xE8, 0, 0, 0, 0,               // 17 call GetLocalSkater
        0x59,                           // 22 pop ecx
        0x85, 0xC0,                     // 23 test eax, eax
        0x74, 0x03,                     // 25 jz orig
        0xC2, 0x04, 0x00,               // 27 ret 4
        0x8B, 0x41, 0x34,               // 30 orig: mov eax, [ecx+0x34]
        0x83, 0xC1, 0x28,               // 33 add ecx, 0x28
        0xE9, 0, 0, 0, 0 };             // 36 jmp 0x5665C6
    BYTE* s2 = MakeStub(get, sizeof get);
    if (s2) {
        *(DWORD*)(s2 + 2) = (DWORD)&g_localZero;
        Rel32(s2 + 18, 0x566520);
        Rel32(s2 + 37, 0x5665C6);
        SLog(JumpAt(0x5665C0, s2, 6, getOrig) ? "skater 0 = own skater switch in" : "0x5665C0 not as expected, switch skipped");
    }
}

static void Tick() {
    PatchOnce();
    if (g_localZero && GetTickCount() - g_localZeroTick > 3000) { g_localZero = 0; SLog("skater 0 switch timed out, off"); }
    char* mgr = Mgr();
    if (!mgr) { g_pendingCount = 0; return; }
    void* server = *(void**)(mgr + 4);
    void* client = *(void**)(mgr + 8);
    if (server && OnServer()) Register(server, (void*)&ServerHandler, "host");
    if (client) Register(client, (void*)&ClientHandler, "client");
    if (client) RegisterHorn(client);
    RunHears();
    if (g_stockTick) g_stockTick();
    if (OnServer()) RunHorns(); else g_hornCount = 0;
    for (int i = 0; i < g_pendingCount; ++i) {
        Pending& p = g_pending[i];
        char* s = SkaterById(p.id);
        char* player = PlayerBySkaterId(p.id);
        if (!s || !player) { SLog("look for skater " + std::to_string(p.id) + " skipped: not here"); continue; }
        if (player == LocalPlayerInfo()) continue;
        if (p.fromHostProfile) {
            void* stored = *(void**)(player + kPlayerProf);
            if (stored && RebuildSkater(s, stored)) SLog("rebuilt " + PlayerName(player) + " (host view)");
            continue;
        }
        void* tmp = ReadProfile(p.data, p.len);
        if (!tmp) continue;
        void* stored = *(void**)(player + kPlayerProf);
        if (stored) AssignProfile(stored, tmp);
        if (RebuildSkater(s, tmp)) SLog("rebuilt " + PlayerName(player) + " with the new look");
        FreeProfile(tmp);
    }
    g_pendingCount = 0;
}

// THUGRECOMP_SkinLocalZero on=1|0  (Load Skater online): `Skater = 0` means our own skater while on.
static bool __cdecl CF_SkinLocalZero(void* params, void*) {
    PatchOnce();
    g_localZero = IntParam(params, "on", 0) ? 1 : 0;
    g_localZeroTick = GetTickCount();
    return true;
}

// THUGRECOMP_SkinHello  (client; the callback of the host's greeting panel block) remembers that this host
// runs dadmod and answers with a hello, so the host forwards other players' new looks to us.
static bool __cdecl CF_SkinHello(void*, void*) {
    char* mgr = Mgr();
    if (!mgr || OnServer()) return true;
    void* client = *(void**)(mgr + 8);
    if (!client) return false;
    Register(client, (void*)&ClientHandler, "client");
    g_greetApp = client;
    static BYTE hello[4] = { kMagic, kSubHello, 0, 0 };
    SendToServer(hello, 4);
    SLog("greeted by a dadmod host, said hello");
    return true;
}

// THUGRECOMP_SkinSend  after a mid-game Load Skater online: shows our new look to the other players.
// False when this host does not run dadmod (then only a rejoin shows it).
static bool __cdecl CF_SkinSend(void*, void*) {
    char* mgr = Mgr();
    char* me = LocalPlayerInfo();
    char* mod = *(char**)kSkateModPtr;
    if (!mgr || !me || !mod) return false;
    typedef void* (THISCALL* GetFn)(void*, int);
    void* mine = ((GetFn)kGetProfile)(mod, 0);
    if (!mine) return false;
    static BYTE buf[kMaxProfile + 8];
    if (OnServer()) {
        int n = PackProfile(mine, buf, kMaxProfile);
        if (n <= 0 || n > kMaxSend) { SLog("Load Skater: look too big to send live (" + std::to_string(n) + " bytes)"); return false; }
        HostTakeLook(me, buf, n);
        return true;
    }
    void* client = *(void**)(mgr + 8);
    if (!client || client != g_greetApp) {
        SLog("Load Skater: this host has not greeted us as dadmod, the look shows after a rejoin");
        return false;
    }
    buf[0] = kMagic; buf[1] = kSubSkin; buf[2] = 0; buf[3] = 0;
    int n = PackProfile(mine, buf + 4, kMaxProfile);
    if (n <= 0 || n > kMaxSend) { SLog("Load Skater: look too big to send live (" + std::to_string(n) + " bytes)"); return false; }
    SendToServer(buf, n + 4);
    SLog("Load Skater: new look sent to the host (" + std::to_string(n) + " bytes)");
    return true;
}

// THUGRECOMP_CarsHornSend  (cars 2.0, we honk in a net game): sends the 0x39 horn to the host, which relays it to
// every other player on any server; dadmod players hear it from our car (HornHandler). Max one per second.
static bool __cdecl CF_CarsHornSend(void*, void*) {
    char* mgr = Mgr();
    char* me = LocalPlayerInfo();
    if (!mgr || !me) return false;
    void* client = *(void**)(mgr + 8);
    if (!client) return false;
    static DWORD s_last;
    if (s_last && GetTickCount() - s_last < 1000) return false;
    s_last = GetTickCount();
    int id = PlayerSkaterId(me);
    if (id < 0 || id > 15) return false;
    static BYTE horn[4];
    horn[0] = (BYTE)id; horn[1] = 'D'; horn[2] = 'H'; horn[3] = 1;
    BYTE desc[0x20];
    typedef void (THISCALL* CtorFn)(void*);
    memset(desc, 0, 0x20);
    ((CtorFn)kMsgDescCtorF)(desc);
    desc[0] = kHornMsg;
    *(WORD*)(desc + 2) = 4;
    *(void**)(desc + 4) = horn;
    *(int*)(desc + 0xC) = 2;
    desc[0x10] = 8;
    typedef void (THISCALL* Fn)(void*, void*);
    ((Fn)kClientSendF)(client, desc);
    return true;
}

// THUGRECOMP_SkinHorn  (cars 2.0, a dadmod guest honks): tells a dadmod host, which plays it for everyone.
// False (nothing sent) when we are the host or this host has not greeted us as dadmod (a stock host never gets it).
static bool __cdecl CF_SkinHorn(void*, void*) {
    char* mgr = Mgr();
    if (!mgr || OnServer()) return false;
    void* client = *(void**)(mgr + 8);
    if (!client || client != g_greetApp) return false;
    static DWORD s_last;
    if (s_last && GetTickCount() - s_last < 1000) return false;
    s_last = GetTickCount();
    static BYTE horn[4] = { kMagic, kSubHorn, 0, 0 };
    SendToServer(horn, 4);
    return true;
}

}  // namespace skin
