# dadmod client build

A player-side package with none of the server mods, for the stock THUG Pro install
("THUG Pro REAL BASE INSTALL", what most players use) and for Kali Mod installs. It never
replaces or edits a Kali or THUG Pro file.

## How it loads

- `binkw32.dll` (from `native/loader.c`) is the loader. The installer renames the game's stock
  `binkw32.dll` to `binkw32_orig.dll`; every Bink export forwards there (`native/binkw32.def`).
- At boot the game loads its own scripts from `data\pre\thugpro_qb.prx`. The loader then loads our
  archive `data\pre\dadmod_qb.prx` the same way, so whatever is installed (stock or Kali) loads
  first and ours goes on top.
- `wrap.txt` lists stock scripts we change. Before our scripts load, each one is renamed to
  `<name>_orig`; our version does its part and calls `<name>_orig <...>`. That keeps Kali's or
  stock's own version running underneath instead of replacing it.
- Log: `<game>\dadmod\client.log`. Script function `THUGRECOMP_ClientLog text="..."` writes to it.

Proven on a copy of the stock install on 2026-11-05 (`../client_spike`): the stock
`create_main_menu` was wrapped, a new script ran, and the stock main menu came up as usual.

## Building

From `work/`: `python -I client/make_client.py` (or `sh build/make.sh client`). Output goes to
`build/client/`. It refuses any output folder inside a game folder. The DLL builds with MinGW
(`i686-w64-mingw32-gcc`) when present, otherwise with MSVC through `native/build.bat`.

## Adding a mod to the client build

1. Check its line in `../mods/MANIFEST.tsv` (`client` column: yes / later / no).
2. Put its scripts under `qb/dadmod/<mod>.q`. Only new scripts and wrappers: never a full copy
   of a stock or Kali script file (the server build's `mods/host_observer` copies are not used here).
3. Add any stock script it needs to change to `wrap.txt`, and call `<name>_orig <...>` from ours.
4. DLL parts go into `native/` as their own `.inc`, included from `loader.c`.
5. Set its `client` column to `yes` once it is in.

Rules for the public build (Noah, 2026-11-05): noclip, Player Speed, infinite balance and bank
drops stay available online; the Kali chaos port and the thpsX Vault level files stay out.
