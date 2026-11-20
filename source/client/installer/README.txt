
  ██████╗  █████╗ ██████╗ ███╗   ███╗ ██████╗ ██████╗
  ██╔══██╗██╔══██╗██╔══██╗████╗ ████║██╔═══██╗██╔══██╗
  ██║  ██║███████║██║  ██║██╔████╔██║██║   ██║██║  ██║
  ██║  ██║██╔══██║██║  ██║██║╚██╔╝██║██║   ██║██║  ██║
  ██████╔╝██║  ██║██████╔╝██║ ╚═╝ ██║╚██████╔╝██████╔╝
  ╚═════╝ ╚═╝  ╚═╝╚═════╝ ╚═╝     ╚═╝ ╚═════╝ ╚═════╝
  ████╗                                           ████╗
  ╚═██████╗                                   ██████╔═╝
    ╚═████████████████████████████████████████████╔═╝
      ╚═════████████╔═══════════════████████╔═════╝
          ▄██████████▄╗           ▄██████████▄╗
          ████╔══╗████║           ████╔══╗████║
          ▀██████████▀╔╝          ▀██████████▀╔╝
           ╚═════════╝             ╚═════════╝

                @DADMOD_VERSION@ beta  ·  for THUG Pro

  Works with plain THUG Pro or Kali Mod.
  Changes none of THUG Pro's or Kali's own files.


  CONTENTS
    1. Install / Update
    2. Repair
    3. Uninstall
    4. Playing with Kali Mod
    5. What's in dadmod
    6. What's new in @DADMOD_VERSION@
    7. Extra levels
    8. If something goes wrong
    9. Credits


==========================================================================
 1. INSTALL / UPDATE
==========================================================================

  Step 1   Close THUG Pro.

  Step 2   Unzip this zip into your THUG Pro folder
           (the folder with THUGPro.exe in it).

  Step 3   Open the "dadmod-install" folder and double-click "Setup.bat".

  Step 4   Pick  1) Install   (or  1) Update  if dadmod is already in).

  Step 5   Start THUG Pro as usual. The first start takes a few
           seconds longer while the main menu scenes are set up.

           You'll see "Dadmod @DADMOD_VERSION@ beta" at the bottom of the main menu.

  TIP  Keep the dadmod-install folder. Setup.bat is also how you
       Update, Repair and Uninstall.


==========================================================================
 2. REPAIR
==========================================================================

  A dadmod map or file went missing?
  Close THUG Pro, run "Setup.bat" and pick  2) Repair.
  It only puts back what's missing.


==========================================================================
 3. UNINSTALL
==========================================================================

  Close THUG Pro, run "Setup.bat" and pick  3) Uninstall.
  Your game goes back to exactly how it was.

  Your dadmod settings stay in the "dadmod" folder in your game folder.
  Delete that folder too if you don't want them.

  The dadmod-install folder stays too, so you can install again later.


  UPDATES

  Setup.bat checks for a newer dadmod each time it opens (and with
  4) Check for updates). If there is one, it downloads it and updates
  your game. Your settings stay.


==========================================================================
 4. PLAYING WITH KALI MOD
==========================================================================

  dadmod is made to sit alongside Kali Mod:

    * Setup spots Kali Mod and builds dadmod for it.
    * None of Kali's files are changed. dadmod's scripts load next to
      Kali's and take over a few parts while the game runs.
    * Uninstall puts your game back to exactly how Kali Mod left it.

  WHAT DADMOD CHANGES ON A KALI MOD GAME

    Edit Skater colors
      Kali's color menu (Randomize Color, Reset to default) is replaced
      by dadmod's own: Color, Brightness and Saturation sliders,
      Random Color and Default Color.

    Edit Skater scaling
      Kali's unlimited scaling is replaced by dadmod's limits
      (1 to 1000 for every part).

    Pause menu
      Kali's pause menu stays as it is, Kalimod v2 entry included.
      dadmod adds one item to it: "Dadmod", right under Continue.

    Quick Menu
      dadmod adds Noclip, Free Cam, Load Skater and
      Set Main Menu Here under Level Restarts.

    Main menu
      "Kalimod Features" stays, next to "Dadmod".

    Welcome message
      Kali's welcome is replaced by dadmod's, so you get one, not two.


==========================================================================
 5. WHAT'S IN DADMOD
