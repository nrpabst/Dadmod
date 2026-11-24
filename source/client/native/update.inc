// In-game updater (Noah 2026-11-18; reworked 2026-11-23). Client build only; included by loader.cpp after common.inc.
//  - Main menu > Dadmod has an "Updates" row that opens the Updates page (qb/dadmod/update.q): the update button
//    (check / download / restart and install), What's new for the new and the installed version, Auto update.
//  - Auto update (panel key upd_auto, default Off (Noah 2026-11-23 8:09 PM ET)): a newer release downloads in the background.
//  - Once dadmod.zip is downloaded, a hidden updater waits for this game to close and installs it then ("installs
//    when you quit"); "Restart and install now" leaves a flag file so the updater starts the game again afterwards.
//
// Check: one background request at boot (and on "check again") to the public releases list, the one Setup.bat reads:
// api.github.com/repos/nrpabst/Dadmod/releases (highest version with a dadmod.zip wins). No token, nothing sent but
// the request. DADMOD_UPDATE_URL overrides the address (local tests), like the installer.
// Install: <game>\dadmod\updater\dadmod.ps1 update -Game <game> -WaitPid <pid> -Zip <zip> -Version <v> [-Sha256 <h>]
// -OnQuit, run by 64-bit PowerShell (Sysnative from this 32-bit game; the map packs need a big unpack window),
// without a console window: it shows its own small dadmod window while it installs.
#include <winhttp.h>
#pragma comment(lib, "winhttp.lib")

