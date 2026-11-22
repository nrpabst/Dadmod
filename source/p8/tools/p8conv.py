r"""Project 8 (original Xbox) zone -> THUG Pro (THUG2 PC) level files.

Our own reader for P8's Xbox zone files and writer for THUG2-format scene, collision and texture files.

    python -I p8conv.py convert <zone.pak.xbx> <outdir> <LevelName>

writes <outdir>\<LevelName>.scn.xbx, .tex.xbx, .col.xbx and <LevelName>_nodes.json (node array dump).

P8 Xbox formats (little endian), as worked out from the disc files:
  pak:  32-byte entries (type crc, offset from entry, size, pak crc, full name crc, name crc, unk, flags) [+160 byte name]
  tex:  0xFACECAA2, u16 ?, u16 count, u32 entry table, u32 data start, ...; entries 0x28 bytes:
        u16 6, u16 0x28, u32 checksum, u16 w, u16 h, u16 w, u16 h, u8 levels, u8, u8, u8 format (1/2 = DXT1, 5 = DXT5),
        u32 1, u32 ?, u32 -1, u32 -1, u32 absolute data offset; mips stored back to back
  scn:  u32 0, 7 x 0xCABAAAFA; at 0x20: u16 ?, u16 material count, u32 material block size (scene header at 0x20 + it);
        materials 0x120 bytes each from 0x30; scene header B = 0xBABEFACE, u32 extra; R = B + 8 + extra; offsets are relative to R:
        R+0x7C sector count, R+0x80 sector table (0x30 each, checksum at +4, flags at +8),
        R+0x84 geom table (0x68 each, bbox at +0x18/+0x28, mesh count at +0x44), R+0x90 mesh table (0xAC each)
  col:  THUG2 layout with a 0x50 byte header (THUG2: 0x20)
"""
import json, math, os, re, struct, sys, zlib

# ------------------------------------------------------------------ helpers
def crc(s):
    return (zlib.crc32(s.lower().encode()) ^ 0xFFFFFFFF) & 0xFFFFFFFF


def u32(b, o):
    return struct.unpack_from('<I', b, o)[0]


def u16(b, o):
    return struct.unpack_from('<H', b, o)[0]


# ------------------------------------------------------------------ pak
def read_pak(data):
    out = []
    o = 0
    while o + 32 <= len(data):
        t, off, size, pk, full, name, unk, flags = struct.unpack_from('<8I', data, o)
        nm = ''
        if flags & 0x20:
            nm = data[o + 32:o + 32 + 0xA0].split(b'\0')[0].decode('latin1')
        if t in (crc('.last'), crc('last')):
            break
        out.append(dict(type=t, name=nm, full=full, data=data[o + off:o + off + size]))
        o += 32 + (0xA0 if flags & 0x20 else 0)
    return out


# ------------------------------------------------------------------ textures
class Tex:
    __slots__ = ('checksum', 'width', 'height', 'levels', 'texel_depth', 'palette_depth', 'dxt', 'palette', 'mips')


