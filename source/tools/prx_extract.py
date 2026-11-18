"""Extract Neversoft PRE v3 (.prx/.pre) archives. Usage: prx_extract.py OUTDIR file.prx [...]"""
import struct, sys, os

def lzss(src, out_size):
    N, F, TH = 4096, 18, 2
    ring = bytearray(b" " * N); r = N - F  # Okumura LZSS: ring starts as spaces
    out = bytearray(); i = 0; flags = 0
    while len(out) < out_size and i < len(src):
        flags >>= 1
        if not flags & 0x100:
            flags = src[i] | 0xFF00; i += 1
        if flags & 1:
            c = src[i]; i += 1
            out.append(c); ring[r] = c; r = (r + 1) & (N - 1)
        else:
            if i + 1 >= len(src): break
            lo, hi = src[i], src[i + 1]; i += 2
            pos = lo | ((hi & 0xF0) << 4); ln = (hi & 0x0F) + TH + 1
            for k in range(ln):
                c = ring[(pos + k) & (N - 1)]
                out.append(c); ring[r] = c; r = (r + 1) & (N - 1)
    return bytes(out)

def entries(path):
    b = open(path, 'rb').read()
    total, ver, magic, n = struct.unpack_from('<IHHI', b, 0)
    assert magic == 0xABCD, f"{path}: bad magic {magic:#x}"
    off = 12
    for _ in range(n):
        usz, csz, nl, ck = struct.unpack_from('<IIII', b, off); off += 16
        name = b[off:off + nl].split(b'\0')[0].decode('latin1'); off += nl
        d = csz or usz
        raw = b[off:off + d]; off += (d + 3) & ~3
        yield name, ck, (lzss(raw, usz) if csz else raw), usz

if __name__ == '__main__':
    out = sys.argv[1]; bad = 0; total = 0
    for p in sys.argv[2:]:
        base = os.path.splitext(os.path.basename(p))[0]
        for name, ck, data, usz in entries(p):
            total += 1
            if len(data) != usz: bad += 1; print("SIZE MISMATCH", p, name, len(data), usz)
            dst = os.path.join(out, base, name.replace(chr(92), os.sep))
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            open(dst, 'wb').write(data)
    print(f"extracted {total} entries, {bad} size mismatches")