namespace dupdate {

static volatile LONG g_state = 0;   // 0 checking, 1 up to date, 2 newer, 3 check failed, 4 no version file
static volatile LONG g_checking = 0;
static char g_cur[32] = "";
static char g_new[32] = "";
static char g_url[1024] = "";        // browser_download_url of the newest dadmod.zip
static char g_sha[80] = "";          // its sha256 (GitHub "digest"), "" when GitHub gives none
static char g_notes[96] = "";        // short change log for the menu hint (ASCII, < 96 bytes)
static std::string g_body;           // the newest release's notes (What's new page)
static volatile LONG g_size = 0;     // asset size in bytes (0 = unknown)
static bool g_started = false;       // the restart-now updater was started
static bool g_armed = false;         // the waiting "install when you quit" updater runs
static DWORD g_armPid = 0;

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
// "0.10.3" -> 1003 (for settings: last version seen / popup shown)
static int VerNum(const char* s) {
    int v[4];
    if (!s[0] || !ParseVer(s, v)) return 0;
    return v[0] * 1000000 + v[1] * 1000 + v[2];
}

// GET url; the body goes to `body`, or to the file `toFile` when given (progress in g_dlDone / g_dlTotal).
// Uses the Windows (Internet Options) proxy when one is set, like Setup.bat does.
static bool HttpGet(const wchar_t* url, std::string& body, const char* toFile = nullptr) {
    URL_COMPONENTS uc; memset(&uc, 0, sizeof uc); uc.dwStructSize = sizeof uc;
    wchar_t host[256], path[2048];
    uc.lpszHostName = host; uc.dwHostNameLength = 256; uc.lpszUrlPath = path; uc.dwUrlPathLength = 2048;
    wchar_t extra[2048]; uc.lpszExtraInfo = extra; uc.dwExtraInfoLength = 2048;
    if (!WinHttpCrackUrl(url, 0, 0, &uc)) return false;
    std::wstring full = std::wstring(path) + extra;
    bool ok = false;
    WINHTTP_CURRENT_USER_IE_PROXY_CONFIG ie; memset(&ie, 0, sizeof ie);
    HINTERNET s = NULL;
    if (WinHttpGetIEProxyConfigForCurrentUser(&ie) && ie.lpszProxy && ie.lpszProxy[0])
        s = WinHttpOpen(L"dadmod-game", WINHTTP_ACCESS_TYPE_NAMED_PROXY, ie.lpszProxy,
                        ie.lpszProxyBypass && ie.lpszProxyBypass[0] ? ie.lpszProxyBypass : WINHTTP_NO_PROXY_BYPASS, 0);
    if (ie.lpszProxy) GlobalFree(ie.lpszProxy);
    if (ie.lpszProxyBypass) GlobalFree(ie.lpszProxyBypass);
    if (ie.lpszAutoConfigUrl) GlobalFree(ie.lpszAutoConfigUrl);
    if (!s) s = WinHttpOpen(L"dadmod-game", WINHTTP_ACCESS_TYPE_DEFAULT_PROXY, WINHTTP_NO_PROXY_NAME, WINHTTP_NO_PROXY_BYPASS, 0);
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
                        DWORD n = 0, w = 0; bool wr = true, rd = true;
                        for (;;) {
                            if (!WinHttpReadData(r, buf, sizeof buf, &n)) { rd = false; break; }
                            if (!n) break;
                            if (!WriteFile(f, buf, n, &w, NULL) || w != n) { wr = false; break; }
                            InterlockedExchangeAdd(&g_dlDone, (LONG)n);
                        }
                        CloseHandle(f);
                        ok = wr && rd && (!g_dlTotal || g_dlDone == g_dlTotal);
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
// the value of "key": "..." inside seg, from its first occurrence after `from` (and before `to`)
static std::string JsonField(const std::string& seg, const char* key, size_t from = 0, size_t to = std::string::npos) {
    std::string k = std::string("\"") + key + "\"";
    size_t p = seg.find(k, from);
    if (p == std::string::npos || (to != std::string::npos && p > to)) return "";
    p = seg.find(':', p + k.size());
    if (p == std::string::npos) return "";
    p++;
    while (p < seg.size() && (seg[p] == ' ' || seg[p] == '\n' || seg[p] == '\r' || seg[p] == '\t')) p++;
    return JsonStr(seg, p);
}

// release notes / whatsnew.txt -> the change items ("~ ", "+ ", "- ", "* ", "x " bullets, wrapped lines joined) and
// the NEW / CHANGED / FIXED headings, in order. Headings come back as "#NEW".
static std::vector<std::string> NoteItems(const std::string& body) {
    std::vector<std::string> items;
    size_t p = 0;
    std::string cur;
    auto flush = [&]() { if (!cur.empty()) { items.push_back(cur); cur.clear(); } };
    while (p < body.size()) {
        size_t e = body.find('\n', p); if (e == std::string::npos) e = body.size();
        std::string ln = body.substr(p, e - p);
        p = e + 1;
        while (!ln.empty() && (ln.back() == '\r' || ln.back() == ' ')) ln.pop_back();
        size_t a = ln.find_first_not_of(' ');
        if (a == std::string::npos) { flush(); continue; }
        std::string t = ln.substr(a);
        if (t.compare(0, 3, "```") == 0) { flush(); continue; }
        char b = t[0];
        bool heading = t.size() >= 3 && t.size() <= 12 && t.find_first_not_of("ABCDEFGHIJKLMNOPQRSTUVWXYZ '") == std::string::npos;
        if (heading) { flush(); items.push_back("#" + t); continue; }
        if ((b == '~' || b == '+' || b == '-' || b == '*' || b == 'x') && t.size() > 2 && t[1] == ' ') {
            flush(); cur = std::string(1, b) + " " + t.substr(2);
        } else if (!cur.empty() && a >= 4) {
            cur += " " + t;                        // wrapped line of the same bullet
        } else flush();
    }
    flush();
    for (std::string& it : items) {               // ASCII only, no markdown, no double quotes (QB strings)
        std::string clean;
        for (size_t i = 0; i < it.size(); ++i) {
            char ch = it[i];
            if (ch == '`' || (ch == '*' && i != 0)) continue;
            if ((unsigned char)ch < 32 || (unsigned char)ch > 126) ch = ' ';
            if (ch == '"') ch = '\'';
            if (ch == '\\') ch = '/';
            if (ch == ';') ch = ',';                // the menu font has no ';' (it drew a box)
            if (ch == ' ' && !clean.empty() && clean.back() == ' ') continue;
            clean += ch;
        }
        it = clean;
    }
    return items;
}

// release notes -> one short line: the first sentence of each change bullet joined with ". ", cut to fit the menu
// hint box (stock pause hints must stay under 96 bytes)
static void MakeNotes(const std::string& body, char* out, size_t cap) {
    std::string s;
    for (std::string it : NoteItems(body)) {
        if (it.empty() || it[0] == '#') continue;
        std::string clean = it.size() > 2 ? it.substr(2) : it;
        size_t dot = clean.find(". ");
        if (dot != std::string::npos) clean = clean.substr(0, dot);
        while (!clean.empty() && (clean.back() == ' ' || clean.back() == '.' || clean.back() == ';' || clean.back() == ',')) clean.pop_back();
        if (clean.empty()) continue;
        s += (s.empty() ? "" : ". ") + clean;
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

// notes -> menu rows of at most `width` characters (What's new page)
static std::vector<std::string> NoteLines(const std::string& body, size_t width) {
    std::vector<std::string> out;
    for (const std::string& it : NoteItems(body)) {
        if (it[0] == '#') {
            std::string h = it.substr(1);
            if (!out.empty()) out.push_back("");
            out.push_back(h);
            continue;
        }
        std::string rest = it, prefix = "";
        bool first = true;
        while (!rest.empty()) {
            size_t w = width - (first ? 0 : 2);
            std::string line;
            if (rest.size() <= w) { line = rest; rest.clear(); }
            else {
                size_t cut = rest.rfind(' ', w);
                if (cut == std::string::npos || cut < w / 2) cut = w;
                line = rest.substr(0, cut);
                rest = rest.substr(cut);
                while (!rest.empty() && rest[0] == ' ') rest.erase(0, 1);
            }
            out.push_back((first ? "" : "  ") + line);
            first = false;
        }
    }
    while (!out.empty() && out.back().empty()) out.pop_back();
    return out;
}

// the releases list: an array of release objects; each has "tag_name", "draft", its "assets" (each with "name",
// "size", "digest" and "browser_download_url") and "body" (the notes)
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

static std::string ZipPath() {
    std::string dir = ExeDirFile("update");
    CreateDirectoryA(dir.c_str(), NULL);
    return dir + "\\dadmod.zip";
}

static DWORD WINAPI CheckThread(LPVOID) {
    char url[1024];
    DWORD n = GetEnvironmentVariableA("DADMOD_UPDATE_URL", url, sizeof url);
    if (!n || n >= sizeof url) strcpy(url, "https://api.github.com/repos/nrpabst/Dadmod/releases?per_page=30");
    wchar_t wurl[1024]; MultiByteToWideChar(CP_ACP, 0, url, -1, wurl, 1024);
    std::string body;
    if (!HttpGet(wurl, body)) { Log("update check: could not read the releases list"); InterlockedExchange(&g_state, 3); InterlockedExchange(&g_checking, 0); return 0; }
    int best[4], cur[4]; std::string tag, seg;
    FindNewest(body, best, tag, seg);
    if (best[0] < 0) { Log("update check: no release with a dadmod.zip"); InterlockedExchange(&g_state, 1); InterlockedExchange(&g_checking, 0); return 0; }
    ParseVer(g_cur, cur);
    char nv[32];
    _snprintf(nv, sizeof nv - 1, "%d.%d.%d", best[0], best[1], best[2]);
    if (best[3]) _snprintf(nv, sizeof nv - 1, "%d.%d.%d.%d", best[0], best[1], best[2], best[3]);
    nv[sizeof nv - 1] = 0;
    // the dadmod.zip asset: its download address, size and sha256
    char u[1024] = "", sha[80] = ""; LONG size = 0;
    size_t a = seg.find("\"name\": \"dadmod.zip\"");
    if (a == std::string::npos) a = seg.find("\"name\":\"dadmod.zip\"");
    if (a != std::string::npos) {
        size_t endA = seg.find("\"browser_download_url\"", a);
        std::string bu = JsonField(seg, "browser_download_url", a);
        strncpy(u, bu.c_str(), sizeof u - 1);
        size_t sp = seg.find("\"size\"", a);
        if (sp != std::string::npos && sp < endA) { sp = seg.find(':', sp); if (sp != std::string::npos) size = atol(seg.c_str() + sp + 1); }
        std::string dg = JsonField(seg, "digest", a, endA);
        if (dg.compare(0, 7, "sha256:") == 0 && dg.size() == 7 + 64) strncpy(sha, dg.c_str() + 7, sizeof sha - 1);
    }
    bool newer = CmpVer(best, cur) > 0;
    // a download kept from an earlier game session: ready to install when it is this version and whole
    LONG dl = g_dl;
    if (dl != 1) {
        std::string zip = ZipPath(), verf = zip + ".ver", have;
        ReadWholeFile(verf, have);
        have = mmenu::Trim(have);
        WIN32_FILE_ATTRIBUTE_DATA fa;
        bool exists = GetFileAttributesExA(zip.c_str(), GetFileExInfoStandard, &fa) != 0;
        if (exists && newer && have == nv && size && fa.nFileSizeHigh == 0 && (LONG)fa.nFileSizeLow == size) {
            g_zip = zip;
            dl = 2;
            Log("update check: dadmod %s was already downloaded, ready to install", nv);
        } else if (exists && dl != 2) {
            DeleteFileA(zip.c_str()); DeleteFileA(verf.c_str());   // an older or broken download
        }
    }
    strncpy(g_new, nv, sizeof g_new - 1);
    strncpy(g_url, u, sizeof g_url - 1);
    strncpy(g_sha, sha, sizeof g_sha - 1);
    InterlockedExchange(&g_size, size);
    g_body = JsonField(seg, "body");
    MakeNotes(g_body, g_notes, 90);
    if (!g_notes[0]) _snprintf(g_notes, sizeof g_notes - 1, "dadmod %s is out", g_new);
    if (dl == 2) InterlockedExchange(&g_dl, 2);
    Log("update check: newest release %s, this game has %s%s", tag.c_str(), g_cur, newer ? " -> update available" : "");
    if (newer) Log("update check: %s (%ld bytes, sha256 %s) notes: %s", g_url, (long)g_size, g_sha[0] ? g_sha : "-", g_notes);
    InterlockedExchange(&g_state, newer ? 2 : 1);
    InterlockedExchange(&g_checking, 0);
    return 0;
}

static void Check() {
    if (InterlockedCompareExchange(&g_checking, 1, 0) != 0) return;
    InterlockedExchange(&g_state, 0);
    HANDLE t = CreateThread(NULL, 0, CheckThread, NULL, 0, NULL);
    if (t) CloseHandle(t); else { InterlockedExchange(&g_state, 3); InterlockedExchange(&g_checking, 0); }
}

static void StartCheck() {
    std::string vf = ExeDirFile("version.txt");
    FILE* f = fopen(vf.c_str(), "rb");
    if (!f) { Log("update check: no dadmod\\version.txt, skipped"); g_state = 4; return; }
    char line[64] = ""; fgets(line, sizeof line, f); fclose(f);
    int i = 0; for (char* p = line; *p && *p != '\r' && *p != '\n' && i < (int)sizeof g_cur - 1; p++) if (*p != ' ') g_cur[i++] = *p;
    g_cur[i] = 0;
    Check();
}

static DWORD WINAPI DownloadThread(LPVOID) {
    std::string part = g_zip + ".part";
    wchar_t wurl[1024]; MultiByteToWideChar(CP_ACP, 0, g_url, -1, wurl, 1024);
    std::string unused;
    Log("update: downloading %s", g_url);
    bool ok = HttpGet(wurl, unused, part.c_str());
    if (ok && g_size && g_dlDone != g_size) { Log("update: download is %ld bytes, expected %ld", (long)g_dlDone, (long)g_size); ok = false; }
    if (ok) ok = MoveFileExA(part.c_str(), g_zip.c_str(), MOVEFILE_REPLACE_EXISTING) != 0;
    if (ok) WriteWholeFile(g_zip + ".ver", std::string(g_new) + "\r\n");
    if (!ok) DeleteFileA(part.c_str());
    Log("update: download %s (%ld bytes)", ok ? "done" : "failed", (long)g_dlDone);
    InterlockedExchange(&g_dl, ok ? 2 : 3);
    return 0;
}

static bool StartDownload() {
    if (g_dl == 1 || g_dl == 2) return true;
    if (g_state != 2 || !g_url[0]) { Log("update: nothing to download"); return false; }
    g_zip = ZipPath();
    InterlockedExchange(&g_dlDone, 0);
    InterlockedExchange(&g_dlTotal, 0);
    InterlockedExchange(&g_dl, 1);
    HANDLE t = CreateThread(NULL, 0, DownloadThread, NULL, 0, NULL);
    if (t) CloseHandle(t); else InterlockedExchange(&g_dl, 3);
    return t != NULL;
}

static bool AutoOn() {
    int v = 0;                                     // default Off (Noah 2026-11-23 8:09 PM ET)
    if (!gfx::PanelGet("upd_auto", &v)) v = 0;
    return v != 0;
}

// 64-bit PowerShell when this 32-bit game runs on 64-bit Windows (System32 would give the 32-bit one)
static std::wstring PowerShellExe() {
    wchar_t win[MAX_PATH]; GetWindowsDirectoryW(win, MAX_PATH);
    BOOL wow = FALSE; IsWow64Process(GetCurrentProcess(), &wow);
    std::wstring p = std::wstring(win) + (wow ? L"\\Sysnative" : L"\\System32") + L"\\WindowsPowerShell\\v1.0\\powershell.exe";
    if (GetFileAttributesW(p.c_str()) == INVALID_FILE_ATTRIBUTES)
        p = std::wstring(win) + L"\\System32\\WindowsPowerShell\\v1.0\\powershell.exe";
    return p;
}
static std::wstring Widen(const std::string& s) {
    wchar_t w[2048]; MultiByteToWideChar(CP_ACP, 0, s.c_str(), -1, w, 2048); return w;
}
// the game folder (no trailing backslash: it would escape the closing quote), wide so any folder name works
static std::wstring GameDirW() {
    wchar_t exe[MAX_PATH]; GetModuleFileNameW(NULL, exe, MAX_PATH);
    wchar_t* sl = wcsrchr(exe, L'\\'); if (sl) *sl = 0;
    return exe;
}

// runs dadmod\updater\dadmod.ps1 update ... ; onQuit = wait for this game to close, install, start it again only
// when "Restart and install now" left dadmod\update\restart.txt
static bool RunUpdater(bool onQuit) {
    std::wstring game = GameDirW();
    std::wstring ps1 = game + L"\\dadmod\\updater\\dadmod.ps1";
    if (GetFileAttributesW(ps1.c_str()) == INVALID_FILE_ATTRIBUTES) { Log("update: no dadmod\\updater\\dadmod.ps1 (run Setup.bat to update this time)"); return false; }
    std::wstring cmd = L"\"" + PowerShellExe() + L"\" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \"" + ps1 +
                       L"\" update -Game \"" + game + L"\" -WaitPid " + std::to_wstring(GetCurrentProcessId());
    if (g_dl == 2 && !g_zip.empty()) {
        cmd += L" -Zip \"" + Widen(g_zip) + L"\" -Version " + Widen(g_new);
        if (g_sha[0]) cmd += L" -Sha256 " + Widen(g_sha);
    }
    if (onQuit) cmd += L" -OnQuit";
    std::vector<wchar_t> buf(cmd.begin(), cmd.end()); buf.push_back(0);
    STARTUPINFOW si; memset(&si, 0, sizeof si); si.cb = sizeof si;
    PROCESS_INFORMATION pi;
    BOOL ok = CreateProcessW(NULL, buf.data(), NULL, NULL, FALSE, CREATE_NO_WINDOW, NULL, game.c_str(), &si, &pi);
    if (ok) { CloseHandle(pi.hThread); if (onQuit) g_armPid = pi.dwProcessId; CloseHandle(pi.hProcess); }
    Log("update: updater %s%s", ok ? "started" : "could not start", onQuit ? " (installs when the game closes)" : "");
    return ok != 0;
}
static bool ArmedAlive() {
    if (!g_armed || !g_armPid) return false;
    HANDLE h = OpenProcess(SYNCHRONIZE, FALSE, g_armPid);
    if (!h) return false;
    bool alive = WaitForSingleObject(h, 0) == WAIT_TIMEOUT;
    CloseHandle(h);
    return alive;
}

static void MbText(char* out, size_t cap, const char* lead, LONG done, LONG total) {
    if (total > 0) _snprintf(out, cap - 1, "%s %ld%%", lead, (long)((double)done * 100.0 / (double)total));
    else _snprintf(out, cap - 1, "%s %ld MB", lead, (long)(done >> 20));
    out[cap - 1] = 0;
}
static void SizeText(char* out, size_t cap) {
    LONG s = g_size;
    if (s <= 0) out[0] = 0;
    else if (s < (1 << 20)) _snprintf(out, cap - 1, " (%ld KB)", (long)((s + 1023) >> 10));
    else _snprintf(out, cap - 1, " (%ld MB)", (long)((s + (1 << 19)) >> 20));
    out[cap - 1] = 0;
}

// THUGRECOMP_UpdateInfo [auto] ->
//   update_state (0 checking, 1 up to date, 2 newer, 3 failed, 4 unknown), update_dl (0 not started, 1 downloading,
//   2 downloaded, 3 download failed), update_version "0.10.3", update_current "0.10.2", update_version_num /
//   update_current_num (for the popup settings), update_auto (Auto update setting), update_row (main menu > Dadmod
//   row), update_act / update_act_desc (the Updates page button and its hint), update_line (one-line status for
//   the main menu and the corner while playing, "" when there is nothing to say).
//   With auto: starts the download when Auto update is on. Also arms the "install when you quit" updater once a
//   download is ready (from the main thread, so it is never started twice).
static bool __cdecl CF_UpdateInfo(void* params, void* script) {
    LONG st = g_state, dl = g_dl;
    bool aut = AutoOn();
    if (FlagParam(params, "auto") && st == 2 && (dl == 0) && aut) { StartDownload(); dl = g_dl; }
    static int armTries = 0;                       // at most 3 waiting updaters per game session
    if (dl == 2 && st == 2 && !g_armed && !g_started && armTries < 3) { ++armTries; g_armed = RunUpdater(true); }
    else if (dl == 2 && g_armed && !g_started && !ArmedAlive()) { g_armed = false; }   // re-armed on the next call
    std::string from;                              // dadmod\update\updated_from.txt = the version before the last update
    if (ReadWholeFile(ExeDirFile("update\\updated_from.txt"), from)) {
        std::string v;
        for (char ch : from) if ((ch >= '0' && ch <= '9') || ch == '.') v += ch; else if (!v.empty()) break;
        if (FlagParam(params, "seen")) { DeleteFileA(ExeDirFile("update\\updated_from.txt").c_str()); v.clear(); }
        from = v.size() < 16 ? v : "";
    } else from.clear();
    RetStr(script, "update_from", from.c_str());
    RetInt(script, "update_state", (int)st);
    RetInt(script, "update_dl", (int)dl);
    RetInt(script, "update_auto", aut ? 1 : 0);
    RetStr(script, "update_version", g_new);
    RetStr(script, "update_current", g_cur);
    RetInt(script, "update_version_num", VerNum(g_new));
    RetInt(script, "update_current_num", VerNum(g_cur));
    char row[96], act[96], desc[96], line[96], sz[24];
    SizeText(sz, sizeof sz);
    row[0] = act[0] = desc[0] = line[0] = 0;
    if (st == 2 && dl == 2) {
        _snprintf(row, sizeof row - 1, "Updates (%s ready)", g_new);
        _snprintf(act, sizeof act - 1, "Restart and install %s now", g_new);
        _snprintf(desc, sizeof desc - 1, "Or keep playing: dadmod %s installs by itself when you quit THUG Pro", g_new);
        _snprintf(line, sizeof line - 1, "dadmod %s is ready - it installs when you quit", g_new);
    } else if (st == 2 && dl == 1) {
        MbText(row, sizeof row, "Updates (downloading", g_dlDone, g_dlTotal ? g_dlTotal : g_size);
        strncat(row, ")", sizeof row - strlen(row) - 1);
        MbText(act, sizeof act, "Downloading dadmod update...", g_dlDone, g_dlTotal ? g_dlTotal : g_size);
        _snprintf(desc, sizeof desc - 1, "Keep playing. When it's done, dadmod %s installs when you quit", g_new);
        char lead[48]; _snprintf(lead, sizeof lead - 1, "Downloading dadmod %s...", g_new); lead[sizeof lead - 1] = 0;
        MbText(line, sizeof line, lead, g_dlDone, g_dlTotal ? g_dlTotal : g_size);
    } else if (st == 2) {
        _snprintf(row, sizeof row - 1, "Updates (%s is out)", g_new);
        _snprintf(act, sizeof act - 1, "Download dadmod %s%s", g_new, sz);
        _snprintf(desc, sizeof desc - 1, "%s", dl == 3 ? "The last download failed. Pick this to try again" : g_notes);
        if (dl == 3) _snprintf(line, sizeof line - 1, "The dadmod %s download failed - Dadmod > Updates", g_new);
        else _snprintf(line, sizeof line - 1, "dadmod %s is out - Dadmod > Updates", g_new);
    } else if (st == 0) {
        _snprintf(row, sizeof row - 1, "Updates");
        _snprintf(act, sizeof act - 1, "Checking for updates...");
        _snprintf(desc, sizeof desc - 1, "Asking GitHub for the newest dadmod");
    } else if (st == 1) {
        _snprintf(row, sizeof row - 1, "Updates");
        _snprintf(act, sizeof act - 1, "Up to date (dadmod %s)", g_cur);
        _snprintf(desc, sizeof desc - 1, "You have the newest dadmod. Pick this to check again");
    } else if (st == 3) {
        _snprintf(row, sizeof row - 1, "Updates");
        _snprintf(act, sizeof act - 1, "Couldn't check for updates");
        _snprintf(desc, sizeof desc - 1, "No internet, or GitHub is busy. Pick this to try again");
    } else {
        _snprintf(row, sizeof row - 1, "Updates");
        _snprintf(act, sizeof act - 1, "dadmod version unknown");
        _snprintf(desc, sizeof desc - 1, "dadmod\\version.txt is missing. Run Setup.bat in dadmod-install to repair");
    }
    row[sizeof row - 1] = act[sizeof act - 1] = desc[sizeof desc - 1] = line[sizeof line - 1] = 0;
    RetStr(script, "update_row", row);
    RetStr(script, "update_act", act);
    RetStr(script, "update_act_desc", desc);
    RetStr(script, "update_line", line);
    return true;
}

// THUGRECOMP_UpdateDownload -> update_ok 1 when the background download started (or is already running / done)
static bool __cdecl CF_UpdateDownload(void* params, void* script) {
    (void)params;
    RetInt(script, "update_ok", StartDownload() ? 1 : 0);
    return true;
}

// THUGRECOMP_UpdateCheck -> asks GitHub again (the Updates page button when up to date or the check failed)
static bool __cdecl CF_UpdateCheck(void* params, void* script) {
    (void)params; (void)script;
    if (g_state == 1 || g_state == 3) Check();      // never while a newer release is known (its notes are in use)
    return true;
}

// THUGRECOMP_UpdateStart -> update_ok 1 when the game may quit now: the waiting updater installs and starts the game
// again (restart.txt), or a new updater was started for it
static bool __cdecl CF_UpdateStart(void* params, void* script) {
    (void)params;
    if (g_started) { Log("update: already started"); RetInt(script, "update_ok", 1); return true; }
    bool ok = false;
    if (g_dl == 2) {
        // restart.txt also when the waiting updater belongs to another open THUG Pro from this folder (two games at
        // once): that one installs once both are closed and must start the game again too (2026-11-24)
        bool flag = WriteWholeFile(ExeDirFile("update\\restart.txt"), "restart\r\n");
        if (flag && ArmedAlive()) { ok = true; Log("update: restart and install now (the waiting updater takes it from here)"); }
    }
    if (!ok) ok = RunUpdater(false);
    g_started = ok;
    RetInt(script, "update_ok", ok ? 1 : 0);
    return true;
}

// THUGRECOMP_UpdateNotes which=0|1 index=N -> note_count, note_text: the What's new page rows for the new release
// (which=0, from GitHub) or the installed version (which=1, dadmod\whatsnew.txt from the package)
static bool __cdecl CF_UpdateNotes(void* params, void* script) {
    static std::vector<std::string> lines[2];
    static std::string src[2];
    static int widths[2] = { 0, 0 };
    int which = IntParam(params, "which", 0) ? 1 : 0;
    int index = IntParam(params, "index", 0);
    int width = IntParam(params, "width", 40);
    if (width < 20) width = 20;
    if (width > 80) width = 80;
    std::string body;
    if (which == 0) { if (g_state == 2) body = g_body; }
    else ReadWholeFile(ExeDirFile("whatsnew.txt"), body);
    if (body != src[which] || width != widths[which]) { src[which] = body; widths[which] = width; lines[which] = NoteLines(body, (size_t)width); }
    RetInt(script, "note_count", (int)lines[which].size());
    RetStr(script, "note_text", index >= 0 && index < (int)lines[which].size() ? lines[which][index].c_str() : "");
    return true;
}

}  // namespace dupdate
