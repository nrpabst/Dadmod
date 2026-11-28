// Servers joined log (Noah, 2026-11-27): <game>\dadmod\servers.log gets one line per server you join from the
// server list (time, name, IP:port, players, mode), one per level change while you are in that game, and one when you
// leave. Included after modes.inc / logcap.inc (ExeDirFile, IntParam, RetInt, RetStr, logcap::Append).
//   THUGRECOMP_ServerLogJoin id=<server list id>   called by choose_selected_server before the stock ChooseServer.
//                                                   Reads the game's own server list entry; false if it is not there.
//   THUGRECOMP_ServerLogTick net=0|1 host=0|1 level="<level>"
//                                                   called from dadmod_tod_watch (every 30 frames). Logs "connected",
//                                                   level changes and "left".
//   THUGRECOMP_ServerCurrent -> name="..." ip="a.b.c.d" port=N   true while we are in a game we joined from the list.
// Server list entry layout (THUGPro.exe, CF_ChooseServer 0x5470D0): list object = [0x7CCE14], lookup by id
// = thiscall 0x5464D0(list, id); entry +0x14 name (char[16]), +0x24 IPv4 (network order), +0x28 port,
// +0x30 players, +0x34 max players, +0x60 mode text.
namespace srvlog {

static const DWORD kServerList = 0x7CCE14;
static const DWORD kServerById = 0x5464D0;

struct Info { char name[17]; char mode[48]; DWORD ip; int port; int players; int maxPlayers; };

static bool g_have = false;      // a join was picked from the list
static bool g_connected = false; // net game seen since that pick
static int  g_outTicks = 0;      // ticks out of a net game after being in one
static int  g_waitTicks = 0;     // ticks since the pick without a net game
static Info g_cur;
static std::string g_level;

static bool ReadEntry(int id, Info* out) {
    __try {
        void* list = *(void**)kServerList;
        if (!list) return false;
        typedef char* (__thiscall* Fn)(void*, int);
        char* e = ((Fn)kServerById)(list, id);
        if (!e) return false;
        memcpy(out->name, e + 0x14, 16); out->name[16] = 0;
        memcpy(out->mode, e + 0x60, 47); out->mode[47] = 0;
        out->ip = *(DWORD*)(e + 0x24);
        out->port = *(int*)(e + 0x28);
        out->players = *(int*)(e + 0x30);
        out->maxPlayers = *(int*)(e + 0x34);
        return true;
    } __except (EXCEPTION_EXECUTE_HANDLER) { return false; }
}

static std::string IpText(DWORD ip) {
    const unsigned char* b = (const unsigned char*)&ip;
    char s[20]; wsprintfA(s, "%d.%d.%d.%d", b[0], b[1], b[2], b[3]);
    return s;
}

static std::string Printable(const char* s) {
    std::string r;
    for (; *s; ++s) r += (*s >= 32 && *s < 127) ? *s : '?';
    return r;
}

static void Write(const std::string& line) {
    SYSTEMTIME t; GetLocalTime(&t);
    char stamp[32];
    wsprintfA(stamp, "%04d-%02d-%02d %02d:%02d:%02d ", t.wYear, t.wMonth, t.wDay, t.wHour, t.wMinute, t.wSecond);
    std::string out = stamp + line + "\r\n";
    logcap::Append(ExeDirFile("servers.log").c_str(), out.data(), (DWORD)out.size(), logcap::kSmall);  // trims itself at 256 KB
}

static std::string Tag() { return "\"" + Printable(g_cur.name) + "\" " + IpText(g_cur.ip) + ":" + std::to_string(g_cur.port); }

static bool __cdecl CF_ServerLogJoin(void* params, void*) {
    // the list item passes id as a checksum (AddChecksum), and CF_ChooseServer reads it with GetChecksum
    DWORD cid = 0;
    typedef bool (__thiscall* CsFn)(void*, DWORD, DWORD*, bool);
    if (!((CsFn)0x476950)(params, QbKey("id"), &cid, false)) cid = (DWORD)IntParam(params, "id", 0);
    Info i;
    if (!ReadEntry((int)cid, &i)) {
        char m[80]; wsprintfA(m, "joining a server (list entry %08X not found)", cid);
        Write(m);
        return false;
    }
    if (g_have && g_connected) Write("left " + Tag());
    g_cur = i; g_have = true; g_connected = false; g_waitTicks = 0; g_outTicks = 0; g_level.clear();
    char extra[96];
    wsprintfA(extra, " players %d/%d mode ", i.players, i.maxPlayers);
    Write("joining " + Tag() + extra + Printable(i.mode));
    return true;
}

static bool __cdecl CF_ServerLogTick(void* params, void*) {
    if (!g_have) return true;
    bool net = IntParam(params, "net", 0) != 0;
    (void)IntParam(params, "host", 0);
    const char* lv = nullptr;
    GetStringParam(params, "level", &lv);
    if (!g_connected) {
        if (net) { g_connected = true; Write("connected to " + Tag()); }
        else if (++g_waitTicks > 120) { Write("never got in to " + Tag()); g_have = false; return true; }
        else return true;
    }
    // InNetGame drops for a moment while a level loads (seen 2026-11-27: "left" logged 4 s before the real quit),
    // so only count it as leaving after about 10 seconds out of a net game.
    // IsHost also reads true for a moment while a joined level loads (seen 2026-11-27: "left" 1 s after joining
    // with the 10 s wait in), so only "not in a net game" counts here.
    if (!net) {
        if (++g_outTicks > 20) {
            Write("left " + Tag());
            g_have = false; g_connected = false; g_level.clear(); g_outTicks = 0;
        }
        return true;
    }
    g_outTicks = 0;
    if (lv && *lv && g_level != lv) {
        g_level = lv;
        Write("level " + Printable(lv) + " on " + Tag());
    }
    return true;
}

static bool __cdecl CF_ServerCurrent(void*, void* script) {
    if (!g_have || !g_connected) return false;
    RetStr(script, "name", g_cur.name);
    RetStr(script, "ip", IpText(g_cur.ip).c_str());
    RetInt(script, "port", g_cur.port);
    return true;
}

// Servers where dadmod's added maps are locked for non-hosts (Noah, 2026-11-27: open level-select servers, where
// picking a map nobody else has kicks everyone). <game>\dadmod\locked_servers.txt, one per line: an IP, IP:port or
// server name (case and color codes ignored). Lines starting with ; are notes. Re-read at most once a second.
//   THUGRECOMP_ServerMapsLocked   true while we are in a game joined from the list whose server is on that list.
static std::vector<std::string> g_locked;
static DWORD g_lockedRead = 0;
static std::string LowerNoColor(const char* in) {
    std::string r;
    for (size_t i = 0; in[i]; ++i) {
        if (in[i] == '\\' && (in[i + 1] == 'c' || in[i + 1] == 'C') && in[i + 2]) { i += 2; continue; }
        r += (char)tolower((unsigned char)in[i]);
    }
    while (!r.empty() && (r.back() == ' ' || r.back() == '\t' || r.back() == '\r')) r.pop_back();
    size_t s = 0; while (s < r.size() && (r[s] == ' ' || r[s] == '\t')) ++s;
    return r.substr(s);
}
static void LoadLocked() {
    DWORD now = GetTickCount();
    if (g_lockedRead && now - g_lockedRead < 1000) return;
    g_lockedRead = now ? now : 1;
    g_locked.clear();
    // built in, so deleting the file does not unlock them (Noah, 2026-11-27: both ELEVATED FCFS servers)
    static const char* kBuiltIn[] = { "47.6.1.27:5153", "elevated fcfs", "47.6.1.27:5155", "elevated fcfs 2" };
    for (const char* k : kBuiltIn) g_locked.push_back(k);
    std::string text;
    if (!ReadWholeFile(ExeDirFile("locked_servers.txt"), text)) return;
    size_t p = 0;
    while (p <= text.size()) {
        size_t e = text.find('\n', p);
        if (e == std::string::npos) e = text.size();
        std::string line = LowerNoColor(text.substr(p, e - p).c_str());
        if (!line.empty() && line[0] != ';') g_locked.push_back(line);
        p = e + 1;
    }
}
static bool __cdecl CF_ServerMapsLocked(void*, void*) {
    if (!g_have || !g_connected) return false;
    LoadLocked();
    std::string ip = IpText(g_cur.ip), ipPort = ip + ":" + std::to_string(g_cur.port), name = LowerNoColor(g_cur.name);
    for (const std::string& l : g_locked)
        if (l == ip || l == ipPort || (!name.empty() && l == name)) return true;
    return false;
}

}  // namespace srvlog
