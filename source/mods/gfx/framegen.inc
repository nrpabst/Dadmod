// Frame generation (Noah 2026-11-21: "can we build frame generation into thugpro", "make sure it plays nice with all
// graphics cards", "it should work with up to 240hz"). Included by gfx.inc (inside namespace gfx), after RunScreen.
//
// Why it is needed: the main loop (0x44EEF0) is a fixed 60 ticks a second (it busy-waits on the performance counter
// for freq/60, with Sleep(0)), physics and one render per tick, and late ticks skip their render. So the game never
// draws more than 60 frames. On a 120-240 Hz monitor dadmod adds in-between frames:
//   1. At the HUD boundary (RunScene) the finished 3D picture is copied (fgS), so the HUD never gets warped.
//   2. At Present the whole frame (3D + HUD, before the screen effects) is kept back (fgF), and a quarter-res luma
//      pyramid of the 3D picture is built (1/4, 1/8, 1/16, 1/32 of the screen).
//   3. Motion search: coarse to fine block matching between the last two 3D pictures (symmetric, so the vectors
//      describe the halfway picture). Vectors are packed 16 bit per axis into plain A8R8G8B8 textures (every card).
//   4. The in-between frame at time t moves pixels of both pictures along the vectors and mixes them; where the two
//      disagree (something appeared from behind something else, or a camera cut) it shows the nearer real picture
//      unmoved. Pixels the HUD covers are taken from the real frame as is.
//   5. Pacing: the game's own Present shows the first in-between frame; the rest and then the real frame are shown
//      at even steps from the game's busy-wait (its Sleep(0) calls), or at the latest when the next frame begins
//      (BeginScene). Auto uses the monitor's rate, or a common rate is picked (120/144/165/180/240 Hz); 144 Hz alternates
//      2 and 3 frames per real frame, 120 Hz is always 2, 240 Hz always 4.
// Every card: 5 small pixel shaders, each well under the 512 instruction slots D3D9 guarantees (the build checks it
// with shaderslots.ps1 -Limit 512), every create checked, all-or-nothing. It switches itself off (logged once) when
// the monitor is 60 Hz, a shader or texture can't be made, ReShade is loaded, or the game runs below 60.
// dadmod\gfx_test.ini (test builds only): fgmult = 2|3|4 forces the multiplier (to test 3x/4x on a 120 Hz monitor).

static const char kFgShaders[] = R"HLSL(
float4 fgpx : register(c0);
float4 fgA : register(c90);
float4 fgB : register(c91);
sampler fs0 : register(s0);
sampler fs1 : register(s1);
sampler fs2 : register(s2);
sampler fs3 : register(s3);

float fgL(float3 c) { return dot(c, float3(0.299, 0.587, 0.114)); }

float4 fgEnc(float2 v) {
    float2 n = clamp(floor(v * 256.0 + 32768.5), 0.0, 65535.0);
    float2 hi = floor(n / 256.0);
    float2 lo = n - hi * 256.0;
    return float4(hi.x, lo.x, hi.y, lo.y) / 255.0;
}
float2 fgDec(float4 e) {
    float4 b = floor(e * 255.0 + 0.5);
    return (float2(b.x * 256.0 + b.y, b.z * 256.0 + b.w) - 32768.0) / 256.0;
}

float4 ps_fg_copy(float2 uv : TEXCOORD0) : COLOR { return tex2D(fs0, uv); }

float4 ps_fg_luma(float2 uv : TEXCOORD0) : COLOR {
    float2 d = fgpx.xy;
    float l = fgL(tex2D(fs0, uv + float2(-d.x, -d.y)).rgb) + fgL(tex2D(fs0, uv + float2(d.x, -d.y)).rgb)
            + fgL(tex2D(fs0, uv + float2(-d.x, d.y)).rgb) + fgL(tex2D(fs0, uv + float2(d.x, d.y)).rgb);
    l *= 0.25;
    return float4(l, l, l, 1);
}

float fgSad(float2 uv, float2 o) {
    float2 d = fgpx.xy;
    float s = 0;
    [unroll] for (int y = -1; y <= 1; y++) {
        [unroll] for (int x = -1; x <= 1; x++) {
            float2 q = uv + float2(x, y) * d;
            s += abs(tex2Dlod(fs0, float4(q - o, 0, 0)).r - tex2Dlod(fs1, float4(q + o, 0, 0)).r);
        }
    }
    return s;
}

