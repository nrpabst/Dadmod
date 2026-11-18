"""Which of our QB scripts/globals the client build needs, and where they come from.

    python -I client/tools/analyze.py [build/obsspawn_test/mod/qb] [decompiled/thugpro_qb/qb]   (run from work/)

Reads the server build's script tree (every file it changes) and the decompiled Kali Original scripts,
finds our blocks (added, or changed from the original), names the mod folder each one comes from, and
follows references from the client mods (mods/MANIFEST.tsv client = yes/later) to list what else they pull
in. Writes client/tools/analysis.tsv.
"""
import os, re, sys, glob, collections

WORK = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.chdir(WORK)
MOD = sys.argv[1] if len(sys.argv) > 1 else 'build/obsspawn_test/mod/qb'
BASE = sys.argv[2] if len(sys.argv) > 2 else 'decompiled/thugpro_qb/qb'
STOCK = 'decompiled_stock/thugpro_qb/qb'   # THUG Pro REAL BASE INSTALL (stock), decompiled
SKIP = re.compile(r'\.(before|bak|broken|failed|held|new|after|with|old)')

def blocks(path):
    """script NAME ... endscript, and top-level NAME = value (up to where its braces/brackets close)."""
    out = collections.OrderedDict()
    if not os.path.isfile(path):
        return out
    cur, depth = None, 0
    for line in open(path, encoding='latin-1').read().replace('\r', '').split('\n'):
        if cur and cur.startswith('script '):
            out[cur] += line + '\n'
            if line.startswith('endscript'):
                cur = None
            continue
        if cur and depth > 0:
            out[cur] += line + '\n'
            depth += line.count('{') + line.count('[') - line.count('}') - line.count(']')
            if depth <= 0:
                cur = None
            continue
        m = re.match(r'^script\s+(\S+)', line)
        if m:
            cur = 'script ' + m.group(1); out[cur] = line + '\n'; continue
        m = re.match(r'^([^\s=]+)\s*=', line)
        if m:
            cur = 'global ' + m.group(1); out[cur] = line + '\n'
            depth = line.count('{') + line.count('[') - line.count('}') - line.count(']')
            if depth <= 0:
                cur = None
    return out


def name_of(k):
    return k.split(' ', 1)[1]

# ---- manifest
side, client = {}, {}
for ln in open('mods/MANIFEST.tsv', encoding='latin-1'):
    if ln.startswith('#') or not ln.strip():
        continue
    f = ln.rstrip('\n').split('\t')
    side[f[0]], client[f[0]] = f[1], f[2]

# ---- where each definition lives in mods/ (not host_observer)
origin = collections.defaultdict(set)
for p in glob.glob('mods/**/*.q', recursive=True):
    if SKIP.search(p) or '/host_observer/' in p or '_live' in p:
        continue
    mod = p.split('/')[1]
    for k in blocks(p):
        origin[name_of(k).lower()].add(mod)

# ---- our blocks in the server build
ours = {}
for p in glob.glob(os.path.join(MOD, '**', '*.q'), recursive=True):
    if SKIP.search(p):
        continue
    rel = os.path.relpath(p, MOD)
    b, m = blocks(os.path.join(BASE, rel)), blocks(p)
    for k, v in m.items():
        if k not in b:
            ours[name_of(k).lower()] = (k, rel, 'added', v)
        elif b[k] != v:
            ours[name_of(k).lower()] = (k, rel, 'changed', v)
tok = re.compile(r'[A-Za-z_][A-Za-z0-9_]*')

def mods_of(n):
    return sorted(origin.get(n, {'host_observer'}))

def is_client(n):
    return any(client.get(m) in ('yes', 'later') for m in mods_of(n))

refs = {n: {t.lower() for t in tok.findall(v[3])} & ours.keys() - {n} for n, v in ours.items()}
need, todo = set(), [n for n in ours if is_client(n)]
why = {}
while todo:
    n = todo.pop()
    if n in need:
        continue
    need.add(n)
    for r in refs[n]:
        if r not in need:
            why.setdefault(r, n); todo.append(r)

# every block of stock THUG Pro and of Kali Original, by name, whatever file it is in
def all_blocks(root):
    d = {}
    for p in glob.glob(os.path.join(root, '**', '*.q'), recursive=True):
        for k, v in blocks(p).items():
            d[name_of(k).lower()] = v
    return d
stock, kali = all_blocks(STOCK), all_blocks(BASE)

def base_state(n):
    if n not in kali and n not in stock:
        return 'new'
    if n not in stock:
        return 'kali-only'
    if n not in kali:
        return 'stock-only'
    return 'same-in-stock-and-kali' if stock[n] == kali[n] else 'KALI-DIFFERS'

rows = []
for n in sorted(need):
    k, rel, kind, v = ours[n]
    ms = mods_of(n)
    tag = 'client' if is_client(n) else ('SERVER' if any(side.get(m) == 'server' for m in ms) else 'host_observer')
    rows.append((tag, kind, k, rel, ','.join(ms), why.get(n, ''), base_state(n)))
with open('client/tools/analysis.tsv', 'w') as f:
    f.write('# tag\tkind\tblock\tfile\tmods\tpulled in by\tstock vs kali\n')
    for r in rows:
        f.write('\t'.join(r) + '\n')
c = collections.Counter((r[0], r[1]) for r in rows)
print('our blocks in the server build:', len(ours), ' needed by client mods:', len(need))
for k, v in sorted(c.items()):
    print(' ', k, v)
