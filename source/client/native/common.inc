// Shared helpers for the client loader (client build only).
// Same behavior as the helpers of the same name in mods/modes_batch/modes.inc and native/thugrecomp,
// kept as a separate copy so the server build's files never change for the client build.
// Included by loader.cpp after its engine addresses, QbKey and Log.
#include <string>
#include <vector>
#include <map>
#include <algorithm>
#include <math.h>
#include <stdlib.h>

static const DWORD kNetManagerPtr      = 0x7CCE14;  // Net manager*
static const int kPlayerList         = 0x128;     // Manager player list head (gfx.inc ground mist; same as the server build)
static const int kPlayerSkater       = 0x14;      // PlayerInfo CSkater*
static const int kPlayerFlags        = 0x1D0;     // PlayerInfo flags; 1 = local player
static const DWORD kIsServer           = 0x44E4F0;  // bool __thiscall Manager::OnServer()
static const DWORD kStructGetInteger   = 0x476630;  // bool __thiscall CStruct::GetInteger(DWORD, int*, bool)
static const DWORD kStructContainsFlag = 0x476B40;  // bool __thiscall CStruct::ContainsFlag(DWORD)
static const DWORD kAddInteger         = 0x477B80;  // void __thiscall CStruct::AddInteger(DWORD, int)
static const DWORD kAddString          = 0x478390;  // void __thiscall CStruct::AddString(DWORD, 3, const char*)

