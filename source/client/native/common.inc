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
static bool IsHostServer() {
    char* mgr = *(char**)kNetManagerPtr;
    typedef char (THISCALL* Fn)(void*);
    return mgr && ((Fn)kIsServer)(mgr);
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
    HANDLE f = CreateFileA(path.c_str(), GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr,
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
    std::string tmp = path + ".tmp";
    HANDLE f = CreateFileA(tmp.c_str(), GENERIC_WRITE, 0, nullptr, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (f == INVALID_HANDLE_VALUE) return false;
    DWORD wrote = 0;
    BOOL ok = WriteFile(f, data.data(), (DWORD)data.size(), &wrote, nullptr);
    CloseHandle(f);
    if (!ok || wrote != data.size()) { DeleteFileA(tmp.c_str()); return false; }
    return MoveFileExA(tmp.c_str(), path.c_str(), MOVEFILE_REPLACE_EXISTING) != 0;
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
namespace gfx { bool SetKey(const char* key, int value); bool GetKey(const char* key, int* value); }
static bool __cdecl CF_SettingSave(void* params, void*) {
    const char* key;
    if (!GetStringParam(params, "key", &key)) return false;
    int value = IntParam(params, "value", 0);
    if (!strncmp(key, "gfx_", 4)) return gfx::SetKey(key, value);
    std::string path = ExeDirFile("panel_settings.txt"), data, out;
    ReadWholeFile(path, data);
    size_t s = 0;
    while (s < data.size()) {
        size_t e = data.find_first_of("\r\n", s);
        std::string line = data.substr(s, e == std::string::npos ? std::string::npos : e - s);
        s = e == std::string::npos ? data.size() : e + 1;
        if (line.empty()) continue;
        size_t sp = line.find(' ');
        if (sp != std::string::npos && line.substr(0, sp) == key) continue;
        out += line + "\r\n";
    }
    out += std::string(key) + " " + std::to_string(value) + "\r\n";
    return WriteWholeFile(path, out);
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
    std::string data;
    if (!ReadWholeFile(ExeDirFile("panel_settings.txt"), data)) return false;
    size_t s = 0;
    while (s < data.size()) {
        size_t e = data.find_first_of("\r\n", s);
        std::string line = data.substr(s, e == std::string::npos ? std::string::npos : e - s);
        s = e == std::string::npos ? data.size() : e + 1;
        size_t sp = line.find(' ');
        if (sp == std::string::npos || line.substr(0, sp) != key) continue;
        RetInt(script, "value", atoi(line.c_str() + sp + 1));
        return true;
    }
    return false;
}
