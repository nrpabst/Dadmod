r"""Full parse of a THUG2-layout collision file (P8 uses the same layout with a 0x50 byte header).

    sections(data, hdr) -> dict(header, objtab, verts, inten, faces, facebytes, nodes, leaves, ...)
Each object row (0x40 bytes): u32 checksum, u16 flags, u16 nverts, u16 nfaces, u8 small_faces, u8 fixed_verts,
u32 first face byte offset, 4f bbox min, 4f bbox max, u32 vert byte offset, u32 bsp byte offset,
u32 intensity offset, u32 pad. Faces: u16 flags, u16 terrain, 3 x u16 (large, 10 bytes) or 3 x u8 + pad (small,
8 bytes). After the faces (2-aligned) one byte per face, then (4-aligned) u32 node bytes, the BSP nodes
(8 bytes: leaf = u8 3 | u8 0 | u16 count, u32 face list index; node = i32 (axis | split*16 << 2), u32 left child
byte offset; right child follows left) and the u16 leaf face lists.
"""
import struct


def sections(b, hdr):
    ver, nobj, tv, nf, nlf, nlv, nsv, _ = struct.unpack_from('<8I', b, 0)
    objs = []
    fsize = 0
    for i in range(nobj):
        o = hdr + i * 0x40
        cs, fl, nv, nfo, sf, fx, ff = struct.unpack_from('<IHHHBBI', b, o)
        bmin = struct.unpack_from('<4f', b, o + 0x10)
        bmax = struct.unpack_from('<4f', b, o + 0x20)
        vo, bo, io, pad = struct.unpack_from('<4I', b, o + 0x30)
        objs.append(dict(cs=cs, flags=fl, nv=nv, nf=nfo, small=sf, fixed=fx, ff=ff, bmin=bmin, bmax=bmax,
                         vo=vo, bo=bo, io=io, row=b[o:o + 0x40]))
        fsize = max(fsize, ff + nfo * (8 if sf else 10))
    vbase = (hdr + 0x40 * nobj + 15) & ~15
    vend = vbase + nlv * 12 + nsv * 6
    ibase = vend
    fbase = (ibase + tv + 3) & ~3
    fend = fbase + fsize
    p = (fend + 1) & ~1
    facebytes = b[p:p + nf]
    p = (p + nf + 3) & ~3
    nbytes = struct.unpack_from('<I', b, p)[0]
    nodes = b[p + 4:p + 4 + nbytes]
    leaves = b[p + 4 + nbytes:]
    return dict(header=struct.unpack_from('<8I', b, 0), extra_header=b[0x20:hdr], objs=objs,
                verts=b[vbase:vend], inten=b[ibase:ibase + tv], faces=b[fbase:fend], facebytes=facebytes,
                nodes=nodes, leaves=leaves)


def obj_faces(s, o):
    out = []
    p = o['ff']
    for j in range(o['nf']):
        fl, tt = struct.unpack_from('<HH', s['faces'], p)
        if o['small']:
            vi = tuple(s['faces'][p + 4:p + 7])
            p += 8
        else:
            vi = struct.unpack_from('<3H', s['faces'], p + 4)
            p += 10
        out.append((fl, tt, vi))
    return out


def obj_verts(s, o):
    p = o['vo']
    if o['fixed']:
        mn = o['bmin']
        return [tuple(mn[k] + v[k] * 0.0625 for k in range(3)) for v in struct.iter_unpack('<3H', s['verts'][p:p + 6 * o['nv']])]
    return list(struct.iter_unpack('<3f', s['verts'][p:p + 12 * o['nv']]))


def obj_tree(s, o):
    """[(kind, a, b)] nodes of this object's BSP in breadth order reachable from its root"""
    out = []
    stack = [o['bo']]
    seen = set()
    while stack:
        no = stack.pop(0)
        if no in seen or no + 8 > len(s['nodes']):
            continue
        seen.add(no)
        w, v = struct.unpack_from('<iI', s['nodes'], no)
        if (w & 3) == 3:
            cnt = (w >> 16) & 0xFFFF
            out.append(('leaf', cnt, tuple(struct.unpack_from('<%dH' % cnt, s['leaves'], 2 * v)) if 2 * (v + cnt) <= len(s['leaves']) else None))
        else:
            out.append(('node', w & 3, w >> 2))
            stack += [v, v + 8]
    return out
