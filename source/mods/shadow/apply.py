"""Skater shadow after the game's own car exit (Noah 2026-11-22: "why couldnt we fix the stock bug").

    python -I mods/shadow/apply.py build/obsspawn_test/mod      (run from work/, by obsspawn_test_make.sh)

Stock ToggleUserControlledVehicleMode always gives the skater the full-body shadow when they get out of a car, even
with the THUG Pro launcher's Skater Shadow Quality on Low (a circle). Like client/wrap.txt does in the player build,
the stock definition is renamed to ToggleUserControlledVehicleMode_orig (player_controlled_vehicle.q is copied in from
the decompiled Kali Original first), and carexit.q (ours: calls the _orig, then dadmod_shadow_restore once the skater
is out of the car) goes into qb/dadmod/dadmod_cars.qb. client/qb/dadmod/carexit.q must be the same file.
Players in other skaters' cars (NonLocalClientExitVehicle) are not touched: they keep the stock Simple shadow.
"""
import os, re, shutil, sys

NAME = 'ToggleUserControlledVehicleMode'
REL = 'game/player_controlled_vehicle.q'
KALI = 'decompiled/thugpro_qb/qb'


def main(root):
    here = os.path.dirname(os.path.abspath(__file__))
    a = open(os.path.join(here, 'carexit.q'), encoding='latin-1').read().replace('\r\n', '\n')
    cli = os.path.join(here, '..', '..', 'client', 'qb', 'dadmod', 'carexit.q')
    if not os.path.isfile(cli) or open(cli, encoding='latin-1').read().replace('\r\n', '\n') != a:
        print('shadow: client/qb/dadmod/carexit.q differs from mods/shadow/carexit.q (copy it over)')
        return 1
    qb = os.path.join(root, 'qb')
    dst = os.path.join(qb, REL)
    if not os.path.isfile(dst):
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copy(os.path.join(KALI, REL), dst)
    pat = re.compile(r'^script %s\b' % NAME, re.M | re.I)
    n = 0
    for d, _, fs in os.walk(qb):
        for f in fs:
            if not f.endswith('.q'):
                continue
            p = os.path.join(d, f)
            s = open(p, encoding='latin-1', newline='').read()
            t, c = pat.subn('script %s_orig' % NAME, s)
            if c:
                n += c
                open(p, 'w', encoding='latin-1', newline='').write(t)
    if n != 1:
        print('shadow: expected 1 definition of %s, found %d' % (NAME, n))
        return 1
    out = os.path.join(qb, 'dadmod', 'dadmod_cars.q')
    if not os.path.isfile(out):
        print('shadow: %s missing (cars2 step must run first)' % out)
        return 1
    with open(out, 'a', encoding='latin-1', newline='') as fh:
        fh.write('\n' + a)
    print('shadow: wrapped %s' % NAME)
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1]))
