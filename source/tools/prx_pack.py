"""Rebuild a PRE v3 (.prx) archive, replacing or adding entries.

  prx_pack.py ORIG.prx OUT.prx [--dir DIR] [--add NAME=FILE]...

Entries keep their original order and original (compressed) bytes unless a
replacement exists. With --dir, DIR/<entry name> replaces that entry when present
(use the same relative layout prx_extract.py produced). Replaced/added entries
are stored uncompressed (csz=0), which the engine accepts (62 shipped entries
already use it). With no replacements the output is byte-identical to ORIG.
"""
import os, struct, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from qb import qbkey

def read_entries(path):
    b = open(path, 'rb').read()
    total, ver, magic, n = struct.unpack_from('<IHHI', b, 0)
    assert magic == 0xABCD and ver == 3, 'not a PRE v3 archive'
    off, out = 12, []
    for _ in range(n):
        usz, csz, nl, ck = struct.unpack_from('<IIII', b, off)
        name = b[off + 16:off + 16 + nl].split(b'\0')[0].decode('latin1')
        d = csz or usz
        out.append({'name': name, 'usz': usz, 'csz': csz, 'ck': ck,
                    'data': b[off + 16 + nl:off + 16 + nl + d]})
        off += 16 + nl + ((d + 3) & ~3)
    return out

def write_archive(entries, path):
    body = bytearray()
    for e in entries:
        nm = e['name'].encode('latin1') + b'\0'
        nm += b'\0' * ((-len(nm)) % 4)
        body += struct.pack('<IIII', e['usz'], e['csz'], len(nm), e['ck']) + nm + e['data']
        body += b'\0' * ((-len(e['data'])) % 4)
    hdr = struct.pack('<IHHI', 12 + len(body), 3, 0xABCD, len(entries))
    open(path, 'wb').write(hdr + body)

def stored(name, data):
    return {'name': name, 'usz': len(data), 'csz': 0, 'ck': qbkey(name), 'data': data}

def main(argv):
    orig, out, args = argv[0], argv[1], argv[2:]
    entries = read_entries(orig)
    replaced = []
    while args:
        if args[0] == '--dir':
            d = args[1]; args = args[2:]
            for e in entries:
                p = os.path.join(d, e['name'].replace('\\', os.sep))
                if os.path.isfile(p):
                    e.update(stored(e['name'], open(p, 'rb').read())); replaced.append(e['name'])
        elif args[0] == '--add':
            name, src = args[1].split('=', 1); args = args[2:]
            data = open(src, 'rb').read()
            hit = next((e for e in entries if e['name'].lower() == name.lower()), None)
            if hit: hit.update(stored(hit['name'], data))
            else: entries.append(stored(name, data))
            replaced.append(name)
        else:
            raise SystemExit(f'unknown arg {args[0]}')
    write_archive(entries, out)
    print(f'wrote {out}: {len(entries)} entries, {len(replaced)} replaced/added')

if __name__ == '__main__':
    main(sys.argv[1:])