float4 ps_fg_search0(float2 uv : TEXCOORD0) : COLOR {
    float2 d = fgpx.xy;
    float2 best = 0;
    float bc = fgSad(uv, float2(0, 0)) - 0.02;
    [loop] for (int j = -6; j <= 6; j++) {
        [loop] for (int i = -6; i <= 6; i++) {
            float2 v = float2(i, j);
            float c = fgSad(uv, v * 0.5 * d) + 0.004 * (abs(v.x) + abs(v.y));
            if (c < bc) { bc = c; best = v; }
        }
    }
    return fgEnc(best);
}

float2 fgCoarse(float2 uv) { return fgDec(tex2Dlod(fs2, float4(uv, 0, 0))) * 2.0; }

float4 ps_fg_search1(float2 uv : TEXCOORD0) : COLOR {
    float2 d = fgpx.xy, cd = fgA.xy;
    float2 pred = fgCoarse(uv);
    float2 best = 0;
    float bc = fgSad(uv, float2(0, 0)) - 0.02;
    [loop] for (int k = 0; k < 4; k++) {
        float2 off = float2(k == 0 ? 1.0 : (k == 1 ? -1.0 : 0.0), k == 2 ? 1.0 : (k == 3 ? -1.0 : 0.0)) * cd;
        float2 v = fgCoarse(uv + off);
        float c = fgSad(uv, v * 0.5 * d) + 0.01 * (abs(v.x - pred.x) + abs(v.y - pred.y));
        if (c < bc) { bc = c; best = v; }
    }
    [loop] for (int j = -2; j <= 2; j++) {
        [loop] for (int i = -2; i <= 2; i++) {
            float2 v = pred + float2(i, j);
            float c = fgSad(uv, v * 0.5 * d) + 0.006 * (abs((float)i) + abs((float)j));
            if (c < bc) { bc = c; best = v; }
        }
    }
    return fgEnc(best);
}

float2 fgVec(float2 uv) {
    float2 tc = uv * fgA.zw - 0.5;
    float2 f = frac(tc);
    float2 b = (floor(tc) + 0.5) * fgA.xy;
    float2 v00 = fgDec(tex2Dlod(fs2, float4(b, 0, 0)));
    float2 v10 = fgDec(tex2Dlod(fs2, float4(b + float2(fgA.x, 0), 0, 0)));
    float2 v01 = fgDec(tex2Dlod(fs2, float4(b + float2(0, fgA.y), 0, 0)));
    float2 v11 = fgDec(tex2Dlod(fs2, float4(b + fgA.xy, 0, 0)));
    return lerp(lerp(v00, v10, f.x), lerp(v01, v11, f.x), f.y);
}

float4 ps_fg_make(float2 uv : TEXCOORD0) : COLOR {
    float t = fgB.x;
    float2 dv = fgVec(uv) * fgA.xy;
    float3 a = tex2Dlod(fs0, float4(uv - t * dv, 0, 0)).rgb;
    float3 b = tex2Dlod(fs1, float4(uv + (1 - t) * dv, 0, 0)).rgb;
    float3 e3 = abs(a - b);
    float w = saturate((max(e3.r, max(e3.g, e3.b)) - 0.08) * 6.0);
    float3 n0 = tex2Dlod(fs0, float4(uv, 0, 0)).rgb;
    float3 n1 = tex2Dlod(fs1, float4(uv, 0, 0)).rgb;
    float3 c = lerp(lerp(a, b, t), t < 0.5 ? n0 : n1, w);
    float3 full = tex2Dlod(fs3, float4(uv, 0, 0)).rgb;
    float3 h3 = abs(full - n1);
    float hud = max(h3.r, max(h3.g, h3.b)) > 0.004 ? 1.0 : 0.0;
    return float4(lerp(c, full, hud), 1);
}
)HLSL";

static IDirect3DPixelShader9 *g_fgCopy = nullptr, *g_fgLuma = nullptr, *g_fgSearch0 = nullptr, *g_fgSearch1 = nullptr, *g_fgMake = nullptr;
static bool g_fgShadersTried = false, g_fgShadersOk = false;
static bool g_fgDead = false;        // a shader or texture could not be made: off for this session
static int g_fgTestMult = 0;         // gfx_test.ini fgmult

