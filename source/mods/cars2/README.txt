dadmod cars 2.0 (2026-11-20): Pause > dadmod > Cars. Our own code; replaces cars 1.0 (archived in
work\archive\dadmod_cars_1.0_20261120, see RESTORE.txt there).

What it does
- The Cars page lists 17 of the stock VehicleSetupMapping cars (OffroadCar is left out: same pickup model).
- RC Car removed 2026-11-20 (Noah: "the rc car doesn't drive properly"): stock RCCarSetup has no control_type, its
  body is the Custom Tuner model, and its physics are tuned for a much smaller scale. Not retuned on purpose.
- Picking one: close the pause menu, exit any car first, then
  MakeSkaterGoto Switch_OnGroundAi params = { NewScript = TransAm VehicleSetup = <setup> Exitable }
  This is the stock goal path. ToggleUserControlledVehicleMode then runs ON THE SKATER, so its Obj_GetId gives the
  real skater id and the stock BroadcastEnterVehicle shows the right car to every other player (mod or not).
  The setup always gets control_type = <picked type> (RCCarSetup has none in stock, which would broadcast garbage).
- Setups with skater_anim (Security Cart, Gardener Cart, Forklift, Mini Baja) get skater_anim = Ped_SIT_Idle:
  the stock anims (Ped_Driver_Turn_Range, Ped_Baha_Drive) are not in THUG Pro and crashed at THUGPro+0x7D62F.