==========================================================================

  MAIN MENU
    * Custom main menu scenes: pick a level, spot and camera, or save
      your own with  Pause > dadmod > Set Main Menu Here.
    * Random mode picks a different scene each time.
    * Skater poses: Default, Single Animation, Cycle Animations, Random.
    * Reorder the main menu: F9 reorder, F10 undo, F12 default.

  MENU LOOK
    * Menu UI colors, themes, text effects and layout
      (Dadmod > Menu UI).

  EDIT SKATER
    * dadmod's own Edit Skater additions (inspired by ken's CAS Mod),
      the same with or without Kali Mod.
    * Load Skater from the Quick Menu in the middle of a level (offline).

  SKATING
    * Animations: play any skater animation, star favorites, and
      Kali's idle loops.
    * Throwables: get ammo and throw stuff with Square, in any server.
    * Bank Drops and Bail Cancel.
    * Player Speed: slow motion up to faster.
    * Infinite balance (offline).
    * Noclip (F6).
    * Freeskate keeps running while the pause menu is open.

  GRAPHICS, WEATHER AND SOUND
    * Graphics: sky, time of day, effects, colors and retro looks
      (Dadmod > Graphics).
    * Weather just for you: rain, thunderstorms, snow, fog, fireworks.
    * Level sounds and Special trick sounds on/off.

  CONTROLS
    * Keyboard and controller bindings.
    * Controller plug and play.
    * Mirror mode, background input, stick dead zone.
    * Swap A/B and X/Y.

  ONLINE
    * Typed chat is kept when a game starts.

  LEVELS
    * Filled level slots and a THPG tab (see 7. Extra levels).

  UNDER THE HOOD
    * Faster boot.
    * A fix for a crash some skater parts cause.


==========================================================================
 6. WHAT'S NEW IN @DADMOD_VERSION@
