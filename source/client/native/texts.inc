// Client copies of three small script functions the client mods use, so the server-only mod files they
// live in (mods/qmenu/qmenu.inc, mods/modes_batch/modes.inc) stay out of the client build.
//   THUGRECOMP_TextSave key value / TextLoad key -> value: short texts kept in dadmod\qmenu_last.txt
//   THUGRECOMP_TextHas text find: case-insensitive "contains", color codes ignored
//   THUGRECOMP_Log text: a line in dadmod\client.log
static std::map<std::string, std::string> g_clientText;
static bool g_clientTextLoaded = false;

static void ClientTextLoad() {
    if (g_clientTextLoaded) return;
    g_clientTextLoaded = true;
    std::string data;
    if (!ReadWholeFile(ExeDirFile("qmenu_last.txt"), data)) return;
    size_t s = 0;
    while (s < data.size()) {
        size_t e = data.find_first_of("\r\n", s);
        std::string line = data.substr(s, e == std::string::npos ? std::string::npos : e - s);
        s = e == std::string::npos ? data.size() : e + 1;
        size_t t = line.find('\t');
        if (t != std::string::npos && t > 0) g_clientText[line.substr(0, t)] = line.substr(t + 1);
    }
}

static bool __cdecl CF_TextSave(void* params, void*) {
    const char* key;
    const char* value;
    if (!GetStringParam(params, "key", &key) || !GetStringParam(params, "value", &value)) return false;
    std::string k = key, v = mmenu::Trim(value);
    for (char& c : v) if (c == '\t' || c == '\r' || c == '\n') c = ' ';
    if (k.empty() || v.empty() || v.size() > 100) return false;
    ClientTextLoad();
    g_clientText[k] = v;
    std::string out;
    for (const auto& kv : g_clientText) out += kv.first + "\t" + kv.second + "\r\n";
    WriteWholeFile(ExeDirFile("qmenu_last.txt"), out);
    return true;
}

static bool __cdecl CF_TextLoad(void* params, void* script) {
    const char* key;
    if (!GetStringParam(params, "key", &key)) return false;
    ClientTextLoad();
    auto it = g_clientText.find(key);
    if (it == g_clientText.end() || it->second.empty()) return false;
    RetStr(script, "value", it->second.c_str());
    return true;
}

static std::string ClientTextFold(const char* s) {
    std::string o;
    for (size_t i = 0; s[i]; ++i) {
        if (s[i] == '\\' && (s[i + 1] == 'c' || s[i + 1] == 'C') && s[i + 2]) { i += 2; continue; }
        o += (char)tolower((unsigned char)s[i]);
    }
    return o;
}

static bool __cdecl CF_TextHas(void* params, void*) {
    const char* text;
    const char* find;
    if (!GetStringParam(params, "text", &text) || !GetStringParam(params, "find", &find)) return false;
    std::string f = mmenu::Trim(ClientTextFold(find));
    return f.empty() || ClientTextFold(text).find(f) != std::string::npos;
}

static bool __cdecl CF_Log(void* params, void*) {
    const char* t;
    if (GetStringParam(params, "text", &t)) Log("script: %s", t);
    return true;
}

// THUGRECOMP_MenuLevelHas index = <i>: true when the Menu level list may show level <i> (the skate shop, or a
// level whose menu archive was put together on this machine; mods/mainmenu/mainmenu.inc ClientMenuLevel)
static bool __cdecl CF_MenuLevelHas(void* params, void*) {
    int i = IntParam(params, "index", -1);
    if (i == 0) return true;
    if (i < 0 || i >= mmenu::kMenuLevelCount) return false;
    return mmenu::ClientHasMenuArchive(mmenu::kMenuLevels[i].key);
}
