// cars2: driving input remap (Noah 2026-11-20, "the keyboard controls are really bad. it should use wsad to drive").
//
// The stock car (CVehicleComponent input, 0x4376B0) reads the car's input component pad (+0x1314; the CPad
// sits at +0x20 in it, buttons are 0x20 apart, constructor 0x46B940): X (+0x1C0) = gas, Square (+0x180) = brake
// then reverse, R1 (+0x100) = handbrake unless the setup has no_handbrake (car +0x2CD), Triangle (+0x1A0,
// Exitable cars) = brake and get out once stopped, left stick X / d-pad left-right = steer.
// The player's movement keys only move the left stick, so Forward/Backward did nothing in a car.
//
// The control block ReadControls (0x5F5BC0) builds for player 1: +4 d-pad/buttons WORD, +6 ollie (X), +7 grab
// (Circle), +8 flip (Square), +9 grind (Triangle), +0xA/+0xB the "l1"/"r1" bind slots (an extra pad byte only),
// +0xC/+0xD the "l2"/"r2" bind slots (PS2 L1+L2 / R1+R2, FUN_005BD200), +0x10 left stick Y.
// Left stick Y is POSITIVE for forward: the Forward key (bind slot 0) writes +0x7FFF, Backward -0x7FFF
// (Noah 2026-11-21 "for me s accelerates and w brakes": this file had up as negative before).
//
// While the local skater drives (QB dadmod_cars_watch sends THUGRECOMP_CarsDrive on=1 every few frames):
//   forward (stick Y > 40% or d-pad up) -> X = gas, backward (stick Y < -40% or d-pad down) -> Square = brake
//   Space, Numpad 9, controller RB (R1) -> +0xB (the "r1" bind slot 15) = handbrake; Space's own bind is cleared.
//   Fix 3 (Noah 2026-11-21 "space doesn't handbrake the car but numpad 3 does"): his slot 15 is Numpad 3 and slot 17
//   Numpad 9, so the car's R1 really comes from +0xB; +0xD (fix 2, from the FUN_005BD200 reading) did nothing.
//   Backspace (tap) -> holds Triangle until the car has stopped and you are out (stock exit), bind cleared
// Never stuck on: it is active only while the last on=1 is under kStaleMs old, the game is not paused
// (0x6FA7D4, the byte GameIsPaused reads) and the last call wasn't on=0. Every exit path in cars2.q sends on=0.
namespace cars2 {

static const DWORD kStaleMs = 1000;  // the driver script beats every 3 frames; 1 s rides out slow frames
static const DWORD kPausedByte = 0x6FA7D4;
static const DWORD kKbMode = 0x7D6A3C;   // ReadControls keyboard mode: 1 / 3 = fixed keys (Space = start there)
static const DWORD kExitHoldMs = 6000;   // Backspace keeps Triangle held this long at most
static const int kDikSpace = 0x39, kDikBack = 0x0E, kDikNum9 = 0x49;
static volatile LONG g_on;            // last THUGRECOMP_CarsDrive on=
static volatile DWORD g_beat;         // GetTickCount of the last on=1
static bool g_active;                 // remap applied on the last read (for the on/off log)
static volatile LONG g_testDir, g_testReads;  // test aid: pretend forward (1) / backward (-1) for N reads
static volatile LONG g_testKey, g_testKeyReads;  // test aid: pretend this DIK key is down for N reads
static DWORD g_exitSince;             // Backspace pressed: hold Triangle from then
static bool g_backWas;
// 2026-11-24 (log 2026-11-23 19:05: got in the NY Cab and was out again 1 s later): a Triangle / grind key still held
// from the menu pick made the stopped car ask to get out at once. Triangle now counts only after it was let go once
// since the remap turned on (each car you get in).
static bool g_triArmed;

static const char* State() {
    if (!g_on) return "turned off: not driving, or a menu is open";
    if (GetTickCount() - g_beat > kStaleMs) return "driver script stopped";
    if (*(volatile BYTE*)kPausedByte) return "game paused";
    return nullptr;
}

static bool KeyDown(int dik) {
    if (g_testKeyReads > 0 && g_testKey == dik) return true;
    return dik > 0 && dik < 256 && (((const BYTE*)padhub::kKeyState)[dik] & 0x80) != 0;
}

// Undo what a keyboard key did to the control block through the player's binds (slot -> block, ReadControls).
static void ClearKey(BYTE* out, int dik) {
    const int* kb = (const int*)padhub::kKb0Binds;
    for (int s = 8; s < 20; ++s) {
        if (kb[s] != dik) continue;
        switch (s) {
        case 8: out[6] = 0; break;   case 9: out[7] = 0; break;
        case 10: out[8] = 0; break;  case 11: out[9] = 0; break;
        case 13: out[4] &= ~0x20; break;
        case 14: out[0xA] = 0; break; case 15: out[0xB] = 0; break;
        case 16: out[0xC] = 0; break; case 17: out[0xD] = 0; break;
        case 18: out[4] &= ~0x40; break; case 19: out[4] &= ~0x80; break;
        }
    }
    LONG mode = *(volatile LONG*)kKbMode;
    if (mode == 1 || mode == 3) {   // fixed-key mode: Space = start (0x10), Backspace = select (0x20)
        if (dik == kDikSpace && !KeyDown(1)) out[4] &= ~0x10;
        if (dik == kDikBack) out[4] &= ~0x20;
    }
}

static void HornPoll();
// From gfx ReadControlsHook, player 1 only, after the engine filled the block.
static void Remap(BYTE* out) {
    if (!out) return;
    const char* off = State();
    bool active = off == nullptr;
    if (active != g_active) {
        g_active = active;
        if (active) { g_triArmed = false; mmenu::Log("cars2: driving remap on (forward = gas, back = brake, Space/RB handbrake, Backspace out)"); }
        else mmenu::Log("cars2: driving remap off (%s)", off);
    }
    if (g_testKeyReads > 0) --g_testKeyReads;
    if (!active) { g_testReads = 0; g_exitSince = 0; g_backWas = false; return; }
    if (g_testReads > 0) {
        --g_testReads;
        *(short*)(out + 0x10) = g_testDir > 0 ? 32767 : -32767;
    }
    short ly = *(short*)(out + 0x10);
    WORD dpad = *(WORD*)(out + 4);
    HornPoll();
    if (KeyDown(0x23)) ClearKey(out, 0x23);

    bool space = KeyDown(kDikSpace), back = KeyDown(kDikBack);
    if (space) ClearKey(out, kDikSpace);
    if (back) ClearKey(out, kDikBack);
    bool rb = (((DWORD)padhub::g_padButtons >> padhub::B_RB) & 1) != 0;
    bool hand = space || KeyDown(kDikNum9) || rb;

    if (back && !g_backWas) { g_exitSince = GetTickCount(); mmenu::Log("cars2: Backspace, getting out"); }
    g_backWas = back;
    if (g_exitSince && GetTickCount() - g_exitSince > kExitHoldMs) g_exitSince = 0;

    if (!g_triArmed) {             // Triangle held since before getting in: ignore it until it is let go
        if (out[9] == 0) g_triArmed = true;
        else out[9] = 0;
    }
    if (g_exitSince) {             // stock exit: Triangle brakes to a stop, then ExitVehicleRequest
        out[6] = 0;
        out[9] = 0xFF;
        return;
    }
    // 2026-11-21 (Noah: "if you're on gamepad you can accelerate and brake with the left joystick. we want that to not
    // happen"): gas / brake come from the KEYBOARD Forward / Backward keys only (bind slots 0 / 1; in the fixed-key
    // modes also W/S and Up/Down), not from left stick Y or the d-pad, so a controller keeps its stock buttons
    // (X / A gas, Square / X brake) and its stick only steers. (ly / dpad are no longer used for gas / brake.)
    (void)ly; (void)dpad;
    const int* kb = (const int*)padhub::kKb0Binds;
    LONG mode = *(volatile LONG*)kKbMode;
    bool fixedKeys = mode == 1 || mode == 3;
    bool fwd = KeyDown(kb[0]) || (fixedKeys && (KeyDown(0x11) || KeyDown(0xC8)));
    bool rev = KeyDown(kb[1]) || (fixedKeys && (KeyDown(0x1F) || KeyDown(0xD0)));
    if (g_testReads > 0) { fwd = g_testDir > 0; rev = g_testDir < 0; }
    if (fwd) out[6] = 0xFF;    // forward key -> X = gas
    if (rev) out[8] = 0xFF;    // backward key -> Square = brake / reverse
    if (hand) out[0xB] = 0xFF;                       // -> the button Numpad 3 / RB feed = handbrake
}

// ---- GTA 3 style steering (Noah 2026-11-21 "make the handling for the cars in dadmod work like gta 3") ----
// The car's input step 0x4376B0 (__fastcall, ECX = vehicle component) writes the steer value to +0x304 (|stick| *
// stick, or exactly +-1 from the d-pad / A-D keys) and the steering code 0x435F00 turns it into a wheel angle
// (max_steering_angle * steer) with no speed sensitivity. Its only caller is 0x43C1E9 in the vehicle update; we
// redirect that call, run the stock step, then: ramp the steer value (full lock in ~0.18 s, back to center faster)
// and scale it down with speed (100% standing still, 45% at ~85 mph). Only while the driving remap is on (the local
// player drives) and the handling option is GTA 3 (THUGRECOMP_CarsDrive gta=1, the default).
// Speed = distance the component's position (+0x18) moved per second, smoothed.
static volatile LONG g_gta = 1;
static volatile LONG g_horn;          // horn presses since the QB beat last asked
static bool g_hornWas;
static const DWORD kSteerCall = 0x43C1E9, kSteerFn = 0x4376B0;
static float g_steer, g_speed, g_lastPos[3];
static BYTE* g_lastComp;
static LARGE_INTEGER g_lastT, g_freq;
static DWORD g_steerLogAt;

static void __fastcall SteerHook(BYTE* comp) {
    ((void(__fastcall*)(BYTE*))kSteerFn)(comp);
    if (!comp) return;
    LARGE_INTEGER now; QueryPerformanceCounter(&now);
    if (!g_freq.QuadPart) QueryPerformanceFrequency(&g_freq);
    float dt = g_lastT.QuadPart ? (float)((double)(now.QuadPart - g_lastT.QuadPart) / (double)g_freq.QuadPart) : 0.f;
    g_lastT = now;
    const float* pos = (const float*)(comp + 0x18);
    bool fresh = comp != g_lastComp || dt <= 0.f || dt > 0.25f;
    if (!fresh) {
        float dx = pos[0] - g_lastPos[0], dy = pos[1] - g_lastPos[1], dz = pos[2] - g_lastPos[2];
        float v = sqrtf(dx * dx + dy * dy + dz * dz) / dt;
        if (v > 6000.f) v = g_speed;                       // teleport / reset: ignore
        float k = dt * 6.f; if (k > 1.f) k = 1.f;
        g_speed += (v - g_speed) * k;
    } else { g_speed = 0.f; g_steer = 0.f; }
    g_lastComp = comp;
    g_lastPos[0] = pos[0]; g_lastPos[1] = pos[1]; g_lastPos[2] = pos[2];
    if (!g_gta || State() != nullptr) { g_steer = 0.f; return; }
    float* st = (float*)(comp + 0x304);
    float target = *st;
    if (dt > 0.1f) dt = 0.1f;
    float rate = (target == 0.f || target * g_steer < 0.f) ? 9.f : 5.5f;
    float diff = target - g_steer, step = rate * dt;
    g_steer += diff > step ? step : (diff < -step ? -step : diff);
    if (target == 0.f && fabsf(g_steer) < 0.03f) g_steer = 0.f;
    float f = g_speed / 1500.f; if (f > 1.f) f = 1.f;
    *st = g_steer * (1.f - 0.55f * f);
    if (GetTickCount() - g_steerLogAt > 3000) {
        g_steerLogAt = GetTickCount();
        mmenu::Log("cars2: gta steering speed %.0f in/s (%.0f mph) steer in %.2f out %.2f", g_speed, g_speed / 17.6f, target, *st);
    }
}

// 2026-11-21 (Noah: "ok nvm lets just use thugpro stock handling"): the GTA 3 steering hook is no longer installed
// (SteerHook stays as reference, unused). 2026-11-24: the same call site 0x43C1E9 now goes to TrackHook (stock input step,
// then the respawn / flip-back tracker below); Install() also adds the wheel-bone guard.
//
// Wheel-bone guard (props crashed at 0x43BA80 reading 0x1D0): the vehicle's finalize step 0x43BA20 asks the body
// model for its bone list (call 0x493040 at 0x43BA62, ECX = model's skeleton data) and reads the four wheel
// positions from it without a NULL check. A model with no car bones (a prop .mdl) returns NULL. The guard hands back
// a zeroed dummy list instead, so a bad body model can never crash (its wheels just all sit at the middle).
static const DWORD kBonesCall = 0x43BA62, kBonesFn = 0x493040;
static BYTE g_dummyBones[0x800];
static void* __fastcall BonesGuard(void* ecx, void* /*edx*/) {
    void* r = ecx ? ((void*(__thiscall*)(void*))kBonesFn)(ecx) : nullptr;
    if (!r) {
        static DWORD s_logAt;
        if (GetTickCount() - s_logAt > 5000) { s_logAt = GetTickCount(); mmenu::Log("cars2: car body model has no wheel bones, using a blank set (no crash)"); }
        memset(g_dummyBones, 0, sizeof g_dummyBones);
        return g_dummyBones;
    }
    return r;
}

// ---- Respawn at the last safe spot + flip back (Noah 2026-11-24: "i drove into the water and my car respawned face
// down in a ramp") ----
// Stock recovery is all QB: a water / kill trigger runs SK3_KillSkater(_Water) -> SK3_Killskater_Finish (hides the car
// 0.5 s for water) -> SK3_Killskater_Finish3, which while Driving does PlayerVehicle : Vehicle_MoveToRestart <node>
// (the trigger's restart node, else trg_playerrestart: skater restart points, often on or next to ramps) and
// PlayerVehicleCamera : VehicleCamera_Reset. The car is dropped there with whatever spin it had.
// Vehicle component (ECX of the input step 0x4376B0, called first thing in the update 0x43C1D0 at 0x43C1E9):
//   +0x18 pos, +0x28 momentum, +0x38 orientation quaternion (x y z w), +0x48 angular momentum, +0x58 awake (1),
//   +0x5C sleep timer, +0x64 matrix rows right / up (+0x74, up.y = +0x78) / forward (+0x84) / +0x94 (0 0 0 1),
//   +0xA4 velocity, +0xB4 angular velocity, +0x114 wheels touching, +0x190 wheel count, +0x11A stock self-right state.
//   Quaternion <-> matrix: 0x42E1F0 (thiscall, ECX = quat out, arg = matrix), 0x42BC40 (ECX = quat, arg = matrix out),
//   both used by the stock self-righting 0x438770 (which builds the upright matrix right = (fz,0,-fx), up = (0,1,0),
//   forward = (fx,0,fz) the same way as below).
// What we do, only on the local player's car (object id PlayerVehicle) while the driving beat runs:
//   - every 0.5 s with all wheels down, up.y > 0.9 and not dropping fast: remember pos + heading (4 kept)
//   - the car jumps (stock recovery teleport: > 300 units at > 6000 units/s) or has had no wheel down for 4 s and is
//     2500 below the best spot: put it back at the newest spot at least 1 s old (else the newest, else where you got
//     in), lifted a bit, upright, facing that heading, no speed or spin; the QB beat then resets the car camera
//   - tipped (up.y < 0.3), nearly still for 3 s: stand it up at the same spot, lifted, same heading
static const DWORD kSafeSampleMs = 500, kFallMs = 4000, kTipMs = 3000;
struct Spot { float p[3]; float fx, fz; DWORD t; };
static Spot g_spots[4];
static int g_nSpots;
static Spot g_entry;
static BYTE* g_tComp;
static DWORD g_tSeen, g_sampleAt, g_airSince, g_tipSince, g_ignoreUntil;
static float g_tLast[3];
static LARGE_INTEGER g_tT;
static volatile LONG g_camReset;
static DWORD g_pvId;
static bool g_idWarned;

static DWORD QbKey(const char* s) {
    DWORD c = 0xFFFFFFFF;
    for (; *s; ++s) {
        BYTE b = (BYTE)*s; if (b >= 'A' && b <= 'Z') b += 32;
        c ^= b;
        for (int k = 0; k < 8; ++k) c = (c >> 1) ^ (0xEDB88320 & (0 - (c & 1)));
    }
    return c;
}
static bool IsPlayerVehicle(BYTE* comp) {
    if (!g_pvId) g_pvId = QbKey("PlayerVehicle");
    BYTE* obj = *(BYTE**)(comp + 0xC);
    if (!obj || IsBadReadPtr(obj, 0x40)) return false;
    for (int o = 4; o < 0x40; o += 4) if (*(DWORD*)(obj + o) == g_pvId) return true;
    if (!g_idWarned) { g_idWarned = true; mmenu::Log("cars2: car object has no PlayerVehicle id, respawn tracker idle for it"); }
    return false;
}
static void Heading(BYTE* comp, float& fx, float& fz) {
    const float* m = (const float*)(comp + 0x64);
    fx = m[8]; fz = m[10];
    float l = sqrtf(fx * fx + fz * fz);
    if (l < 0.3f) { fx = m[4]; fz = m[6]; l = sqrtf(fx * fx + fz * fz); }   // standing on its nose: use the roof
    if (l < 0.01f) { fx = 0.f; fz = 1.f; return; }
    fx /= l; fz /= l;
}
static void PlaceUpright(BYTE* comp, const float p[3], float lift, float fx, float fz) {
    float l = sqrtf(fx * fx + fz * fz);
    if (l < 0.01f) { fx = 0.f; fz = 1.f; } else { fx /= l; fz /= l; }
    float m[16] = { fz, 0.f, -fx, 0.f,  0.f, 1.f, 0.f, 0.f,  fx, 0.f, fz, 0.f,  0.f, 0.f, 0.f, 1.f };
    float q[4] = { 0.f, 0.f, 0.f, 1.f };
    ((void(__thiscall*)(float*, float*))0x42E1F0)(q, m);
    float* f = (float*)comp;
    f[0x18 / 4] = p[0]; f[0x1C / 4] = p[1] + lift; f[0x20 / 4] = p[2];
    for (int i = 0; i < 3; ++i) { f[0x28 / 4 + i] = 0.f; f[0x48 / 4 + i] = 0.f; f[0xA4 / 4 + i] = 0.f; f[0xB4 / 4 + i] = 0.f; }
    for (int i = 0; i < 4; ++i) f[0x38 / 4 + i] = q[i];
    ((void(__thiscall*)(float*, float*))0x42BC40)(f + 0x38 / 4, f + 0x64 / 4);
    f[0x94 / 4] = 0.f; f[0x98 / 4] = 0.f; f[0x9C / 4] = 0.f; f[0xA0 / 4] = 1.f;
    comp[0x11A] = 0;
    *(int*)(comp + 0x58) = 1; *(int*)(comp + 0x5C) = 0;
    g_tLast[0] = p[0]; g_tLast[1] = p[1] + lift; g_tLast[2] = p[2];
    g_ignoreUntil = GetTickCount() + 1000;
    g_airSince = 0; g_tipSince = 0;
    InterlockedExchange(&g_camReset, 1);
}
static const Spot& BestSpot() {
    DWORD now = GetTickCount();
    for (int i = g_nSpots - 1; i >= 0; --i) if (now - g_spots[i].t >= 1000) return g_spots[i];
    if (g_nSpots) return g_spots[g_nSpots - 1];
    return g_entry;
}
static void Respawn(BYTE* comp, const char* why) {
    const Spot& s = BestSpot();
    char line[200];
    _snprintf(line, sizeof line, "cars2: respawn at last safe spot (%s) %.0f %.0f %.0f%s", why, s.p[0], s.p[1], s.p[2],
              g_nSpots ? "" : " (where you got in)");
    line[sizeof line - 1] = 0;
    Spot c = s;
    PlaceUpright(comp, c.p, 15.f, c.fx, c.fz);
    ::DebugLog(line);
}
static void Track(BYTE* comp) {
    DWORD now = GetTickCount();
    if (*(volatile BYTE*)kPausedByte || now - g_beat > 5000 || !IsPlayerVehicle(comp)) return;
    const float* f = (const float*)comp;
    const float* pos = f + 0x18 / 4;
    LARGE_INTEGER t; QueryPerformanceCounter(&t);
    if (!g_freq.QuadPart) QueryPerformanceFrequency(&g_freq);
    if (comp != g_tComp || now - g_tSeen > 1000) {
        g_tComp = comp; g_nSpots = 0; g_airSince = 0; g_tipSince = 0; g_sampleAt = now;
        g_entry.p[0] = pos[0]; g_entry.p[1] = pos[1]; g_entry.p[2] = pos[2]; g_entry.t = now;
        Heading(comp, g_entry.fx, g_entry.fz);
        g_ignoreUntil = now + 1500;
        g_tLast[0] = pos[0]; g_tLast[1] = pos[1]; g_tLast[2] = pos[2]; g_tT = t; g_tSeen = now;
        return;
    }
    g_tSeen = now;
    float dt = (float)((double)(t.QuadPart - g_tT.QuadPart) / (double)g_freq.QuadPart);
    g_tT = t;
    float dx = pos[0] - g_tLast[0], dy = pos[1] - g_tLast[1], dz = pos[2] - g_tLast[2];
    float d = sqrtf(dx * dx + dy * dy + dz * dz);
    g_tLast[0] = pos[0]; g_tLast[1] = pos[1]; g_tLast[2] = pos[2];
    bool ignore = (LONG)(now - g_ignoreUntil) < 0;
    if (!ignore && dt > 0.f && d > 300.f && d / dt > 6000.f) { Respawn(comp, "stock recovery moved the car"); return; }

    float upY = f[0x78 / 4];
    const float* vel = f + 0xA4 / 4;
    float sp = sqrtf(vel[0] * vel[0] + vel[1] * vel[1] + vel[2] * vel[2]);
    int touch = *(const int*)(comp + 0x114), wheels = *(const int*)(comp + 0x190);
    if (touch == 0) {
        if (!g_airSince) g_airSince = now;
        const Spot& b = BestSpot();
        if (!ignore && now - g_airSince > kFallMs && pos[1] < b.p[1] - 2500.f) { Respawn(comp, "fell under the level"); return; }
    } else g_airSince = 0;

    if (wheels > 0 && touch >= wheels && upY > 0.9f && vel[1] > -300.f && now - g_sampleAt >= kSafeSampleMs) {
        g_sampleAt = now;
        if (g_nSpots == 4) { memmove(g_spots, g_spots + 1, 3 * sizeof(Spot)); g_nSpots = 3; }
        Spot& s = g_spots[g_nSpots++];
        s.p[0] = pos[0]; s.p[1] = pos[1]; s.p[2] = pos[2]; s.t = now;
        Heading(comp, s.fx, s.fz);
    }

    if (upY < 0.3f && sp < 150.f) {
        if (!g_tipSince) g_tipSince = now;
        if (now - g_tipSince > kTipMs) {
            float fx, fz; Heading(comp, fx, fz);
            float p[3] = { pos[0], pos[1], pos[2] };
            PlaceUpright(comp, p, 40.f, fx, fz);
            char line[160];
            _snprintf(line, sizeof line, "cars2: flipped back (up %.2f) %.0f %.0f %.0f", upY, p[0], p[1], p[2]);
            line[sizeof line - 1] = 0;
            ::DebugLog(line);
        }
    } else g_tipSince = 0;
}
static void __fastcall TrackHook(BYTE* comp) {
    ((void(__fastcall*)(BYTE*))kSteerFn)(comp);
    if (comp) Track(comp);
}

static void Install() {
    {
        BYTE* s = (BYTE*)kSteerCall;
        DWORD old;
        if (s[0] != 0xE8 || (DWORD)(kSteerCall + 5 + *(LONG*)(s + 1)) != kSteerFn) mmenu::Log("cars2: respawn tracker site changed, not installed");
        else if (VirtualProtect(s, 5, PAGE_EXECUTE_READWRITE, &old)) {
            *(LONG*)(s + 1) = (LONG)((DWORD)TrackHook - (kSteerCall + 5));
            VirtualProtect(s, 5, old, &old);
            FlushInstructionCache(GetCurrentProcess(), s, 5);
        }
    }
    BYTE* p = (BYTE*)kBonesCall;
    if (p[0] != 0xE8 || (DWORD)(kBonesCall + 5 + *(LONG*)(p + 1)) != kBonesFn) { mmenu::Log("cars2: wheel-bone guard site changed, not installed"); return; }
    DWORD old;
    if (!VirtualProtect(p, 5, PAGE_EXECUTE_READWRITE, &old)) return;
    *(LONG*)(p + 1) = (LONG)((DWORD)BonesGuard - (kBonesCall + 5));
    VirtualProtect(p, 5, old, &old);
    FlushInstructionCache(GetCurrentProcess(), p, 5);
}

// Horn: H on keyboard, left stick click (L3) on a pad, while driving. Counted here, played by the QB beat.
static void HornPoll() {
    static DWORD s_last;
    bool h = KeyDown(0x23) || (((DWORD)padhub::g_padButtons >> padhub::B_LS) & 1) != 0;
    if (h && !g_hornWas && GetTickCount() - s_last > 1200) { s_last = GetTickCount(); InterlockedIncrement(&g_horn); }
    g_hornWas = h;
}

// THUGRECOMP_CarsDrive on=1|0  -> driving remap heartbeat / off. Returns active = 1 when the remap applies now.
// gta=1|0 sets the GTA 3 steering (any time). Returns horn = 1 when the horn key was pressed since the last call.
// Test aids: test=1 (forward) or test=-1 (back) reads=N pretends that direction is held for N controller reads;
// key=<DIK code> reads=N pretends that key is down (57 Space, 14 Backspace, 73 Numpad 9).
static bool __cdecl CF_CarsDrive(void* params, void* script) {
    int on = IntParam(params, "on", -1);
    if (on == 1) { g_beat = GetTickCount(); InterlockedExchange(&g_on, 1); }
    else if (on == 0) { InterlockedExchange(&g_on, 0); InterlockedExchange(&g_testReads, 0); }
    int t = IntParam(params, "test", 0);
    if (t) { g_testDir = t; InterlockedExchange(&g_testReads, IntParam(params, "reads", 60)); }
    int k = IntParam(params, "key", 0);
    if (k) { g_testKey = k; InterlockedExchange(&g_testKeyReads, IntParam(params, "reads", 60)); }
    int gta = IntParam(params, "gta", -1);
    if (gta == 0 || gta == 1) InterlockedExchange(&g_gta, gta);
    RetInt(script, "active", State() == nullptr ? 1 : 0);
    if (InterlockedExchange(&g_camReset, 0)) RetInt(script, "cam_reset", 1);   // the tracker moved the car: QB resets the camera
    if (InterlockedExchange(&g_horn, 0) > 0 && State() == nullptr) RetInt(script, "horn", 1);
    return true;
}

// THUGRECOMP_CarsKeys -> dadmod_c2_up/_dn/_lf/_rt = what to show for the player's movement on the device the prompts
// show now: the bound key names on keyboard (Forward/Backward/Turn left/Turn right, any binds), d-pad glyphs on a pad.
// Also dadmod_c2_hk (handbrake) and dadmod_c2_xo (get out): Space / Backspace on keyboard, RB / Y glyphs on a pad.
static bool __cdecl CF_CarsKeys(void* params, void* script) {
    if (padhub::g_appliedDevice < 0) { padhub::TpCtrlLayout(); padhub::g_appliedDevice = padhub::g_launcherLayout == 0 ? 0 : 1; }
    int dev = IntParam(params, "dev", -1);
    bool onPad = dev >= 0 ? dev == 1 : padhub::g_appliedDevice == 1;
    static const char* kKeys[4] = { "dadmod_c2_up", "dadmod_c2_dn", "dadmod_c2_lf", "dadmod_c2_rt" };
    // on a pad: gas = X / A (\m0, the accept button), brake = Square / X (\b1), steer = d-pad or stick left / right
    static const char* kGlyph[4] = { "\\m0", "\\b1", "\\b6", "\\b5" };
    for (int i = 0; i < 4; ++i) {
        char name[64];
        if (onPad) strcpy(name, kGlyph[i]);
        else padhub::KeyName(((int*)padhub::kKb0Binds)[i], name, sizeof name);
        RetStr(script, kKeys[i], name);
    }
    RetStr(script, "dadmod_c2_hk", onPad ? "\\bh" : "Space");
    RetStr(script, "dadmod_c2_xo", onPad ? "hold \\b0" : "Backspace");
    RetStr(script, "dadmod_c2_hn", onPad ? "\\bk" : "H");
    // dadmod_c2_xl: the long form for the Get Out row (keyboard: Backspace, or hold the grind key = stock Triangle)
    char longOut[96];
    if (onPad) strcpy(longOut, "hold \\b0");
    else {
        char g[64];
        padhub::KeyName(((int*)padhub::kKb0Binds)[11], g, sizeof g);
        _snprintf(longOut, sizeof longOut, "Backspace (or hold %s)", g); longOut[sizeof longOut - 1] = 0;
    }
    RetStr(script, "dadmod_c2_xl", longOut);
    return true;
}

}  // namespace cars2
