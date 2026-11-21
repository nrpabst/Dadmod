// skycompare: renders the gfx.inc sky shaders from two versions of gfx.inc with the same constants (same camera,
// same time of day, same game time) on this PC's graphics card and compares the pictures pixel by pixel.
// Made 2026-11-21 to check that shrinking the shaders for NVIDIA's slot limit changed nothing visible.
//   skycompare.exe <old gfx.inc> <new gfx.inc> <output folder>
// Prints one line per case: max and average difference (0-255 per channel) and writes old/new/side-by-side PNGs.
#include <windows.h>
#include <d3d9.h>
#include <stdio.h>
#include <string>
#include <vector>
#include <math.h>
#pragma comment(lib, "d3d9.lib")
#pragma comment(lib, "user32.lib")

struct XBuf : IUnknown { virtual void* STDMETHODCALLTYPE GetBufferPointer() = 0; virtual DWORD STDMETHODCALLTYPE GetBufferSize() = 0; };
typedef HRESULT(WINAPI* Compile_t)(LPCSTR, UINT, const void*, void*, LPCSTR, LPCSTR, DWORD, XBuf**, XBuf**, void**);
typedef HRESULT(WINAPI* Save_t)(LPCWSTR, DWORD, IDirect3DSurface9*, const PALETTEENTRY*, const RECT*);
static Compile_t g_compile;
static Save_t g_save;
static IDirect3DDevice9* g_dev;
static const UINT W = 800, H = 450;

static std::string Hlsl(const char* path) {
    FILE* f = fopen(path, "rb");
    if (!f) { printf("can't open %s\n", path); exit(1); }
    std::string s; char b[65536]; size_t n;
    while ((n = fread(b, 1, sizeof b, f)) > 0) s.append(b, n);
    fclose(f);
    size_t a = s.find("R\"HLSL("), e = s.find(")HLSL\"");
    if (a == std::string::npos || e == std::string::npos) { printf("no kShaders in %s\n", path); exit(1); }
    return s.substr(a + 7, e - a - 7);
}
static void* Make(const std::string& src, const char* fn, const char* prof) {
    XBuf *code = nullptr, *err = nullptr;
    HRESULT hr = g_compile(src.c_str(), (UINT)src.size(), nullptr, nullptr, fn, prof, 0, &code, &err, nullptr);
    if (FAILED(hr) || !code) { printf("compile %s failed: %s\n", fn, err ? (const char*)err->GetBufferPointer() : "?"); exit(1); }
    void* out = nullptr;
    hr = prof[0] == 'v' ? g_dev->CreateVertexShader((const DWORD*)code->GetBufferPointer(), (IDirect3DVertexShader9**)&out)
                        : g_dev->CreatePixelShader((const DWORD*)code->GetBufferPointer(), (IDirect3DPixelShader9**)&out);
    code->Release(); if (err) err->Release();
    if (FAILED(hr)) { printf("create %s failed %08lX\n", fn, hr); exit(1); }
    return out;
}

struct Case { const char* name; const char* oldPs; const char* newPs; float style, tod, todNext, blend, pop; int view; bool tex; float rain, snow; };

static void Look(int view, float c[3][4]) {
    // camera right/up/back; 0 horizon ahead, 1 looking up, 2 toward the black hole, 3 looking down a little
    float yaw = view == 2 ? atan2f(0.15f, 1.0f) : (view == 3 ? 2.0f : 0.6f);
    float pitch = view == 1 ? 0.9f : (view == 2 ? 0.30f : (view == 3 ? -0.15f : 0.12f));
    float fx = sinf(yaw) * cosf(pitch), fy = sinf(pitch), fz = cosf(yaw) * cosf(pitch);   // forward
    float rx = cosf(yaw), ry = 0, rz = -sinf(yaw);                                         // right
    float ux = fy * rz - fz * ry, uy = fz * rx - fx * rz, uz = fx * ry - fy * rx;           // up = forward x right
    if (uy < 0) { ux = -ux; uy = -uy; uz = -uz; }
    float v[3][4] = {{rx, ry, rz, 0}, {ux, uy, uz, 0}, {-fx, -fy, -fz, 0}};
    memcpy(c, v, sizeof v);
}

