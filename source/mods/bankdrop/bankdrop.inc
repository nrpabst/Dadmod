// Bank drops: lets the acid drop land on banks and kickers, not just vert.
// Same three patches as "THUGPro Bank Drops.exe", but the two shared
// constants are swapped for private copies so nothing else in the exe changes.
// Client-side physics: only affects players who run this DLL.
// InstallBankDropHooks() is called from DllMain after InstallHooks(); it starts in the
// state saved in thugrecomp.ini (default on). The in-game switch is the "Bank Drops" item
// in Options > Control Setup > In Air Options.

static float g_bankdrop_max_ny = 0.95f;     // was 0.7071 (cos 45) at 0x6467bc
static float g_bankdrop_down_dist = 32000.0f; // was 4000 at 0x64b8f8
static const DWORD kBankDropJz = 0x502629;   // test byte [esp+0xe8],8 / jz: vert polys only
static const DWORD kBankDropAngleOps[] = { 0x4ff04c, 0x50263a };          // fcomp [0x6467bc]
static const DWORD kBankDropDistOps[] = { 0x4feede, 0x4fef5e, 0x4ff018, 0x502609 }; // fsub [0x64b8f8]
static bool g_bankdrop_ok = false, g_bankdrop_on = false;

static void BankDropWrite(DWORD addr, const void* bytes, int len) {
    DWORD old;
    VirtualProtect((void*)addr, len, PAGE_EXECUTE_READWRITE, &old);
    memcpy((void*)addr, bytes, len);
    VirtualProtect((void*)addr, len, old, &old);
    FlushInstructionCache(GetCurrentProcess(), (void*)addr, len);
}

static void BankDropSet(bool on) {
    if (!g_bankdrop_ok) return;
    BankDropWrite(kBankDropJz, on ? "\x90\x90\x90\x90\x90\x90" : "\x0f\x84\xf4\x00\x00\x00", 6);
    DWORD p = on ? (DWORD)&g_bankdrop_max_ny : 0x6467bc;
    for (DWORD a : kBankDropAngleOps) BankDropWrite(a, &p, 4);
    p = on ? (DWORD)&g_bankdrop_down_dist : 0x64b8f8;
    for (DWORD a : kBankDropDistOps) BankDropWrite(a, &p, 4);
    g_bankdrop_on = on;
}

// thugrecomp.ini next to THUGPro.exe ([bankdrop] enabled=, default on).
static void BankDropIni(char* out) {
    DWORD n = GetModuleFileNameA(nullptr, out, MAX_PATH);
    if (!n || n >= MAX_PATH) { out[0] = 0; return; }
    while (n && out[n - 1] != '\\' && out[n - 1] != '/') --n;
    strcpy(out + n, "dadmod\\thugrecomp.ini");
}

static void InstallBankDropHooks() {
    if (memcmp((void*)kBankDropJz, "\x0f\x84\xf4\x00\x00\x00", 6) != 0) return;
    for (DWORD a : kBankDropAngleOps) if (*(DWORD*)a != 0x006467bc) return;
    for (DWORD a : kBankDropDistOps) if (*(DWORD*)a != 0x0064b8f8) return;
    g_bankdrop_ok = true;
    char ini[MAX_PATH + 16]; BankDropIni(ini);
    BankDropSet(!ini[0] || GetPrivateProfileIntA("bankdrop", "enabled", 1, ini) != 0);
}

// Options > Control Setup > In Air Options > "Bank Drops" (control_setup.q).
static bool __cdecl CF_BankDropsOn(void*, void*) { return g_bankdrop_on; }

// THUGRECOMP_BankDropsSet on=0|1: applies live and saves to thugrecomp.ini.
static bool __cdecl CF_BankDropsSet(void* params, void*) {
    typedef bool (__thiscall* IntFn)(void*, DWORD, int*, bool);
    int on = 1;
    ((IntFn)0x476630)(params, QbKey("on"), &on, false);  // CStruct::GetInteger
    BankDropSet(on != 0);
    char ini[MAX_PATH + 16]; BankDropIni(ini);
    if (ini[0]) WritePrivateProfileStringA("bankdrop", "enabled", g_bankdrop_on ? "1" : "0", ini);
    return g_bankdrop_on;
}

static bool __cdecl CF_BankDrops(void*, void*) {
    BankDropSet(!g_bankdrop_on);
    return g_bankdrop_on;
}
