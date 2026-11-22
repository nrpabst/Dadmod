// Frame generation (Noah 2026-11-21: "can we build frame generation into thugpro", "make sure it plays nice with all
// graphics cards", "it should work with up to 240hz"). Included by gfx.inc (inside namespace gfx), after RunScreen.
//
// Why it is needed: the main loop (0x44EEF0) is a fixed 60 ticks a second (it busy-waits on the performance counter
// for freq/60, with Sleep(0)), physics and one render per tick. A tick that starts 1.5 ticks or more behind its
// schedule skips its render (up to 4 in a row); the schedule itself never slips. So the game never draws more than
// 60 frames. On a 120-240 Hz monitor dadmod adds in-between frames:
//   1. At the HUD boundary (RunScene) the finished 3D picture is copied (fgS), so the HUD never gets warped.
//   2. At Present the whole frame (3D + HUD, before the screen effects) is kept back (fgF), and a quarter-res luma
//      pyramid of the 3D picture is built (1/4, 1/8, 1/16, 1/32 of the screen).
//   3. Motion search: coarse to fine block matching between the last two 3D pictures (symmetric, so the vectors
//      describe the halfway picture), with the last real frame's motion as an extra guess. Vectors are packed
//      16 bit per axis into plain A8R8G8B8 textures (every card).
//   4. The in-between frame at time t moves pixels of both pictures along the vectors and mixes them; where the two
//      disagree (something appeared from behind something else) it shows the nearer real picture unmoved. Pixels
//      the HUD covers are taken from the real frame as is. A camera cut (respawn, replay, level change) shows only
//      real frames.
//   5. Pacing (2026-11-22 rework): every frame is aimed at its own monitor refresh. In a window the refresh times
//      come from Windows (DwmGetCompositionTimingInfo), else from the card's scan line (GetRasterStatus), in true
//      fullscreen with v-sync the card itself shows one frame per refresh; only without any of those the frames
//      are spaced by the clock. The game's own Present is held until the start of a refresh, so the game's frames
//      lock on to the monitor instead of drifting against it. If the frames of one tick can't all go out before
//      the game would start skipping renders, that tick shows only its real frame (never two frames bunched up).
//      Rates that aren't a multiple of 60 (144 Hz) follow one even grid of frame times across ticks.
// Shaders: 6 small pixel shaders, each well under the 512 instruction slots D3D9 guarantees (the build checks it
// with shaderslots.ps1 -Limit 512). They are compiled (the bytecode is the same for every card) by a background
// thread from the game's first frame, during the startup loading screen, together with the other effect shaders
// frame generation needs, and loaded onto the card at startup (Noah 2026-11-22: turning it on froze the game ~6 s
// while every effect shader compiled). Every create is checked, all-or-nothing: it switches itself off (logged)
// when the monitor is 60 Hz, a shader or texture can't be made, ReShade is loaded, or the game runs below 60.
// dadmod\gfx_test.ini (test builds only): fgmult = 2|3|4 forces the multiplier (clock pacing, to test 3x/4x on a
// 120 Hz monitor).

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
    l = sqrt(l * 0.25);  // square root: lifts dark detail so night levels still give the search something to match
    return float4(l, l, l, 1);
}

