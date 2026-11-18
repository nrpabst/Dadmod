r"""dadmod patch recipes (Noah 2026-11-17: the public release ships no THUG Pro / Kali bytes).

A recipe rebuilds one of our files byte for byte on the player's PC from the player's own game files plus our own
bytes. Copy ops point into "sources" (entries of the player's .prx archives, unpacked, or loose files), insert ops
carry our bytes. Every source is pinned by its md5, so a recipe only applies to the exact files it was made from;
a recipe can hold several variants (plain THUG Pro, the Kali Mod builds) and the installer uses the first variant
whose sources all match. The result is checked against the target md5 before it is written.

  python -I tools/dadpatch.py make OUT.dpr TARGET_FILE GAMEDIR [GAMEDIR...] --src data\pre\thugpro_qb.prx [--src ...]
  python -I tools/dadpatch.py apply RECIPE.dpr GAMEDIR OUT_FILE
  python -I tools/dadpatch.py info RECIPE.dpr

File format (little endian):
  "DPR1"  u32 target_size  16 bytes target md5  u16 len + utf8 target path  u16 n_variants
  variant: u16 n_sources, then per source: u16 len + utf8 game-relative path, u16 len + utf8 entry name ("" = whole
           file), 16 bytes md5 of the source bytes;  u32 n_ops, then per op:
           0x01 u16 source u32 offset u32 length   (copy)
           0x02 u32 length + bytes                 (insert, our bytes)
Inserts never hold a run of MIN_COPY or more bytes that also occurs in a source (those become copies).
"""
import hashlib, os, struct, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from prx_extract import entries as prx_entries   # noqa: E402

MIN_COPY = 16
SPARSE = 32


def thug2_root():
    # the THUG2 game folder THUG Pro reads THUG2 levels from (HKCU Software/THUG Pro/Settings thug2_path)
    try:
        import winreg
        with winreg.OpenKey(winreg.HKEY_CURRENT_USER, r'Software\THUG Pro\Settings') as k:
            return winreg.QueryValueEx(k, 'thug2_path')[0]
    except Exception:
        return None


# files the release itself installs (the extra levels): read from here when the game folder has none (build time only)
OVERLAY = {}   # lower game-relative path -> full path


def resolve(gamedir, path):
    """game-relative path; "thug2:" paths are relative to the THUG2 game folder"""
    if path.lower().startswith('thug2:'):
        r = thug2_root()
        return os.path.join(r, path[6:]) if r else None
    full = os.path.join(gamedir, path)
    if not os.path.isfile(full) and path.lower() in OVERLAY:
        return OVERLAY[path.lower()]
    return full


_cache = {}


def _entries(full):
    if full not in _cache:
        _cache[full] = [(n, d) for n, ck, d, usz in prx_entries(full)]
    return _cache[full]


def all_script_sources(gamedir):
    """every stock script archive a THUG Pro player has: data\\pre script archives and the THUG2 level scripts"""
    out = []
    pre = os.path.join(gamedir, 'data', 'pre')
    for f in sorted(os.listdir(pre)):
        fl = f.lower()
        if fl.startswith('mainmenu_') or fl.startswith('dadmod'):
            continue
        if fl.endswith('_scripts.prx') or fl in ('thugpro_qb.prx', 'thugpro_qe.prx'):
            out.append(os.path.join('data', 'pre', f))
    r = thug2_root()
    if r and os.path.isdir(os.path.join(r, 'Data', 'pre')):
        for f in sorted(os.listdir(os.path.join(r, 'Data', 'pre'))):
            if f.lower().endswith('_scripts.prx'):
                out.append('thug2:' + os.path.join('Data', 'pre', f))
    return out


def read_source(gamedir, path, entry):
    full = resolve(gamedir, path)
    if not full or not os.path.isfile(full):
        return None
    if not entry:
        return open(full, 'rb').read()
    for name, data in _entries(full):
        if name.lower() == entry.lower():
            return data
    return None


