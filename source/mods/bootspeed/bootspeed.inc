// bootspeed.inc - faster startup (included into the combined binkw32.dll by obsspawn_test_make.sh).
//
// 1. THUG Pro's ContentManager (.NET) re-reads and CRCs every custom level in User\ on every boot
//    (about 1 GB, 3.5 s), then rewrites the same .level.dat files and User\manifest_levels.dat.
//    When nothing under User\ changed since manifest_levels.dat was last written, the result
//    would be identical, so the ContentManagerWrapper ctor and TestMethod are turned into no-ops
//    and the existing manifests are used. Any added, edited or deleted file makes it scan as usual.
//    bootspeed.ini [bootspeed] skip_scan=0 forces the scan every boot.
// 2. The exe sleeps a flat 2 s during boot (Sleep(2000) at 0x564E64, push 0x7D0). Patched to 0.
//    bootspeed.ini [bootspeed] skip_sleep=0 keeps it.
// 4. First-boot splash while the custom-level scan runs (see StartSplash). bootspeed.ini splash=0 turns it off.
// Logs to bootspeed.log next to THUGPro.exe.

#include <stdio.h>
#include <stdarg.h>
#include <math.h>

namespace bootspeed {

static char g_log[4096];
static void Note(const char* fmt, ...) {
    char line[512];
    va_list ap; va_start(ap, fmt); _vsnprintf(line, sizeof(line) - 3, fmt, ap); va_end(ap);
    line[sizeof(line) - 3] = 0; strcat(line, "\r\n");
    if (strlen(g_log) + strlen(line) < sizeof(g_log)) strcat(g_log, line);
    HANDLE f = CreateFileA("dadmod\\bootspeed.log", GENERIC_WRITE, FILE_SHARE_READ, NULL, CREATE_ALWAYS, 0, NULL);
    if (f != INVALID_HANDLE_VALUE) { DWORD n; WriteFile(f, g_log, (DWORD)strlen(g_log), &n, NULL); CloseHandle(f); }
}

static unsigned long long FtU(const FILETIME& f) { return ((unsigned long long)f.dwHighDateTime << 32) | f.dwLowDateTime; }

static unsigned long long g_cutoff;
static char g_newer[MAX_PATH];
static int g_count;

// true if anything under dir (files or folders) was created or written after g_cutoff
static bool NewerUnder(const char* dir, int depth) {
    char pat[MAX_PATH];
    if (_snprintf(pat, sizeof(pat), "%s\\*", dir) < 0) return true;
    WIN32_FIND_DATAA fd;
    HANDLE h = FindFirstFileA(pat, &fd);
    if (h == INVALID_HANDLE_VALUE) return false;
    bool newer = false;
    do {
        if (!strcmp(fd.cFileName, ".") || !strcmp(fd.cFileName, "..")) continue;
        if (depth == 0 && (!_stricmp(fd.cFileName, "manifest_levels.dat") || !_stricmp(fd.cFileName, "manifest_soundtracks.dat"))) continue;
        g_count++;
        unsigned long long t = FtU(fd.ftLastWriteTime), c = FtU(fd.ftCreationTime);
        if (c > t) t = c;
        char sub[MAX_PATH];
        _snprintf(sub, sizeof(sub), "%s\\%s", dir, fd.cFileName); sub[MAX_PATH - 1] = 0;
        if (t > g_cutoff) { strcpy(g_newer, sub); newer = true; break; }
        if ((fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) && depth < 12 && NewerUnder(sub, depth + 1)) { newer = true; break; }
    } while (FindNextFileA(h, &fd));
    FindClose(h);
    return newer;
}

static bool g_skip_scan;
static bool g_user_empty;   // no manifest and no files under User: the scan has nothing to do, so no splash

// true if any file (not folder) sits under dir, the two manifests aside
static bool FilesUnder(const char* dir, int depth) {
    char pat[MAX_PATH];
    if (_snprintf(pat, sizeof(pat), "%s\\*", dir) < 0) return true;
    WIN32_FIND_DATAA fd;
    HANDLE h = FindFirstFileA(pat, &fd);
    if (h == INVALID_HANDLE_VALUE) return false;
    bool any = false;
    do {
        if (!strcmp(fd.cFileName, ".") || !strcmp(fd.cFileName, "..")) continue;
        if (depth == 0 && (!_stricmp(fd.cFileName, "manifest_levels.dat") || !_stricmp(fd.cFileName, "manifest_soundtracks.dat"))) continue;
        if (!(fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)) { any = true; break; }
        char sub[MAX_PATH];
        _snprintf(sub, sizeof(sub), "%s\\%s", dir, fd.cFileName); sub[MAX_PATH - 1] = 0;
        if (depth >= 12 || FilesUnder(sub, depth + 1)) { any = true; break; }
    } while (FindNextFileA(h, &fd));
    FindClose(h);
    return any;
}

static bool ScanNeeded() {
    WIN32_FILE_ATTRIBUTE_DATA m;
    if (!GetFileAttributesExA("User\\manifest_levels.dat", GetFileExInfoStandard, &m)) {
        g_user_empty = !FilesUnder("User", 0);
        Note(g_user_empty ? "scan: no User\\manifest_levels.dat yet and no files under User, no splash" : "scan: no User\\manifest_levels.dat yet");
        return true;
    }
    g_cutoff = FtU(m.ftLastWriteTime) + 2ull * 10000000ull;   // 2 s slack: the scan writes it last
    DWORD t0 = GetTickCount();
    bool newer = NewerUnder("User", 0);
    Note("scan check: %d entries in %lu ms%s%s", g_count, GetTickCount() - t0, newer ? ", changed: " : ", unchanged", newer ? g_newer : "");
    return newer;
}

static void PatchBytes(void* at, const void* bytes, size_t n) {
    DWORD old;
    if (VirtualProtect(at, n, PAGE_EXECUTE_READWRITE, &old)) {
        memcpy(at, bytes, n);
        VirtualProtect(at, n, old, &old);
        FlushInstructionCache(GetCurrentProcess(), at, n);
    }
}

static bool g_patched;
static void PatchWrapper(HMODULE m) {
    if (g_patched || !m) return;
    g_patched = true;
    unsigned char* ctor = (unsigned char*)GetProcAddress(m, "??0ContentManagerWrapper@@QAE@XZ");
    unsigned char* test = (unsigned char*)GetProcAddress(m, "?TestMethod@ContentManagerWrapper@@QAEXXZ");
    // both exports are "jmp [slot]" thunks into managed code
    if (!ctor || !test || ctor[0] != 0xFF || ctor[1] != 0x25 || test[0] != 0xFF || test[1] != 0x25) { Note("wrapper exports not as expected, scan left on"); return; }
    static const unsigned char ctor_stub[] = { 0xC7, 0x01, 0, 0, 0, 0, 0x89, 0xC8, 0xC3 };  // mov dword [ecx],0; mov eax,ecx; ret
    static const unsigned char test_stub[] = { 0xC3, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC };        // ret
    // the ctor thunk is followed by padding (cc cc) and then managed IL data, so only 8 bytes are free:
    // jump to a stub of our own instead of writing 9 bytes in place
    static unsigned char* ctor_mem;
    if (!ctor_mem) ctor_mem = (unsigned char*)VirtualAlloc(NULL, 16, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
    if (!ctor_mem) return;
    memcpy(ctor_mem, ctor_stub, sizeof(ctor_stub));
    unsigned char jmp[6] = { 0xE9, 0, 0, 0, 0, 0xCC };
    *(int*)(jmp + 1) = (int)(ctor_mem - (ctor + 5));
    PatchBytes(ctor, jmp, sizeof(jmp));
    PatchBytes(test, test_stub, sizeof(test_stub));
    Note("custom content unchanged: skipped the User\\ rescan");
}

// LdrRegisterDllNotification: patch ContentManagerWrapper.dll as soon as it is mapped
struct UStr { USHORT Length, MaximumLength; PWSTR Buffer; };
struct NotifyData { ULONG Flags; const UStr* FullDllName; const UStr* BaseDllName; PVOID DllBase; ULONG SizeOfImage; };
typedef VOID (CALLBACK* NotifyFn)(ULONG reason, const NotifyData* data, PVOID ctx);
typedef LONG (NTAPI* RegisterFn)(ULONG flags, NotifyFn fn, PVOID ctx, PVOID* cookie);

static VOID CALLBACK OnDll(ULONG reason, const NotifyData* data, PVOID) {
    if (reason != 1 || !data || !data->BaseDllName || !data->BaseDllName->Buffer) return;   // 1 = loaded
    if (_wcsnicmp(data->BaseDllName->Buffer, L"ContentManagerWrapper.dll", data->BaseDllName->Length / 2) == 0 &&
        data->BaseDllName->Length / 2 == 25)
        PatchWrapper((HMODULE)data->DllBase);
}

// 3. Texture unswizzle. The exe's loader (0x5F5AF0, cdecl dst, src, width, height, bytes per texel)
//    turns Xbox-swizzled (Morton order) textures linear by rebuilding x/y bit by bit for every texel;
//    at boot that is ~1.75 s of the main thread. Same result here with per-axis lookup tables.
//    bootspeed.ini [bootspeed] fast_textures=0 keeps the stock routine.
static unsigned char* __cdecl SlowUnswizzle(unsigned char* dst, const unsigned char* src, int w, unsigned h, unsigned bpp) {
    unsigned total = (unsigned)w * h;
    for (unsigned i = 0; i < total; i++) {
        unsigned mask = 1, x = 0, y = 0, xb = 1, yb = 1, xr = (unsigned)(w >> 1), yr = (unsigned)((int)h >> 1);
        while (xr || yr) {
            if (xr) { xr >>= 1; if (i & mask) x |= xb; xb <<= 1; mask <<= 1; }
            if (yr) { yr >>= 1; if (i & mask) y |= yb; yb <<= 1; mask <<= 1; }
        }
        memcpy(dst + (y * (unsigned)w + x) * bpp, src, bpp);
        src += bpp;
    }
    return dst;
}

static unsigned char* __cdecl FastUnswizzle(unsigned char* dst, const unsigned char* src, int w, unsigned h, unsigned bpp) {
    const unsigned MAXD = 4096;
    if (w <= 0 || (w & (w - 1)) || !h || (h & (h - 1)) || (unsigned)w > MAXD || h > MAXD || !bpp)
        return SlowUnswizzle(dst, src, w, h, bpp);
    unsigned xs[MAXD], ys[MAXD], mx[16], my[16], nx = 0, ny = 0;
    unsigned mask = 1, xr = (unsigned)w >> 1, yr = h >> 1;
    while (xr || yr) {                          // same bit order as the stock loop: x bit, then y bit
        if (xr) { xr >>= 1; mx[nx++] = mask; mask <<= 1; }
        if (yr) { yr >>= 1; my[ny++] = mask; mask <<= 1; }
    }
    for (unsigned x = 0; x < (unsigned)w; x++) { unsigned v = 0; for (unsigned k = 0; k < nx; k++) if (x >> k & 1) v |= mx[k]; xs[x] = v; }
    for (unsigned y = 0; y < h; y++) { unsigned v = 0; for (unsigned k = 0; k < ny; k++) if (y >> k & 1) v |= my[k]; ys[y] = v; }
    unsigned char* row = dst;
    for (unsigned y = 0; y < h; y++, row += (unsigned)w * bpp) {
        unsigned yv = ys[y];
        if (bpp == 4) {
            unsigned* d = (unsigned*)row; const unsigned* s = (const unsigned*)src;
            for (unsigned x = 0; x < (unsigned)w; x++) d[x] = s[xs[x] | yv];
        } else if (bpp == 2) {
            unsigned short* d = (unsigned short*)row; const unsigned short* s = (const unsigned short*)src;
            for (unsigned x = 0; x < (unsigned)w; x++) d[x] = s[xs[x] | yv];
        } else if (bpp == 1) {
            for (unsigned x = 0; x < (unsigned)w; x++) row[x] = src[xs[x] | yv];
        } else {
            for (unsigned x = 0; x < (unsigned)w; x++) memcpy(row + x * bpp, src + (xs[x] | yv) * bpp, bpp);
        }
    }
    return dst;
}

static void InstallFastTextures() {
    unsigned char* f = (unsigned char*)0x5F5AF0;
    static const unsigned char expect[] = { 0x83, 0xEC, 0x10, 0x8B, 0x44, 0x24, 0x1C };
    if (memcmp(f, expect, sizeof(expect))) { Note("texture unswizzle not found, left alone"); return; }
    unsigned char jmp[5] = { 0xE9 };
    *(int*)(jmp + 1) = (int)((unsigned char*)FastUnswizzle - (f + 5));
    PatchBytes(f, jmp, 5);
    Note("fast texture unswizzle on");
}

// 4. First-boot splash (Noah 2026-11-17, loading screen "B2"): while THUG Pro's custom-level scan runs (first boot
//    after an install/update, or after maps change) there is no game window yet, so a borderless full-screen window shows
//    the block-letter DADMOD in the Sunset colors with a sliding glow line and "First boot takes the longest".
//    Our own drawing (GDI), no image files. It never takes focus, closes as soon as the game shows its own window,
//    and after 3 minutes at the latest. bootspeed.ini [bootspeed] splash=0 turns it off.
#pragma comment(lib, "gdi32.lib")
#pragma comment(lib, "advapi32.lib")
static const wchar_t* kLogo[] = {
    L"\x2588\x2588\x2588\x2588\x2588\x2588\x2557  \x2588\x2588\x2588\x2588\x2588\x2557 \x2588\x2588\x2588\x2588\x2588\x2588\x2557 \x2588\x2588\x2588\x2557   \x2588\x2588\x2588\x2557 \x2588\x2588\x2588\x2588\x2588\x2588\x2557 \x2588\x2588\x2588\x2588\x2588\x2588\x2557",
    L"\x2588\x2588\x2554\x2550\x2550\x2588\x2588\x2557\x2588\x2588\x2554\x2550\x2550\x2588\x2588\x2557\x2588\x2588\x2554\x2550\x2550\x2588\x2588\x2557\x2588\x2588\x2588\x2588\x2557 \x2588\x2588\x2588\x2588\x2551\x2588\x2588\x2554\x2550\x2550\x2550\x2588\x2588\x2557\x2588\x2588\x2554\x2550\x2550\x2588\x2588\x2557",
    L"\x2588\x2588\x2551  \x2588\x2588\x2551\x2588\x2588\x2588\x2588\x2588\x2588\x2588\x2551\x2588\x2588\x2551  \x2588\x2588\x2551\x2588\x2588\x2554\x2588\x2588\x2588\x2588\x2554\x2588\x2588\x2551\x2588\x2588\x2551   \x2588\x2588\x2551\x2588\x2588\x2551  \x2588\x2588\x2551",
    L"\x2588\x2588\x2551  \x2588\x2588\x2551\x2588\x2588\x2554\x2550\x2550\x2588\x2588\x2551\x2588\x2588\x2551  \x2588\x2588\x2551\x2588\x2588\x2551\x255a\x2588\x2588\x2554\x255d\x2588\x2588\x2551\x2588\x2588\x2551   \x2588\x2588\x2551\x2588\x2588\x2551  \x2588\x2588\x2551",
    L"\x2588\x2588\x2588\x2588\x2588\x2588\x2554\x255d\x2588\x2588\x2551  \x2588\x2588\x2551\x2588\x2588\x2588\x2588\x2588\x2588\x2554\x255d\x2588\x2588\x2551 \x255a\x2550\x255d \x2588\x2588\x2551\x255a\x2588\x2588\x2588\x2588\x2588\x2588\x2554\x255d\x2588\x2588\x2588\x2588\x2588\x2588\x2554\x255d",
    L"\x255a\x2550\x2550\x2550\x2550\x2550\x255d \x255a\x2550\x255d  \x255a\x2550\x255d\x255a\x2550\x2550\x2550\x2550\x2550\x255d \x255a\x2550\x255d     \x255a\x2550\x255d \x255a\x2550\x2550\x2550\x2550\x2550\x255d \x255a\x2550\x2550\x2550\x2550\x2550\x255d",
};
static HWND g_splash;
static DWORD g_splashStart;
static DWORD g_splashFadeOut;   // tick when the fade out began (0 = not yet)
static DWORD g_splashHold = 1500;     // shown at least this long (no one-frame flash); bootspeed.ini splash_hold (ms) for tests
static unsigned long long g_splashFt;   // when the splash started (file time), to see the scan finish
static wchar_t g_splashVer[64] = L"dadmod";

static void SplashRect(HDC dc, double x0, double y0, double x1, double y1, COLORREF c) {
    RECT r = { (LONG)(x0 + 0.5), (LONG)(y0 + 0.5), (LONG)(x1 + 0.5), (LONG)(y1 + 0.5) };
    if (r.right <= r.left) r.right = r.left + 1;
    if (r.bottom <= r.top) r.bottom = r.top + 1;
    HBRUSH b = CreateSolidBrush(c); FillRect(dc, &r, b); DeleteObject(b);
}

static COLORREF SplashMix(COLORREF a, COLORREF b, double f) {
    if (f < 0) f = 0; if (f > 1) f = 1;
    return RGB((int)(GetRValue(a) + (GetRValue(b) - GetRValue(a)) * f), (int)(GetGValue(a) + (GetGValue(b) - GetGValue(a)) * f),
               (int)(GetBValue(a) + (GetBValue(b) - GetBValue(a)) * f));
}

// Sunset theme colors across the word: pink, red, orange, gold
static COLORREF SplashSunset(double u) {
    static const COLORREF stops[4] = { RGB(255, 80, 220), RGB(255, 20, 20), RGB(255, 120, 0), RGB(255, 180, 20) };
    if (u < 0) u = 0; if (u > 1) u = 1;
    double p = u * 3; int k = (int)p; if (k > 2) k = 2;
    return SplashMix(stops[k], stops[k + 1], p - k);
}

static void SplashText(HDC dc, const wchar_t* t, int px, COLORREF c, double cx, double y, bool right = false, double rx = 0) {
    HFONT f = CreateFontW(-px, 0, 0, 0, FW_NORMAL, 0, 0, 0, DEFAULT_CHARSET, 0, 0, CLEARTYPE_QUALITY, 0, L"Segoe UI");
    HGDIOBJ old = SelectObject(dc, f);
    SIZE sz; GetTextExtentPoint32W(dc, t, (int)wcslen(t), &sz);
    SetBkMode(dc, TRANSPARENT); SetTextColor(dc, c);
    int x = right ? (int)(rx - sz.cx) : (int)(cx - sz.cx / 2.0);
    TextOutW(dc, x, (int)y, t, (int)wcslen(t));
    SelectObject(dc, old); DeleteObject(f);
}

// the same picture as work\release_test\loading_idea_B2.png, drawn for a w x h window (laid out on 1920x1080)
static void SplashPaint(HDC dc, int w, int h) {
    // fills the whole window (the whole screen); the picture is scaled to fit and centered
    double s = w / 1920.0 < h / 1080.0 ? w / 1920.0 : h / 1080.0;
    double oy = (h - 1080 * s) / 2;
    const COLORREF top = RGB(14, 4, 22), bot = RGB(70, 14, 40);
    for (int y = 0; y < h; y += 2) SplashRect(dc, 0, y, w, y + 2, SplashMix(top, bot, (double)y / h));
    const int rows = sizeof(kLogo) / sizeof(kLogo[0]);
    int cols = 0;
    for (int r = 0; r < rows; r++) { int n = (int)wcslen(kLogo[r]); if (n > cols) cols = n; }
    double cw = 26 * s, ch = 52 * s;
    double x0 = (w - cols * cw) / 2, y0 = oy + 300 * s, wordw = cols * cw;
    const COLORREF shade = RGB(110, 40, 70);
    double t = cw * 0.16 < 2.0 ? 2.0 : cw * 0.16, o = cw * 0.22;
    for (int r = 0; r < rows; r++) {
        const wchar_t* row = kLogo[r];
        for (int c = 0; row[c]; c++) {
            wchar_t q = row[c];
            double x = x0 + c * cw, y = y0 + r * ch, mx = x + cw / 2, my = y + ch / 2;
            double ya = y, yb = y + ch;
            if (q == 0x2584) ya = y + ch / 2; else if (q == 0x2580) yb = y + ch / 2;
            if (q == 0x2588 || q == 0x2584 || q == 0x2580) {
                for (int k = 0; k < 4; k++)   // 4 slices per cell keep the gradient smooth
                    SplashRect(dc, x + cw * k / 4, ya, x + cw * (k + 1) / 4, yb, SplashSunset((x + cw * (k + 0.5) / 4 - x0) / wordw));
            } else if (q >= 0x2550 && q <= 0x256C) {
                bool L = wcschr(L"\x2550\x2557\x255d\x2563\x2566\x2569\x256c", q) != NULL;
                bool R = wcschr(L"\x2550\x2554\x255a\x2560\x2566\x2569\x256c", q) != NULL;
                bool U = wcschr(L"\x2551\x255a\x255d\x2560\x2563\x2569\x256c", q) != NULL;
                bool D = wcschr(L"\x2551\x2554\x2557\x2560\x2563\x2566\x256c", q) != NULL;
                for (int k = -1; k <= 1; k += 2) {
                    if (L || R) SplashRect(dc, L ? x : mx - o, my + k * o - t / 2, R ? x + cw : mx + o, my + k * o + t / 2, shade);
                    if (U || D) SplashRect(dc, mx + k * o - t / 2, U ? y : my - o, mx + k * o + t / 2, D ? y + ch : my + o, shade);
                }
            }
        }
    }
    // thin line with a glow sliding back and forth along it
    double ly = y0 + rows * ch + 70 * s, half = 420 * s, glow = 110 * s;
    double bgc = (double)ly / h;
    COLORREF bg = SplashMix(top, bot, bgc);
    SplashRect(dc, w / 2.0 - half, ly - 1.5 * s, w / 2.0 + half, ly + 1.5 * s, RGB(80, 30, 60));
    double ph = fmod((GetTickCount() - g_splashStart) / 2400.0, 2.0);
    double u = ph < 1 ? ph : 2 - ph;
    u = u * u * (3 - 2 * u);
    double gx = w / 2.0 - half + glow + u * (2 * half - 2 * glow);
    for (int k = 8; k >= 1; k--) {   // soft glow: rounded layers, brighter toward the middle
        HBRUSH gb = CreateSolidBrush(SplashMix(bg, RGB(255, 140, 40), 0.09 * (9 - k)));
        HPEN np = (HPEN)GetStockObject(NULL_PEN);
        HGDIOBJ ob = SelectObject(dc, gb), op = SelectObject(dc, np);
        int ex = (int)(k * 3 * s), ey = (int)(k * 1.6 * s + 1);
        RoundRect(dc, (int)(gx - glow - ex), (int)(ly - ey), (int)(gx + glow + ex), (int)(ly + ey + 1), ey * 2, ey * 2);
        SelectObject(dc, ob); SelectObject(dc, op); DeleteObject(gb);
    }
    SplashRect(dc, gx - glow * 0.82, ly - 1.5 * s, gx + glow * 0.82, ly + 1.5 * s, RGB(255, 200, 120));
    SplashText(dc, L"First boot takes the longest. Hang tight...", (int)(38 * s + 0.5), RGB(240, 210, 210), w / 2.0, ly + 50 * s);
    SplashText(dc, g_splashVer, (int)(24 * s + 0.5), RGB(150, 100, 120), 0, h - 50 * s, true, w - 30 * s);
}

// test aid: bootspeed.ini [bootspeed] splash_shot=1 saves dadmod\splash_shot.bmp of the splash 2 s after it opens
static bool g_splashShot, g_splashShotDone;
static void SplashSaveShot(int w, int h) {
    HDC scr = GetDC(NULL);
    BITMAPINFO bi = {};
    bi.bmiHeader.biSize = sizeof(bi.bmiHeader); bi.bmiHeader.biWidth = w; bi.bmiHeader.biHeight = h;
    bi.bmiHeader.biPlanes = 1; bi.bmiHeader.biBitCount = 32; bi.bmiHeader.biCompression = BI_RGB;
    void* bits = NULL;
    HBITMAP bm = CreateDIBSection(scr, &bi, DIB_RGB_COLORS, &bits, NULL, 0);
    HDC mem = CreateCompatibleDC(scr);
    HGDIOBJ old = SelectObject(mem, bm);
    SplashPaint(mem, w, h);
    GdiFlush();
    DWORD size = (DWORD)w * h * 4;
    BITMAPFILEHEADER fh = {};
    fh.bfType = 0x4D42; fh.bfOffBits = sizeof(fh) + sizeof(bi.bmiHeader); fh.bfSize = fh.bfOffBits + size;
    HANDLE f = CreateFileA("dadmod\\splash_shot.bmp", GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, 0, NULL);
    if (f != INVALID_HANDLE_VALUE) {
        DWORD n;
        WriteFile(f, &fh, sizeof(fh), &n, NULL); WriteFile(f, &bi.bmiHeader, sizeof(bi.bmiHeader), &n, NULL); WriteFile(f, bits, size, &n, NULL);
        CloseHandle(f);
        Note("splash: saved dadmod\\splash_shot.bmp");
    }
    SelectObject(mem, old); DeleteObject(bm); DeleteDC(mem); ReleaseDC(NULL, scr);
}

static BOOL CALLBACK SplashFindGame(HWND hw, LPARAM found) {
    DWORD pid = 0;
    GetWindowThreadProcessId(hw, &pid);
    if (pid != GetCurrentProcessId() || hw == g_splash || !IsWindowVisible(hw)) return TRUE;
    RECT r; GetWindowRect(hw, &r);
    if (r.right - r.left < 320 || r.bottom - r.top < 240) return TRUE;   // tooltips, IME windows
    *(HWND*)found = hw;
    return FALSE;
}

// cover exactly the game's own picture: its window's client area, moved and resized along with it
static HWND g_splashGameWnd;
static void SplashFollow(HWND hw) {
    HWND gw = NULL;
    EnumWindows(SplashFindGame, (LPARAM)&gw);
    if (!gw) return;
    RECT rc; GetClientRect(gw, &rc);
    POINT tl = { 0, 0 }; ClientToScreen(gw, &tl);
    if (rc.right < 320 || rc.bottom < 240) return;
    RECT cur; GetWindowRect(hw, &cur);
    if (cur.left != tl.x || cur.top != tl.y || cur.right - cur.left != rc.right || cur.bottom - cur.top != rc.bottom) {
        SetWindowPos(hw, HWND_TOPMOST, tl.x, tl.y, rc.right, rc.bottom, SWP_NOACTIVATE);
        if (gw != g_splashGameWnd) Note("splash: on the game window (%dx%d at %d,%d)", (int)rc.right, (int)rc.bottom, (int)tl.x, (int)tl.y);
    }
    g_splashGameWnd = gw;
}

static LRESULT CALLBACK SplashProc(HWND hw, UINT msg, WPARAM wp, LPARAM lp) {
    switch (msg) {
    case WM_TIMER: {
        if (g_splashShot && !g_splashShotDone && GetTickCount() - g_splashStart > 2000) { g_splashShotDone = true; RECT rc; GetClientRect(hw, &rc); SplashSaveShot(rc.right, rc.bottom); }
        // the game opens its (black) window before the scan ends: wait until the scan has written
        // User\manifest_levels.dat again (it writes that last), then close once the game window is up
        SplashFollow(hw);
        HWND gameWnd = NULL;
        bool game = false, scanned = false;
        WIN32_FILE_ATTRIBUTE_DATA m;
        if (GetFileAttributesExA("User\\manifest_levels.dat", GetFileExInfoStandard, &m)) scanned = FtU(m.ftLastWriteTime) > g_splashFt;
        DWORD now = GetTickCount(), age = now - g_splashStart;
        if (!g_splashFadeOut) {
            if (scanned && age >= g_splashHold) { EnumWindows(SplashFindGame, (LPARAM)&gameWnd); game = gameWnd != NULL; }
            if (game || age > 180000) {   // fade out over the game window (0.8 s), then close
                g_splashFadeOut = now;
                Note("splash: fading out (%s) after %lu ms, hold %lu", game ? "game window up" : "3 min", age, g_splashHold);
            }
        }
        // fade in over 0.5 s at launch, fade out over 0.8 s at the end (layered window alpha), always on top
        double a = age < 500 ? age / 500.0 : 1.0;
        if (g_splashFadeOut) {
            double f = (now - g_splashFadeOut) / 800.0;
            if (f >= 1) { Note("splash: closed"); DestroyWindow(hw); return 0; }
            a *= 1 - f;
        }
        SetLayeredWindowAttributes(hw, 0, (BYTE)(a * 255 + 0.5), LWA_ALPHA);
        if (g_splashFadeOut) SetWindowPos(hw, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
        InvalidateRect(hw, NULL, FALSE);
        return 0;
    }
    case WM_MOUSEACTIVATE: return MA_NOACTIVATE;
    case WM_ERASEBKGND: return 1;
    case WM_PAINT: {
        PAINTSTRUCT ps; HDC dc = BeginPaint(hw, &ps);
        RECT rc; GetClientRect(hw, &rc);
        HDC mem = CreateCompatibleDC(dc);
        HBITMAP bm = CreateCompatibleBitmap(dc, rc.right, rc.bottom);
        HGDIOBJ old = SelectObject(mem, bm);
        SplashPaint(mem, rc.right, rc.bottom);
        BitBlt(dc, 0, 0, rc.right, rc.bottom, mem, 0, 0, SRCCOPY);
        SelectObject(mem, old); DeleteObject(bm); DeleteDC(mem);
        EndPaint(hw, &ps);
        return 0;
    }
    case WM_DESTROY: g_splash = NULL; PostQuitMessage(0); return 0;
    }
    return DefWindowProcW(hw, msg, wp, lp);
}

static DWORD WINAPI SplashThread(LPVOID) {
    WNDCLASSW wc = {};
    wc.lpfnWndProc = SplashProc;
    wc.hInstance = GetModuleHandleW(NULL);
    wc.hCursor = LoadCursor(NULL, IDC_ARROW);
    wc.lpszClassName = L"dadmod_first_boot";
    RegisterClassW(&wc);
    // where the game's picture will be: fullscreen = the whole main monitor; windowed (THUG Pro's windowed_mode) = its
    // size (THUG Pro draws at width x height in both modes), centered. Once the game's own window exists the splash moves onto it (SplashFollow).
    int sw = GetSystemMetrics(SM_CXSCREEN), sh = GetSystemMetrics(SM_CYSCREEN), w = sw, h = sh, x = 0, y = 0;
    HKEY k;
    if (RegOpenKeyExA(HKEY_CURRENT_USER, "Software\\THUG Pro\\Settings", 0, KEY_READ, &k) == ERROR_SUCCESS) {
        DWORD win = 0, ww = 0, wh = 0, n = sizeof(DWORD);
        RegQueryValueExA(k, "windowed_mode", NULL, NULL, (BYTE*)&win, &n); n = sizeof(DWORD);
        RegQueryValueExA(k, "width", NULL, NULL, (BYTE*)&ww, &n); n = sizeof(DWORD);
        RegQueryValueExA(k, "height", NULL, NULL, (BYTE*)&wh, &n);
        RegCloseKey(k);
        if (win && ww >= 320 && wh >= 240 && (int)ww <= sw && (int)wh <= sh) { w = ww; h = wh; x = (sw - w) / 2; y = (sh - h) / 2; }
    }
    g_splash = CreateWindowExW(WS_EX_TOPMOST | WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE | WS_EX_LAYERED, wc.lpszClassName, L"dadmod", WS_POPUP,
                               x, y, w, h, NULL, NULL, wc.hInstance, NULL);
    if (!g_splash) { Note("splash: could not open its window"); return 0; }
    SetLayeredWindowAttributes(g_splash, 0, 0, LWA_ALPHA);   // starts invisible, fades in
    ShowWindow(g_splash, SW_SHOWNOACTIVATE);
    SetTimer(g_splash, 1, 16, NULL);
    Note("splash: shown (%dx%d)", w, h);
    MSG m;
    while (GetMessageW(&m, NULL, 0, 0) > 0) { TranslateMessage(&m); DispatchMessageW(&m); }
    return 0;
}

static void StartSplash() {
    if (!GetPrivateProfileIntA("bootspeed", "splash", 1, ".\\dadmod\\bootspeed.ini")) { Note("splash off (bootspeed.ini)"); return; }
    HANDLE f = CreateFileA("dadmod\\version.txt", GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL);
    if (f != INVALID_HANDLE_VALUE) {
        char b[32] = {}; DWORD n = 0;
        ReadFile(f, b, sizeof(b) - 1, &n, NULL); CloseHandle(f);
        for (DWORD i = 0; i < n; i++) if (b[i] == '\r' || b[i] == '\n') { b[i] = 0; break; }
        if (b[0]) _snwprintf(g_splashVer, 63, L"dadmod %hs beta", b);
    }
    g_splashHold = GetPrivateProfileIntA("bootspeed", "splash_hold", 1500, ".\\dadmod\\bootspeed.ini");
    g_splashShot = GetPrivateProfileIntA("bootspeed", "splash_shot", 0, ".\\dadmod\\bootspeed.ini") != 0;
    g_splashStart = GetTickCount();
    FILETIME ft; GetSystemTimeAsFileTime(&ft); g_splashFt = FtU(ft);
    HANDLE th = CreateThread(NULL, 0, SplashThread, NULL, 0, NULL);
    if (th) CloseHandle(th);
}

static void Install() {
    g_log[0] = 0;
    if (GetPrivateProfileIntA("bootspeed", "fast_textures", 1, ".\\dadmod\\bootspeed.ini")) InstallFastTextures();
    else Note("fast texture unswizzle off (bootspeed.ini)");
    bool skip_scan = GetPrivateProfileIntA("bootspeed", "skip_scan", 1, ".\\dadmod\\bootspeed.ini") != 0;
    bool skip_sleep = GetPrivateProfileIntA("bootspeed", "skip_sleep", 1, ".\\dadmod\\bootspeed.ini") != 0;

    unsigned char* s = (unsigned char*)0x564E64;   // push 0x7D0; call [Sleep]
    if (skip_sleep && s[0] == 0x68 && *(DWORD*)(s + 1) == 2000 && s[5] == 0xFF && s[6] == 0x15) {
        DWORD zero = 0; PatchBytes(s + 1, &zero, 4);
        Note("boot Sleep(2000) removed");
    } else Note(skip_sleep ? "boot Sleep(2000) not found, left alone" : "boot Sleep(2000) kept (bootspeed.ini)");

    // The engine's file open (0x5BC9B0) calls CreateFileA with share mode 0, so a second game running
    // from the same folder that opens the same file at the same moment fails. The custom level check
    // (CustomLevelIsValid) then CRCs nothing and sends the host to the main menu. Share reads instead.
    unsigned char* f = (unsigned char*)0x5BCA32;   // push 0 (security attrs); push 0 (share mode); push eax; push 0x7D1810
    if (f[0] == 0x6A && f[1] == 0 && f[2] == 0x6A && f[3] == 0 && f[4] == 0x50 && f[5] == 0x68 && *(DWORD*)(f + 6) == 0x7D1810) {
        unsigned char share = FILE_SHARE_READ; PatchBytes(f + 3, &share, 1);
        Note("file open: share reads with other games");
    } else Note("file open share mode not found, left alone");

    if (!skip_scan) { Note("scan forced on (bootspeed.ini)"); return; }
    if (ScanNeeded()) { if (!g_user_empty) StartSplash(); return; }
    g_skip_scan = true;
    HMODULE m = GetModuleHandleA("ContentManagerWrapper.dll");
    if (m) { PatchWrapper(m); return; }
    RegisterFn reg = (RegisterFn)GetProcAddress(GetModuleHandleA("ntdll.dll"), "LdrRegisterDllNotification");
    static PVOID cookie;
    if (!reg || reg(0, OnDll, NULL, &cookie) != 0) Note("could not watch for ContentManagerWrapper.dll, scan left on");
}

} // namespace bootspeed

static void InstallBootSpeedHooks() { bootspeed::Install(); }
