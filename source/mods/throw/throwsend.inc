// ---- Thrown props for players without dadmod on a host WITHOUT dadmod (Noah 2026-11-24). Shared by the server build
// (Dev is also a client on other people's servers) and the client build (client/native/loader.cpp).
// Plan: work\notes\carstock_test\stockhost_throw_plan.md.
//
// A stock host relays a client's msg 0x48 (run script) to every other player unchanged (0x56A2D0). So when we throw
// one of our types as a client of a host without dadmod, the QB (dadmod_throw_cstock_send) sends the projectile
// itself as 0x48 CreateCompositeObject + a panel-block wake through the host, and this file keeps the normal 0x83
// for that throw from going out (stock Kali would draw a COMBO O, dadmod players would draw a second car).
// Needs skinsync.inc (included before) for the "host greeted us as dadmod" check.
namespace throwsend {

static const DWORD kSendCall   = 0x5B5302;   // call ClientApp::Send inside CF_BroadcastProjectile (0x5B51B0)
static const DWORD kClientSend = 0x459E50;   // void __thiscall ClientApp::Send(MsgDesc*)
static const DWORD kDescCtor   = 0x4549F0;   // MsgDesc::MsgDesc()
static const DWORD kGetStruct  = 0x4767C0;   // bool __thiscall CStruct::GetStructure(DWORD key, CStruct**, bool)
static const DWORD kGetSum     = 0x476950;   // bool __thiscall CStruct::GetChecksum(DWORD key, DWORD*, bool)
static const DWORD kPackStruct = 0x479E20;   // int __cdecl WriteToBuffer(CStruct*, BYTE*, int size, int, int)

static DWORD g_types[128];
static int   g_typeCount = 0;
static int   g_on = -1;          // -1 = not read yet (dadmod\throwstock.txt, shared with throwstock.inc)
static bool  g_patched = false;
static int   g_held = 0;

static void SLogT(const std::string& line) {
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
static void SetOn(int on) { g_on = on ? 1 : 0; }
static bool IsType(DWORD t) {
    for (int i = 0; i < g_typeCount; ++i) if (g_types[i] == t) return true;
    return false;
}
static void AddType(DWORD t) { if (t && !IsType(t) && g_typeCount < 128) g_types[g_typeCount++] = t; }

static char* Mgr() { return *(char**)0x7CCE14; }
static void* ClientApp() { char* m = Mgr(); return m ? *(void**)(m + 8) : nullptr; }
// we are a client in a net game (not the host)
static bool IsClient() { char* m = Mgr(); return m && !(*(DWORD*)m & 1) && ClientApp(); }
// the host did not greet us as dadmod (skinsync.inc: THUGRECOMP_SkinHello records the client App that was greeted)
static bool HostStock() { return IsClient() && skin::g_greetApp != ClientApp(); }

// replaces ClientApp::Send at 0x5B5302. 2026-11-27 (throw fix): it NEVER holds the 0x83 back any more. On 2026-11-24
// Noah threw on a host that did not greet us; the 0x83 was held, the 0x48 went out, and the players without dadmod saw
// nothing (a real THUG Pro server may not relay a player's 0x48; on a dadmod host whose greeting did not arrive the
// held 0x83 also stopped the host's own push). The 0x83 now always goes out (the LAN-proven path: dadmod host pushes
// the real model); dadmod_throw_cstock_send adds the 0x48 copy only when the host did not greet us. Cost: on a stock
// host Kali sees its COMBO O as well, and on a dadmod host that failed to greet, stock players may see two copies.
static void __fastcall SendHook(void* app, void*, BYTE* desc) {
    if (desc && desc[0] == 0x83 && g_typeCount && *(const WORD*)(desc + 2) >= 0x2C) {
        const BYTE* data = *(const BYTE**)(desc + 4);
        if (data && IsType(*(const DWORD*)(data + 0x28)) && On() && HostStock()) {
            if (++g_held == 1 || g_held % 50 == 0)
                SLogT("host without dadmod: our throw goes as 0x83 plus a 0x48 copy (" + std::to_string(g_held) + ")");
        }
    }
    typedef void (__thiscall* Fn)(void*, BYTE*);
    ((Fn)kClientSend)(app, desc);
}

static void Patch() {
    if (g_patched) return;
    g_patched = true;
    BYTE* site = (BYTE*)kSendCall;
    DWORD want = kClientSend - (kSendCall + 5);
    if (site[0] != 0xE8 || *(DWORD*)(site + 1) != want) { SLogT("0x83 send call at 0x5B5302 not as expected, hook skipped"); return; }
    DWORD old;
    if (!VirtualProtect(site, 5, PAGE_EXECUTE_READWRITE, &old)) { SLogT("0x83 send hook: VirtualProtect failed"); return; }
    *(DWORD*)(site + 1) = (DWORD)&SendHook - (kSendCall + 5);
    VirtualProtect(site, 5, old, &old);
    FlushInstructionCache(GetCurrentProcess(), site, 5);
    SLogT("0x83 send hook in (our throws on a host without dadmod also go as 0x48; the 0x83 always goes out)");
}

// THUGRECOMP_ThrowHostStock  true when we are a client in a net game whose host has not greeted us as dadmod.
static bool __cdecl CF_ThrowHostStock(void*, void*) {
    Patch();
    return HostStock();
}

// THUGRECOMP_ThrowSendToServer run=<script> params={...}  client only: 0x48 {script, no object, packed params} to the
// host, which relays it to everyone else (a stock host does). Same payload as obsspawn's SendScriptToPlayer, same desc
// values as the stock 0x83. False when we are not a client or the params don't fit in 0x400 bytes.
static bool __cdecl CF_ThrowSendToServer(void* params, void*) {
    Patch();
    void* app = ClientApp();
    if (!IsClient() || !app) return false;
    DWORD script = 0;
    typedef bool (__thiscall* SumFn)(void*, DWORD, DWORD*, bool);
    if (!((SumFn)kGetSum)(params, QbKey("run"), &script, false) || !script) return false;
    void* sub = nullptr;
    typedef bool (__thiscall* StructFn)(void*, DWORD, void**, bool);
    if (!((StructFn)kGetStruct)(params, QbKey("params"), &sub, false) || !sub) return false;
    static BYTE data[0x410];
    memset(data, 0, sizeof data);
    ((DWORD*)data)[0] = script;
    ((int*)data)[1] = -1;
    typedef int (__cdecl* WriteFn)(void*, BYTE*, int, int, int);
    int n = ((WriteFn)kPackStruct)(sub, data + 8, 0x400, 1, 0);
    if (n <= 0 || n > 0x400) { SLogT("0x48 to the host: params too big"); return false; }
    BYTE desc[0x20];
    memset(desc, 0, sizeof desc);
    typedef void (__thiscall* CtorFn)(void*);
    ((CtorFn)kDescCtor)(desc);
    desc[0] = 0x48;
    *(WORD*)(desc + 2) = (WORD)(n + 8);
    *(void**)(desc + 4) = data;
    *(int*)(desc + 0xC) = 2;
    desc[0x10] = 8;
    typedef void (__thiscall* SendFn)(void*, BYTE*);
    ((SendFn)kClientSend)(app, desc);
    return true;
}

// Client build only (the server build has these in throwstock.inc, which forwards to SetOn / AddType):
// THUGRECOMP_ThrowStockOn [set=0|1] (returns dadmod_tsn = next copy number) and THUGRECOMP_ThrowStockType type=.
static int g_next = 0;
static bool __cdecl CF_ClientStockOn(void* params, void* script) {
    int set = IntParam(params, "set", -1);
    if (set == 0 || set == 1) {
        SetOn(set);
        WriteWholeFile(ExeDirFile("throwstock.txt"), set ? "1\r\n" : "0\r\n");
        SLogT(set ? "option on" : "option off");
    }
    RetInt(script, "dadmod_tsn", g_next);
    g_next = (g_next + 1) % 16;
    return On();
}
static bool __cdecl CF_ClientStockType(void* params, void*) {
    Patch();
    typedef bool (__thiscall* SumFn)(void*, DWORD, DWORD*, bool);
    DWORD t = 0;
    if (!((SumFn)kGetSum)(params, QbKey("type"), &t, false) || !t) return g_typeCount > 0;
    AddType(t);
    return true;
}

}  // namespace throwsend
