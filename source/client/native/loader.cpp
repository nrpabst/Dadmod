// dadmod client loader (binkw32.dll proxy). Client build only; the server build keeps native/thugrecomp.
// Mod code is included straight from its folder under work/mods, so both builds share one copy of it.
//
// THUG Pro loads its scripts once at boot from data\pre\thugpro_qb.prx (the list is code\qb\qdir.txt
// inside it; FUN_005A59D0, called from 0x5A5B2D). We redirect that call: after the game's own scripts
// (stock THUG Pro or Kali, whichever is installed) we load data\pre\dadmod_qb.prx the same way.
// Nothing in thugpro_qb.prx is replaced, so Kali's files are never touched.
//
// Inside dadmod_qb.prx:
//   code\dadmod\wrap.txt  stock script names to wrap. Before our scripts load, each existing script
//                         X is renamed to X_orig in the symbol table, so our X can do its part and
//                         call X_orig <...>. Whatever version the player has keeps running underneath.
//   code\dadmod\qdir.txt  our .qb files, loaded in order (later definitions win).
//
// Proven on a copy of the stock install 2026-11-05 (work/client_spike). Log: <game>\dadmod\client.log.
#include <windows.h>
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <ctype.h>
#include <errno.h>
#include "widefile.inc"   // all file calls go through the wide Windows functions

#ifdef _MSC_VER
#define THISCALL __thiscall
#else
#define THISCALL __attribute__((thiscall))
#endif

// ---- THUGPro.exe (2004-09-14 build, the one every THUG Pro install ships)
static const DWORD kCallRegisterCFuncs = 0x5A5F52;  // E8 -> 0x46EFD0
static const DWORD kRegisterCFuncs     = 0x46EFD0;  // cdecl(CFuncEntry*, count)
static const DWORD kCallLoadStartup    = 0x5A5B2D;  // E8 -> 0x5A59D0 (startup script loader)
static const DWORD kLoadStartup        = 0x5A59D0;
static const DWORD kStructGetString    = 0x476C60;  // thiscall CStruct::GetString(key, const char**, bool)
static const DWORD kMemMgr             = 0x7D1800;  // memory manager*; +0x110 = script heap
static const DWORD kPushHeap           = 0x5BB0E0;  // thiscall(memmgr, heap)
static const DWORD kPopHeap            = 0x5BB110;  // thiscall(memmgr)
static const DWORD kLoadPre            = 0x5B75A0;  // cdecl(name)  name under data\pre
static const DWORD kUnloadPre          = 0x5B7130;  // cdecl(name)
static const DWORD kFileLoad           = 0x5B7C00;  // cdecl(name, 0, 0, 0, 0) -> buffer
static const DWORD kFileSize           = 0x5B72E0;  // cdecl(name) -> size
static const DWORD kFileFree           = 0x5B7270;  // cdecl(name)
static const DWORD kLoadBegin          = 0x476300;  // cdecl()
static const DWORD kLoadEnd            = 0x476310;  // cdecl()
static const DWORD kNameCrc            = 0x401B90;  // cdecl(name) -> checksum
static const DWORD kUnloadFileSyms     = 0x46EEC0;  // cdecl(file checksum): drops symbols from that file
static const DWORD kLoaderFlag         = 0x479070;  // cdecl(0xC472ECC5, 0), as the stock loop does
static const DWORD kLoadQbFile         = 0x46EDE0;  // cdecl(name, 1, 0)
static const DWORD kSymTable           = 0x6F3624;  // symbol buckets[0x1000]: +1 type, +4 name, +8 file, +0x10 next

static const char* kPre  = "dadmod_qb.prx";
static const char* kQdir = "code\\dadmod\\qdir.txt";
static const char* kWrap = "code\\dadmod\\wrap.txt";

