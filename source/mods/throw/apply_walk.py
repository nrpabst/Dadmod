"""Throw on foot wins over the board whack (Noah 2026-11-02), patched into the files the game loads them from
(procrastination.qb has no room left). Usage: apply_walk.py <mod tree> <decompiled thugpro_qb dir>
- walking_control.q (the anybinds copy already in the mod tree): PlayWalkAnim skips WalkingSlap while you have ammo
- projectiles.q: walk_maybe_throw_projectile2 plays the full-body standing throw"""
import os, shutil, sys
mod, dec = sys.argv[1], sys.argv[2]
sk = os.path.join(mod, 'qb', 'game', 'skater')
os.makedirs(sk, exist_ok=True)


def patch(path, old, new):
    s = open(path, newline='').read()
    nl = '\r\n' if '\r\n' in s else '\n'
    old, new = old.replace('\n', nl), new.replace('\n', nl)
    assert s.count(old) == 1, '%s: %d matches' % (path, s.count(old))
    open(path, 'w', newline='').write(s.replace(old, new))


wc = os.path.join(sk, 'walking_control.q')
if not os.path.exists(wc):
    shutil.copy(os.path.join(dec, 'qb', 'game', 'skater', 'walking_control.q'), wc)
patch(wc, 'script PlayWalkAnim\n    if not IsBoardMissing\n',
      'script PlayWalkAnim\n    if GotParam anim\n        if ( <anim> = WalkingSlap )\n            GetAmmo\n'
      '            if ( <ammo> > 0 )\n                return\n            endif\n        endif\n    endif\n    if not IsBoardMissing\n')
pj = os.path.join(sk, 'projectiles.q')
if not os.path.exists(pj):
    shutil.copy(os.path.join(dec, 'qb', 'game', 'skater', 'projectiles.q'), pj)
patch(pj, '    MakeSkaterGoto throw_while_walking\n    GetAmmo\n',
      '    MakeSkaterGoto throw_while_walking params = { standing = 1 }\n    GetAmmo\n')
print('throw: walk patches applied')
