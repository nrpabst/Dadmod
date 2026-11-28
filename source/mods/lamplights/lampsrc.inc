// lampsrc (2026-11-23, Noah: "build it for players"): builds the lamp post models a map's lamp list names from the
// player's OWN game files, so the release ships no game content. dadmod\lamprecipes.txt (made by
// mods/lampeditor/lamp_cache.py: our own numbers only) says, per model, which level and which scene objects (sector
// checksums) to take, the base point and the bulbs. This file reads the level's scene and textures (THUG2 install:
// <thug2_path>\Data\Levels\XX\XX.scn.xbx / .tex.xbx; THUG Pro: <game>\data\pre\<level>scn.prx, LZSS packed) and
// builds the same model blob lamp_cache.py writes (lampmodels.inc draws it). A built model is kept in
// dadmod\lampcache\<key>.bin. Anything missing or unreadable: no model (the lamp's light still works).
// The scene layout is the one p8/tools/thug2scn.py reads (round-trip tested on every THUG2 and THUG Pro scene).
#include <string>
#include <vector>
#include <unordered_map>
#include <algorithm>
#include <stdint.h>
namespace lampsrc {

// ---- recipes
struct Recipe {
    std::string key, title, group, src, level;   // src "thug2" / "thugpro"
    int num = 0;
    std::vector<uint32_t> sectors;               // post first, then joined heads
    float base[3] = {0, 0, 0}, height = 0, rad = 0;
    std::vector<float> bulbs, aims;              // x y z per bulb / aim (0 0 0 = straight down)
};
static std::vector<Recipe> g_recipes;
static std::vector<std::string> g_groups;
static bool g_recipesRead = false;

static void SplitStr(const std::string& s, char sep, std::vector<std::string>& out) {
    out.clear();
    size_t a = 0;
    for (;;) {
        size_t b = s.find(sep, a);
        out.push_back(s.substr(a, b == std::string::npos ? std::string::npos : b - a));
        if (b == std::string::npos) break;
        a = b + 1;
    }
}
static void Floats(const std::string& s, std::vector<float>& out) {
    out.clear();
    const char* p = s.c_str();
    char* e;
    for (;;) {
        float v = strtof(p, &e);
        if (e == p) break;
        out.push_back(v);
        p = e;
    }
}
// model|KEY|TITLE|GROUP|NUM|SRC|LEVEL|cs,cs,...|bx by bz|height rad|b1x b1y b1z ...|a1x a1y a1z ...
static bool ReadRecipes() {
    if (g_recipesRead) return !g_recipes.empty();
    g_recipesRead = true;
    std::string data;
    if (!ReadWholeFile(ExeDirFile("lamprecipes.txt"), data)) {
        mmenu::Log("lampsrc: no dadmod\\lamprecipes.txt, lamp posts off (their lights still work)");
        return false;
    }
    size_t s0 = 0;
    std::vector<std::string> f;
    std::vector<float> v;
    while (s0 < data.size()) {
        size_t e = data.find_first_of("\r\n", s0);
        std::string line = data.substr(s0, e == std::string::npos ? std::string::npos : e - s0);
        s0 = e == std::string::npos ? data.size() : e + 1;
        if (line.compare(0, 6, "model|") != 0) continue;
        SplitStr(line, '|', f);
        if (f.size() < 12) continue;
        Recipe r;
        r.key = f[1]; r.title = f[2]; r.group = f[3]; r.num = atoi(f[4].c_str()); r.src = f[5]; r.level = f[6];
        std::vector<std::string> cs;
        SplitStr(f[7], ',', cs);
        for (const auto& c : cs) if (!c.empty()) r.sectors.push_back((uint32_t)strtoul(c.c_str(), nullptr, 16));
        Floats(f[8], v); if (v.size() >= 3) { r.base[0] = v[0]; r.base[1] = v[1]; r.base[2] = v[2]; }
        Floats(f[9], v); if (v.size() >= 2) { r.height = v[0]; r.rad = v[1]; }
        Floats(f[10], r.bulbs); r.bulbs.resize(r.bulbs.size() / 3 * 3);
        Floats(f[11], r.aims); r.aims.resize(r.bulbs.size(), 0.0f);
        if (r.sectors.empty() || r.bulbs.empty()) continue;
        bool known = false;
        for (const auto& g : g_groups) if (g == r.group) known = true;
        if (!known) g_groups.push_back(r.group);
        g_recipes.push_back(r);
    }
    mmenu::Log("lampsrc: %d lamp post recipes in %d groups", (int)g_recipes.size(), (int)g_groups.size());
    return !g_recipes.empty();
}
static int GroupOf(const Recipe& r) {
    for (size_t i = 0; i < g_groups.size(); ++i) if (g_groups[i] == r.group) return (int)i;
    return 0;
}

// ---- source files
static std::string Thug2Dir() {
    HKEY k;
    char buf[MAX_PATH] = {0};
    DWORD n = sizeof buf - 1, type = 0;
    if (RegOpenKeyExA(HKEY_CURRENT_USER, "Software\\THUG Pro\\Settings", 0, KEY_READ, &k) != ERROR_SUCCESS) return "";
    LONG rc = RegQueryValueExA(k, "thug2_path", nullptr, &type, (BYTE*)buf, &n);
    RegCloseKey(k);
    if (rc != ERROR_SUCCESS || type != REG_SZ) return "";
    std::string s = buf;
    if (!s.empty() && s.back() != '\\' && s.back() != '/') s += '\\';
    return s;
}
static std::string GameDir() {
    char p[MAX_PATH];
    DWORD n = GetModuleFileNameA(nullptr, p, MAX_PATH);
    std::string s(p, n);
    size_t c = s.find_last_of("\\/");
    return c == std::string::npos ? std::string() : s.substr(0, c + 1);
}
static bool ReadFileBytes(const std::string& path, std::string& out) {
    FILE* f = fopen(path.c_str(), "rb");
    if (!f) return false;
    fseek(f, 0, SEEK_END);
    long n = ftell(f);
    fseek(f, 0, SEEK_SET);
    if (n <= 0 || n > 256 * 1024 * 1024) { fclose(f); return false; }
    out.resize((size_t)n);
    bool ok = fread(&out[0], 1, (size_t)n, f) == (size_t)n;
    fclose(f);
    return ok;
}
// Neversoft PRE v3 archive (tools/prx_extract.py): entries with Okumura LZSS packing
static void Lzss(const uint8_t* src, size_t n, size_t outSize, std::string& out) {
    out.clear(); out.reserve(outSize);
    uint8_t ring[4096];
    memset(ring, ' ', sizeof ring);
    int r = 4096 - 18;
    size_t i = 0;
    unsigned flags = 0;
    while (out.size() < outSize && i < n) {
        flags >>= 1;
        if (!(flags & 0x100)) { if (i >= n) break; flags = src[i++] | 0xFF00; }
        if (flags & 1) {
            if (i >= n) break;
            uint8_t c = src[i++];
            out.push_back((char)c); ring[r] = c; r = (r + 1) & 4095;
        } else {
            if (i + 1 >= n) break;
            int lo = src[i], hi = src[i + 1];
            i += 2;
            int pos = lo | ((hi & 0xF0) << 4), len = (hi & 0x0F) + 3;
            for (int k = 0; k < len; ++k) {
                uint8_t c = ring[(pos + k) & 4095];
                out.push_back((char)c); ring[r] = c; r = (r + 1) & 4095;
            }
        }
    }
}
static bool PrxEntry(const std::string& prx, const std::string& wantSuffix, std::string& out) {
    const uint8_t* b = (const uint8_t*)prx.data();
    size_t n = prx.size();
    if (n < 12) return false;
    uint16_t magic; uint32_t cnt;
    memcpy(&magic, b + 6, 2); memcpy(&cnt, b + 8, 4);
    if (magic != 0xABCD || cnt > 100000) return false;
    size_t off = 12;
    for (uint32_t e = 0; e < cnt; ++e) {
        if (off + 16 > n) return false;
        uint32_t usz, csz, nl, ck;
        memcpy(&usz, b + off, 4); memcpy(&csz, b + off + 4, 4); memcpy(&nl, b + off + 8, 4); memcpy(&ck, b + off + 12, 4);
        off += 16;
        if (off + nl > n) return false;
        std::string name((const char*)b + off, strnlen((const char*)b + off, nl));
        off += nl;
        size_t d = csz ? csz : usz;
        if (off + d > n) return false;
        std::string low = name;
        for (auto& c : low) c = (char)tolower((unsigned char)(c == '/' ? '\\' : c));
        if (low.size() >= wantSuffix.size() && low.compare(low.size() - wantSuffix.size(), wantSuffix.size(), wantSuffix) == 0) {
            if (csz) Lzss(b + off, csz, usz, out);
            else out.assign((const char*)b + off, usz);
            return out.size() == usz;
        }
        off += (d + 3) & ~(size_t)3;
    }
    return false;
}
// the level's scene + textures (the last level read stays in memory: a map's models mostly share a few levels)
static std::string g_srcKey, g_scn, g_tex;
static bool LoadSource(const Recipe& r) {
    std::string k = r.src + ":" + r.level;
    if (k == g_srcKey) return !g_scn.empty();
    g_srcKey = k; g_scn.clear(); g_tex.clear();
    std::string lv = r.level, low = r.level;
    for (auto& c : low) c = (char)tolower((unsigned char)c);
    if (r.src == "thug2") {
        std::string d = Thug2Dir();
        if (d.empty()) { mmenu::Log("lampsrc: THUG2 folder not set (THUG Pro thug2_path), %s posts skipped", lv.c_str()); return false; }
        std::string base = d + "Data\\Levels\\" + lv + "\\" + lv;
        if (!ReadFileBytes(base + ".scn.xbx", g_scn) || !ReadFileBytes(base + ".tex.xbx", g_tex)) {
            mmenu::Log("lampsrc: %s.scn.xbx / .tex.xbx not found in the THUG2 folder, posts from it skipped", lv.c_str());
            g_scn.clear(); g_tex.clear();
            return false;
        }
        return true;
    }
    std::string prx;
    if (!ReadFileBytes(GameDir() + "data\\pre\\" + lv + "scn.prx", prx)) {
        mmenu::Log("lampsrc: data\\pre\\%sscn.prx not found, posts from it skipped", lv.c_str());
        return false;
    }
    if (!PrxEntry(prx, "\\" + low + ".scn.xbx", g_scn) || !PrxEntry(prx, "\\" + low + ".tex.xbx", g_tex)) {
        mmenu::Log("lampsrc: %sscn.prx has no readable scene / textures, posts from it skipped", lv.c_str());
        g_scn.clear(); g_tex.clear();
        return false;
    }
    return true;
}

// ---- scene reader (thug2scn.py)
struct Rd {
    const uint8_t* b; size_t n, o; bool ok = true;
    bool take(size_t k) { if (!ok || o + k > n) { ok = false; return false; } o += k; return true; }
    template <class T> T get() { T v{}; if (!ok || o + sizeof(T) > n) { ok = false; return v; } memcpy(&v, b + o, sizeof(T)); o += sizeof(T); return v; }
    template <class T> T peek(size_t at = 0) const { T v{}; if (o + at + sizeof(T) <= n) memcpy(&v, b + o + at, sizeof(T)); return v; }
};
struct Mat { uint32_t tex = 0, cut = 0, blend = 0; bool twosided = false; };
struct Mesh { uint32_t mat; uint8_t stride; uint16_t nv; const uint8_t* vb; uint32_t vbsize; uint32_t fvf; uint8_t offs[4]; std::vector<uint16_t> idx; };
struct Sector { uint32_t cs, flags; std::vector<Mesh> meshes; };

static bool ReadMaterial(Rd& r, std::unordered_map<uint32_t, Mat>& mats) {
    size_t o0 = r.o;
    uint32_t cs = r.get<uint32_t>(); r.get<uint32_t>();
    uint32_t np = r.get<uint32_t>(), cut = r.get<uint32_t>();
    if (!r.ok || np > 8) return false;
    r.get<uint8_t>(); r.get<float>(); r.get<uint8_t>();
    uint8_t two = r.get<uint8_t>();
    r.get<int32_t>();
    uint8_t grass = r.get<uint8_t>();
    if (grass) r.take(8);
    float spec = r.get<float>();
    if (spec > 0) r.take(12);
    Mat m; m.cut = cut; m.twosided = two != 0;
    for (uint32_t j = 0; j < np && r.ok; ++j) {
        size_t p0 = r.o;
        uint32_t tex = r.peek<uint32_t>(0), fl = r.peek<uint32_t>(4);
        if (j == 0) { m.tex = tex; m.blend = r.peek<uint32_t>(21); }
        r.take(49);
        if (fl & 1) r.take(32);
        if ((fl & 2) && j == 0) {
            uint32_t ns = r.get<uint32_t>();
            if (ns > 4096) return false;
            for (uint32_t q = 0; q < ns && r.ok; ++q) { uint32_t nk = r.peek<uint32_t>(); if (nk > 65536) return false; r.take(8 + 8 * (size_t)nk); }
        }
        if (fl & 0x800) { uint32_t nk = r.peek<uint32_t>(); if (nk > 65536) return false; r.take(16 + 8 * (size_t)nk); }
        r.take(16);
        (void)p0;
    }
    (void)o0;
    if (r.ok) mats[cs] = m;
    return r.ok;
}
static bool ReadMesh(Rd& r, Mesh* keep) {
    r.take(16 + 24);
    r.get<uint32_t>();
    uint32_t mat = r.get<uint32_t>();
    uint32_t nlod = r.get<uint32_t>();
    if (!r.ok || nlod > 16) return false;
    const uint8_t* lod0 = nullptr; uint32_t nlod0 = 0;
    for (uint32_t l = 0; l < nlod && r.ok; ++l) {
        uint32_t n = r.get<uint32_t>();
        if (n > 1000000) return false;
        if (l == 0) { lod0 = r.b + r.o; nlod0 = n; }
        r.take(2 * (size_t)n);
    }
    uint16_t n2 = r.get<uint16_t>();
    const uint8_t* strip = r.b + r.o;
    r.take(2 * (size_t)n2);
    r.take(14);
    uint8_t stride = r.get<uint8_t>();
    uint16_t nv = r.get<uint16_t>();
    uint8_t nbuf = r.get<uint8_t>();
    if (!r.ok || nbuf > 16) return false;
    const uint8_t* vb0 = nullptr; uint32_t vb0size = 0;
    for (uint8_t k = 0; k < nbuf && r.ok; ++k) {
        r.get<uint8_t>();
        uint32_t size = r.get<uint32_t>();
        if (size > 64 * 1024 * 1024) return false;
        if (k == 0) { vb0 = r.b + r.o; vb0size = size; }
        r.take(size);
    }
    uint32_t fvf = r.get<uint32_t>();
    r.get<int32_t>();
    uint8_t offs[4];
    for (int k = 0; k < 4; ++k) offs[k] = r.get<uint8_t>();
    if (offs[3]) r.take(nv);
    r.get<uint32_t>();
    uint32_t ps = r.get<uint32_t>();
    if (ps == 1) { r.get<uint32_t>(); uint32_t k = r.get<uint32_t>(); if (k > 16 * 1024 * 1024) return false; r.take(k); }
    if (!r.ok) return false;
    if (keep) {
        keep->mat = mat; keep->stride = stride; keep->nv = nv; keep->vb = vb0; keep->vbsize = vb0size; keep->fvf = fvf;
        memcpy(keep->offs, offs, 4);
        const uint8_t* ip = n2 ? strip : lod0;
        uint32_t ni = n2 ? n2 : nlod0;
        keep->idx.resize(ni);
        if (ni) memcpy(keep->idx.data(), ip, ni * 2);
    }
    return true;
}
// the wanted sectors (and every material) of a scene
static bool ReadScene(const std::string& scn, const std::vector<uint32_t>& want, std::unordered_map<uint32_t, Mat>& mats,
                      std::vector<Sector>& out) {
    Rd r{(const uint8_t*)scn.data(), scn.size(), 0};
    r.take(12);
    uint32_t nm = r.get<uint32_t>();
    if (!r.ok || nm > 100000) return false;
    for (uint32_t i = 0; i < nm; ++i) if (!ReadMaterial(r, mats)) return false;
    uint32_t ns = r.get<uint32_t>();
    if (!r.ok || ns > 200000) return false;
    out.assign(want.size(), Sector());
    size_t found = 0;
    for (uint32_t i = 0; i < ns && r.ok && found < want.size(); ++i) {
        uint32_t cs = r.get<uint32_t>(); r.get<int32_t>();
        uint32_t flags = r.get<uint32_t>(), nmesh = r.get<uint32_t>();
        r.take(24 + 16);
        if (flags & 0x00800000) r.take(40);
        if (!r.ok || nmesh > 4096) return false;
        int slot = -1;
        for (size_t w = 0; w < want.size(); ++w) if (want[w] == cs && out[w].meshes.empty()) { slot = (int)w; break; }
        for (uint32_t m = 0; m < nmesh; ++m) {
            Mesh mesh;
            if (!ReadMesh(r, slot >= 0 ? &mesh : nullptr)) return false;
            if (slot >= 0) out[slot].meshes.push_back(std::move(mesh));
        }
        if (slot >= 0) { out[slot].cs = cs; out[slot].flags = flags; ++found; }
    }
    return r.ok;
}
struct Tex { uint32_t w, h, dxt; std::vector<std::pair<const uint8_t*, uint32_t>> mips; const uint8_t* pal; uint32_t palSize; };
static bool ReadTextures(const std::string& t, std::unordered_map<uint32_t, Tex>& out) {
    Rd r{(const uint8_t*)t.data(), t.size(), 0};
    r.get<uint32_t>();
    uint32_t n = r.get<uint32_t>();
    if (!r.ok || n > 100000) return false;
    for (uint32_t i = 0; i < n && r.ok; ++i) {
        Tex x;
        uint32_t cs = r.get<uint32_t>();
        x.w = r.get<uint32_t>(); x.h = r.get<uint32_t>();
        uint32_t lv = r.get<uint32_t>(); r.get<uint32_t>(); r.get<uint32_t>();
        x.dxt = r.get<uint32_t>();
        x.palSize = r.get<uint32_t>();
        if (!r.ok || lv > 16 || x.palSize > 4096) return false;
        x.pal = r.b + r.o;
        r.take(x.palSize);
        for (uint32_t l = 0; l < lv && r.ok; ++l) {
            uint32_t sz = r.get<uint32_t>();
            if (sz > 64 * 1024 * 1024) return false;
            x.mips.push_back({r.b + r.o, sz});
            r.take(sz);
        }
        if (r.ok) out[cs] = x;
    }
    return r.ok;
}

// ---- model blob (lamp_cache.py model_parts + bulbs/aims, lampmodels.inc reads it)
static void Put(std::string& s, const void* p, size_t n) { s.append((const char*)p, n); }
template <class T> static void PutV(std::string& s, T v) { Put(s, &v, sizeof v); }
static bool BuildBlob(const Recipe& rc, std::string& blob) {
    if (!LoadSource(rc)) return false;
    std::unordered_map<uint32_t, Mat> mats;
    std::vector<Sector> secs;
    if (!ReadScene(g_scn, rc.sectors, mats, secs)) { mmenu::Log("lampsrc: %s: scene not readable", rc.key.c_str()); return false; }
    if (secs.empty() || secs[0].meshes.empty()) { mmenu::Log("lampsrc: %s: object %08x not in the level", rc.key.c_str(), rc.sectors[0]); return false; }
    std::unordered_map<uint32_t, Tex> texs;
    if (!ReadTextures(g_tex, texs)) mmenu::Log("lampsrc: %s: textures not readable (drawn untextured)", rc.key.c_str());
    std::string texBlob, partBlob;
    std::unordered_map<uint32_t, int> texIndex;
    uint32_t ntex = 0, nparts = 0;
    for (const auto& sec : secs) {
        bool bill = (sec.flags & 0x00800000) != 0;
        for (const auto& m : sec.meshes) {
            if (!m.vb || m.stride < 12 || (size_t)m.stride * m.nv > m.vbsize) continue;
            std::vector<uint16_t> tri;
            for (size_t t = 0; t + 2 < m.idx.size(); ++t) {
                uint16_t a = m.idx[t], b = m.idx[t + 1], c = m.idx[t + 2];
                if (t % 2) std::swap(a, b);
                if (a == b || b == c || a == c || a >= m.nv || b >= m.nv || c >= m.nv) continue;
                tri.push_back(a); tri.push_back(b); tri.push_back(c);
            }
            if (tri.empty()) continue;
            int ti = -1; uint32_t flags = 0, ref = 0;
            auto mi = mats.find(m.mat);
            if (mi != mats.end()) {
                const Mat& mt = mi->second;
                auto tt = texs.find(mt.tex);
                if (tt != texs.end()) {
                    auto ex = texIndex.find(mt.tex);
                    if (ex != texIndex.end()) ti = ex->second;
                    else {
                        const Tex& x = tt->second;
                        uint32_t fmt = 0;
                        bool argb = false, pal = false;
                        if (x.dxt == 1) fmt = MAKEFOURCC('D', 'X', 'T', '1');
                        else if (x.dxt == 2 || x.dxt == 3) fmt = MAKEFOURCC('D', 'X', 'T', '3');
                        else if (x.dxt == 5) fmt = MAKEFOURCC('D', 'X', 'T', '5');
                        else if (!x.mips.empty() && x.mips[0].second >= x.w * x.h * 4) { fmt = 21; argb = true; }
                        else if (x.palSize && !x.mips.empty() && x.mips[0].second >= x.w * x.h) { fmt = 21; pal = true; }
                        if (fmt && !x.mips.empty()) {
                            PutV(texBlob, x.w); PutV(texBlob, x.h); PutV(texBlob, fmt); PutV(texBlob, (uint32_t)x.mips.size());
                            for (size_t l = 0; l < x.mips.size(); ++l) {
                                if (pal) {
                                    uint32_t mw = x.w >> l ? x.w >> l : 1, mh = x.h >> l ? x.h >> l : 1, cnt = mw * mh;
                                    if (cnt > x.mips[l].second) cnt = x.mips[l].second;
                                    PutV(texBlob, cnt * 4);
                                    for (uint32_t q = 0; q < cnt; ++q) {
                                        uint32_t pi = x.mips[l].first[q] * 4u;
                                        uint8_t px[4] = {0, 0, 0, 0};
                                        if (pi + 4 <= x.palSize) memcpy(px, x.pal + pi, 4);
                                        Put(texBlob, px, 4);
                                    }
                                } else {
                                    PutV(texBlob, x.mips[l].second);
                                    Put(texBlob, x.mips[l].first, x.mips[l].second);
                                }
                            }
                            (void)argb;
                            ti = (int)ntex++;
                            texIndex[mt.tex] = ti;
                        }
                    }
                }
                if (mt.cut) { flags |= 1; ref = mt.cut < 255 ? mt.cut : 255; }
                if (mt.blend == 1 || mt.blend == 2) flags |= 4;
                else if (mt.blend != 0) flags |= 2;
                if (mt.twosided) flags |= 8;
            }
            // vertices: position from the base, grey shading at the game's scale, doubled alpha, uv
            uint8_t co = (m.fvf & 0x40) ? m.offs[1] : 0xFF, uo = (m.fvf & 0xF00) ? m.offs[2] : 0xFF;
            std::vector<float> pos(m.nv * 3), uv(m.nv * 2, 0.0f);
            std::vector<uint8_t> col(m.nv * 4, 128);
            for (uint32_t k = 0; k < m.nv; ++k) {
                const uint8_t* v = m.vb + (size_t)k * m.stride;
                memcpy(&pos[k * 3], v, 12);
                if (co != 0xFF && co + 4u <= m.stride) memcpy(&col[k * 4], v + co, 4);
                if (uo != 0xFF && uo + 8u <= m.stride) memcpy(&uv[k * 2], v + uo, 8);
            }
            uint32_t nv = m.nv;
            if (bill) {  // camera-facing globe: a second copy turned 90 degrees, both sides drawn
                float cx = 0, cz = 0;
                for (uint32_t k = 0; k < nv; ++k) { cx += pos[k * 3]; cz += pos[k * 3 + 2]; }
                cx /= nv; cz /= nv;
                for (uint32_t k = 0; k < nv; ++k) {
                    float x = pos[k * 3], y = pos[k * 3 + 1], z = pos[k * 3 + 2];
                    pos.push_back(cx - (z - cz)); pos.push_back(y); pos.push_back(cz + (x - cx));
                    uv.push_back(uv[k * 2]); uv.push_back(uv[k * 2 + 1]);
                    for (int q = 0; q < 4; ++q) col.push_back(col[k * 4 + q]);
                }
                size_t nt = tri.size();
                for (size_t q = 0; q < nt; ++q) tri.push_back((uint16_t)(tri[q] + nv));
                nv *= 2;
                flags |= 8 | 16;
            }
            if (nv > 65535) continue;
            PutV(partBlob, (int32_t)ti); PutV(partBlob, flags); PutV(partBlob, ref); PutV(partBlob, nv); PutV(partBlob, (uint32_t)tri.size());
            for (uint32_t k = 0; k < nv; ++k) {
                float p[3] = {pos[k * 3] - rc.base[0], pos[k * 3 + 1] - rc.base[1], pos[k * 3 + 2] - rc.base[2]};
                Put(partBlob, p, 12);
                const uint8_t* c = &col[k * 4];  // B G R A
                int lum = (int)(0.3f * c[2] + 0.59f * c[1] + 0.11f * c[0]);
                lum = lum < 40 ? 40 : lum > 128 ? 128 : lum;
                uint8_t o[4] = {(uint8_t)lum, (uint8_t)lum, (uint8_t)lum, (uint8_t)(c[3] * 2 > 255 ? 255 : c[3] * 2)};
                Put(partBlob, o, 4);
                Put(partBlob, &uv[k * 2], 8);
            }
            Put(partBlob, tri.data(), tri.size() * 2);
            ++nparts;
        }
    }
    if (!nparts) { mmenu::Log("lampsrc: %s: no drawable parts", rc.key.c_str()); return false; }
    blob.clear();
    PutV(blob, ntex); PutV(blob, nparts);
    blob += texBlob; blob += partBlob;
    uint32_t nb = (uint32_t)(rc.bulbs.size() / 3);
    PutV(blob, nb);
    Put(blob, rc.bulbs.data(), rc.bulbs.size() * 4);
    Put(blob, rc.aims.data(), rc.aims.size() * 4);
    return true;
}

// ---- cache: dadmod\lampcache\<key>.bin = "LMC1" + recipe hash + blob
static uint32_t RecipeHash(const Recipe& r) {
    uint32_t h = 2166136261u;
    auto mix = [&](const void* p, size_t n) { for (size_t i = 0; i < n; ++i) { h ^= ((const uint8_t*)p)[i]; h *= 16777619u; } };
    mix(r.key.data(), r.key.size()); mix(r.level.data(), r.level.size());
    mix(r.sectors.data(), r.sectors.size() * 4); mix(r.base, 12);
    mix(r.bulbs.data(), r.bulbs.size() * 4); mix(r.aims.data(), r.aims.size() * 4);
    uint32_t ver = 1; mix(&ver, 4);
    return h;
}
static std::string CachePath(const Recipe& r) {
    std::string k = r.key;
    for (auto& c : k) if (c == ':' || c == '\\' || c == '/') c = '_';
    return ExeDirFile(("lampcache\\" + k + ".bin").c_str());
}
static bool GetBlob(const Recipe& r, std::string& blob) {
    std::string path = CachePath(r), data;
    uint32_t h = RecipeHash(r);
    if (ReadFileBytes(path, data) && data.size() > 8 && !memcmp(data.data(), "LMC1", 4) && *(const uint32_t*)(data.data() + 4) == h) {
        blob.assign(data, 8, std::string::npos);
        return true;
    }
    DWORD t0 = GetTickCount();
    if (!BuildBlob(r, blob)) return false;
    std::string dir = ExeDirFile("lampcache");
    CreateDirectoryA(dir.c_str(), nullptr);
    std::string out = "LMC1";
    out.append((const char*)&h, 4);
    out += blob;
    WriteWholeFile(path, out);
    mmenu::Log("lampsrc: built %s (%s) from the %s files in %lu ms", r.key.c_str(), r.title.c_str(), r.src == "thug2" ? "THUG2" : "THUG Pro",
               (unsigned long)(GetTickCount() - t0));
    return true;
}
static void Forget() { g_srcKey.clear(); g_scn.clear(); g_scn.shrink_to_fit(); g_tex.clear(); g_tex.shrink_to_fit(); }  // after a level's posts are built

}  // namespace lampsrc
