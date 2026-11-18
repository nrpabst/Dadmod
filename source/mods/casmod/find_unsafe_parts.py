"""Lists Edit Skater parts whose model a player with a stock THUG Pro Kali + THUG2 install may not have
loaded (missing file, or only packed inside a level's own .prx). Showing one of these on your skater can
crash other players. Writes mods/casmod/unsafe_parts.txt (list name, desc_id, offline|never) for
hide_unsafe_parts.py: offline = the model is in the Dev game, so it can go in Edit Skater's Offline Only menu.
Run from anywhere on the VM side: python3 find_unsafe_parts.py
"""
import os, re, sys, json
sys.path.insert(0, os.path.expanduser('~/mnt/thugpro recomp/work/tools'))
from prx_extract import entries
G = os.path.expanduser("~/mnt/Tony Hawk's Underground 2/Game/Data")
O = os.path.expanduser('~/mnt/thugpro recomp/THUG Pro Kali v2 - 1.2 Original/data')
W = os.path.expanduser('~/mnt/thugpro recomp/work')
have = set()
def norm(p):
    p = p.replace('\\', '/').lower().lstrip('/')
    if p.startswith('data/'): p = p[5:]
    p = re.sub(r'\.(xbx|ps2|ngc)$', '', p)
    return p
for root in (G, O):
    for dp, dn, fn in os.walk(os.path.join(root, 'models')):
        for f in fn:
            have.add(norm(os.path.relpath(os.path.join(dp, f), root)))
D = os.path.expanduser('~/mnt/thugpro recomp/THUG Pro Kali v2 - 1.2 Dev/data')
have_dev = set()
for dp, dn, fn in os.walk(os.path.join(D, 'models')):
    for f in fn:
        have_dev.add(norm(os.path.relpath(os.path.join(dp, f), D)))
for prx in [G+'/pre/Bits.prx', G+'/pre/skaterparts.prx', G+'/pre/skaterparts_secret.prx', G+'/pre/skaterparts_temp.prx', G+'/pre/casfiles.prx', O+'/pre/thugpro_models.prx']:
    for n, ck, d, u in entries(prx):
        have.add(norm(n))
# lists: last definition wins, load order: game/*.q then thugpro/procrastination.q
files = [os.path.join(W, 'decompiled/thugpro_qb/qb/game', f) for f in sorted(os.listdir(W + '/decompiled/thugpro_qb/qb/game')) if f.startswith('cas_')]
files = [os.path.join(W, 'decompiled/thugpro_qb/qb', f) for f in sorted(os.listdir(W + '/decompiled/thugpro_qb/qb')) if f.startswith('cas_') and f.endswith('.q')] + files
files.append(W + '/decompiled/thugpro_qb/qb/thugpro/procrastination.q')
lists = {}
for f in files:
    L = open(f, encoding='latin1').read().split('\n')
    i = 0
    while i < len(L):
        m = re.match(r'^(\w+) = \[\s*$', L[i])
        if m:
            name = m.group(1); items = []; depth = 0; cur = None; i += 1
            while not L[i].startswith(']'):
                l = L[i].strip()
                if depth == 0 and l == '{': cur = []
                if cur is not None: cur.append(l)
                depth += l.count('{') - l.count('}')
                if depth == 0 and cur is not None:
                    items.append(cur); cur = None
                i += 1
            if any(any(x.startswith('desc_id') for x in it) for it in items):
                lists[name] = (os.path.basename(f), items)
        i += 1
bad = {}
for name, (src, items) in lists.items():
    for it in items:
        d = next((x[len('desc_id = '):] for x in it if x.startswith('desc_id = ')), None)
        meshes = re.findall(r'(?:mesh\w*|model\w*) = "([^"]+)"', '\n'.join(it))
        miss = [m for m in meshes if norm(m) not in have]
        if miss:
            local = all(norm(m) in have or norm(m) in have_dev for m in miss)
            if d == 'Skater_Paulie':
                local = norm('models/cutscenes/Paulie_Full.skin') in have   # casfix points it there in our build
            bad.setdefault(name, []).append((d, miss, 'hidden' in it, local))
tot = 0
for name in sorted(bad):
    print(name, '(%s)' % lists[name][0])
    for d, miss, hid, local in bad[name]:
        tot += 1
        print('   ', d, miss, 'hidden' if hid else 'SHOWN', 'offline' if local else 'NO MODEL')
print('total', tot, 'lists', len(lists))
open(W + '/mods/casmod/unsafe_parts.txt', 'w', newline='\n').write(''.join('%s %s %s\n' % (k, b[0], 'offline' if b[3] else 'never') for k in sorted(bad) for b in bad[k]))