def read_p8_tex(b):
    assert u32(b, 0) == 0xFACECAA2, 'not a P8 texture dictionary'
    count = u16(b, 6)
    table = u32(b, 8)
    out = []
    for i in range(count):
        o = table + i * 0x28
        cs = u32(b, o + 4)
        w, h = struct.unpack_from('<HH', b, o + 8)
        levels, fmt = b[o + 0x10], b[o + 0x13]
        data = u32(b, o + 0x24)
        if fmt not in (0, 1, 2, 5):
            raise ValueError('texture %08x: unknown format %d' % (cs, fmt))
        bs = 16 if fmt == 5 else 8
        t = Tex()
        t.checksum, t.width, t.height = cs, w, h
        t.texel_depth, t.palette_depth, t.palette = 32, 32, b''   # palette_depth 32 as THUG Pro's P8 levels write it
        t.dxt = {0: 0, 1: 1, 2: 1, 5: 5}[fmt]
        t.mips = []
        p = data
        for lv in range(levels):
            mw, mh = max(1, w >> lv), max(1, h >> lv)
            if fmt == 0:    # 32-bit BGRA; texel order differs per level (see decode_32)
                size = mw * mh * 4
                t.mips.append(decode_32(b[p:p + size], mw, mh))
            else:
                size = max(1, (mw + 3) // 4) * max(1, (mh + 3) // 4) * bs
                t.mips.append(b[p:p + size])
            p += size
        t.levels = len(t.mips)
        out.append(t)
    return out


def morton_bits(w, h):
    """linear texel index bit k (x bits, then y bits) -> address bit in Xbox swizzled (Morton) order"""
    bw, bh = w.bit_length() - 1, h.bit_length() - 1
    m = {}
    sh = xi = yi = 0
    while xi < bw or yi < bh:
        if xi < bw:
            m[xi] = sh
            xi += 1
            sh += 1
        if yi < bh:
            m[bw + yi] = sh
            yi += 1
            sh += 1
    return [m[k] for k in range(bw + bh)]


def decode_32(data, w, h):
    """P8 32-bit textures don't share one texel order: single-level ones are plain Morton swizzled, but in the
    mipmapped sky textures the top level has the Morton bit shuffle applied 5 times and the smaller levels are
    linear (checked: the top level box-filtered down matches mip 1 to within 0.25/255). So for each level try the
    shuffle applied 0..n times and keep the smoothest result (mean neighbour difference); the right order is
    always far smoother than any wrong one (sky: 3.7 vs 18+)."""
    import numpy as np
    nb = (w * h).bit_length() - 1
    if nb < 2:
        return bytes(data)
    mb = morton_bits(w, h)
    px = np.frombuffer(data, np.uint8).reshape(-1, 4)
    lin = np.arange(w * h)
    best = None
    perm = list(range(nb))
    for n in range(nb + 1):
        addr = np.zeros_like(lin)
        for k in range(nb):
            addr |= ((lin >> k) & 1) << perm[k]
        im = px[addr].reshape(h, w, 4)
        f = im[:, :, :3].astype(np.int32)
        score = (np.abs(np.diff(f, axis=0)).mean() if h > 1 else 0) + (np.abs(np.diff(f, axis=1)).mean() if w > 1 else 0)
        if best is None or score < best[0] - 1e-9:
            best = (score, n, im)
        perm = [mb[q] for q in perm]
    return best[2].tobytes()


def unswizzle(data, w, h, bpp):
    """Xbox swizzled (Morton order, interleaving the smaller dimension's bits) -> linear rows"""
    out = bytearray(len(data))
    def morton(x, y):
        o = bit = 0
        mx, my = w - 1, h - 1
        sh = 0
        while mx or my:
            if mx:
                o |= (x & 1) << sh
                x >>= 1
                mx >>= 1
                sh += 1
            if my:
                o |= (y & 1) << sh
                y >>= 1
                my >>= 1
                sh += 1
        return o
    for y in range(h):
        for x in range(w):
            s = morton(x, y) * bpp
            d = (y * w + x) * bpp
            out[d:d + bpp] = data[s:s + bpp]
    return bytes(out)


def write_thug_tex(path, texs):
    parts = [struct.pack('<II', 1, len(texs))]
    for t in texs:
        parts.append(struct.pack('<8I', t.checksum, t.width, t.height, len(t.mips), t.texel_depth, t.palette_depth,
                                 t.dxt, len(t.palette)))
        parts.append(t.palette)
        for m in t.mips:
            parts.append(struct.pack('<I', len(m)))
            parts.append(m)
    open(path, 'wb').write(b''.join(parts))


# ------------------------------------------------------------------ scene
MAT_SIZE = 0x120
# STOCK_PARITY: write P8's material data the way THUG Pro's own P8 conversion (z_center / City Center, which does
# not flicker) does - P8 draw order (+0x2C), sorted, single-sided (+0x0E), per-axis clamp (+0xA0), zbias, blend,
# env passes, duplicates and decal geometry all kept as P8 has them. Verified 2026-11-15 by converting the disc
# z_center and diffing against the shipped file: only the LOD bias (-8/-9) and the UV-wibble data differ.
# False re-enables our older render heuristics (dedupe, decal lift, solid cut-outs, env-pass drop, zbias bumps).
STOCK_PARITY = True

# pass flags we can't carry over (they need extra data blocks we don't convert yet)
DROP_PASS_FLAGS = 0x1 | 0x2 | 0x800


def uv_wibble(b, ptr):
    """P8 per-pass UV wibble: material +0xE0 + 4*pass points at a 0x30-byte entry (in the block after the material
    table) whose 8 floats at +0x20 are what THUG2 stores after the pass. Checked 2026-11-16 against all 13 wibble
    passes of THUG Pro's own z_center: every one sits at ptr + 0x20. (Until fix40 we read ptr - 0x10 = the previous
    entry: each material got its neighbour's motion - leaves with a fast scroll or NaNs, the tree tops jumping.)"""
    if not ptr or ptr + 0x20 + 32 > len(b):
        return None
    w = struct.unpack_from('<8f', b, ptr + 0x20)
    return w if all(math.isfinite(x) for x in w) else None


def vc_wibble(b, o):
    """P8 vertex colour animation of the material at o (pass 0 flag 0x2): +0x100 = sequence count, +0x104 ->
    block whose table at +0x20 holds 12-byte entries {nkeys, phase, keys ptr}; keys = (time ms, RGBA bytes).
    Same layout THUG2's loader (exe 0x4D2CB0, pass 0 only) and its per-frame update (0x4D1B40) use.
    Returns [(phase, [(time, rgba u32), ...]), ...] or None."""
    n, blk = u32(b, o + 0x100), u32(b, o + 0x104)
    if not 0 < n <= 64 or not 0 < blk < len(b) - 0x20 - 12 * n:
        return None
    seqs = []
    for k in range(n):
        nk, phase, kp = struct.unpack_from('<3I', b, blk + 0x20 + 12 * k)
        kp += 0x20                       # P8 pointers are 0x20 short of the data (as for UV wibble; checked vs THUG Pro's z_center)
        if not 0 < nk <= 256 or not 0 < kp <= len(b) - 8 * nk:
            return None
        keys = [struct.unpack_from('<II', b, kp + 8 * q) for q in range(nk)]
        if any(keys[q][0] > keys[q + 1][0] for q in range(nk - 1)):
            return None
        seqs.append((phase, keys))
    return seqs


def anim_textures(b, o, m):
    """P8 animated textures (pass flag 0x800, flashing signs / screens): material +0x10C -> one entry (+0x20)
    {?, nkeys, ..., keys ptr at +0x34}; keys (ptr+0x20) are 0x38 bytes {time ms, 3 x 0, texture per pass [4]
    (0xFFFFFFFF = keep the pass texture), ...}. The last key repeats the one before it and marks the loop end -
    the same rule as THUG2's flipbook (exe 0x4D1CC0: period = last time - first time). Sets p['anim'] =
    [(time, texture), ...] on each 0x800 pass."""
    for p in m['p']:
        p['anim'] = None
    if not any(p['flags'] & 0x800 for p in m['p']):
        return
    e = u32(b, o + 0x10C)
    if not 0 < e < len(b) - 0x60:
        return
    e += 0x20
    n, kp = u32(b, e + 4), u32(b, e + 0x34) + 0x20
    if not 1 < n <= 512 or not 0 < kp <= len(b) - 0x38 * n:
        return
    keys = [struct.unpack_from('<I12xI', b, kp + 0x38 * k)[0] for k in range(n)]
    if any(keys[k] > keys[k + 1] for k in range(n - 1)) or keys[-1] <= keys[0]:
        return
    for j, p in enumerate(m['p']):
        if p['flags'] & 0x800:
            tex = [u32(b, kp + 0x38 * k + 0x10 + 4 * j) for k in range(n)]
            p['anim'] = [(keys[k], p['tex'] if tex[k] == 0xFFFFFFFF else tex[k]) for k in range(n)]


def vc_wibble_verts(b, R, mo, nv):
    """per-vertex colour sequence choice of a P8 mesh (+0xA4 -> nv bytes, 0 = own colour, k = sequence k-1),
    the same convention as THUG2's mesh +0x8C array (exe 0x4D4CA0). None when the mesh has none."""
    p = u32(b, mo + 0xA4)
    if p == 0xFFFFFFFF or R + p + nv > len(b):
        return None
    arr = bytes(b[R + p:R + p + nv])
    return arr if any(arr) else None


def read_p8_scene(b, objects=frozenset(), texs=()):
    """objects: sector checksums that are LevelObjects (models in local space, placed by their node)"""
    nmat = u16(b, 0x22)
    B = 0x20 + u32(b, 0x24)
    assert u32(b, B) == 0xBABEFACE, 'scene header not found'
    R = B + 8 + u32(b, B + 4)
    mats = []
    for i in range(nmat):
        o = 0x30 + i * MAT_SIZE
        m = dict(checksum=u32(b, o), name=u32(b, o + 4), passes=max(1, min(4, u32(b, o + 8))),
                 sorted=b[o + 0x0C], two_sided=b[o + 0x0D], single_sided=b[o + 0x0E],
                 alpha_cutoff=b[o + 0x10], zbias=b[o + 0x11],
                 draw_order=struct.unpack_from('<f', b, o + 0x2C)[0], p=[])
        for j in range(m['passes']):
            mn, mg = struct.unpack_from('<HH', b, o + 0xD0 + 4 * j)
            m['p'].append(dict(
                flags=u32(b, o + 0x30 + 4 * j), tex=u32(b, o + 0x40 + 4 * j),
                color=struct.unpack_from('<3f', b, o + 0x50 + 16 * j),
                blend=u32(b, o + 0x90 + 4 * j) & 0xFF, fixed=u32(b, o + 0x90 + 4 * j) >> 24,
                clamp=u32(b, o + 0xA0 + 4 * j) & 0xFF,
                addr_u=u32(b, o + 0xA0 + 4 * j) & 0xFFFF, addr_v=u32(b, o + 0xA0 + 4 * j) >> 16,
                env=struct.unpack_from('<2f', b, o + 0xB0 + 8 * j),
                mmin=mn, mmag=mg, uvwibble=uv_wibble(b, u32(b, o + 0xE0 + 4 * j))))
        m['vcw'] = vc_wibble(b, o) if m['p'][0]['flags'] & 0x2 else None
        anim_textures(b, o, m)
        mats.append(m)

    nsec = u32(b, R + 0x7C)
    sec_tab = R + u32(b, R + 0x80)
    geom_tab = R + u32(b, R + 0x84)
    mesh_tab = R + u32(b, R + 0x90)
    sectors = []
    mi = 0
    for i in range(nsec):
        so = sec_tab + i * 0x30
        go = geom_tab + i * 0x68
        s = dict(checksum=u32(b, so + 4), flags=u32(b, so + 8),
                 bmin=struct.unpack_from('<3f', b, go + 0x18), bmax=struct.unpack_from('<3f', b, go + 0x28),
                 meshes=[])
        for j in range(u32(b, go + 0x44)):
            mo = mesh_tab + mi * 0xAC
            mi += 1
            stride = b[mo + 0x18]
            col_off, nrm_off, uv_off = b[mo + 0x1C], b[mo + 0x1D], b[mo + 0x1F]
            prim = b[mo + 0x22]
            nv = u16(b, mo + 0x26)
            ni = u32(b, mo + 0x28)
            ib = R + u32(b, mo + 0x58)
            vb = R + u32(b, mo + 0x78) + 0xC
            idx = list(struct.unpack_from('<%dH' % ni, b, ib))
            verts = []
            nuv = (stride - uv_off) // 8 if uv_off else 0
            for k in range(nv):
                p = vb + k * stride
                pos = struct.unpack_from('<3f', b, p)
                nrm = struct.unpack_from('<3f', b, p + nrm_off) if nrm_off else None
                col = b[p + col_off:p + col_off + 4] if col_off else b'\x80\x80\x80\x80'
                uvs = [struct.unpack_from('<2f', b, p + uv_off + 8 * u) for u in range(nuv)]
                verts.append((pos, nrm, col, uvs))
            if prim == 5:
                idx = list_to_strip(idx)
            elif prim != 6:
                raise ValueError('mesh %d: unknown primitive type %d' % (mi - 1, prim))
            s['meshes'].append(dict(flags=u32(b, mo), sphere=struct.unpack_from('<4f', b, mo + 4),
                                    mat=u32(b, mo + 0x14), idx=idx, verts=verts, nuv=nuv,
                                    vcw=vc_wibble_verts(b, R, mo, nv)))
        sectors.append(s)
    if STOCK_PARITY:
        return mats, sectors
    sectors = dedupe_triangles(mats, sectors, objects)
    fix_materials(mats, sectors)
    fix_cutouts(mats, sectors, texs)
    return mats, sectors


def tex_alpha(t):
    """top mip alpha channel as a numpy array (None if it can't be decoded)"""
    import io
    import numpy as np
    from PIL import Image
    w, h, m = t.width, t.height, t.mips[0]
    try:
        if t.dxt == 0:
            return np.frombuffer(m, np.uint8).reshape(-1, 4)[:, 3]
        four = {1: b'DXT1', 5: b'DXT5'}[t.dxt]
        pf = struct.pack('<II4sIIIII', 32, 4, four, 0, 0, 0, 0, 0)
        hdr = b'DDS ' + struct.pack('<IIIIIII', 124, 0x81007, h, w, len(m), 0, 1) + b'\0' * 44 + pf + struct.pack('<IIIII', 0x1000, 0, 0, 0, 0)
        return np.asarray(Image.open(io.BytesIO(hdr + m)).convert('RGBA'))[..., 3].ravel()
    except Exception:
        return None


def fix_cutouts(mats, sectors, texs):
    """P8 draws cut-outs (alpha cutoff set: awnings with scalloped edges, fences, leaves, signs) as blended
    pass 0. In THUG2 a blended pass 0 is a sorted transparent mesh, ordered per mesh every frame - the
    Buckster's Coffee awning's top and underside swapped order as the camera moved (big triangles flashing
    red/maroon). When the texture alpha is (almost) only on/off and the vertex alpha is full, draw it opaque
    with the alpha test instead: it writes depth, so nothing can swap.
    Many signs/posters have no P8 cutoff at all (fully opaque texture, or clean on/off alpha) but are still
    blended - the Fat Cakes "no parking"/"no skateboarding" signs went ghostly every other frame. Those get
    the alpha test at 128 (P8's cutoff if higher) when they have see-through texels, none if they don't."""
    import numpy as np
    T = {t.checksum: t for t in texs}
    valpha = {}
    for s in sectors:
        for me in s['meshes']:
            v = valpha.setdefault(me['mat'], [0, 0])
            v[0] += len(me['verts'])
            v[1] += sum(1 for x in me['verts'] if x[2][3] >= 0x7C)
    cache = {}
    for m in mats:
        p0 = m['p'][0]
        cut = m['alpha_cutoff']
        if p0['blend'] != 5 or p0['tex'] not in T:
            continue
        n, full = valpha.get(m['checksum'], (0, 0))
        if not n or full < 0.98 * n:
            continue
        if p0['tex'] not in cache:
            cache[p0['tex']] = tex_alpha(T[p0['tex']])
        a = cache[p0['tex']]
        if a is None:
            continue
        lo = max(cut, 8)
        mid = ((a > lo) & (a < 230)).mean()       # texels that really need blending
        if mid < 0.10:
            p0['blend'] = 0
            p0['flags'] &= ~0x40
            if (a <= lo).mean() > 0.005:          # has see-through texels: cut them out
                m['alpha_cutoff'] = max(cut, 128)


def solid_cutouts(mats, sectors, min_cutoff=30):
    """Foliage and other hard cut-outs drawn the way P8's own City Center draws its trees (the same leaf textures
    63af9d22 / dcf48c67 / 9b54f6b7 there: pass 0 opaque, alpha test 60, draw order 0, not sorted). Downtown and
    the other zones mark those materials blended (blend 5), many also sorted at draw order 1500: THUG Pro then
    re-sorts every leaf mesh by distance each frame and the canopy pops as the order flips while the camera
    moves. A blended pass-0 material with alpha cutoff >= min_cutoff and full vertex alpha (nothing fades by
    vertex alpha) becomes opaque + alpha test at its own cutoff, unsorted, draw order 0. Returns the checksums."""
    valpha = {}
    for s in sectors:
        for me in s['meshes']:
            v = valpha.setdefault(me['mat'], [0, 0])
            v[0] += len(me['verts'])
            v[1] += sum(1 for x in me['verts'] if x[2][3] >= 0x7C)
    out = []
    for m in mats:
        p0 = m['p'][0]
        n, full = valpha.get(m['checksum'], (0, 0))
        if p0['blend'] != 5 or m['alpha_cutoff'] < min_cutoff or not n or full < 0.98 * n:
            continue
        p0['blend'] = 0
        p0['flags'] &= ~0x40
        m['sorted'] = 0
        m['draw_order'] = 0.0
        out.append(m['checksum'])
    return out


def keep_culling(mats, sectors):
    """THUG Pro's scene loader (0x4D3200) turns back-face culling OFF (material two_sided byte forced to 1) for a
    material whose single_sided byte is 0 when its first pass blends. P8 culls those. Where such a material has
    back-to-back faces (opposite-facing coplanar overlapping triangles: Downtown's street bunting pennants, the
    Buckster's awning top/underside), both sides then draw and z-fight (lit against shadowed: flashing). For
    those materials only, single_sided is set to 1 so the engine keeps culling as P8 does. Returns the list."""
    import numpy as np
    from collections import defaultdict
    M = {m['checksum']: m for m in mats}
    tris = defaultdict(list)
    for s in sectors:
        for me in s['meshes']:
            m = M.get(me['mat'])
            if not m or m['two_sided'] or m['single_sided'] or not m['p'][0]['blend']:
                continue
            V = me['verts']
            for t in strip_tris(me['idx']):
                tris[me['mat']].append([V[i][0] for i in t])
    out = []
    for mat, T in tris.items():
        T = np.array(T, dtype=float)
        n = np.cross(T[:, 1] - T[:, 0], T[:, 2] - T[:, 0])
        ln = np.linalg.norm(n, axis=1)
        ok = ln > 1e-6
        T, n = T[ok], n[ok] / ln[ok, None]
        d = (n * T[:, 0]).sum(1)
        lo, hi = T.min(1), T.max(1)
        for i in range(len(T)):
            j = np.where((n @ n[i] < -0.99) & (np.abs(d + d[i]) < 1.0))[0]
            if len(j) and np.all((lo[j] <= hi[i] + 0.5) & (hi[j] >= lo[i] - 0.5), axis=1).any():
                M[mat]['single_sided'] = 1
                out.append(mat)
                break
    return sorted(out)


def fix_coincident(mats, sectors, objects=frozenset(), cas=None, trick=frozenset()):
    """Coincident triangles that would flicker in THUG Pro (coincident.py has the rules):
    (a) back-to-back faces that look different in a material the engine draws two-sided: both faces move to a
        single-sided clone of the material (two_sided 0, single_sided 1: culled), so each shows from its own side;
    (b) same-facing copies that look different, in one sector or in two CreatedAtStart sectors: the later copy
        is dropped (copies in a piece that isn't created at start are a story variant and stay);
    (c) same-facing overlaps of different materials: counted only (the decal-over-base pattern stock keeps).
    Returns the counts."""
    import coincident
    M = {m['checksum']: m for m in mats}
    two = {cs: coincident.effective_two_sided(m['two_sided'], m['single_sided'], m['p'][0]['blend'])
           for cs, m in M.items()}
    tris, where = [], []
    for si, s in enumerate(sectors):
        scope = s['checksum'] if s['checksum'] in objects else None
        for mi, me in enumerate(s['meshes']):
            V = me['verts']
            for ti, t in enumerate(strip_tris(me['idx'])):
                tris.append((scope, s['checksum'], me['mat'], [V[k][0] for k in t], [V[k][2] for k in t],
                             [V[k][3][0] if V[k][3] else (0.0, 0.0) for k in t]))
                where.append((si, mi, ti))
    found = coincident.find(tris, two)
    drop, move = set(), set()
    from collections import Counter
    left = Counter(where[k][0] for k in range(len(tris)))      # triangles per sector
    for i, j in found['b']:
        si, sj = tris[i][1], tris[j][1]
        if si == sj or cas is None or (si in cas and sj in cas):
            if where[i] in drop or where[j] in drop:
                continue
            # drop the later copy, unless that would empty its sector (a piece that is only the copy):
            # then the earlier copy goes
            k = j if left[where[j][0]] > 1 else i
            if left[where[k][0]] > 1:
                drop.add(where[k])
                left[where[k][0]] -= 1
    # (d) the same surface re-triangulated in two shown sectors with different shading (awning + TrickObject copy)
    nd = 0
    for i in coincident.find_retriangulated(tris, cas, trick):
        if where[i] not in drop and left[where[i][0]] > 1:
            drop.add(where[i])
            left[where[i][0]] -= 1
            nd += 1
    for i, j in found['a']:
        if where[i] not in drop and where[j] not in drop:
            move.add(where[i])
            move.add(where[j])
    clones = {}
    for si, s in enumerate(sectors):
        new_meshes = []
        for mi, me in enumerate(s['meshes']):
            tl = strip_tris(me['idx'])
            keep = [t for ti, t in enumerate(tl) if (si, mi, ti) not in drop and (si, mi, ti) not in move]
            moved = [t for ti, t in enumerate(tl) if (si, mi, ti) in move]
            if keep or not moved and len(keep) == len(tl):
                if len(keep) != len(tl):
                    me = dict(me, idx=list_to_strip([k for t in keep for k in t]))
                new_meshes.append(me)
            if moved:
                cs = me['mat']
                if cs not in clones:
                    c = (cs * 2654435761 + 0x53494E47) & 0xFFFFFFFF
                    while c in M:
                        c = (c + 1) & 0xFFFFFFFF
                    clone = dict(M[cs], checksum=c, two_sided=0, single_sided=1)
                    mats.append(clone)
                    M[c] = clone
                    clones[cs] = c
                new_meshes.append(dict(me, mat=clones[cs], idx=list_to_strip([k for t in moved for k in t])))
        if new_meshes:
            s['meshes'] = new_meshes
        # (a sector left with no triangles keeps its last mesh untouched: never empty)
    return dict(a=len(move), b=len(drop) - nd, c=len(found['c']), d=nd)


def lift_sunk_decals(mats, sectors, objects=frozenset(), cas=None, clear=0.05):
    """(f) blended decals sunk under the opaque surface they cover (coincident.find_sunk): each vertex of a sunk
    face moves along the covered surface's normal to `clear` above it (a vertex shared by several sunk faces takes
    the largest lift; the rest of the decal mesh stays put, so it bends instead of cracking). From there the
    material zbias depth bias wins as it does for stock decals. Returns the number of faces lifted."""
    import coincident
    import numpy as np
    M = {m['checksum']: m for m in mats}
    tris, where = [], []
    for si, s in enumerate(sectors):
        if s['checksum'] in objects or (cas is not None and s['checksum'] not in cas):
            continue
        for mi, me in enumerate(s['meshes']):
            V = me['verts']
            for tt in strip_tris(me['idx']):
                tris.append((None, s['checksum'], me['mat'], [V[k][0] for k in tt], None, None))
                where.append((si, mi, tt))
    sunk = coincident.find_sunk(tris, lambda c: c in M and M[c]['p'] and M[c]['p'][0]['blend'])
    lifts = {}                                       # (sector, mesh, vertex) -> lift vector
    for i, j, depth in sunk:
        B = np.array(tris[j][3], dtype=float)
        nrm = np.cross(B[1] - B[0], B[2] - B[0])
        nrm /= max(np.linalg.norm(nrm), 1e-9)
        si, mi, tt = where[i]
        for k in tt:
            p = np.array(sectors[si]['meshes'][mi]['verts'][k][0], dtype=float)
            need = clear - float(nrm @ (p - B[0]))  # this vertex's own distance below the base plane
            if need <= 0:
                continue
            old = lifts.get((si, mi, k))
            if old is None or need > np.linalg.norm(old):
                lifts[(si, mi, k)] = nrm * need
    for (si, mi, k), v in lifts.items():
        V = sectors[si]['meshes'][mi]['verts']
        V[k] = (tuple(float(x) for x in np.array(V[k][0], dtype=float) + v),) + tuple(V[k][1:])
    return len(sunk)


def resolve_coplanar(mats, sectors, objects=frozenset(), cas=None, lift=0.4):
    """(e) same-facing coplanar overlaps with no stable winner (coincident.find_unstable): faces triangulated
    differently z-fight per pixel whatever the draw order (Downtown's curb + drain grate over the asphalt, a roof
    over its taggable copy). For each covered face pair the OVERLAY wins: the blended one when only one blends,
    else the material with fewer faces in that piece (the decal / smaller surface), else the later one.
    Same material, different shading: the overlay face is dropped when all three corners lie on the other surface
    (no hole); otherwise (and for different materials) the overlay face moves to its own vertices lifted `lift`
    units along its normal, in a copy of its material with zbias + 1 (THUG Pro sets D3DRS_DEPTHBIAS from
    zbias, 0x4DAB60 state 0x15). Returns (dropped, lifted)."""
    import coincident
    import numpy as np
    from collections import Counter
    M = {m['checksum']: m for m in mats}
    mkey = lambda c: (M[c]['sorted'], M[c]['draw_order'], M[c]['zbias'])
    tris, where = [], []
    for si, s in enumerate(sectors):
        if s['checksum'] in objects or (cas is not None and s['checksum'] not in cas):
            continue
        for mi, me in enumerate(s['meshes']):
            V = me['verts']
            for ti, tt in enumerate(strip_tris(me['idx'])):
                tris.append((None, s['checksum'], me['mat'], [V[k][0] for k in tt], [V[k][2] for k in tt],
                             [V[k][3][0] if V[k][3] else (0.0, 0.0) for k in tt]))
                where.append((si, mi, ti))
    pairs = coincident.find_unstable(tris, mkey)
    if not pairs:
        return 0, 0
    cnt = Counter((t[1], t[2]) for t in tris)
    blended = lambda c: bool(M[c]['p'][0]['blend'])

    def overlay(i, j):
        a, b = tris[i], tris[j]
        if blended(a[2]) != blended(b[2]):
            return i if blended(a[2]) else j
        ca, cb = cnt[(a[1], a[2])], cnt[(b[1], b[2])]
        if ca != cb:
            return i if ca < cb else j
        return max(i, j)

    def corners_on(i, j_tris):
        for p in tris[i][3]:
            if not any(coincident._inside(p, *tris[j][3], eps=-1e-3) for j in j_tris):
                return False
        return True

    covers = {}
    for i, j in pairs:
        covers.setdefault(i, []).append(j)
    drop, lifted = set(), set()
    for i, j in pairs:
        o = overlay(i, j)
        base = j if o == i else i
        if where[o] in drop or where[o] in lifted:
            continue
        if tris[o][2] == tris[base][2] and corners_on(o, [base] + covers.get(o, [])):
            drop.add(where[o])
        else:
            lifted.add(where[o])
    clones = {}
    for si, s in enumerate(sectors):
        new_meshes = []
        changed = False
        for mi, me in enumerate(s['meshes']):
            tl = strip_tris(me['idx'])
            keep = [tt for ti, tt in enumerate(tl) if (si, mi, ti) not in drop and (si, mi, ti) not in lifted]
            up = [tt for ti, tt in enumerate(tl) if (si, mi, ti) in lifted]
            if len(keep) == len(tl):
                new_meshes.append(me)
                continue
            changed = True
            if keep:
                new_meshes.append(dict(me, idx=list_to_strip([k for tt in keep for k in tt])))
            if up:
                cs = me['mat']
                if cs not in clones:
                    c = (cs * 2246822519 + 0x4C494654) & 0xFFFFFFFF
                    while c in M:
                        c = (c + 1) & 0xFFFFFFFF
                    clone = dict(M[cs], checksum=c, zbias=min(M[cs]['zbias'] + 1, 16))
                    mats.append(clone)
                    M[c] = clone
                    clones[cs] = c
                V = me['verts']
                nv = []
                for tt in up:
                    P3 = [np.array(V[k][0], dtype=float) for k in tt]
                    nrm = np.cross(P3[1] - P3[0], P3[2] - P3[0])
                    nrm = nrm / max(np.linalg.norm(nrm), 1e-9) * lift
                    for k, p in zip(tt, P3):
                        nv.append((tuple(float(x) for x in p + nrm),) + tuple(V[k][1:]))
                vw = me.get('vcw') and bytes(me['vcw'][k] for tt in up for k in tt)
                new_meshes.append(dict(me, mat=clones[cs], verts=nv, vcw=vw,
                                       idx=list_to_strip(list(range(len(nv))))))
        if changed and new_meshes:
            s['meshes'] = new_meshes
    return len(drop), len(lifted)


def strip_tris(idx):
    """strip -> list of non-degenerate triangles, winding kept (odd strip triangles flipped)"""
    out = []
    for t in range(len(idx) - 2):
        a, b, c = idx[t:t + 3]
        if a != b and b != c and a != c:
            out.append((b, a, c) if t % 2 else (a, b, c))
    return out


def dedupe_triangles(mats, sectors, objects=frozenset()):
    """P8 meshes hold the same triangle more than once within a material: back-to-back copies with reversed
    winding (the street bunting pennants: front and back face in one plane) and exact repeats (bowling pins,
    35 copies). THUG2 draws both and they z-fight. Keep the first copy of each triangle per material and
    direction. Back-to-back faces (front + back, reversed winding) are KEPT and the material keeps P8's
    two_sided flag: THUG Pro culls back faces of single-sided materials (CULLMODE set per material), so exactly
    one of them shows from either side. (Dropping one and forcing two-sided made the Buckster's awning flash:
    its bright top and dark underside are the same surface triangulated differently, so both survived and
    two-sided drew both from above.)
    World (LevelGeometry) sectors are compared with each other too: Downtown's Buckster's Coffee awning is in
    two CreatedAtStart sectors with identical triangles (P8 scripts hid one), and the copies flickered.
    LevelObject sectors are only deduped within themselves (their models are in local space). A sector left
    with no triangles is dropped (its node goes too). Returns the new sector list."""
    M = {m['checksum']: m for m in mats}
    world_seen = {}
    out = []
    for s in sectors:
        seen = {} if s['checksum'] in objects else world_seen
        keep_meshes = []
        for me in s['meshes']:
            V = me['verts']
            tris = strip_tris(me['idx'])
            kept = []
            for a, b, c in tris:
                ps = [tuple(round(x, 2) for x in V[k][0]) for k in (a, b, c)]
                key = (me['mat'], tuple(sorted(ps)))
                i = ps.index(min(ps))
                rot = (ps[i], ps[(i + 1) % 3], ps[(i + 2) % 3])     # winding-aware form
                prev = seen.setdefault(key, set())
                if rot not in prev:          # same-direction repeats go; a back-to-back face is kept
                    prev.add(rot)
                    kept.append((a, b, c))
            if len(kept) != len(tris):
                if not kept:
                    continue
                me['idx'] = list_to_strip([k for t in kept for k in t])
            keep_meshes.append(me)
        if keep_meshes:
            s['meshes'] = keep_meshes
            out.append(s)
    return out


class SceneGeo:
    """All of a scene's triangles with a 3D grid, for 'is there a surface right behind this one' tests."""

    def __init__(self, sectors):
        import numpy as np
        from collections import defaultdict
        tris, tmat, src = [], [], []
        for s in sectors:
            for me in s['meshes']:
                V = me['verts']
                for tri in strip_tris(me['idx']):          # proper winding (odd strip triangles flipped)
                    a, b, c = tri
                    tris.append((V[a][0], V[b][0], V[c][0]))
                    tmat.append(me['mat'])
                    src.append((me, tri))
        self.src = src
        self.np = np
        self.T = np.array(tris, dtype=np.float64).reshape(-1, 3, 3)
        self.TM = np.array(tmat, dtype=np.uint32)
        T = self.T
        n = np.cross(T[:, 1] - T[:, 0], T[:, 2] - T[:, 0])
        ln = np.linalg.norm(n, axis=1)
        self.area = ln / 2
        self.n = n / np.maximum(ln, 1e-12)[:, None]
        self.ok = ln > 1e-6
        self.grid, self.cell = {}, 1.0
        if not len(T):
            return
        ext = float(max(np.ptp(T[:, :, k]) for k in range(3)))
        self.cell = cell = max(32.0, ext / 128.0)
        lo = np.floor(T.min(1) / cell).astype(int)
        hi = np.floor(T.max(1) / cell).astype(int)
        grid = defaultdict(list)
        for i in np.nonzero(self.ok)[0]:
            (x0, y0, z0), (x1, y1, z1) = lo[i], hi[i]
            if (x1 - x0 + 1) * (y1 - y0 + 1) * (z1 - z0 + 1) > 20000:
                continue                      # sky-dome sized triangle: never a backing surface
            for x in range(x0, x1 + 1):
                for y in range(y0, y1 + 1):
                    for z in range(z0, z1 + 1):
                        grid[(x, y, z)].append(i)
        self.grid = {k: np.array(v) for k, v in grid.items()}

    def backed(self, i, mask, reach=4.0):
        """True if a triangle allowed by mask (bool per triangle) lies within reach along triangle i's normal."""
        np = self.np
        c = self.T[i].mean(0)
        d = self.n[i]
        ids = set()
        for p in (c - reach * d, c, c + reach * d):
            g = self.grid.get(tuple(np.floor(p / self.cell).astype(int).tolist()))
            if g is not None:
                ids.update(g.tolist())
        ids = [j for j in ids if mask[j]]
        if not ids:
            return False
        ids = np.array(ids)
        o = c - reach * d
        D = 2 * reach * d
        a = self.T[ids, 0]
        e1 = self.T[ids, 1] - a
        e2 = self.T[ids, 2] - a
        h = np.cross(np.broadcast_to(D, e2.shape), e2)
        det = (e1 * h).sum(1)
        good = np.abs(det) > 1e-9
        f = np.where(good, 1.0 / np.where(good, det, 1.0), 0.0)
        sv = o - a
        u = f * (sv * h).sum(1)
        q = np.cross(sv, e1)
        v = f * (q * D).sum(1)
        t = f * (e2 * q).sum(1)
        return bool(np.any(good & (u >= 0) & (v >= 0) & (u + v <= 1) & (t >= 0) & (t <= 1)))

    def backed_fraction(self, mat, mask, sel=None):
        np = self.np
        mine = (self.TM == mat) & self.ok
        if sel is not None:
            mine &= sel
        ids = np.nonzero(mine)[0]
        tot = self.area[ids].sum()
        if not tot:
            return 0.0
        return sum(self.area[i] for i in ids if self.backed(i, mask)) / tot


def fix_materials(mats, sectors):
    """P8 -> THUG2 material fixes that need the scene geometry.

    1 Clamp UVs for a pass P8 marks with 1 at +0xA0 (sky panels, decals) when every mesh's UVs for it lie in
      0..1, so filtering doesn't wrap the opposite edge in (the sky seam stripes); otherwise keep wrap.
    2 Env-mapped passes (0x8, a sky reflection map) next to other passes are dropped - drawn as a plain layer
      they covered roads/curbs in glowing blue. If the material sits on another opaque surface (a decal), its
      next pass blends over that surface; if nothing is behind it (shop windows ARE the wall there) that pass
      is made solid - left blended, the windows were see-through into hollow buildings ("missing floors").
    3 Ground surfaces whose pass 0 is blended but that have nothing under them (Suburbs road = grime + asphalt
      layers) get an opaque pass 0 and no alpha test; otherwise the sky shows through them.
    4 Coplanar overlapping surfaces with the same zbias z-fight (Downtown window glass vs its window overlay
      flashed every frame); the one drawn on top (blended over opaque, else the smaller one) gets zbias + 1."""
    import numpy as np
    uses = {}
    for s in sectors:
        for me in s['meshes']:
            uses.setdefault(me['mat'], []).append(me)
    M = {m['checksum']: m for m in mats}
    for m in mats:                                                      # 1
        for j, p in enumerate(m['p']):
            ok = p['clamp'] == 1
            for me in uses.get(m['checksum'], []) if ok else ():
                if j >= me['nuv']:
                    continue
                for v in me['verts']:
                    u_, v_ = v[3][j]
                    if not (-0.01 <= u_ <= 1.01 and -0.01 <= v_ <= 1.01):
                        ok = False
                        break
                if not ok:
                    break
            p['addr'] = 1 if ok else 0
    geo = SceneGeo(sectors)
    if not len(geo.T):
        return
    used = set(int(x) for x in geo.TM)
    opaque = np.array([M[int(x)]['p'][0]['blend'] == 0 for x in geo.TM])
    keep_of = {}
    for m in mats:                                                      # 2
        keep = [j for j, p in enumerate(m['p']) if not (p['flags'] & 0x8)]
        if not keep or len(keep) == len(m['p']) or m['checksum'] not in used:
            continue
        on_surface = geo.backed_fraction(m['checksum'], opaque & (geo.TM != m['checksum'])) >= 0.5
        keep_of[m['checksum']] = keep
        m['p'] = [m['p'][j] for j in keep]
        m['passes'] = len(m['p'])
        if on_surface:
            if m['p'][0]['blend'] != 0:
                m['p'][0]['flags'] |= 0x40   # decal: first pass now blends over the surface behind it
        else:
            m['p'][0]['blend'] = 0           # the material is the surface itself (shop windows in a hollow
            m['p'][0]['flags'] &= ~0x40      # building): solid, or you see through into nothing
            m['alpha_cutoff'] = 0
    for s in sectors:
        for me in s['meshes']:
            keep = keep_of.get(me['mat'])
            if keep and me['nuv']:
                me['verts'] = [(pos, nrm, col, [uvs[k] for k in keep if k < len(uvs)])
                               for pos, nrm, col, uvs in me['verts']]
                me['nuv'] = len(me['verts'][0][3]) if me['verts'] else 0
    ground = np.abs(geo.n[:, 1]) > 0.7
    for m in mats:                                                      # 3
        p0 = m['p'][0]
        if p0['blend'] != 5 or m['zbias'] or m['alpha_cutoff'] > 1 or m['checksum'] not in used:
            continue
        mine = geo.TM == m['checksum']
        tot = geo.area[mine].sum()
        if not tot or geo.area[mine & ground].sum() < 0.5 * tot:
            continue
        if geo.backed_fraction(m['checksum'], opaque & (geo.TM != m['checksum']), ground) < 0.3:
            p0['blend'] = 0
            p0['flags'] &= ~0x40
            m['alpha_cutoff'] = 0      # its alpha is a layer mask, not holes: no alpha test
    if split_back_to_back(mats, sectors, geo):                         # 3b
        geo = SceneGeo(sectors)
        opaque = np.array([{m['checksum']: m for m in mats}[int(x)]['p'][0]['blend'] == 0 for x in geo.TM])
    pairs = fix_zfighting(mats, geo)                                    # 4
    offset_decals(mats, sectors, geo, opaque, layer_ranks(mats, pairs))  # 5
    for _ in range(3):      # moved layers can land on another layer: re-check, raise zbias, move the difference
        geo2 = SceneGeo(sectors)
        before = {m['checksum']: m['zbias'] for m in mats}
        new = fix_zfighting(mats, geo2)
        if all(before[m['checksum']] == m['zbias'] for m in mats) and new <= pairs:
            break
        pairs |= new
        offset_decals(mats, sectors, geo, opaque, layer_ranks(mats, pairs))
    split_back_to_back(mats, sectors, SceneGeo(sectors))   # back-to-back sheets that only meet after the moves


def split_back_to_back(mats, sectors, geo):
    """A two-sided material that also has back-to-back faces (front + back sheet in one plane, often triangulated
    differently, so dedupe can't pair them) draws both from either side and they z-fight. Move those triangles
    into a single-sided copy of the material (checksum + 1 until free), so back-face culling shows exactly one
    of the pair; the rest of the material (single sheets: leaves, fences) stays two-sided."""
    np = geo.np
    from collections import defaultdict
    M = {m['checksum']: m for m in mats}
    n, T = geo.n, geo.T
    sg = np.where(np.abs(n[:, 0]) > 1e-6, np.sign(n[:, 0]),
                  np.where(np.abs(n[:, 1]) > 1e-6, np.sign(n[:, 1]), np.where(n[:, 2] < 0, -1.0, 1.0)))
    nc = n * sg[:, None]
    dc = (nc * T[:, 0]).sum(1)
    planes = defaultdict(list)
    for i in np.nonzero(geo.ok)[0]:
        if not M[int(geo.TM[i])]['two_sided']:
            continue
        nb = tuple(np.round(nc[i] * 50).astype(int).tolist())
        db = int(np.floor(dc[i]))               # within ~1 unit (same bins as validate_p8)
        planes[(nb, db)].append(i)
        planes[(nb, db + 1)].append(i)
    lo, hi = T.min(1), T.max(1)
    flagged = set()
    for ids in planes.values():
        if len(ids) < 2:
            continue
        ids = np.array(ids)
        for i in ids:
            j = ids[(geo.TM[ids] == geo.TM[i]) & ((n[ids] @ n[i]) < -0.9)]
            if len(j) and np.any(np.all((lo[j] < hi[i] - 0.1) & (hi[j] > lo[i] + 0.1), axis=1)):
                flagged.add(int(i))
    # exact back-to-back copies (same corners, opposite winding), across sectors too - as validate_p8 checks
    byk = defaultdict(list)
    for i in np.nonzero(geo.ok)[0]:
        k = int(geo.TM[i])
        if not M[k]['two_sided']:
            continue
        rp = [tuple(round(float(x), 2) for x in p) for p in T[i]]
        r0 = rp.index(min(rp))
        byk[(k, tuple(sorted(rp)))].append((int(i), (rp[r0], rp[(r0 + 1) % 3], rp[(r0 + 2) % 3])))
    for lst in byk.values():
        if len(set(r for _, r in lst)) > 1:
            flagged.update(i for i, _ in lst)
    if not flagged:
        return False
    used = set(M)
    clone = {}
    by_mesh = defaultdict(set)
    for i in flagged:
        me, tri = geo.src[i]
        by_mesh[id(me)].add(tri)
    for s in sectors:
        extra = []
        for me in s['meshes']:
            move = by_mesh.get(id(me))
            if not move:
                continue
            k = me['mat']
            if k not in clone:
                c = (k + 1) & 0xFFFFFFFF
                while c in used:
                    c = (c + 1) & 0xFFFFFFFF
                used.add(c)
                m2 = dict(M[k])
                m2['p'] = [dict(p) for p in M[k]['p']]
                m2['checksum'] = c
                m2['two_sided'] = 0
                mats.append(m2)
                M[c] = m2
                clone[k] = c
            tris = strip_tris(me['idx'])
            keep = [t for t in tris if t not in move]
            gone = [t for t in tris if t in move]
            me2 = dict(me)
            me2['mat'] = clone[k]
            me2['idx'] = list_to_strip([x for t in gone for x in t])
            me2.pop('zoff', None)
            if keep:
                me['idx'] = list_to_strip([x for t in keep for x in t])
                extra.append(me2)
            else:
                me['mat'] = clone[k]          # the whole mesh is back-to-back sheets
        s['meshes'] += extra
    return True


def layer_ranks(mats, pairs):
    """Position of each zbias > 0 material in its stack of overlapping layers: 0 = directly on the surface,
    1 = on top of a rank-0 layer, ... (longest chain of overlapping lower-zbias layers)."""
    M = {m['checksum']: m for m in mats}
    nb = {}
    for a, b in pairs:
        nb.setdefault(a, set()).add(b)
        nb.setdefault(b, set()).add(a)
    rank = {}
    for m in sorted(mats, key=lambda m: m['zbias']):
        zb = m['zbias']
        if zb <= 0:
            continue
        below = [rank[o] for o in nb.get(m['checksum'], ()) if o in rank and M[o]['zbias'] < zb]
        rank[m['checksum']] = 1 + max(below) if below else 0
    return rank


def offset_decals(mats, sectors, geo, opaque, rank):
    """Bake zbias into the geometry. THUG Pro never sets a D3D depth bias (no DEPTHBIAS / SLOPESCALEDEPTHBIAS
    render state anywhere in the exe, viewport depth always 0..1), so decals lying exactly on a surface
    (Crete Park graffiti on its wall at distance 0.00, shadow decals on the pads, the awning layers) z-fight
    with it as the camera moves. Push every mesh with zbias > 0 off the opaque surface behind it, along its
    own normal, by 0.3 + 0.4 * (its rank in the stack of overlapping layers) units (max 3): 0.4 between
    stacked layers beats the 24-bit depth precision at normal distances (zbias steps of 0.06 did not - the
    Crete Park graffiti layers zbias 7/8 sat 0.06 apart and still fought), and the stacking order is kept."""
    np = geo.np
    M = {m['checksum']: m for m in mats}
    for s in sectors:
        for me in s['meshes']:
            zb = M[me['mat']]['zbias']
            if zb <= 0 or not me['verts']:
                continue
            r_ = rank.get(me['mat'], 0)
            if M[me['mat']]['p'][0]['blend'] != 0:
                # blended decals (shadows, grime, graffiti): 1 unit + 0.5 per layer, so they stay in front of
                # their surface even far away (24-bit depth steps reach ~0.3-0.5 units at 3000 units)
                off = min(4.0, 1.0 + 0.5 * r_)
            else:
                off = min(3.0, 0.3 + 0.4 * r_)      # opaque zbias pieces (trim): small lift keeps edges aligned
            if 'zoff' in me:                     # already moved: only move the difference along the same normals
                d_off = off - me['zoff'][0]
                if abs(d_off) > 1e-6:
                    V = np.array([v[0] for v in me['verts']], dtype=np.float64) + d_off * me['zoff'][1]
                    me['verts'] = [(tuple(V[k]), nrm, col, uvs) for k, (pos, nrm, col, uvs) in enumerate(me['verts'])]
                    me['zoff'] = (off, me['zoff'][1])
                continue
            V = np.array([v[0] for v in me['verts']], dtype=np.float64)
            acc = np.zeros_like(V)
            fn_sum = np.zeros(3)
            for a, b, c in strip_tris(me['idx']):
                n = np.cross(V[b] - V[a], V[c] - V[a])
                acc[[a, b, c]] += n
                fn_sum += n
            ln = np.linalg.norm(acc, axis=1)
            ok = ln > 1e-9
            if not ok.any():
                continue
            vn = np.zeros_like(V)
            vn[ok] = acc[ok] / ln[ok, None]
            # which side is the surface on? cast from the mesh's triangle centres along -n and +n
            behind = front = 0
            mine = np.nonzero(geo.TM == me['mat'])[0]
            ctr = V.mean(0)
            mask = opaque & (geo.TM != me['mat'])
            for i in mine[:64]:
                if np.abs(geo.T[i].mean(0) - ctr).max() > np.ptp(V, axis=0).max() + 1:
                    continue      # another mesh of the same material
                c = geo.T[i].mean(0)
                d = geo.n[i]
                if (d @ (fn_sum / (np.linalg.norm(fn_sum) + 1e-12))) < 0:
                    d = -d        # use the mesh's overall facing
                behind += _hit_side(geo, c, -d, mask)      # surface behind the decal (normal case)
                front += _hit_side(geo, c, d, mask)        # surface in front: push the other way
            sign = -1.0 if front > behind else 1.0
            V2 = V + sign * off * vn
            me['verts'] = [(tuple(V2[k]), nrm, col, uvs) for k, (pos, nrm, col, uvs) in enumerate(me['verts'])]
            me['zoff'] = (off, sign * vn)


def _hit_side(geo, c, d, mask, reach=4.0):
    """True if an allowed triangle crosses the segment c .. c + reach*d"""
    np = geo.np
    ids = set()
    for p in (c, c + 0.5 * reach * d, c + reach * d):
        g = geo.grid.get(tuple(np.floor(p / geo.cell).astype(int).tolist()))
        if g is not None:
            ids.update(g.tolist())
    ids = [j for j in ids if mask[j]]
    if not ids:
        return False
    ids = np.array(ids)
    D = reach * d
    a = geo.T[ids, 0]
    e1 = geo.T[ids, 1] - a
    e2 = geo.T[ids, 2] - a
    h = np.cross(np.broadcast_to(D, e2.shape), e2)
    det = (e1 * h).sum(1)
    good = np.abs(det) > 1e-9
    f = np.where(good, 1.0 / np.where(good, det, 1.0), 0.0)
    sv = c - a
    u = f * (sv * h).sum(1)
    q = np.cross(sv, e1)
    v = f * (q * D).sum(1)
    t = f * (e2 * q).sum(1)
    return bool(np.any(good & (u >= 0) & (v >= 0) & (u + v <= 1) & (t >= -1e-6) & (t <= 1)))


def fix_zfighting(mats, geo):
    np = geo.np
    from collections import defaultdict
    M = {m['checksum']: m for m in mats}
    n, T = geo.n, geo.T
    sg = np.where(np.abs(n[:, 0]) > 1e-6, np.sign(n[:, 0]),
                  np.where(np.abs(n[:, 1]) > 1e-6, np.sign(n[:, 1]), np.where(n[:, 2] < 0, -1.0, 1.0)))
    nc = n * sg[:, None]
    dc = (nc * T[:, 0]).sum(1)
    planes = defaultdict(list)
    for i in np.nonzero(geo.ok & (geo.area > 0.5))[0]:
        # surfaces within ~1 unit of each other z-fight at a distance; each triangle goes in its 1-unit depth bin
        # and the next one, so two surfaces closer than 1 unit always share a bin (no bin-edge misses)
        nb = tuple(np.round(nc[i] * 50).astype(int).tolist())
        db = int(np.floor(dc[i]))
        planes[(nb, db)].append(i)
        planes[(nb, db + 1)].append(i)
    lo, hi = T.min(1), T.max(1)
    pairs = set()
    for ids in planes.values():
        if len(ids) < 2 or len(set(geo.TM[ids].tolist())) < 2:
            continue
        ids = np.array(ids)
        for x in range(len(ids) - 1):
            i = ids[x]
            j = ids[x + 1:]
            j = j[geo.TM[j] != geo.TM[i]]
            if not len(j):
                continue
            ov = np.all((lo[j] < hi[i] - 0.5) & (hi[j] > lo[i] + 0.5), axis=1)
            for jj in j[ov]:
                pairs.add(tuple(sorted((int(geo.TM[i]), int(geo.TM[jj])))))
    tot = defaultdict(float)
    for k, a in zip(geo.TM.tolist(), geo.area.tolist()):
        tot[k] += a

    def top(a, b):
        ba, bb = M[a]['p'][0]['blend'] != 0, M[b]['p'][0]['blend'] != 0
        if ba != bb:
            return (a, b) if ba else (b, a)
        return (a, b) if tot[a] < tot[b] else (b, a)
    for _ in range(4):
        changed = False
        for a, b in sorted(pairs):
            t, u = top(a, b)
            if M[t]['zbias'] <= M[u]['zbias'] < 30:   # stacked layers; THUG Pro ignores zbias itself
                M[t]['zbias'] = M[u]['zbias'] + 1
                changed = True
        if not changed:
            break
    return pairs


def list_to_strip(idx):
    s = []
    for t in range(0, len(idx) - 2, 3):
        a, b_, c = idx[t:t + 3]
        if s:
            s += [s[-1], a]
            if len(s) % 2:
                s.append(a)
        s += [a, b_, c]
    return s


def write_thug_scene(path, mats, sectors, tex_ids):
    out = bytearray()
    w = lambda fmt, *a: out.extend(struct.pack(fmt, *a))
    w('<3I', 1, 1, 1)
    w('<I', len(mats))
    for mi, m in enumerate(mats):
        w('<3I', m['checksum'], m['name'], m['passes'])
        w('<I', m['alpha_cutoff'])
        # sorted + draw order as THUG Pro's own P8 conversions write them (z_center/hisch, matched against the P8
        # disc materials): sorted only where P8 says so (draw order 1500); every other blended material gets the
        # fixed draw order 1250 - drawn after the opaque world in a stable order. Marking all blended materials
        # sorted (our old rule) re-sorted them per frame and made signs/decals swap and flash; draw order 0
        # drew decals before the road (blue sky through their shapes).
        blended = m['p'][0]['blend'] != 0
        draw_order = 1500.0 if m['sorted'] else (1250.0 if blended else 0.0)
        if STOCK_PARITY:
            draw_order = m['draw_order']      # P8's own per-material draw order (+0x2C), as THUG Pro copies it
        elif draw_order:
            # stacked blended layers draw in a fixed order: lower zbias first, then a unique per-material tie-break
            draw_order += m['zbias'] + mi * 0.0001
        w('<?f??i', bool(m['sorted']), draw_order, bool(m['single_sided']) if STOCK_PARITY else False,
          bool(m['two_sided']),
          m['zbias'])   # P8 zbias = THUG2 range (0..10)
        w('<?', False)            # grassify
        w('<f', 0.0)              # specular power
        for j, p in enumerate(m['p']):
            tex = p['tex'] if p['tex'] in tex_ids else 0
            flags = p['flags'] & ~DROP_PASS_FLAGS
            vcw = m.get('vcw') if j == 0 else None    # the exe reads colour sequences on pass 0 only
            if vcw:
                flags |= 0x2
            anim = p.get('anim')
            if anim and tex and all(t in tex_ids for _, t in anim):
                flags |= 0x800    # texture flipbook: every frame's texture must be in the level (exe looks them up)
            else:
                anim = None
            if STOCK_PARITY and p['flags'] & 0x1 and p.get('uvwibble'):
                flags |= 0x1      # UV wibble: P8's 8 floats are written below (as THUG Pro's z_center has them)
            if not tex:
                flags &= ~0x4     # not textured
            w('<II', tex, flags)
            w('<?3f', True, *p['color'])
            w('<II', p['blend'] if p['blend'] <= 15 else 0, p['fixed'])
            if STOCK_PARITY:
                w('<II', p['addr_u'], p['addr_v'])   # P8 +0xA0: u clamp in the low 16 bits, v in the high 16
            else:
                w('<II', p['addr'], p['addr'])       # u/v addressing: 0 wrap, 1 clamp
            w('<2f', *p['env'])
            w('<I', 65540)        # 0x10004 on every pass, as in stock THUG2 / THUG Pro levels (we wrote 0 on pass 0)
            if flags & 0x1:
                w('<8f', *p['uvwibble'])
            if flags & 0x2:
                w('<I', len(vcw))
                for phase, keys in vcw:
                    w('<II', len(keys), phase)
                    for t, c in keys:
                        w('<II', t, c)
            if flags & 0x800:     # nkeys, period (unused by the exe), iterations 0 = loop forever, phase 0
                w('<4I', len(anim), anim[-1][0] - anim[0][0], 0, 0)
                for t, tx in anim:
                    w('<II', t, tx)
            w('<II', p['mmag'] or 1, p['mmin'] or 4)
            # mip LOD bias as THUG Pro's P8 conversions write it: -9 on the first pass of a multi-pass material
            lb = -9.0 if (STOCK_PARITY and j == 0 and len(m['p']) > 1) else -8.0
            w('<ff', lb, lb)
    MV = {m['checksum']: m.get('vcw') for m in mats}   # colour sequences written per material (pass 0)
    w('<I', len(sectors))
    for s in sectors:
        has_n = all(v[1] is not None for m in s['meshes'] for v in m['verts'])
        # P8's own sector flags (0x80002047 etc. - THUG Pro's P8 levels keep them as-is); the low bits follow
        # the vertex layout we write: 0x1 UVs and 0x2 colours always, 0x4 normals when present
        flags = (s['flags'] & ~0x7 & ~0x800000) | 0x1 | 0x2 | (0x4 if has_n else 0)
        # (0x800000 = billboard sector: the exe then reads 10 more dwords, which we don't write)
        # sector box/sphere from the vertices we write (decals are moved off their surfaces, dedupe drops some)
        allp = [v[0] for m in s['meshes'] for v in m['verts']]
        bmin = [min(p[k] for p in allp) for k in range(3)] if allp else list(s['bmin'])
        bmax = [max(p[k] for p in allp) for k in range(3)] if allp else list(s['bmax'])
        cx = [(bmin[k] + bmax[k]) / 2 for k in range(3)]
        r = math.sqrt(sum((bmax[k] - cx[k]) ** 2 for k in range(3)))
        w('<IiII', s['checksum'], -1, flags, len(s['meshes']))
        w('<6f', *bmin, *bmax)
        w('<4f', *cx, r)
        for m in s['meshes']:
            ps = [v[0] for v in m['verts']]
            mn = [min(p[k] for p in ps) for k in range(3)]
            mx = [max(p[k] for p in ps) for k in range(3)]
            ctr = [(mn[k] + mx[k]) / 2 for k in range(3)]     # culling sphere from the vertices we write
            rad = max(math.sqrt(sum((p[k] - ctr[k]) ** 2 for k in range(3))) for p in ps) + 0.01
            w('<4f', *ctr, rad)
            w('<6f', *mn, *mx)
            w('<II', 0, m['mat'])
            w('<I', 1)
            w('<I', len(m['idx']))
            w('<%dH' % len(m['idx']), *m['idx'])
            w('<H', len(m['idx']))
            w('<%dH' % len(m['idx']), *m['idx'])
            out.extend(b'\0' * 14)
            nuv = max(1, m['nuv'])
            stride = 12 + (12 if has_n else 0) + 4 + 8 * nuv
            w('<BHH', stride, len(m['verts']), 1)
            w('<I', stride * len(m['verts']))
            for pos, nrm, col, uvs in m['verts']:
                w('<3f', *pos)
                if has_n:
                    w('<3f', *nrm)
                out.extend(col)
                for u in range(nuv):
                    w('<2f', *(uvs[u] if u < len(uvs) else (uvs[0] if uvs else (0.0, 0.0))))
            fvf = 0x2 | (0x10 if has_n else 0) | 0x40 | (0x100 * nuv)
            w('<ii', fvf, 0)
            # 4th byte: per-vertex colour sequence bytes follow (exe 0x4D5CC0 -> mesh +0x8C, used by 0x4D4CA0)
            nseq = len(MV[m['mat']]) if MV.get(m['mat']) else 0
            vw = m.get('vcw') if nseq and m.get('vcw') and len(m['vcw']) == len(m['verts']) else None
            w('<BBBB', 12 if has_n else 0, 24 if has_n else 12, 28 if has_n else 16, 1 if vw else 0)
            if vw:
                out.extend(bytes(x if x <= nseq else 0 for x in vw))
            w('<I', 1)
            w('<III', 1, 0, 0)
    w('<i', 0)
    open(path, 'wb').write(out)


# ------------------------------------------------------------------ collision
# 0x40 = trigger: the engine looks up the object's node and reads its TriggerScript without a NULL check
# (0x434A60 -> 0x476950 with ECX=0, crash reading 0x4). We carry no P8 scripts, so no face may trigger.
COL_DROP_FLAGS = 0x40


def open_interior_walls(objs, side=150.0):
    """P8 is one streamed world: its zones carry invisible collision walls (face flag 0x1000, no render geometry)
    at zone edges and around story areas. Standing alone, some of them cut through playable space - Noah hit
    one in Crete Park between the floor tiles and a ledge. A wall face is a real boundary when there is ground
    on one side only; when there is solid, visible ground (an up-facing face without 0x1000/0x10) under both
    sides within `side` units, it only blocks the skater, so it is made non-collidable (0x10).
    Returns the number of faces changed."""
    import numpy as np
    from collections import defaultdict
    gt = []
    for o in objs:
        V = o['verts']
        for fl, tt, vi in o['faces']:
            if fl & 0x1010:
                continue
            a, b, c = (np.array(V[k], dtype=np.float64) for k in vi)
            n = np.cross(b - a, c - a)
            ln = np.linalg.norm(n)
            if ln > 1e-6 and abs(n[1]) / ln > 0.6:
                gt.append((a, b, c))
    if not gt:
        return 0
    G = np.array(gt)
    cell = 256.0
    grid = defaultdict(list)
    lo = np.floor(G[:, :, [0, 2]].min(1) / cell).astype(int)
    hi = np.floor(G[:, :, [0, 2]].max(1) / cell).astype(int)
    for i in range(len(G)):
        for x in range(lo[i, 0], hi[i, 0] + 1):
            for z in range(lo[i, 1], hi[i, 1] + 1):
                grid[(x, z)].append(i)
    grid = {k: np.array(v) for k, v in grid.items()}

    def ground(p, ylo, yhi):
        """is there ground at (p.x, p.z) between heights ylo and yhi?"""
        ids = grid.get((int(np.floor(p[0] / cell)), int(np.floor(p[2] / cell))))
        if ids is None:
            return False
        A, Bv, C = G[ids, 0], G[ids, 1], G[ids, 2]
        v0, v1, v2 = C - A, Bv - A, p - A
        d00 = v0[:, 0] ** 2 + v0[:, 2] ** 2
        d01 = v0[:, 0] * v1[:, 0] + v0[:, 2] * v1[:, 2]
        d11 = v1[:, 0] ** 2 + v1[:, 2] ** 2
        d20 = v2[:, 0] * v0[:, 0] + v2[:, 2] * v0[:, 2]
        d21 = v2[:, 0] * v1[:, 0] + v2[:, 2] * v1[:, 2]
        den = d00 * d11 - d01 * d01
        den[np.abs(den) < 1e-9] = 1e-9
        u = (d11 * d20 - d01 * d21) / den
        w = (d00 * d21 - d01 * d20) / den
        y = A[:, 1] + u * v0[:, 1] + w * v1[:, 1]
        return bool(np.any((u >= 0) & (w >= 0) & (u + w <= 1) & (y <= yhi) & (y >= ylo)))

    changed = 0
    for o in objs:
        V = o['verts']
        faces = o['faces']
        for k, (fl, tt, vi) in enumerate(faces):
            if not fl & 0x1000 or fl & 0x10:
                continue
            a, b, c = (np.array(V[q], dtype=np.float64) for q in vi)
            n = np.cross(b - a, c - a)
            ln = np.linalg.norm(n)
            if ln < 1e-6 or abs(n[1]) / ln > 0.3:
                continue                       # only (near-)vertical walls
            n /= ln
            hor = np.array([n[0], 0.0, n[2]])
            hor /= max(np.linalg.norm(hor), 1e-9)
            ymin = min(a[1], b[1], c[1])
            ymax = max(a[1], b[1], c[1])
            # both sides of the wall need ground within the wall's own height range (skater could stand there)
            pts = [(a + b + c) / 3, (a + b) / 2, (b + c) / 2, (a + c) / 2]
            both = 0
            for p in pts:
                if ground(p + hor * side, ymin - 50.0, ymax - 60.0) and ground(p - hor * side, ymin - 50.0, ymax - 60.0):
                    both += 1
            if both >= 3:
                faces[k] = (fl | 0x10, tt, vi)
                changed += 1
    return changed


def read_p8_col(b, hdr=0x50, keep_trigger=frozenset()):
    """keep_trigger: collision objects (node names) whose node gets a converted TriggerScript keep the trigger
    flag 0x40; on every other object it is cleared (the engine reads a missing TriggerScript -> crash)"""
    ver, nobj, tv, nlf, nsf, nlv, nsv, _ = struct.unpack_from('<8I', b, 0)
    vbase = (hdr + 0x40 * nobj + 15) & ~15
    ibase = vbase + nlv * 12 + nsv * 6
    fbase = (ibase + tv + 3) & ~3
    objs = []
    for i in range(nobj):
        o = hdr + i * 0x40
        cs, fl, nv, nf, sf, fx, ff = struct.unpack_from('<IHHHBBI', b, o)
        mn = struct.unpack_from('<3f', b, o + 0x10)
        vo, bo, io = struct.unpack_from('<III', b, o + 0x30)
        p = vbase + vo
        if fx:
            verts = [tuple(mn[k] + v[k] * 0.0625 for k in range(3)) for v in struct.iter_unpack('<3H', b[p:p + 6 * nv])]
        else:
            verts = list(struct.iter_unpack('<3f', b[p:p + 12 * nv]))
        inten = b[ibase + io:ibase + io + nv]
        faces = []
        p = fbase + ff
        for j in range(nf):
            fflags, tt = struct.unpack_from('<HH', b, p)
            if sf:
                vi = tuple(b[p + 4:p + 7])
                p += 8
            else:
                vi = struct.unpack_from('<3H', b, p + 4)
                p += 10
            faces.append((fflags if cs in keep_trigger else fflags & ~COL_DROP_FLAGS, tt, vi))
        objs.append(dict(checksum=cs, flags=fl, verts=verts, inten=inten, faces=faces))
    return objs


def verbatim_col(b, keep_trigger=frozenset(), hdr=0x50):
    """THUG2 collision file = P8's with the 0x50 byte header cut to 0x20 (all section offsets are relative);
    face flag 0x40 (trigger) is cleared on objects not in keep_trigger"""
    import colparse
    s = colparse.sections(b, hdr)
    out = bytearray(b[:0x20] + b[hdr:])
    ver, nobj, tv, nf, nlf, nlv, nsv, _ = s['header']
    vbase = (hdr + 0x40 * nobj + 15) & ~15
    fbase = (vbase + nlv * 12 + nsv * 6 + tv + 3) & ~3
    for o in s['objs']:
        if o['cs'] in keep_trigger:
            continue
        p = fbase + o['ff']
        for j in range(o['nf']):
            fl = struct.unpack_from('<H', b, p)[0]
            if fl & COL_DROP_FLAGS:
                struct.pack_into('<H', out, p - (hdr - 0x20), fl & ~COL_DROP_FLAGS)
            p += 8 if o['small'] else 10
    return bytes(out)


def bsp(verts, faces, ids, depth=0):
    """returns ('leaf', [face ids]) or ('node', axis, point, left, right)"""
    if len(ids) <= 40 or depth > 30:
        return ('leaf', ids)
    best = None
    for axis in range(3):
        cs = sorted(sum(verts[v][axis] for v in faces[i][2]) / 3.0 for i in ids)
        point = math.floor(cs[len(cs) // 2] * 16.0) / 16.0
        left, right = [], []
        for i in ids:
            vals = [verts[v][axis] for v in faces[i][2]]
            if min(vals) < point:
                left.append(i)
            if max(vals) >= point:
                right.append(i)
        dup = len(left) + len(right) - len(ids)
        if left and right and len(left) < len(ids) and len(right) < len(ids):
            if best is None or dup < best[0]:
                best = (dup, axis, point, left, right)
    if best is None or best[0] >= len(ids) // 2:
        return ('leaf', ids)
    _, axis, point, left, right = best
    return ('node', axis, point, bsp(verts, faces, left, depth + 1), bsp(verts, faces, right, depth + 1))


def write_thug_col(path, objs):
    total_v = sum(len(o['verts']) for o in objs)
    total_f = sum(len(o['faces']) for o in objs)
    hdr = struct.pack('<8I', 10, len(objs), total_v, total_f, 0, total_v, 0, 0)
    objtab = bytearray()
    verts = bytearray()
    inten = bytearray()
    faces = bytearray()
    nodes = bytearray()
    node_faces = []
    fo = vo = bo = io = 0
    for o in objs:
        vs = o['verts']
        if not vs:
            mn = mx = (0.0, 0.0, 0.0)
        else:
            mn = tuple(min(v[k] for v in vs) for k in range(3))
            mx = tuple(max(v[k] for v in vs) for k in range(3))
        tree = bsp(vs, o['faces'], list(range(len(o['faces']))))
        # breadth first, children adjacent (left, right)
        flat = [tree]
        index = {id(tree): 0}
        q = [tree]
        while q:
            t = q.pop(0)
            if t[0] == 'node':
                for ch in (t[3], t[4]):
                    index[id(ch)] = len(flat)
                    flat.append(ch)
                    q.append(ch)
        objtab += struct.pack('<IHHHBBI', o['checksum'], o['flags'], len(vs), len(o['faces']), 0, 0, fo)
        objtab += struct.pack('<4f4f', *mn, 1.0, *mx, 1.0)
        objtab += struct.pack('<IIII', vo, bo, io, 0)
        for t in flat:
            if t[0] == 'leaf':
                nodes += struct.pack('<BBHI', 3, 0, len(t[1]), len(node_faces))
                node_faces += t[1]
            else:
                nodes += struct.pack('<iI', (t[1] & 3) | (int(round(t[2] * 16.0)) << 2), bo + index[id(t[3])] * 8)
        bo += len(flat) * 8
        for v in vs:
            verts += struct.pack('<3f', *v)
        inten += bytes(o['inten']) if len(o['inten']) == len(vs) else b'\x80' * len(vs)
        for fl, tt, vi in o['faces']:
            faces += struct.pack('<HH3H', fl, tt, *vi)
        fo += 10 * len(o['faces'])
        vo += 12 * len(vs)
        io += len(vs)
    out = bytearray(hdr) + objtab
    out += b'\0' * (-len(out) % 16)
    out += verts + inten
    out += b'\0' * (-len(out) % 4)
    out += faces
    out += b'\0' * (-len(out) % 2)
    out += b'\0' * total_f
    out += b'\0' * (-len(out) % 4)
    out += struct.pack('<I', len(nodes)) + nodes
    out += struct.pack('<%dH' % len(node_faces), *node_faces)
    open(path, 'wb').write(out)


# ------------------------------------------------------------------ driver
T_SCN = 0x7EA7357B


def convert(pak_path, outdir, level):
    os.makedirs(outdir, exist_ok=True)
    files = read_pak(open(pak_path, 'rb').read())
    by = {}
    for f in files:
        by.setdefault(f['type'], []).append(f)
    # a zone pak also holds small model files of the same types; the level's own are the largest
    big = lambda t: max(by[t], key=lambda f: len(f['data']))['data']
    tex = big(crc('.tex'))
    scn = big(T_SCN)
    texs = read_p8_tex(tex)
    write_thug_tex(os.path.join(outdir, level + '.tex.xbx'), texs)
    qbs = [f for f in files if f['name'].lower().endswith('\\%s.qb.xbx' % os.path.basename(pak_path).split('.')[0].lower())]
    objects = set()
    cas = None              # sectors whose node is CreatedAtStart (None: no node array, e.g. skies)
    trick = set()           # sectors whose node is a TrickObject
    door_scripts, trigger_ok = {}, {}
    scripts_q, tcounts = '\n', {}
    if qbs:
        try:
            pnodes = nodes_from_qb(qbs[0]['data'])
            objects = {n.get(crc('Name')) for n in pnodes if n.get(crc('Class')) == crc('LevelObject')}
            cas = {n.get(crc('Name')) for n in pnodes if crc('CreatedAtStart') in n['_flags']}
            trick = {n.get(crc('Name')) for n in pnodes if crc('TrickObject') in n['_flags']}
            scripts_q, conv, tcounts = convert_triggers(
                qbs[0]['data'], [f['data'] for f in files if f['name'].lower().endswith('.qb.xbx')], pnodes)
            door_scripts = conv
            # nodes whose P8 TriggerScript we convert: their collision keeps the trigger flag
            trigger_ok = {n.get(crc('Name')): n[crc('TriggerScript')] for n in pnodes
                          if n.get(crc('TriggerScript')) in conv and n.get(crc('Class')) in KEEP_CLASSES}
        except Exception:
            objects = set()     # sky qbs have no node array
    mats, sectors = read_p8_scene(scn, objects, texs)
    # fix25's solid_cutouts is off again (2026-11-16 audit): THUG Pro's own z_center keeps those materials blended
    # + sorted exactly as P8 has them, and the tree-top jumping turned out to be the UV wibble offset (fix40)
    solid = solid_cutouts(mats, sectors) if os.environ.get('P8_SOLID_CUTOUTS') else []
    if solid:
        print('  cut-outs drawn solid with alpha test (foliage etc.): %d materials' % len(solid))
    culled = keep_culling(mats, sectors)
    if culled:
        print('  single-sided kept culled (back-to-back faces): %s' % ', '.join('%08x' % c for c in culled))
    cc = fix_coincident(mats, sectors, objects, cas, trick)
    # sunk decals and unstable coplanar overlaps feed each other (a lifted overlay can cover a decal, a lifted
    # decal can land on another layer): alternate the two until neither changes anything
    ns = cd = cl = 0
    for _ in range(5):
        n_ = lift_sunk_decals(mats, sectors, objects, cas)
        d_, l_ = resolve_coplanar(mats, sectors, objects, cas)
        ns, cd, cl = ns + n_, cd + d_, cl + l_
        if not (n_ or d_ or l_):
            break
    if ns:
        print('  sunk decals: %d blended faces lifted onto the surface they cover' % ns)
    if cd or cl:
        print('  coplanar overlaps without a stable winner: %d overlay faces dropped, %d lifted' % (cd, cl))
    if any(cc.values()):
        print('  coincident faces: %d back-to-back moved to culled clones, %d differing copies dropped, '
              '%d re-triangulated copies dropped, %d different-material overlaps (reported)'
              % (cc['a'], cc['b'], cc['d'], cc['c']))
    write_thug_scene(os.path.join(outdir, level + '.scn.xbx'), mats, sectors, {t.checksum for t in texs})
    objs = []
    if crc('.col') in by:
        # Stock parity (THUG Pro's own P8 levels: z_center, hisch, z_funpark): the P8 collision file verbatim, only
        # the header shrinks (0x50 -> 0x20). The one change is the trigger flag on faces whose node gets no
        # converted TriggerScript. Invisible walls (0x1000) stay as P8 has them; pieces P8 doesn't create at
        # start are switched off through their nodes (write_nodearray_q keeps every node a col object names).
        p8col = big(crc('.col'))
        objs = read_p8_col(p8col, keep_trigger=set(trigger_ok))
        open(os.path.join(outdir, level + '.col.xbx'), 'wb').write(verbatim_col(p8col, set(trigger_ok)))
    print('%s: %d textures, %d materials, %d sectors, %d meshes, %d collision objects' % (
        level, len(texs), len(mats), len(sectors), sum(len(s['meshes']) for s in sectors), len(objs)))
    boxes = {}
    for s in sectors:
        ps = [v[0] for me in s['meshes'] for v in me['verts']]
        if ps:
            boxes[s['checksum']] = ([min(p[k] for p in ps) for k in range(3)], [max(p[k] for p in ps) for k in range(3)])
    if door_scripts:
        print('  P8 triggers converted: %s; %d trigger nodes' % (dict(tcounts), len(trigger_ok)))
    return dict(files=files, sectors={s['checksum'] for s in sectors}, boxes=boxes,
                col={o['checksum']: len(o['faces']) for o in objs},
                colboxes={o['checksum']: ([min(v[k] for v in o['verts']) for k in range(3)],
                                          [max(v[k] for v in o['verts']) for k in range(3)]) for o in objs if o['verts']},
                qb=qbs[0]['data'] if qbs else None, door_scripts=door_scripts, trigger_ok=trigger_ok,
                scripts_q=scripts_q if door_scripts else '\n')


P8_DOOR_HANDLER = 0x8D18984A      # P8 spawnscriptlater target for swinging doors (params door, angle | close, time)


KILL_CALLS = ('SK3_KillSkater', 'SK3_KillSkater_Water', 'TeleportSkaterToNode')   # stock THUG2 scripts, same params


from collections import Counter as _Counter
DROPPED = _Counter()
DROPPED_INNER = _Counter()


def convert_triggers(main_qb, all_qbs, pnodes):
    """Convert the P8 TriggerScripts we can express in THUG2: gaps, kill / out-of-bounds resets and doors.

    P8 layout (decoded with p8script): a node's TriggerScript (in the zone qb) calls gap scripts from the
    zone's _scripts qb - each one line, StartGap {GapID flags} or EndGap {GapID score text} - plus career /
    story helpers that we drop; or it calls SK3_KillSkater / SK3_KillSkater_Water / TeleportSkaterToNode
    {nodename}; or it swings doors (p8_door_scripts). A trigger script is converted when every remaining line
    is one of those; scripts left with nothing (empty stubs, story only) are not, and their trigger faces stay
    cleared. Returns (scripts .q text, {trigger script: True}, counts)."""
    import p8script, p8qb
    from collections import Counter
    names = {crc(w): w for w in ('StartGap', 'EndGap', 'GapID', 'flags', 'score', 'text', 'nodename') + KILL_CALLS}
    flag_names = {crc(w): w for w in ('PURE_AIR', 'PURE_GROUND', 'PURE_RAIL', 'PURE_WALL', 'PURE_LIP', 'PURE_MANUAL',
                                      'REQUIRE_AIR', 'REQUIRE_GROUND', 'REQUIRE_RAIL', 'REQUIRE_WALL', 'REQUIRE_LIP',
                                      'REQUIRE_MANUAL', 'CANCEL_AIR', 'CANCEL_GROUND', 'CANCEL_RAIL', 'CANCEL_WALL',
                                      'CANCEL_LIP', 'CANCEL_MANUAL', 'CANCEL_WALLPLANT', 'REQUIRE_WALLPLANT')}
    scripts = {}
    for b in all_qbs:
        for k, c in p8script.scripts(b).items():
            if k not in scripts or len(c) > len(scripts[k]):
                scripts[k] = c
    node_names = {n.get(crc('Name')) for n in pnodes if n.get(crc('Class')) in KEEP_CLASSES}
    doors = p8_door_scripts(main_qb)

    def key(v):
        return v if isinstance(v, str) else ('#"0x%08x"' % v)

    def gap_line(code):
        """a P8 gap script -> one THUG2 line, else None"""
        ls = [l for l in p8script.calls(code) if l and l != [('op', 'endscript')]]
        if len(ls) != 1 or len(ls[0]) != 2 or ls[0][0][0] != 'name' or ls[0][1][0] != 'struct':
            return None
        fn = names.get(ls[0][0][1])
        st = ls[0][1][1]
        if fn not in ('StartGap', 'EndGap') or st is None:
            return None
        d = {k: v for k, v in st if k is not None}
        gid = d.get(crc('GapID'))
        if gid is None:
            return None
        if fn == 'StartGap':
            fl = d.get(crc('flags')) or []
            fl = fl if isinstance(fl, list) else [fl]
            ftxt = ' '.join(flag_names.get(int(f), '#"0x%08x"' % int(f)) for f in fl)
            return 'StartGap GapID = %s flags = [ %s ]' % (key(int(gid)), ftxt)
        score = d.get(crc('score'), 0)
        txt = d.get(crc('text'), '')
        if not isinstance(score, int) or not isinstance(txt, str):
            return None
        return 'EndGap GapID = %s score = %d text = %s' % (key(int(gid)), score, q_value(txt))

    gap_scripts = {}
    out_lines, triggers = [], {}
    counts = Counter()
    for w in ('ShatterAndDie', 'Create', 'Kill', 'name', 'area', 'variance', 'vel_x', 'vel_y', 'vel_z', 'spread',
              'PlaySound', 'SpawnSound', 'printf'):
        names[crc(w)] = w
    names[crc('kill')] = 'Kill'
    names[crc('create')] = 'Create'
    BLOCK_OPS = {'if', 'else', 'switch', 'begin', 'repeat', 'jump', 'endif', 'endswitch', 'return', 'break'}

    def args_of(l, params):
        """a call line's parameters -> (dict key checksum -> value, [flags]); <param> refs resolved from params
        (None when a ref has no value)"""
        d, fl = {}, []
        if len(l) == 2 and l[1][0] == 'struct':
            for k, v in (l[1][1] or []):
                (fl.append(v) if k is None else d.__setitem__(k, v))
            return d, fl
        i = 1
        while i < len(l):
            k = l[i]
            if k[0] == 'name' and i + 2 < len(l) and l[i + 1] == ('op', '='):
                v = l[i + 2]
                if v == ('op', '2d') and i + 3 < len(l) and l[i + 3][0] == 'name':
                    d[k[1]] = params.get(l[i + 3][1])
                    i += 4
                    continue
                d[k[1]] = v[1] if v[0] != 'op' else None
                i += 3
                continue
            if k[0] == 'name':
                fl.append(k[1])
            i += 1
        return d, fl

    def expand(code, params, depth, counts):
        """P8 script tokens -> our THUG2 lines: gaps, kills / teleports, glass shatter, piece create / kill, and
        the same followed through called P8 scripts (with their parameters). Scripts with conditions or loops
        (story / career logic) and anything else are left out."""
        out = []
        ls = p8script.calls(code)
        if any(tok[0] == 'op' and tok[1] in BLOCK_OPS for l in ls for tok in l):
            return out
        for l in ls:
            if not l or l == [('op', 'endscript')] or l == [('name', 0)] or l[0][0] != 'name':
                continue
            fn = l[0][1]
            nmf = names.get(fn)
            a, fl = args_of(l, params)
            if nmf in ('StartGap', 'EndGap'):
                gid = a.get(crc('GapID'))
                if gid is None:
                    continue
                if nmf == 'StartGap':
                    f = a.get(crc('flags')) or []
                    f = f if isinstance(f, list) else [f]
                    out.append('StartGap GapID = %s flags = [ %s ]' % (key(int(gid)), ' '.join(
                        flag_names.get(int(x), '#"0x%08x"' % int(x)) for x in f)))
                else:
                    score, txt = a.get(crc('score'), 0), a.get(crc('text'), '')
                    if isinstance(score, int) and isinstance(txt, str):
                        out.append('EndGap GapID = %s score = %d text = %s' % (key(int(gid)), score, q_value(txt)))
                counts['gap'] += 1
            elif nmf in KILL_CALLS:
                nn = a.get(crc('nodename'))
                if nn is not None and int(nn) in node_names:
                    out.append('%s nodename = #"0x%08x"' % (nmf, int(nn)))
                    counts['kill' if nmf != 'TeleportSkaterToNode' else 'teleport'] += 1
            elif nmf == 'ShatterAndDie':
                nn = a.get(crc('name'))
                if nn is not None and int(nn) in node_names:
                    extra = ''.join(' %s = %s' % (names[k], a[k]) for k in a
                                    if names.get(k) in ('area', 'variance', 'vel_x', 'vel_y', 'vel_z', 'spread')
                                    and isinstance(a[k], (int, float)))
                    out.append('if IsAlive name = #"0x%08x"' % int(nn))
                    out.append('    ShatterAndDie name = #"0x%08x"%s' % (int(nn), extra))
                    out.append('    PlaySound HitGlassPane2x vol = 90')
                    out.append('endif')
                    counts['glass'] += 1
            elif nmf in ('Create', 'Kill'):
                nn = a.get(crc('name'))
                if nn is not None and int(nn) in node_names:
                    out.append('%s name = #"0x%08x"' % (nmf.lower(), int(nn)))
                    counts['create/kill'] += 1
            elif fn in scripts and depth < 4:
                sub = expand(scripts[fn], a, depth + 1, counts)
                if sub:
                    out += sub
                else:
                    counts['dropped line'] += 1
            else:
                counts['dropped line'] += 1            # career goals, story flags, P8 sounds, printf...
                DROPPED[nmf or '#%08x' % fn] += 1
        return out
    for n in pnodes:
        t = n.get(crc('TriggerScript'))
        if t is None or n.get(crc('Class')) not in KEEP_CLASSES or t in triggers:
            continue
        if t in doors:
            triggers[t] = True
            counts['door'] += 1
            continue
        code = scripts.get(t)
        if not code:
            continue
        ok = True
        if p8script.calls(code) and p8script.calls(code)[0] and p8script.calls(code)[0][0][0] != 'name':
            ok = False
        body = expand(code, {}, 0, counts)
        if ok and body:
            out_lines += ['script #"0x%08x"' % t] + ['    ' + x for x in body] + ['endscript']
            triggers[t] = True
            counts['trigger script'] += 1
    for g, line in sorted(gap_scripts.items()):
        out_lines += ['script #"0x%08x"' % g, '    ' + line, 'endscript']
    counts['gap script'] = len(gap_scripts)
    text = door_scripts_q(doors) if doors else ''
    text += '\n'.join(out_lines) + '\n'
    return text, triggers, counts


def p8_door_scripts(qb_bytes):
    """P8 TriggerScripts that only swing doors (Car Factory glass doors etc.):
    {script checksum: [dict(door=, angle= | close=True, time=)]}. Each is a list of spawnscriptlater calls
    whose inline struct holds the handler flag and params { door angle sound } / { door close time }."""
    import p8script, p8qb
    out = {}
    for name, code in p8script.scripts(qb_bytes).items():
        calls = []
        ok = True
        k = 0
        while True:
            i = code.find(b'\x4a', k)
            if i < 0:
                break
            st = code.find(b'\x00\x00\x01\x00', i + 3)
            if st < 0 or st > i + 12:
                k = i + 1
                continue
            try:
                items = p8qb.read_struct(code[st:], 0)
            except Exception:
                ok = False
                break
            flags = [v for kk, v in items if kk is None]
            params = dict((kk, v) for kk, v in items if kk is not None)
            pr = params.get(crc('params'))
            if P8_DOOR_HANDLER not in flags or not isinstance(pr, list):
                ok = False
                break
            d = {kk: v for kk, v in pr if kk is not None}
            f = [v for kk, v in pr if kk is None]
            door = d.get(crc('door'))
            if door is None:
                ok = False
                break
            call = dict(door=int(door), time=float(d.get(crc('time'), 0.3)))
            if crc('close') in f:
                call['close'] = True
            elif crc('angle') in d:
                call['angle'] = float(d[crc('angle')])
            else:
                ok = False
                break
            calls.append(call)
            k = st + 4
        if ok and calls:
            out[name] = calls
    return out


def door_scripts_q(door_scripts):
    """our THUG2 scripts for the converted P8 door triggers + the shared swing helper"""
    lines = [
        'script dadmod_p8_door time = 0.3',
        '    if ObjectExists id = <door>',
        '        <door> : GetTags',
        '        if GotParam close',
        '            if GotParam p8_door_back',
        '                if ( <p8_door_isopen> = 1 )',
        '                    <door> : Obj_Rotate relative = <p8_door_back> time = <time>',
        '                    <door> : Obj_PlaySound elevatordoorclose vol = 60',
        '                    <door> : SetTags p8_door_isopen = 0',
        '                endif',
        '            endif',
        '        else',
        '            if GotParam p8_door_isopen',
        '                if ( <p8_door_isopen> = 1 )',
        '                    return',
        '                endif',
        '            endif',
        '            <door> : Obj_Rotate relative = <swing> time = <time>',
        '            <door> : Obj_PlaySound elevatordooropen vol = 60',
        '            <door> : SetTags p8_door_isopen = 1 p8_door_back = <back>',
        '        endif',
        '    endif',
        'endscript']
    for name, calls in sorted(door_scripts.items()):
        lines.append('script #"0x%08x"' % name)
        for c in calls:
            if c.get('close'):
                lines.append('    dadmod_p8_door door = #"0x%08x" close time = %s' % (c['door'], q_value(c['time'])))
            else:
                a = c['angle']
                lines.append('    dadmod_p8_door door = #"0x%08x" swing = (0.0,%s,0.0) back = (0.0,%s,0.0) time = 0.3'
                             % (c['door'], q_value(a), q_value(-a)))
        lines.append('endscript')
    return '\n'.join(lines) + '\n'


if __name__ == '__main__':
    if sys.argv[1] == 'convert':
        convert(sys.argv[2], sys.argv[3], sys.argv[4])


# ------------------------------------------------------------------ node array -> THUG2 .q
# ClimbingNode: P8 ladders (Type = Ladder, CreatedAtStart, one end links to the other) - the same node layout as THUG2's
# own ladders (stock Z_SR: two ClimbingNodes, Type = Ladder, top linked to bottom), so they are kept as they are
# GenericNode: P8's King of the Hill crown spots (Type = Crown), kept like THUG Pro's own z_center / z_funpark do
# ParticleObject: P8 level particle boxes (falling water, smoke...), written the way THUG Pro's own z_center does: P8's
# particle keys as they are, without the texture key (P8's particle images are not in the level's texture file)
KEEP_CLASSES = {crc(c) for c in ('RailNode', 'Restart', 'LevelGeometry', 'LevelObject', 'ClimbingNode', 'GenericNode',
                                 'ParticleObject')}
# node keys carried over, in output order; everything else (scripts, peds, AI data) is left out
KEY_NAMES = ['Name', 'Pos', 'Angles', 'Class', 'Type', 'CollisionMode', 'TerrainType', 'Cluster', 'RestartName',
             'restart_types', 'Links',
             # P8 knock-around objects (cones, cans, crates...): THUG2 bouncy LevelObject physics, same key names
             # (P8's lod_dist1/2 of 200/300 are left out: in THUG2 they'd hide the objects beyond 300 units)
             'SuspendDistance', 'Contacts', 'center_of_mass', 'coeff_restitution',
             'coeff_friction', 'skater_collision_impulse_factor', 'skater_collision_rotation_factor',
             'skater_collision_assent', 'skater_collision_radius', 'SoundType',
             # ParticleObject keys (lod_dist only written for particles, see write_nodearray_q)
             'BoxDims', 'BoxPositions', 'BlendMode', 'FixedAlpha', 'AlphaCutoff', 'MaxStreams', 'lod_dist1',
             'lod_dist2', 'EmitRate', 'Lifetime', 'MidPointPCT', 'Radii', 'RadiusSpread', 'RotVel', 'RotVelTimeScale',
             'TimeSeed', 'BoxRGBAs', 'ColorMidTime',
             # ped AI waypoints (Type = PedAI): P8 uses THUG2's own ped path keys (cf. stock AP / BA waypoints)
             'PedType', 'priority', 'ContinueWeight', 'SkateAction']
# P8 bouncy object SoundType -> a THUG Pro rigid body sound type (RigidBodySounds names). Types THUG Pro also has
# keep their name; P8-only ones (names unknown, checksums) are matched by object size and look: ~30-35 unit
# props -> small cone, 45-75 -> big cone / plastic can, flat 20 -> can, 90x60 chairs, large 100-150 -> drum.
P8_SOUNDTYPES = {crc(n): n for n in ('ST_BowlingPin', 'MetalTrashCan', 'NO_Barstool')}
P8_SOUNDTYPES.update({crc('Plastic50GalDrum'): 'PlasticTrashCan', crc('PottedPlant'): 'BE_LargePlanter',
                      0x5614b3ca: 'SmallTrafficCone', 0xdb358e98: 'SmallTrafficCone', 0x9be9b9c1: 'BigTrafficCone',
                      0x5f85eeb9: 'BE_LargePlanter', 0x2b430f9d: 'PlasticTrashCan', 0xee54bbb8: 'AluminumCan',
                      0x9646cf4d: 'CardboardBox', 0x6841b591: 'PlasticChair', 0xd171bc40: 'Metal50GalDrum',
                      0x39e17e25: 'Metal50GalDrum'})
# LipOverride (rails, as z_funpark), Occluder (level geometry used for visibility culling, as z_center),
# DieUponSettling / NeverSuspend (bouncy objects, as z_center) are flags THUG Pro's own P8 ports keep
FLAG_NAMES = ['CreatedAtStart', 'TrickObject', 'AbsentInNetGames', 'NetEnabled', 'Permanent', 'NoClimbing', 'bouncy',
              'LipOverride', 'Occluder', 'DieUponSettling', 'NeverSuspend',
              'UseMidPoint', 'UseColorMidTime', 'useGlobalColorModulation',     # particle flags
              'Continue', 'JumpToNextNode']                                     # ped AI waypoint flags
KEYS = {crc(k): k for k in KEY_NAMES}
FLAGS = {crc(k): k for k in FLAG_NAMES}
VALUE_NAMES = {crc(v): v for v in (
    'RailNode', 'Restart', 'LevelGeometry', 'LevelObject', 'ClimbingNode', 'Ladder', 'GenericNode', 'Crown', 'ParticleObject', 'NEWFLAT', 'Blend', 'Add', 'Pedestrian', 'Vehicle',
    'Waypoint', 'ACCEL', 'PedAI', 'Geometry', 'Player1', 'Multiplayer', 'Horse', 'CTF',
    'Team', 'Generic', 'Concrete', 'Metal', 'Wood', 'Normal', 'TERRAIN_DEFAULT', 'TERRAIN_GRINDCONC',
    'TERRAIN_GRINDMETAL', 'TERRAIN_GRINDWOOD', 'TERRAIN_GRINDPLASTIC', 'TERRAIN_GRINDWOODRAILING',
    'TERRAIN_GRINDWIRE', 'TERRAIN_GRINDCHAIN', 'TERRAIN_GRINDROPE',
    'Skate', 'Walk', 'Stand', 'Continue')}


def q_value(v):
    import p8qb
    if isinstance(v, p8qb.Key):
        return VALUE_NAMES.get(v, '#"0x%08x"' % v)
    if isinstance(v, bool):
        return str(int(v))
    if isinstance(v, int):
        return str(v)
    if isinstance(v, float):
        return repr(float('%.7g' % v)) if math.isfinite(v) else '0.0'
    if isinstance(v, str):
        return '"%s"' % v.replace('"', "'")
    if isinstance(v, tuple):
        return '(' + ','.join(q_value(float(x)) for x in v) + ')'
    if isinstance(v, list):
        return '[ ' + ' '.join(q_value(x) for x in v) + ' ]'
    raise ValueError(repr(v))


def nodes_from_qb(qb_bytes):
    """P8 node array -> list of dicts (prototype structs merged in)"""
    import p8qb
    b = qb_bytes
    fid = p8qb._u32(b, 0x24)
    protos = {}
    arr = None
    for o in range(0x1C, len(b) - 20, 4):
        if b[o] == 0 and b[o + 3] == 0 and p8qb._u32(b, o + 8) == fid:
            t, name, ptr = b[o + 2], p8qb._u32(b, o + 4), p8qb._u32(b, o + 12)
            if t == p8qb.STRUCT:
                protos[name] = ptr
            elif t == p8qb.ARRAY and arr is None:
                arr = ptr
    out = []
    for raw in p8qb.read_array(b, arr):
        node = {}
        flags = []
        for k, v in raw:
            if k is None and isinstance(v, p8qb.Key) and v in protos:
                for pk, pv in p8qb.read_struct(b, protos[v]):
                    if pk is None:
                        flags.append(pv)
                    else:
                        node.setdefault(pk, pv)
            elif k is None:
                flags.append(v)
            else:
                node[k] = v
        node['_flags'] = flags
        out.append(node)
    return out


RAIL = crc('RailNode')
ABSENT_NET = crc('AbsentInNetGames')


def link_ok(src, dst):
    """The engine's rail builder (0x57E960) hashes the RailNodes it creates, then for each rail's Links probes
    that hash until it finds the target - forever if the target isn't there. So a rail may only link to a rail
    the engine also creates: a RailNode, and not one dropped in net games (AbsentInNetGames, 0x565BB0) unless
    the source is dropped too. (P8Suburbs node 100 linked to a Restart and hung the level load.)"""
    if src.get(crc('Class')) != RAIL:
        return True
    if dst.get(crc('Class')) != RAIL:
        return False
    return ABSENT_NET not in dst['_flags'] or ABSENT_NET in src['_flags']


def write_nodearray_q(path, level, nodes, sectors=None, trigger_ok=None, col=None, prox_trig=None):
    """col: {collision object name: face count}. Like THUG Pro's own z_center (and reTHAWed's P8 zones), every
    geometry node that names a scene sector or a collision object is kept with P8's CreatedAtStart, so pieces P8
    doesn't create at start (story variants, Crete Park's coffee-cup-destroyed walls) are off, not orphaned
    collision that stays solid forever. A collision object whose node has another class (P8 ModelExport) is
    written as LevelGeometry so its CreatedAtStart still applies."""
    geo = {crc('LevelGeometry'), crc('LevelObject')}
    col = col or {}
    import p8qb
    lg = crc('LevelGeometry')
    nodes = [{**n, crc('Class'): p8qb.Key(lg), crc('CollisionMode'): p8qb.Key(crc('Geometry'))} if n.get(crc('Class')) not in KEEP_CLASSES and not (prox_trig is not None and n.get(crc('Class')) == crc('ProximNode')) and col.get(n.get(crc('Name')))
             else n for n in nodes]
    amb = (crc('ProximNode'), crc('EmitterObject')) if prox_trig is not None else ()
    keep = [i for i, n in enumerate(nodes) if (n.get(crc('Class')) in KEEP_CLASSES or offline_actor(n) or n.get(crc('Class')) in amb)
            and not (sectors is not None and n.get(crc('Class')) in geo and n.get(crc('Name')) not in sectors
                     and n.get(crc('Name')) not in col
                     and not (trigger_ok and n.get(crc('Name')) in trigger_ok))]   # collision-only trigger volumes stay
    remap = {old: new for new, old in enumerate(keep)}
    lines = ['%s_NodeArray = [' % level]
    counts = {}
    actor_scripts = []
    arm_groups([nodes[i] for i in keep])
    ALL_NODES[:] = nodes
    machine_plan([nodes[i] for i in keep])
    for i in keep:
        n = nodes[i]
        cls = VALUE_NAMES.get(n[crc('Class')], '?')
        counts[cls] = counts.get(cls, 0) + 1
        if n.get(crc('Class')) in amb:
            lines += ambience_node(n, prox_trig)
            continue
        if n.get(crc('Class')) in (crc('Pedestrian'), crc('Vehicle')):
            links = [remap[x] for x in (n.get(crc('Links')) or []) if x in remap]
            if n.get(crc('Class')) == crc('Pedestrian') and n.get(crc('PedAI_Type')) == crc('Skater') and not links:
                # P8's skater ped has no link (P8 missions drive it, Ped_SetAiMode scripted): start it on the
                # nearest skate waypoint, the way stock THUG2 skater peds (AP's TRG_Skater01) are linked
                wps = [j for j in keep if nodes[j].get(crc('Class')) == crc('Waypoint')
                       and nodes[j].get(crc('Type')) == crc('PedAI') and nodes[j].get(crc('PedType')) == crc('Skate')]
                if wps:
                    p0 = n[crc('Pos')]
                    j = min(wps, key=lambda j: sum((a - b) ** 2 for a, b in zip(nodes[j][crc('Pos')], p0)))
                    links = [remap[j]]
            lines += actor_node(n, links, actor_scripts)
            continue
        lines.append('{')
        for kname in KEY_NAMES:
            k = crc(kname)
            if k not in n:
                continue
            v = n[k]
            if kname == 'Links':
                v = [remap[x] for x in v if x in remap and link_ok(n, nodes[x])]
                if not v:
                    continue
            if kname == 'Name':
                lines.append('Name = #"0x%08x"' % v)
                continue
            if kname in ('lod_dist1', 'lod_dist2') and n.get(crc('Class')) != crc('ParticleObject'):
                continue
            if kname == 'SoundType':
                st = P8_SOUNDTYPES.get(int(v))
                if st:
                    lines.append('SoundType = %s' % st)
                continue
            lines.append('%s = %s' % (kname, q_value(v)))
        if trigger_ok and n.get(crc('Name')) in trigger_ok:
            # converted P8 trigger (door swing): script written by door_scripts_q into the level's _scripts.q
            lines.append('TriggerScript = #"0x%08x"' % trigger_ok[n[crc('Name')]])
        for f in n['_flags']:
            if f in FLAGS:
                lines.append(FLAGS[f])
        lines.append('}')
    extra, scripts = ctf_nodes([nodes[i] for i in keep])
    for k, v in extra:
        counts[k] = counts.get(k, 0) + 1
        lines += v
    lines.append(']')
    lines += scripts + actor_scripts
    if counts.get('Pedestrian'):
        # load_level runs this by name outside net games: the THUG2 human skeleton's anims the peds use
        lines += ['script load_level_anims', '    animload_THPS6_human', 'endscript']
    open(path, 'w', encoding='latin1', newline='\n').write('\n'.join(lines) + '\n')
    return counts


# Offline actors, the way P8 has them (AbsentInNetGames: never created online). P8's own ped and car models are
# not in THUG Pro, so they become THUG2 ones: every P8 pedestrian spot gets a THUG2 random ped (Ped_From_Profile,
# THPS6_human skeleton, random_male/female_profile - the stock THUG Pro setup, e.g. atlanta), and P8's street
# cars (Downtown's cop car and SUV) become THUG2 car models driving P8's own waypoint path with the stock
# Car_Generic01 script. P8's machinery "vehicles" (robot arms, car frames, playground rides) are not cars.
P8_CARS = {'veh\\veh_cop\\veh_cop.mdl': 'veh\\veh_cop\\veh_cop.mdl',
           'veh\\veh_explorer\\veh_explorer.mdl': 'veh\\Veh_Galaxie\\Veh_Galaxie.mdl'}


# P8 machinery / rides (Vehicle nodes with their own P8 model, converted by build_p8.build_models). P8 drives them
# with rigid-body physics and skeletal anims we don't have; our own motion per model instead:
# ('spin', deg/s) turns on Y, ('swing', axis, deg, speed) rocks back and forth, ('path', mph) follows the node's
# P8 waypoint links, ('still',) stays put (robot arm parts: their pieces are placed separately and would come apart).
MACHINES = {
    'veh_merrygoround': ('spin', 30), 'veh_elevator_crank': ('spin', 20),
    'veh_playground_swing': ('swing', 'X', 25, 30), 'veh_playground_seesaw': ('swing', 'Z', 12, 15),
    'veh_boatmast': ('swing', 'Z', 3, 2),
    # path following (Obj_FollowPathLinked on P8's conveyor waypoints) hung the single-player load in the 2026-11-16
    # test until it was started a moment after load (MACHINE_PLAN). The robot arm parts with no collision file crashed
    # the load (exe 0x40A2F6) until every model got one.
    'veh_carframe': ('path', 4), 'veh_tug': ('path', 6), 'veh_tug_cart': ('path', 6),
    'veh_robot_arm_main': ('swing', 'Y', 30, 8), 'veh_robot_arm_middle': ('still',), 'veh_robot_arm_tip': ('still',),
}


# robot arms: joints from the converted models (build_p8 fills ARM_JOINTS: main part's top joint, middle part's far
# end, in model space) and each middle / tip part's parent {name: (parent name, parent assembled pos, Y angle)}
ARM_JOINTS = {}
ARM_PARENT = {}


MACHINE_PLAN = {}     # node name -> ('path', delay s, cycle s | None, start pos) | ('lock', parent name, local offset)
FRAME_GAP = 8.0       # seconds between Car Factory car frames leaving the stack (P8 spawns them in sequence)


def machine_plan(nodes):
    """Car Factory: the 12 car frames all start stacked at one spot linked to one conveyor path (P8 releases them one
    after another) -> each gets a start delay, and, as the path doesn't loop, a cycle time after which it jumps back
    to the start; a tug on a looping path just drives; tug carts (no links in P8, a helper hitches them to their tug)
    lock to the nearest tug in the same row."""
    import math
    MACHINE_PLAN.clear()
    idx = {n[crc('Name')]: i for i, n in enumerate(nodes) if crc('Name') in n}
    byname = {n[crc('Name')]: n for n in nodes if crc('Name') in n}

    def path(n):
        pts, seen, j = [tuple(n[crc('Pos')])], set(), (n.get(crc('Links')) or [None])[0]
        names = [x for x in idx]
        while j is not None and j not in seen and 0 <= j < len(ALL_NODES):
            seen.add(j)
            pts.append(tuple(ALL_NODES[j][crc('Pos')]))
            l = ALL_NODES[j].get(crc('Links')) or []
            j = l[0] if l else None
        loops = j is not None
        return sum(math.dist(pts[k], pts[k + 1]) for k in range(len(pts) - 1)), loops

    count = {}
    tugs = []
    for n in nodes:
        mn = machine_name(n) if n.get(crc('Class')) == crc('Vehicle') else None
        how = MACHINES.get(mn) if mn else None
        if not how or how[0] != 'path':
            continue
        if mn == 'veh_tug_cart' and not n.get(crc('Links')):
            continue
        length, loops = path(n)
        key = (n.get(crc('Links')) or [None])[0]
        k = count.get(key, 0)
        count[key] = k + 1
        speed = how[1] * 17.6                      # mph -> units (inches) per second
        MACHINE_PLAN[n[crc('Name')]] = ('path', k * FRAME_GAP if mn == 'veh_carframe' else 0.0,
                                        None if loops else length / speed + 1.0, tuple(n[crc('Pos')]))
        if mn == 'veh_tug':
            tugs.append(n)
    for n in nodes:
        if machine_name(n) == 'veh_tug_cart' and not n.get(crc('Links')) and tugs:
            p = n[crc('Pos')]
            t = min(tugs, key=lambda t: math.dist(t[crc('Pos')], p))
            a = float(t.get(crc('Angles'), (0.0, 0.0, 0.0))[1])
            d = [p[k] - t[crc('Pos')][k] for k in range(3)]
            c, s = math.cos(a), math.sin(a)
            MACHINE_PLAN[n[crc('Name')]] = ('lock', t[crc('Name')], (d[0] * c - d[2] * s, d[1], d[0] * s + d[2] * c))


ALL_NODES = []        # the full P8 node list (indices = Links targets) while writing a node array


def arm_groups(nodes):
    """the three robot arm parts P8 places at one spot: middle locks to main, tip to middle"""
    import math
    ARM_PARENT.clear()
    if not ARM_JOINTS:
        return
    spots = {}
    for n in nodes:
        mn = machine_name(n) if n.get(crc('Class')) == crc('Vehicle') else None
        if mn and mn.startswith('veh_robot_arm_'):
            spots.setdefault(tuple(round(x) for x in n[crc('Pos')]), {})[mn] = n
    for parts in spots.values():
        m, mid, tip = (parts.get('veh_robot_arm_' + k) for k in ('main', 'middle', 'tip'))
        if not (m and mid and tip):
            continue
        a = float(m.get(crc('Angles'), (0.0, 0.0, 0.0))[1])
        c, s = math.cos(a), math.sin(a)
        j = ARM_JOINTS['veh_robot_arm_main']
        p = m[crc('Pos')]
        mpos = (p[0] + j[0] * c + j[2] * s, p[1] + j[1], p[2] + j[2] * c - j[0] * s)
        ARM_PARENT[mid[crc('Name')]] = (m[crc('Name')], tuple(p), a)
        ARM_PARENT[tip[crc('Name')]] = (mid[crc('Name')], mpos, a)


def machine_name(n):
    m = str(n.get(crc('model'), '')).lower().replace('/', '\\')
    b = m.split('\\')[-1].split('.')[0]
    return b if b in MACHINES else None


def offline_actor(n):
    c = n.get(crc('Class'))
    skip = os.environ.get('P8_SKIP', '').split(',')     # bisecting crashes: P8_SKIP=machines,peds,cars,waypoints
    if ('machines' in skip and c == crc('Vehicle') and machine_name(n)) or ('peds' in skip and c == crc('Pedestrian')) \
            or ('cars' in skip and c == crc('Vehicle') and not machine_name(n)) or ('waypoints' in skip and c == crc('Waypoint')) \
            or (c == crc('Vehicle') and machine_name(n) and any(s and s in machine_name(n) for s in skip if s.startswith('veh_'))):
        return False
    if c in (crc('Pedestrian'), crc('Waypoint')):
        return True
    return c == crc('Vehicle') and (str(n.get(crc('model'), '')).lower() in P8_CARS or machine_name(n) is not None)


# P8 sound loops that stack several clips at once every pass; we play one of them per pass instead (Noah,
# 2026-11-22: the Suburbs fountain played 4 splashes together every 0.1-0.5 s -> 15-20 overlapping voices),
# with their vol scaled by the given factor (Noah: still "really loud" up close at P8's 100-140)
THIN_SFX_LOOPS = {0xaf459890: 1.0}     # z_houses fountain (0.5 was tried while the .snd files were still noise)


def scale_vol(line, f):
    """vol = N / vol = randomrange (a,b) in one play line -> times f"""
    line = re.sub(r'vol = randomrange \(([-\d.e+]+),([-\d.e+]+)\)',
                  lambda m: 'vol = randomrange (%s,%s)' % (q_value(float(m.group(1)) * f), q_value(float(m.group(2)) * f)), line)
    return re.sub(r'vol = ([-\d.e+]+)(?= |$)', lambda m: 'vol = %s' % q_value(float(m.group(1)) * f), line)


def thin_plays(body):
    """runs of 2+ back-to-back Obj_PlaySound / PlaySound lines -> one randomnorepeat( @ ... ) pick"""
    out, run = [], []
    for x in body + [None]:
        if x is not None and (x.startswith('Obj_PlaySound ') or x.startswith('PlaySound ')):
            run.append(x)
            continue
        if len(run) > 1:
            out.append('randomnorepeat( %s )' % ' '.join('@ ' + r for r in run))
        else:
            out.extend(run)
        run = []
        if x is not None:
            out.append(x)
    return out


# P8 bank sounds with the 'looping' flag that an ambience script starts at a fixed EmitterObject (fountain water,
# machine hums...): P8 starts them once and they loop. Ours: a hidden Ghost GameObject at the emitter (the stock way,
# HOF's tss_WaterfountainSound; THPG does the same) whose TriggerScript plays the sound once; the .snd carries a loop
# ('smpl' chunk, p8sound.thug_snd loop=True). Filled by p8_ambience: EmitterObject name -> [our loop script names].
LOOP_EMITTERS = {}


def loop_ghost_nodes(name, pos):
    out = []
    for s in LOOP_EMITTERS.get(name, []):
        out += ['{', 'Name = %s_node' % s, 'Pos = %s' % pos, 'Angles = (0.0,0.0,0.0)', 'Class = GameObject',
                'Type = Ghost', 'CreatedAtStart', 'model = "none"', 'SuspendDistance = 0', 'lod_dist1 = 2500',
                'lod_dist2 = 5000', 'TriggerScript = %s' % s, '}']
    return out


def p8_ambience(all_qbs, pnodes, bank_names, stream_names=frozenset(), loop_names=frozenset()):
    r"""P8 level ambience, re-done with THUG2's own scheme (stock FL: ProximNode TrigBox -> SpawnSound <script>, whose
    loop does Obj_PlaySound <snd> ... emitter = <EmitterObject>). P8 does the same: a ProximNode's TriggerScript is
    SpawnSound { <sound script> }, and the sound script loops picking an emitter and playing bank sounds at it.
    We rewrite the simple loops only - lines: <x> = random(emitters), Obj_PlaySound / PlaySound <bank sound>
    vol/pitch [emitter], wait randomrange (ms) - into our own scripts; streams (P8 stream files we don't have),
    tags, conditions and spawned helpers are left out (a script that keeps nothing is dropped).
    bank_names: {sound checksum} present in the level's converted sound bank.
    Our sound names are p8s_<checksum> (LoadSound "<level>\\p8s_<checksum>": the files are installed under
    data\sounds\<level>). Returns (scripts .q text, {P8 proxim TriggerScript: our TriggerScript}, used sounds)."""
    import p8script
    scripts = {}
    for b in all_qbs:
        for k, c in p8script.scripts(b).items():
            if k not in scripts or len(c) > len(scripts[k]):
                scripts[k] = c
    SP, OPS, PS = crc('SpawnSound'), crc('Obj_PlaySound'), crc('PlaySound')
    OPST = crc('Obj_PlayStream')     # P8 stream (pcm.wad) loops: played as ordinary sounds (stream_names)
    K_VOL, K_PITCH, K_EM = crc('vol'), crc('pitch'), crc('emitter')
    # P8's distance fade (Obj_PlaySound ... dropoff_function = exponential); THUG2 takes the same key and names
    K_DF = crc('dropoff_function')
    DF_NAMES = {crc(n): n for n in ('exponential', 'inv_exponential', 'linear', 'standard')}
    emitters = {n[crc('Name')] for n in pnodes if n.get(crc('Class')) == crc('EmitterObject')}
    out, trig, used, done = [], {}, set(), {}
    LOOP_EMITTERS.clear()
    loops_made = set()

    def rng(l, i):
        """value tokens at l[i:] -> (text, next index)"""
        if l[i] == ('op', 'randomrange') and i + 1 < len(l) and l[i + 1][0] == 'vec':
            return 'randomrange (%s)' % ','.join(q_value(float(x)) for x in l[i + 1][1]), i + 2
        if l[i][0] in ('int', 'float'):
            return q_value(l[i][1]), i + 1
        if l[i] == ('op', '2d') and i + 1 < len(l) and l[i + 1][0] == 'name':
            return '<p8v_%08x>' % l[i + 1][1], i + 2
        if l[i][0] == 'name' and l[i][1] in emitters:          # emitter = <a fixed EmitterObject>
            return '#"0x%08x"' % l[i][1], i + 1
        return None, i + 1

    def sound_script(sc):
        if sc in done:
            return done[sc]
        body, keep = [], False
        ls = p8script.calls(scripts.get(sc, b''))
        # conditions, tags and helper spawns are P8 logic we don't carry: such scripts are left out whole
        if any(t[0] == 'op' and t[1] in ('if', 'else', 'switch') for l in ls for t in l) or \
                any(l and l[0][0] == 'name' and l[0][1] in (crc('SetTags'), crc('GetTags'), crc('Obj_SpawnScript'))
                    for l in ls):
            done[sc] = None
            return None
        assigned = set()
        for l in ls:
            if not l or l == [('op', 'endscript')]:
                continue
            if l in ([('op', 'begin')], [('op', 'repeat')]):
                body.append(l[0][1])
                continue
            if l[0] == ('op', '2d') and len(l) > 3 and l[2] == ('op', '='):       # <x> = (random) emitters
                em = [v for k, v in l[3:] if k == 'name' and v in emitters]
                if em and len(em) == len(l) - 3:
                    assigned.add(l[1][1])
                    body.append('<p8v_%08x> = %s' % (l[1][1], ('#"0x%08x"' % em[0]) if len(em) == 1 else
                                'random( %s )' % ' '.join('@ #"0x%08x"' % e for e in em)))
                continue
            if l[0][0] != 'name':
                continue
            fn = l[0][1]
            if (fn in (OPS, PS) and len(l) > 1 and l[1][0] == 'name' and l[1][1] in bank_names) or \
                    (fn == OPST and len(l) > 1 and l[1][0] == 'name' and l[1][1] in stream_names):
                snd = l[1][1]
                args, i = [], 2
                while i + 2 < len(l) + 1 and i < len(l):
                    if l[i][0] == 'name' and i + 1 < len(l) and l[i + 1] == ('op', '=') and l[i][1] == K_DF:
                        if i + 2 < len(l) and l[i + 2][0] == 'name' and l[i + 2][1] in DF_NAMES:
                            args.append('dropoff_function = %s' % DF_NAMES[l[i + 2][1]])
                        i += 3
                    elif l[i][0] == 'name' and i + 1 < len(l) and l[i + 1] == ('op', '=') and l[i][1] in (K_VOL, K_PITCH, K_EM):
                        txt, j = rng(l, i + 2)
                        if txt and txt.startswith('<p8v_') and int(txt[5:13], 16) not in assigned:
                            txt = None                  # a value P8 set in code we don't carry
                        if txt:
                            args.append('%s = %s' % ({K_VOL: 'vol', K_PITCH: 'pitch', K_EM: 'emitter'}[l[i][1]], txt))
                        i = j
                    else:
                        i += 1
                if fn == PS:
                    args = [a for a in args if not a.startswith('emitter')]
                em = [a for a in args if a.startswith('emitter = #"0x')]
                if fn == OPS and snd in loop_names and em:
                    # a looping sound at a fixed emitter: one Ghost object plays it for good (see LOOP_EMITTERS)
                    e = int(em[0][-9:-1], 16)
                    if (snd, e) not in loops_made:
                        loops_made.add((snd, e))
                        ln = 'dadmod_p8_loop_%08x_%08x' % (snd, e)
                        out.extend(['script %s' % ln,
                                    '    Obj_PlaySound p8s_%08x %s' % (snd, ' '.join(a for a in args if not a.startswith('emitter'))),
                                    'endscript'])
                        LOOP_EMITTERS.setdefault(e, []).append(ln)
                        used.add(snd)
                    continue
                body.append('%s p8s_%08x %s' % ('PlaySound' if fn == PS else 'Obj_PlaySound', snd, ' '.join(args)))
                used.add(snd)
                keep = True
                continue
            if fn == crc('wait') and len(l) > 1:
                if l[1] == ('op', 'randomrange') and len(l) > 2 and l[2][0] == 'vec':
                    a, b2 = l[2][1][:2]
                    body.append('wait randomrange (%s,%s) seconds' % (q_value(a / 1000.0), q_value(b2 / 1000.0)))
                elif l[1][0] in ('int', 'float') and len(l) > 2 and l[2] == ('name', crc('gameframes')):
                    body.append('wait %d gameframes' % l[1][1])
                elif l[1][0] in ('int', 'float'):
                    body.append('wait %s seconds' % q_value(float(l[1][1]) / 1000.0))
        # a loop must wait, or it would replay every frame
        if not keep or ('begin' in body and not any(x.startswith('wait') for x in body)):
            done[sc] = None
            return None
        if sc in THIN_SFX_LOOPS:
            body = thin_plays([scale_vol(x, THIN_SFX_LOOPS[sc]) if 'PlaySound ' in x else x for x in body])
        name = 'dadmod_p8_sfx_%08x' % sc
        out.extend(['script %s' % name] + ['    ' + x for x in body] + ['endscript'])
        done[sc] = name
        return name

    BONK = crc('BonkBush')

    def rustle_script(sc):
        if sc in done:
            return done[sc]
        body, ok = [], False
        for l in p8script.calls(scripts.get(sc, b'')):
            if not l or l == [('op', 'endscript')]:
                continue
            if l in ([('op', 'if'), ('name', crc('inside'))], [('op', 'endif')]):
                body.append('if inside' if len(l) == 2 else 'endif')
                continue
            if l[0] == ('name', PS) and len(l) > 1 and l[1][0] == 'name' and (l[1][1] == BONK or l[1][1] in bank_names):
                snd = 'BonkBush' if l[1][1] == BONK else 'p8s_%08x' % l[1][1]
                args, i = [], 2
                while i < len(l):
                    if l[i][0] == 'name' and i + 1 < len(l) and l[i + 1] == ('op', '=') and l[i][1] in (K_VOL, K_PITCH):
                        txt, j = rng(l, i + 2)
                        if txt and not txt.startswith('<'):
                            args.append('%s = %s' % ('vol' if l[i][1] == K_VOL else 'pitch', txt))
                        i = j
                    else:
                        i += 1
                body.append('    PlaySound %s %s' % (snd, ' '.join(args)))
                used.add(l[1][1])
                ok = True
                continue
            if l[0] == ('name', crc('wait')) and len(l) > 2 and l[1] == ('op', 'randomrange') and l[2][0] == 'vec':
                a, b2 = l[2][1][:2]
                body.append('    wait randomrange (%s,%s) seconds' % (q_value(a / 1000.0), q_value(b2 / 1000.0)))
                continue
            done[sc] = None                     # anything else: not a plain rustle script
            return None
        if not ok or body.count('if inside') != body.count('endif'):
            done[sc] = None
            return None
        name = 'dadmod_p8_rustle_%08x' % sc
        out.extend(['script %s' % name] + ['    ' + x for x in body] + ['endscript'])
        done[sc] = name
        return name

    REV_MODES = {crc(m): m for m in (
        'REV_MODE_GENERIC REV_MODE_PADDEDCELL REV_MODE_ROOM REV_MODE_BATHROOM REV_MODE_LIVINGROOM REV_MODE_STONEROOM '
        'REV_MODE_AUDITORIUM REV_MODE_CONCERTHALL REV_MODE_CAVE REV_MODE_ARENA REV_MODE_HANGAR REV_MODE_CARPETEDHALLWAY '
        'REV_MODE_HALLWAY REV_MODE_STONECORRIDOR REV_MODE_ALLEY REV_MODE_FOREST REV_MODE_CITY REV_MODE_MOUNTAINS '
        'REV_MODE_QUARRY REV_MODE_PLAIN REV_MODE_PARKINGLOT REV_MODE_SEWERPIPE REV_MODE_UNDERWATER').split()}
    K_MODE = crc('mode')

    def reverb_script(sc):
        """P8 reverb zones (garages, tunnels): the box's script sets SetSfxReverb <amount> mode = REV_MODE_* while
        inside (P8 wraps it in pause / split-screen / volume checks). THUG2 has the same CFunc and modes (stock
        hi / nj levels); ours: inside -> P8's amount and mode, outside -> 0."""
        key = ('rev', sc)
        if key in done:
            return done[key]
        res = None
        for l in p8script.calls(scripts.get(sc, b'')):
            if l and l[0] == ('name', crc('SetSfxReverb')) and len(l) > 1 and l[1][0] == 'struct' and l[1][1]:
                d = {k: v for k, v in l[1][1] if k is not None}
                amt = [v for k, v in l[1][1] if k is None and isinstance(v, (int, float))]
                mode = d.get(K_MODE)
                if amt and mode is not None:
                    mn = REV_MODES.get(int(mode), '#"0x%08x"' % int(mode))
                    res = 'dadmod_p8_reverb_%08x' % sc
                    out.extend(['script %s' % res, '    if inside', '        SetSfxReverb %s mode = %s' % (amt[0], mn),
                                '    else', '        SetSfxReverb 0 mode = %s' % mn, '    endif', 'endscript'])
                break
        done[key] = res
        return res

    for n in pnodes:
        if n.get(crc('Class')) != crc('ProximNode'):
            continue
        t = n.get(crc('TriggerScript'))
        if t is None or t in trig:
            continue
        calls = []
        for l in p8script.calls(scripts.get(t, b'')):
            if l and l[0] == ('name', SP) and len(l) > 1 and l[1][0] == 'struct':
                calls += [v for k, v in (l[1][1] or []) if k is None and v in scripts]
        ours = [s for s in (sound_script(c) for c in calls) if s]
        if ours:
            tn = 'dadmod_p8_prox_%08x' % t
            out.extend(['script %s' % tn] + ['    SpawnSound %s' % s for s in ours] + ['endscript'])
            trig[t] = tn
            continue
        # bush / tree rustle: a proxim box whose script is "if inside: PlaySound BonkBush (and/or bank sounds),
        # wait" - the same as stock City Center's z_center_bush_rustle on its tree / hedge boxes
        tl = [l for l in p8script.calls(scripts.get(t, b'')) if l and l != [('op', 'endscript')]]
        if len(tl) == 1 and tl[0][0][0] == 'name' and len(tl[0]) == 1 and tl[0][0][1] in scripts:
            r = rustle_script(tl[0][0][1]) or reverb_script(tl[0][0][1])
            if r:
                trig[t] = r
    return '\n'.join(out) + '\n', trig, used


def ambience_node(n, prox_trig):
    """THUG2 ProximNode / EmitterObject entries (stock FL layout); the proxim box is P8's collision object of the
    same name, which our verbatim collision file keeps"""
    name = n[crc('Name')]
    pos = '(%s)' % ','.join(q_value(float(x)) for x in n[crc('Pos')])
    ang = '(%s)' % ','.join(q_value(float(x)) for x in n.get(crc('Angles'), (0.0, 0.0, 0.0)))
    out = ['{', 'Name = #"0x%08x"' % name, 'Pos = %s' % pos, 'Angles = %s' % ang]
    if n[crc('Class')] == crc('EmitterObject'):
        return out + ['Class = EmitterObject', 'Type = BoundingBox', 'CreatedAtStart', '}'] + loop_ghost_nodes(name, pos)
    typ = n.get(crc('Type'))
    out += ['Class = ProximNode', 'Type = %s' % ('object' if typ == crc('object') else 'camera'), 'CreatedAtStart']
    out += ['ProximObject'] if crc('ProximObject') in n['_flags'] else []
    out += ['RenderToViewport', 'SelectRenderOnly', 'Shape = BoundingBox']
    t = prox_trig.get(n.get(crc('TriggerScript')))
    if t:
        out.append('TriggerScript = %s' % t)
    return out + ['}']


def actor_node(n, links, scripts):
    name = n[crc('Name')]
    pos = '(%s)' % ','.join(q_value(float(x)) for x in n[crc('Pos')])
    ang = '(%s)' % ','.join(q_value(float(x)) for x in n.get(crc('Angles'), (0.0, 0.0, 0.0)))
    out = ['{', 'Name = #"0x%08x"' % name, 'Pos = %s' % pos, 'Angles = %s' % ang]
    if n[crc('Class')] == crc('Pedestrian') and n.get(crc('PedAI_Type')) == crc('Skater') and links:
        # P8 skater ped -> the stock THUG2 skater ped (AP TRG_Skater01): skateboard profile, Ped_InitAI Skater,
        # linked to the first skate waypoint; it then rides P8's PedAI skate path (Continue / ContinueWeight)
        trig = 'dadmod_p8_skaterped_%08x' % name
        out += ['Class = Pedestrian', 'Type = Ped_Skateboard_A', 'CreatedAtStart', 'AbsentInNetGames',
                'PedAI_Type = Stand', 'skeletonName = THPS6_human', 'animName = animload_THPS6_human',
                'profile = Ped_Skateboard_A', 'SuspendDistance = 10000', 'lod_dist1 = 200', 'lod_dist2 = 201',
                'TriggerScript = %s' % trig, 'Links = [ %s ]' % ' '.join(str(x) for x in links), '}']
        scripts += ['script %s' % trig, '    Ped_InitAI Skater', 'endscript']
        return out
    if n[crc('Class')] == crc('Pedestrian'):
        prof = 'random_female_profile' if name % 3 == 0 else 'random_male_profile'
        out += ['Class = Pedestrian', 'Type = Ped_From_Profile', 'CreatedAtStart', 'AbsentInNetGames',
                'skeletonName = THPS6_human', 'animName = animload_THPS6_human', 'profile = %s' % prof,
                'SuspendDistance = 0', 'lod_dist1 = 150', 'lod_dist2 = 300']
    elif machine_name(n):
        mn = machine_name(n)
        how = MACHINES[mn]
        trig = 'dadmod_p8_machine_%08x' % name
        if 'still' in os.environ.get('P8_SKIP', '').split(','):
            how = ('still',)
        elif mn in ('veh_robot_arm_middle', 'veh_robot_arm_tip') and name in ARM_PARENT and ARM_JOINTS:
            # P8 places all three parts at the arm's base and moves them with bones; we assemble the rest pose:
            # middle on the main part's top joint, tip on the middle's far end, each locked to its parent
            parent, ppos, a = ARM_PARENT[name]
            j = ARM_JOINTS['veh_robot_arm_main' if mn == 'veh_robot_arm_middle' else 'veh_robot_arm_middle']
            import math
            c, s = math.cos(a), math.sin(a)
            wp = (ppos[0] + j[0] * c + j[2] * s, ppos[1] + j[1], ppos[2] + j[2] * c - j[0] * s)
            out[2] = 'Pos = (%s)' % ','.join(q_value(float(x)) for x in wp)
            out += ['Class = Vehicle', 'Type = #"Default"', 'CreatedAtStart', 'AbsentInNetGames', 'NoSkitch'] + (
                    ['nocollision'] if crc('nocollision') in n['_flags'] else []) + [
                    'model = "veh\\\\%s\\\\%s.mdl"' % (mn, mn), 'SuspendDistance = 10000', 'lod_dist1 = 400',
                    'lod_dist2 = 401'] + ([] if 'nolock' in os.environ.get('P8_SKIP', '') else ['TriggerScript = %s' % trig])
            scripts += [] if 'nolock' in os.environ.get('P8_SKIP', '') else ['script %s' % trig, '    if InNetGame', '        return', '    endif',
                        '    Obj_LockToObject ObjectName = #"0x%08x" (%s)' % (parent, ','.join(q_value(float(x)) for x in j)),
                        'endscript']
            return out + ['}']
        if mn == 'veh_robot_arm_main' and ARM_JOINTS and how != ('still',):
            how = ('swing', 'Y', 30, 8)
        out += ['Class = Vehicle', 'Type = #"Default"', 'CreatedAtStart', 'AbsentInNetGames', 'NoSkitch'] + (
                    ['nocollision'] if crc('nocollision') in n['_flags'] else []) + [
                'model = "veh\\\\%s\\\\%s.mdl"' % (mn, mn), 'SuspendDistance = 10000', 'lod_dist1 = 400',
                'lod_dist2 = 401']
        body = []
        if how[0] == 'spin':
            body = ['    Obj_RotY speed = %d' % how[1]]
        elif how[0] == 'swing':
            ax, deg, sp = how[1], how[2], how[3]
            body = ['    Obj_Rot%s angle = %d speed = %d' % (ax, deg, sp), '    Obj_WaitRotate', '    begin',
                    '        Obj_Rot%s angle = %d speed = %d' % (ax, -2 * deg, sp), '        Obj_WaitRotate',
                    '        Obj_Rot%s angle = %d speed = %d' % (ax, 2 * deg, sp), '        Obj_WaitRotate',
                    '    repeat']
        elif how[0] == 'path' and MACHINE_PLAN.get(name, ('',))[0] == 'lock':
            _, parent, off = MACHINE_PLAN[name]
            body = ['    wait 1 seconds', '    Obj_LockToObject ObjectName = #"0x%08x" (%s)' % (parent, ','.join(q_value(float(x)) for x in off))]
        elif how[0] == 'path' and links:
            # started a moment after the level is up (stock z_funpark starts its coaster from a level script, not at
            # object creation; following a path while the level was still loading hung the single-player load)
            _, delay, cycle, start = MACHINE_PLAN.get(name, ('path', 0.0, None, None))
            body = ['    wait %s seconds' % q_value(2.0 + delay), '    Obj_PathHeading on', '    Obj_SetPathTurnDist 30']
            if cycle:                       # one-way conveyor: run it, jump back to the start, again
                body += ['    begin', '        Obj_SetPosition position = (%s)' % ','.join(q_value(float(x)) for x in start),
                         '        Obj_FollowPathLinked', '        Obj_SetPathVelocity %d mph' % how[1],
                         '        wait %s seconds' % q_value(round(cycle, 1)), '    repeat']
            else:
                body += ['    Obj_FollowPathLinked', '    Obj_SetPathVelocity %d mph' % how[1]]
        if body:
            out.append('TriggerScript = %s' % trig)
            scripts += ['script %s' % trig, '    if InNetGame', '        return', '    endif'] + body + ['endscript']
    else:
        model = P8_CARS[str(n.get(crc('model'))).lower()].replace('\\', '\\\\')
        trig = 'dadmod_p8_car_%08x' % name
        out += ['Class = Vehicle', 'Type = #"Default"', 'CreatedAtStart', 'AbsentInNetGames', 'NoSkitch'] + (
                    ['nocollision'] if crc('nocollision') in n['_flags'] else []) + [
                'model = "%s"' % model, 'skeletonName = car', 'SuspendDistance = 0', 'lod_dist1 = 400',
                'lod_dist2 = 401']
        if links:
            out.append('TriggerScript = %s' % trig)
            scripts += ['script %s' % trig, '    Car_Generic01 { DefaultSpeed = 25 TurnDist = 100 StickToGround }',
                        'endscript']
    if links:
        out.append('Links = [ %s ]' % ' '.join(str(x) for x in links))
    return out + ['}']


def ctf_nodes(kept):
    """Capture-the-flag support like THUG Pro's own P8 levels (z_center): four flag GameObjects (stock flag
    models) whose TriggerScript calls the stock Team_Flag <colour>, and a Type team restart at each. The spots
    are the level's own multiplayer restarts, spread out (farthest-point pick), so they stand on real ground."""
    import math
    mp = crc('Multiplayer')
    def spot(n):
        return tuple(n[crc('Pos')]), tuple(n.get(crc('Angles'), (0.0, 0.0, 0.0)))
    rs = [n for n in kept if n.get(crc('Class')) == crc('Restart')]
    pts = [spot(n) for n in rs if mp in (n.get(crc('restart_types')) or []) or n.get(crc('Type')) == mp]
    if len(pts) < 4:
        pts = [spot(n) for n in rs]
    if len(pts) < 4:
        return [], []
    d = lambda a, b: math.dist(a[0], b[0])
    pick = [max(pts, key=lambda p: max(d(p, q) for q in pts))]
    while len(pick) < 4:
        pick.append(max((p for p in pts if p not in pick), key=lambda p: min(d(p, q) for q in pick)))
    extra, scripts = [], []
    bs = chr(92) * 2          # a \\ inside the .q string
    for colour, (pos, ang) in zip(('Blue', 'Green', 'Red', 'Yellow'), pick):
        p = '(%s)' % ','.join(q_value(float(x)) for x in pos)
        a = '(%s)' % ','.join(q_value(float(x)) for x in ang)
        lc = colour.lower()
        model = 'gameobjects%sflags%sflag_%s%sflag_%s.mdl' % (bs, bs, lc, bs, lc)
        extra.append(('CTF flag', ['{', 'Name = TRG_P8_Flag_%s' % colour, 'Pos = %s' % p, 'Angles = %s' % a,
                                   'Class = GameObject', 'Type = Flag_%s' % colour, 'model = "%s"' % model,
                                   'SuspendDistance = 0', 'lod_dist1 = 800', 'lod_dist2 = 801',
                                   'TriggerScript = TRG_P8_Flag_%sScript' % colour, '}']))
        extra.append(('team restart', ['{', 'Name = TRG_P8_Team_Restart_%s' % colour, 'Pos = %s' % p,
                                       'Angles = %s' % a, 'Class = Restart', 'Type = team',
                                       'RestartName = "Team: Restart"', 'restart_types = [ team ]', '}']))
        scripts += ['script TRG_P8_Flag_%sScript' % colour, '    Team_Flag %s' % lc, 'endscript']
    # King of the Hill: a level without P8 crown spots (only Suburbs has them) gets GenericNode Type = Crown nodes
    # at the same spread-out multiplayer restarts (THUG Pro's own P8 ports carry crown GenericNodes)
    if not any(n.get(crc('Class')) == crc('GenericNode') and n.get(crc('Type')) == crc('Crown') for n in kept):
        for k, (pos, ang) in enumerate(pick, 1):
            p = '(%s)' % ','.join(q_value(float(x)) for x in pos)
            a = '(%s)' % ','.join(q_value(float(x)) for x in ang)
            extra.append(('crown', ['{', 'Name = TRG_P8_Crown_%02d' % k, 'Pos = %s' % p, 'Angles = %s' % a,
                                    'Class = GenericNode', 'Type = Crown', 'CreatedAtStart', '}']))
    return extra, scripts