- Get out: the "Get Out" row, or the stock ExitVehicleRequest (car's own get-out button, Exitable). We read the
  car position, run ToggleUserControlledVehicleMode, put the skater there, UnpausePhysics, SetSpeed 0, and
  MakeSkaterGoto Switch_OnGroundAi NewScript = OnGroundAi (back on the board, walking cleaned up).
- dadmod_cars_watch (spawned while driving) gets you out when the level changes, a game mode starts
  (allowed only in is_lobby / is_singlesession, like the Quick Menu), the skater goes away, or the car object
  disappears (then a manual cleanup without touching the missing PlayerVehicle).
- No globals; locals are prefixed dadmod_c2_ (engine member names like "driving" freeze the VM).

On-screen text (all ours unless noted)
- Pause > dadmod row: "Cars  >" / "Drive a car. Everyone on the server sees it, even players without dadmod"
- Page title "cars"; first row "Get Out" / "Get out of the car and back on your board, right where the car is"
- Car rows: the car name / "Drive the <name>. Everyone on the server sees it, even without dadmod"
- Greyed row when not allowed: "No skater right now", "The level is changing", "Not while observing",
  "Cars work in free skate only"
- Messages: "Land first, then pick the car", "Get up first, then pick the car", "Could not switch cars",
  "The car didn't start", "You're not in a car"
- Nothing is shown on screen while driving (the old red controls panel was removed 2026-11-20, Noah found it
  annoying). The controls are in the row descriptions instead, built when the page opens with the player's own keys
  (THUGRECOMP_CarsKeys = Forward/Backward/Turn keys on keyboard, d-pad glyphs on a pad; THUGRECOMP_ButtonText for
  the grind and R2 keys):
  car rows: "Drive the <name>. Everyone sees it. <up>/<down> gas/brake, <left>/<right> steer"
  Get Out:  "Get out here. In a car: hold <grind key> to stop and get out, <R2 key> handbrake"

Controls and the driving input remap (cars2.inc, 2026-11-20)
- The stock car reads fixed pad buttons (0x4376B0): X = gas, Square = brake then reverse, Triangle (Exitable) =
  brake and get out once stopped, R1 = handbrake (on PC the R2/revert key sets it), left stick / d-pad = steer.
- While driving, the DLL makes up (left stick Y up or d-pad up) also press X and down also press Square, in the
  control block ReadControls builds for player 1 (gfx.inc ReadControlsHook -> cars2::Remap). So W/S (whatever is
  bound to Forward/Backward) drive, with any binds; a pad stick up/down works too.
- On only while dadmod_cars_watch keeps sending THUGRECOMP_CarsDrive on=1 (every 3 frames, and on=0 while a menu,
  dialog, keyboard or pause is up). Off at once on every exit path (dadmod_cars_hint_off sends on=0), when the
  game is paused (byte 0x6FA7D4), or when no on=1 came for 1 s (script died, level unload). Transitions are logged
  in dadmod\mainmenu.log ("cars2: driving remap on/off (why)").
- Default keys (fix 2): gas W (or Numpad 2), brake/reverse S (or Numpad 4), steer A/D, handbrake Space (or Numpad 9;
  RB on a pad), get out Backspace (or hold Numpad 8 / Y).
- Test harness: work\build\live\cars2fix_t.q (dadmod_c2f_*; THUGRECOMP_CarsDrive test=1/-1 reads=N fakes up/down).
  Its dadmod_c2f_quit (stock level_select_change_level_quit from a spawned script) crashes even with no car
  (0x459E71), so quit was not tested that way.

Tests (2026-11-20, Dev, my own test games)
- Offline Carnival/SF: all 18 spawn, drive, switch while driving, in/out x5, level change, quit to main menu
  while driving, pause + Get Out from the menu, car dropped under the map (the car recovers by itself).
- LAN with the stock copy: the stock copy joined my LAN host; the car was not caught on the stock screen, and the
  host crashed at THUGPro+0x76B41 (reading 0x4) at "get out" while my test script had been teleporting the car and
  skater around. Not yet reproduced with a plain get-in/get-out online. Needs a clean LAN re-test.

Fix 2 (2026-11-21, Noah: "for me s accelerates and w brakes", "we also need a handbrake", "the handbrake didnt do
anything but spacebar is better anyway", "somehow i seem to be standing in my car", "the handbrake control on
controller should be R1, and the get out of car control should be backspace")
- W/S swap: ReadControls writes left stick Y = +0x7FFF for the Forward key (bind slot 0) and -0x7FFF for Backward
  (slot 1); the remap assumed up was negative, so Backward pressed X (gas). The faked test input used the same wrong
  sign, so the test drove "correctly". Now forward (Y > 40% or d-pad up) = X, back = Square.
- Handbrake: the car reads pad R1 (input component +0x100: CPad at +0x20, constructor 0x46B940; car +0x2CD =
  no_handbrake, only 2 stock setups). R1 comes from control block +0xD (the "r2" bind slot 17, which sets PS2 R1 and
  R2 in FUN_005BD200); the "r1" slot 15 (+0xB, Numpad 9 / RB) only sets an extra pad byte, so it did nothing.
  Now Space (DIK 0x39), Numpad 9 (0x49) or controller RB (padhub g_padButtons) set +0xD. Whatever Space is bound to
  (e.g. ollie = X = gas) is cleared from the block while driving.
- Get out: Backspace (DIK 0x0E) tap holds Triangle (stock Exitable exit: brakes, then ExitVehicleRequest) for up to
  6 s; gas is blocked meanwhile. Its own bind is cleared while driving. Backspace has no in-game use in stock or
  dadmod (only the main-menu splash skip and chat, and the remap is off while the chat keyboard is open).
  Holding the grind key / Y still works. Controller get-out = hold Y (Triangle), unchanged.
- Hidden skater: the car hides the skater once when it is created (0x43BCA5: Hide unless make_skater_visible), and
  something later shows it again (not found statically). dadmod_cars_beat now hides the skater every beat (3 frames)
  while driving a setup without make_skater_visible; unhide on every exit path (Switch_OnGroundAi unhides, the manual
  cleanup and the "not driving any more" branch call unhide).
- Descriptions: car rows "Drive the <name>: W/S gas/brake, A/D steer, Space handbrake, Backspace out. Everyone sees
  it"; Get Out "Get out here. In a car: Backspace (or hold <grind key>) gets out, Space handbrake"; on a controller
  h (RB) and "hold 0" (Y). The old car rows used locals CarsKeys never returned (fixed: dadmod_c2_* names).
- Test aid: THUGRECOMP_CarsDrive key=<DIK> reads=N fakes a key (57 Space, 14 Backspace, 73 Numpad 9).
- Not tested in game yet (DLL change, Noah's Dev game was running): needs a restart, then a real key test.

Fix 3 (2026-11-21, Noah after a restart: "space doesn't handbrake the car but numpad 3 does. everything else works
though. upon unpausing you can see the skater for 1 frame but it goes away")
- Handbrake byte: Noah's binds (HKCU\Software\THUG Pro\Settings) have slot 15 ("r1") = Numpad 3 and slot 17 ("r2")
  = Numpad 9. Numpad 3 brakes, so the car's R1 comes from control block +0xB, not +0xD (fix 2 read FUN_005BD200
  wrong). Space / Numpad 9 / RB now set +0xB. On a controller the dadmod Xbox preset puts RB in slot 15 already.
- Unpause flash: exit_pause_menu (procrastination.q, patched by mods/cars2/apply.py from the make script) now ends
  with dadmod_cars_rehide: hide at once when driving a car with skater tag dadmod_c2_hide = 1 (set at get-in), then
  every frame for 15 frames (dadmod_cars_rehide_frames).

Car sounds (2026-11-21, Noah: "i just noticed none of the cars have sounds")
- Every car setup uses a PlayerVehicleSounds entry (NY_JunkCar, SE_ATV for the Mini Baja, Default for the Blimp). All
  three play CarLoop (engine), Vehicle_Tire_Loop (tires) and BonkMetal_11 (hits). Stock only loads those in levels
  that have cars (their *_sfx scripts: NY, FL, HI, SD, ...), so elsewhere the vehicle sound component had nothing.
- dadmod_cars_go now runs the same three LoadSound lines as those levels right before getting in. CF_LoadSound
  (0x44D7D0 -> 0x47B360) skips a sound that is already loaded and puts it in the level table (max 256 entries),
  which is freed on the next level change, so nothing piles up. Files are the game's own; nothing shipped.

Camera per car (2026-11-21, Noah: "some of the cars take up the entire screen, can we adjust the camera for them?")
- Stock CreatePlayerVehicle builds PlayerVehicleCamera from the global vehicleCameraSetup (offset_distance 240,
  offset_height 55), the same for every car. The vehiclecamera component copies those values when it is created
  (0x5244A0 reads alignment_rate/offset_height/offset_distance/angle into its own fields), so dadmod_cars_go Changes
  the global just before getting in and Changes it back to stock as soon as PlayerVehicleCamera exists (and on the
  "didn't start" path). Nothing else ever sees the changed values.
- Sizes from each car's THUG2 collision file (models\veh\*.col.xbx, longest side), scaled from the TransAm (stock
  camera, about 270): Custom Tuner / Impala / El Camino 255/58, Lada / Taurus 250/57, Police Car / Pickup 290/66,
  Limo 320/73, NY Cab 345/78. Everything else keeps 240/55 (TransAm, carts, Forklift, Mini Baja, Wrangler, Sports
  Car, Blimp). Tune here (switch in dadmod_cars_go) if a car still looks wrong.

GTA 3 style handling, More Cars, Props, horn (2026-11-21, Noah: "make the handling for the cars in dadmod work like gta
3", "a drivable traffic cone ... more cars like that"). Plan: work\notes\cars2_gta3_handling_plan.md.
- gen_cars2.py -> cars2_gen.q (run by hand after edits): dadmod_c2_tunes (per control_type overrides merged into the
  setup in dadmod_cars_go when the handling is GTA 3), dadmod_c2_cams (camera distance/height/alignment per car),
  dadmod_car_<x>_setup / dadmod_prop_<x>_setup (clones of stock setups with THUG2 models), dadmod_c2_extra_map (added to
  VehicleSetupMapping by dadmod_cars_boot from Load_MainMenu, so dadmod viewers see extra cars/props), dadmod_c2_push_map
  (stock map + inline extras, for a future host push to players without dadmod; not used yet: too big for one 0x48).
- Numbers come from our own feel profiles and rules (no GTA file read). Mass in lb, torques ft-lb (exe 0x437D00 init).
- Steering: cars2.inc SteerHook replaces the call at 0x43C1E9 to the input step 0x4376B0 (ECX = vehicle component):
  ramps +0x304 (5.5/s out, 9/s back) and scales it by speed (100% -> 45% at 1500 in/s), speed from +0x18 position delta.
  Only while the remap is on and gta=1 (THUGRECOMP_CarsDrive gta=). Logs "gta steering speed" to mainmenu.log every 3 s.
- Horn: H / L3 counted in the DLL (1.2 s cooldown), dadmod_cars_beat gets horn=1 -> dadmod_cars_horn (CarHorn stream on
  the car; host also sends every player a panel block PlayStream CarHorn).
- Handling option: THUGRECOMP_SettingSave key "cars_handling_stock" (0/1), row "Handling: GTA 3 / Stock".
- Build: cars2.q + cars2_gen.q + throw.q + throw_types.q are their own qb (qb\dadmod\dadmod_cars.qb), added to qdir.txt
  by add_qdir.py, because ButtonScripts.qb / procrastination.qb are at the 512 KB limit.
- Not tested in game yet. Risks: prop bodies (static .mdl with the car skeleton), tuning numbers are a first guess.

Game modes (2026-11-24, Noah: "can you make cars work in the middle of a gamemode as well", "should work after zero as well")
- dadmod_cars_can_drive: online, cars work in every mode except Horse ("No cars in Horse": turn based, the game pauses and
  teleports players between turns) and Goal Attack ("No cars in Goal Attack": getting in runs GoalManager_HideAllGoalPeds 1).
  Offline it is still free skate only.
- After the car starts, the skater runs dadmod_cars_drive_ai (stock DrivingAi's handlers, so Road Kill / Hit and Run still
  work) with RunHasEnded -> dadmod_cars_run_ended: when the clock hits zero the run ends like stock EndOfRun (lands tricks,
  drops the CTF flag, EndOfRunDone after 1 s so the round doesn't wait on the driver) but without DisablePlayerInput, so you
  keep driving after zero. Getting in after zero (dadmod_cars_after_zero: timed mode and time_left < 1) skips that exception
  and re-enables input; getting out after zero (before the score screen) runs stock EndOfRun instant.
- dadmod_cars_watch gets you out when a new game starts (game mode changes to anything but free skate; going back to free
  skate after a game keeps you in) or a new round starts (time left jumps up by more than 3 s in a timed mode).
- Untested in a real game so far (live-loaded into Dev 2026-11-24).
Respawn at the last safe spot + flip back (2026-11-24, Noah: "i drove into the water and my car respawned face down in a
ramp"; picked "Last safe spot + flip back")
- Cause: stock recovery is QB only. A water / kill trigger runs SK3_KillSkater(_Water) -> SK3_Killskater_Finish ->
  SK3_Killskater_Finish3, which while Driving calls PlayerVehicle : Vehicle_MoveToRestart <node> (the trigger's restart
  node or trg_playerrestart). Those are skater restart points, often on or next to ramps, and the car keeps its tilt and
  spin there.
- cars2.inc Track (hook on the input step call 0x43C1E9, every frame of the local player's car, object id PlayerVehicle):
  every 0.5 s with all wheels down, upright (up.y > 0.9) and not dropping fast it remembers pos + heading (last 4).
  When the car jumps (> 300 units at > 6000 units/s: the stock teleport) or has had no wheel down for 4 s while 2500
  below the best spot, it puts the car back at the newest spot that is at least 1 s old (else the newest, else where you
  got in), 15 units up, upright, same heading, no speed or spin. Tipped over (up.y < 0.3) and nearly still for 3 s: it
  stands the car up where it is, 40 units up, same heading. Upright quaternion via the stock matrix <-> quat helpers
  0x42E1F0 / 0x42BC40 (as the stock self-righting 0x438770 does).
- Camera: THUGRECOMP_CarsDrive returns cam_reset = 1 after a move; dadmod_cars_beat runs PlayerVehicleCamera :
  VehicleCamera_Reset.
- Log: thugrecomp_debug.log "cars2: respawn at last safe spot (...)" and "cars2: flipped back". If the car's object id
  can't be read, mainmenu.log says "cars2: car object has no PlayerVehicle id" and the tracker stays idle.
- No menu option. Any stock car teleport while driving (also a pause menu restart) now lands at the last safe spot.
- DLL change: needs a game restart. Not tested in game yet.

Camera look after getting out (2026-11-24, Noah: "when you get out of a car it doesn't give you camera control back until
you get off board")
- Cause: skatercam0's cameralookaround component keeps a look lock (+0x18) that a pad button press flips; it keeps
  updating under the car camera, so a press while driving could leave it locked. The skater camera clears it only in
  its walking branch (0x4FA860), so stepping off the board brought the look back.
- Fix: dadmod_cars_exit_now calls THUGRECOMP_CarsDrive camfree = 1, which clears the lock (and the look offset) and logs
  "cars2: got out, skater camera look lock was N (override N), cleared" to thugrecomp_debug.log. DLL change: restart.