static char g_logPath[MAX_PATH];
#ifdef DADMOD_DIAG
// Diagnostic build only (build_diag.bat): dadmod\diag.log and %LOCALAPPDATA%\dadmod_diag\diag.log get a line for
// every startup step, so a player's PC where scripts/settings never show up can tell us which step didn't happen.
static char g_diagGame[MAX_PATH], g_diagApp[MAX_PATH];
static volatile LONG g_diagStartup = 0, g_diagCFuncs = 0, g_diagLoaded = 0, g_diagOkShown = 0;
// Three copies of the log, opened once in DllMain (the moment where writing is known to work) and kept open:
// dadmod\diag.log by full path, dadmod\diag_rel.log by relative path, %LOCALAPPDATA%\dadmod_diag\diag.log.
static HANDLE g_diagH[3] = { INVALID_HANDLE_VALUE, INVALID_HANDLE_VALUE, INVALID_HANDLE_VALUE };
static CRITICAL_SECTION g_diagLock; static bool g_diagLockOk = false;
static void Diag(const char* fmt, ...) {
    DWORD keep = GetLastError();
    char line[1100]; SYSTEMTIME t; GetLocalTime(&t);
    int k = _snprintf(line, 64, "%02d:%02d:%02d.%03d [%lu] ", t.wHour, t.wMinute, t.wSecond, t.wMilliseconds, GetCurrentThreadId());
    va_list ap; va_start(ap, fmt); _vsnprintf(line + k, sizeof line - k - 3, fmt, ap); va_end(ap);
    line[sizeof line - 3] = 0; strcat(line, "\r\n");
    if (g_diagLockOk) EnterCriticalSection(&g_diagLock);
    for (HANDLE h : g_diagH) if (h != INVALID_HANDLE_VALUE) {
        DWORD n; SetFilePointer(h, 0, NULL, FILE_END); WriteFile(h, line, (DWORD)strlen(line), &n, NULL); FlushFileBuffers(h);
    }
    if (g_diagLockOk) LeaveCriticalSection(&g_diagLock);
    SetLastError(keep);
}
static bool DiagIsWrite(DWORD access, DWORD disp) {
    return (access & (GENERIC_WRITE | GENERIC_ALL | FILE_WRITE_DATA | FILE_APPEND_DATA | DELETE)) || disp == CREATE_ALWAYS || disp == CREATE_NEW || disp == TRUNCATE_EXISTING;
}
// Every file call our DLL makes goes through these (macros below): failures are always logged with the Windows
// error, successful writes too (first 400), so the log shows exactly which call stops working and with what code.
static HANDLE WINAPI DiagCreateFileA(LPCSTR path, DWORD access, DWORD share, LPSECURITY_ATTRIBUTES sa, DWORD disp, DWORD flags, HANDLE tmpl) {
    DWORD attrBefore = DmGetFileAttributesA(path);
    HANDLE h = DmCreateFileA(path, access, share, sa, disp, flags, tmpl);
    DWORD e = GetLastError();
    bool wr = DiagIsWrite(access, disp);
    if (h == INVALID_HANDLE_VALUE) {
        if (wr || e != ERROR_FILE_NOT_FOUND && e != ERROR_PATH_NOT_FOUND)
            Diag("OPEN FAILED error %lu: %s (access 0x%lX, share 0x%lX, disposition %lu, existed before: %s)", e, path, access, share, disp, attrBefore == INVALID_FILE_ATTRIBUTES ? "no" : "yes");
    } else if (wr && InterlockedIncrement(&g_diagOkShown) <= 400)
        Diag("open ok: %s (access 0x%lX, disposition %lu, existed before: %s)", path, access, disp, attrBefore == INVALID_FILE_ATTRIBUTES ? "no" : "yes");
    SetLastError(e);
    return h;
}
static BOOL WINAPI DiagWriteFile(HANDLE h, LPCVOID buf, DWORD len, LPDWORD wrote, LPOVERLAPPED ov) {
    BOOL ok = (WriteFile)(h, buf, len, wrote, ov); DWORD e = GetLastError();
    if (!ok || (wrote && *wrote != len)) Diag("WRITE FAILED error %lu: handle %p, %lu of %lu bytes", e, h, wrote ? *wrote : 0, len);
    SetLastError(e); return ok;
}
static BOOL WINAPI DiagMoveFileExA(LPCSTR from, LPCSTR to, DWORD flags) {
    BOOL ok = DmMoveFileExA(from, to, flags); DWORD e = GetLastError();
    if (!ok) Diag("RENAME FAILED error %lu: %s -> %s (flags 0x%lX)", e, from, to ? to : "(null)", flags); else Diag("rename ok: %s -> %s", from, to ? to : "(null)");
    SetLastError(e); return ok;
}
static BOOL WINAPI DiagMoveFileA(LPCSTR from, LPCSTR to) {
    BOOL ok = DmMoveFileA(from, to); DWORD e = GetLastError();
    if (!ok) Diag("RENAME FAILED error %lu: %s -> %s", e, from, to); else Diag("rename ok: %s -> %s", from, to);
    SetLastError(e); return ok;
}
static BOOL WINAPI DiagDeleteFileA(LPCSTR path) {
    BOOL ok = DmDeleteFileA(path); DWORD e = GetLastError();
    if (!ok) { if (e != ERROR_FILE_NOT_FOUND && e != ERROR_PATH_NOT_FOUND) Diag("DELETE FAILED error %lu: %s", e, path); } else Diag("delete ok: %s", path);
    SetLastError(e); return ok;
}
static BOOL WINAPI DiagCreateDirectoryA(LPCSTR path, LPSECURITY_ATTRIBUTES sa) {
    BOOL ok = DmCreateDirectoryA(path, sa); DWORD e = GetLastError();
    if (!ok && e != ERROR_ALREADY_EXISTS) Diag("MKDIR FAILED error %lu: %s", e, path); else if (ok) Diag("mkdir ok: %s", path);
    SetLastError(e); return ok;
}
static BOOL WINAPI DiagWritePrivateProfileStringA(LPCSTR sec, LPCSTR key, LPCSTR val, LPCSTR file) {
    BOOL ok = DmWritePrivateProfileStringA(sec, key, val, file); DWORD e = GetLastError();
    if (!ok) Diag("INI WRITE FAILED error %lu: %s [%s] %s", e, file, sec ? sec : "", key ? key : ""); else Diag("ini write ok: %s [%s] %s", file, sec ? sec : "", key ? key : "");
    SetLastError(e); return ok;
}
static FILE* DiagFopen(const char* path, const char* mode) {
    FILE* f = DmFopen(path, mode); int en = errno; DWORD e = GetLastError();
    if (!f) { if (mode[0] != 'r' || en != ENOENT) Diag("FOPEN FAILED errno %d, error %lu: %s (%s)", en, e, path, mode); } else if (mode[0] != 'r') Diag("fopen ok: %s (%s)", path, mode);
    return f;
}
#undef CreateFileA
#undef MoveFileExA
#undef MoveFileA
#undef DeleteFileA
#undef CreateDirectoryA
#undef WritePrivateProfileStringA
#undef fopen
#define CreateFileA(...) DiagCreateFileA(__VA_ARGS__)
#define WriteFile(...) DiagWriteFile(__VA_ARGS__)
#define MoveFileExA(...) DiagMoveFileExA(__VA_ARGS__)
#define MoveFileA(...) DiagMoveFileA(__VA_ARGS__)
#define DeleteFileA(...) DiagDeleteFileA(__VA_ARGS__)
#define CreateDirectoryA(...) DiagCreateDirectoryA(__VA_ARGS__)
#define WritePrivateProfileStringA(...) DiagWritePrivateProfileStringA(__VA_ARGS__)
#define fopen(...) DiagFopen(__VA_ARGS__)
#else
static void Diag(const char*, ...) {}
#endif
static void Log(const char* fmt, ...) {
    char line[600]; va_list ap; va_start(ap, fmt); _vsnprintf(line, sizeof line - 3, fmt, ap); va_end(ap);
    line[sizeof line - 3] = 0; strcat(line, "\r\n");
    HANDLE f = CreateFileA(g_logPath, FILE_APPEND_DATA, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_ALWAYS, 0, NULL);  // share write: two threads logging at once used to drop a line
    if (f != INVALID_HANDLE_VALUE) { DWORD n; WriteFile(f, line, (DWORD)strlen(line), &n, NULL); CloseHandle(f); }
#ifdef DADMOD_DIAG
    else Diag("client.log write FAILED (error %lu): %s", GetLastError(), line);
    Diag("log: %.300s", line);
#endif
}

static DWORD QbKey(const char* s) {
    DWORD c = 0xFFFFFFFF;
    for (; *s; ++s) {
        unsigned char ch = (unsigned char)tolower((unsigned char)*s);
        if (ch == '/') ch = '\\';
        c ^= ch;
        for (int i = 0; i < 8; ++i) c = (c >> 1) ^ ((c & 1) ? 0xEDB88320 : 0);
    }
    return c;
}

typedef void (__cdecl* Fn0)(void);
typedef void (__cdecl* Fn1)(DWORD);
typedef void (__cdecl* Fn2)(DWORD, DWORD);
typedef void* (__cdecl* FnFileLoad)(const char*, int, int, int, int);
typedef int (__cdecl* FnName)(const char*);
typedef void (__cdecl* FnLoadQb)(const char*, int, int);
typedef void (THISCALL* FnThis0)(void*);
typedef void (THISCALL* FnThis1)(void*, DWORD);
typedef char (THISCALL* FnGetStr)(void*, DWORD, const char**, char);

static BYTE* FindSym(DWORD key, BYTE*** link) {
    BYTE** buckets = *(BYTE***)kSymTable;
    BYTE** pp = &buckets[key & 0xFFF];
    while (*pp) {
        if (*(DWORD*)(*pp + 4) == key) { if (link) *link = pp; return *pp; }
        pp = (BYTE**)(*pp + 0x10);
    }
    return NULL;
}

// Rename the loaded script `name` to `name_orig` (same entry, moved to the new name's bucket).
static void WrapRename(const char* name) {
    char orig[200]; _snprintf(orig, sizeof orig - 1, "%s_orig", name); orig[sizeof orig - 1] = 0;
    DWORD k = QbKey(name), k2 = QbKey(orig);
    BYTE** link; BYTE* e = FindSym(k, &link);
    if (!e) { Log("wrap %s: not defined in this install, skipped", name); return; }
    if (FindSym(k2, NULL)) { Log("wrap %s: %s already exists, skipped", name, orig); return; }
    *link = *(BYTE**)(e + 0x10);
    *(DWORD*)(e + 4) = k2;
    BYTE** buckets = *(BYTE***)kSymTable;
    *(BYTE**)(e + 0x10) = buckets[k2 & 0xFFF];
    buckets[k2 & 0xFFF] = e;
    Log("wrap %s -> %s", name, orig);
}

