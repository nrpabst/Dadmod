// Copy Scales From... / Copy Tricks From... (mods/skatercopy, Noah 2026-11-20).
// Reads another saved skater (<game>\Save\*.SKA) without changing it, so Edit Skater's scaling menu and the
// Edit Tricks menu can put that skater's body scales or trick setup on the skater being edited.
// Our own code. The save is checked (size, version, checksum) and then read by the game's own reader, so the
// result is exactly what the game would load. Nothing is written to any save file.
//
//   THUGRECOMP_SkcCount                -> <count> saved skaters (rescans the Save folder)
//   THUGRECOMP_SkcName index = N       -> <name> (file name without .SKA)
//   THUGRECOMP_SkcScales index = N     -> changes the CALLER'S local struct <skc_app> (an appearance from
//                                         GetPlayerAppearance): every body scale becomes the saved skater's;
//                                         scales that skater left at normal go back to normal. false = unreadable
//                                         Without index: the scales come from the caller's local <skc_from> (undo)
//   THUGRECOMP_SkcTricks index = N     -> <skc_trick_mapping> (struct) + <skc_specials> (count, up to 12);
//                                         false = unreadable or no trick setup in that save
//   THUGRECOMP_SkcSpecial index = N    -> from the last SkcTricks: <slot> <trick> (checksums; trick is an int
//                                         when <cat> = 1, a created trick number)
namespace skc {

static const DWORD kCtor        = 0x476410;  // CStruct::CStruct (thiscall)
static const DWORD kDtor        = 0x477130;  // CStruct::~CStruct (thiscall)
static const DWORD kReadBuffer  = 0x47A0C0;  // BYTE* __cdecl ReadFromBuffer(CStruct*, const BYTE*) (memcard load uses it)
static const DWORD kAppend      = 0x478480;  // CStruct::AppendStructure(const CStruct*) (thiscall): deep copy, same name+type replaces
static const DWORD kAddInt      = 0x477B80;  // CStruct::AddInteger(name, int) (thiscall)
static const DWORD kAddSum      = 0x477D40;  // CStruct::AddChecksum(name, checksum) (thiscall)
static const DWORD kGetStruct   = 0x4767C0;  // CStruct::GetStructure(name, CStruct**, assert) (thiscall)

// engine layouts: CStruct { ?, Comp* head @+4 }; Comp { BYTE type<<1 | flag, ?, short, DWORD name @+4,
// DWORD value @+8, Comp* next @+0xC }; CArray { BYTE type, BYTE flag, ?, ?, DWORD size @+4, data @+8 (the one
// element itself when size == 1) }
enum { T_INT = 1, T_STRUCT = 10, T_STRUCTPTR = 11, T_ARRAY = 12, T_NAME = 13 };
static BYTE* Head(void* st) { return *(BYTE**)((BYTE*)st + 4); }
static BYTE* Next(BYTE* c) { return *(BYTE**)(c + 0xC); }
static int Type(BYTE* c) { return c[0] >> 1; }
static DWORD Name(BYTE* c) { return *(DWORD*)(c + 4); }
static DWORD Val(BYTE* c) { return *(DWORD*)(c + 8); }
static BYTE* Find(void* st, DWORD name) {
    for (BYTE* c = st ? Head(st) : nullptr; c; c = Next(c)) if (Name(c) == name) return c;
    return nullptr;
}
static void* FindStruct(void* st, const char* name) {
    BYTE* c = Find(st, QbKey(name));
    return c && (Type(c) == T_STRUCT || Type(c) == T_STRUCTPTR) ? (void*)Val(c) : nullptr;
}

struct Save { std::string name, path; };
static std::vector<Save> g_saves;

static std::string SaveDir() {
    char exe[MAX_PATH];
    DWORD n = GetModuleFileNameA(nullptr, exe, MAX_PATH);
    if (!n || n >= MAX_PATH) return "";
    char* slash = strrchr(exe, '\\');
    if (!slash) return "";
    slash[1] = 0;
    return std::string(exe) + "Save\\";
}
static bool LessNoCase(const Save& a, const Save& b) { return _stricmp(a.name.c_str(), b.name.c_str()) < 0; }
static void Scan() {
    g_saves.clear();
    std::string dir = SaveDir();
    if (dir.empty()) return;
    WIN32_FIND_DATAA fd;
    HANDLE h = FindFirstFileA((dir + "*.SKA").c_str(), &fd);
    if (h == INVALID_HANDLE_VALUE) return;
    do {
        if (fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) continue;
        std::string f = fd.cFileName;
        if (f.size() < 5 || _stricmp(f.c_str() + f.size() - 4, ".SKA")) continue;
        g_saves.push_back({ f.substr(0, f.size() - 4), dir + f });
    } while (FindNextFileA(h, &fd));
    FindClose(h);
    std::sort(g_saves.begin(), g_saves.end(), LessNoCase);
}

// Neversoft CRC32 (init 0xFFFFFFFF, no final xor, bytes as they are)
static DWORD Crc(const BYTE* p, size_t n) {
    DWORD c = 0xFFFFFFFF;
    for (size_t i = 0; i < n; ++i) {
        c ^= p[i];
        for (int k = 0; k < 8; ++k) c = (c >> 1) ^ ((c & 1) ? 0xEDB88320 : 0);
    }
    return c;
}

// Reads save #idx into root (constructed by the caller). Only a save the game itself wrote (right size, version,
// both checksums) reaches the game's reader, so a broken file can never crash it.
static bool Load(int idx, void* root) {
    if (idx < 0 || idx >= (int)g_saves.size()) return false;
    std::string d;
    if (!ReadWholeFile(g_saves[idx].path, d) || d.size() < 0x20 || d.size() > 4 * 1024 * 1024) return false;
    const BYTE* b = (const BYTE*)d.data();
    DWORD crc = *(DWORD*)b, scrc = *(DWORD*)(b + 4), ssize = *(DWORD*)(b + 8), total = *(DWORD*)(b + 12), ver = *(DWORD*)(b + 16);
    if (ver != 38 || total > d.size() || ssize > total || 20 + ssize >= total) {
        mmenu::Log("skatercopy: %s is not a skater save (version %u)", g_saves[idx].name.c_str(), ver);
        return false;
    }
    std::string z(d, 0, total);
    memset(&z[0], 0, 4);
    if (Crc((const BYTE*)z.data(), total) != crc || Crc(b + 20, ssize) != scrc) {
        mmenu::Log("skatercopy: %s failed its checksum, not read", g_saves[idx].name.c_str());
        return false;
    }
    if (b[total - 1] != 0) return false;                      // the data struct ends with its end byte
    typedef const BYTE* (__cdecl* ReadFn)(void*, const BYTE*);
    const BYTE* end = ((ReadFn)kReadBuffer)(root, b + 20 + ssize);
    if (end != b + total) mmenu::Log("skatercopy: %s read %d bytes short", g_saves[idx].name.c_str(), (int)(b + total - end));
    return true;
}
static void* Custom(void* root) {
    void* cs = FindStruct(root, "CustomSkater");
    return cs ? FindStruct(cs, "custom") : nullptr;
}

typedef void (__thiscall* CtorFn)(void*);
typedef void (__thiscall* AppendFn)(void*, void*);
typedef void (__thiscall* AddIntFn)(void*, DWORD, int);
typedef void (__thiscall* AddSumFn)(void*, DWORD, DWORD);
typedef char (__thiscall* GetStructFn)(void*, DWORD, void**, int);

static void* Locals(void* script) { return script ? *(void**)((char*)script + 0x14) : nullptr; }

static bool __cdecl CF_SkcCount(void* params, void* script) {
    Scan();
    RetInt(script, "count", (int)g_saves.size());
    return true;
}
static bool __cdecl CF_SkcName(void* params, void* script) {
    int i = IntParam(params, "index", -1);
    if (i < 0 || i >= (int)g_saves.size()) return false;
    RetStr(script, "name", g_saves[i].name.c_str());
    return true;
}

// the scale entries of an appearance (Edit Skater's scaling menu, all of them)
static const char* kScaleNames[] = {
    "object_scaling", "headtop_bone_group", "head_bone_group", "nose_bone_group", "jaw_bone_group",
    "torso_bone_group", "stomach_bone_group", "upper_arm_bone_group", "lower_arm_bone_group", "hands_bone_group",
    "upper_leg_bone_group", "lower_leg_bone_group", "feet_bone_group", "board_bone_group", "wheels_bone_group",
};
static bool IsScale(DWORD name) {
    for (const char* n : kScaleNames) if (QbKey(n) == name) return true;
    return false;
}

static bool __cdecl CF_SkcScales(void* params, void* script) {
    int idx = IntParam(params, "index", -1);
    void* target = nullptr;
    void* loc = Locals(script);
    if (!loc || !((GetStructFn)kGetStruct)(loc, QbKey("skc_app"), &target, 0) || !target) return false;
    BYTE root[16] = {0}, rest[16] = {0};
    ((CtorFn)kCtor)(root);
    ((CtorFn)kCtor)(rest);
    bool ok = false;
    void* src = nullptr;
    if (idx >= 0) {
        if (Load(idx, root)) src = FindStruct(Custom(root), "appearance");
    } else {                                                   // undo: the caller's local <skc_from> (a copy is used)
        void* from = nullptr;
        if (((GetStructFn)kGetStruct)(loc, QbKey("skc_from"), &from, 0) && from) { ((AppendFn)kAppend)(root, from); src = root; }
    }
    {
        if (src) {
            // keep only the scale entries in the saved skater's appearance; the rest moves to `rest` (freed below)
            BYTE* keep = nullptr; BYTE** kt = &keep;
            BYTE* drop = nullptr; BYTE** dt = &drop;
            for (BYTE* c = Head(src); c; ) {
                BYTE* nx = Next(c);
                *(BYTE**)(c + 0xC) = nullptr;
                if ((Type(c) == T_STRUCT || Type(c) == T_STRUCTPTR) && IsScale(Name(c))) { *kt = c; kt = (BYTE**)(c + 0xC); }
                else { *dt = c; dt = (BYTE**)(c + 0xC); }
                c = nx;
            }
            *(BYTE**)((BYTE*)src + 4) = keep;
            *(BYTE**)(rest + 4) = drop;
            // a scale the saved skater never changed isn't in its save: put ours back to normal
            int reset = 0, copied = 0;
            for (BYTE* c = Head(target); c; c = Next(c)) {
                if ((Type(c) != T_STRUCT && Type(c) != T_STRUCTPTR) || !IsScale(Name(c)) || Find(src, Name(c))) continue;
                void* g = (void*)Val(c);
                ((AddIntFn)kAddInt)(g, QbKey("x"), 100);
                ((AddIntFn)kAddInt)(g, QbKey("y"), 100);
                ((AddIntFn)kAddInt)(g, QbKey("z"), 100);
                ((AddIntFn)kAddInt)(g, QbKey("use_default_scale"), 1);
                ++reset;
            }
            for (BYTE* c = Head(src); c; c = Next(c)) ++copied;
            ((AppendFn)kAppend)(target, src);
            mmenu::Log("skatercopy: scales from %s (%d copied, %d back to normal)", idx >= 0 ? g_saves[idx].name.c_str() : "undo", copied, reset);
            ok = true;
        }
    }
    ((CtorFn)kDtor)(rest);
    ((CtorFn)kDtor)(root);
    return ok;
}

struct Special { DWORD slot, trick; bool cat; };
static std::vector<Special> g_specials;

static bool __cdecl CF_SkcTricks(void* params, void* script) {
    int idx = IntParam(params, "index", -1);
    void* loc = Locals(script);
    if (!loc) return false;
    g_specials.clear();
    BYTE root[16] = {0}, out[16] = {0};
    ((CtorFn)kCtor)(root);
    ((CtorFn)kCtor)(out);
    bool ok = false;
    if (Load(idx, root)) {
        void* info = FindStruct(Custom(root), "info");
        BYTE* tm = info ? Find(info, QbKey("trick_mapping")) : nullptr;
        if (tm && (Type(tm) == T_STRUCT || Type(tm) == T_STRUCTPTR)) {
            // hand trick_mapping over under our own name: move that one entry into `out`, append, move it back
            BYTE** link = (BYTE**)((BYTE*)info + 4);
            while (*link != tm) link = (BYTE**)(*link + 0xC);
            *link = Next(tm);
            *(BYTE**)(tm + 0xC) = nullptr;
            DWORD oldName = Name(tm);
            *(DWORD*)(tm + 4) = QbKey("skc_trick_mapping");
            *(BYTE**)(out + 4) = tm;
            ((AppendFn)kAppend)(loc, out);
            *(DWORD*)(tm + 4) = oldName;
            *(BYTE**)(out + 4) = nullptr;
            *(BYTE**)(tm + 0xC) = *link;
            *link = tm;
            // specials { [ { trickname trickslot } ... ] }
            void* sp = FindStruct(info, "specials");
            BYTE* arr = sp ? Head(sp) : nullptr;
            while (arr && Type(arr) != T_ARRAY) arr = Next(arr);
            if (arr && Val(arr)) {
                BYTE* a = (BYTE*)Val(arr);
                DWORD n = *(DWORD*)(a + 4);
                for (DWORD i = 0; i < n && i < 12; ++i) {
                    void* e = (void*)(n == 1 ? *(DWORD*)(a + 8) : ((DWORD*)*(DWORD*)(a + 8))[i]);
                    if ((a[0] != T_STRUCT && a[0] != T_STRUCTPTR) || !e) break;
                    BYTE* tn = Find(e, QbKey("trickname"));
                    BYTE* ts = Find(e, QbKey("trickslot"));
                    Special s = { QbKey("Unassigned"), QbKey("Unassigned"), false };
                    if (ts && Type(ts) == T_NAME) s.slot = Val(ts);
                    if (tn && Type(tn) == T_NAME) s.trick = Val(tn);
                    else if (tn && Type(tn) == T_INT) { s.trick = Val(tn); s.cat = true; }
                    g_specials.push_back(s);
                }
            }
            RetInt(script, "skc_specials", (int)g_specials.size());
            mmenu::Log("skatercopy: tricks from %s (%d specials)", g_saves[idx].name.c_str(), (int)g_specials.size());
            ok = true;
        }
    }
    ((CtorFn)kDtor)(out);
    ((CtorFn)kDtor)(root);
    return ok;
}
static bool __cdecl CF_SkcSpecial(void* params, void* script) {
    int i = IntParam(params, "index", -1);
    void* loc = Locals(script);
    if (i < 0 || i >= (int)g_specials.size() || !loc) return false;
    ((AddSumFn)kAddSum)(loc, QbKey("slot"), g_specials[i].slot);
    if (g_specials[i].cat) ((AddIntFn)kAddInt)(loc, QbKey("trick"), (int)g_specials[i].trick);
    else ((AddSumFn)kAddSum)(loc, QbKey("trick"), g_specials[i].trick);
    RetInt(script, "cat", g_specials[i].cat ? 1 : 0);
    return true;
}

}  // namespace skc
