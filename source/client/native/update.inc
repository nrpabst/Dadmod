// In-game updater (Noah 2026-11-18). Client build only; included by loader.cpp after common.inc.
//  - "Update available" text after the Dadmod text on the main menu (same look and text effect; qb/dadmod/welcome.q).
//  - Pause > dadmod gets a row only while a newer release exists: "Download newest update (0.9.11)", its hint is a
//    short change log from the release notes. Picking it downloads dadmod.zip here in the background (keep playing);
//    then the row reads "Restart to install update" and starts the updater, which installs it and restarts the game.
//
// Check: one background request at boot to the public releases list (the same one Setup.bat reads:
// api.github.com/repos/nrpabst/Dadmod/releases, betas included, highest version with a dadmod.zip wins). No token,
// nothing sent but the request. DADMOD_UPDATE_URL overrides the address (local tests), like the installer.
// Install: <game>\dadmod\updater\dadmod.ps1 update -Game <game> -WaitPid <pid> -Zip <downloaded zip>, in its own
// console window; it waits for this game to close, installs the zip (it downloads it itself if -Zip is missing or
// wrong) and starts THUGPro.exe again.
#include <winhttp.h>
#pragma comment(lib, "winhttp.lib")

namespace dupdate {

static volatile LONG g_state = 0;   // 0 checking, 1 up to date, 2 newer, 3 check failed, 4 no version file
static char g_cur[32] = "";
static char g_new[32] = "";
static char g_url[1024] = "";        // browser_download_url of the newest dadmod.zip
static char g_notes[96] = "";        // short change log for the menu hint (ASCII, < 96 bytes)
static volatile LONG g_size = 0;     // asset size in bytes (0 = unknown)
static bool g_popupShown = false;
static bool g_started = false;

static volatile LONG g_dl = 0;       // 0 not started, 1 downloading, 2 done, 3 failed
static volatile LONG g_dlDone = 0, g_dlTotal = 0;
static std::string g_zip;            // <game>\dadmod\update\dadmod.zip

// "v0.9.10 beta" -> {0,9,10,0}; false when there are no numbers
static bool ParseVer(const char* s, int v[4]) {
    v[0] = v[1] = v[2] = v[3] = 0;
    while (*s && !isdigit((unsigned char)*s)) s++;
    if (!*s) return false;
    for (int i = 0; i < 4; i++) {
        if (!isdigit((unsigned char)*s)) break;
        v[i] = atoi(s);
        while (isdigit((unsigned char)*s)) s++;
        if (*s != '.' || !isdigit((unsigned char)s[1])) break;
        s++;
    }
    return true;
}
static int CmpVer(const int a[4], const int b[4]) {
    for (int i = 0; i < 4; i++) if (a[i] != b[i]) return a[i] < b[i] ? -1 : 1;
    return 0;
}

// GET url; the body goes to `body`, or to the file `toFile` when given (progress in g_dlDone / g_dlTotal)
static bool HttpGet(const wchar_t* url, std::string& body, const char* toFile = nullptr) {
    URL_COMPONENTS uc; memset(&uc, 0, sizeof uc); uc.dwStructSize = sizeof uc;
    wchar_t host[256], path[2048];
    uc.lpszHostName = host; uc.dwHostNameLength = 256; uc.lpszUrlPath = path; uc.dwUrlPathLength = 2048;
    wchar_t extra[2048]; uc.lpszExtraInfo = extra; uc.dwExtraInfoLength = 2048;
    if (!WinHttpCrackUrl(url, 0, 0, &uc)) return false;
    std::wstring full = std::wstring(path) + extra;
    bool ok = false;
    HINTERNET s = WinHttpOpen(L"dadmod-game", WINHTTP_ACCESS_TYPE_DEFAULT_PROXY, WINHTTP_NO_PROXY_NAME, WINHTTP_NO_PROXY_BYPASS, 0);
    if (!s) return false;
    if (toFile) WinHttpSetTimeouts(s, 15000, 15000, 30000, 30000);
    else WinHttpSetTimeouts(s, 8000, 8000, 8000, 8000);
    {
        // Windows 7/8 don't offer TLS 1.2 by default; GitHub needs it
        DWORD proto = 0x00000800 | 0x00000200;  // TLS 1.2 | TLS 1.1
        WinHttpSetOption(s, WINHTTP_OPTION_SECURE_PROTOCOLS, &proto, sizeof proto);
    }
    HINTERNET c = WinHttpConnect(s, host, uc.nPort, 0);
    if (c) {
        DWORD flags = uc.nScheme == INTERNET_SCHEME_HTTPS ? WINHTTP_FLAG_SECURE : 0;
        HINTERNET r = WinHttpOpenRequest(c, L"GET", full.c_str(), NULL, WINHTTP_NO_REFERER, WINHTTP_DEFAULT_ACCEPT_TYPES, flags);
        if (r) {
            const wchar_t* hdr = toFile ? L"Accept: application/octet-stream\r\n" : L"Accept: application/vnd.github+json\r\n";
            if (WinHttpSendRequest(r, hdr, (DWORD)-1L, WINHTTP_NO_REQUEST_DATA, 0, 0, 0) &&
                WinHttpReceiveResponse(r, NULL)) {      // follows GitHub's redirect to the file host by itself
                DWORD code = 0, len = sizeof code;
                WinHttpQueryHeaders(r, WINHTTP_QUERY_STATUS_CODE | WINHTTP_QUERY_FLAG_NUMBER, WINHTTP_HEADER_NAME_BY_INDEX, &code, &len, WINHTTP_NO_HEADER_INDEX);
                if (code != 200) {
                    Log("update: the server answered %lu", code);
                } else if (toFile) {
                    DWORD clen = 0; len = sizeof clen;
                    if (WinHttpQueryHeaders(r, WINHTTP_QUERY_CONTENT_LENGTH | WINHTTP_QUERY_FLAG_NUMBER, WINHTTP_HEADER_NAME_BY_INDEX, &clen, &len, WINHTTP_NO_HEADER_INDEX) && clen)
                        InterlockedExchange(&g_dlTotal, (LONG)clen);
                    HANDLE f = CreateFileA(toFile, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
                    if (f != INVALID_HANDLE_VALUE) {
                        static char buf[1 << 16];
                        DWORD n = 0, w = 0; bool wr = true;
                        while (WinHttpReadData(r, buf, sizeof buf, &n) && n) {
                            if (!WriteFile(f, buf, n, &w, NULL) || w != n) { wr = false; break; }
                            InterlockedExchangeAdd(&g_dlDone, (LONG)n);
                        }
                        CloseHandle(f);
                        ok = wr && (!g_dlTotal || g_dlDone == g_dlTotal);
                    }
                } else {
                    char buf[8192]; DWORD n = 0;
                    while (WinHttpReadData(r, buf, sizeof buf, &n) && n) { body.append(buf, n); if (body.size() > (8u << 20)) break; }
                    ok = true;
                }
            }
            WinHttpCloseHandle(r);
        }
        WinHttpCloseHandle(c);
    }
    WinHttpCloseHandle(s);
    return ok;
}

// the JSON string value that starts at the quote j[q]; \uXXXX outside ASCII becomes a space
static std::string JsonStr(const std::string& j, size_t q) {
    std::string out;
    if (q >= j.size() || j[q] != '"') return out;
    for (size_t i = q + 1; i < j.size() && j[i] != '"'; i++) {
        char ch = j[i];
        if (ch == '\\' && i + 1 < j.size()) {
            char e = j[++i];
            if (e == 'n') out += '\n';
            else if (e == 'r' || e == 't') out += ' ';
            else if (e == 'u' && i + 4 < j.size()) {
                int v = (int)strtol(j.substr(i + 1, 4).c_str(), nullptr, 16);
                out += (v >= 32 && v < 127) ? (char)v : ' ';
                i += 4;
            } else out += e;
        } else out += ch;
    }
    return out;
}
// the value of "key": "..." inside seg, from its first occurrence
static std::string JsonField(const std::string& seg, const char* key, size_t from = 0) {
    std::string k = std::string("\"") + key + "\"";
    size_t p = seg.find(k, from);
    if (p == std::string::npos) return "";
    p = seg.find(':', p + k.size());
    if (p == std::string::npos) return "";
    p++;
    while (p < seg.size() && (seg[p] == ' ' || seg[p] == '\n' || seg[p] == '\r' || seg[p] == '\t')) p++;
    return JsonStr(seg, p);
}

// release notes -> one short line: the first sentence of each change bullet ("~ ", "+ ", "- ", "* ", "x "),
// joined with "; ", cut to fit the menu hint box (stock pause hints must stay under 96 bytes)
static void MakeNotes(const std::string& body, char* out, size_t cap) {
    std::vector<std::string> items;
    size_t p = 0;
    std::string cur;
    bool inCode = false;
    auto flush = [&]() { if (!cur.empty()) { items.push_back(cur); cur.clear(); } };
    while (p <= body.size()) {
        size_t e = body.find('\n', p); if (e == std::string::npos) e = body.size();
        std::string ln = body.substr(p, e - p);
        p = e + 1;
        size_t a = ln.find_first_not_of(' ');
        if (a == std::string::npos) { flush(); continue; }
        std::string t = ln.substr(a);
        if (t.compare(0, 3, "```") == 0) { inCode = !inCode; flush(); continue; }
        char b = t[0];
        if ((b == '~' || b == '+' || b == '-' || b == '*' || b == 'x') && t.size() > 2 && t[1] == ' ') {
            flush(); cur = t.substr(2);
        } else if (!cur.empty() && a >= 4) {
            cur += " " + t;                        // wrapped line of the same bullet
        } else flush();
        if (p > body.size()) break;
    }
    flush();
    std::string s;
    for (std::string it : items) {
        std::string clean;                       // drop markdown ** and backticks, squeeze spaces
        for (size_t i = 0; i < it.size(); i++) {
            char ch = it[i];
            if (ch == '*' || ch == '`') continue;
            if ((unsigned char)ch < 32 || (unsigned char)ch > 126) ch = ' ';
            if (ch == '"') ch = '\'';
            if (ch == ' ' && !clean.empty() && clean.back() == ' ') continue;
            clean += ch;
        }
        size_t dot = clean.find(". ");
        if (dot != std::string::npos) clean = clean.substr(0, dot);
        while (!clean.empty() && (clean.back() == ' ' || clean.back() == '.')) clean.pop_back();
        if (clean.empty()) continue;
        s += (s.empty() ? "" : "; ") + clean;
        if (s.size() >= cap) break;
    }
    if (s.size() > cap - 1) {
        size_t cut = s.rfind(' ', cap - 4);
        if (cut == std::string::npos || cut < cap / 2) cut = cap - 4;
        s = s.substr(0, cut);
        while (!s.empty() && (s.back() == ' ' || s.back() == ';' || s.back() == ',' || s.back() == ':')) s.pop_back();
        s += "...";
    }
    strncpy(out, s.c_str(), cap - 1); out[cap - 1] = 0;
}

// the releases list: an array of release objects; each has "tag_name", "draft", its "assets" (each with "name",
// "size" and "browser_download_url") and "body" (the notes)
static void FindNewest(const std::string& j, int best[4], std::string& bestTag, std::string& bestSeg) {
    best[0] = best[1] = best[2] = best[3] = -1;
    size_t p = 0;
    const std::string key = "\"tag_name\"";
    while ((p = j.find(key, p)) != std::string::npos) {
        size_t next = j.find(key, p + key.size());
        std::string rel = j.substr(p, next == std::string::npos ? std::string::npos : next - p);
        p += key.size();
        std::string tag = JsonField(rel, "tag_name");
        std::string flat; flat.reserve(rel.size());
        for (char ch : rel) if (ch != ' ' && ch != '\n' && ch != '\r' && ch != '\t') flat += ch;
        if (flat.find("\"draft\":true") != std::string::npos) continue;
        if (flat.find("\"name\":\"dadmod.zip\"") == std::string::npos) continue;
        int v[4];
        if (!ParseVer(tag.c_str(), v)) continue;
        if (best[0] < 0 || CmpVer(v, best) > 0) { memcpy(best, v, sizeof v); bestTag = tag; bestSeg = rel; }
    }
}

static DWORD WINAPI CheckThread(LPVOID) {
    char url[1024];
    DWORD n = GetEnvironmentVariableA("DADMOD_UPDATE_URL", url, sizeof url);
    if (!n || n >= sizeof url) strcpy(url, "https://api.github.com/repos/nrpabst/Dadmod/releases?per_page=30");
    wchar_t wurl[1024]; MultiByteToWideChar(CP_ACP, 0, url, -1, wurl, 1024);
    std::string body;
    if (!HttpGet(wurl, body)) { Log("update check: could not read the releases list"); InterlockedExchange(&g_state, 3); return 0; }
    int best[4], cur[4]; std::string tag, seg;
    FindNewest(body, best, tag, seg);
    if (best[0] < 0) { Log("update check: no release with a dadmod.zip"); InterlockedExchange(&g_state, 1); return 0; }
    ParseVer(g_cur, cur);
    _snprintf(g_new, sizeof g_new - 1, "%d.%d.%d", best[0], best[1], best[2]);
    if (best[3]) _snprintf(g_new, sizeof g_new - 1, "%d.%d.%d.%d", best[0], best[1], best[2], best[3]);
    // the dadmod.zip asset: its download address and size
    size_t a = seg.find("\"name\": \"dadmod.zip\"");
    if (a == std::string::npos) a = seg.find("\"name\":\"dadmod.zip\"");
    if (a != std::string::npos) {
        // the asset's fields after its name: uploader { }, ..., size, ..., browser_download_url
        std::string u = JsonField(seg, "browser_download_url", a);
        strncpy(g_url, u.c_str(), sizeof g_url - 1);
        size_t sp = seg.find("\"size\"", a);
        if (sp != std::string::npos) { sp = seg.find(':', sp); if (sp != std::string::npos) InterlockedExchange(&g_size, atol(seg.c_str() + sp + 1)); }
    }
    MakeNotes(JsonField(seg, "body"), g_notes, 90);
    if (!g_notes[0]) _snprintf(g_notes, sizeof g_notes - 1, "dadmod %s is out. Download it while you play, then restart to install it", g_new);
    bool newer = CmpVer(best, cur) > 0;
    Log("update check: newest release %s, this game has %s%s", tag.c_str(), g_cur, newer ? " -> update available" : "");
    if (newer) Log("update check: %s (%ld bytes) notes: %s", g_url, (long)g_size, g_notes);
    InterlockedExchange(&g_state, newer ? 2 : 1);
    return 0;
}

static void StartCheck() {
    std::string vf = ExeDirFile("version.txt");
    FILE* f = fopen(vf.c_str(), "rb");
    if (!f) { Log("update check: no dadmod\\version.txt, skipped"); g_state = 4; return; }
    char line[64] = ""; fgets(line, sizeof line, f); fclose(f);
    int i = 0; for (char* p = line; *p && *p != '\r' && *p != '\n' && i < (int)sizeof g_cur - 1; p++) if (*p != ' ') g_cur[i++] = *p;
    g_cur[i] = 0;
    HANDLE t = CreateThread(NULL, 0, CheckThread, NULL, 0, NULL);
    if (t) CloseHandle(t); else g_state = 3;
}

static DWORD WINAPI DownloadThread(LPVOID) {
    std::string part = g_zip + ".part";
    wchar_t wurl[1024]; MultiByteToWideChar(CP_ACP, 0, g_url, -1, wurl, 1024);
    std::string unused;
    Log("update: downloading %s", g_url);
    bool ok = HttpGet(wurl, unused, part.c_str());
    if (ok && g_size && g_dlDone != g_size) { Log("update: download is %ld bytes, expected %ld", (long)g_dlDone, (long)g_size); ok = false; }
    if (ok) ok = MoveFileExA(part.c_str(), g_zip.c_str(), MOVEFILE_REPLACE_EXISTING) != 0;
    if (!ok) DeleteFileA(part.c_str());
    Log("update: download %s (%ld bytes)", ok ? "done" : "failed", (long)g_dlDone);
    InterlockedExchange(&g_dl, ok ? 2 : 3);
    return 0;
}

static void MbText(char* out, size_t cap, LONG done, LONG total) {
    if (total > 0) _snprintf(out, cap - 1, "Downloading update... %ld of %ld MB", (long)(done >> 20), (long)((total + (1 << 19)) >> 20));
    else _snprintf(out, cap - 1, "Downloading update... %ld MB", (long)(done >> 20));
    out[cap - 1] = 0;
}

// THUGRECOMP_UpdateInfo [popup] ->
//   update_state (0 checking, 1 up to date, 2 newer, 3 failed, 4 unknown), update_version "0.9.11",
//   update_current "0.9.10", update_dl (0 not started, 1 downloading, 2 ready to install, 3 download failed),
//   update_label (the dadmod menu row), update_desc (its hint: the change log), update_progress (on-screen text).
//   With popup: update_popup = 1 the first time a newer version is known in this game session, else 0.
static bool __cdecl CF_UpdateInfo(void* params, void* script) {
    LONG st = g_state, dl = g_dl;
    RetInt(script, "update_state", (int)st);
    RetInt(script, "update_dl", (int)dl);
    RetStr(script, "update_version", g_new);
    RetStr(script, "update_current", g_cur);
    char label[96], desc[96], prog[96];
    if (dl == 2) {
        _snprintf(label, sizeof label - 1, "Restart to install update (%s)", g_new);
        _snprintf(desc, sizeof desc - 1, "Closes THUG Pro, installs dadmod %s and starts the game again", g_new);
        _snprintf(prog, sizeof prog - 1, "Update downloaded");
    } else if (dl == 1) {
        MbText(label, sizeof label, g_dlDone, g_dlTotal ? g_dlTotal : g_size);
        _snprintf(desc, sizeof desc - 1, "%s", g_notes);
        MbText(prog, sizeof prog, g_dlDone, g_dlTotal ? g_dlTotal : g_size);
    } else {
        _snprintf(label, sizeof label - 1, "Download newest update (%s)", g_new);
        _snprintf(desc, sizeof desc - 1, "%s", dl == 3 ? "The last download failed. Pick this to try again" : g_notes);
        _snprintf(prog, sizeof prog - 1, "%s", dl == 3 ? "Update download failed" : "");
    }
    label[sizeof label - 1] = desc[sizeof desc - 1] = prog[sizeof prog - 1] = 0;
    RetStr(script, "update_label", label);
    RetStr(script, "update_desc", desc);
    RetStr(script, "update_progress", prog);
    if (FlagParam(params, "popup")) {
        int show = (st == 2 && !g_popupShown) ? 1 : 0;
        if (show) g_popupShown = true;
        RetInt(script, "update_popup", show);
    }
    return true;
}

// THUGRECOMP_UpdateDownload -> update_ok 1 when the background download started (or is already running / done)
static bool __cdecl CF_UpdateDownload(void* params, void* script) {
    (void)params;
    if (g_dl == 1 || g_dl == 2) { RetInt(script, "update_ok", 1); return true; }
    if (g_state != 2 || !g_url[0]) { Log("update: nothing to download"); RetInt(script, "update_ok", 0); return true; }
    std::string dir = ExeDirFile("update");
    CreateDirectoryA(dir.c_str(), NULL);
    g_zip = dir + "\\dadmod.zip";
    InterlockedExchange(&g_dlDone, 0);
    InterlockedExchange(&g_dlTotal, 0);
    InterlockedExchange(&g_dl, 1);
    HANDLE t = CreateThread(NULL, 0, DownloadThread, NULL, 0, NULL);
    if (t) CloseHandle(t); else InterlockedExchange(&g_dl, 3);
    RetInt(script, "update_ok", t ? 1 : 0);
    return true;
}

// THUGRECOMP_UpdateStart -> update_ok 1 when the updater window started (the script then quits the game)
static bool __cdecl CF_UpdateStart(void* params, void* script) {
    (void)params;
    char exe[MAX_PATH]; GetModuleFileNameA(NULL, exe, MAX_PATH);
    char game[MAX_PATH]; strcpy(game, exe);
    char* sl = strrchr(game, '\\'); if (sl) *sl = 0;          // no trailing backslash: it would escape the quote
    std::string ps1 = ExeDirFile("updater\\dadmod.ps1");
    if (g_started || GetFileAttributesA(ps1.c_str()) == INVALID_FILE_ATTRIBUTES) {
        Log("update: %s", g_started ? "already started" : "no dadmod\\updater\\dadmod.ps1 (run Setup.bat to update this time)");
        RetInt(script, "update_ok", 0);
        return true;
    }
    char sys[MAX_PATH]; GetSystemDirectoryA(sys, MAX_PATH);
    char zipArg[MAX_PATH + 16] = "";
    if (g_dl == 2 && !g_zip.empty()) _snprintf(zipArg, sizeof zipArg - 1, " -Zip \"%s\"", g_zip.c_str());
    char cmd[2048];
    _snprintf(cmd, sizeof cmd - 1, "\"%s\\WindowsPowerShell\\v1.0\\powershell.exe\" -NoProfile -ExecutionPolicy Bypass -File \"%s\" update -Game \"%s\" -WaitPid %lu%s",
              sys, ps1.c_str(), game, GetCurrentProcessId(), zipArg);
    cmd[sizeof cmd - 1] = 0;
    STARTUPINFOA si; memset(&si, 0, sizeof si); si.cb = sizeof si;
    PROCESS_INFORMATION pi;
    BOOL ok = CreateProcessA(NULL, cmd, NULL, NULL, FALSE, CREATE_NEW_CONSOLE, NULL, game, &si, &pi);
    if (ok) { CloseHandle(pi.hThread); CloseHandle(pi.hProcess); g_started = true; }
    Log("update: %s %s", ok ? "started" : "could not start", cmd);
    RetInt(script, "update_ok", ok ? 1 : 0);
    return true;
}

}  // namespace dupdate
