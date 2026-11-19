r"""Makes the "THUG Pro + Kali download" recipe game: what a player has after a fresh THUG Pro install plus the
public Kali Mod download dragged in (its data\pre\thugpro_qb.prx replaces the stock one, and there is NO
thugpro_qe.prx). make_client.py builds a recipe variant for it, so the installer works without thugpro_qe.prx
(Noah 2026-11-18: a player with only the Kali download got "script files dadmod does not know").

    python -I client/tools/make_recipe_game_kali.py [--base DIR] [--kali DIR] [--out DIR]   (run from work/)

Only the script archives the recipes read are copied (data\pre\*_scripts.prx and thugpro_qb.prx). The folder is a
read-only build input, not a game: never run, install into, or commit it.
"""
import os, shutil, sys

WORK = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ROOT = os.path.dirname(WORK)
BASE = os.path.join(ROOT, 'cleanup_archive_20261116', 'THUG Pro REAL BASE INSTALL')
KALI = r'C:\Users\Noah\Downloads\kalimodv2_1.2'
OUT = os.path.join(ROOT, 'recipe_games', 'THUG Pro + Kali download')


def find(folder, name):
    for f in os.listdir(folder):
        if f.lower() == name.lower():
            return os.path.join(folder, f)
    return None


def main(argv):
    base, kali, out = BASE, KALI, OUT
    while argv:
        a = argv.pop(0)
        if a == '--base':
            base = argv.pop(0)
        elif a == '--kali':
            kali = argv.pop(0)
        elif a == '--out':
            out = argv.pop(0)
        else:
            sys.exit('unknown argument: ' + a)
    bpre = find(find(base, 'data'), 'pre')
    kqb = find(find(find(kali, 'data'), 'pre'), 'thugpro_qb.prx')
    if not kqb:
        sys.exit('no data\\pre\\thugpro_qb.prx in ' + kali)
    if os.path.exists(os.path.join(out, 'THUGPro.exe')):
        sys.exit('refusing: %s is a game folder' % out)
    pre = os.path.join(out, 'data', 'pre')
    os.makedirs(pre, exist_ok=True)
    n = 0
    for f in sorted(os.listdir(bpre)):
        fl = f.lower()
        if fl.startswith('mainmenu_') or fl.startswith('dadmod') or fl == 'thugpro_qe.prx':
            continue
        if fl.endswith('_scripts.prx') or fl == 'thugpro_qb.prx':
            shutil.copy2(os.path.join(bpre, f), os.path.join(pre, f))
            n += 1
    shutil.copy2(kqb, os.path.join(pre, 'thugpro_qb.prx'))
    stale = find(pre, 'thugpro_qe.prx')
    if stale:
        sys.exit('unexpected thugpro_qe.prx in ' + pre)
    print('%s: %d stock script archives + the Kali download\'s thugpro_qb.prx, no thugpro_qe.prx' % (out, n))


if __name__ == '__main__':
    main(sys.argv[1:])