static void ForEachLine(const char* p, int size, void (*fn)(const char*)) {
    const char* end = p + size; char line[256];
    while (p < end) {
        int i = 0;
        while (p < end && *p != '\r' && *p != '\n') { if (i < 255) line[i++] = *p; p++; }
        line[i] = 0; p++;
        while (i > 0 && (line[i - 1] == ' ' || line[i - 1] == '\t')) line[--i] = 0;
        if (line[0] && line[0] != '#') fn(line);
    }
}

static void LoadOneQb(const char* cline) {
    char line[256]; strncpy(line, cline, 255); line[255] = 0;
    char* s = strstr(line, "data\\");
    if (s) memmove(line, s + 5, strlen(s + 5) + 1);
    ((Fn1)kUnloadFileSyms)((DWORD)((FnName)kNameCrc)(line));
    ((Fn2)kLoaderFlag)(0xC472ECC5, 0);
    ((FnLoadQb)kLoadQbFile)(line, 1, 0);
#ifdef DADMOD_DIAG
    InterlockedIncrement(&g_diagLoaded);
#endif
    Log("loaded %s", line);
}

static void LoadDadmodScripts(void) {
    char path[MAX_PATH]; GetModuleFileNameA(NULL, path, MAX_PATH);
    char* sl = strrchr(path, '\\'); if (sl) sl[1] = 0;
    strcat(path, "data\\pre\\"); strcat(path, kPre);
    if (GetFileAttributesA(path) == INVALID_FILE_ATTRIBUTES) { Log("no data\\pre\\%s, nothing to load", kPre); return; }
    void* mm = *(void**)kMemMgr;
    ((FnThis1)kPushHeap)(mm, *(DWORD*)((BYTE*)mm + 0x110));
    ((FnName)kLoadPre)(kPre);
    ((FnThis0)kPopHeap)(*(void**)kMemMgr);

    const char* w = (const char*)((FnFileLoad)kFileLoad)(kWrap, 0, 0, 0, 0);
    if (w) { ForEachLine(w, ((FnName)kFileSize)(kWrap), WrapRename); ((FnName)kFileFree)(kWrap); }

    const char* q = (const char*)((FnFileLoad)kFileLoad)(kQdir, 0, 0, 0, 0);
    if (q) {
        int n = ((FnName)kFileSize)(kQdir);
        // No kLoadBegin/kLoadEnd here: "begin" turns on string sharing, whose table the game frees at the end
        // of its own boot load (0x476310 frees it but keeps the count), so strings in our globals crashed at
        // 0x4762A0 (2026-11-06). Without it every string just gets its own copy.
        ForEachLine(q, n, LoadOneQb);
        ((FnName)kFileFree)(kQdir);
    } else Log("no %s in %s", kQdir, kPre);
    ((FnName)kUnloadPre)(kPre);
}

// ---- safe start (2026-11-19): a player's game closed on every start, after its window came up and before any script
// loaded, right as the Direct3D hooks attached. dadmod\boot_check.txt is written when the DLL loads and removed once our
// scripts have loaded. If it is still there at the next start, that start never got that far: dadmod\safe_start.txt is
// written and the early Direct3D steps are skipped (gfx::Install(false)) until a normal start works again (see below).
static char g_bootCheck[MAX_PATH], g_safeFile[MAX_PATH];
static bool FileThere(const char* p) { return GetFileAttributesA(p) != INVALID_FILE_ATTRIBUTES; }
static void WriteText(const char* p, const char* text) {
    HANDLE f = CreateFileA(p, GENERIC_WRITE, FILE_SHARE_READ, NULL, CREATE_ALWAYS, 0, NULL);
    if (f != INVALID_HANDLE_VALUE) { DWORD n; WriteFile(f, text, (DWORD)strlen(text), &n, NULL); CloseHandle(f); }
}
// What safe start skips (checked 2026-11-22): only the early Direct3D steps (the CreateDevice import hook and the
// probe thread). The controller-read hook still picks the game's device up a few frames later and puts the graphics
// hooks in, so graphics keep working in safe start.
//
// Auto re-check (2026-11-22): safe_start.txt keeps key lines next to its text: version= (the dadmod version that turned
// it on), good_starts= (safe starts that reached the scripts), tries= / tries_version= (failed normal-start retries on
// this version), retry_next=1 (the player chose "Try a normal start"). boot_check.txt says what the last start was:
// normal, safe or retry. A retry is a normal start made while safe start is on; it happens when tries < 2 for this
// version and (the file came from another version, or good_starts >= 10), or once when the player asks. A retry that
// reaches the scripts ends safe start (the file moves to dadmod\backups); one that doesn't counts a try.
struct SafeState { char version[32]; int good, tries; char triesVer[32]; int retryNext; };
static SafeState g_ss;
static char g_dadVer[32] = "unknown";
static int g_startMode = 0;          // 0 normal, 1 safe, 2 retry
static volatile LONG g_ssJustOn = 0, g_ssBack = 0;

