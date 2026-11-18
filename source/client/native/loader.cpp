// dadmod client loader (binkw32.dll proxy). Client build only; the server build keeps native/thugrecomp.
// Mod code is included straight from its folder under work/mods, so both builds share one copy of it.
//
// THUG Pro loads its scripts once at boot from data\pre\thugpro_qb.prx (the list is code\qb\qdir.txt
// inside it; FUN_005A59D0, called from 0x5A5B2D). We redirect that call: after the game's own scripts
// (stock THUG Pro or Kali, whichever is installed) we load data\pre\dadmod_qb.prx the same way.
// Nothing in thugpro_qb.prx is replaced, so Kali's files are never touched.
//
// Inside dadmod_qb.prx:
//   code\dadmod\wrap.txt  stock script names to wrap. Before our scripts load, each existing script
//                         X is renamed to X_orig in the symbol table, so our X can do its part and
//                         call X_orig <...>. Whatever version the player has keeps running underneath.
//   code\dadmod\qdir.txt  our .qb files, loaded in order (later definitions win).
//
// Proven on a copy of the stock install 2026-11-05 (work/client_spike). Log: <game>\dadmod\client.log.
#include <windows.h>
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <ctype.h>

#ifdef _MSC_VER
#define THISCALL __thiscall
#else
#define THISCALL __attribute__((thiscall))
#endif

// ---- THUGPro.exe (2004-09-14 build, the one every THUG Pro install ships)
static const DWORD kCallRegisterCFuncs = 0x5A5F52;  // E8 -> 0x46EFD0
static const DWORD kRegisterCFuncs     = 0x46EFD0;  // cdecl(CFuncEntry*, count)
static const DWORD kCallLoadStartup    = 0x5A5B2D;  // E8 -> 0x5A59D0 (startup script loader)
static const DWORD kLoadStartup        = 0x5A59D0;
static const DWORD kStructGetString    = 0x476C60;  // thiscall CStruct::GetString(key, const char**, bool)
static const DWORD kMemMgr             = 0x7D1800;  // memory manager*; +0x110 = script heap
static const DWORD kPushHeap           = 0x5BB0E0;  // thiscall(memmgr, heap)
static const DWORD kPopHeap            = 0x5BB110;  // thiscall(memmgr)
static const DWORD kLoadPre            = 0x5B75A0;  // cdecl(name)  name under data\pre
static const DWORD kUnloadPre          = 0x5B7130;  // cdecl(name)
static const DWORD kFileLoad           = 0x5B7C00;  // cdecl(name, 0, 0, 0, 0) -> buffer
static const DWORD kFileSize           = 0x5B72E0;  // cdecl(name) -> size
static const DWORD kFileFree           = 0x5B7270;  // cdecl(name)
static const DWORD kLoadBegin          = 0x476300;  // cdecl()
static const DWORD kLoadEnd            = 0x476310;  // cdecl()
static const DWORD kNameCrc            = 0x401B90;  // cdecl(name) -> checksum
static const DWORD kUnloadFileSyms     = 0x46EEC0;  // cdecl(file checksum): drops symbols from that file
static const DWORD kLoaderFlag         = 0x479070;  // cdecl(0xC472ECC5, 0), as the stock loop does
static const DWORD kLoadQbFile         = 0x46EDE0;  // cdecl(name, 1, 0)
static const DWORD kSymTable           = 0x6F3624;  // symbol buckets[0x1000]: +1 type, +4 name, +8 file, +0x10 next

static const char* kPre  = "dadmod_qb.prx";
static const char* kQdir = "code\\dadmod\\qdir.txt";
static const char* kWrap = "code\\dadmod\\wrap.txt";

static char g_logPath[MAX_PATH];
static void Log(const char* fmt, ...) {
    char line[600]; va_list ap; va_start(ap, fmt); _vsnprintf(line, sizeof line - 3, fmt, ap); va_end(ap);
    line[sizeof line - 3] = 0; strcat(line, "\r\n");
    HANDLE f = CreateFileA(g_logPath, FILE_APPEND_DATA, FILE_SHARE_READ, NULL, OPEN_ALWAYS, 0, NULL);
    if (f != INVALID_HANDLE_VALUE) { DWORD n; WriteFile(f, line, (DWORD)strlen(line), &n, NULL); CloseHandle(f); }
}

