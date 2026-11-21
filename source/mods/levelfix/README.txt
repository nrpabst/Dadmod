levelfix: small fixes to stock level scripts, compiled to data\dadmod_levelfix.qb.
load_level (host_observer Levels.q for the Dev build, client/qb/dadmod/menus.q for the player build)
LoadQBs it LevelSpecific after each level's own qbs, so the scripts here replace the stock copies.

levelfix.q:
- NO_manual_spot (New Orleans, NO_Scripts.qb): manualing over a manhole cover played GrindMetalOn02 twice
  (NO_SFX_Manual_Over_Manhole) and shook the camera. Noah 2026-11-21: "permanently force them off in dadmod".
  Replaced with an empty script at first, then put back the same day: Noah "the clank is fine by itself. the screams are not"
  (the screams were NO_EndGap_VortexSpine below). Clank and camera shake are stock again.
- NO_EndGap_VortexSpine (New Orleans, NO_Scripts.qb): the "Into the Underworld" gap at the manhole played a random
  SK6_NO_CryptYell01/02/03 scream with a plain PlayStream vol = 200 (not tied to an object, so the Level sounds slider
  never scaled it; soundlog 2026-11-21 06:23:58 "SCRIPT PlayStream #AC792D99 vol=200"). Noah 2026-11-21 "i still hear
  the manhole screams". Same script without the scream: the gap, its score and NO_GotVortexSpine (goal flag) stay.
