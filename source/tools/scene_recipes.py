r"""Recipes for the main menu scenes (dadmod\menulevels\*.qb): each one is rebuilt on the player's PC from the player's
own script archives (THUG Pro's data\pre, the THUG2 game folder for THUG2 levels, or the extra levels the release
installs) plus our own bytes. Used by client/make_client.py with prebuilt dadpatch.Corpus objects (one per game).
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dadpatch   # noqa: E402


def rows(menulevels):
    for line in open(os.path.join(menulevels, 'list.txt'), encoding='latin-1'):
        f = line.split()
        if len(f) >= 5 and not f[0].startswith('#'):
            yield f


def make_all(menulevels, out_dir, corpora):
    os.makedirs(out_dir, exist_ok=True)
    made, report, seen = [], [], set()
    for row in rows(menulevels):
        qb = row[1]
        if qb in seen:
            continue
        seen.add(qb)
        target_file = os.path.join(menulevels, qb)
        target_path = os.path.join('dadmod', 'menulevels', qb)
        b, variants, target = dadpatch.make(target_file, target_path, None, corpora=corpora)
        if not any(dadpatch.apply_recipe(b, c.game) == target for c in corpora):
            report.append('%s: NO GAME REBUILDS IT' % qb)
            continue
        name = os.path.splitext(qb)[0] + '.dpr'
        open(os.path.join(out_dir, name), 'wb').write(b)
        made.append(name)
        report.append('%s: %s' % (qb, '; '.join(dadpatch.stats(variants, target)[:1])))
    return made, report
