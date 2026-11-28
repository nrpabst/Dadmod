// Crash breadcrumbs: when the game dies of an unhandled exception, append to dadmod\crash.log the faulting address, the
// registers, the return addresses found on the stack (THUGPro.exe and binkw32.dll code only) and the last few lines of dadmod\mainmenu.log.
// Unhandled-exception filter (a first-chance handler deadlocked boot): it only writes the log and then lets
// Windows report the crash as before. No CRT or heap use inside, since the heap may be what broke.
namespace crashlog {

static LONG g_entries = 0;
static HMODULE g_self = nullptr;

static bool InModule(HMODULE m, DWORD a, DWORD* off) {
    if (!m) return false;
    auto dos = (IMAGE_DOS_HEADER*)m;
    auto nt = (IMAGE_NT_HEADERS*)((BYTE*)m + dos->e_lfanew);
    DWORD base = (DWORD)m, size = nt->OptionalHeader.SizeOfImage;
    if (a < base || a >= base + size) return false;
    if (off) *off = a - base;
    return true;
}

static void Where(char* out, size_t n, DWORD a) {
    DWORD off;
    if (InModule(GetModuleHandleA(nullptr), a, &off)) snprintf(out, n, "THUGPro+0x%06lX (0x%08lX)", off, a);
    else if (InModule(g_self, a, &off)) snprintf(out, n, "binkw32+0x%05lX", off);
    else snprintf(out, n, "0x%08lX", a);
}

static void Put(HANDLE f, const char* s) { DWORD w; WriteFile(f, s, (DWORD)strlen(s), &w, nullptr); }

static LONG WINAPI Handler(EXCEPTION_POINTERS* ep) {
    if (InterlockedIncrement(&g_entries) > 1) return EXCEPTION_CONTINUE_SEARCH;
    // only Win32 calls and stack buffers here: the heap may be the thing that is broken
    char path[MAX_PATH], line[256], w[64];
    DWORD n = GetModuleFileNameA(nullptr, path, MAX_PATH);
    while (n > 0 && path[n - 1] != '\\') --n;
    path[n] = 0;
    char logp[MAX_PATH], mlp[MAX_PATH];
    snprintf(logp, sizeof logp, "%sdadmod\\crash.log", path);
    snprintf(mlp, sizeof mlp, "%sdadmod\\mainmenu.log", path);
    HANDLE f = CreateFileA(logp, FILE_APPEND_DATA, FILE_SHARE_READ, nullptr, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (f == INVALID_HANDLE_VALUE) return EXCEPTION_CONTINUE_SEARCH;
    CONTEXT* c = ep->ContextRecord;
    DWORD code = ep->ExceptionRecord->ExceptionCode;
    SYSTEMTIME t; GetLocalTime(&t);
    snprintf(line, sizeof line, "==== %04d-%02d-%02d %02d:%02d:%02d  exception 0x%08lX\r\n", t.wYear, t.wMonth, t.wDay,
             t.wHour, t.wMinute, t.wSecond, code);
    Put(f, line);
    Where(w, sizeof w, c->Eip);
    snprintf(line, sizeof line, "at %s", w); Put(f, line);
    if (code == EXCEPTION_ACCESS_VIOLATION && ep->ExceptionRecord->NumberParameters >= 2) {
        ULONG_PTR rw = ep->ExceptionRecord->ExceptionInformation[0];
        snprintf(line, sizeof line, "  (%s 0x%08lX)", rw == 0 ? "reading" : rw == 1 ? "writing" : "executing",
                 (DWORD)ep->ExceptionRecord->ExceptionInformation[1]);
        Put(f, line);
    }
    Put(f, "\r\n");
    snprintf(line, sizeof line, "eax=%08lX ebx=%08lX ecx=%08lX edx=%08lX esi=%08lX edi=%08lX ebp=%08lX esp=%08lX\r\n",
             c->Eax, c->Ebx, c->Ecx, c->Edx, c->Esi, c->Edi, c->Ebp, c->Esp);
    Put(f, line);
    Put(f, "stack (return addresses):\r\n");
    DWORD* sp = (DWORD*)c->Esp;
    int found = 0;
    MEMORY_BASIC_INFORMATION mbi;
    if (VirtualQuery(sp, &mbi, sizeof mbi)) {
        DWORD* end = (DWORD*)((BYTE*)mbi.BaseAddress + mbi.RegionSize);
        for (int i = 0; i < 1024 && sp + i < end && found < 24; ++i) {
            DWORD v = sp[i], off;
            if (InModule(GetModuleHandleA(nullptr), v, &off) || InModule(g_self, v, &off)) {
                Where(w, sizeof w, v);
                snprintf(line, sizeof line, "  [esp+%03X] %s\r\n", i * 4, w);
                Put(f, line);
                ++found;
            }
        }
    }
    HANDLE m = CreateFileA(mlp, GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr, OPEN_EXISTING, 0, nullptr);
    if (m != INVALID_HANDLE_VALUE) {
        char buf[1024];
        DWORD size = GetFileSize(m, nullptr), got = 0;
        SetFilePointer(m, size > sizeof buf - 1 ? (LONG)(size - (sizeof buf - 1)) : 0, nullptr, FILE_BEGIN);
        ReadFile(m, buf, sizeof buf - 1, &got, nullptr);
        buf[got] = 0;
        CloseHandle(m);
        Put(f, "last mainmenu.log lines:\r\n"); Put(f, buf); Put(f, "\r\n");
    }
    Put(f, "\r\n");
    CloseHandle(f);
    return EXCEPTION_CONTINUE_SEARCH;
}

// FireEvent to a target id that is neither an object nor a running script: the engine's send-event code
// (0x462F00) calls a no-op warning and then still passes the event to a NULL script (call 0x473800 from
// 0x463295, return 0x46329A), which crashes at 0x473800 reading 0xA4 (10 Dev crash.log entries, mostly
// focus events on a menu torn down at the main menu). Turning the push at 0x46327F into a jump to the
// normal exit 0x4632A8 makes a missing target do nothing. Only patched when the original bytes are there.
static void PatchFireEventNullTarget() {
    BYTE* at = (BYTE*)0x46327F;
    static const BYTE orig[5] = { 0x68, 0x00, 0x04, 0x00, 0x00 };  // push 0x400
    if (memcmp(at, orig, sizeof orig) != 0) {
        DebugLog("crashlog: FireEvent null-target patch skipped, bytes at 0x46327F differ");
        return;
    }
    DWORD old;
    if (!VirtualProtect(at, 2, PAGE_EXECUTE_READWRITE, &old)) return;
    at[0] = 0xEB; at[1] = 0x27;  // jmp 0x4632A8
    VirtualProtect(at, 2, old, &old);
    FlushInstructionCache(GetCurrentProcess(), at, 2);
}

// Net message send to a missing client: 0x459E50 (thiscall(client, msg*), ret 4) reads client+0x1E98 with no null
// check. Skater code fetches the client with 0x532EA0 (net manager slot) and calls it straight away; when that slot
// is empty it crashed at 0x459E71 reading 0x1E98 (Dev crash.log 2026-11-19 11:18, 2026-11-20 20:00:29 and 20:02:22:
// trick score msg 0x52 from 0x5647C6, msg 0x35 from 0x444D34, while hosting with Cars 2.0 in use). The first 7 bytes
// become a jump to a stub that returns at once for a NULL client and otherwise runs the original code.
static void PatchNetSendNullClient() {
    BYTE* at = (BYTE*)0x459E50;
    static const BYTE orig[7] = { 0x6A, 0xFF, 0x68, 0x78, 0x82, 0x63, 0x00 };  // push -1; push 0x638278
    if (memcmp(at, orig, sizeof orig) != 0) {
        DebugLog("crashlog: net send null-client patch skipped, bytes at 0x459E50 differ");
        return;
    }
    BYTE* stub = (BYTE*)VirtualAlloc(nullptr, 32, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
    if (!stub) return;
    BYTE* s = stub;
    *s++ = 0x85; *s++ = 0xC9;                    // test ecx, ecx
    *s++ = 0x75; *s++ = 0x03;                    // jnz +3
    *s++ = 0xC2; *s++ = 0x04; *s++ = 0x00;       // ret 4
    memcpy(s, orig, sizeof orig); s += sizeof orig;
    *s = 0xE9; *(DWORD*)(s + 1) = 0x459E57 - (DWORD)(s + 5); s += 5;   // jmp 0x459E57
    FlushInstructionCache(GetCurrentProcess(), stub, 32);
    DWORD old;
    if (!VirtualProtect(at, 7, PAGE_EXECUTE_READWRITE, &old)) return;
    at[0] = 0xE9; *(DWORD*)(at + 1) = (DWORD)stub - (0x459E50 + 5);
    at[5] = 0x90; at[6] = 0x90;
    VirtualProtect(at, 7, old, &old);
    FlushInstructionCache(GetCurrentProcess(), at, 7);
}

// Level name lookup (0x5369A0, thiscall(skate mod, bool), ret 4): matches the current level (this+0x34) against
// level_select_menu_level_info and returns its text, or NULL. Our level-select tab scripts (THPG tab:
// Load_dadmod_THPGLarxBaltimore etc.) aren't in that list, so it returned NULL and hosting crashed in the
// server-list report (0x53F960 -> 0x5FA010 strlen(NULL), 2026-11-18). The hook keeps the stock answer and, when there
// is none, looks the level up in every level_select_tabs list. The report call site also gets "" instead of NULL.
typedef const char* (__fastcall* LevelNameFn)(void* self, void* edx, int flag);
static BYTE g_lnTramp[16];
static const DWORD kGlobalArray = 0x479070;   // CArray* cdecl(DWORD name, int) or NULL
static const DWORD kArrayAt     = 0x46CC30;   // void* __thiscall CArray::At(int)
static const DWORD kStrChecksum = 0x476950;   // bool __thiscall CStruct::GetChecksum(DWORD, DWORD*, bool)
static const DWORD kStrString   = 0x476C60;   // bool __thiscall CStruct::GetString(DWORD, const char**, bool)

static void* GlobalArray(DWORD name) { return ((void*(__cdecl*)(DWORD, int))kGlobalArray)(name, 0); }
static void* ArrayAt(void* a, int i) { return ((void*(__thiscall*)(void*, int))kArrayAt)(a, i); }
static bool StructChecksum(void* s, DWORD k, DWORD* out) {
    return ((bool(__thiscall*)(void*, DWORD, DWORD*, bool))kStrChecksum)(s, k, out, false);
}
static bool StructString(void* s, DWORD k, const char** out) {
    return ((bool(__thiscall*)(void*, DWORD, const char**, bool))kStrString)(s, k, out, false);
}

static const char* TabLevelName(DWORD level) {
    const DWORD kTabs = 0xB4F8F12D, kLevels = 0x60D59BE6, kLevel = 0x651533EC, kText = 0xC4745838;
    void* tabs = GlobalArray(kTabs);
    if (!tabs) return nullptr;
    int nt = *(int*)((BYTE*)tabs + 4);
    for (int t = 0; t < nt; t++) {
        void* tab = ArrayAt(tabs, t);
        DWORD listName = 0;
        if (!tab || !StructChecksum(tab, kLevels, &listName)) continue;
        void* list = GlobalArray(listName);
        if (!list) continue;
        int n = *(int*)((BYTE*)list + 4);
        for (int i = 0; i < n; i++) {
            void* e = ArrayAt(list, i);
            DWORD lv = 0;
            const char* text = nullptr;
            if (e && StructChecksum(e, kLevel, &lv) && lv == level && StructString(e, kText, &text) && text)
                return text;
        }
    }
    return nullptr;
}

static const char* __fastcall LevelNameHook(void* self, void* edx, int flag) {
    const char* s = ((LevelNameFn)(void*)g_lnTramp)(self, edx, flag);
    if (!s && self) s = TabLevelName(*(DWORD*)((BYTE*)self + 0x34));
    return s;
}

static const char* __fastcall LevelNameReport(void* self, void* edx, int flag) {
    const char* s = LevelNameHook(self, edx, flag);
    return s ? s : "";
}

static void PatchLevelNameLookup() {
    BYTE* fn = (BYTE*)0x5369A0;
    BYTE* site = (BYTE*)0x53F960;
    static const BYTE origFn[5] = { 0x51, 0x53, 0x55, 0x56, 0x57 };   // push ecx/ebx/ebp/esi/edi
    static const BYTE origSite[5] = { 0xE8, 0x3B, 0x70, 0xFF, 0xFF }; // call 0x5369A0
    if (memcmp(fn, origFn, 5) != 0 || memcmp(site, origSite, 5) != 0) {
        DebugLog("crashlog: level name patch skipped, bytes at 0x5369A0/0x53F960 differ");
        return;
    }
    DWORD old;
    if (!VirtualProtect(g_lnTramp, sizeof g_lnTramp, PAGE_EXECUTE_READWRITE, &old)) return;
    memcpy(g_lnTramp, origFn, 5);
    g_lnTramp[5] = 0xE9;
    *(DWORD*)(g_lnTramp + 6) = (DWORD)(fn + 5) - (DWORD)(g_lnTramp + 10);
    if (!VirtualProtect(site, 5, PAGE_EXECUTE_READWRITE, &old)) return;
    *(DWORD*)(site + 1) = (DWORD)&LevelNameReport - (DWORD)(site + 5);
    VirtualProtect(site, 5, old, &old);
    if (!VirtualProtect(fn, 5, PAGE_EXECUTE_READWRITE, &old)) return;
    fn[0] = 0xE9;
    *(DWORD*)(fn + 1) = (DWORD)&LevelNameHook - (DWORD)(fn + 5);
    VirtualProtect(fn, 5, old, &old);
    FlushInstructionCache(GetCurrentProcess(), fn, 5);
    FlushInstructionCache(GetCurrentProcess(), site, 5);
}

// Skater camera update (0x4FA860, __fastcall(cam), no stack args, plain ret). cam+0x170 is the skater it follows.
// A1: as a level starts from Level Select, the target skater can be there without its SkaterCorePhysics component yet;
//     0x4FBC53 calls GetComponent(0x5BD63B29) and 0x4FBC58 read [NULL+0x152C] (4 crashes in a player's 0.10.0
//     crash.log, 2 in Dev 2026-11-17/18). A NULL component (or NULL +0x152C) now takes the same path as
//     [[c+0x152C]+0x18] == 0 (jump to 0x4FBC71).
// A2: returning from a level to the main menu, the camera ran one more update on a freed skater (GetComponent faulted
//     reading obj+0x100, return 0x4FA9BD). The entry now checks that a non-NULL target is still the local skater or in
//     the Skate mod's skater list (GetSkater returns NULL past the end); when it isn't, this frame is skipped.
static const DWORD kCgSkateMod = 0x7CE478, kCgGetSkater = 0x5665C0, kCgLocalSkater = 0x566520;
static volatile LONG g_camSkipLogged = 0;

static void CamGuardLogOnce() {
    if (InterlockedExchange(&g_camSkipLogged, 1)) return;
    char path[MAX_PATH], line[160];
    DWORD n = GetModuleFileNameA(nullptr, path, MAX_PATH);
    while (n > 0 && path[n - 1] != '\\') --n;
    path[n] = 0;
    char logp[MAX_PATH];
    snprintf(logp, sizeof logp, "%sdadmod\\mainmenu.log", path);
    SYSTEMTIME t; GetLocalTime(&t);
    snprintf(line, sizeof line, "%02d:%02d:%02d camera guard: skipped a frame, its skater was gone\r\n", t.wHour, t.wMinute,
             t.wSecond);
    HANDLE f = CreateFileA(logp, FILE_APPEND_DATA, FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr, OPEN_ALWAYS,
                           FILE_ATTRIBUTE_NORMAL, nullptr);
    if (f != INVALID_HANDLE_VALUE) { Put(f, line); CloseHandle(f); }
}

static bool __fastcall CamTargetLive(BYTE* cam) {
    void* target = *(void**)(cam + 0x170);
    if (!target) return true;                    // the original returns early on its own
    void* mod = *(void**)kCgSkateMod;
    if (!mod) return true;                       // can't tell: leave it to the original
    if (((void*(__thiscall*)(void*))kCgLocalSkater)(mod) == target) return true;
    for (unsigned i = 0; i < 64; ++i) {
        void* s = ((void*(__thiscall*)(void*, unsigned))kCgGetSkater)(mod, i);
        if (!s) break;
        if (s == target) return true;
    }
    CamGuardLogOnce();
    return false;
}

static void PatchSkaterCamera() {
    BYTE* entry = (BYTE*)0x4FA860;
    BYTE* site = (BYTE*)0x4FBC58;
    static const BYTE origEntry[6] = { 0x64, 0xA1, 0x00, 0x00, 0x00, 0x00 };   // mov eax, fs:[0]
    static const BYTE origSite[11] = { 0x8B, 0x80, 0x2C, 0x15, 0x00, 0x00,     // mov eax, [eax+0x152C]
                                       0x39, 0x68, 0x18, 0x74, 0x0E };          // cmp [eax+0x18], ebp; je 0x4FBC71
    BYTE* stub = (BYTE*)VirtualAlloc(nullptr, 96, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
    if (!stub) return;
    DWORD old;
    if (memcmp(site, origSite, sizeof origSite) == 0) {
        BYTE* s = stub;
        *s++ = 0x85; *s++ = 0xC0;                                    // test eax, eax
        *s++ = 0x0F; *s++ = 0x84; *(DWORD*)s = 0x4FBC71 - (DWORD)(s + 4); s += 4;   // jz 0x4FBC71
        memcpy(s, origSite, 6); s += 6;                              // mov eax, [eax+0x152C]
        *s++ = 0x85; *s++ = 0xC0;                                    // test eax, eax
        *s++ = 0x0F; *s++ = 0x84; *(DWORD*)s = 0x4FBC71 - (DWORD)(s + 4); s += 4;   // jz 0x4FBC71
        *s++ = 0x39; *s++ = 0x68; *s++ = 0x18;                       // cmp [eax+0x18], ebp
        *s++ = 0x0F; *s++ = 0x84; *(DWORD*)s = 0x4FBC71 - (DWORD)(s + 4); s += 4;   // je 0x4FBC71
        *s = 0xE9; *(DWORD*)(s + 1) = 0x4FBC63 - (DWORD)(s + 5);     // jmp 0x4FBC63
        if (VirtualProtect(site, sizeof origSite, PAGE_EXECUTE_READWRITE, &old)) {
            site[0] = 0xE9; *(DWORD*)(site + 1) = (DWORD)stub - (0x4FBC58 + 5);
            for (int i = 5; i < (int)sizeof origSite; ++i) site[i] = 0x90;
            VirtualProtect(site, sizeof origSite, old, &old);
            FlushInstructionCache(GetCurrentProcess(), site, sizeof origSite);
            DebugLog("crashlog: skater camera null-physics guard applied (0x4FBC58)");
        }
    } else {
        DebugLog("crashlog: skater camera null-physics guard skipped, bytes at 0x4FBC58 differ");
    }
    if (memcmp(entry, origEntry, sizeof origEntry) == 0) {
        BYTE* s = stub + 48;
        BYTE* e = s;
        *s++ = 0x51; *s++ = 0x52;                                    // push ecx; push edx
        *s = 0xE8; *(DWORD*)(s + 1) = (DWORD)&CamTargetLive - (DWORD)(s + 5); s += 5;   // call CamTargetLive (ecx = cam)
        *s++ = 0x5A; *s++ = 0x59;                                    // pop edx; pop ecx
        *s++ = 0x84; *s++ = 0xC0;                                    // test al, al
        *s++ = 0x75; *s++ = 0x01;                                    // jnz +1
        *s++ = 0xC3;                                                 // ret (skip this frame)
        memcpy(s, origEntry, 6); s += 6;                             // mov eax, fs:[0]
        *s = 0xE9; *(DWORD*)(s + 1) = 0x4FA866 - (DWORD)(s + 5);     // jmp 0x4FA866
        if (VirtualProtect(entry, 6, PAGE_EXECUTE_READWRITE, &old)) {
            entry[0] = 0xE9; *(DWORD*)(entry + 1) = (DWORD)e - (0x4FA860 + 5);
            entry[5] = 0x90;
            VirtualProtect(entry, 6, old, &old);
            FlushInstructionCache(GetCurrentProcess(), entry, 6);
            DebugLog("crashlog: skater camera stale-target guard applied (0x4FA860)");
        }
    } else {
        DebugLog("crashlog: skater camera stale-target guard skipped, bytes at 0x4FA860 differ");
    }
    FlushInstructionCache(GetCurrentProcess(), stub, 96);
}

// Global flags out of range (2026-11-22): SetGlobalFlag / UnSetGlobalFlag / GetGlobalFlag (0x5843A0 / 0x5843D0 /
// 0x584400, __thiscall(career, flag), ret 4) keep 512 flags in 0x40 bytes at career+0x5F0 with no bounds check.
// THUG Pro's own scripts use bigger flag numbers: the Auto-Goto flag #"0xae8d5911" = 4240 lands on career+0x800 bit 16,
// which is the heap block header of a career list object; UnSetGlobalFlag on it (level_select_change_level_quit,
// set_custom_restart, Auto-Goto off) turns its allocator 0x7D1098 into 0x7C1098 and quitting the game then crashed in
// MemMgr::Free at 0x5BA0CA reading 0x20 (a player 3x on 2026-11-19/20, Dev about 10x 2026-11-16..21). Flags 0-511 keep
// the original storage; bigger ones get their own bits here instead of writing into the heap; negative ones are ignored.
static DWORD g_extFlags[512];   // flags 512 .. 16383
static bool ExtFlag(int flag, DWORD** word, DWORD* bit) {
    if (flag < 512 || flag >= 512 + 512 * 32) return false;
    *word = &g_extFlags[(flag - 512) >> 5];
    *bit = 1u << (flag & 31);
    return true;
}
static void __fastcall SetFlagHook(BYTE* career, void*, int flag) {
    DWORD* w; DWORD b;
    if (flag >= 0 && flag < 512) *(DWORD*)(career + 0x5F0 + (flag >> 5) * 4) |= 1u << (flag & 31);
    else if (ExtFlag(flag, &w, &b)) *w |= b;
}
static void __fastcall UnSetFlagHook(BYTE* career, void*, int flag) {
    DWORD* w; DWORD b;
    if (flag >= 0 && flag < 512) *(DWORD*)(career + 0x5F0 + (flag >> 5) * 4) &= ~(1u << (flag & 31));
    else if (ExtFlag(flag, &w, &b)) *w &= ~b;
}
static bool __fastcall GetFlagHook(BYTE* career, void*, int flag) {
    DWORD* w; DWORD b;
    if (flag >= 0 && flag < 512) return (*(DWORD*)(career + 0x5F0 + (flag >> 5) * 4) & (1u << (flag & 31))) != 0;
    if (ExtFlag(flag, &w, &b)) return (*w & b) != 0;
    return false;
}
static void PatchGlobalFlags() {
    static const BYTE setUnset[16] = { 0x8B, 0xC1, 0x8B, 0x4C, 0x24, 0x04, 0x8B, 0xD1, 0xC1, 0xFA, 0x05, 0x8D, 0x84, 0x90, 0xF0, 0x05 };
    static const BYTE get[8] = { 0x8B, 0x44, 0x24, 0x04, 0x8B, 0xD1, 0x8B, 0xC8 };
    BYTE* fs = (BYTE*)0x5843A0; BYTE* fu = (BYTE*)0x5843D0; BYTE* fg = (BYTE*)0x584400;
    if (memcmp(fs, setUnset, 16) != 0 || memcmp(fu, setUnset, 16) != 0 || memcmp(fg, get, 8) != 0 ||
        fs[0x1C] != 0x09 || fu[0x1E] != 0xF7) {
        DebugLog("crashlog: global flag bounds patch skipped, bytes at 0x5843A0/0x5843D0/0x584400 differ");
        return;
    }
    struct { BYTE* at; void* fn; } p[3] = { { fs, (void*)&SetFlagHook }, { fu, (void*)&UnSetFlagHook }, { fg, (void*)&GetFlagHook } };
    for (auto& e : p) {
        DWORD old;
        if (!VirtualProtect(e.at, 5, PAGE_EXECUTE_READWRITE, &old)) return;
        e.at[0] = 0xE9; *(DWORD*)(e.at + 1) = (DWORD)e.fn - ((DWORD)e.at + 5);
        VirtualProtect(e.at, 5, old, &old);
        FlushInstructionCache(GetCurrentProcess(), e.at, 5);
    }
    DebugLog("crashlog: global flag bounds patch applied (flags 512+ kept apart from the career data)");
}

// Particle vertex buffer NULL (2026-11-22): the particle draw 0x4D5290 locks its dynamic vertex buffer once a frame
// ([edi+8]->Lock at 0x4D54CF..0x4D54E0) but the buffer comes from 0x4D3FF0, which ignores a failed
// CreateVertexBuffer, so it crashed at 0x4D54DD reading 0 (a player 2026-11-20 on 0.9.16, Dev 2026-11-17). At 0x4D54B8
// (nothing pushed yet, same stack depth as 0x4D56DB, where both draw paths meet) a NULL buffer now skips this
// particle system's draw for the frame; the render state restore after 0x4D56DB still runs.
static void PatchParticleNullVB() {
    BYTE* at = (BYTE*)0x4D54B8;
    static const BYTE orig[10] = { 0x8B, 0x0F, 0x8B, 0x47, 0x0C, 0x68, 0x00, 0x20, 0x00, 0x00 };
    if (memcmp(at, orig, sizeof orig) != 0 || memcmp((BYTE*)0x4D56DB, "\x80\x3E\x00\x5F", 4) != 0) {
        DebugLog("crashlog: particle null vertex buffer guard skipped, bytes at 0x4D54B8 differ");
        return;
    }
    BYTE* stub = (BYTE*)VirtualAlloc(nullptr, 32, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
    if (!stub) return;
    BYTE* s = stub;
    *s++ = 0x83; *s++ = 0x7F; *s++ = 0x08; *s++ = 0x00;                       // cmp dword ptr [edi+8], 0
    *s++ = 0x0F; *s++ = 0x84; *(DWORD*)s = 0x4D56DB - (DWORD)(s + 4); s += 4;  // je 0x4D56DB
    memcpy(s, orig, 5); s += 5;                                                // mov ecx,[edi]; mov eax,[edi+0xC]
    *s = 0xE9; *(DWORD*)(s + 1) = 0x4D54BD - (DWORD)(s + 5);                   // jmp 0x4D54BD
    FlushInstructionCache(GetCurrentProcess(), stub, 32);
    DWORD old;
    if (!VirtualProtect(at, 5, PAGE_EXECUTE_READWRITE, &old)) return;
    at[0] = 0xE9; *(DWORD*)(at + 1) = (DWORD)stub - (0x4D54B8 + 5);
    VirtualProtect(at, 5, old, &old);
    FlushInstructionCache(GetCurrentProcess(), at, 5);
    DebugLog("crashlog: particle null vertex buffer guard applied (0x4D54B8)");
}

// IsAlive on a missing node online (2026-11-23): getting out of a car runs the stock
// ToggleUserControlledVehicleMode_orig -> GoalManager_HideAllGoalPeds 0 -> goal_add_ped_arrow, which does
// "IsAlive name = <trigger_obj_id>" with no NodeExists check. In net games IsAlive (0x5A4DA0) looks the node up
// (0x45C1B0) and hands it to the AbsentInNetGames check 0x565BB0 without a NULL check, so a goal whose trigger node is
// not in the level crashed at 0x476B41 reading 4 (Dev, Barcelona online, twice on car exit). A NULL node now answers
// "not absent" and IsAlive carries on down its normal (offline) path, which handles a missing object.
static volatile LONG g_nodeGuardLogged = 0;

static void NodeGuardLogOnce() {
    if (InterlockedExchange(&g_nodeGuardLogged, 1)) return;
    char path[MAX_PATH], line[160];
    DWORD n = GetModuleFileNameA(nullptr, path, MAX_PATH);
    while (n > 0 && path[n - 1] != '\\') --n;
    path[n] = 0;
    char logp[MAX_PATH];
    snprintf(logp, sizeof logp, "%sdadmod\\mainmenu.log", path);
    SYSTEMTIME t; GetLocalTime(&t);
    snprintf(line, sizeof line, "%02d:%02d:%02d node guard: IsAlive asked about an object this level doesn't have\r\n",
             t.wHour, t.wMinute, t.wSecond);
    HANDLE f = CreateFileA(logp, FILE_APPEND_DATA, FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr, OPEN_ALWAYS,
                           FILE_ATTRIBUTE_NORMAL, nullptr);
    if (f != INVALID_HANDLE_VALUE) { Put(f, line); CloseHandle(f); }
}

static void PatchIsAliveMissingNode() {
    BYTE* at = (BYTE*)0x565BB0;
    static const BYTE orig[9] = { 0x8B, 0x4C, 0x24, 0x04, 0x68, 0xC6, 0x0A, 0x91, 0x68 };   // mov ecx,[esp+4]; push AbsentInNetGames
    if (memcmp(at, orig, sizeof orig) != 0 || at[9] != 0xE8) {
        DebugLog("crashlog: IsAlive missing node guard skipped, bytes at 0x565BB0 differ");
        return;
    }
    BYTE* stub = (BYTE*)VirtualAlloc(nullptr, 32, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
    if (!stub) return;
    BYTE* s = stub;
    memcpy(s, orig, 4); s += 4;                                              // mov ecx, [esp+4]
    *s++ = 0x85; *s++ = 0xC9;                                                // test ecx, ecx
    *s++ = 0x74; *s++ = 0x0A;                                                // jz zero
    memcpy(s, orig + 4, 5); s += 5;                                          // push AbsentInNetGames
    *s = 0xE9; *(DWORD*)(s + 1) = 0x565BB9 - (DWORD)(s + 5); s += 5;         // jmp 0x565BB9 (the original call)
    *s = 0xE8; *(DWORD*)(s + 1) = (DWORD)&NodeGuardLogOnce - (DWORD)(s + 5); s += 5;   // zero: call NodeGuardLogOnce
    *s++ = 0x33; *s++ = 0xC0;                                                // xor eax, eax
    *s++ = 0xC2; *s++ = 0x04; *s++ = 0x00;                                   // ret 4
    FlushInstructionCache(GetCurrentProcess(), stub, 32);
    DWORD old;
    if (!VirtualProtect(at, sizeof orig, PAGE_EXECUTE_READWRITE, &old)) return;
    at[0] = 0xE9; *(DWORD*)(at + 1) = (DWORD)stub - (0x565BB0 + 5);
    for (int i = 5; i < (int)sizeof orig; ++i) at[i] = 0x90;
    VirtualProtect(at, sizeof orig, old, &old);
    FlushInstructionCache(GetCurrentProcess(), at, sizeof orig);
    DebugLog("crashlog: IsAlive missing node guard applied (0x565BB0)");
}

static void Install() {
    GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                       (LPCSTR)&Handler, &g_self);
    SetUnhandledExceptionFilter(Handler);
    PatchFireEventNullTarget();
    PatchNetSendNullClient();
    PatchLevelNameLookup();
    PatchSkaterCamera();
    PatchGlobalFlags();
    PatchParticleNullVB();
    PatchIsAliveMissingNode();
}

}  // namespace crashlog