static double FgNow() {
    static LARGE_INTEGER f = {};
    if (!f.QuadPart) QueryPerformanceFrequency(&f);
    LARGE_INTEGER n;
    QueryPerformanceCounter(&n);
    return (double)n.QuadPart / (double)f.QuadPart;
}
static bool FgOn() { return V("gfx_framegen") != 0 && !g_fgDead; }

static void FgReadTest() {
    std::string s;
    if (!ReadWholeFile(ExeDirFile("gfx_test.ini"), s)) return;
    size_t p = s.find("fgmult");
    if (p == std::string::npos) return;
    size_t eq = s.find('=', p);
    if (eq == std::string::npos) return;
    int m = atoi(s.c_str() + eq + 1);
    if (m >= 1 && m <= 4) { g_fgTestMult = m; mmenu::Log("gfx: frame generation [TEST: %dx forced]", m); }
}

static bool FgShader(IDirect3DDevice9* dev, CompileShader_t compile, const char* fn, IDirect3DPixelShader9** out) {
    static unsigned long long h = 0;
    if (!h) {
        h = 1469598103934665603ULL;
        for (size_t i = 0; i < sizeof kFgShaders - 1; ++i) { h ^= (unsigned char)kFgShaders[i]; h *= 1099511628211ULL; }
    }
    char name[160];
    wsprintfA(name, "shadercache\\%s_ps_3_0_%08X%08X.bin", fn, (DWORD)(h >> 32), (DWORD)h);
    std::string path = ExeDirFile(name), code, err;
    if (!ReadWholeFile(path, code) || code.size() < 4 || code.size() % 4) {
        code.clear();
        if (!compile) { mmenu::Log("gfx: frame generation shader %s: d3dx9_43.dll not found", fn); return false; }
        XBuf *c = nullptr, *e = nullptr;
        HRESULT hr = compile(kFgShaders, sizeof kFgShaders - 1, nullptr, nullptr, fn, "ps_3_0", 0, &c, &e, nullptr);
        if (e) { err = (const char*)e->GetBufferPointer(); e->Release(); }
        if (FAILED(hr) || !c) {
            if (c) c->Release();
            mmenu::Log("gfx: frame generation shader %s failed to compile: %s", fn, err.empty() ? "?" : err.c_str());
            return false;
        }
        code.assign((const char*)c->GetBufferPointer(), c->GetBufferSize());
        c->Release();
        CreateDirectoryA(ExeDirFile("shadercache").c_str(), nullptr);
        WriteWholeFile(path, code);
    }
    UINT slots = ShaderSlots(code);
    if (slots > g_cardPsSlots || slots > 512) {
        mmenu::Log("gfx: frame generation shader %s skipped: %u instruction slots (card allows %u, our limit 512)", fn, slots, g_cardPsSlots);
        return false;
    }
    HRESULT hr = g_testFailShader == fn ? D3DERR_INVALIDCALL : dev->CreatePixelShader((const DWORD*)code.data(), out);
    if (FAILED(hr) || !*out) {
        if (*out) { (*out)->Release(); *out = nullptr; }
        mmenu::Log("gfx: frame generation shader %s rejected by the card (hr 0x%08lX, %u slots)%s", fn, hr, slots, g_testFailShader == fn ? " [TEST]" : "");
        return false;
    }
    return true;
}
static bool FgMakeShaders(IDirect3DDevice9* dev) {
    if (g_fgShadersTried) return g_fgShadersOk;
    g_fgShadersTried = true;
    FgReadTest();
    if (!g_dx) g_dx = LoadLibraryA("d3dx9_43.dll");
    auto compile = g_dx ? (CompileShader_t)GetProcAddress(g_dx, "D3DXCompileShader") : nullptr;
    struct { const char* fn; IDirect3DPixelShader9** out; } list[] = {
        {"ps_fg_copy", &g_fgCopy}, {"ps_fg_luma", &g_fgLuma}, {"ps_fg_search0", &g_fgSearch0},
        {"ps_fg_search1", &g_fgSearch1}, {"ps_fg_make", &g_fgMake}};
    bool ok = true;
    for (auto& s : list) if (!FgShader(dev, compile, s.fn, s.out)) { ok = false; break; }
    if (!ok) {
        for (auto& s : list) if (*s.out) { (*s.out)->Release(); *s.out = nullptr; }
        g_fgDead = true;
        mmenu::Log("gfx: frame generation off on this card (the game itself is unchanged)");
        return false;
    }
    g_fgShadersOk = true;
    mmenu::Log("gfx: frame generation shaders ready");
    return true;
}

