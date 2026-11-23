// lampmodels (Noah 2026-11-23): real lamp post models from the THUG2 / THUG Pro levels, drawn with our own D3D code.
// Player build: the posts a map's lamp list names (lamps_<level>.q model entries, THUGRECOMP_LampPost), built on the
// player's PC from the player's own game files (lampsrc.inc: dadmod\lamprecipes.txt + dadmod\lampcache). Shipped
// posts are merged per model into one world-space buffer per part when a map loads (one draw per model part per
// map). Dev build also: the Lamp Editor's placed lamps, its cursor lamp (cyan tint + dark footprint) and the spinning
// preview. Only models the current map (or the editor) uses get textures / buffers (managed pool, they live through
// a device reset); everything is let go on a level change. gfx.inc calls in through g_lmScene (end of the 3D scene,
// before the night tint), g_lmFrameEnd (after the HUD) and g_lmFree (device reset).
namespace lampmdl {

struct Rec { std::string key, title; int group, num; float bulb[3], height, rad; std::vector<float> bulbs, aims;
             int blobState = 0; std::string blob; };  // bulbs / aims: x y z per bulb (aim 0 = straight down); blob: lampsrc
static std::vector<Rec> g_rec;
static std::vector<std::string> g_groups;
static int g_loadState = 0;  // 0 not tried, 1 loaded, -1 none

static bool Loaded() {
    if (g_loadState) return g_loadState > 0;
    g_loadState = -1;
    if (!lampsrc::ReadRecipes()) return false;
    g_groups = lampsrc::g_groups;
    for (const auto& rc : lampsrc::g_recipes) {
        Rec r;
        r.key = rc.key; r.title = rc.title; r.group = lampsrc::GroupOf(rc); r.num = rc.num;
        r.height = rc.height; r.rad = rc.rad; r.bulbs = rc.bulbs; r.aims = rc.aims;
        for (int k = 0; k < 3; ++k) r.bulb[k] = rc.bulbs[k];
        g_rec.push_back(r);
    }
    g_loadState = g_rec.empty() ? -1 : 1;
    return g_loadState > 0;
}
static int Find(const std::string& key) {
    if (!Loaded()) return -1;
    for (size_t i = 0; i < g_rec.size(); ++i) if (!_stricmp(g_rec[i].key.c_str(), key.c_str())) return (int)i;
    return -1;
}
static int Count() { return Loaded() ? (int)g_rec.size() : 0; }
// the model's data (built from the player's files the first time, then from dadmod\lampcache); false = can't be had
static bool Blob(int i) {
    if (i < 0 || i >= (int)g_rec.size()) return false;
    Rec& r = g_rec[i];
    if (!r.blobState) r.blobState = lampsrc::GetBlob(lampsrc::g_recipes[i], r.blob) ? 1 : -1;
    return r.blobState > 0;
}

// ---- GPU copies (made the first time a model is drawn); parts keep a CPU copy for the per-map merged buffers
struct Part { IDirect3DVertexBuffer9* vb; IDirect3DIndexBuffer9* ib; int tex; DWORD flags, ref; UINT nv, ni; std::string verts, idx; };
struct Gpu { bool tried = false, ok = false; std::vector<IDirect3DTexture9*> tex; std::vector<Part> parts; };
static std::vector<Gpu> g_gpu;
static IDirect3DDevice9* g_gpuDev = nullptr;
static const DWORD kFVF = D3DFVF_XYZ | D3DFVF_DIFFUSE | D3DFVF_TEX1;

// per-map merged posts: one buffer pair per (model, part, chunk of up to 60000 vertices)
struct Batch { int model, part; IDirect3DVertexBuffer9* vb; IDirect3DIndexBuffer9* ib; UINT nv, ni; };
static std::vector<Batch> g_batch;
static bool g_batchDirty = true;
static void FreeBatches() {
    for (auto& b : g_batch) { if (b.vb) b.vb->Release(); if (b.ib) b.ib->Release(); }
    g_batch.clear();
    g_batchDirty = true;
}
static void FreeGpu() {
    FreeBatches();
    for (auto& g : g_gpu) {
        for (auto* t : g.tex) if (t) t->Release();
        for (auto& p : g.parts) { if (p.vb) p.vb->Release(); if (p.ib) p.ib->Release(); }
        g.tex.clear(); g.parts.clear(); g.tried = g.ok = false;
    }
}
static bool Ensure(IDirect3DDevice9* dev, int i) {
    if (i < 0 || i >= (int)g_rec.size()) return false;
    if (g_gpuDev != dev) { FreeGpu(); g_gpuDev = dev; }
    if ((int)g_gpu.size() < (int)g_rec.size()) g_gpu.resize(g_rec.size());
    Gpu& g = g_gpu[i];
    if (g.tried) return g.ok;
    g.tried = true;
    if (!Blob(i)) return false;
    const Rec& r = g_rec[i];
    const char* b = r.blob.data();
    const char* e = b + r.blob.size();
    auto rd = [&](void* dst, size_t n) { if (b + n > e) return false; memcpy(dst, b, n); b += n; return true; };
    uint32_t nt, np;
    if (!rd(&nt, 4) || !rd(&np, 4) || nt > 64 || np > 256) return false;
    for (uint32_t t = 0; t < nt; ++t) {
        uint32_t w, h, fmt, nmip;
        if (!rd(&w, 4) || !rd(&h, 4) || !rd(&fmt, 4) || !rd(&nmip, 4) || nmip > 16 || !w || !h || w > 4096 || h > 4096) return false;
        IDirect3DTexture9* tx = nullptr;
        if (FAILED(dev->CreateTexture(w, h, nmip, 0, (D3DFORMAT)fmt, D3DPOOL_MANAGED, &tx, nullptr))) tx = nullptr;
        bool dxt = fmt != 21;
        UINT blk = fmt == MAKEFOURCC('D', 'X', 'T', '1') ? 8 : 16;
        for (uint32_t m = 0; m < nmip; ++m) {
            uint32_t sz;
            if (!rd(&sz, 4) || b + sz > e) { if (tx) tx->Release(); return false; }
            UINT mw = w >> m ? w >> m : 1, mh = h >> m ? h >> m : 1;
            UINT rows = dxt ? (mh + 3) / 4 : mh, rowb = dxt ? ((mw + 3) / 4) * blk : mw * 4;
            D3DLOCKED_RECT lr;
            if (tx && rows * rowb <= sz && SUCCEEDED(tx->LockRect(m, &lr, nullptr, 0))) {
                for (UINT y = 0; y < rows; ++y) memcpy((char*)lr.pBits + y * lr.Pitch, b + y * rowb, rowb);
                tx->UnlockRect(m);
            }
            b += sz;
        }
        g.tex.push_back(tx);
    }
    for (uint32_t p = 0; p < np; ++p) {
        int32_t ti; uint32_t fl, ref, nv, ni;
        if (!rd(&ti, 4) || !rd(&fl, 4) || !rd(&ref, 4) || !rd(&nv, 4) || !rd(&ni, 4) || !nv || nv > 65535) return false;
        if (b + nv * 24 + ni * 2 > e) return false;
        Part pt = {nullptr, nullptr, ti, fl, ref, nv, ni, std::string(b, nv * 24), std::string(b + nv * 24, ni * 2)};
        void* dst = nullptr;
        if (SUCCEEDED(dev->CreateVertexBuffer(nv * 24, D3DUSAGE_WRITEONLY, kFVF, D3DPOOL_MANAGED, &pt.vb, nullptr)) &&
            SUCCEEDED(pt.vb->Lock(0, 0, &dst, 0))) { memcpy(dst, b, nv * 24); pt.vb->Unlock(); }
        b += nv * 24;
        if (ni && SUCCEEDED(dev->CreateIndexBuffer(ni * 2, D3DUSAGE_WRITEONLY, D3DFMT_INDEX16, D3DPOOL_MANAGED, &pt.ib, nullptr)) &&
            SUCCEEDED(pt.ib->Lock(0, 0, &dst, 0))) { memcpy(dst, b, ni * 2); pt.ib->Unlock(); }
        b += ni * 2;
        if (pt.vb && pt.ib) g.parts.push_back(pt);
        else { if (pt.vb) pt.vb->Release(); if (pt.ib) pt.ib->Release(); }
    }
    g.ok = !g.parts.empty();
    mmenu::Log("lampmodels: loaded %s (%d parts, %d textures)%s", r.title.c_str(), (int)g.parts.size(), (int)g.tex.size(), g.ok ? "" : " FAILED");
    return g.ok;
}

// ---- what to draw: g_ship = the map's lamp posts (lamplights.q -> THUGRECOMP_LampPost); dev build: g_inst = the
// editor's placed lamps, g_cur = its cursor lamp, the preview box
struct Inst { int model; float x, y, z, rot; };
static std::vector<Inst> g_inst;
static std::vector<Inst> g_ship;
struct Cursor { bool on; int model; float x, y, z, rot, ground; };  // y = the lamp's base (ground + raise)
static Cursor g_cur = {false, -1, 0, 0, 0, 0, 0};
static bool g_prevOn = false;
static float g_prevBox[4] = {0, 0, 0, 0};  // the editor's preview box in 640x480 menu units

static void AddPost(int model, float x, float y, float z, float rot) { g_ship.push_back({model, x, y, z, rot}); g_batchDirty = true; }
static void ClearPosts() { g_ship.clear(); FreeBatches(); }
// level change: the last map's posts and every model's GPU copy go (the next map loads only what it names)
static void LevelReset() {
    ClearPosts();
    FreeGpu();
    for (auto& r : g_rec) { r.blob.clear(); r.blob.shrink_to_fit(); if (r.blobState > 0) r.blobState = 0; }
    lampsrc::Forget();
}

// local -> world: turned by rot degrees around Y, then moved (the same turn lampeditor.inc uses for the bulb)
static void TurnXZ(float rot, float lx, float lz, float& wx, float& wz) {
    float a = rot * 3.14159265f / 180.0f, c = cosf(a), s = sinf(a);
    wx = lx * c + lz * s; wz = -lx * s + lz * c;
}
static D3DMATRIX World(float x, float y, float z, float rot) {
    float a = rot * 3.14159265f / 180.0f, c = cosf(a), s = sinf(a);
    D3DMATRIX m = {};
    m._11 = c; m._13 = -s; m._22 = 1; m._31 = s; m._33 = c; m._41 = x; m._42 = y; m._43 = z; m._44 = 1;
    return m;
}
static IDirect3DStateBlock9* g_save = nullptr;
static void Free() { if (g_save) { g_save->Release(); g_save = nullptr; } }  // device reset (models are managed)

static void CommonStates(IDirect3DDevice9* dev) {
    auto rs = [&](D3DRENDERSTATETYPE k, DWORD v) { gfx::g_origRS(dev, k, v); };
    dev->SetVertexShader(nullptr); dev->SetPixelShader(nullptr);
    dev->SetFVF(kFVF);
    rs(D3DRS_ZENABLE, D3DZB_TRUE); rs(D3DRS_ZWRITEENABLE, TRUE); rs(D3DRS_ZFUNC, D3DCMP_LESSEQUAL);
    rs(D3DRS_LIGHTING, FALSE); rs(D3DRS_FOGENABLE, FALSE); rs(D3DRS_SPECULARENABLE, FALSE); rs(D3DRS_STENCILENABLE, FALSE);
    rs(D3DRS_COLORWRITEENABLE, 0xF); rs(D3DRS_ALPHABLENDENABLE, FALSE); rs(D3DRS_ALPHATESTENABLE, FALSE);
    rs(D3DRS_SEPARATEALPHABLENDENABLE, FALSE); rs(D3DRS_BLENDOP, D3DBLENDOP_ADD); rs(D3DRS_SCISSORTESTENABLE, FALSE);
    rs(D3DRS_CULLMODE, D3DCULL_NONE); rs(D3DRS_FILLMODE, D3DFILL_SOLID); rs(D3DRS_SHADEMODE, D3DSHADE_GOURAUD);
    rs(D3DRS_CLIPPING, TRUE); rs(D3DRS_VERTEXBLEND, D3DVBF_DISABLE); rs(D3DRS_INDEXEDVERTEXBLENDENABLE, FALSE);
    rs(D3DRS_DEPTHBIAS, 0); rs(D3DRS_SLOPESCALEDEPTHBIAS, 0);
    dev->SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE2X);
    dev->SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TEXTURE); dev->SetTextureStageState(0, D3DTSS_COLORARG2, D3DTA_DIFFUSE);
    dev->SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
    dev->SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE); dev->SetTextureStageState(0, D3DTSS_ALPHAARG2, D3DTA_DIFFUSE);
    dev->SetTextureStageState(0, D3DTSS_TEXCOORDINDEX, 0); dev->SetTextureStageState(0, D3DTSS_TEXTURETRANSFORMFLAGS, D3DTTFF_DISABLE);
    dev->SetTextureStageState(1, D3DTSS_COLOROP, D3DTOP_DISABLE); dev->SetTextureStageState(1, D3DTSS_ALPHAOP, D3DTOP_DISABLE);
    for (int s = 1; s < 4; ++s) dev->SetTexture(s, nullptr);
    dev->SetSamplerState(0, D3DSAMP_MINFILTER, D3DTEXF_LINEAR); dev->SetSamplerState(0, D3DSAMP_MAGFILTER, D3DTEXF_LINEAR);
    dev->SetSamplerState(0, D3DSAMP_MIPFILTER, D3DTEXF_LINEAR);
    dev->SetSamplerState(0, D3DSAMP_ADDRESSU, D3DTADDRESS_WRAP); dev->SetSamplerState(0, D3DSAMP_ADDRESSV, D3DTADDRESS_WRAP);
}
// tint = 0: as the level draws it; else an extra additive pass in that colour (the editor's cursor lamp)
static void DrawModel(IDirect3DDevice9* dev, int i, const D3DMATRIX& w, DWORD tint, bool zwrite = true) {
    if (!Ensure(dev, i)) return;
    auto rs = [&](D3DRENDERSTATETYPE k, DWORD v) { gfx::g_origRS(dev, k, v); };
    gfx::g_origST(dev, D3DTS_WORLD, &w);
    const Gpu& g = g_gpu[i];
    // tint (the editor's cursor lamp, 2026-11-23): the lamp as the level draws it, coloured and see-through by the
    // texture factor (rgb = colour, a = opacity) in stage 1, depth tested, writing no depth
    if (tint) {
        rs(D3DRS_TEXTUREFACTOR, tint);
        dev->SetTextureStageState(1, D3DTSS_COLOROP, D3DTOP_MODULATE);
        dev->SetTextureStageState(1, D3DTSS_COLORARG1, D3DTA_CURRENT); dev->SetTextureStageState(1, D3DTSS_COLORARG2, D3DTA_TFACTOR);
        dev->SetTextureStageState(1, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
        dev->SetTextureStageState(1, D3DTSS_ALPHAARG1, D3DTA_CURRENT); dev->SetTextureStageState(1, D3DTSS_ALPHAARG2, D3DTA_TFACTOR);
        dev->SetTextureStageState(2, D3DTSS_COLOROP, D3DTOP_DISABLE); dev->SetTextureStageState(2, D3DTSS_ALPHAOP, D3DTOP_DISABLE);
    }
    for (int pass = 0; pass < 1; ++pass) {
        for (const auto& p : g.parts) {
            if ((p.flags & 16) && !gfx::g_bulbNight && !tint) continue;  // glow sprites (globe lights) only at night
            dev->SetTexture(0, p.tex >= 0 && p.tex < (int)g.tex.size() ? g.tex[p.tex] : nullptr);
            dev->SetTextureStageState(0, D3DTSS_COLOROP, p.tex >= 0 ? D3DTOP_MODULATE2X : D3DTOP_SELECTARG2);
            rs(D3DRS_ALPHATESTENABLE, (p.flags & 1) ? TRUE : FALSE);
            rs(D3DRS_ALPHAREF, p.ref ? p.ref : 1); rs(D3DRS_ALPHAFUNC, D3DCMP_GREATEREQUAL);
            bool blend = (p.flags & 6) != 0 || tint;
            rs(D3DRS_ALPHABLENDENABLE, blend ? TRUE : FALSE);
            if (p.flags & 4) { rs(D3DRS_SRCBLEND, D3DBLEND_SRCALPHA); rs(D3DRS_DESTBLEND, D3DBLEND_ONE); }
            else { rs(D3DRS_SRCBLEND, D3DBLEND_SRCALPHA); rs(D3DRS_DESTBLEND, D3DBLEND_INVSRCALPHA); }
            rs(D3DRS_ZWRITEENABLE, blend || !zwrite ? FALSE : TRUE);
            dev->SetStreamSource(0, p.vb, 0, 24);
            dev->SetIndices(p.ib);
            gfx::g_origDIP(dev, D3DPT_TRIANGLELIST, 0, 0, p.nv, 0, p.ni / 3);
        }
    }
    dev->SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TEXTURE);
    if (tint) { dev->SetTextureStageState(1, D3DTSS_COLOROP, D3DTOP_DISABLE); dev->SetTextureStageState(1, D3DTSS_ALPHAOP, D3DTOP_DISABLE); }
}
static void DrawFootprint(IDirect3DDevice9* dev, const Cursor& c) {  // dark square on the ground under the cursor lamp
    float r = 40;
    if (c.model >= 0 && c.model < (int)g_rec.size()) r = g_rec[c.model].rad * 1.6f + 20;
    if (r > 160) r = 160;
    struct V { float x, y, z; DWORD c; float u, v; } q[4];
    const float lx[4] = {-r, r, r, -r}, lz[4] = {-r, -r, r, r};
    for (int k = 0; k < 4; ++k) { q[k].x = lx[k]; q[k].y = 0.5f; q[k].z = lz[k]; q[k].c = 0x70000000; q[k].u = q[k].v = 0; }
    D3DMATRIX w = World(c.x, c.ground, c.z, c.rot);  // on the ground, also when the lamp is raised or lowered
    gfx::g_origST(dev, D3DTS_WORLD, &w);
    auto rs = [&](D3DRENDERSTATETYPE k, DWORD v) { gfx::g_origRS(dev, k, v); };
    dev->SetTexture(0, nullptr);
    dev->SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_SELECTARG2); dev->SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_SELECTARG2);
    rs(D3DRS_ALPHATESTENABLE, FALSE); rs(D3DRS_ALPHABLENDENABLE, TRUE);
    rs(D3DRS_SRCBLEND, D3DBLEND_SRCALPHA); rs(D3DRS_DESTBLEND, D3DBLEND_INVSRCALPHA); rs(D3DRS_ZWRITEENABLE, FALSE);
    rs(D3DRS_DEPTHBIAS, 0xB8D1B717);  // -0.0001f: stays on top of the ground it lies on
    gfx::g_origDPUP(dev, D3DPT_TRIANGLEFAN, 2, q, sizeof(V));
    rs(D3DRS_DEPTHBIAS, 0);
    dev->SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
}