static void ReadSmall(const char* p, char* buf, int size) {
    buf[0] = 0;
    HANDLE f = CreateFileA(p, GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL);
    if (f == INVALID_HANDLE_VALUE) return;
    DWORD n = 0; ReadFile(f, buf, size - 1, &n, NULL); CloseHandle(f);
    buf[n] = 0;
}
static void CopyWord(char* out, int size, const char* s) {   // up to the end of the line, spaces dropped
    int i = 0;
    for (; *s && *s != '\r' && *s != '\n' && i < size - 1; ++s) if (*s != ' ' && *s != '\t') out[i++] = *s;
    out[i] = 0;
}
static const char* KeyLine(const char* text, const char* key) {   // value after "key=" at a line start, or NULL
    size_t kl = strlen(key);
    for (const char* p = text; p && *p; ) {
        if (strncmp(p, key, kl) == 0 && p[kl] == '=') return p + kl + 1;
        p = strchr(p, '\n'); if (p) ++p;
    }
    return NULL;
}
static void LoadSafeState(void) {
    char buf[2048]; ReadSmall(g_safeFile, buf, sizeof buf);
    memset(&g_ss, 0, sizeof g_ss);
    const char* v;
    if ((v = KeyLine(buf, "version"))) CopyWord(g_ss.version, sizeof g_ss.version, v);   // none: an older file
    if ((v = KeyLine(buf, "good_starts"))) g_ss.good = atoi(v);
    if ((v = KeyLine(buf, "tries"))) g_ss.tries = atoi(v);
    if ((v = KeyLine(buf, "tries_version"))) CopyWord(g_ss.triesVer, sizeof g_ss.triesVer, v);
    if ((v = KeyLine(buf, "retry_next"))) g_ss.retryNext = atoi(v);
}
static void SaveSafeState(void) {
    char text[1400];
    _snprintf(text, sizeof text - 1,
        "THUG Pro closed during startup last time, before dadmod's scripts loaded.\r\n"
        "So dadmod now skips one risky startup step (its early Direct3D hook). Everything still works, graphics too.\r\n"
        "dadmod tries a normal start again after an update, or when you pick Dadmod > Graphics > Try a normal start.\r\n"
        "The lines below are for dadmod; please leave them as they are.\r\n"
        "version=%s\r\ngood_starts=%d\r\ntries=%d\r\ntries_version=%s\r\nretry_next=%d\r\n",
        g_ss.version[0] ? g_ss.version : "old", g_ss.good, g_ss.tries, g_ss.triesVer, g_ss.retryNext);
    text[sizeof text - 1] = 0;
    WriteText(g_safeFile, text);
}
static bool SafeStartCheck(void) {
    char dir[MAX_PATH]; strcpy(dir, g_logPath);
    char* sl = strrchr(dir, '\\'); if (sl) sl[1] = 0;
    _snprintf(g_bootCheck, MAX_PATH - 1, "%sboot_check.txt", dir);
    _snprintf(g_safeFile, MAX_PATH - 1, "%ssafe_start.txt", dir);
    char vpath[MAX_PATH], vbuf[64];
    _snprintf(vpath, MAX_PATH - 1, "%sversion.txt", dir); vpath[MAX_PATH - 1] = 0;
    ReadSmall(vpath, vbuf, sizeof vbuf);
    if (vbuf[0]) CopyWord(g_dadVer, sizeof g_dadVer, vbuf);
    bool safe = FileThere(g_safeFile);
    if (safe) LoadSafeState();
    bool justFailed = false;
    if (FileThere(g_bootCheck)) {
        char last[32]; ReadSmall(g_bootCheck, last, sizeof last);
        if (strncmp(last, "retry", 5) == 0) {
            if (!safe) { memset(&g_ss, 0, sizeof g_ss); strcpy(g_ss.version, g_dadVer); }
            if (strcmp(g_ss.triesVer, g_dadVer) != 0) { g_ss.tries = 0; strcpy(g_ss.triesVer, g_dadVer); }
            g_ss.tries++;
            g_ss.good = 0;
            safe = justFailed = true;
            Log("safe start: the last start was a try at a normal start and it closed during startup (try %d on %s), so safe start stays on", g_ss.tries, g_dadVer);
        } else if (strncmp(last, "normal", 6) == 0 || !safe) {
            memset(&g_ss, 0, sizeof g_ss);
            strcpy(g_ss.version, g_dadVer); strcpy(g_ss.triesVer, g_dadVer);
            safe = true;
            InterlockedExchange(&g_ssJustOn, 1);
            Log("safe start: the last start closed before dadmod's scripts loaded, so safe start is on now (dadmod skips its early Direct3D hook; graphics still work)");
        } else {
            Log("safe start: the last safe start closed before dadmod's scripts loaded too, not counted, safe start stays on");
        }
    } else if (safe) {
        g_ss.good++;
        Log("safe start: the last safe start went fine (%d good starts on file)", g_ss.good);
    }
    g_startMode = 0;
    if (safe) {
        if (strcmp(g_ss.triesVer, g_dadVer) != 0) { g_ss.tries = 0; strcpy(g_ss.triesVer, g_dadVer); }
        bool otherVer = strcmp(g_ss.version, g_dadVer) != 0;
        if (g_ss.retryNext) {
            g_ss.retryNext = 0;
            g_startMode = 2;
            Log("safe start: the player asked to try a normal start, trying it now");
        } else if (!justFailed && g_ss.tries < 2 && (otherVer || g_ss.good >= 10)) {
            g_startMode = 2;
            if (otherVer) Log("safe start: safe start came from dadmod %s and this is %s, trying a normal start", g_ss.version[0] ? g_ss.version : "(an older version)", g_dadVer);
            else Log("safe start: %d good safe starts, trying a normal start", g_ss.good);
        } else {
            g_startMode = 1;
            if (g_ss.tries >= 2) Log("safe start: on (2 tries at a normal start failed on %s, the next try comes with an update)", g_dadVer);
            else Log("safe start: on (dadmod\\safe_start.txt), early Direct3D hook skipped");
        }
        SaveSafeState();
    }
    WriteText(g_bootCheck, g_startMode == 2 ? "retry\r\n" : g_startMode == 1 ? "safe\r\n" : "normal\r\n");
    return g_startMode == 1;
}
// a retry reached the scripts: safe start ends; the file goes to dadmod\backups (never deleted)
static void SafeStartReached(void) {
    if (g_startMode != 2) return;
    char dir[MAX_PATH]; strcpy(dir, g_safeFile);
    char* sl = strrchr(dir, '\\'); if (sl) sl[1] = 0;
    char bdir[MAX_PATH], dst[MAX_PATH];
    _snprintf(bdir, MAX_PATH - 1, "%sbackups", dir); bdir[MAX_PATH - 1] = 0;
    CreateDirectoryA(bdir, NULL);
    SYSTEMTIME t; GetLocalTime(&t);
    _snprintf(dst, MAX_PATH - 1, "%s\\safe_start.txt.ended_%04d%02d%02d_%02d%02d%02d", bdir, t.wYear, t.wMonth, t.wDay,
              t.wHour, t.wMinute, t.wSecond);
    dst[MAX_PATH - 1] = 0;
    if (MoveFileExA(g_safeFile, dst, MOVEFILE_REPLACE_EXISTING | MOVEFILE_COPY_ALLOWED))
        Log("safe start: the normal start reached dadmod's scripts, safe start is off again (old file in dadmod\\backups)");
    else Log("safe start: the normal start reached dadmod's scripts, but safe_start.txt could not be moved (error %lu)", GetLastError());
    g_startMode = 0;
    InterlockedExchange(&g_ssBack, 1);
}

static void BeforeGameScripts(void);
static void __cdecl LoadStartupHook(void) {
#ifdef DADMOD_DIAG
    InterlockedExchange(&g_diagStartup, 1);
    Diag("startup script loader reached (our hook ran)");
#endif
    BeforeGameScripts();
    Diag("menu levels assembled, running the game's own startup scripts");
    ((Fn0)kLoadStartup)();
    Diag("game scripts done, loading dadmod_qb.prx");
    LoadDadmodScripts();
    SafeStartReached();
#ifdef DADMOD_DIAG
    Diag("dadmod scripts done: %ld files loaded", g_diagLoaded);
    if (!DeleteFileA(g_bootCheck)) Diag("boot_check.txt delete FAILED (error %lu)", GetLastError());
#else
    DeleteFileA(g_bootCheck);   // this start got past the risky part (safe start)
#endif
}

