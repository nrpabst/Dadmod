// Infinite balance (Pause > dadmod > Balance): glues the meter to the center.
// The stock Perfect Rail / Perfect Manual cheats zero the lean only AFTER the per-frame balance
// update (0x579cc0), which has already drawn the meter with the lean carried into a new trick,
// so the meter showed off-center for one frame. While the lock is on, these call sites zero the
// lean (+0x30) and lean speed (+0x34) BEFORE the update instead. Skitch (0x50f167) is left alone.
// Script turns it on/off with THUGRECOMP_SettingSave key="gfx_balancelock" (gfx.inc forwards it).
namespace balancelock {
static volatile LONG g_on = 0;
static const DWORD kUpdate = 0x579cc0;
static const DWORD kSites[] = { 0x5047a0, 0x50c11c, 0x50e07c, 0x50f200 };  // grind, lip, grind, manual
static DWORD g_update = kUpdate;

static __declspec(naked) void UpdateStub() {
    __asm {
        cmp g_on, 0
        je go
        mov dword ptr [ecx + 0x30], 0
        mov dword ptr [ecx + 0x34], 0
    go:
        jmp dword ptr [g_update]
    }
}

void Set(bool on) { InterlockedExchange(&g_on, on ? 1 : 0); }

static void Install() {
    for (DWORD a : kSites) {
        BYTE* p = (BYTE*)a;
        if (p[0] != 0xE8 || a + 5 + *(int*)(p + 1) != kUpdate) return;  // only the build we analysed
    }
    for (DWORD a : kSites) {
        DWORD old;
        VirtualProtect((void*)a, 5, PAGE_EXECUTE_READWRITE, &old);
        *(int*)(a + 1) = (int)((DWORD)&UpdateStub - (a + 5));
        VirtualProtect((void*)a, 5, old, &old);
        FlushInstructionCache(GetCurrentProcess(), (void*)a, 5);
    }
}
}  // namespace balancelock