int main(int argc, char** argv) {
    if (argc < 4) { printf("skycompare <old gfx.inc> <new gfx.inc> <out dir>\n"); return 1; }
    std::string oldSrc = Hlsl(argv[1]), newSrc = Hlsl(argv[2]), out = argv[3];
    CreateDirectoryA(out.c_str(), nullptr);
    HMODULE dx = LoadLibraryA("d3dx9_43.dll");
    g_compile = dx ? (Compile_t)GetProcAddress(dx, "D3DXCompileShader") : nullptr;
    g_save = dx ? (Save_t)GetProcAddress(dx, "D3DXSaveSurfaceToFileW") : nullptr;
    if (!g_compile || !g_save) { printf("d3dx9_43.dll missing\n"); return 1; }
    HWND wnd = CreateWindowA("STATIC", "skycompare", WS_POPUP, 0, 0, W, H, nullptr, nullptr, nullptr, nullptr);
    IDirect3D9* d3d = Direct3DCreate9(D3D_SDK_VERSION);
    D3DPRESENT_PARAMETERS pp = {};
    pp.Windowed = TRUE; pp.SwapEffect = D3DSWAPEFFECT_DISCARD; pp.BackBufferWidth = W; pp.BackBufferHeight = H;
    pp.BackBufferFormat = D3DFMT_X8R8G8B8; pp.hDeviceWindow = wnd;
    if (FAILED(d3d->CreateDevice(D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL, wnd, D3DCREATE_HARDWARE_VERTEXPROCESSING, &pp, &g_dev))) { printf("no device\n"); return 1; }
    D3DADAPTER_IDENTIFIER9 id = {}; d3d->GetAdapterIdentifier(0, 0, &id);
    printf("card: %s\n", id.Description);
    IDirect3DTexture9 *rt = nullptr, *skyTex = nullptr;
    g_dev->CreateTexture(W, H, 1, D3DUSAGE_RENDERTARGET, D3DFMT_A8R8G8B8, D3DPOOL_DEFAULT, &rt, nullptr);
    IDirect3DSurface9 *rts = nullptr, *mem = nullptr, *pair = nullptr;
    rt->GetSurfaceLevel(0, &rts);
    g_dev->CreateOffscreenPlainSurface(W, H, D3DFMT_A8R8G8B8, D3DPOOL_SYSTEMMEM, &mem, nullptr);
    g_dev->CreateOffscreenPlainSurface(W * 2, H, D3DFMT_A8R8G8B8, D3DPOOL_SYSTEMMEM, &pair, nullptr);
    // a stand-in "game sky" for the grading and weather passes: a blue-to-white gradient with some clouds
    g_dev->CreateTexture(W, H, 1, 0, D3DFMT_A8R8G8B8, D3DPOOL_MANAGED, &skyTex, nullptr);
    D3DLOCKED_RECT lr; skyTex->LockRect(0, &lr, nullptr, 0);
    for (UINT y = 0; y < H; ++y) for (UINT x = 0; x < W; ++x) {
        float v = (float)y / H, c = 0.5f + 0.5f * sinf(x * 0.03f) * sinf(y * 0.05f);
        BYTE r = (BYTE)(60 + 150 * v + 30 * c), g = (BYTE)(110 + 110 * v + 30 * c), b = (BYTE)(220 + 30 * v);
        ((DWORD*)((BYTE*)lr.pBits + y * lr.Pitch))[x] = 0xFF000000 | (r << 16) | (g << 8) | b;
    }
    skyTex->UnlockRect(0);
    D3DVERTEXELEMENT9 el[] = {{0, 0, D3DDECLTYPE_FLOAT4, 0, D3DDECLUSAGE_POSITION, 0}, {0, 16, D3DDECLTYPE_FLOAT2, 0, D3DDECLUSAGE_TEXCOORD, 0}, D3DDECL_END()};
    IDirect3DVertexDeclaration9* decl = nullptr; g_dev->CreateVertexDeclaration(el, &decl);
    IDirect3DVertexShader9* vs = (IDirect3DVertexShader9*)Make(newSrc, "vs_main", "vs_3_0");

    std::vector<Case> cases;
    const char* galaxyName[] = {"", "galaxy 1 milky way", "galaxy 2 nebula", "galaxy 3 deep space", "galaxy 4 matrix"};
    for (int s = 1; s <= 4; ++s) for (int v = 0; v < 2; ++v) cases.push_back({galaxyName[s], "ps_galaxy", "ps_galaxy", (float)s, 0, 0, 0, 0.5f, v, false});
    const char* skyName[] = {"aurora", "synthwave", "storm", "golden", "vapor", "hell", "underwater", "rainbow", "black hole", "candy"};
    static char newNames[10][16];
    for (int s = 5; s <= 14; ++s) {
        sprintf(newNames[s - 5], "ps_sky%d", s);
        for (int v = 0; v < 3; ++v) cases.push_back({skyName[s - 5], "ps_skies", newNames[s - 5], (float)s, 0, 0, 0, 0.5f, v, false});
        cases.push_back({skyName[s - 5], "ps_skies", newNames[s - 5], (float)s, 4, 0, 0, 0.6f, 1, false});   // night look
        cases.push_back({skyName[s - 5], "ps_skies", newNames[s - 5], (float)s, 5, 3, 0.4f, 0.8f, 0, false});  // evening blending into sunset
    }
    const char* todName[] = {"grading off", "grading morning", "grading day", "grading sunset", "grading night", "grading evening"};
    for (int t = 0; t <= 5; ++t) for (int v = 0; v < 2; ++v) cases.push_back({todName[t], "ps_sky", "ps_sky", 0, (float)t, 0, 0, 0.7f, v, true});
    cases.push_back({"grading day->night blend", "ps_sky", "ps_sky", 0, 2, 4, 0.5f, 0.7f, 1, true});
    cases.push_back({"weather rain", "ps_weather", "ps_weather", 0, 0, 0, 0, 0.5f, 0, true, 1.0f, 0});
    cases.push_back({"weather snow", "ps_weather", "ps_weather", 0, 0, 0, 0, 0.5f, 3, true, 0, 1.0f});

    int n = 0, worst = 0;
    for (auto& c : cases) {
        ++n;
        std::vector<DWORD> img[2];
        for (int k = 0; k < 2; ++k) {
            IDirect3DPixelShader9* ps = (IDirect3DPixelShader9*)Make(k ? newSrc : oldSrc, k ? c.newPs : c.oldPs, "ps_3_0");
            g_dev->SetRenderTarget(0, rts);
            g_dev->BeginScene();
            g_dev->SetRenderState(D3DRS_ZENABLE, FALSE); g_dev->SetRenderState(D3DRS_CULLMODE, D3DCULL_NONE);
            g_dev->SetRenderState(D3DRS_ALPHABLENDENABLE, FALSE);
            g_dev->SetSamplerState(0, D3DSAMP_ADDRESSU, D3DTADDRESS_CLAMP); g_dev->SetSamplerState(0, D3DSAMP_ADDRESSV, D3DTADDRESS_CLAMP);
            g_dev->SetSamplerState(0, D3DSAMP_MINFILTER, D3DTEXF_LINEAR); g_dev->SetSamplerState(0, D3DSAMP_MAGFILTER, D3DTEXF_LINEAR);
            g_dev->SetVertexShader(vs); g_dev->SetPixelShader(ps); g_dev->SetVertexDeclaration(decl);
            g_dev->SetTexture(0, c.tex ? skyTex : nullptr);
            float cst[24][4] = {};
            cst[0][0] = 1.0f / W; cst[0][1] = 1.0f / H; cst[0][2] = (float)W; cst[0][3] = (float)H;
            cst[1][3] = 123.4f;                               // game time (s): the same for both
            cst[7][0] = 1.0f / tanf(0.6f) * H / W; cst[7][1] = 1.0f / tanf(0.6f); cst[7][2] = 1; cst[7][3] = -1;
            cst[9][1] = c.style;
            float cam[3][4]; Look(c.view, cam); memcpy(cst[10], cam, sizeof cam);
            cst[13][0] = 0.62f; cst[13][1] = 0.66f; cst[13][2] = 0.72f; cst[13][3] = 1;
            cst[16][0] = c.tod; cst[16][1] = c.pop; cst[16][2] = c.todNext; cst[16][3] = c.blend;
            cst[17][0] = c.rain; cst[17][1] = c.snow;
            cst[18][0] = 1; cst[18][1] = 0.9f; cst[18][2] = 1;
            cst[19][0] = 0.6f; cst[19][1] = 0.62f; cst[19][2] = 0.66f; cst[19][3] = 1;
            g_dev->SetPixelShaderConstantF(0, &cst[0][0], 24);
            float ox = -1.0f / W, oy = 1.0f / H;
            float v[4][6] = {{-1 + ox, 1 + oy, 0, 1, 0, 0}, {1 + ox, 1 + oy, 0, 1, 1, 0}, {-1 + ox, -1 + oy, 0, 1, 0, 1}, {1 + ox, -1 + oy, 0, 1, 1, 1}};
            g_dev->DrawPrimitiveUP(D3DPT_TRIANGLESTRIP, 2, v, sizeof v[0]);
            g_dev->EndScene();
            g_dev->GetRenderTargetData(rts, mem);
            D3DLOCKED_RECT l; mem->LockRect(&l, nullptr, D3DLOCK_READONLY);
            img[k].resize(W * H);
            for (UINT y = 0; y < H; ++y) memcpy(&img[k][y * W], (BYTE*)l.pBits + y * l.Pitch, W * 4);
            mem->UnlockRect();
            ps->Release();
        }
        int mx = 0; double sum = 0; long diffPx = 0;
        for (UINT i = 0; i < W * H; ++i) {
            int pm = 0;
            for (int ch = 0; ch < 3; ++ch) {
                int a = (img[0][i] >> (ch * 8)) & 255, b = (img[1][i] >> (ch * 8)) & 255, d = a > b ? a - b : b - a;
                sum += d; if (d > pm) pm = d;
            }
            if (pm > mx) mx = pm;
            if (pm) ++diffPx;
        }
        if (mx > worst) worst = mx;
        printf("%2d %-28s view %d  max diff %3d  average %.4f  pixels differing %ld of %u\n", n, c.name, c.view, mx, sum / (W * H * 3.0), diffPx, W * H);
        D3DLOCKED_RECT l; pair->LockRect(&l, nullptr, 0);
        for (UINT y = 0; y < H; ++y) { memcpy((BYTE*)l.pBits + y * l.Pitch, &img[0][y * W], W * 4); memcpy((BYTE*)l.pBits + y * l.Pitch + W * 4, &img[1][y * W], W * 4); }
        pair->UnlockRect();
        wchar_t fn[MAX_PATH]; std::string nm = c.name; for (auto& ch : nm) if (ch == ' ' || ch == '>' || ch == '-') ch = '_';
        swprintf(fn, MAX_PATH, L"%hs\\%02d_%hs_view%d_old_left_new_right.png", out.c_str(), n, nm.c_str(), c.view);
        g_save(fn, 3 /* D3DXIFF_PNG */, pair, nullptr, nullptr);
    }
    printf("worst max diff over all %d cases: %d (of 255)\n", n, worst);
    return 0;
}