// ---- mods in the client build (mods/MANIFEST.tsv, client = yes)
#define DADMOD_CLIENT_HAS_MAINMENU
#include "common.inc"
#define DebugLog Log                                // shared mods call DebugLog (Dev DLL name); the client logger is Log
#include "../../mods/crashlog/crashlog.inc"      // dadmod\crash.log breadcrumbs
#include "../../mods/bootspeed/bootspeed.inc"    // skip the level rescan and the boot sleep
#include "../../mods/controller/padhub.inc"      // controller hotplug for player 1
#include "../../mods/mainmenu/mainmenu.inc"      // main menu scenes, menu order, key and text helpers (dadmod\mainmenu.ini)
#include "../../mods/bankdrop/bankdrop.inc"      // bank drops (dadmod\thugrecomp.ini)
#include "texts.inc"                             // saved search texts + script log (client copies)
#include "menulevels.inc"                        // main menu scenes put together from the player's own files
#include "../../mods/balance/balancelock.inc"   // infinite balance (gfx.inc forwards gfx_balancelock); client build: offline only, enforced by the client menu scripts
#include "../../mods/skinsync/skinsync.inc"      // live skater looks online after Load Skater (dadmod to dadmod)
#include "../../mods/throw/throwsend.inc"        // thrown props reach players without dadmod on a host without dadmod (0x48 via the host)
#include "../../mods/cars2/cars2.inc"        // Cars: while driving, up/down also press gas/brake (gfx.inc ReadControlsHook calls it)
#include "../../mods/gfx/gfx.inc"                // graphics settings (dadmod\gfx.ini)
#define SOUNDLOG_NO_LOGGER   // no sound logger in the player build (Noah 2026-11-21)
#include "../../mods/soundlog/soundlog.inc"      // level/teleporter sound volumes, sound logger (dadmod\soundlog.txt)
#include "../../mods/skatercopy/skatercopy.inc"  // Copy Scales From / Copy Tricks From another saved skater (reads Save\*.SKA)
#include "../../mods/fullscreen/fullscreen.inc"    // Graphics > Display live (THUGRECOMP_DisplayLive) + Alt+Enter fullscreen toggle (Noah 2026-11-21: in the player build)
#include "../../mods/lamplights/lampsrc.inc"      // lamp post models built from the player's own THUG2 / THUG Pro files
#include "../../mods/lamplights/lampmodels.inc"   // lamp posts drawn per map (merged per model part)
#include "../../mods/lamplights/lamplights.inc"    // street lamps + lit windows at night (Chicago): engine LevelLights, bulbs/pools/windows drawn by gfx.inc
#include "update.inc"                             // in-game updater: release check at boot, Update dadmod

// ---- script functions
struct CFuncEntry { const char* name; bool (__cdecl* fn)(void*, void*); };

// THUGRECOMP_ClientLog text="..."  appends a line to dadmod\client.log
static bool __cdecl CF_ClientLog(void* params, void* script) {
    (void)script;
    const char* t = NULL;
    if (GetStringParam(params, "text", &t)) Log("script: %s", t);
    return true;
}

// THUGRECOMP_SafeStartInfo -> safe (1: this start is a safe start), just_on (1 once: safe start turned on this start,
// show the popup), back (1 once: a normal start worked again this start, show the message)
static bool __cdecl CF_SafeStartInfo(void* params, void* script) {
    (void)params;
    RetInt(script, "safe", g_startMode == 1 ? 1 : 0);
    RetInt(script, "just_on", InterlockedExchange(&g_ssJustOn, 0) ? 1 : 0);
    RetInt(script, "back", InterlockedExchange(&g_ssBack, 0) ? 1 : 0);
    return true;
}

// THUGRECOMP_SafeStartRetry -> ok=1: the next start tries a normal start (as the automatic retry does)
static bool __cdecl CF_SafeStartRetry(void* params, void* script) {
    (void)params;
    if (!FileThere(g_safeFile)) { RetInt(script, "ok", 0); return true; }
    LoadSafeState();
    g_ss.retryNext = 1;
    SaveSafeState();
    Log("safe start: the player picked Try a normal start, the next start tries it");
    RetInt(script, "ok", 1);
    return true;
}

// THUGRECOMP_ModelExists model="veh\\Veh_Duck\\Veh_Duck.mdl"  true when the game can find that model as a loose file,
// <game>\User\Data\Models\<model>.xbx, <game>\data\models\<model>.xbx or THUG2's own models
// (<thug2_path>\Data\models\<model>.xbx, HKCU\Software\THUG Pro\Settings thug2_path, the folder the engine reads
// THUG2's data from). 2026-11-21: the THUG2 check was missing, so on plain THUG Pro (no Kali copies in
// User\Data\Models) thrown cars fell back to the COMBO O although the game can load them.
static bool __cdecl CF_ModelExists(void* params, void* script) {
    (void)script;
    const char* m = NULL;
    if (!GetStringParam(params, "model", &m) || !m || !*m || strstr(m, "..")) return false;
    char path[MAX_PATH];
    DWORD len = GetModuleFileNameA(nullptr, path, MAX_PATH);
    if (!len || len >= MAX_PATH) return false;
    char* slash = strrchr(path, '\\');
    if (!slash) return false;
    slash[1] = 0;
    const char* roots[] = { "User\\Data\\Models\\", "data\\models\\" };
    for (const char* r : roots) {
        std::string f = std::string(path) + r + m + ".xbx";
        DWORD a = GetFileAttributesA(f.c_str());
        if (a != INVALID_FILE_ATTRIBUTES && !(a & FILE_ATTRIBUTE_DIRECTORY)) return true;
    }
    char t2[MAX_PATH] = "";
    DWORD n = sizeof t2 - 1;
    HKEY k;
    if (RegOpenKeyExA(HKEY_CURRENT_USER, "Software\\THUG Pro\\Settings", 0, KEY_READ, &k) == ERROR_SUCCESS) {
        DWORD type = 0;
        if (RegQueryValueExA(k, "thug2_path", NULL, &type, (BYTE*)t2, &n) != ERROR_SUCCESS || type != REG_SZ) t2[0] = 0;
        else t2[n < sizeof t2 ? n : sizeof t2 - 1] = 0;
        RegCloseKey(k);
    }
    if (t2[0]) {
        std::string f = t2;
        if (f.back() != '\\' && f.back() != '/') f += '\\';
        f += std::string("Data\\models\\") + m + ".xbx";
        DWORD a = GetFileAttributesA(f.c_str());
        if (a != INVALID_FILE_ATTRIBUTES && !(a & FILE_ATTRIBUTE_DIRECTORY)) return true;
    }
    return false;
}

// THUGRECOMP_GameFileExists file="data\\pre\\P8Suburbsscn.prx"  true when that file is in the game folder (a path
// relative to THUGPro.exe's folder; no "..", no drive). Noah 2026-11-23: the extra maps come in separate map packs
// the installer fetches; a level whose files aren't there yet is greyed out in level select instead of loading.
static bool __cdecl CF_GameFileExists(void* params, void* script) {
    (void)script;
    const char* m = NULL;
    if (!GetStringParam(params, "file", &m) || !m || !*m || strstr(m, "..") || strchr(m, ':') || m[0] == '\\' || m[0] == '/') return false;
    char path[MAX_PATH];
    DWORD len = GetModuleFileNameA(nullptr, path, MAX_PATH);
    if (!len || len >= MAX_PATH) return false;
    char* slash = strrchr(path, '\\');
    if (!slash) return false;
    slash[1] = 0;
    std::string f = std::string(path) + m;
    DWORD a = GetFileAttributesA(f.c_str());
    return a != INVALID_FILE_ATTRIBUTES && !(a & FILE_ATTRIBUTE_DIRECTORY);
}