==========================================================================

  FIXED
    x Online level select: Philadelphia, Baltimore and Washington D.C.
      in the Proving Ground tab can be picked when you host. They load
      Larxian's map the same way the User tab does, so players without
      dadmod who have that map can join too.


  0.9.16
  ------

  NEW
    + Pause > Graphics > Sound > Teleporter sounds (0 to 100): the
      volume of the sounds teleporters and teleporting elevators play.
    + Pause > Graphics > Sound > Sound logger (default Off): On writes
      every sound the game plays to dadmod\soundlog.txt, for finding
      sound bugs.

  FIXED
    x BHRA: your skater holds the revert pose in the air again.
    x Easy BHRA: buttslaps out of a BHRA work again.
    x BHRA style Land Pivot plays the full Land Pivot animation. The
      Revert style keeps its shorter (60%) revert.
    x Level sounds no longer go quiet after you pause the game.


  0.9.15
  ------

  NEW
    + Pause > dadmod > Gameplay > BHRA style (default Land Pivot): with
      Land Pivots on, pick how your Bunny Hop Revert looks after a land
      pivot hop: the Land Pivot or a Revert.

  FIXED
    x BHRA keeps combo now works with Land Pivots on: a hop then a land
      pivot in the air (THUG Pro's own BHRA) keeps your combo. Before,
      only BHRAs off vert ramps did.
    x Easy BHRA after a land pivot hop gives a longer land pivot window
      (it used to give a normal revert window instead).
    x Buttslaps out of a BHRA work like in the normal game.
    x BHRA keeps combo after zero also works for land pivot BHRAs.


  0.9.14
  ------

  FIXED
    x BHRA keeps combo now also works after zero (the timer running
      out in Trick Attack, Graffiti and other timed modes). Before,
      the hop and revert worked but the combo still ended.


  0.9.13
  ------

  NEW
    + Pause > dadmod > Gameplay > BHRA keeps combo (default Off): a
      Bunny Hop Revert (hop out of a revert window, revert in the air)
      keeps your combo going. Only your own game changes.
    + Pause > dadmod > Gameplay > Easy BHRA (default Off): a longer
      revert window around the hop, so BHRAs are easier to hit.
    + Pause > Graphics > Sound: Level sounds and Special trick sounds
      sliders (0 to 100).
    + Graphics: a "Graphics effects: dadmod / ReShade" row when ReShade
      is installed in the game folder.
    + Reorder any menu: F9 move mode, F10 undo, F12 stock order (on a
      controller: hold Select and press LB, RB or LT).
    + Online Load Skater: other dadmod players see your new skater
      within about a second (others after a rejoin).
    + Pause > dadmod > Gameplay > Trick Screen Effects (default On):
      Off skips the full-screen effect of special tricks like the 3D
      Scary Grind. Thanks shibe.
    + Edit Skater: Male Backpack and Female Backpack rows, so any
      skater can wear either one. Thanks shibe.

  CHANGED
    ~ Quick Menu > Free Cam shows online too (where the server allows
      the free camera).
    ~ Menus show the keys and buttons you actually use, and switch
      between keyboard and controller pictures as you play.
    ~ Edit Skater scale sliders move 1 per press; push the stick hard to
      go faster.
    ~ A controller that disconnects is picked up again by itself.

  FIXED
    x Settings, keybinds and menus not saving on some Windows 11 PCs.
    x The game not starting on some PCs.
    x Bank drops could not be switched in the player build.
    x Keybind menu missing in the player build.
    x Empty black description box under some menus.
    x "ESC = Back" and "ENT = Accept" overlapping in pop-ups.
    x Throwables now work online without Kali (plain THUG Pro).
      Vehicle throwables need Kali's models; without them you throw
      a COMBO O. Thanks shibe.
    x THPG tab: Larxian's cities load even when your copy has another
      name.


  0.9.12
  ------

  NEW
    + Edit Skater scaling has no limits: Scale Options go from 0 to
      1,000,000, and each press moves about 5% of the number, so big
      sizes come fast.
    + Logo and tattoo Scale has no limits either and shows a plain
      number (100 is normal size).
    + Main menu > Match slope: your skater leans with the ground they
      stand on (On), or stands straight up (Off).

  CHANGED
    ~ Edit Skater is now all dadmod's own code. It looks and works the
      same as before.
    ~ Long menu titles shrink to fit on the screen.
    ~ When Setup stops, it says why in plain words (for example a CAS
      mod changed your skate shop scripts) and writes a report you can
      send to Noah.

  FIXED
    x Setup no longer stops on Kali Mod installs that don't have a CAS
      mod or the extra Kali file.


  0.9.11
  ------

  NEW
    + In-game updates: when a new dadmod is out, "Update available"
      shows under the dadmod text on the main menu. Main menu > Dadmod >
      "Download newest update" downloads it while you play, then
      "Restart to install update" installs it and restarts the game.
    + 12 of the extra maps can be hosted online: pick them in the online
      level select, or type their ! command (like !STREETS, !NYC,
      !SUBURBS).
    + Time of day follows Kali Mod's Time Of Day menu and the other way
      round (Morning, Day/Afternoon, Sunset/Evening, Night).

  CHANGED
    ~ Time of day works online: your pick shows on your screen only and
      stays when the server changes the time. "Level / server" follows
      the server.
    ~ INSTALL.txt is now README.txt.

  FIXED
    x Hosting on a THPG tab level no longer crashes the game.


  0.9.8 - 0.9.10
  --------------

  NEW
    + Graphics > Display: Windowed mode and Resolution (THUG Pro's own
      display settings; shows after a restart). A size your monitor
      can't show is fixed at startup.
    + Custom menus > Restore deleted menus: put back a menu you deleted.

  CHANGED
    ~ Cleaner dadmod menus:
      - Pause > dadmod is 8 rows: Animations, Throwables, Gameplay,
        Sky & weather, Sound, Controls, Graphics, Set Main Menu Here.
      - Menu UI > Effects is now "Menu colors", grouped into Theme,
        Highlight, Text, Box and All colors. Highlight style moved in.
      - Clearer names: Highlight color, Bar color, Text color, Title
        color, Brackets speed, Menu brightness, Skater on screen, Time
        per animation, Reset this shot, Starred (was Favorites).
      - Main Menu options shows Cycle order; Camera control, mode, shot
        and time sit together.
      - Graphics has a Sound group (level sounds, special trick sounds).
    ~ Highlight color works with every Effect: Scan tints it, the
      letter effects keep the option you are on in your color.
    ~ The first-boot loading screen covers the game window in windowed
      mode instead of the whole screen.
    ~ A new install starts with every Graphics option off.


  0.9.7
  -----

  NEW
    + Setup checks for a newer dadmod and can update itself
      (4) Check for updates).
    + A loading screen while the first boot scans your custom levels.
    + Menu scene "Starred": star several Custom menus (d-pad Right)
      and each start shows one of them, at random or in order.
    + Camera shot "Static": one still view, no orbit or movement.

  CHANGED
    ~ Only d-pad Right stars and unstars, everywhere (animations,
      idle loops, the main menu animation picker, Custom menus).
      Square no longer stars. In Custom menus, Square still deletes.
    ~ Camera control is at the top of the Camera page.
    ~ Camera shot and Custom camera no longer have favorite or delete.
    ~ Menu UI > Effects hides options another setting overrides
      (Highlight under moving effects, Bar under Grow/Slide/Brackets/
      Spotlight/Wave, Bar FX under Underline/Side marker).
    ~ Main menu colors only shows while Effect is Off.
    ~ Ambient life starts on People + cars.
    ~ Pause menu descriptions show in the box on the right, like the
      dadmod main menu pages.

  FIXED
    - Edit Skater menu colors now change at the same speed as every
      other menu.


  0.9.6
  -----

  NEW
    + Pose mode for your main menu skater: Default, Single Animation,
      Cycle Animations, Random.
    + Animation picker right on the main menu:
      Dadmod > Main Menu options > Skater pose > Animations.
    + Default pose cycles the idle loops.
    + Idle loops: Square stars a loop; starred loops cycle on the
      main menu.
    + Project 8's Training, Suburbs, Downtown, Car Factory, Crete Park.
    + THPG tab: Larxian's Philadelphia, Baltimore and Washington D.C.,
      plus THPG Training.
    + Main menu scenes for all the new maps.
    + Pause > dadmod > Level sounds and Special trick sounds
      (like the guitar grind) on/off.

  CHANGED
    ~ Kalimod Features stays on the main menu next to Dadmod.
    ~ Custom menu scenes start on Random, including the East LA tram.
    ~ Infinite balance works offline and in Freeskate, and turns off
      in online games.
    ~ Vehicles shows in the pause dadmod menu as "Coming later".
    ~ Setup is one file (Setup.bat) with a numbered menu.

  FIXED
    - The THPG tab no longer crashes the game.
    - The menu highlight no longer gets stuck when you scroll down
      and back up.
    - Backing out of Keyboard bindings goes back to the pause menu.
    - Long idle loop names no longer run into the star.


