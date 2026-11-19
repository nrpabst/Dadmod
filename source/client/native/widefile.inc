// Every file call the client DLL makes goes through the wide (Unicode) Windows functions.
//
// Why (2026-11-19): on a player's PC (Windows 11 build 26200, Windhawk injected into the game) CreateFileA with a
// full path started failing with ERROR_PATH_NOT_FOUND about 0.3 s after the DLL loaded - for files that exist, for
// reading and writing alike - while CreateFileW with the very same path, and relative ANSI paths, kept working.
// Nothing dadmod saved ever arrived (settings, logs, menu level archives) and nothing it read back was found, so
// every setting showed its default. His diagnostic log (build_diag.bat) showed it call by call.
// The wide functions are what the ANSI ones call underneath anyway, so this changes nothing on a healthy PC.
//
// Included by loader.cpp right after the system headers and before any mod code. The macros at the end reroute the
// ANSI names, so shared mod code (work/mods, also built into the server DLL) stays as it is.
#ifndef DADMOD_WIDEFILE_INC
#define DADMOD_WIDEFILE_INC

static const int kWidePath = 1024;
static bool DmWide(const char* a, wchar_t* w, int n = kWidePath) {
    if (!a) { w[0] = 0; return false; }
    if (MultiByteToWideChar(CP_ACP, 0, a, -1, w, n) > 0) return true;
    w[0] = 0; SetLastError(ERROR_FILENAME_EXCED_RANGE); return false;
}
static HANDLE WINAPI DmCreateFileA(LPCSTR path, DWORD access, DWORD share, LPSECURITY_ATTRIBUTES sa, DWORD disp, DWORD flags, HANDLE tmpl) {
    wchar_t w[kWidePath]; if (!DmWide(path, w)) return INVALID_HANDLE_VALUE;
    return CreateFileW(w, access, share, sa, disp, flags, tmpl);
}
static BOOL WINAPI DmDeleteFileA(LPCSTR path) {
    wchar_t w[kWidePath]; if (!DmWide(path, w)) return FALSE;
    return DeleteFileW(w);
}
static BOOL WINAPI DmMoveFileExA(LPCSTR from, LPCSTR to, DWORD flags) {
    wchar_t a[kWidePath], b[kWidePath]; if (!DmWide(from, a)) return FALSE;
    if (to && !DmWide(to, b)) return FALSE;
    return MoveFileExW(a, to ? b : NULL, flags);
}
static BOOL WINAPI DmMoveFileA(LPCSTR from, LPCSTR to) {
    wchar_t a[kWidePath], b[kWidePath]; if (!DmWide(from, a) || !DmWide(to, b)) return FALSE;
    return MoveFileW(a, b);
}
static BOOL WINAPI DmCreateDirectoryA(LPCSTR path, LPSECURITY_ATTRIBUTES sa) {
    wchar_t w[kWidePath]; if (!DmWide(path, w)) return FALSE;
    return CreateDirectoryW(w, sa);
}
static DWORD WINAPI DmGetFileAttributesA(LPCSTR path) {
    wchar_t w[kWidePath]; if (!DmWide(path, w)) return INVALID_FILE_ATTRIBUTES;
    return GetFileAttributesW(w);
}
static BOOL WINAPI DmGetFileAttributesExA(LPCSTR path, GET_FILEEX_INFO_LEVELS level, LPVOID info) {
    wchar_t w[kWidePath]; if (!DmWide(path, w)) return FALSE;
    return GetFileAttributesExW(w, level, info);   // the info block has no strings: same layout for A and W
}
static UINT WINAPI DmGetPrivateProfileIntA(LPCSTR sec, LPCSTR key, INT def, LPCSTR file) {
    wchar_t s[256], k[256], f[kWidePath];
    if (!DmWide(sec, s, 256) || !DmWide(key, k, 256) || !DmWide(file, f)) return (UINT)def;
    return GetPrivateProfileIntW(s, k, def, f);
}
static BOOL WINAPI DmWritePrivateProfileStringA(LPCSTR sec, LPCSTR key, LPCSTR val, LPCSTR file) {
    wchar_t s[256], k[256], v[1024], f[kWidePath];
    if (!DmWide(file, f)) return FALSE;
    if (sec && !DmWide(sec, s, 256)) return FALSE;
    if (key && !DmWide(key, k, 256)) return FALSE;
    if (val && !DmWide(val, v, 1024)) return FALSE;
    return WritePrivateProfileStringW(sec ? s : NULL, key ? k : NULL, val ? v : NULL, f);
}
static void DmFindDataToA(const WIN32_FIND_DATAW& w, WIN32_FIND_DATAA* a) {
    a->dwFileAttributes = w.dwFileAttributes; a->ftCreationTime = w.ftCreationTime;
    a->ftLastAccessTime = w.ftLastAccessTime; a->ftLastWriteTime = w.ftLastWriteTime;
    a->nFileSizeHigh = w.nFileSizeHigh; a->nFileSizeLow = w.nFileSizeLow;
    a->dwReserved0 = w.dwReserved0; a->dwReserved1 = w.dwReserved1;
    if (WideCharToMultiByte(CP_ACP, 0, w.cFileName, -1, a->cFileName, sizeof a->cFileName, NULL, NULL) <= 0) a->cFileName[0] = 0;
    if (WideCharToMultiByte(CP_ACP, 0, w.cAlternateFileName, -1, a->cAlternateFileName, sizeof a->cAlternateFileName, NULL, NULL) <= 0) a->cAlternateFileName[0] = 0;
}
static HANDLE WINAPI DmFindFirstFileA(LPCSTR pattern, WIN32_FIND_DATAA* fd) {
    wchar_t w[kWidePath]; if (!DmWide(pattern, w)) return INVALID_HANDLE_VALUE;
    WIN32_FIND_DATAW wd; HANDLE h = FindFirstFileW(w, &wd);
    if (h != INVALID_HANDLE_VALUE) DmFindDataToA(wd, fd);
    return h;
}
static BOOL WINAPI DmFindNextFileA(HANDLE h, WIN32_FIND_DATAA* fd) {   // only for handles from DmFindFirstFileA
    WIN32_FIND_DATAW wd; if (!FindNextFileW(h, &wd)) return FALSE;
    DmFindDataToA(wd, fd); return TRUE;
}
static DWORD WINAPI DmGetPrivateProfileStringA(LPCSTR sec, LPCSTR key, LPCSTR def, LPSTR out, DWORD outLen, LPCSTR file) {
    wchar_t s[256], k[256], d[1024], f[kWidePath], v[1024];
    if (!out || !outLen) return 0;
    out[0] = 0;
    if (!sec || !key || !DmWide(sec, s, 256) || !DmWide(key, k, 256) || !DmWide(file, f)) return 0;   // whole-section reads are not used here
    if (def && !DmWide(def, d, 1024)) return 0;
    GetPrivateProfileStringW(s, k, def ? d : L"", v, 1024, f);
    int n = WideCharToMultiByte(CP_ACP, 0, v, -1, out, (int)outLen, NULL, NULL);
    if (n <= 0) { out[outLen - 1] = 0; return (DWORD)strlen(out); }
    return (DWORD)(n - 1);
}
// Only what update.inc uses: no application name, no environment block, a STARTUPINFOA without strings.
static BOOL WINAPI DmCreateProcessA(LPCSTR app, LPSTR cmd, LPSECURITY_ATTRIBUTES pa, LPSECURITY_ATTRIBUTES ta, BOOL inherit, DWORD flags,
                                    LPVOID env, LPCSTR dir, LPSTARTUPINFOA si, LPPROCESS_INFORMATION pi) {
    static wchar_t wcmd[4096];   // CreateProcessW may write to the command line
    wchar_t wapp[kWidePath], wdir[kWidePath];
    if (env) { SetLastError(ERROR_NOT_SUPPORTED); return FALSE; }
    if (app && !DmWide(app, wapp)) return FALSE;
    if (cmd && !DmWide(cmd, wcmd, 4096)) return FALSE;
    if (dir && !DmWide(dir, wdir)) return FALSE;
    STARTUPINFOW wsi; memset(&wsi, 0, sizeof wsi); wsi.cb = sizeof wsi;
    if (si) { wsi.dwFlags = si->dwFlags & ~(DWORD)STARTF_USESTDHANDLES; wsi.wShowWindow = si->wShowWindow; }
    return CreateProcessW(app ? wapp : NULL, cmd ? wcmd : NULL, pa, ta, inherit, flags, NULL, dir ? wdir : NULL, &wsi, pi);
}
static FILE* DmFopen(const char* path, const char* mode) {
    wchar_t w[kWidePath], m[16];
    if (!DmWide(path, w) || !DmWide(mode, m, 16)) return NULL;
    return _wfopen(w, m);
}

#define CreateFileA(...) DmCreateFileA(__VA_ARGS__)
#define DeleteFileA(...) DmDeleteFileA(__VA_ARGS__)
#define MoveFileExA(...) DmMoveFileExA(__VA_ARGS__)
#define MoveFileA(...) DmMoveFileA(__VA_ARGS__)
#define CreateDirectoryA(...) DmCreateDirectoryA(__VA_ARGS__)
#define GetFileAttributesA(...) DmGetFileAttributesA(__VA_ARGS__)
#define GetFileAttributesExA(...) DmGetFileAttributesExA(__VA_ARGS__)
#define GetPrivateProfileIntA(...) DmGetPrivateProfileIntA(__VA_ARGS__)
#define WritePrivateProfileStringA(...) DmWritePrivateProfileStringA(__VA_ARGS__)
#define FindFirstFileA(...) DmFindFirstFileA(__VA_ARGS__)
#define FindNextFileA(...) DmFindNextFileA(__VA_ARGS__)
#define GetPrivateProfileStringA(...) DmGetPrivateProfileStringA(__VA_ARGS__)
#define CreateProcessA(...) DmCreateProcessA(__VA_ARGS__)
#define fopen(...) DmFopen(__VA_ARGS__)
#endif