static struct CFuncEntry g_cfuncs[] = {
    { "THUGRECOMP_GameFileExists", CF_GameFileExists },
    { "THUGRECOMP_ModelExists", CF_ModelExists },
    { "THUGRECOMP_ClientLog", CF_ClientLog },
    { "THUGRECOMP_SafeStartInfo", CF_SafeStartInfo },
    { "THUGRECOMP_SafeStartRetry", CF_SafeStartRetry },
    { "THUGRECOMP_SettingSave", CF_SettingSave },
    { "THUGRECOMP_SettingLoad", CF_SettingLoad },
    { "THUGRECOMP_CarsDrive", cars2::CF_CarsDrive },
    { "THUGRECOMP_CarsKeys", cars2::CF_CarsKeys },
    { "THUGRECOMP_GfxReset", gfx::CF_GfxReset },
    { "THUGRECOMP_ReShadeInfo", gfx::CF_ReShadeInfo },
    { "THUGRECOMP_AddLevelLight", lamplights::CF_AddLevelLight },
    { "THUGRECOMP_LampBulbsClear", lamplights::CF_LampBulbsClear },
    { "THUGRECOMP_LampBulb", lamplights::CF_LampBulb },
    { "THUGRECOMP_LampPost", lamplights::CF_LampPost },
    { "THUGRECOMP_LampNight", lamplights::CF_LampNight },
    { "THUGRECOMP_ThrowSendToServer", throwsend::CF_ThrowSendToServer },
    { "THUGRECOMP_ThrowHostStock", throwsend::CF_ThrowHostStock },
    { "THUGRECOMP_ThrowStockOn", throwsend::CF_ClientStockOn },
    { "THUGRECOMP_ThrowStockType", throwsend::CF_ClientStockType },
    { "THUGRECOMP_SkinHello", skin::CF_SkinHello },
    { "THUGRECOMP_SkinSend", skin::CF_SkinSend },
    { "THUGRECOMP_SkinLocalZero", skin::CF_SkinLocalZero },
    { "THUGRECOMP_SkinHorn", skin::CF_SkinHorn },
    { "THUGRECOMP_CarsHornSend", skin::CF_CarsHornSend },
    { "THUGRECOMP_SkcCount", skc::CF_SkcCount },
    { "THUGRECOMP_SkcName", skc::CF_SkcName },
    { "THUGRECOMP_SkcScales", skc::CF_SkcScales },
    { "THUGRECOMP_SkcTricks", skc::CF_SkcTricks },
    { "THUGRECOMP_SkcSpecial", skc::CF_SkcSpecial },
    { "THUGRECOMP_PadPressed", padhub::CF_PadPressed },
    { "THUGRECOMP_PadHeld", padhub::CF_PadHeld },
    { "THUGRECOMP_BindName", padhub::CF_BindName },
    { "THUGRECOMP_BindCapture", padhub::CF_BindCapture },
    { "THUGRECOMP_BindPoll", padhub::CF_BindPoll },
    { "THUGRECOMP_BindReset", padhub::CF_BindReset },
    { "THUGRECOMP_InputDevice", padhub::CF_InputDevice },
    { "THUGRECOMP_ButtonText", padhub::CF_ButtonText },
    { "THUGRECOMP_BankDropsOn", CF_BankDropsOn },
    { "THUGRECOMP_BankDropsSet", CF_BankDropsSet },
    { "THUGRECOMP_TextSave", CF_TextSave },
    { "THUGRECOMP_TextLoad", CF_TextLoad },
    { "THUGRECOMP_TextHas", CF_TextHas },
    { "THUGRECOMP_Log", CF_Log },
    { "THUGRECOMP_MenuLevelHas", CF_MenuLevelHas },
    { "THUGRECOMP_MenuLevel", mmenu::CF_MenuLevel },
    { "THUGRECOMP_MenuSpot", mmenu::CF_MenuSpot },
    { "THUGRECOMP_MenuTick", mmenu::CF_MenuTick },
    { "THUGRECOMP_MenuMark", mmenu::CF_MenuMark },
    { "THUGRECOMP_MenuOpt", mmenu::CF_MenuOpt },
    { "THUGRECOMP_MenuDelete", mmenu::CF_MenuDelete },
    { "THUGRECOMP_MenuFav", mmenu::CF_MenuFav },
    { "THUGRECOMP_MenuSetHere", mmenu::CF_MenuSetHere },
    { "THUGRECOMP_MenuCamEdit", mmenu::CF_MenuCamEdit },
    { "THUGRECOMP_MenuSaved", mmenu::CF_MenuSaved },
    { "THUGRECOMP_MenuSavedDelete", mmenu::CF_MenuSavedDelete },
    { "THUGRECOMP_MenuFavAnim", mmenu::CF_MenuFavAnim },
    { "THUGRECOMP_MenuFocus", mmenu::CF_MenuFocus },
    { "THUGRECOMP_KeyPressed", mmenu::CF_KeyPressed },
    { "THUGRECOMP_WalkCam", mmenu::CF_WalkCam },
    { "THUGRECOMP_MouseMenu", mmenu::CF_MouseMenu },
    { "THUGRECOMP_MouseBack", mmenu::CF_MouseBack },
    { "THUGRECOMP_MouseNext", mmenu::CF_MouseNext },
    { "THUGRECOMP_MouseRightPause", mmenu::CF_MouseRightPause },
    { "THUGRECOMP_MouseArrows", mmenu::CF_MouseArrows },
    { "THUGRECOMP_MouseOver", mmenu::CF_MouseOver },
    { "THUGRECOMP_MouseHoverDone", mmenu::CF_MouseHoverDone },
    { "THUGRECOMP_FitText", mmenu::CF_FitText },
    { "THUGRECOMP_MenuOrder", mmenu::CF_MenuOrder },
    { "THUGRECOMP_MenuOrderMove", mmenu::CF_MenuOrderMove },
    { "THUGRECOMP_MenuOrderUndo", mmenu::CF_MenuOrderUndo },
    { "THUGRECOMP_MenuOrderReset", mmenu::CF_MenuOrderReset },
    { "THUGRECOMP_ScanText", mmenu::CF_ScanText },
    { "THUGRECOMP_TextClip", mmenu::CF_TextClip },
    { "THUGRECOMP_UiClock", mmenu::CF_UiClock },
    { "THUGRECOMP_Display", mmenu::CF_Display },
    { "THUGRECOMP_DisplayLive", fullscreen::CF_DisplayLive },
    { "THUGRECOMP_MenuRestore", mmenu::CF_MenuRestore },
    { "THUGRECOMP_LayoutInfo", mmenu::CF_LayoutInfo },
    { "THUGRECOMP_LayoutChild", mmenu::CF_LayoutChild },
    { "THUGRECOMP_MenuSeen", mmenu::CF_MenuSeen },
    { "THUGRECOMP_MenuHasOrder", mmenu::CF_MenuHasOrder },
    { "THUGRECOMP_CapturePush", mmenu::CF_CapturePush },
    { "THUGRECOMP_CaptureNext", mmenu::CF_CaptureNext },
    { "THUGRECOMP_CaptureClear", mmenu::CF_CaptureClear },
    { "THUGRECOMP_ReorderBegin", mmenu::CF_ReorderBegin },
    { "THUGRECOMP_ReorderAdd", mmenu::CF_ReorderAdd },
    { "THUGRECOMP_ReorderSave", mmenu::CF_ReorderSave },
    { "THUGRECOMP_ReorderUndo", mmenu::CF_ReorderUndo },
    { "THUGRECOMP_ReorderReset", mmenu::CF_ReorderReset },
    { "THUGRECOMP_ReorderPermInit", mmenu::CF_ReorderPermInit },
    { "THUGRECOMP_ReorderPermAt", mmenu::CF_ReorderPermAt },
    { "THUGRECOMP_ReorderPermMove", mmenu::CF_ReorderPermMove },
    { "THUGRECOMP_ReorderPermPush", mmenu::CF_ReorderPermPush },
    { "THUGRECOMP_ReorderPermSet", mmenu::CF_ReorderPermSet },
    { "THUGRECOMP_UpdateInfo", dupdate::CF_UpdateInfo },
    { "THUGRECOMP_UpdateStart", dupdate::CF_UpdateStart },
    { "THUGRECOMP_UpdateDownload", dupdate::CF_UpdateDownload },
    { "THUGRECOMP_UpdateCheck", dupdate::CF_UpdateCheck },
    { "THUGRECOMP_UpdateNotes", dupdate::CF_UpdateNotes },
};

