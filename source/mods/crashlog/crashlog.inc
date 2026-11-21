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

static void Install() {
    GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                       (LPCSTR)&Handler, &g_self);
    SetUnhandledExceptionFilter(Handler);
    PatchFireEventNullTarget();
    PatchNetSendNullClient();
    PatchLevelNameLookup();
}

}  // namespace crashlog