static DWORD QbKey(const char* s) {
    DWORD c = 0xFFFFFFFF;
    for (; *s; ++s) {
        unsigned char ch = (unsigned char)tolower((unsigned char)*s);
        if (ch == '/') ch = '\\';
        c ^= ch;
        for (int i = 0; i < 8; ++i) c = (c >> 1) ^ ((c & 1) ? 0xEDB88320 : 0);
    }
    return c;
}

typedef void (__cdecl* Fn0)(void);
typedef void (__cdecl* Fn1)(DWORD);
typedef void (__cdecl* Fn2)(DWORD, DWORD);
typedef void* (__cdecl* FnFileLoad)(const char*, int, int, int, int);
typedef int (__cdecl* FnName)(const char*);
typedef void (__cdecl* FnLoadQb)(const char*, int, int);
typedef void (THISCALL* FnThis0)(void*);
typedef void (THISCALL* FnThis1)(void*, DWORD);
typedef char (THISCALL* FnGetStr)(void*, DWORD, const char**, char);

static BYTE* FindSym(DWORD key, BYTE*** link) {
    BYTE** buckets = *(BYTE***)kSymTable;
    BYTE** pp = &buckets[key & 0xFFF];
    while (*pp) {
        if (*(DWORD*)(*pp + 4) == key) { if (link) *link = pp; return *pp; }
        pp = (BYTE**)(*pp + 0x10);
    }
    return NULL;
}

// Rename the loaded script `name` to `name_orig` (same entry, moved to the new name's bucket).
static void WrapRename(const char* name) {
    char orig[200]; _snprintf(orig, sizeof orig - 1, "%s_orig", name); orig[sizeof orig - 1] = 0;
    DWORD k = QbKey(name), k2 = QbKey(orig);
    BYTE** link; BYTE* e = FindSym(k, &link);
    if (!e) { Log("wrap %s: not defined in this install, skipped", name); return; }
    if (FindSym(k2, NULL)) { Log("wrap %s: %s already exists, skipped", name, orig); return; }
    *link = *(BYTE**)(e + 0x10);
    *(DWORD*)(e + 4) = k2;
    BYTE** buckets = *(BYTE***)kSymTable;
    *(BYTE**)(e + 0x10) = buckets[k2 & 0xFFF];
    buckets[k2 & 0xFFF] = e;
    Log("wrap %s -> %s", name, orig);
}

static void ForEachLine(const char* p, int size, void (*fn)(const char*)) {
    const char* end = p + size; char line[256];
    while (p < end) {
        int i = 0;
        while (p < end && *p != '\r' && *p != '\n') { if (i < 255) line[i++] = *p; p++; }
        line[i] = 0; p++;
        while (i > 0 && (line[i - 1] == ' ' || line[i - 1] == '\t')) line[--i] = 0;
        if (line[0] && line[0] != '#') fn(line);
    }
}

static void LoadOneQb(const char* cline) {
    char line[256]; strncpy(line, cline, 255); line[255] = 0;
    char* s = strstr(line, "data\\");
    if (s) memmove(line, s + 5, strlen(s + 5) + 1);
    ((Fn1)kUnloadFileSyms)((DWORD)((FnName)kNameCrc)(line));
    ((Fn2)kLoaderFlag)(0xC472ECC5, 0);
    ((FnLoadQb)kLoadQbFile)(line, 1, 0);
    Log("loaded %s", line);
}

static void LoadDadmodScripts(void) {
    char path[MAX_PATH]; GetModuleFileNameA(NULL, path, MAX_PATH);
    char* sl = strrchr(path, '\\'); if (sl) sl[1] = 0;
    strcat(path, "data\\pre\\"); strcat(path, kPre);
    if (GetFileAttributesA(path) == INVALID_FILE_ATTRIBUTES) { Log("no data\\pre\\%s, nothing to load", kPre); return; }
    void* mm = *(void**)kMemMgr;
    ((FnThis1)kPushHeap)(mm, *(DWORD*)((BYTE*)mm + 0x110));
    ((FnName)kLoadPre)(kPre);
    ((FnThis0)kPopHeap)(*(void**)kMemMgr);

    const char* w = (const char*)((FnFileLoad)kFileLoad)(kWrap, 0, 0, 0, 0);
    if (w) { ForEachLine(w, ((FnName)kFileSize)(kWrap), WrapRename); ((FnName)kFileFree)(kWrap); }

    const char* q = (const char*)((FnFileLoad)kFileLoad)(kQdir, 0, 0, 0, 0);
    if (q) {
        int n = ((FnName)kFileSize)(kQdir);
        // No kLoadBegin/kLoadEnd here: "begin" turns on string sharing, whose table the game frees at the end
        // of its own boot load (0x476310 frees it but keeps the count), so strings in our globals crashed at
        // 0x4762A0 (2026-11-06). Without it every string just gets its own copy.
        ForEachLine(q, n, LoadOneQb);
        ((FnName)kFileFree)(kQdir);
    } else Log("no %s in %s", kQdir, kPre);
    ((FnName)kUnloadPre)(kPre);
}