// ---- textures (D3DPOOL_DEFAULT: freed at every device reset) ----
static IDirect3DTexture9 *g_fgS[2] = {}, *g_fgF = nullptr, *g_fgL[2][4] = {}, *g_fgV[4] = {};
static UINT g_fgW = 0, g_fgH = 0, g_fgLw[4] = {}, g_fgLh[4] = {};
static bool g_fgHave[2] = {};
static DWORD g_fgSeq[2] = {};
static int g_fgCur = 0;             // slot of the newest 3D picture
static bool g_fgSceneThis = false;  // the 3D picture of this frame was copied at the HUD boundary

static void FgFree() {
    IDirect3DTexture9** all[] = {&g_fgS[0], &g_fgS[1], &g_fgF, &g_fgL[0][0], &g_fgL[0][1], &g_fgL[0][2], &g_fgL[0][3],
                                 &g_fgL[1][0], &g_fgL[1][1], &g_fgL[1][2], &g_fgL[1][3], &g_fgV[0], &g_fgV[1], &g_fgV[2], &g_fgV[3]};
    for (auto p : all) if (*p) { (*p)->Release(); *p = nullptr; }
    g_fgW = g_fgH = 0;
    g_fgHave[0] = g_fgHave[1] = false;
    g_fgSceneThis = false;
}
static bool FgTargets(IDirect3DDevice9* dev, UINT w, UINT h) {
    if (w == g_fgW && h == g_fgH && g_fgF) return true;
    FgFree();
    auto rt = [&](UINT a, UINT b, IDirect3DTexture9** t) {
        HRESULT hr = dev->CreateTexture(a, b, 1, D3DUSAGE_RENDERTARGET, D3DFMT_A8R8G8B8, D3DPOOL_DEFAULT, t, nullptr);
        if (FAILED(hr) || !*t) { *t = nullptr; mmenu::Log("gfx: frame generation texture %ux%u failed (hr 0x%08lX)", a, b, hr); return false; }
        return true;
    };
    for (int k = 0; k < 4; ++k) {
        g_fgLw[k] = w >> (2 + k); if (!g_fgLw[k]) g_fgLw[k] = 1;
        g_fgLh[k] = h >> (2 + k); if (!g_fgLh[k]) g_fgLh[k] = 1;
    }
    bool ok = rt(w, h, &g_fgS[0]) && rt(w, h, &g_fgS[1]) && rt(w, h, &g_fgF);
    for (int k = 0; ok && k < 4; ++k)
        ok = rt(g_fgLw[k], g_fgLh[k], &g_fgL[0][k]) && rt(g_fgLw[k], g_fgLh[k], &g_fgL[1][k]) && rt(g_fgLw[k], g_fgLh[k], &g_fgV[k]);
    if (!ok) { FgFree(); return false; }
    g_fgW = w; g_fgH = h;
    return true;
}
static bool FgReady(IDirect3DDevice9* dev, UINT w, UINT h) {
    if (g_fgDead) return false;
    if (!MakeShaders(dev) || !EnsureTargets(dev, w, h)) return false;
    if (!FgMakeShaders(dev)) return false;
    if (!FgTargets(dev, w, h)) {
        static int n = 0;
        if (++n >= 3) { g_fgDead = true; mmenu::Log("gfx: frame generation off: its textures can't be made on this card"); }
        return false;
    }
    return true;
}
static IDirect3DSurface9* FgSurf(IDirect3DTexture9* t) {
    IDirect3DSurface9* s = nullptr;
    if (t) t->GetSurfaceLevel(0, &s);
    return s;
}

// RunScene (the HUD is about to be drawn): keep the finished 3D picture
static void FgCaptureScene(IDirect3DDevice9* dev) {
    if (!FgOn()) return;
    IDirect3DSurface9* bb = nullptr;
    if (FAILED(dev->GetBackBuffer(0, 0, D3DBACKBUFFER_TYPE_MONO, &bb)) || !bb) return;
    D3DSURFACE_DESC d;
    bb->GetDesc(&d);
    if (FgReady(dev, d.Width, d.Height)) {
        IDirect3DSurface9* s = FgSurf(g_fgS[g_fgCur ^ 1]);
        if (s && SUCCEEDED(dev->StretchRect(bb, nullptr, s, nullptr, D3DTEXF_NONE))) g_fgSceneThis = true;
        if (s) s->Release();
    }
    bb->Release();
}