static bool GetStringParam(void* params, const char* key, const char** out) {
    typedef char (THISCALL* Fn)(void*, DWORD, const char**, char);
    *out = nullptr;
    return ((Fn)kStructGetString)(params, QbKey(key), out, 0) && *out;
}
static int IntParam(void* params, const char* key, int def) {
    int v = def;
    typedef char (THISCALL* Fn)(void*, DWORD, int*, char);
    ((Fn)kStructGetInteger)(params, QbKey(key), &v, 0);
    return v;
}
static bool FlagParam(void* params, const char* key) {
    typedef char (THISCALL* Fn)(void*, DWORD);
    return ((Fn)kStructContainsFlag)(params, QbKey(key)) != 0;
}
static void RetInt(void* script, const char* key, int v) {
    if (!script) return;
    void* params = *(void**)((char*)script + 0x14);
    typedef void (THISCALL* Fn)(void*, DWORD, int);
    if (params) ((Fn)kAddInteger)(params, QbKey(key), v);
}
static void RetStr(void* script, const char* key, const char* s) {
    if (!script) return;
    void* params = *(void**)((char*)script + 0x14);
    typedef void (THISCALL* Fn)(void*, DWORD, int, const char*);
    if (params) ((Fn)kAddString)(params, QbKey(key), 3, s);
}
// True only on the host of a net game. 0x44E4F0 (kIsServer) alone just means "in a net game" (true on joining
// players too, found 2026-11-19); [manager] & 1 is "we run the server" (script OnServer, 0x533F90), which is also
// set offline, so both are checked, in the order the stock IsHost (0x538D70) checks them.
static bool IsHostServer() {
    char* mgr = *(char**)kNetManagerPtr;
    typedef char (THISCALL* Fn)(void*);
    return mgr && ((Fn)kIsServer)(mgr) && (*(DWORD*)mgr & 1) != 0;
}
// every file of ours lives in <game>\dadmod\ (Noah, 2026-10-11)
static std::string ExeDirFile(const char* file) {
    char path[MAX_PATH];
    DWORD len = GetModuleFileNameA(nullptr, path, MAX_PATH);
    if (!len || len >= MAX_PATH) return "";
    char* slash = strrchr(path, '\\');
    if (!slash) return "";
    slash[1] = 0;
    std::string dir = std::string(path) + "dadmod\\";
    static bool made = false;
    if (!made) { CreateDirectoryA(dir.c_str(), nullptr); made = true; }
    return dir + file;
}
static bool ReadWholeFile(const std::string& path, std::string& out) {
    out.clear();
    // FILE_SHARE_DELETE: another open game can still swap the file in while this one reads it (2026-11-23)
    HANDLE f = CreateFileA(path.c_str(), GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, nullptr,
                           OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (f == INVALID_HANDLE_VALUE) return false;
    char buf[8192];
    DWORD got;
    while (ReadFile(f, buf, sizeof buf, &got, nullptr) && got) out.append(buf, got);
    CloseHandle(f);
    if (out.size() >= 3 && (unsigned char)out[0] == 0xEF && (unsigned char)out[1] == 0xBB && (unsigned char)out[2] == 0xBF) out.erase(0, 3);
    return true;
}
static bool WriteWholeFile(const std::string& path, const std::string& data) {
    // a temp name per game, so two open games saving at once never share one (2026-11-23)
    std::string tmp = path + "." + std::to_string((unsigned long)GetCurrentProcessId()) + ".tmp";
    HANDLE f = CreateFileA(tmp.c_str(), GENERIC_WRITE, 0, nullptr, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (f == INVALID_HANDLE_VALUE) return false;
    DWORD wrote = 0;
    BOOL ok = WriteFile(f, data.data(), (DWORD)data.size(), &wrote, nullptr);
    CloseHandle(f);
    if (!ok || wrote != data.size()) { DeleteFileA(tmp.c_str()); return false; }
    for (int tries = 0; tries < 5; ++tries) {   // the other game may have the file open for a moment
        if (MoveFileExA(tmp.c_str(), path.c_str(), MOVEFILE_REPLACE_EXISTING)) return true;
        Sleep(2);
    }
    DeleteFileA(tmp.c_str());
    return false;
}

#ifndef DADMOD_CLIENT_HAS_MAINMENU
// mods/gfx uses mmenu::Log / mmenu::Trim from mods/mainmenu/mainmenu.inc. Until the main menu mod is in
// the client build, these stand in for them (same output file and format).
namespace mmenu {
static void Log(const char* fmt, ...) {
    char line[512];
    va_list ap; va_start(ap, fmt); _vsnprintf(line, sizeof line - 1, fmt, ap); va_end(ap);
    line[sizeof line - 1] = 0;
    SYSTEMTIME t; GetLocalTime(&t);
    char stamp[32]; sprintf(stamp, "%04d-%02d-%02d %02d:%02d:%02d ", t.wYear, t.wMonth, t.wDay, t.wHour, t.wMinute, t.wSecond);
    std::string path = ExeDirFile("mainmenu.log");
    HANDLE f = CreateFileA(path.c_str(), FILE_APPEND_DATA, FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (f == INVALID_HANDLE_VALUE) return;
    std::string s = std::string(stamp) + line + "\r\n";
    DWORD w; WriteFile(f, s.data(), (DWORD)s.size(), &w, nullptr); CloseHandle(f);
}
static std::string Trim(const std::string& s) {
    size_t a = s.find_first_not_of(" \t\r\n"), b = s.find_last_not_of(" \t\r\n");
    return a == std::string::npos ? "" : s.substr(a, b - a + 1);
}
}  // namespace mmenu
#endif

// THUGRECOMP_SettingSave key="..." value=N / THUGRECOMP_SettingLoad key="..." -> value=N
// Same store as the server build: gfx_* keys go to dadmod\gfx.ini (gfx.inc), the rest to
// dadmod\panel_settings.txt.
namespace gfx { bool SetKey(const char* key, int value); bool GetKey(const char* key, int* value);
                 bool PanelSet(const char* key, int value); bool PanelGet(const char* key, int* value); }  // panel_settings.txt (gfx.inc, 2026-11-23)
static bool __cdecl CF_SettingSave(void* params, void*) {
    const char* key;
    if (!GetStringParam(params, "key", &key)) return false;
    int value = IntParam(params, "value", 0);
    if (!strncmp(key, "gfx_", 4)) return gfx::SetKey(key, value);
#ifdef DADMOD_DIAG
    bool ok = gfx::PanelSet(key, value);
    Diag("setting save %s = %d: %s (error %lu)", key, value, ok ? "ok" : "FAILED", ok ? 0UL : GetLastError());
    return ok;
#else
    return gfx::PanelSet(key, value);
#endif
}
static bool __cdecl CF_SettingLoad(void* params, void* script) {
    const char* key;
    if (!GetStringParam(params, "key", &key)) return false;
    if (!strncmp(key, "gfx_", 4)) {
        int v;
        if (!gfx::GetKey(key, &v)) return false;
        RetInt(script, "value", v);
        return true;
    }
    int v;
    if (!gfx::PanelGet(key, &v)) return false;
    RetInt(script, "value", v);
    return true;
}