static void BeforeGameScripts(void);
static void __cdecl LoadStartupHook(void) {
    BeforeGameScripts();
    ((Fn0)kLoadStartup)();
    LoadDadmodScripts();
}

// ---- mods in the client build (mods/MANIFEST.tsv, client = yes)
#define DADMOD_CLIENT_HAS_MAINMENU
#include "common.inc"
#define DebugLog Log                                // shared mods call DebugLog (Dev DLL name); the client logger is Log
#include "../../mods/crashlog/crashlog.inc"      // dadmod\crash.log breadcrumbs
#include "../../mods/bootspeed/bootspeed.inc"    // skip the level rescan and the boot sleep
#include "../../mods/controller/padhub.inc"      // controller hotplug for player 1
#include "../../mods/mainmenu/mainmenu.inc"      // main menu scenes, menu order, key and text helpers (dadmod\mainmenu.ini)
#include "../../mods/bankdrop/bankdrop.inc"      // bank drops (dadmod\thugrecomp.ini)
#include "texts.inc"                             // saved search texts + script log (client copies)
#include "menulevels.inc"                        // main menu scenes put together from the player's own files
#include "../../mods/balance/balancelock.inc"   // infinite balance (gfx.inc forwards gfx_balancelock); client build: offline only, enforced by the client menu scripts
#include "../../mods/gfx/gfx.inc"                // graphics settings (dadmod\gfx.ini)

// ---- script functions
struct CFuncEntry { const char* name; bool (__cdecl* fn)(void*, void*); };

// THUGRECOMP_ClientLog text="..."  appends a line to dadmod\client.log
static bool __cdecl CF_ClientLog(void* params, void* script) {
    (void)script;
    const char* t = NULL;
    if (GetStringParam(params, "text", &t)) Log("script: %s", t);
    return true;
}