// ---- status and pacing ----
// gfx_framegen (Noah 2026-11-21 "we should be able to select common hz"): 0 off, 1 auto (the monitor's rate), 2 120 Hz,
// 3 144 Hz, 4 165 Hz, 5 180 Hz, 6 240 Hz. A picked rate above the monitor's is capped to the monitor (frames it can't
// show would only block). Rates that aren't a multiple of 60 alternate (144 Hz: 2, 3, 2, 3, 2 frames per real frame).
static const int kFgRates[] = {0, 0, 120, 144, 165, 180, 240};
static int g_fgRate = 0;            // frames shown per second (0 = not running)
static int g_fgMult = 1;            // frames shown for the current real frame
static double g_fgAcc = 0;          // fraction of a frame carried to the next real frame
static int g_fgRefresh = 0;
static const char* g_fgWhy = "";    // why it isn't generating right now (logged when it changes)
static double g_fgLast = 0, g_fgGapAvg = 1.0 / 60, g_fgPauseUntil = 0;
static int g_fgSlow = 0;
static DWORD g_fgThread = 0;
static bool g_fgGenNow = false;     // bb holds a generated frame (the game's Present shows it)
static bool g_fgInEnd = false;      // inside EndFrame: our own BeginScene calls are not the next frame
static LONG g_fgBsCount = 0;
static int g_fgStats[4] = {};       // generated shown on time, generated dropped, real on time, real late

static void FgWhy(const char* why) {
    if (strcmp(why, g_fgWhy)) {
        mmenu::Log("gfx: frame generation %s", why);
        g_fgWhy = why;
    }
}
static void FgCheckRefresh(IDirect3DDevice9* dev) {
    static DWORD at = 0;
    if (g_fgRefresh && (int)(g_presents - at) < 120) return;
    at = g_presents;
    IDirect3D9* d3d = nullptr;
    D3DDEVICE_CREATION_PARAMETERS cp = {};
    D3DDISPLAYMODE dm = {};
    if (SUCCEEDED(dev->GetDirect3D(&d3d)) && d3d) {
        if (SUCCEEDED(dev->GetCreationParameters(&cp))) d3d->GetAdapterDisplayMode(cp.AdapterOrdinal, &dm);
        d3d->Release();
    }
    int r = (int)dm.RefreshRate;
    int pick = V("gfx_framegen");
    int want = pick >= 2 && pick <= 6 ? kFgRates[pick] : r;
    int rate = want > r + 3 ? r : want;  // never faster than the monitor
    if (rate > 240) rate = 240;
    if (rate < 100) rate = 0;
    if (g_fgTestMult) rate = 60 * g_fgTestMult;
    if (r != g_fgRefresh || rate != g_fgRate)
        mmenu::Log("gfx: frame generation: monitor %d Hz, picked %s%d Hz -> showing %d frames a second", r,
                   pick >= 2 ? "" : "auto ", want, rate ? rate : 60);
    g_fgRefresh = r;
    g_fgRate = rate;
}
static int g_fgPickWas = -1;

