levelfix: small fixes to stock level scripts, compiled to data\dadmod_levelfix.qb.
load_level (client/qb/dadmod/menus.q) LoadQBs it LevelSpecific after each level's own qbs, so the scripts here
replace the stock copies.

levelfix.q:
- NO_EndGap_VortexSpine (New Orleans, NO_Scripts.qb): the "Into the Underworld" gap at the manhole played a random
  SK6_NO_CryptYell01/02/03 scream with a plain PlayStream vol = 200 (not tied to an object, so the Level sounds slider
  never scaled it). Noah 2026-11-21: "the screams are not" fine. Same script without the scream: the gap, its score
  and NO_GotVortexSpine (goal flag) stay. The manual-over-manhole clank and camera shake (NO_manual_spot) stay stock.