float fgSad(float2 uv, float2 o) {
    float2 d = fgpx.xy * 2.0;  // 3x3 taps spread over 5x5 pixels: steadier vectors for the same cost
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

// fgA.xy: one texel of the coarser level, fgA.z: scale of last frame's vectors to this level, fgA.w: 1 = they exist
float4 ps_fg_search1(float2 uv : TEXCOORD0) : COLOR {
    float2 d = fgpx.xy, cd = fgA.xy;
    float2 pred = fgCoarse(uv);
    // start from the coarse level's guess; "nothing moved" only wins where it fits clearly better
    // (2026-11-22: a big bonus for standing still left flat walls and sky frozen while the rest moved)
    float2 best = pred;
    float bc = fgSad(uv, pred * 0.5 * d);
    float c0 = fgSad(uv, float2(0, 0)) - 0.008;
    if (c0 < bc) { bc = c0; best = 0; }
    if (fgA.w > 0.5) {  // last real frame's motion here: keeps the vectors steady from frame to frame
        float2 v = fgDec(tex2Dlod(fs3, float4(uv, 0, 0))) * fgA.z;
        float c = fgSad(uv, v * 0.5 * d) + 0.002 * (abs(v.x - pred.x) + abs(v.y - pred.y));
        if (c < bc) { bc = c; best = v; }
    }
    [loop] for (int k = 0; k < 4; k++) {
        float2 off = float2(k == 0 ? 1.0 : (k == 1 ? -1.0 : 0.0), k == 2 ? 1.0 : (k == 3 ? -1.0 : 0.0)) * cd;
        float2 v = fgCoarse(uv + off);
        float c = fgSad(uv, v * 0.5 * d) + 0.01 * (abs(v.x - pred.x) + abs(v.y - pred.y));
        if (c < bc) { bc = c; best = v; }
    }
    float2 ctr = best;  // refine around the best guess so far
    [loop] for (int j = -2; j <= 2; j++) {
        [loop] for (int i = -2; i <= 2; i++) {
            float2 v = ctr + float2(i, j);
            float c = fgSad(uv, v * 0.5 * d) + 0.006 * (abs((float)i) + abs((float)j));
            if (c < bc) { bc = c; best = v; }
        }
    }
    return fgEnc(best);
}

// a vector that fits its own pixels worse than a neighbour's vector is replaced by that one (removes stray vectors)
float4 ps_fg_smooth(float2 uv : TEXCOORD0) : COLOR {
    float2 d = fgpx.xy;
    float2 best = fgDec(tex2Dlod(fs2, float4(uv, 0, 0)));
    float bc = fgSad(uv, best * 0.5 * d);
    [loop] for (int j = -1; j <= 1; j++) {
        [loop] for (int i = -1; i <= 1; i++) {
            float2 v = fgDec(tex2Dlod(fs2, float4(uv + float2(i, j) * d, 0, 0)));
            float c = fgSad(uv, v * 0.5 * d);
            if (c < bc - 0.0001) { bc = c; best = v; }
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
    float2 v = fgVec(uv);
    // the vectors describe the halfway picture: away from t = 0.5 (3x/4x frames) read them where this pixel
    // is at the halfway time (2026-11-22: they were read at the pixel itself, so 3x/4x frames wobbled)
    if (abs(t - 0.5) > 0.01) v = fgVec(uv + (0.5 - t) * v * fgA.xy);
    float2 dv = v * fgA.xy;
    float3 a = tex2Dlod(fs0, float4(uv - t * dv, 0, 0)).rgb;
    float3 b = tex2Dlod(fs1, float4(uv + (1 - t) * dv, 0, 0)).rgb;
    // how well the two moved pictures agree around this pixel (3x3): where they don't, the vector is wrong here
    // (or something appeared from behind something else) and the nearer real picture is shown unmoved instead
    // Also: what is at this pixel in one real picture must be found one whole vector away in the other (in at least
    // one direction). 2026-11-22 recording: on a dark floor the search found "floor here, floor there" vectors
    // that skip right over the skater's legs and board; both moved pictures showed floor, so they agreed and the
    // legs vanished from the made-up frames (flashing at 60 Hz). Such a vector can't carry what is really here.
    float e = 0, ef = 0, eb = 0;
    [unroll] for (int y = -1; y <= 1; y++) {
        [unroll] for (int x = -1; x <= 1; x++) {
            float2 q = uv + float2(x, y) * fgpx.xy;
            float3 e3 = abs(tex2Dlod(fs0, float4(q - t * dv, 0, 0)).rgb - tex2Dlod(fs1, float4(q + (1 - t) * dv, 0, 0)).rgb);
            float3 f3 = abs(tex2Dlod(fs0, float4(q, 0, 0)).rgb - tex2Dlod(fs1, float4(q + dv, 0, 0)).rgb);
            float3 b3 = abs(tex2Dlod(fs1, float4(q, 0, 0)).rgb - tex2Dlod(fs0, float4(q - dv, 0, 0)).rgb);
            e += max(e3.r, max(e3.g, e3.b));
            ef += max(f3.r, max(f3.g, f3.b));
            eb += max(b3.r, max(b3.g, b3.b));
        }
    }
    e = max(e, min(ef, eb));
    float w = saturate((e / 9.0 - 0.035) * 15.0);
    float3 n0 = tex2Dlod(fs0, float4(uv, 0, 0)).rgb;
    float3 n1 = tex2Dlod(fs1, float4(uv, 0, 0)).rgb;
    float3 c = lerp(lerp(a, b, t), t < 0.5 ? n0 : n1, w);
    float3 full = tex2Dlod(fs3, float4(uv, 0, 0)).rgb;
    float3 h3 = abs(full - n1);
    float hud = max(h3.r, max(h3.g, h3.b)) > 0.004 ? 1.0 : 0.0;
    float3 o = lerp(c, full, hud);
    if (fgB.y > 0.5) {  // debug view (gfx_test.ini fgshow = 1): red = motion guess rejected, blue = HUD, magenta corner = made-up frame
        o = lerp(o, float3(1, 0, 0), w * 0.5);
        o = lerp(o, float3(0, 0.3, 1), hud * 0.5);
        if (uv.x > 1 - 24 * fgpx.x && uv.y < 24 * fgpx.y) o = float3(1, 0, 1);
    }
    return float4(o, 1);
}
)HLSL";

static IDirect3DPixelShader9 *g_fgCopy = nullptr, *g_fgLuma = nullptr, *g_fgSearch0 = nullptr, *g_fgSearch1 = nullptr, *g_fgSmooth = nullptr, *g_fgMake = nullptr;
static bool g_fgShadersTried = false, g_fgShadersOk = false;
static bool g_fgDead = false;        // a shader or texture could not be made: off for this session
static int g_fgTestMult = 0;         // gfx_test.ini fgmult
static int g_fgDebugView = 0;        // gfx_test.ini fgshow

static double FgFreq() {
    static LARGE_INTEGER f = {};
    if (!f.QuadPart) QueryPerformanceFrequency(&f);
    return (double)f.QuadPart;
}
static double FgNow() {
    LARGE_INTEGER n;
    QueryPerformanceCounter(&n);
    return (double)n.QuadPart / FgFreq();
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
    if (m >= 1 && m <= 4) { g_fgTestMult = m; mmenu::Log("gfx: frame generation [TEST: %dx forced, frames spaced by the clock]", m); }
}
static void FgReadShow() {  // gfx_test.ini fgshow = 1: debug view in the made-up frames
    std::string s;
    g_fgDebugView = 0;
    if (!ReadWholeFile(ExeDirFile("gfx_test.ini"), s)) return;
    size_t p = s.find("fgshow");
    if (p == std::string::npos) return;
    size_t eq = s.find('=', p);
    if (eq != std::string::npos && atoi(s.c_str() + eq + 1) == 1) { g_fgDebugView = 1; mmenu::Log("gfx: frame generation [TEST: debug view]"); }
}

// ---- compiling (any thread: the compiler and the cache files are guarded by CompileLock in gfx.inc) ----
static const char* const kFgNames[] = {"ps_fg_copy", "ps_fg_luma", "ps_fg_search0", "ps_fg_search1", "ps_fg_smooth", "ps_fg_make"};
static bool FgCode(CompileShader_t compile, const char* fn, std::string& code, std::string& err) {
    static unsigned long long h = 0;
    if (!h) {
        unsigned long long x = 1469598103934665603ULL;
        for (size_t i = 0; i < sizeof kFgShaders - 1; ++i) { x ^= (unsigned char)kFgShaders[i]; x *= 1099511628211ULL; }
        h = x;
    }
    char name[160];
    wsprintfA(name, "shadercache\\%s_ps_3_0_%08X%08X.bin", fn, (DWORD)(h >> 32), (DWORD)h);
    std::string path = ExeDirFile(name);
    EnterCriticalSection(CompileLock());
    bool ok = ReadWholeFile(path, code) && code.size() >= 4 && code.size() % 4 == 0;
    if (!ok) {
        code.clear();
        if (!compile) err = "d3dx9_43.dll not found";
        else {
            XBuf *c = nullptr, *e = nullptr;
            HRESULT hr = compile(kFgShaders, sizeof kFgShaders - 1, nullptr, nullptr, fn, "ps_3_0", 0, &c, &e, nullptr);
            if (e) { err = (const char*)e->GetBufferPointer(); e->Release(); }
            if (SUCCEEDED(hr) && c) {
                code.assign((const char*)c->GetBufferPointer(), c->GetBufferSize());
                CreateDirectoryA(ExeDirFile("shadercache").c_str(), nullptr);
                WriteWholeFile(path, code);
                ok = true;
            } else if (err.empty()) err = "?";
            if (c) c->Release();
        }
    }
    LeaveCriticalSection(CompileLock());
    return ok;
}

// The startup compile (Noah 2026-11-22: "at the startup loading screen"). Frame generation also draws with the
// effect set MakeShaders makes, so those are compiled here too (keep this list in step with MakeShaders in gfx.inc);
// a missing name only means that shader compiles when it is first needed, as before.
static volatile LONG g_fgPreState = 0;  // 0 not started, 1 compiling, 2 done
static volatile LONG g_fgPreFails = 0;
static double g_fgPreSecs = 0;
static DWORD WINAPI FgPrecompileThread(void*) {
    double t0 = FgNow();
    HMODULE dx = LoadLibraryA("d3dx9_43.dll");
    auto compile = dx ? (CompileShader_t)GetProcAddress(dx, "D3DXCompileShader") : nullptr;
    static const char* const kMain[] = {"ps_fxaa", "ps_bright", "ps_down", "ps_blur", "ps_scene", "ps_look", "ps_screen", "ps_ao",
                                        "ps_aoblur", "ps_galaxy", "ps_sky", "ps_weather", "ps_fireworks", "ps_lamps", "ps_mirror",
                                        "ps_nighttint", "ps_groundmist"};
    std::string code, err;
    if (!CachedShaderCode(compile, "vs_main", "vs_3_0", code, err)) InterlockedIncrement(&g_fgPreFails);
    for (const char* fn : kMain) if (!CachedShaderCode(compile, fn, "ps_3_0", code, err)) InterlockedIncrement(&g_fgPreFails);
    for (int i = 5; i <= 14; ++i) {
        char fn[16];
        wsprintfA(fn, "ps_sky%d", i);
        if (!CachedShaderCode(compile, fn, "ps_3_0", code, err)) InterlockedIncrement(&g_fgPreFails);
    }
    for (const char* fn : kFgNames) if (!FgCode(compile, fn, code, err)) InterlockedIncrement(&g_fgPreFails);
    g_fgPreSecs = FgNow() - t0;
    InterlockedExchange(&g_fgPreState, 2);
    return 0;
}

static bool FgShader(IDirect3DDevice9* dev, CompileShader_t compile, const char* fn, IDirect3DPixelShader9** out) {
    std::string code, err;
    if (!FgCode(compile, fn, code, err)) {
        mmenu::Log("gfx: frame generation shader %s failed to compile: %s", fn, err.c_str());
        return false;
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
    FgReadShow();
    CardCheck(dev);
    if (!g_dx) g_dx = LoadLibraryA("d3dx9_43.dll");
    auto compile = g_dx ? (CompileShader_t)GetProcAddress(g_dx, "D3DXCompileShader") : nullptr;
    IDirect3DPixelShader9** outs[] = {&g_fgCopy, &g_fgLuma, &g_fgSearch0, &g_fgSearch1, &g_fgSmooth, &g_fgMake};
    bool ok = g_cardSM3;
    if (!ok) mmenu::Log("gfx: frame generation needs shader model 3.0");
    for (int i = 0; ok && i < 6; ++i) if (!FgShader(dev, compile, kFgNames[i], outs[i])) ok = false;
    if (!ok) {
        for (auto o : outs) if (*o) { (*o)->Release(); *o = nullptr; }
        g_fgDead = true;
        mmenu::Log("gfx: frame generation off on this card (the game itself is unchanged)");
        return false;
    }
    g_fgShadersOk = true;
    mmenu::Log("gfx: frame generation shaders ready");
    return true;
}
// EndFrame, every frame: start the background compile on the first frame, and load the shaders onto the card as
// soon as it is done (still during startup)
static void FgStartup(IDirect3DDevice9* dev) {
    if (g_fgPreState == 0) {
        g_fgPreState = 1;
        HANDLE h = CreateThread(nullptr, 0, FgPrecompileThread, nullptr, 0, nullptr);
        if (h) { CloseHandle(h); mmenu::Log("gfx: frame generation: preparing shaders in the background"); }
        else { g_fgPreState = 2; mmenu::Log("gfx: frame generation: background shader compile could not start (they compile when first needed)"); }
        return;
    }
    if (g_fgPreState == 2 && !g_fgShadersTried) {
        mmenu::Log("gfx: frame generation: startup shader compile done in %.1f s%s", g_fgPreSecs,
                   g_fgPreFails ? " (some failed; those are tried again when needed)" : "");
        FgMakeShaders(dev);
    }
}

// ---- textures (D3DPOOL_DEFAULT: freed at every device reset) ----
static IDirect3DTexture9 *g_fgS[2] = {}, *g_fgF = nullptr, *g_fgL[2][4] = {}, *g_fgV[4] = {}, *g_fgVt = nullptr, *g_fgVp = nullptr;
static UINT g_fgW = 0, g_fgH = 0, g_fgLw[4] = {}, g_fgLh[4] = {};
static bool g_fgHave[2] = {};
static DWORD g_fgSeq[2] = {};
static int g_fgCur = 0;             // slot of the newest 3D picture
static bool g_fgSceneThis = false;  // the 3D picture of this frame was copied at the HUD boundary
static bool g_fgVpValid = false;    // g_fgVp holds the motion of the frame pair right before this one

static void FgRecFree();   // the debugger's surfaces (below)
static void FgQueryFree();
static void FgFree() {
    FgRecFree();
    FgQueryFree();
    IDirect3DTexture9** all[] = {&g_fgS[0], &g_fgS[1], &g_fgF, &g_fgL[0][0], &g_fgL[0][1], &g_fgL[0][2], &g_fgL[0][3],
                                 &g_fgL[1][0], &g_fgL[1][1], &g_fgL[1][2], &g_fgL[1][3], &g_fgV[0], &g_fgV[1], &g_fgV[2], &g_fgV[3],
                                 &g_fgVt, &g_fgVp};
    for (auto p : all) if (*p) { (*p)->Release(); *p = nullptr; }
    g_fgW = g_fgH = 0;
    g_fgHave[0] = g_fgHave[1] = false;
    g_fgSceneThis = false;
    g_fgVpValid = false;
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
    ok = ok && rt(g_fgLw[0], g_fgLh[0], &g_fgVt) && rt(g_fgLw[0], g_fgLh[0], &g_fgVp);
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

// ---- status ----
// gfx_framegen (Noah 2026-11-21 "we should be able to select common hz"): 0 off, 1 auto (the monitor's rate), 2 120 Hz,
// 3 144 Hz, 4 165 Hz, 5 180 Hz, 6 240 Hz. A picked rate above the monitor's is capped to the monitor (frames it can't
// show would only block). Below the monitor's rate it shows a frame every 2nd (3rd...) refresh, the nearest even
// split, so every frame stays on screen equally long.
static const int kFgRates[] = {0, 0, 120, 144, 165, 180, 240};
static int g_fgRate = 0;            // frames shown per second (0 = not running)
static int g_fgGap = 1;             // monitor refreshes per shown frame
static int g_fgRefresh = 0, g_fgModeH = 0;
static double g_fgPhase = 0;        // where the first frame of the next real frame falls (0..1 of a real frame)
static float g_fgPlan[5];           // t of each frame of this real frame (1 = the real frame itself)
static int g_fgPlanN = 0;
static const char* g_fgWhy = "";    // why it isn't generating right now (logged when it changes)
static double g_fgLast = 0, g_fgGapAvg = 1.0 / 60, g_fgPauseUntil = 0;
static int g_fgSlow = 0;
static bool g_fgGenNow = false;     // bb holds a generated frame (the game's Present shows it)
static bool g_fgInEnd = false;      // inside EndFrame: our own BeginScene calls are not the next frame
static LONG g_fgBsCount = 0;
static int g_fgTicks = 0;
static int g_fgStats[5] = {};       // in-between frames shown, real frames shown, ticks with no room, camera cuts, late safety flushes
static int g_fgIvStats[3] = {};     // frames on their own refresh, frames that shared a refresh (one not seen), refreshes that repeated a frame

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
    int gap = 1;
    if (rate >= 100 && r > 0) {
        gap = (int)((double)r / rate + 0.5);
        if (gap < 1) gap = 1;
        while (gap < 8 && (r + gap / 2) / gap > 240) ++gap;
        rate = (r + gap / 2) / gap;
        int m60 = (rate + 30) / 60 * 60;
        if (abs(rate - m60) <= 3) rate = m60;  // 119/121 Hz monitors: 2 frames per real frame, locked to the refresh
    }
    if (rate < 100) rate = 0;
    if (g_fgTestMult) { rate = 60 * g_fgTestMult; gap = 1; }
    if (r != g_fgRefresh || rate != g_fgRate || gap != g_fgGap)
        mmenu::Log("gfx: frame generation: monitor %d Hz, picked %s%d Hz -> showing %d frames a second%s", r,
                   pick >= 2 ? "" : "auto ", want, rate ? rate : 60, gap > 1 ? (gap == 2 ? " (every 2nd refresh)" : " (every few refreshes)") : "");
    if (rate != g_fgRate) g_fgPhase = 0;
    g_fgRefresh = r;
    g_fgModeH = (int)dm.Height;
    g_fgRate = rate;
    g_fgGap = gap;
}
static int g_fgPickWas = -1;
static bool g_fgPresentKnown = false, g_fgWindowed = false, g_fgImmediate = false;  // the device's present settings (AdjustPP)
static bool g_fgForcedImm = false;  // ... and frame generation changed the game's window present setting
static DWORD g_fgInterval = 0;      // the device's present interval
static bool g_fgFsAsked = false;    // fullscreen reset asked once for a faster refresh
static bool g_fgBsThis = false;     // the game's first BeginScene of this frame was seen
static double g_fgBegin = 0;        // ... and when (the game starts drawing a tick)
static double g_fgPresentDone = 0;  // when the last real frame's presents were all done
static double g_fgLogicEst = 0.002; // shortest time from that to the next BeginScene: about the game's own update time

// the frame times of this real frame on one even grid of 1/rate s across real frames
static void FgMakePlan() {
    double s = 60.0 / g_fgRate, t = g_fgPhase;
    if (t <= 1e-4 || t > s + 1e-4) t = s;
    g_fgPlanN = 0;
    while (t < 1 - 1e-3 && g_fgPlanN < 4) { g_fgPlan[g_fgPlanN++] = (float)t; t += s; }
    if (t <= 1 + 1e-3 && g_fgPlanN < 5) { g_fgPlan[g_fgPlanN++] = 1.0f; t += s; }  // the real frame falls on the grid
    g_fgPhase = t - 1;
}

// camera cut: a jump this big in 1/60 s (respawn, replay, menu camera, level change) has no motion to fill in
static D3DMATRIX g_fgViewPrev = {};
static bool g_fgViewHave = false;
static bool FgCameraCut(const D3DMATRIX& m) {
    auto pos = [](const D3DMATRIX& v, float* c) {
        for (int j = 0; j < 3; ++j) c[j] = -(v._41 * v.m[j][0] + v._42 * v.m[j][1] + v._43 * v.m[j][2]);
    };
    bool cut = false;
    float fa2 = m._13 * m._13 + m._23 * m._23 + m._33 * m._33;
    if (g_fgViewHave) {
        const D3DMATRIX& q = g_fgViewPrev;
        float fb2 = q._13 * q._13 + q._23 * q._23 + q._33 * q._33;
        if (fa2 > 0.5f && fb2 > 0.5f) {  // both real cameras
            float a[3], b[3];
            pos(m, a); pos(q, b);
            float dx = a[0] - b[0], dy = a[1] - b[1], dz = a[2] - b[2];
            float dot = (m._13 * q._13 + m._23 * q._23 + m._33 * q._33) / sqrtf(fa2 * fb2);
            cut = dx * dx + dy * dy + dz * dz > 300.0f * 300.0f || dot < 0.94f;
        }
    }
    g_fgViewPrev = m;
    g_fgViewHave = true;
    return cut;
}

// The game's Present (via EndFrame, before RunScreen): keep this frame back and put the first in-between frame
// in the back buffer. Returns true when it did.
static void FgDraw(IDirect3DDevice9* dev, IDirect3DSurface9* bb, int prev, int cur, float t, bool search);
static const char* g_fgNoPair = "off";  // why this tick shows no in-between frames (the debugger's sheet)
static bool FgFrame(IDirect3DDevice9* dev) {
    g_fgNoPair = "off";
    g_fgGenNow = false;
    g_fgBbGenerated = false;
    g_fgPlanN = 0;
    double now = FgNow();
    double gap = g_fgLast ? now - g_fgLast : 1.0 / 60;
    g_fgLast = now;
    g_fgGapAvg = g_fgGapAvg * 0.95 + gap * 0.05;
    bool sceneThis = g_fgSceneThis;
    g_fgSceneThis = false;
    bool cut = FgCameraCut(g_view);
    if (!FgOn()) {
        g_fgRunning = false;
        g_fgHave[0] = g_fgHave[1] = false;
        g_fgBsThis = false;
        if (V("gfx_framegen")) FgWhy("off: not available on this card");
        else if (*g_fgWhy) FgWhy("off");
        if (V("gfx_framegen") == 0 && g_fgPresentKnown && g_fgForcedImm) {  // turned off: the game's own window present setting back
            g_fgPresentKnown = false;
            mmenu::Log("gfx: frame generation off: resetting the device to give the game its own present setting back");
            *(volatile BYTE*)0x786AB4 = 1;
        }
        return false;
    }
    g_fgBsThis = false;
    auto stop = [&](const char* why) { g_fgRunning = false; g_fgHave[0] = g_fgHave[1] = false; if (why) FgWhy(why); g_fgNoPair = "not running"; return false; };
    if (g_reshadeLoaded) return stop("off: ReShade is loaded");
    if (V("gfx_framegen") != g_fgPickWas) { g_fgPickWas = V("gfx_framegen"); g_fgRefresh = 0; g_fgFsAsked = false; }  // a new pick: check again now
    if (g_fgPresentKnown && g_fgWindowed && !g_fgImmediate) {  // turned on in a window: reset once so presents stop waiting
        g_fgPresentKnown = false;
        mmenu::Log("gfx: frame generation: resetting the device so window presents don't wait for the monitor");
        *(volatile BYTE*)0x786AB4 = 1;
    }
    FgCheckRefresh(dev);
    if (g_fgRate < 100) {
        if (g_fgPresentKnown && !g_fgWindowed && !g_fgFsAsked) {  // true fullscreen turned on mid-game: ask for the fastest refresh
            g_fgFsAsked = true;
            g_fgPresentKnown = false;
            mmenu::Log("gfx: frame generation: resetting the device to ask for the monitor's fastest refresh");
            *(volatile BYTE*)0x786AB4 = 1;
        }
        return stop("off: monitor is 60 Hz or slower");
    }
    if (g_presents > 600 && g_fgBsCount == 0) { g_fgDead = true; return stop("off: the game never calls BeginScene"); }
    // the game running below 60: never make it worse
    if (now < g_fgPauseUntil) return stop(nullptr);
    if (g_fgGapAvg > 1.0 / 52) {
        if (++g_fgSlow > 120) {
            g_fgSlow = 0;
            g_fgPauseUntil = now + 10;
            mmenu::Log("gfx: frame generation paused for 10 s: the game is running below 60 (%.1f fps)", 1.0 / g_fgGapAvg);
            return stop(nullptr);
        }
    } else g_fgSlow = 0;
    IDirect3DSurface9* bb = nullptr;
    if (FAILED(dev->GetBackBuffer(0, 0, D3DBACKBUFFER_TYPE_MONO, &bb)) || !bb) return stop(nullptr);
    D3DSURFACE_DESC d;
    bb->GetDesc(&d);
    if (!FgReady(dev, d.Width, d.Height)) { bb->Release(); return stop(nullptr); }
    int n = g_fgCur ^ 1, p = g_fgCur;
    IDirect3DSurface9 *sF = FgSurf(g_fgF), *sS = FgSurf(g_fgS[n]);
    bool ok = sF && sS && SUCCEEDED(dev->StretchRect(bb, nullptr, sF, nullptr, D3DTEXF_NONE));
    if (ok && !sceneThis) ok = SUCCEEDED(dev->StretchRect(bb, nullptr, sS, nullptr, D3DTEXF_NONE));  // no HUD boundary this frame
    if (sF) sF->Release();
    if (sS) sS->Release();
    if (!ok) { bb->Release(); return stop(nullptr); }
    g_fgCur = n;
    g_fgHave[n] = true;
    g_fgSeq[n] = g_presents;
    // a pair = this frame and the one right before it, on time, with no camera cut between them. Without one
    // (first frame, a skipped or late tick, a cut) only the pyramid is built and the real frame goes out now.
    bool pair = g_fgHave[p] && g_fgSeq[p] + 1 == g_presents && gap < 1.5 / 60;
    g_fgNoPair = !g_fgHave[p] ? "first frame" : g_fgSeq[p] + 1 != g_presents ? "skipped tick" : gap >= 1.5 / 60 ? "late tick" : cut ? "camera cut" : "";
    if (pair && cut) { ++g_fgStats[3]; pair = false; }
    if (pair) FgMakePlan();
    pair = pair && g_fgPlanN >= 1 && g_fgPlan[0] < 1.0f;
    if (!pair) { g_fgPlanN = 0; g_fgPhase = 0; }
    FgDraw(dev, bb, p, n, pair ? g_fgPlan[0] : 0.0f, true);
    if (!pair) g_fgVpValid = false;
    g_fgRunning = true;
    if (pair) { g_fgGenNow = true; g_fgBbGenerated = true; FgWhy("on"); }
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
    for (DWORD sm = 2; sm <= 3; ++sm) {  // vectors (s2) and last frame's vectors / the full frame (s3): exact texels
        dev->SetSamplerState(sm, D3DSAMP_MINFILTER, D3DTEXF_POINT);
        dev->SetSamplerState(sm, D3DSAMP_MAGFILTER, D3DTEXF_POINT);
    }
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
                float a[4] = {1.0f / g_fgLw[k + 1], 1.0f / g_fgLh[k + 1], 1.0f / (float)(1 << k), g_fgVpValid ? 1.0f : 0.0f};
                dev->SetPixelShaderConstantF(90, a, 1);
                s = FgSurf(g_fgV[k]);
                Pass(dev, g_fgSearch1, s, g_fgLw[k], g_fgLh[k], g_fgLw[k], g_fgLh[k], g_fgL[prev][k], g_fgL[cur][k], g_fgV[k + 1],
                     g_fgVpValid ? g_fgVp : nullptr);
                if (s) s->Release();
            }
            for (int r = 0; r < 2; ++r) {  // V0 -> Vt -> Vp (Vp: this frame's final vectors, and next frame's guess)
                IDirect3DTexture9 *src = r ? g_fgVt : g_fgV[0], *dst = r ? g_fgVp : g_fgVt;
                s = FgSurf(dst);
                Pass(dev, g_fgSmooth, s, g_fgLw[0], g_fgLh[0], g_fgLw[0], g_fgLh[0], g_fgL[prev][0], g_fgL[cur][0], src);
                if (s) s->Release();
            }
            g_fgVpValid = true;
        }
    }
    if (t > 0) {
        float a[4] = {1.0f / g_fgLw[0], 1.0f / g_fgLh[0], (float)g_fgLw[0], (float)g_fgLh[0]}, b[4] = {t, g_fgDebugView ? 1.0f : 0.0f, 0, 0};
        dev->SetPixelShaderConstantF(90, a, 1);
        dev->SetPixelShaderConstantF(91, b, 1);
        Pass(dev, g_fgMake, bb, w, h, w, h, g_fgS[prev], g_fgS[cur], g_fgVp, g_fgF);
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

// ---- refresh timing ----
// One refresh = one frame. Refresh k (counted from the performance counter's zero) starts at vb + (k - kb) * per.
struct FgVb { bool ok; double vb, per; };
typedef HRESULT(WINAPI* DwmTiming_t)(HWND, void*);
static int g_fgVbSrc = -1;          // 0 the clock, 1 Windows (window), 2 the card's scan line, 3 v-sync (true fullscreen)
static bool g_fgRaster = false, g_fgRasterKnown = false;
static FgVb FgVblankInfo(IDirect3DDevice9* dev) {
    FgVb r = {false, 0, 0};
    int src = 0;
    double want = g_fgRefresh > 0 ? 1.0 / g_fgRefresh : 0;
    if (g_fgTestMult || want <= 0) src = 0;
    else if (!g_fgWindowed && g_fgInterval != D3DPRESENT_INTERVAL_IMMEDIATE) src = 3;
    else {
        static DwmTiming_t dwm = nullptr;
        static bool tried = false;
        if (!tried) {
            tried = true;
            HMODULE m = LoadLibraryA("dwmapi.dll");
            if (m) dwm = (DwmTiming_t)GetProcAddress(m, "DwmGetCompositionTimingInfo");
        }
        if (dwm && g_fgWindowed) {
            BYTE buf[292] = {};  // DWM_TIMING_INFO (packed): cbSize, rateRefresh, qpcRefreshPeriod @12, rateCompose, qpcVBlank @28, ...
            *(UINT32*)buf = sizeof buf;
            if (SUCCEEDED(dwm(nullptr, buf))) {
                ULONGLONG per = *(ULONGLONG*)(buf + 12), vb = *(ULONGLONG*)(buf + 28);
                UINT32 num = *(UINT32*)(buf + 4), den = *(UINT32*)(buf + 8);
                double p = (double)per / FgFreq();
                static double keep = 0;  // one fixed period: refresh numbers must stay the same from call to call
                if (per && vb && fabs(p - want) < want * 0.05) {
                    if (keep <= 0 || fabs(p - keep) > keep * 0.01) {
                        keep = p;
                        mmenu::Log("gfx: frame generation: Windows reports the refresh as %u/%u Hz (%.4f ms)", num, den, p * 1000.0);
                    }
                    r.ok = true; r.vb = (double)vb / FgFreq(); r.per = keep; src = 1;
                }
            }
        }
        if (!r.ok) {
            if (!g_fgRasterKnown) {
                D3DCAPS9 c = {};
                g_fgRaster = SUCCEEDED(dev->GetDeviceCaps(&c)) && (c.Caps & D3DCAPS_READ_SCANLINE);
                g_fgRasterKnown = true;
            }
            D3DRASTER_STATUS rs = {};
            if (g_fgRaster && g_fgModeH > 0 && SUCCEEDED(dev->GetRasterStatus(0, &rs))) {
                double ph = rs.InVBlank ? 0.99 : (double)rs.ScanLine / g_fgModeH;
                if (ph > 0.99) ph = 0.99;
                r.ok = true; r.vb = FgNow() - ph * want; r.per = want; src = 2;
            }
        }
    }
    if (src != g_fgVbSrc) {
        static const char* kSrc[] = {"spaced by the clock (no refresh timing here)", "locked to the monitor's refresh (Windows' timing)",
                                     "locked to the monitor's refresh (the card's scan line)", "shown one per refresh by v-sync (true fullscreen)"};
        mmenu::Log("gfx: frame generation timing: frames %s", kSrc[src]);
        g_fgVbSrc = src;
    }
    return r;
}
static long long FgIv(const FgVb& v, double t, double* ph) {
    double x = (t - v.vb) / v.per + floor(v.vb / v.per);
    long long iv = (long long)floor(x);
    if (ph) *ph = x - (double)iv;
    return iv;
}
static double FgIvStart(const FgVb& v, long long iv) { return v.vb + ((double)iv - floor(v.vb / v.per)) * v.per; }
static void FgWaitUntil(double t) { while (FgNow() < t) Sleep(0); }  // the game's own wait does the same (Sleep(0) spin)

// which refresh each frame really went to (just before its Present), for the log
static long long g_fgShownIv = -1;
static void FgNoteShown(IDirect3DDevice9* dev) {
    if (!g_fgRunning || (g_fgVbSrc != 1 && g_fgVbSrc != 2)) { g_fgShownIv = -1; return; }
    FgVb v = FgVblankInfo(dev);
    if (!v.ok) { g_fgShownIv = -1; return; }
    long long iv = FgIv(v, FgNow(), nullptr);
    if (g_fgShownIv >= 0) {
        long long d = iv - g_fgShownIv;
        if (d <= 0) ++g_fgIvStats[1];
        else if (d < 8 * g_fgGap) { ++g_fgIvStats[0]; if (d > g_fgGap) g_fgIvStats[2] += (int)(d / g_fgGap) - 1; }
    }
    g_fgShownIv = iv;
}

// ---- waiting for the card: a frame is presented only once the card has finished drawing it, so its refresh is
// decided by when we present it, not by how busy the card is (event queries exist on every D3D9 card; if one
// can't be made, frames aren't waited for)
static IDirect3DQuery9* g_fgQuery = nullptr;
static bool g_fgQueryTried = false;
static void FgQueryFree() { if (g_fgQuery) { g_fgQuery->Release(); g_fgQuery = nullptr; } g_fgQueryTried = false; }
static double FgGpuWait(IDirect3DDevice9* dev) {
    if (!g_fgQueryTried) {
        g_fgQueryTried = true;
        if (FAILED(dev->CreateQuery(D3DQUERYTYPE_EVENT, &g_fgQuery)) || !g_fgQuery) {
            g_fgQuery = nullptr;
            static bool said = false;
            if (!said) { said = true; mmenu::Log("gfx: frame generation: no event query on this card (frames aren't waited for)"); }
        }
    }
    if (!g_fgQuery) return 0;
    double t0 = FgNow();
    if (FAILED(g_fgQuery->Issue(D3DISSUE_END))) return 0;
    while (g_fgQuery->GetData(nullptr, 0, D3DGETDATA_FLUSH) == S_FALSE && FgNow() - t0 < 0.02) Sleep(0);
    return FgNow() - t0;
}

// ---- the debugger (Noah 2026-11-22: "create a debugger so you can see whats happening, im seeing flashing now") ----
// Shift+F11 (or a file dadmod\fgdebug.txt) records the next 120 frames that go to the screen, exactly as presented,
// at half size, then saves them as PNGs plus frames.csv (time, kind, t, which refresh it was aimed at and which it
// got, card wait, our wait) to dadmod\fgdebug\<date_time>\. The game pauses for a few seconds while it saves.
static const int kFgRecN = 120;
static IDirect3DSurface9* g_fgRec[kFgRecN] = {};
struct FgRecRow { double tm, phase, gpu, wait; long long ivWant, ivReal; float t; int kind, tick, src; const char* why; };
static FgRecRow g_fgRecRow[kFgRecN];
static int g_fgRecI = -1;
static UINT g_fgRecW = 0, g_fgRecH = 0;
static D3DFORMAT g_fgRecFmt = D3DFMT_X8R8G8B8;  // the back buffer's own format (as screenshots do)
static bool g_fgRecAsk = false;
static const char* const kFgKind[] = {"real_nofg", "gen_first", "gen", "real", "real_noroom"};
static void FgDebugAsk() { g_fgRecAsk = true; }
static std::string g_fgRecDir;      // the last recording's folder
static bool g_fgSnapAsk = false;    // after a recording: save the next made-up frame's inputs at full size
static void FgSaveSurf(IDirect3DDevice9* dev, IDirect3DSurface9* src, const std::string& path) {
    if (!src) return;
    if (!g_dx) g_dx = LoadLibraryA("d3dx9_43.dll");
    auto save = g_dx ? (SaveSurface_t)GetProcAddress(g_dx, "D3DXSaveSurfaceToFileW") : nullptr;
    if (!save) return;
    D3DSURFACE_DESC d;
    src->GetDesc(&d);
    IDirect3DSurface9 *plain = nullptr, *mem = nullptr;
    if (FAILED(dev->CreateRenderTarget(d.Width, d.Height, d.Format, D3DMULTISAMPLE_NONE, 0, FALSE, &plain, nullptr))) return;
    if (SUCCEEDED(dev->StretchRect(src, nullptr, plain, nullptr, D3DTEXF_NONE)) &&
        SUCCEEDED(dev->CreateOffscreenPlainSurface(d.Width, d.Height, d.Format, D3DPOOL_SYSTEMMEM, &mem, nullptr)) &&
        SUCCEEDED(dev->GetRenderTargetData(plain, mem))) {
        wchar_t wpath[1024];
        if (MultiByteToWideChar(CP_ACP, 0, path.c_str(), -1, wpath, 1024) > 0) save(wpath, 3 /*D3DXIFF_PNG*/, mem, nullptr, nullptr);
    }
    if (mem) mem->Release();
    plain->Release();
}
static void FgSaveTex(IDirect3DDevice9* dev, IDirect3DTexture9* t, const std::string& path) {
    IDirect3DSurface9* s = FgSurf(t);
    FgSaveSurf(dev, s, path);
    if (s) s->Release();
}
// the 3D pictures (before/after), the whole held-back frame, the luma, the motion vectors (RGBA = x hi, x lo,
// y hi, y lo; 128,0 = 0) and the made-up frame itself, full size
static void FgSnap(IDirect3DDevice9* dev) {
    g_fgSnapAsk = false;
    if (g_fgRecDir.empty()) return;
    int p = g_fgCur ^ 1, c = g_fgCur;
    FgSaveTex(dev, g_fgS[p], g_fgRecDir + "\\snap_scene_before.png");
    FgSaveTex(dev, g_fgS[c], g_fgRecDir + "\\snap_scene_after.png");
    FgSaveTex(dev, g_fgF, g_fgRecDir + "\\snap_full_frame_after.png");
    FgSaveTex(dev, g_fgL[p][0], g_fgRecDir + "\\snap_luma_before.png");
    FgSaveTex(dev, g_fgL[c][0], g_fgRecDir + "\\snap_luma_after.png");
    FgSaveTex(dev, g_fgVp, g_fgRecDir + "\\snap_vectors.png");
    IDirect3DSurface9* bb = nullptr;
    if (SUCCEEDED(dev->GetBackBuffer(0, 0, D3DBACKBUFFER_TYPE_MONO, &bb)) && bb) {
        FgSaveSurf(dev, bb, g_fgRecDir + "\\snap_made_up_frame.png");
        bb->Release();
    }
    mmenu::Log("gfx: frame generation debugger: saved one made-up frame's inputs (snap_*.png) to %s", g_fgRecDir.c_str());
}
static void FgRecFree() {
    for (auto& r : g_fgRec) if (r) { r->Release(); r = nullptr; }
    g_fgRecI = -1;
}
static void FgRecStart(IDirect3DDevice9* dev) {
    g_fgRecAsk = false;
    if (g_fgRecI >= 0) return;
    IDirect3DSurface9* bb = nullptr;
    if (FAILED(dev->GetBackBuffer(0, 0, D3DBACKBUFFER_TYPE_MONO, &bb)) || !bb) return;
    D3DSURFACE_DESC d;
    bb->GetDesc(&d);
    bb->Release();
    g_fgRecW = d.Width / 2 ? d.Width / 2 : 1;
    g_fgRecH = d.Height / 2 ? d.Height / 2 : 1;
    g_fgRecFmt = d.Format;
    for (int i = 0; i < kFgRecN; ++i) {
        HRESULT hr = dev->CreateRenderTarget(g_fgRecW, g_fgRecH, g_fgRecFmt, D3DMULTISAMPLE_NONE, 0, FALSE, &g_fgRec[i], nullptr);
        if (FAILED(hr) || !g_fgRec[i]) {
            g_fgRec[i] = nullptr;
            FgRecFree();
            mmenu::Log("gfx: frame generation debugger: not enough video memory to record (hr 0x%08lX)", hr);
            return;
        }
    }
    g_fgRecI = 0;
    mmenu::Log("gfx: frame generation debugger: recording the next %d frames shown", kFgRecN);
}
static void FgRecSave(IDirect3DDevice9* dev) {
    if (!g_dx) g_dx = LoadLibraryA("d3dx9_43.dll");
    auto save = g_dx ? (SaveSurface_t)GetProcAddress(g_dx, "D3DXSaveSurfaceToFileW") : nullptr;
    SYSTEMTIME st;
    GetLocalTime(&st);
    char sub[64];
    snprintf(sub, sizeof sub, "fgdebug\\%04d%02d%02d_%02d%02d%02d", st.wYear, st.wMonth, st.wDay, st.wHour, st.wMinute, st.wSecond);
    CreateDirectoryA(ExeDirFile("fgdebug").c_str(), nullptr);
    std::string dir = ExeDirFile(sub);
    CreateDirectoryA(dir.c_str(), nullptr);
    IDirect3DSurface9* mem = nullptr;
    dev->CreateOffscreenPlainSurface(g_fgRecW, g_fgRecH, g_fgRecFmt, D3DPOOL_SYSTEMMEM, &mem, nullptr);
    std::string csv = "frame,ms,kind,t,refresh_aimed,refresh_got,phase_in_refresh,card_wait_ms,our_wait_ms,timing,tick,no_frames_because\n";
    static const char* kSrc[] = {"clock", "windows", "scanline", "vsync"};
    const FgRecRow& r0 = g_fgRecRow[0];
    int saved = 0;
    for (int i = 0; i < kFgRecN; ++i) {
        const FgRecRow& r = g_fgRecRow[i];
        char line[320];
        long long base = r0.ivReal >= 0 ? r0.ivReal : 0;
        snprintf(line, sizeof line, "%d,%.2f,%s,%.3f,%lld,%lld,%.2f,%.2f,%.2f,%s,%d,%s\n", i, (r.tm - r0.tm) * 1000.0, kFgKind[r.kind], r.t,
                 r.ivWant >= 0 ? r.ivWant - base : -1, r.ivReal >= 0 ? r.ivReal - base : -1, r.phase, r.gpu * 1000.0, r.wait * 1000.0,
                 r.src >= 0 && r.src <= 3 ? kSrc[r.src] : "?", r.tick, r.why ? r.why : "");
        csv += line;
        if (save && mem && g_fgRec[i] && SUCCEEDED(dev->GetRenderTargetData(g_fgRec[i], mem))) {
            char name[96];
            snprintf(name, sizeof name, "\\%03d_%s_t%.2f.png", i, kFgKind[r.kind], r.t);
            std::string path = dir + name;
            wchar_t wpath[1024];
            if (MultiByteToWideChar(CP_ACP, 0, path.c_str(), -1, wpath, 1024) > 0 && SUCCEEDED(save(wpath, 3 /*D3DXIFF_PNG*/, mem, nullptr, nullptr))) ++saved;
        }
    }
    WriteWholeFile(dir + "\\frames.csv", csv);
    if (mem) mem->Release();
    FgRecFree();
    g_fgRecDir = dir;
    g_fgSnapAsk = true;
    mmenu::Log("gfx: frame generation debugger: saved %d frames + frames.csv to %s", saved, dir.c_str());
    snprintf(g_shotMsg, sizeof g_shotMsg, "Frame generation recording saved: dadmod\\%s", sub);
    g_shotMsgUntil = GetTickCount() + 600;
}
// right before every Present (the game's and ours): kind 0 real frame with no in-between frames, 1 the first
// in-between frame (the game's Present), 2 a later in-between frame, 3 the real frame after them, 4 real frame
// shown instead because there was no room
static void FgRec(IDirect3DDevice9* dev, int kind, float t, long long ivWant, double gpu, double wait) {
    if (g_fgRecAsk) FgRecStart(dev);
    if (g_fgRecI < 0) return;
    IDirect3DSurface9* bb = nullptr;
    if (SUCCEEDED(dev->GetBackBuffer(0, 0, D3DBACKBUFFER_TYPE_MONO, &bb)) && bb) {
        dev->StretchRect(bb, nullptr, g_fgRec[g_fgRecI], nullptr, D3DTEXF_LINEAR);
        bb->Release();
    }
    FgRecRow& r = g_fgRecRow[g_fgRecI];
    r.tm = FgNow();
    FgVb v = FgVblankInfo(dev);
    r.phase = -1;
    r.ivReal = v.ok ? FgIv(v, r.tm, &r.phase) : -1;
    r.ivWant = ivWant;
    r.t = t; r.kind = kind; r.gpu = gpu; r.wait = wait; r.tick = g_fgTicks; r.src = g_fgVbSrc;
    r.why = kind == 0 ? g_fgNoPair : "";
    if (++g_fgRecI == kFgRecN) FgRecSave(dev);
}

// ---- the frames of one real frame ----
struct FgItem { double due; float t; long long iv; };  // t < 0: the real frame
static FgItem g_fgQ[5];
static int g_fgQn = 0, g_fgQi = 0;
static double g_fgDue[5];
static IDirect3DDevice9* g_fgDev = nullptr;
static IDirect3DSwapChain9* g_fgSc = nullptr;  // the game presents through its swap chain (else the device)
static RECT g_fgRa, g_fgRb;
static bool g_fgHasA = false, g_fgHasB = false;
static HWND g_fgWnd = nullptr;
static DWORD g_fgFlags = 0;
static long long g_fgLastIv = -1;   // the refresh the last frame of the previous real frame was aimed at

static void NoteDeviceLost(HRESULT hr);  // gfx.inc
static void FgClear() { g_fgQn = g_fgQi = 0; }
static void FgRun(bool late);

// HookPresent, after EndFrame, right before the game's Present: pick the refresh for each frame of this real frame
// and hold the game's Present (the first in-between frame) until its refresh starts. If they don't all fit before
// the game would skip its next render, show only the real frame now (2026-11-22: the real frame used to go out
// right behind the in-between frame, which was then never seen).
static long long g_fgIv0 = -1;      // the refresh the first frame of this real frame is aimed at
static void FgBeforePresent(IDirect3DDevice9* dev) {
    if (!g_fgGenNow) { FgNoteShown(dev); FgRec(dev, 0, 1.0f, -1, 0, 0); return; }
    double gpu = FgGpuWait(dev);  // the game's frame (and our first in-between frame) finished on the card
    double now = FgNow();
    double begin = g_fgBegin > 0 && g_fgBegin <= now ? g_fgBegin : now;
    // a tick that starts 1.5 ticks behind its schedule skips its render (0x44EEF0); the schedule's next tick is at
    // most begin - (the game's update time) + 1/60. Stay 2 ms clear of the skip.
    double slack = 0.5 / 60 - 0.002 - g_fgLogicEst;
    if (slack < -0.0015) slack = -0.0015;
    double deadline = begin + 1.0 / 60 + slack;
    int n = g_fgPlanN;
    FgVb v = FgVblankInfo(dev);
    long long iv0 = -1;
    if (v.ok) {
        // The frame is finished on the card (FgGpuWait), so it can go out anywhere inside a refresh except right
        // at its edges, where the compositor takes the picture. Go now if we can (2026-11-22 recording: holding
        // the game's frame to mid-refresh delayed the game, its frames drifted, and every ~7th real frame had
        // no room); the frames after it follow at exactly one refresh (or gap) each.
        double ph;
        long long iv = FgIv(v, now, &ph);
        iv0 = iv;
        double t0 = now;
        if (ph < 0.05) t0 = FgIvStart(v, iv) + 0.05 * v.per;
        else if (ph > 0.95) { iv0 = iv + 1; t0 = FgIvStart(v, iv0) + 0.05 * v.per; }
        if (g_fgLastIv >= 0 && iv0 < g_fgLastIv + g_fgGap && g_fgLastIv - iv0 < 8) {  // the previous frame still owns this refresh
            iv0 = g_fgLastIv + g_fgGap;
            t0 = FgIvStart(v, iv0) + 0.05 * v.per;
        }
        for (int j = 0; j < n; ++j) g_fgDue[j] = t0 + j * g_fgGap * v.per;
    } else if (g_fgVbSrc == 3) {
        for (int j = 0; j < n; ++j) g_fgDue[j] = now;  // the card shows one per refresh
    } else {
        for (int j = 0; j < n; ++j) g_fgDue[j] = now + j / (double)g_fgRate;
    }
    if (g_fgVbSrc != 3 && g_fgDue[n - 1] > deadline) {
        ++g_fgStats[2];
        IDirect3DSurface9* bb = nullptr;
        if (SUCCEEDED(dev->GetBackBuffer(0, 0, D3DBACKBUFFER_TYPE_MONO, &bb)) && bb) {
            FgDraw(dev, bb, g_fgCur ^ 1, g_fgCur, -1.0f, false);
            bb->Release();
            g_fgGenNow = false;
            g_fgBbGenerated = false;
            RunScreen(dev);  // the screen effects on the real frame
        } else g_fgGenNow = false;
        g_fgPlanN = 0;
        g_fgPhase = 0;
        g_fgLastIv = v.ok ? FgIv(v, now, nullptr) : -1;
        FgNoteShown(dev);
        FgRec(dev, 4, 1.0f, -1, gpu, 0);
        return;
    }
    if (g_fgSnapAsk) FgSnap(dev);
    double w0 = FgNow();
    FgWaitUntil(g_fgDue[0]);
    g_fgIv0 = iv0;
    g_fgLastIv = iv0 >= 0 ? iv0 + (long long)(n - 1) * g_fgGap : -1;
    ++g_fgStats[0];
    FgNoteShown(dev);
    FgRec(dev, 1, g_fgPlan[0], iv0, gpu, FgNow() - w0);
}

// after the game's Present returned: show the rest of this real frame's frames at their times
static void FgQueueInner(IDirect3DDevice9* dev, IDirect3DSwapChain9* sc, const RECT* a, const RECT* b, HWND w, const RGNDATA* r, DWORD f, HRESULT hr) {
    if (!g_fgGenNow) return;
    g_fgGenNow = false;
    if (FAILED(hr) || r) { FgClear(); return; }
    g_fgDev = dev; g_fgSc = sc; g_fgWnd = w; g_fgFlags = f;
    g_fgHasA = a != nullptr; if (a) g_fgRa = *a;
    g_fgHasB = b != nullptr; if (b) g_fgRb = *b;
    g_fgQn = g_fgQi = 0;
    for (int j = 1; j < g_fgPlanN; ++j)
        g_fgQ[g_fgQn++] = {g_fgDue[j], g_fgPlan[j] >= 1.0f ? -1.0f : g_fgPlan[j], g_fgIv0 >= 0 ? g_fgIv0 + (long long)j * g_fgGap : -1};
    FgRun(false);
}
static void FgQueue(IDirect3DDevice9* dev, IDirect3DSwapChain9* sc, const RECT* a, const RECT* b, HWND w, const RGNDATA* r, DWORD f, HRESULT hr) {
    FgQueueInner(dev, sc, a, b, w, r, f, hr);
    g_fgBbGenerated = false;
    g_fgPresentDone = FgNow();
    if (++g_fgTicks == 600 || g_fgTicks % 36000 == 0) {
        if (g_fgStats[0] + g_fgStats[2] > 0)
            mmenu::Log("gfx: frame generation %d Hz: %d in-between frames shown, %d real frames with no room for them, %d camera cuts, "
                       "%d late flushes; refreshes: %d frames on their own refresh, %d shared a refresh (one not seen), %d refreshes showed a frame twice",
                       g_fgRate, g_fgStats[0], g_fgStats[2], g_fgStats[3], g_fgStats[4], g_fgIvStats[0], g_fgIvStats[1], g_fgIvStats[2]);
    }
}
static void FgShow(const FgItem& it, bool wait) {
    IDirect3DDevice9* dev = g_fgDev;
    IDirect3DSurface9* bb = nullptr;
    if (!dev || FAILED(dev->GetBackBuffer(0, 0, D3DBACKBUFFER_TYPE_MONO, &bb)) || !bb) { FgClear(); return; }
    FgDraw(dev, bb, g_fgCur ^ 1, g_fgCur, it.t, false);
    bb->Release();
    g_fgBbGenerated = it.t > 0;
    RunScreen(dev);  // the screen effects, FPS counter and screenshot (real frames only) on this frame too
    double gpu = FgGpuWait(dev), w0 = FgNow();
    if (wait) FgWaitUntil(it.due);
    const RECT* a = g_fgHasA ? &g_fgRa : nullptr;
    const RECT* b = g_fgHasB ? &g_fgRb : nullptr;
    FgNoteShown(dev);
    FgRec(dev, it.t > 0 ? 2 : 3, it.t > 0 ? it.t : 1.0f, it.iv, gpu, FgNow() - w0);
    bool wasIn = g_inPost;
    g_inPost = true;
    HRESULT hr = g_fgSc ? g_origSCPresent(g_fgSc, a, b, g_fgWnd, nullptr, g_fgFlags) : g_origPresent(dev, a, b, g_fgWnd, nullptr);
    g_inPost = wasIn;
    NoteDeviceLost(hr);
    if (FAILED(hr)) FgClear();
}
// late = the next frame is starting (safety only: FgQueue shows everything before it returns)
static void FgRun(bool late) {
    while (g_fgQi < g_fgQn) {
        FgItem it = g_fgQ[g_fgQi];
        bool real = it.t < 0;
        ++g_fgQi;
        if (late) ++g_fgStats[4];
        if (late && !real) continue;
        if (!real) ++g_fgStats[0];
        FgShow(it, !late);  // draws it, waits for the card, then for its refresh
    }
    FgClear();
}

typedef HRESULT(STDMETHODCALLTYPE* BeginScene_t)(IDirect3DDevice9*);
static BeginScene_t g_origBS = nullptr;
static HRESULT STDMETHODCALLTYPE HookBS(IDirect3DDevice9* dev) {
    if (!g_inPost && !g_fgInEnd) {
        InterlockedIncrement(&g_fgBsCount);
        if (!g_fgBsThis) {
            g_fgBsThis = true;
            g_fgBegin = FgNow();
            if (g_fgPresentDone > 0) {  // the game's own update time, about: the shortest gap seen lately
                double d = g_fgBegin - g_fgPresentDone;
                g_fgLogicEst += 0.00001;
                if (d >= 0 && d < g_fgLogicEst) g_fgLogicEst = d;
                if (g_fgLogicEst > 0.006) g_fgLogicEst = 0.006;
            }
        }
        if (g_fgQi < g_fgQn) FgRun(true);  // safety: anything still queued goes out before the next frame
    }
    return g_origBS(dev);
}

// AdjustPP (device create / reset). Windowed with frame generation on: presents don't wait for the monitor (the
// compositor shows them without tearing; see the top). Fullscreen (exclusive) with it on: ask for the monitor's
// fastest refresh at this resolution (borderless fullscreen uses the desktop's rate).
static void FgFullscreenRefresh(IDirect3D9* d3d, UINT adapter, D3DPRESENT_PARAMETERS* pp) {
    if (!pp) return;
    g_fgPresentKnown = true;
    g_fgWindowed = pp->Windowed != FALSE;
    g_fgImmediate = false;
    g_fgForcedImm = false;
    g_fgInterval = pp->PresentationInterval;
    g_fgLastIv = -1;
    g_fgShownIv = -1;
    if (V("gfx_framegen") == 0) return;
    if (pp->Windowed) {
        if (pp->PresentationInterval != D3DPRESENT_INTERVAL_IMMEDIATE) {
            mmenu::Log("gfx: frame generation: window presents don't wait for the monitor (the game's own pacing stays 60)%s",
                       V("gfx_vsync") == 1 ? "; the V-sync setting waits while frame generation is off (Windows still stops tearing in a window)" : "");
            g_fgForcedImm = true;
        }
        pp->PresentationInterval = D3DPRESENT_INTERVAL_IMMEDIATE;
        g_fgImmediate = true;
        g_fgInterval = pp->PresentationInterval;
        return;
    }
    if (!d3d) return;
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