// The game's Present (via EndFrame, before RunScreen): keep this frame back and put the first in-between frame
// in the back buffer. Returns true when it did.
static void FgDraw(IDirect3DDevice9* dev, IDirect3DSurface9* bb, int prev, int cur, float t, bool search);
static void FgInstallSleep();
static bool FgFrame(IDirect3DDevice9* dev) {
    g_fgGenNow = false;
    g_fgThread = GetCurrentThreadId();
    double now = FgNow();
    double gap = g_fgLast ? now - g_fgLast : 1.0 / 60;
    g_fgLast = now;
    g_fgGapAvg = g_fgGapAvg * 0.95 + gap * 0.05;
    bool sceneThis = g_fgSceneThis;
    g_fgSceneThis = false;
    if (!FgOn()) {
        g_fgHave[0] = g_fgHave[1] = false;
        if (V("gfx_framegen")) FgWhy("off: not available on this card");
        else if (*g_fgWhy) FgWhy("off");
        return false;
    }
    FgInstallSleep();
    if (g_reshadeLoaded) { g_fgHave[0] = g_fgHave[1] = false; FgWhy("off: ReShade is loaded"); return false; }
    if (V("gfx_framegen") != g_fgPickWas) { g_fgPickWas = V("gfx_framegen"); g_fgRefresh = 0; }  // a new pick: check again now
    FgCheckRefresh(dev);
    if (g_fgRate < 100) { g_fgHave[0] = g_fgHave[1] = false; FgWhy("off: monitor is 60 Hz or slower"); return false; }
    g_fgAcc += g_fgRate / 60.0;
    g_fgMult = (int)(g_fgAcc + 1e-6);
    g_fgAcc -= g_fgMult;
    if (g_fgMult < 1) g_fgMult = 1;
    if (g_fgMult > 4) g_fgMult = 4;
    if (g_presents > 600 && g_fgBsCount == 0) { g_fgDead = true; FgWhy("off: the game never calls BeginScene"); return false; }
    // the game running below 60: never make it worse
    if (now < g_fgPauseUntil) return false;
    if (g_fgGapAvg > 1.0 / 52) {
        if (++g_fgSlow > 120) {
            g_fgSlow = 0;
            g_fgPauseUntil = now + 10;
            g_fgHave[0] = g_fgHave[1] = false;
            mmenu::Log("gfx: frame generation paused for 10 s: the game is running below 60 (%.1f fps)", 1.0 / g_fgGapAvg);
            return false;
        }
    } else g_fgSlow = 0;
    IDirect3DSurface9* bb = nullptr;
    if (FAILED(dev->GetBackBuffer(0, 0, D3DBACKBUFFER_TYPE_MONO, &bb)) || !bb) return false;
    D3DSURFACE_DESC d;
    bb->GetDesc(&d);
    if (!FgReady(dev, d.Width, d.Height)) { bb->Release(); return false; }
    int n = g_fgCur ^ 1, p = g_fgCur;
    IDirect3DSurface9 *sF = FgSurf(g_fgF), *sS = FgSurf(g_fgS[n]);
    bool ok = sF && sS && SUCCEEDED(dev->StretchRect(bb, nullptr, sF, nullptr, D3DTEXF_NONE));
    if (ok && !sceneThis) ok = SUCCEEDED(dev->StretchRect(bb, nullptr, sS, nullptr, D3DTEXF_NONE));  // no HUD boundary this frame
    if (sF) sF->Release();
    if (sS) sS->Release();
    if (!ok) { bb->Release(); g_fgHave[0] = g_fgHave[1] = false; return false; }
    g_fgCur = n;
    g_fgHave[n] = true;
    g_fgSeq[n] = g_presents;
    // a pair = this frame and the one right before it, on time. Without one (first frame, a skipped or late tick)
    // only the pyramid is built and the real frame goes out now (the back buffer is left alone).
    bool pair = g_fgHave[p] && g_fgSeq[p] + 1 == g_presents && gap < 1.5 / 60 && g_fgMult >= 2;
    FgDraw(dev, bb, p, n, pair ? 1.0f / g_fgMult : 0.0f, true);
    if (pair) { g_fgGenNow = true; FgWhy("on"); }
    bb->Release();
    return g_fgGenNow;
}