// the map's posts merged per model part into world-space buffers (built on the first frame after the posts change)
static void BuildBatches(IDirect3DDevice9* dev) {
    FreeBatches();
    g_batchDirty = false;
    if (g_ship.empty()) return;
    DWORD t0 = GetTickCount();
    std::vector<int> models;
    for (const auto& in : g_ship) if (std::find(models.begin(), models.end(), in.model) == models.end()) models.push_back(in.model);
    int posts = 0;
    for (int mi : models) {
        if (!Ensure(dev, mi)) continue;
        std::vector<const Inst*> mine;
        for (const auto& in : g_ship) if (in.model == mi) mine.push_back(&in);
        posts += (int)mine.size();
        const Gpu& g = g_gpu[mi];
        for (int pi = 0; pi < (int)g.parts.size(); ++pi) {
            const Part& pt = g.parts[pi];
            UINT per = pt.nv ? 60000 / pt.nv : 0;
            if (!per || !pt.ni) continue;
            for (size_t s0 = 0; s0 < mine.size(); s0 += per) {
                size_t cnt = mine.size() - s0 < per ? mine.size() - s0 : per;
                Batch bt = {mi, pi, nullptr, nullptr, (UINT)(pt.nv * cnt), (UINT)(pt.ni * cnt)};
                if (FAILED(dev->CreateVertexBuffer(bt.nv * 24, D3DUSAGE_WRITEONLY, kFVF, D3DPOOL_MANAGED, &bt.vb, nullptr)) ||
                    FAILED(dev->CreateIndexBuffer(bt.ni * 2, D3DUSAGE_WRITEONLY, D3DFMT_INDEX16, D3DPOOL_MANAGED, &bt.ib, nullptr))) {
                    if (bt.vb) bt.vb->Release();
                    continue;
                }
                char* vd = nullptr; uint16_t* id = nullptr;
                if (SUCCEEDED(bt.vb->Lock(0, 0, (void**)&vd, 0))) {
                    for (size_t k = 0; k < cnt; ++k) {
                        const Inst& in = *mine[s0 + k];
                        float a = in.rot * 3.14159265f / 180.0f, c = cosf(a), sn = sinf(a);
                        char* dst = vd + k * pt.nv * 24;
                        memcpy(dst, pt.verts.data(), pt.nv * 24);
                        for (UINT v = 0; v < pt.nv; ++v) {
                            float* f = (float*)(dst + v * 24);
                            float lx = f[0], lz = f[2];
                            f[0] = lx * c + lz * sn + in.x; f[1] += in.y; f[2] = -lx * sn + lz * c + in.z;
                        }
                    }
                    bt.vb->Unlock();
                }
                if (SUCCEEDED(bt.ib->Lock(0, 0, (void**)&id, 0))) {
                    const uint16_t* src = (const uint16_t*)pt.idx.data();
                    for (size_t k = 0; k < cnt; ++k)
                        for (UINT j = 0; j < pt.ni; ++j) id[k * pt.ni + j] = (uint16_t)(src[j] + k * pt.nv);
                    bt.ib->Unlock();
                }
                g_batch.push_back(bt);
            }
        }
    }
    lampsrc::Forget();
    mmenu::Log("lampmodels: %d posts, %d models, %d draws (%lu ms)", posts, (int)models.size(), (int)g_batch.size(), GetTickCount() - t0);
}
static void DrawBatches(IDirect3DDevice9* dev) {
    auto rs = [&](D3DRENDERSTATETYPE k, DWORD v) { gfx::g_origRS(dev, k, v); };
    D3DMATRIX id = {};
    id._11 = id._22 = id._33 = id._44 = 1;
    gfx::g_origST(dev, D3DTS_WORLD, &id);
    for (const auto& bt : g_batch) {
        const Gpu& g = g_gpu[bt.model];
        if (bt.part >= (int)g.parts.size()) continue;
        const Part& p = g.parts[bt.part];
        if ((p.flags & 16) && !gfx::g_bulbNight) continue;
        dev->SetTexture(0, p.tex >= 0 && p.tex < (int)g.tex.size() ? g.tex[p.tex] : nullptr);
        dev->SetTextureStageState(0, D3DTSS_COLOROP, p.tex >= 0 ? D3DTOP_MODULATE2X : D3DTOP_SELECTARG2);
        rs(D3DRS_ALPHATESTENABLE, (p.flags & 1) ? TRUE : FALSE);
        rs(D3DRS_ALPHAREF, p.ref ? p.ref : 1); rs(D3DRS_ALPHAFUNC, D3DCMP_GREATEREQUAL);
        bool blend = (p.flags & 6) != 0;
        rs(D3DRS_ALPHABLENDENABLE, blend ? TRUE : FALSE);
        rs(D3DRS_SRCBLEND, D3DBLEND_SRCALPHA); rs(D3DRS_DESTBLEND, (p.flags & 4) ? D3DBLEND_ONE : D3DBLEND_INVSRCALPHA);
        rs(D3DRS_ZWRITEENABLE, blend ? FALSE : TRUE);
        dev->SetStreamSource(0, bt.vb, 0, 24);
        dev->SetIndices(bt.ib);
        gfx::g_origDIP(dev, D3DPT_TRIANGLELIST, 0, 0, bt.nv, 0, bt.ni / 3);
    }
}

