lamplights: THUG2-style LevelLight lights at lamps in older maps (plan: work\docs\lamp_lights_plan\v2_sure).

2026-11-22 first test: ONE light on Chicago (hof), light #1 of v2_sure\hof.csv (cw_LightPole03, x -2472 y 650 z 497),
level + skater, InnerRadius 150, OuterRadius 400, color 255 187 107, Brightness 100 (always on).

- lamplights.inc: THUGRECOMP_AddLevelLight passes its params to the engine's own LevelLight creator 0x490570
  (the one ParseNodeArray uses for Class = LevelLight nodes). Logs "lamplights: light created at ..." to dadmod\mainmenu.log.
- lamplights.q: dadmod_lamplights_level load_script = <load_script>, called by load_level right after ParseNodeArray
  and the time of day setup (host_observer procrastination.q). Appended to qb\dadmod\dadmod_cars.qb by the make script.
- Client build: not wired yet (client\native\loader.cpp include + CFunc row, client\qb\dadmod\menus.q load_level call).