// t > 0: the in-between frame at time t into the back buffer; t < 0: the real frame kept back; t == 0: nothing.
// search: first build the pyramid of the newest 3D picture and (with t > 0) the motion vectors.
static void FgDraw(IDirect3DDevice9* dev, IDirect3DSurface9* bb, int prev, int cur, float t, bool search) {
    bool wasIn = g_inPost;
    g_inPost = true;
    dev->BeginScene();
    g_sb->Capture();
    IDirect3DSurface9 *oldRT = nullptr, *oldDS = nullptr;
    dev->GetRenderTarget(0, &oldRT);
    dev->GetDepthStencilSurface(&oldDS);
    dev->SetDepthStencilSurface(nullptr);
    CommonState(dev);
    dev->SetSamplerState(2, D3DSAMP_MINFILTER, D3DTEXF_POINT);
    dev->SetSamplerState(2, D3DSAMP_MAGFILTER, D3DTEXF_POINT);
    UINT w = g_fgW, h = g_fgH;
    if (search) {
        IDirect3DSurface9* s = FgSurf(g_fgL[cur][0]);
        Pass(dev, g_fgLuma, s, w, h, g_fgLw[0], g_fgLh[0], g_fgS[cur]);
        if (s) s->Release();
        for (int k = 1; k < 4; ++k) {
            s = FgSurf(g_fgL[cur][k]);
            Pass(dev, g_fgCopy, s, g_fgLw[k - 1], g_fgLh[k - 1], g_fgLw[k], g_fgLh[k], g_fgL[cur][k - 1]);
            if (s) s->Release();
        }
        if (t > 0) {
            s = FgSurf(g_fgV[3]);
            Pass(dev, g_fgSearch0, s, g_fgLw[3], g_fgLh[3], g_fgLw[3], g_fgLh[3], g_fgL[prev][3], g_fgL[cur][3]);
            if (s) s->Release();
            for (int k = 2; k >= 0; --k) {
                float a[4] = {1.0f / g_fgLw[k + 1], 1.0f / g_fgLh[k + 1], 0, 0};
                dev->SetPixelShaderConstantF(90, a, 1);
                s = FgSurf(g_fgV[k]);
                Pass(dev, g_fgSearch1, s, g_fgLw[k], g_fgLh[k], g_fgLw[k], g_fgLh[k], g_fgL[prev][k], g_fgL[cur][k], g_fgV[k + 1]);
                if (s) s->Release();
            }
        }
    }
    if (t > 0) {
        float a[4] = {1.0f / g_fgLw[0], 1.0f / g_fgLh[0], (float)g_fgLw[0], (float)g_fgLh[0]}, b[4] = {t, 0, 0, 0};
        dev->SetPixelShaderConstantF(90, a, 1);
        dev->SetPixelShaderConstantF(91, b, 1);
        Pass(dev, g_fgMake, bb, w, h, w, h, g_fgS[prev], g_fgS[cur], g_fgV[0], g_fgF);
    } else if (t < 0) {
        Pass(dev, g_fgCopy, bb, w, h, w, h, g_fgF);  // the real frame, kept back
    }
    for (DWORD i = 0; i < 4; ++i) dev->SetTexture(i, nullptr);
    dev->SetRenderTarget(0, oldRT);
    dev->SetDepthStencilSurface(oldDS);
    g_sb->Apply();
    dev->EndScene();
    if (oldRT) oldRT->Release();
    if (oldDS) oldDS->Release();
    g_inPost = wasIn;
}

// ---- the frames still to show after the game's Present ----
struct FgItem { double due; float t; };  // t < 0: the real frame
static FgItem g_fgQ[4];
static int g_fgQn = 0, g_fgQi = 0;
static IDirect3DDevice9* g_fgDev = nullptr;
static IDirect3DSwapChain9* g_fgSc = nullptr;  // the game presents through its swap chain (else the device)
static RECT g_fgRa, g_fgRb;
static bool g_fgHasA = false, g_fgHasB = false;
static HWND g_fgWnd = nullptr;
static DWORD g_fgFlags = 0;

static void NoteDeviceLost(HRESULT hr);  // gfx.inc
static void FgClear() { g_fgQn = g_fgQi = 0; }
// after the game's Present returned: schedule the rest at even steps of 1/(60 x mult) s
static void FgQueue(IDirect3DDevice9* dev, IDirect3DSwapChain9* sc, const RECT* a, const RECT* b, HWND w, const RGNDATA* r, DWORD f, HRESULT hr) {
    if (!g_fgGenNow) return;
    g_fgGenNow = false;
    if (FAILED(hr) || r) { FgClear(); return; }
    g_fgDev = dev; g_fgSc = sc; g_fgWnd = w; g_fgFlags = f;
    g_fgHasA = a != nullptr; if (a) g_fgRa = *a;
    g_fgHasB = b != nullptr; if (b) g_fgRb = *b;
    double t0 = FgNow(), step = 1.0 / (g_fgRate > 0 ? g_fgRate : 60.0 * g_fgMult);
    g_fgQn = g_fgQi = 0;
    for (int k = 2; k < g_fgMult; ++k) g_fgQ[g_fgQn++] = {t0 + (k - 1) * step, (float)k / g_fgMult};
    g_fgQ[g_fgQn++] = {t0 + (g_fgMult - 1) * step, -1.0f};
}
static void FgShow(const FgItem& it) {
    IDirect3DDevice9* dev = g_fgDev;
    IDirect3DSurface9* bb = nullptr;
    if (!dev || FAILED(dev->GetBackBuffer(0, 0, D3DBACKBUFFER_TYPE_MONO, &bb)) || !bb) { FgClear(); return; }
    FgDraw(dev, bb, g_fgCur ^ 1, g_fgCur, it.t, false);
    bb->Release();
    RunScreen(dev);  // the screen effects, FPS counter and screenshot flash on this frame too
    const RECT* a = g_fgHasA ? &g_fgRa : nullptr;
    const RECT* b = g_fgHasB ? &g_fgRb : nullptr;
    bool wasIn = g_inPost;
    g_inPost = true;
    HRESULT hr = g_fgSc ? g_origSCPresent(g_fgSc, a, b, g_fgWnd, nullptr, g_fgFlags) : g_origPresent(dev, a, b, g_fgWnd, nullptr);
    g_inPost = wasIn;
    NoteDeviceLost(hr);
    if (FAILED(hr)) FgClear();
}
// late = the next frame is starting: drop in-between frames not shown yet, show the real frame now
static void FgRun(bool late) {
    while (g_fgQi < g_fgQn) {
        FgItem it = g_fgQ[g_fgQi];
        bool real = it.t < 0;
        if (!late && FgNow() < it.due) return;
        ++g_fgQi;
        if (late && !real) { ++g_fgStats[1]; continue; }
        ++g_fgStats[real ? (late ? 3 : 2) : 0];
        FgShow(it);
    }
    FgClear();
    if (g_fgStats[2] + g_fgStats[3] == 600 || (g_fgStats[2] + g_fgStats[3]) % 36000 == 0)
        mmenu::Log("gfx: frame generation %d Hz: %d in-between frames shown, %d dropped, real frames %d on time, %d late",
                   g_fgRate, g_fgStats[0] + (g_fgStats[2] + g_fgStats[3]), g_fgStats[1], g_fgStats[2], g_fgStats[3]);
}