static void __cdecl RegisterCFuncsHook(struct CFuncEntry* table, unsigned count) {
    typedef void (__cdecl* Fn)(struct CFuncEntry*, unsigned);
#ifdef DADMOD_DIAG
    if (InterlockedIncrement(&g_diagCFuncs) == 1) Diag("script functions registered (our hook ran, %u game entries)", count);
#endif
    gfx::PatchEngineCFuncs(table, count);  // Level sounds On/Off (gfx.inc)
    ((Fn)kRegisterCFuncs)(table, count);
    ((Fn)kRegisterCFuncs)(g_cfuncs, sizeof g_cfuncs / sizeof g_cfuncs[0]);
}

// before any script loads (the startup loader runs once, at boot)
static void BeforeGameScripts(void) {
    menulevels::Assemble();
    dupdate::StartCheck();   // background request; the main menu asks for the answer later
}

static int PatchCall(DWORD site, DWORD expect, void* to) {
    BYTE* p = (BYTE*)site;
    if (p[0] != 0xE8 || (DWORD)(site + 5 + *(int*)(p + 1)) != expect) return 0;  // not the build we know
    DWORD old; VirtualProtect(p, 5, PAGE_EXECUTE_READWRITE, &old);
    *(int*)(p + 1) = (int)((DWORD)to - (site + 5));
    VirtualProtect(p, 5, old, &old);
    FlushInstructionCache(GetCurrentProcess(), p, 5);
    return 1;
}

