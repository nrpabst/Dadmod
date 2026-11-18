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

static void Install() {
    GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                       (LPCSTR)&Handler, &g_self);
    SetUnhandledExceptionFilter(Handler);
    PatchFireEventNullTarget();
}

}  // namespace crashlog