// the game's busy-wait between ticks (Sleep(0) in 0x44EEF0) is where the queued frames go out on time
static void(WINAPI* g_fgRealSleep)(DWORD) = nullptr;
static void WINAPI FgSleep(DWORD ms) {
    if (g_fgQi < g_fgQn && !g_inPost && GetCurrentThreadId() == g_fgThread) FgRun(false);
    g_fgRealSleep(ms);
}
static void HookImport(HMODULE mod, const char* dll, void* real, void* hook);
static void FgInstallSleep() {
    static bool done = false;
    if (done) return;
    done = true;
    HMODULE k = GetModuleHandleA("kernel32.dll");
    void* real = k ? (void*)GetProcAddress(k, "Sleep") : nullptr;
    if (!real) return;
    g_fgRealSleep = (void(WINAPI*)(DWORD))real;
    HookImport(GetModuleHandleA(nullptr), "kernel32.dll", real, (void*)&FgSleep);
}

typedef HRESULT(STDMETHODCALLTYPE* BeginScene_t)(IDirect3DDevice9*);
static BeginScene_t g_origBS = nullptr;
static HRESULT STDMETHODCALLTYPE HookBS(IDirect3DDevice9* dev) {
    if (!g_inPost && !g_fgInEnd) {
        InterlockedIncrement(&g_fgBsCount);
        if (g_fgQi < g_fgQn) FgRun(true);
    }
    return g_origBS(dev);
}

// fullscreen (exclusive) with frame generation on: ask for the monitor's fastest refresh at this resolution
static void FgFullscreenRefresh(IDirect3D9* d3d, UINT adapter, D3DPRESENT_PARAMETERS* pp) {  // (borderless fullscreen uses the desktop's rate)
    if (!d3d || !pp || pp->Windowed || V("gfx_framegen") == 0) return;
    if (pp->FullScreen_RefreshRateInHz >= 100) return;
    D3DFORMAT fmt = pp->BackBufferFormat == D3DFMT_UNKNOWN ? D3DFMT_X8R8G8B8 : pp->BackBufferFormat;
    if (fmt == D3DFMT_A8R8G8B8) fmt = D3DFMT_X8R8G8B8;
    UINT best = 0, n = d3d->GetAdapterModeCount(adapter, fmt);
    for (UINT i = 0; i < n; ++i) {
        D3DDISPLAYMODE m;
        if (FAILED(d3d->EnumAdapterModes(adapter, fmt, i, &m))) continue;
        if (m.Width == pp->BackBufferWidth && m.Height == pp->BackBufferHeight && m.RefreshRate <= 250 && m.RefreshRate > best) best = m.RefreshRate;
    }
    if (best >= 100) {
        mmenu::Log("gfx: frame generation: fullscreen at %u Hz (was %u)", best, pp->FullScreen_RefreshRateInHz);
        pp->FullScreen_RefreshRateInHz = best;
    }
}