static struct CFuncEntry g_cfuncs[] = {
    { "THUGRECOMP_ClientLog", CF_ClientLog },
    { "THUGRECOMP_SettingSave", CF_SettingSave },
    { "THUGRECOMP_SettingLoad", CF_SettingLoad },
    { "THUGRECOMP_GfxReset", gfx::CF_GfxReset },
    { "THUGRECOMP_PadPressed", padhub::CF_PadPressed },
    { "THUGRECOMP_PadHeld", padhub::CF_PadHeld },
    { "THUGRECOMP_BankDropsOn", CF_BankDropsOn },
    { "THUGRECOMP_BankDropsSet", CF_BankDropsSet },
    { "THUGRECOMP_TextSave", CF_TextSave },
    { "THUGRECOMP_TextLoad", CF_TextLoad },
    { "THUGRECOMP_TextHas", CF_TextHas },
    { "THUGRECOMP_Log", CF_Log },
    { "THUGRECOMP_MenuLevelHas", CF_MenuLevelHas },
    { "THUGRECOMP_MenuLevel", mmenu::CF_MenuLevel },
    { "THUGRECOMP_MenuSpot", mmenu::CF_MenuSpot },
    { "THUGRECOMP_MenuTick", mmenu::CF_MenuTick },
    { "THUGRECOMP_MenuMark", mmenu::CF_MenuMark },
    { "THUGRECOMP_MenuOpt", mmenu::CF_MenuOpt },
    { "THUGRECOMP_MenuDelete", mmenu::CF_MenuDelete },
    { "THUGRECOMP_MenuFav", mmenu::CF_MenuFav },
    { "THUGRECOMP_MenuSetHere", mmenu::CF_MenuSetHere },
    { "THUGRECOMP_MenuCamEdit", mmenu::CF_MenuCamEdit },
    { "THUGRECOMP_MenuSaved", mmenu::CF_MenuSaved },
    { "THUGRECOMP_MenuSavedDelete", mmenu::CF_MenuSavedDelete },
    { "THUGRECOMP_MenuFavAnim", mmenu::CF_MenuFavAnim },
    { "THUGRECOMP_MenuFocus", mmenu::CF_MenuFocus },
    { "THUGRECOMP_KeyPressed", mmenu::CF_KeyPressed },
    { "THUGRECOMP_MenuOrder", mmenu::CF_MenuOrder },
    { "THUGRECOMP_MenuOrderMove", mmenu::CF_MenuOrderMove },
    { "THUGRECOMP_MenuOrderUndo", mmenu::CF_MenuOrderUndo },
    { "THUGRECOMP_MenuOrderReset", mmenu::CF_MenuOrderReset },
    { "THUGRECOMP_ScanText", mmenu::CF_ScanText },
    { "THUGRECOMP_TextClip", mmenu::CF_TextClip },
    { "THUGRECOMP_UiClock", mmenu::CF_UiClock },
    { "THUGRECOMP_Display", mmenu::CF_Display },
    { "THUGRECOMP_MenuRestore", mmenu::CF_MenuRestore },
    { "THUGRECOMP_LayoutInfo", mmenu::CF_LayoutInfo },
    { "THUGRECOMP_LayoutChild", mmenu::CF_LayoutChild },
    { "THUGRECOMP_MenuSeen", mmenu::CF_MenuSeen },
    { "THUGRECOMP_MenuHasOrder", mmenu::CF_MenuHasOrder },
    { "THUGRECOMP_CapturePush", mmenu::CF_CapturePush },
    { "THUGRECOMP_CaptureNext", mmenu::CF_CaptureNext },
    { "THUGRECOMP_CaptureClear", mmenu::CF_CaptureClear },
};

static void __cdecl RegisterCFuncsHook(struct CFuncEntry* table, unsigned count) {
    typedef void (__cdecl* Fn)(struct CFuncEntry*, unsigned);
    gfx::PatchEngineCFuncs(table, count);  // Level sounds On/Off (gfx.inc)
    ((Fn)kRegisterCFuncs)(table, count);
    ((Fn)kRegisterCFuncs)(g_cfuncs, sizeof g_cfuncs / sizeof g_cfuncs[0]);
}

// before any script loads (the startup loader runs once, at boot)
static void BeforeGameScripts(void) {
    menulevels::Assemble();
}

static int PatchCall(DWORD site, DWORD expect, void* to) {
    BYTE* p = (BYTE*)site;
    if (p[0] != 0xE8 || (DWORD)(site + 5 + *(int*)(p + 1)) != expect) return 0;  // not the build we know
    DWORD old; VirtualProtect(p, 5, PAGE_EXECUTE_READWRITE, &old);
    *(int*)(p + 1) = (int)((DWORD)to - (site + 5));
    VirtualProtect(p, 5, old, &old);
    FlushInstructionCache(GetCurrentProcess(), p, 5);
    return 1;
}

BOOL WINAPI DllMain(HINSTANCE inst, DWORD reason, LPVOID reserved) {
    (void)reserved;
    if (reason == DLL_PROCESS_ATTACH) {
        DisableThreadLibraryCalls(inst);
        GetModuleFileNameA(NULL, g_logPath, MAX_PATH);
        char* sl = strrchr(g_logPath, '\\'); if (sl) sl[1] = 0;
        strcat(g_logPath, "dadmod"); CreateDirectoryA(g_logPath, NULL); strcat(g_logPath, "\\client.log");
        int a = PatchCall(kCallRegisterCFuncs, kRegisterCFuncs, (void*)RegisterCFuncsHook);
        int b = PatchCall(kCallLoadStartup, kLoadStartup, (void*)LoadStartupHook);
        Log("---- dadmod client loader: script functions %s, script loader %s", a ? "ok" : "NOT HOOKED", b ? "ok" : "NOT HOOKED");
        // same order as the server build's DllMain
        InstallBankDropHooks();
        InstallPadHubHooks();
        InstallBootSpeedHooks();
        crashlog::Install();
        gfx::Install();
        balancelock::Install();
    }
    return TRUE;
}