// end of the 3D scene: placed lamps near the camera, then the cursor lamp with its footprint
static void Scene(IDirect3DDevice9* dev) {
    if ((g_inst.empty() && g_ship.empty() && !g_cur.on) || !Loaded() || !gfx::g_haveProj || gfx::MirrorOn()) return;
    if (!g_save && FAILED(dev->CreateStateBlock(D3DSBT_ALL, &g_save))) { g_save = nullptr; return; }
    g_save->Capture();
    CommonStates(dev);
    gfx::g_origST(dev, D3DTS_VIEW, &gfx::g_view);
    gfx::g_origST(dev, D3DTS_PROJECTION, &gfx::g_proj);
    const D3DMATRIX& m = gfx::g_view;
    float cx = -(m._41 * m._11 + m._42 * m._12 + m._43 * m._13), cz = -(m._41 * m._31 + m._42 * m._32 + m._43 * m._33);
    int drawn = 0;
    bool postsOn = gfx::V("gfx_lampposts") != 0;  // Extra lamp posts: Hide (the cursor lamp still shows)
    if (g_gpuDev != dev) g_batchDirty = true;
    if (g_batchDirty) BuildBatches(dev);
    if (postsOn) DrawBatches(dev);
    for (const auto& in : g_inst) {
        if (!postsOn) break;
        float dx = in.x - cx, dz = in.z - cz;
        if (dx * dx + dz * dz > 15000.0f * 15000.0f || ++drawn > 300) continue;
        DrawModel(dev, in.model, World(in.x, in.y, in.z, in.rot), 0);
    }
    if (g_cur.on && g_cur.model >= 0) {
        DrawFootprint(dev, g_cur);
        CommonStates(dev);
        DrawModel(dev, g_cur.model, World(g_cur.x, g_cur.y, g_cur.z, g_cur.rot), 0xC0A8E8FF, false);  // light cyan, 75 % opaque  // no depth: the cursor probe must see the ground, not this lamp
    }
    g_save->Apply();
}

