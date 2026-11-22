// Client build: puts the custom main menu scenes together on the player's own machine.
//
// The installer ships one cleaned node array per menu level (dadmod\menulevels\<key>.qb, made by
// client/tools/build_menulevels.py) and dadmod\menulevels\list.txt, one line per archive:
//     <archive> <qb file> <name inside> <extra archive or -> <file data\pre must have, or ->
// At boot, before any script loads, each data\pre\<archive> (mainmenu_<key>_scripts.prx) is written as
//     the player's own data\pre\Skateshop_scripts.prx  (stock or Kali, whichever is installed)
//   + the level's own thugpro archive (entries the skate shop doesn't already have)
//   + our node array,
// the same layout the server build ships (mods/mainmenu/gen_menulevels.py). They are only rewritten when one
// of those files changed (dadmod\menulevels\built.txt), so a later Kali install gets its skate shop scripts in.
// A level whose scene isn't installed gets no archive, and the menu shows the skate shop instead (ClientMenuLevel).
// The uninstaller removes every archive list.txt names.
namespace menulevels {

static std::string GameDir() {
    std::string d = ExeDirFile("x");
    return d.substr(0, d.size() - strlen("dadmod\\x"));
}

static std::string FileStamp(const std::string& path) {
    WIN32_FILE_ATTRIBUTE_DATA a;
    if (!GetFileAttributesExA(path.c_str(), GetFileExInfoStandard, &a)) return "none;";
    char buf[64];
    sprintf(buf, "%lu:%lu:%lu;", a.nFileSizeLow, a.ftLastWriteTime.dwLowDateTime, a.ftLastWriteTime.dwHighDateTime);
    return buf;
}

static DWORD Crc(std::string s) {  // the game's file-name checksum (tools/qb.py qbkey)
    DWORD c = 0xFFFFFFFF;
    for (char ch : s) {
        unsigned char b = (unsigned char)tolower((unsigned char)(ch == '/' ? '\\' : ch));
        c ^= b;
        for (int k = 0; k < 8; ++k) c = (c >> 1) ^ ((c & 1) ? 0xEDB88320u : 0);
    }
    return c;
}

struct Entry { std::string name; std::string raw; };  // raw = the whole entry as stored (header, name, padded data)

static bool ReadArchive(const std::string& path, std::vector<Entry>& out) {
    std::string b;
    if (!ReadWholeFile(path, b) || b.size() < 12) return false;
    if (*(WORD*)(b.data() + 4) != 3 || *(WORD*)(b.data() + 6) != 0xABCD) return false;
    DWORD n = *(DWORD*)(b.data() + 8);
    size_t off = 12;
    for (DWORD i = 0; i < n; ++i) {
        if (off + 16 > b.size()) return false;
        DWORD usz = *(DWORD*)(b.data() + off), csz = *(DWORD*)(b.data() + off + 4), nl = *(DWORD*)(b.data() + off + 8);
        DWORD d = csz ? csz : usz;
        size_t len = 16 + nl + ((d + 3) & ~3u);
        if (off + 16 + nl > b.size()) return false;
        if (off + len > b.size()) len = b.size() - off;  // last entry without padding
        Entry e;
        e.name.assign(b.data() + off + 16, strnlen(b.data() + off + 16, nl));
        e.raw.assign(b.data() + off, len);
        e.raw.resize(((len + 3) & ~(size_t)3), '\0');
        out.push_back(e);
        off += len;
    }
    return true;
}

static std::string LowerStr(std::string s) { for (auto& c : s) c = (char)tolower((unsigned char)c); return s; }

static bool BuildOne(const std::string& pre, const std::string& qbPath, const std::string& inner,
                     const std::string& extra, const std::string& target) {
    std::vector<Entry> ents;
    if (!ReadArchive(pre + "Skateshop_scripts.prx", ents)) { Log("menu levels: can't read Skateshop_scripts.prx"); return false; }
    if (extra != "-") {
        std::vector<Entry> more;
        if (ReadArchive(pre + extra, more)) {
            std::vector<std::string> have;
            for (auto& e : ents) have.push_back(LowerStr(e.name));
            for (auto& e : more) {
                std::string l = LowerStr(e.name);
                bool dup = false;
                for (auto& h : have) if (h == l) { dup = true; break; }
                if (!dup) ents.push_back(e);
            }
        }
    }
    std::string data;
    if (!ReadWholeFile(qbPath, data) || data.empty()) { Log("menu levels: can't read %s", qbPath.c_str()); return false; }
    std::string nm = inner;
    nm.push_back('\0');
    while (nm.size() % 4) nm.push_back('\0');
    Entry ours;
    DWORD hdr[4] = { (DWORD)data.size(), 0, (DWORD)nm.size(), Crc(inner) };
    ours.raw.assign((const char*)hdr, 16);
    ours.raw += nm + data;
    while (ours.raw.size() % 4) ours.raw.push_back('\0');
    ents.push_back(ours);
    std::string body;
    for (auto& e : ents) body += e.raw;
    DWORD head[3];
    head[0] = (DWORD)(12 + body.size());
    head[1] = 3 | (0xABCDu << 16);
    head[2] = (DWORD)ents.size();
    return WriteWholeFile(target, std::string((const char*)head, 12) + body);
}

static std::vector<std::vector<std::string>> ReadList(const std::string& path) {
    std::vector<std::vector<std::string>> rows;
    std::string s;
    if (!ReadWholeFile(path, s)) return rows;
    size_t p = 0;
    while (p < s.size()) {
        size_t e = s.find('\n', p);
        if (e == std::string::npos) e = s.size();
        std::string line = s.substr(p, e - p);
        p = e + 1;
        std::vector<std::string> f;
        size_t i = 0;
        while (i < line.size()) {
            while (i < line.size() && (line[i] == ' ' || line[i] == '\r' || line[i] == '\t')) ++i;
            size_t j = i;
            while (j < line.size() && line[j] != ' ' && line[j] != '\r' && line[j] != '\t') ++j;
            if (j > i) f.push_back(line.substr(i, j - i));
            i = j;
        }
        if (f.size() >= 5 && f[0][0] != '#') rows.push_back(f);
    }
    return rows;
}

static void Assemble() {
    std::string game = GameDir(), pre = game + "data\\pre\\", dir = ExeDirFile("menulevels\\");
    auto rows = ReadList(dir + "list.txt");
    if (rows.empty()) return;
    std::string stamp = FileStamp(pre + "Skateshop_scripts.prx") + FileStamp(dir + "list.txt");
    for (auto& r : rows) {
        stamp += r[0] + "=" + FileStamp(dir + r[1]);
        if (r[3] != "-") stamp += FileStamp(pre + r[3]);
        if (r[4] != "-") stamp += GetFileAttributesA((pre + r[4]).c_str()) != INVALID_FILE_ATTRIBUTES ? "y;" : "n;";
    }
    std::string old;
    ReadWholeFile(dir + "built.txt", old);
    bool same = old == stamp;
    int built = 0, kept = 0, skipped = 0, failed = 0;
    DWORD t0 = GetTickCount();
    for (auto& r : rows) {
        std::string target = pre + r[0];
        bool have = GetFileAttributesA(target.c_str()) != INVALID_FILE_ATTRIBUTES;
        if (r[4] != "-" && GetFileAttributesA((pre + r[4]).c_str()) == INVALID_FILE_ATTRIBUTES) {
            if (have) DeleteFileA(target.c_str());  // its scene went away: ours, never shown again
            ++skipped;
            continue;
        }
        // its scene file wasn't installed (Setup couldn't rebuild it from this game's files): not installed, so it
        // doesn't count as failed and the menu scenes aren't put together again on every start (Noah 2026-11-22)
        if (GetFileAttributesA((dir + r[1]).c_str()) == INVALID_FILE_ATTRIBUTES) {
            if (have) DeleteFileA(target.c_str());
            ++skipped;
            continue;
        }
        if (have && same) { ++kept; continue; }
        if (BuildOne(pre, dir + r[1], r[2], r[3], target)) ++built; else ++failed;
    }
    if (!failed) WriteWholeFile(dir + "built.txt", stamp);
    if (built || failed)
        Log("menu levels: %d put together, %d up to date, %d not installed, %d failed (%lu ms)",
            built, kept, skipped, failed, GetTickCount() - t0);
}

}  // namespace menulevels