def source_list(gamedir, srcs):
    """srcs: game-relative paths; a .prx gives one source per entry, anything else the whole file"""
    out = []
    for path in srcs:
        full = resolve(gamedir, path)
        if not full or not os.path.isfile(full):
            continue
        if path.lower().endswith('.prx'):
            try:
                for name, data in _entries(full):
                    out.append((path, name, data))
            except Exception:
                continue
        else:
            out.append((path, '', open(full, 'rb').read()))
    return out


class Corpus:
    """one game's sources with a sparse index (every SPARSE-th window), built once and used for many targets"""
    def __init__(self, gamedir, srcs):
        self.game = gamedir
        self.sources = source_list(gamedir, srcs)
        self.sparse = {}
        for si, (_, _, data) in enumerate(self.sources):
            for o in range(0, len(data) - SPARSE + 1, SPARSE):
                self.sparse.setdefault(data[o:o + SPARSE], si)


def make_ops(sources, target, sparse=None):
    # 1) which sources share aligned 32-byte windows with the target at all (cheap sparse index)
    if sparse is None:
        sparse = {}
        for si, (_, _, data) in enumerate(sources):
            for o in range(0, len(data) - SPARSE + 1, SPARSE):
                sparse.setdefault(data[o:o + SPARSE], si)
    hit = set()
    for o in range(0, len(target) - SPARSE + 1):
        si = sparse.get(target[o:o + SPARSE])
        if si is not None:
            hit.add(si)
    # 2) full index (every position) of those sources only
    index = {}
    for si in sorted(hit):
        data = sources[si][2]
        for o in range(0, len(data) - MIN_COPY + 1):
            index.setdefault(data[o:o + MIN_COPY], (si, o))
    ops, lit, i, n = [], bytearray(), 0, len(target)
    while i < n:
        m = index.get(target[i:i + MIN_COPY]) if i + MIN_COPY <= n else None
        if m is None:
            lit.append(target[i]); i += 1
            continue
        si, so = m
        data = sources[si][2]
        ln = MIN_COPY
        while i + ln < n and so + ln < len(data) and target[i + ln] == data[so + ln]:
            ln += 1
        # grow backwards into the pending literal bytes
        back = 0
        while back < len(lit) and so - back - 1 >= 0 and lit[len(lit) - back - 1] == data[so - back - 1]:
            back += 1
        if back:
            del lit[len(lit) - back:]
        if lit:
            ops.append((2, bytes(lit))); lit = bytearray()
        ops.append((1, si, so - back, ln + back))
        i += ln
    if lit:
        ops.append((2, bytes(lit)))
    return ops


def apply_ops(ops, datas):
    out = bytearray()
    for op in ops:
        if op[0] == 1:
            _, si, o, ln = op
            out += datas[si][o:o + ln]
        else:
            out += op[1]
    return bytes(out)


def _s(b):
    b = b.encode('utf-8')
    return struct.pack('<H', len(b)) + b


def encode(target_path, target, variants):
    """variants: [(sources_used [(path, entry, data)], ops)]"""
    out = bytearray(b'DPR1' + struct.pack('<I', len(target)) + hashlib.md5(target).digest() + _s(target_path))
    out += struct.pack('<H', len(variants))
    for srcs, ops in variants:
        out += struct.pack('<H', len(srcs))
        for path, entry, data in srcs:
            out += _s(path) + _s(entry) + hashlib.md5(data).digest()
        out += struct.pack('<I', len(ops))
        for op in ops:
            if op[0] == 1:
                out += struct.pack('<BHII', 1, op[1], op[2], op[3])
            else:
                out += struct.pack('<BI', 2, len(op[1])) + op[1]
    return bytes(out)


