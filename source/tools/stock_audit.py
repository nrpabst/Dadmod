r"""Release audit (Noah 2026-11-17): files.dad must hold no THUG Pro / Kali bytes. Every file that goes in (archives are
checked unpacked) is scanned for any run of RUN or more bytes that also occurs in the stock game scripts: thugpro_qb,
thugpro_qe, Skateshop and every level script archive of plain THUG Pro and both Kali builds, plus the THUG2 level
scripts THUG Pro uses. The allowed list (Larxian's cities, the chosen P8/Vault/THPG maps, binkw32.dll) is skipped by
the caller.
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from prx_extract import entries as prx_entries   # noqa: E402
import dadpatch   # noqa: E402

KEY = 32          # index key length; any shared run of 2*KEY-1 bytes or more is always found
RUN = 2 * KEY - 1
MIN_DISTINCT = 8   # plain runs (one color, padding, zeros) are no one's content


def corpus_files(games):
    seen = set()
    for g in games:
        pre = os.path.join(g, 'data', 'pre')
        if not os.path.isdir(pre):
            continue
        for f in sorted(os.listdir(pre)):
            fl = f.lower()
            if fl.endswith('_scripts.prx') or fl in ('thugpro_qb.prx', 'thugpro_qe.prx') or fl.startswith('thugpro_') and fl.endswith('.prx') and 'qb' in fl:
                p = os.path.join(pre, f)
                if fl.startswith('mainmenu_') or fl.startswith('dadmod'):
                    continue
                yield p
    r = dadpatch.thug2_root()
    if r and os.path.isdir(os.path.join(r, 'Data', 'pre')):
        pre = os.path.join(r, 'Data', 'pre')
        for f in sorted(os.listdir(pre)):
            if f.lower().endswith('_scripts.prx'):
                yield os.path.join(pre, f)


def build_index(games):
    index = {}
    n = 0
    for p in corpus_files(games):
        try:
            for name, ck, data, usz in prx_entries(p):
                for o in range(0, len(data) - KEY + 1, KEY):
                    k = data[o:o + KEY]
                    if len(set(k)) >= MIN_DISTINCT:
                        index.setdefault(k, (p, name))
                n += 1
        except Exception:
            continue
    return index, n


def unpacked(name, data):
    """an archive is checked entry by entry, unpacked; anything else as it is"""
    if name.lower().endswith('.prx') and data[4:8] == b'\x03\x00\xcd\xab':
        import tempfile
        with tempfile.NamedTemporaryFile(delete=False, suffix='.prx') as t:
            t.write(data)
        try:
            for en, ck, d, usz in prx_entries(t.name):
                yield name + ':' + en, d
        finally:
            os.remove(t.name)
    else:
        yield name, data


import re
# compiled script name labels (0x2B, checksum, name, 0): the names the compiler stores next to the code, the same in
# anyone's files that use those names; they are not content (Noah's rule, 2026-11-17), so the audit blanks them
# Kali's idle loop names and the Kalimod item's text: used with credit (Noah 2026-11-17, INSTALL.txt and the Idle loops page)
CREDITED = [b'Idle Sequence Loop', b'Pro Ped Idle Sequence Loop 1', b'Pro Ped Idle Sequence Loop 2', b'Skater Ped Idle Sequence Loop 1',
            b'Skater Ped Idle Sequence Loop 2', b'Kneeling Sequence Loop', b'Sit/Lean Sequence Loop', b'Sit (On Deck) Loop',
            b'Every feature of this mod...', b'Kalimod Features']
NAME_LABEL = re.compile(rb'\x2b[\x00-\xff]{4}[\x20-\x7e]{2,}\x00', re.S)


def audit(files, games):
    """files: [(name, bytes)] -> list of hits (name, offset, source)"""
    index, n = build_index(games)
    hits = []
    for name, data in files:
        for sub, d in unpacked(name, data):
            d = NAME_LABEL.sub(lambda m: bytes(len(m.group(0))), d)
            for c in CREDITED:
                d = d.replace(c, bytes(len(c)))
            for o in range(0, len(d) - KEY + 1):
                src = index.get(d[o:o + KEY])
                if src and len(set(d[o:o + KEY])) >= MIN_DISTINCT:
                    hits.append((sub, o, '%s:%s' % (os.path.basename(src[0]), src[1])))
                    break
    return hits, n