#ifdef DADMOD_DIAG
static const char* DiagModuleOf(DWORD addr, char* out, int n) {
    HMODULE m = NULL; out[0] = 0;
    if (GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT, (LPCSTR)addr, &m) && m) {
        char full[MAX_PATH]; GetModuleFileNameA(m, full, MAX_PATH);
        const char* b = strrchr(full, '\\'); _snprintf(out, n - 1, "%s+0x%lX", b ? b + 1 : full, addr - (DWORD)m); out[n - 1] = 0;
    } else _snprintf(out, n - 1, "no module");
    return out;
}
static void DiagCallSite(const char* when, DWORD site) {
    BYTE* p = (BYTE*)site; char mod[MAX_PATH];
    if (p[0] == 0xE8) { DWORD to = site + 5 + *(int*)(p + 1); Diag("%s: call at 0x%lX -> 0x%lX (%s)", when, site, to, DiagModuleOf(to, mod, sizeof mod)); }
    else Diag("%s: bytes at 0x%lX are %02X %02X %02X %02X %02X (not a call any more)", when, site, p[0], p[1], p[2], p[3], p[4]);
}
// The same small append three ways (full path ANSI, full path wide, relative path), without the wrappers' extra lines.
static void DiagTestWrite(const char* name) {
    char path[MAX_PATH]; strcpy(path, g_logPath); char* sl = strrchr(path, '\\'); if (sl) sl[1] = 0; strcat(path, name);
    char rel[MAX_PATH]; _snprintf(rel, MAX_PATH - 1, "dadmod\\%s", name); rel[MAX_PATH - 1] = 0;
    wchar_t wide[MAX_PATH]; MultiByteToWideChar(CP_ACP, 0, path, -1, wide, MAX_PATH);
    HANDLE f = (CreateFileA)(path, FILE_APPEND_DATA, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_ALWAYS, 0, NULL); DWORD e1 = GetLastError();
    if (f != INVALID_HANDLE_VALUE) { CloseHandle(f); e1 = 0; }
    f = CreateFileW(wide, FILE_APPEND_DATA, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_ALWAYS, 0, NULL); DWORD e2 = GetLastError();
    if (f != INVALID_HANDLE_VALUE) { CloseHandle(f); e2 = 0; }
    f = (CreateFileA)(rel, FILE_APPEND_DATA, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_ALWAYS, 0, NULL); DWORD e3 = GetLastError();
    if (f != INVALID_HANDLE_VALUE) { CloseHandle(f); e3 = 0; }
    f = (CreateFileA)(path, FILE_APPEND_DATA, FILE_SHARE_READ, NULL, OPEN_ALWAYS, 0, NULL); DWORD e4 = GetLastError();
    if (f != INVALID_HANDLE_VALUE) { CloseHandle(f); e4 = 0; }
    Diag("write test %s: full path %lu, wide %lu, relative %lu, full path share-read-only %lu (0 = ok, else the Windows error)", name, e1, e2, e3, e4);
}
// Every DLL inside the game process, with its folder: overlays, capture tools and security products show up here.
static void DiagModules(const char* when) {
    typedef BOOL (WINAPI* FnEnum)(HANDLE, HMODULE*, DWORD, LPDWORD);
    HMODULE k = GetModuleHandleA("kernel32.dll"); FnEnum en = k ? (FnEnum)GetProcAddress(k, "K32EnumProcessModules") : NULL;
    if (!en) { Diag("modules %s: cannot list", when); return; }
    static HMODULE list[1024]; static HMODULE seen[1024]; static int nseen = 0; DWORD need = 0;
    if (!en(GetCurrentProcess(), list, sizeof list, &need)) { Diag("modules %s: list failed (error %lu)", when, GetLastError()); return; }
    int n = (int)(need / sizeof(HMODULE)); if (n > 1024) n = 1024; int fresh = 0;
    for (int i = 0; i < n; ++i) {
        bool had = false; for (int j = 0; j < nseen; ++j) if (seen[j] == list[i]) { had = true; break; }
        if (had) continue;
        if (nseen < 1024) seen[nseen++] = list[i];
        char path[MAX_PATH]; path[0] = 0; GetModuleFileNameA(list[i], path, MAX_PATH);
        Diag("module %s: %s", when, path); ++fresh;
    }
    Diag("modules %s: %d loaded, %d new", when, n, fresh);
}
static DWORD WINAPI DiagWatch(LPVOID) {
    static const int waits[] = { 5, 15, 30, 60, 120 };
    for (int w : waits) {
        Sleep(w == 5 ? 5000 : (w == 15 ? 10000 : (w == 30 ? 15000 : (w == 60 ? 30000 : 60000))));
        Diag("after %d s: script functions hook %s, startup loader hook %s, %ld dadmod files loaded", w,
             g_diagCFuncs ? "ran" : "NOT run", g_diagStartup ? "ran" : "NOT run", g_diagLoaded);
        DiagCallSite("startup loader call", kCallLoadStartup);
        DiagCallSite("script functions call", kCallRegisterCFuncs);
        char when[32]; _snprintf(when, sizeof when, "after %d s", w); DiagModules(when);
        DiagTestWrite("panel_settings.txt"); DiagTestWrite("client.log"); DiagTestWrite("diag_newfile_test.txt");
    }
    return 0;
}
static void DiagModules(const char* when);
static void DiagStart(HINSTANCE inst) {
    InitializeCriticalSection(&g_diagLock); g_diagLockOk = true;
    strcpy(g_diagGame, g_logPath); char* sl = strrchr(g_diagGame, '\\'); if (sl) sl[1] = 0; strcat(g_diagGame, "diag.log");
    char la[MAX_PATH]; DWORD n = GetEnvironmentVariableA("LOCALAPPDATA", la, MAX_PATH);
    if (n && n < MAX_PATH - 40) { _snprintf(g_diagApp, MAX_PATH - 1, "%s\\dadmod_diag", la); (CreateDirectoryA)(g_diagApp, NULL); strcat(g_diagApp, "\\diag.log"); }
    const char* paths[3] = { g_diagGame, "dadmod\\diag_rel.log", g_diagApp };
    DWORD errs[3] = { 0, 0, 0 };
    for (int i = 0; i < 3; ++i) if (paths[i][0]) {
        g_diagH[i] = (CreateFileA)(paths[i], FILE_APPEND_DATA, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
        errs[i] = g_diagH[i] == INVALID_HANDLE_VALUE ? GetLastError() : 0;
    }
    Diag("==== dadmod diagnostic DLL (file calls through the wide Windows functions), process %lu", GetCurrentProcessId());
    for (int i = 0; i < 3; ++i) Diag("diag log %d: %s -> %s (error %lu)", i, paths[i][0] ? paths[i] : "(none)", g_diagH[i] == INVALID_HANDLE_VALUE ? "NOT opened" : "opened", errs[i]);
    char cwd[MAX_PATH]; cwd[0] = 0; GetCurrentDirectoryA(MAX_PATH, cwd); Diag("current folder: %s", cwd);
    OSVERSIONINFOA vi; vi.dwOSVersionInfoSize = sizeof vi;
    HMODULE nt = GetModuleHandleA("ntdll.dll");
    if (nt) { typedef void (WINAPI* Fn)(DWORD*, DWORD*, DWORD*); Fn f = (Fn)GetProcAddress(nt, "RtlGetNtVersionNumbers");
        if (f) { DWORD a, b, c; f(&a, &b, &c); Diag("Windows %lu.%lu build %lu", a, b, c & 0xFFFF); } }
    HANDLE tok;
    if (OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &tok)) {
        TOKEN_ELEVATION el; DWORD got;
        if (GetTokenInformation(tok, TokenElevation, &el, sizeof el, &got)) Diag("running as administrator: %s", el.TokenIsElevated ? "yes" : "no");
        BYTE buf[256];
        if (GetTokenInformation(tok, TokenIntegrityLevel, buf, sizeof buf, &got)) {
            TOKEN_MANDATORY_LABEL* ml = (TOKEN_MANDATORY_LABEL*)buf;
            Diag("integrity level: 0x%lX (0x2000 = normal, 0x1000 = low, 0x3000 = high)", *GetSidSubAuthority(ml->Label.Sid, *GetSidSubAuthorityCount(ml->Label.Sid) - 1));
        }
        DWORD virt = 0;
        if (GetTokenInformation(tok, TokenVirtualizationEnabled, &virt, sizeof virt, &got)) Diag("file virtualization: %s", virt ? "ON" : "off");
        CloseHandle(tok);
    }
    char exe[MAX_PATH], dll[MAX_PATH], mod[MAX_PATH]; GetModuleFileNameA(NULL, exe, MAX_PATH); GetModuleFileNameA(inst, dll, MAX_PATH);
    Diag("exe: %s", exe); Diag("this dll: %s", dll); Diag("command line: %.400s", GetCommandLineA());
    (void)mod; DiagModules("at DllMain");
    DiagCallSite("before patch, startup loader call", kCallLoadStartup);
    DiagCallSite("before patch, script functions call", kCallRegisterCFuncs);
}
#endif

BOOL WINAPI DllMain(HINSTANCE inst, DWORD reason, LPVOID reserved) {
    (void)reserved;
    if (reason == DLL_PROCESS_ATTACH) {
        DisableThreadLibraryCalls(inst);
        GetModuleFileNameA(NULL, g_logPath, MAX_PATH);
        char* sl = strrchr(g_logPath, '\\'); if (sl) sl[1] = 0;
        strcat(g_logPath, "dadmod"); CreateDirectoryA(g_logPath, NULL); strcat(g_logPath, "\\client.log");
#ifdef DADMOD_DIAG
        DiagStart(inst);
#endif
        int a = PatchCall(kCallRegisterCFuncs, kRegisterCFuncs, (void*)RegisterCFuncsHook);
        int b = PatchCall(kCallLoadStartup, kLoadStartup, (void*)LoadStartupHook);
        Log("---- dadmod client loader: script functions %s, script loader %s", a ? "ok" : "NOT HOOKED", b ? "ok" : "NOT HOOKED");
        bool safe = SafeStartCheck();
        // same order as the server build's DllMain
        InstallBankDropHooks();
        InstallPadHubHooks();
        InstallBootSpeedHooks();
        crashlog::Install();
        gfx::Install(!safe, true);   // client: one Direct3D probe, on the game's own thread (gfx.inc PatchThread)
        soundlog::Install();
        balancelock::Install();
        cars2::Install();   // wheel-bone guard (a car body without wheel bones crashed at 0x43BA80)
        fullscreen::Install();  // Alt+Enter, live Display changes (mods/fullscreen)
#ifdef DADMOD_DIAG
        DiagCallSite("after patch, startup loader call", kCallLoadStartup);
        DiagTestWrite("panel_settings.txt");
        Diag("DllMain done (safe start %s)", safe ? "on" : "off");
        CloseHandle(CreateThread(NULL, 0, DiagWatch, NULL, 0, NULL));
#endif
    }
    return TRUE;
}