==========================================================================
 7. EXTRA LEVELS
==========================================================================

  dadmod fills the greyed-out level slots (playable offline) and adds a
  THPG tab to the level select. See 9. Credits for the full list.

  Already have one of these levels? Setup keeps yours.


==========================================================================
 8. IF SOMETHING GOES WRONG
==========================================================================

  If Setup stops, it tells you why.
  Logs are in:  <your game folder>\dadmod\client.log


==========================================================================
 9. CREDITS
==========================================================================

  MAPS
    Streets ............................ tyler.thpsX (thpsX Vault)
    THPS2 NY, Skatestreet, Bullring,
    Chopper Drop ....................... letmynutzgo (thpsX Vault)
        made with THUG Tools by asdf_ and KSK; THPS PS1 importing by
        KSK and Greasemonkey; Bullring's bull scripts by Sk8ace;
        Chopper Drop model help from TylerLasagna
    Skate Heaven ....................... rodafy
        skybox and trees by letmynutzgo
    Philadelphia, Baltimore,
    Washington D.C. (THPG tab) ......... Larxian, shipped unmodified
    P8 Training, Suburbs, Downtown,
    Car Factory, Crete Park,
    THPG Training ...................... dadmod's own conversions of
                                         Neversoft's Project 8 and
                                         Proving Ground levels

    The original THPS, Project 8 and Proving Ground levels are
    by Neversoft.

  INSPIRATION AND IDEAS
    ken's CAS Mod v2 ... inspired dadmod's Edit Skater
                         (dadmod's own code, none of CAS Mod's)
    Kali, Kalimod v2 ... the idle loops in Animations > Idle loops
                         (played with dadmod's own scripts), the
                         Random Color option in Edit Skater (inspired
                         by Kali's Randomize Color; dadmod's own code),
                         and the Kalimod Features menu item


                              Have fun!