def decode(b):
    assert b[:4] == b'DPR1', 'not a dadmod recipe'
    size, = struct.unpack_from('<I', b, 4)
    md5 = b[8:24]
    p = 24

    def s():
        nonlocal p
        ln, = struct.unpack_from('<H', b, p); p += 2
        v = b[p:p + ln].decode('utf-8'); p += ln
        return v
    target_path = s()
    nv, = struct.unpack_from('<H', b, p); p += 2
    variants = []
    for _ in range(nv):
        ns, = struct.unpack_from('<H', b, p); p += 2
        srcs = []
        for _ in range(ns):
            path = s(); entry = s(); m = b[p:p + 16]; p += 16
            srcs.append((path, entry, m))
        no, = struct.unpack_from('<I', b, p); p += 4
        ops = []
        for _ in range(no):
            t = b[p]
            if t == 1:
                _, si, o, ln = struct.unpack_from('<BHII', b, p); p += 11
                ops.append((1, si, o, ln))
            else:
                ln, = struct.unpack_from('<I', b, p + 1); p += 5
                ops.append((2, b[p:p + ln])); p += ln
        variants.append((srcs, ops))
    return target_path, size, md5, variants


def make(target_file, target_path, gamedirs, srcs=None, corpora=None):
    """one variant per game folder (identical variants are kept once); corpora: prebuilt Corpus objects instead"""
    target = open(target_file, 'rb').read()
    variants, seen = [], set()
    if corpora is None:
        corpora = [Corpus(g, srcs) for g in gamedirs]
    for c in corpora:
        sources = c.sources
        ops = make_ops(sources, target, c.sparse)
        used = sorted({op[1] for op in ops if op[0] == 1})
        remap = {si: k for k, si in enumerate(used)}
        ops = [(1, remap[op[1]], op[2], op[3]) if op[0] == 1 else op for op in ops]
        vsrcs = [sources[si] for si in used]
        key = tuple((p, e, hashlib.md5(d).hexdigest()) for p, e, d in vsrcs)
        assert apply_ops(ops, [d for _, _, d in vsrcs]) == target
        if key in seen:
            continue
        seen.add(key)
        variants.append((vsrcs, ops))
    return encode(target_path, target, variants), variants, target


def inserts(b):
    """our own bytes in a recipe (every insert op of every variant), for the audit"""
    out = []
    for srcs, ops in decode(b)[3]:
        out += [op[1] for op in ops if op[0] == 2]
    return out


def apply_recipe(b, gamedir):
    target_path, size, md5, variants = decode(b)
    for srcs, ops in variants:
        datas = []
        for path, entry, m in srcs:
            d = read_source(gamedir, path, entry)
            if d is None or hashlib.md5(d).digest() != m:
                break
            datas.append(d)
        else:
            out = apply_ops(ops, datas)
            if hashlib.md5(out).digest() == md5:
                return out
    return None


def stats(variants, target):
    lines = []
    for srcs, ops in variants:
        ins = sum(len(op[1]) for op in ops if op[0] == 2)
        lines.append('%d sources, %d ops, %d of %d bytes ours (%.1f%%)' % (len(srcs), len(ops), ins, len(target), 100.0 * ins / max(1, len(target))))
    return lines


if __name__ == '__main__':
    a = sys.argv[1:]
    if a[0] == 'make':
        out, tf, rest = a[1], a[2], a[3:]
        srcs = [rest[i + 1] for i, x in enumerate(rest) if x == '--src']
        tp = [rest[i + 1] for i, x in enumerate(rest) if x == '--path']
        games = [x for i, x in enumerate(rest) if x not in ('--src', '--path') and (i == 0 or rest[i - 1] not in ('--src', '--path'))]
        b, variants, target = make(tf, tp[0] if tp else os.path.basename(tf), games, srcs)
        open(out, 'wb').write(b)
        print('\n'.join(stats(variants, target)), '->', out, len(b), 'bytes')
    elif a[0] == 'apply':
        r = apply_recipe(open(a[1], 'rb').read(), a[2])
        if r is None:
            sys.exit('no variant matches this game folder')
        open(a[3], 'wb').write(r)
        print('ok', len(r))
    elif a[0] == 'info':
        tp, size, md5, variants = decode(open(a[1], 'rb').read())
        print(tp, size, md5.hex())
        for srcs, ops in variants:
            print(' variant:', len(srcs), 'sources,', len(ops), 'ops')
