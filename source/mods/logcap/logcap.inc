// logcap.inc: log files that never grow past a size cap (Noah 2026-11-24: logs must not take up room on players' PCs).
// Append() adds text to a log. When the file passes its cap it trims itself IN PLACE: the oldest part is cut so about
// half the cap is left (starting at a line break). One file per log, no .old copies.
// Cost on the calling thread: one open + write + close (as before) plus GetFileSizeEx on the open handle every
// kCheckEvery writes. The trim itself (reads only the half that is kept, ~1 MB) runs on a short worker thread; log
// lines written meanwhile are queued in memory and added right after it, so no caller waits for a trim.
// Included first in both DLL builds (Dev: obsspawn_test_make.sh, client: client/native/loader.cpp).
#pragma once
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
namespace logcap {

static const int kCheckEvery = 16;     // size check every 16 writes per log (and on the first write)
static SRWLOCK g_lock = SRWLOCK_INIT;  // appends: shared; a trim: exclusive
static volatile LONG g_trimming = 0;
static SRWLOCK g_pendLock = SRWLOCK_INIT;  // guards the queue below and g_trimActive
static bool g_trimActive = false;
struct Pend { Pend* next; char path[MAX_PATH]; DWORD len; char text[1]; };
static Pend* g_pend = nullptr;
static Pend** g_pendTail = &g_pend;

struct Slot { DWORD hash; int writes; };
static Slot g_slots[32];

static DWORD PathHash(const char* p) {
    DWORD h = 2166136261u;
    for (; *p; ++p) { unsigned char c = (unsigned char)*p; if (c >= 'A' && c <= 'Z') c += 32; h = (h ^ c) * 16777619u; }
    return h ? h : 1;
}
static bool CheckDue(const char* path) {  // true on the first write to a log and then every kCheckEvery writes
    DWORD h = PathHash(path);
    unsigned i = h % 32;
    for (int n = 0; n < 32; ++n, i = (i + 1) % 32) {
        Slot& s = g_slots[i];
        if (s.hash == h) return (++s.writes % kCheckEvery) == 0;
        if (!s.hash) { s.hash = h; s.writes = 0; return true; }
    }
    return true;  // table full: check every time (still cheap)
}

// Cut the file down to its newest ~keep bytes, starting at a line break. Returns false if the file is not touched.
static bool TrimNow(const char* path, DWORD keep) {
    HANDLE f = CreateFileA(path, GENERIC_READ | GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (f == INVALID_HANDLE_VALUE) return false;
    bool ok = false;
    LARGE_INTEGER size;
    if (GetFileSizeEx(f, &size) && size.QuadPart > (LONGLONG)keep) {
        char* buf = (char*)malloc(keep);
        LARGE_INTEGER at; at.QuadPart = size.QuadPart - keep;
        DWORD got = 0;
        if (buf && SetFilePointerEx(f, at, nullptr, FILE_BEGIN) && ReadFile(f, buf, keep, &got, nullptr) && got) {
            DWORD start = 0;
            while (start < got && buf[start] != '\n') ++start;  // drop the partial first line
            start = start < got ? start + 1 : 0;
            LARGE_INTEGER zero = {};
            DWORD w = 0;
            if (SetFilePointerEx(f, zero, nullptr, FILE_BEGIN) && WriteFile(f, buf + start, got - start, &w, nullptr) && SetEndOfFile(f)) ok = true;
        }
        free(buf);
    }
    CloseHandle(f);
    return ok;
}

static void WriteRaw(const char* path, const char* text, DWORD len) {
    HANDLE f = CreateFileA(path, FILE_APPEND_DATA, FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (f == INVALID_HANDLE_VALUE) return;
    DWORD w; WriteFile(f, text, len, &w, nullptr);
    CloseHandle(f);
}
// Trim with every other log write kept out of the file meanwhile: new lines queue up (Append) and are written after.
static void TrimLocked(const char* path, DWORD keep) {
    AcquireSRWLockExclusive(&g_pendLock); g_trimActive = true; ReleaseSRWLockExclusive(&g_pendLock);
    AcquireSRWLockExclusive(&g_lock);  // waits only for writes already under way
    TrimNow(path, keep);
    AcquireSRWLockExclusive(&g_pendLock);
    for (Pend* q = g_pend; q;) { WriteRaw(q->path, q->text, q->len); Pend* n = q->next; free(q); q = n; }
    g_pend = nullptr; g_pendTail = &g_pend;
    g_trimActive = false;
    ReleaseSRWLockExclusive(&g_pendLock);
    ReleaseSRWLockExclusive(&g_lock);
}

struct TrimJob { char path[MAX_PATH]; DWORD keep; };
static DWORD WINAPI TrimThread(LPVOID p) {
    TrimJob* j = (TrimJob*)p;
    TrimLocked(j->path, j->keep);
    free(j);
    InterlockedExchange(&g_trimming, 0);
    return 0;
}
static void TrimLater(const char* path, DWORD cap) {
    if (InterlockedCompareExchange(&g_trimming, 1, 0)) return;  // one trim at a time; a later write asks again
    TrimJob* j = (TrimJob*)malloc(sizeof(TrimJob));
    if (!j || strlen(path) >= MAX_PATH) { free(j); InterlockedExchange(&g_trimming, 0); return; }
    strcpy(j->path, path); j->keep = cap / 2;
    HANDLE t = CreateThread(nullptr, 0, TrimThread, j, 0, nullptr);
    if (t) CloseHandle(t); else { free(j); InterlockedExchange(&g_trimming, 0); }
}

// Append text to a log file capped at cap bytes.
static void Append(const char* path, const char* text, DWORD len, DWORD cap) {
    AcquireSRWLockExclusive(&g_pendLock);
    if (g_trimActive) {  // a trim is running: queue the line (written right after it), don't wait
        Pend* q = strlen(path) < MAX_PATH ? (Pend*)malloc(sizeof(Pend) + len) : nullptr;
        if (q) { q->next = nullptr; strcpy(q->path, path); q->len = len; memcpy(q->text, text, len); *g_pendTail = q; g_pendTail = &q->next; }
        ReleaseSRWLockExclusive(&g_pendLock);
        return;
    }
    ReleaseSRWLockExclusive(&g_pendLock);
    AcquireSRWLockShared(&g_lock);
    HANDLE f = CreateFileA(path, FILE_APPEND_DATA, FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
    bool over = false;
    if (f != INVALID_HANDLE_VALUE) {
        DWORD w; WriteFile(f, text, len, &w, nullptr);
        LARGE_INTEGER size;
        if (CheckDue(path) && GetFileSizeEx(f, &size) && size.QuadPart > (LONGLONG)cap) over = true;
        CloseHandle(f);
    }
    ReleaseSRWLockShared(&g_lock);
    if (over) TrimLater(path, cap);
}
static void Append(const char* path, const char* text, DWORD cap) { Append(path, text, (DWORD)strlen(text), cap); }

// Logs that are already past their cap (from before caps existed) are cut down once at startup, on one worker thread.
struct StartJob { int n; char path[12][MAX_PATH]; DWORD cap[12]; };
static DWORD WINAPI StartThread(LPVOID p) {
    StartJob* j = (StartJob*)p;
    for (int i = 0; i < j->n; ++i) {
        WIN32_FILE_ATTRIBUTE_DATA a;
        if (!GetFileAttributesExA(j->path[i], GetFileExInfoStandard, &a) || (!a.nFileSizeHigh && a.nFileSizeLow <= j->cap[i])) continue;
        TrimLocked(j->path[i], j->cap[i] / 2);
    }
    free(j);
    return 0;
}
static StartJob* g_start = nullptr;
static void StartupAdd(const char* path, DWORD cap) {
    if (!g_start) { g_start = (StartJob*)calloc(1, sizeof(StartJob)); if (!g_start) return; }
    if (g_start->n >= 12 || strlen(path) >= MAX_PATH) return;
    strcpy(g_start->path[g_start->n], path); g_start->cap[g_start->n++] = cap;
}
static void StartupRun() {
    if (!g_start) return;
    StartJob* j = g_start; g_start = nullptr;
    HANDLE t = CreateThread(nullptr, 0, StartThread, j, 0, nullptr);
    if (t) CloseHandle(t); else free(j);
}

// caps (bytes)
static const DWORD kMainMenu = 2u << 20;     // mainmenu.log
static const DWORD kClient = 2u << 20;       // client.log
static const DWORD kCrash = 1u << 20;        // crash.log
static const DWORD kSmall = 256u << 10;      // padhub.log, skinsync.log, throwstock.log
static const DWORD kHostDebug = 5u << 20;    // thugrecomp_debug.log (host)
static const DWORD kHostSmall = 1u << 20;    // lastskater_debug.log, name_history.txt (host)
static const DWORD kSoundLog = 5u << 20;     // soundlog.txt (Dev only, off by default)

// At startup every known log that is already over its cap (older versions had no caps) is cut down once.
struct Boot {
    Boot() {
        char dir[MAX_PATH];
        DWORD n = GetModuleFileNameA(nullptr, dir, MAX_PATH);
        while (n > 0 && dir[n - 1] != '\\') --n;
        dir[n] = 0;
        static const struct { const char* name; const DWORD* cap; } kLogs[] = {
            {"mainmenu.log", &kMainMenu}, {"client.log", &kClient}, {"crash.log", &kCrash}, {"padhub.log", &kSmall},
            {"skinsync.log", &kSmall}, {"throwstock.log", &kSmall}, {"thugrecomp_debug.log", &kHostDebug},
            {"lastskater_debug.log", &kHostSmall}, {"name_history.txt", &kHostSmall}, {"soundlog.txt", &kSoundLog}};
        for (auto& l : kLogs) {
            char p[MAX_PATH + 64];
            _snprintf(p, sizeof p, "%sdadmod\\%s", dir, l.name); p[sizeof p - 1] = 0;
            StartupAdd(p, *l.cap);
        }
        StartupRun();
    }
};

static Boot g_boot;  // runs when the DLL loads

}  // namespace logcap
