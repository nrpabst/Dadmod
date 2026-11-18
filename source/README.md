# dadmod source

The source code of the dadmod installer and everything it installs: every piece of code we wrote or edited for the
player package. Paths match our working tree, so `#include "../../mods/..."` and the build scripts' relative paths
still line up.

## What's here

- `client/native/` - `binkw32.dll`, the loader: forwards every Bink call to the game's own `binkw32_orig.dll`, loads
  our script archive after the game's, and holds the in-game updater (`update.inc`). Build: `client/native/build.bat`
  (MSVC x86).
- `mods/*/*.inc` - the DLL parts the loader includes: graphics settings (`gfx`), controllers (`controller/padhub`),
  main menu scenes (`mainmenu`), boot speed, bank drops, infinite balance lock, crash log.
- `client/qb/dadmod/` - hand-written scripts. Most wrap a stock script (`<name>_orig`, see `client/wrap.txt`) so
  whatever the player has keeps running underneath.
- `client/qb/gen/` - scripts generated from our main build (`client/tools/gen_client_qb.py`): our own new scripts,
  plus our edited versions of THUG Pro scripts (the generator's report, `client/tools/gen_report.txt`, lists each one).
- `mods/mainmenu/casidle.q`, `mods/casmod/` - Edit Skater on the menu levels, mix and match and the other Edit Skater
  additions (our own code, inspired by ken's CAS Mod).
- `client/installer/` - `Setup.bat`, `dadmod.ps1` (install, repair, uninstall, update), the `files.dad` reader
  (`DadmodPack2.cs`) and the player README.
- `client/make_client.py`, `client/tools/`, `tools/` - the package build: QB compiler (`tools/qb.py`), archive
  packer, level pictures, recipes.

## Not included

Other people's work and game data: THUG Pro / Kali Mod's own unedited files, the extra maps (Larxian's THPG cities,
P8, Vault, THPG) and their level-select pictures, and the main menu scene data cut from the game's levels. The
build reads those from a THUG Pro install and from our decompiled script trees, so this folder alone doesn't build
a full package.