// after the HUD: the cursor lamp small and turning inside the editor's preview box
static void FrameEnd(IDirect3DDevice9* dev) {
    if (!g_prevOn || !g_cur.on || g_cur.model < 0 || !Loaded() || g_cur.model >= (int)g_rec.size()) return;
    mmenu::MenuSpace ms = mmenu::GetMenuSpace();
    if (!ms.ok) return;
    D3DVIEWPORT9 vp;
    vp.X = (DWORD)(g_prevBox[0] * ms.xs + ms.xo); vp.Y = (DWORD)(g_prevBox[1] * ms.ys + ms.yo);
    vp.Width = (DWORD)(g_prevBox[2] * ms.xs); vp.Height = (DWORD)(g_prevBox[3] * ms.ys);
    vp.MinZ = 0; vp.MaxZ = 1;
    if (vp.Width < 8 || vp.Height < 8 || (int)(vp.X + vp.Width) > ms.w || (int)(vp.Y + vp.Height) > ms.h) return;
    if (FAILED(dev->BeginScene())) return;
    if (!g_save && FAILED(dev->CreateStateBlock(D3DSBT_ALL, &g_save))) { g_save = nullptr; dev->EndScene(); return; }
    g_save->Capture();
    IDirect3DSurface9* ds = nullptr;
    bool haveZ = SUCCEEDED(dev->GetDepthStencilSurface(&ds)) && ds;
    if (ds) ds->Release();
    dev->SetViewport(&vp);
    if (haveZ) dev->Clear(0, nullptr, D3DCLEAR_ZBUFFER, 0, 1.0f, 0);
    CommonStates(dev);
    if (!haveZ) gfx::g_origRS(dev, D3DRS_ZENABLE, D3DZB_FALSE);
    const Rec& r = g_rec[g_cur.model];
    float h = r.height > 10 ? r.height : 100, reach = r.rad;
    for (int k = 0; k < 3; ++k) if (fabsf(r.bulb[k]) > reach && k != 1) reach = fabsf(r.bulb[k]);
    float size = h > reach * 2 ? h : reach * 2;
    float dist = size * 1.9f + 30;
    float cy = h * 0.5f;
    // view: from (0, cy + dist * 0.15, -dist) looking at (0, cy, 0)
    float ey = cy + dist * 0.15f, ez = -dist;
    float fx = 0, fy = cy - ey, fz = -ez, fl = sqrtf(fy * fy + fz * fz);
    fy /= fl; fz /= fl;
    D3DMATRIX v = {};  // left-handed look-at: right (1,0,0), up = forward x right
    float ux = 0, uy = fz, uz = -fy;
    v._11 = 1; v._12 = ux; v._13 = fx;
    v._21 = 0; v._22 = uy; v._23 = fy;
    v._31 = 0; v._32 = uz; v._33 = fz;
    v._41 = 0; v._42 = -(ey * uy + ez * uz); v._43 = -(ey * fy + ez * fz); v._44 = 1;
    float aspect = (float)vp.Width / (float)vp.Height, fov = 0.70f, yscale = 1.0f / tanf(fov / 2), zn = 5, zf = dist * 4 + 2000;
    D3DMATRIX p = {};
    p._11 = yscale / aspect; p._22 = yscale; p._33 = zf / (zf - zn); p._34 = 1; p._43 = -zn * zf / (zf - zn);
    gfx::g_origST(dev, D3DTS_VIEW, &v);
    gfx::g_origST(dev, D3DTS_PROJECTION, &p);
    float spin = (float)fmod(GetTickCount64() / 1000.0 * 40.0, 360.0);
    D3DMATRIX w = World(0, 0, 0, spin);
    w._31 = -w._31; w._32 = -w._32; w._33 = -w._33;  // the game's view is right-handed: this keeps the model unmirrored
    DrawModel(dev, g_cur.model, w, 0);
    g_save->Apply();
    dev->EndScene();
}

struct Hook { Hook() { gfx::g_lmScene = &Scene; gfx::g_lmFrameEnd = &FrameEnd; gfx::g_lmFree = &Free; } };
static Hook g_hook;

}  // namespace lampmdl
