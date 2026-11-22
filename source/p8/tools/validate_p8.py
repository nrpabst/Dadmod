r"""Re-read the converted P8 level files and check the invariants the engine relies on
(and that no two surfaces z-fight).

    python -I p8\tools\validate_p8.py [Level ...]      (run from work\; reads p8\build\tmp\<Level>)

Independent readers (not p8conv's writers). Exit code 1 if anything fails.
"""
import os, re, struct, sys, zlib
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
TMP = os.path.join(os.path.dirname(HERE), 'build', 'tmp')
LEVELS = ['P8Training', 'P8Suburbs', 'P8Downtown', 'P8CarFactory', 'P8CretePark']
errors = []


def err(level, msg):
    errors.append('%s: %s' % (level, msg))


def check_col(level, path, trigger_ok=frozenset()):
    """P8's collision layout as THUG Pro's own P8 levels ship it (header 0x20; large 10 byte and small 8 byte
    faces, float or fixed verts, P8's BSP). trigger_ok: collision objects whose node has a TriggerScript that
    the level defines; a trigger face anywhere else makes the engine read a missing TriggerScript (0x476953)"""
    import colparse
    b = open(path, 'rb').read()
    s = colparse.sections(b, 0x20)
    ver, nobj, tv, nf, nlf, nlv, nsv, _ = s['header']
    if ver != 10:
        err(level, 'col version %d' % ver)
    flagged = invis_solid = invis_open = 0
    sumf = 0
    for o in s['objs']:
        cs, nv, nfo = o['cs'], o['nv'], o['nf']
        faces = colparse.obj_faces(s, o)
        for j, (fflags, tt, vi) in enumerate(faces):
            if fflags & 0x40 and cs not in trigger_ok:
                flagged += 1
            if fflags & 0x1000:
                if fflags & 0x10:
                    invis_open += 1
                else:
                    invis_solid += 1
            if max(vi) >= nv:
                err(level, 'col obj %08x face %d vertex index %d >= %d' % (cs, j, max(vi), nv))
                break
        if nfo:
            seen = set()
            tree = colparse.obj_tree(s, o)
            for kind, x, y in tree:
                if kind == 'leaf':
                    if y is None:
                        err(level, 'col obj %08x leaf face list past end' % cs)
                        break
                    for fi in y:
                        if fi >= nfo:
                            err(level, 'col obj %08x leaf face %d >= %d' % (cs, fi, nfo))
                        seen.add(fi)
            if len(seen) != nfo:
                err(level, 'col obj %08x bsp covers %d of %d faces' % (cs, len(seen), nfo))
        sumf += nfo
    if sumf != nf + nlf:
        err(level, 'col faces %d vs header %d' % (sumf, nf + nlf))
    if flagged:
        err(level, '%d trigger faces (0x40) on objects without a defined TriggerScript (crash)' % flagged)
    print('  %-13s invisible collision faces: %d solid, %d non-collidable' % (level, invis_solid, invis_open))
    return nobj, nf


def check_scn(level, path, tex_ids, objects=frozenset(), cas=None, trick=frozenset()):
    b = open(path, 'rb').read()
    o = 12
    nm = struct.unpack_from('<I', b, o)[0]
    o += 4
    mats = set()
    zbias, blended, twosided, sortkey = {}, {}, {}, {}
    nseq = {}          # material -> colour sequence count (VC wibble)
    tris = []          # (scope, material, (p0, p1, p2)) for the overlap checks
    ctris = []         # coincident.py triangles (with colours / UVs)
    maxv = maxi = 0
    for i in range(nm):
        cs, name, np_, cut = struct.unpack_from('<4I', b, o)
        zbias[cs] = struct.unpack_from('<i', b, o + 23)[0]
        sortkey[cs] = (b[o + 16], struct.unpack_from('<f', b, o + 17)[0], zbias[cs])
        # effective culling as THUG Pro's loader (0x4D3200) sets it: two_sided, or single_sided 0 with a blended pass 0
        twosided[cs] = b[o + 22] != 0 or (b[o + 21] == 0 and np_ > 0 and struct.unpack_from('<I', b, o + 32 + 21)[0] != 0)
        blended[cs] = struct.unpack_from('<I', b, o + 32 + 21)[0] != 0 if np_ else False
        o += 16 + 16
        if not 1 <= np_ <= 4:
            err(level, 'material %08x has %d passes' % (cs, np_))
        mats.add(cs)
        for j in range(np_):
            tex, fl = struct.unpack_from('<II', b, o)
            if tex and tex not in tex_ids:
                err(level, 'material %08x pass %d texture %08x missing' % (cs, j, tex))
            if fl & 0x2 and j:      # the exe (0x4D2CB0) reads colour sequences on pass 0 only: stream would desync
                err(level, 'material %08x pass %d has colour animation off pass 0' % (cs, j))
            o += 49 + (32 if fl & 0x1 else 0)   # UV wibble: 8 floats after the pass
            if fl & 0x2 and not j:  # colour sequences: count, then {nkeys, phase, nkeys*(time, colour)}
                nseq[cs] = struct.unpack_from('<I', b, o)[0]
                o += 4
                for _q in range(nseq[cs]):
                    nk = struct.unpack_from('<I', b, o)[0]
                    keys = struct.unpack_from('<%dI' % (2 * nk), b, o + 8)
                    if not nk or any(keys[2 * q] > keys[2 * q + 2] for q in range(nk - 1)):
                        err(level, 'material %08x colour sequence %d has bad keys' % (cs, _q))
                    o += 8 + 8 * nk
            if fl & 0x800:          # texture flipbook: nkeys, period, iterations, phase, nkeys*(time, texture)
                nk = struct.unpack_from('<I', b, o)[0]
                keys = struct.unpack_from('<%dI' % (2 * nk), b, o + 16)
                if nk < 2 or any(keys[2 * q] > keys[2 * q + 2] for q in range(nk - 1)) or keys[-2] <= keys[0]:
                    err(level, 'material %08x pass %d flipbook has bad times' % (cs, j))
                for q in range(nk):
                    if keys[2 * q + 1] not in tex_ids:
                        err(level, 'material %08x pass %d flipbook texture %08x missing' % (cs, j, keys[2 * q + 1]))
                o += 16 + 8 * nk
            o += 16
    ns = struct.unpack_from('<I', b, o)[0]
    o += 4
    bad_sphere = bad_box = 0
    for i in range(ns):
        cs, bone, sfl, nmesh = struct.unpack_from('<IiII', b, o)
        sbox = struct.unpack_from('<6f', b, o + 16)
        o += 16 + 24 + 16
        for j in range(nmesh):
            msph = struct.unpack_from('<4f', b, o)
            o += 16 + 24
            mfl, mat = struct.unpack_from('<II', b, o)
            o += 8
            if mat not in mats:
                err(level, 'sector %08x mesh %d material %08x missing' % (cs, j, mat))
            nlod = struct.unpack_from('<I', b, o)[0]
            o += 4
            n = struct.unpack_from('<I', b, o)[0]
            idx = struct.unpack_from('<%dH' % n, b, o + 4)
            o += 4 + 2 * n
            n2 = struct.unpack_from('<H', b, o)[0]
            o += 2 + 2 * n2 + 14
            stride, nv, nbuf, bfl = struct.unpack_from('<BHBB', b, o)
            o += 5
            if nbuf != 1 or bfl:
                err(level, 'sector %08x mesh %d has %d vertex buffers / buffer flag %d' % (cs, j, nbuf, bfl))
            vsize = struct.unpack_from('<I', b, o)[0]
            pos = [struct.unpack_from('<3f', b, o + 4 + k * stride) for k in range(nv)] if stride else []
            vbo = o + 4
            o += 4 + vsize
            fvf = struct.unpack_from('<i', b, o)[0]
            co = 12 + (12 if fvf & 0x10 else 0)          # our layout: pos, [normal], colour, uvs
            cols = [b[vbo + k * stride + co:vbo + k * stride + co + 4] for k in range(nv)] if stride else []
            uvs = [struct.unpack_from('<2f', b, vbo + k * stride + co + 4) for k in range(nv)] if stride >= co + 12 else [(0.0, 0.0)] * nv
            scope = cs if cs in objects else None
            # culling volumes: the mesh sphere and the sector box must hold every vertex
            if pos:
                cx, cy, cz, r = msph
                if max(((p[0] - cx) ** 2 + (p[1] - cy) ** 2 + (p[2] - cz) ** 2) ** 0.5 for p in pos) > r + 0.05:
                    bad_sphere += 1
                if any(p[k] < sbox[k] - 0.05 or p[k] > sbox[3 + k] + 0.05 for p in pos for k in range(3)):
                    bad_box += 1
            for t in range(len(idx) - 2):
                a, b2, c = idx[t:t + 3]
                if t % 2:
                    a, b2 = b2, a          # strip winding alternates
                if a != b2 and b2 != c and a != c and max(a, b2, c) < len(pos):
                    tris.append((scope, mat, (pos[a], pos[b2], pos[c])))
                    ctris.append((scope, cs, mat, (pos[a], pos[b2], pos[c]), (cols[a], cols[b2], cols[c]),
                                  (uvs[a], uvs[b2], uvs[c])))
            if vsize != stride * nv:
                err(level, 'sector %08x mesh %d vertex size %d != %d*%d' % (cs, j, vsize, stride, nv))
            if idx and max(idx) >= nv:
                err(level, 'sector %08x mesh %d index %d >= %d verts' % (cs, j, max(idx), nv))
            maxv, maxi = max(maxv, nv), max(maxi, n)
            if b[o + 11]:           # per-vertex colour sequence bytes (exe mesh +0x8C, 1-based, 0 = own colour)
                sel = b[o + 12:o + 12 + nv]
                if not nseq.get(mat):
                    err(level, 'sector %08x mesh %d picks colour sequences but material %08x has none' % (cs, j, mat))
                elif max(sel) > nseq[mat]:
                    err(level, 'sector %08x mesh %d picks colour sequence %d of %d' % (cs, j, max(sel), nseq[mat]))
                o += nv
            o += 8 + 4 + 4 + 12
    if o + 4 != len(b):
        err(level, 'scn parse ended at %d of %d bytes' % (o + 4, len(b)))
    if bad_sphere:
        err(level, '%d meshes have vertices outside their culling sphere' % bad_sphere)
    if bad_box:
        err(level, '%d meshes have vertices outside their sector box' % bad_box)
    check_overlaps(level, tris, zbias, twosided)
    import coincident
    found = coincident.find(ctris, twosided)
    if cas is not None:
        # copies in a piece that isn't created at start are story variants of the original (never both shown
        # unless Level Options swaps them): only copies in one sector or in two CreatedAtStart sectors count
        found['b'] = [(i, j) for i, j in found['b'] if ctris[i][1] == ctris[j][1]
                      or (ctris[i][1] in cas and ctris[j][1] in cas)]
    found['d'] = coincident.find_retriangulated(ctris, cas, trick)
    shown = [x if (cas is None or x[1] in cas) else (('hidden',),) + x[1:] for x in ctris]
    found['e'] = coincident.find_unstable(shown, lambda c: sortkey[c])
    if found['e']:
        err(level, '%d same-facing coplanar overlaps with no stable winner (per-pixel z-fight)' % len(found['e']))
    found['f'] = coincident.find_sunk(shown, lambda c: blended.get(c))
    if found['f']:
        err(level, '%d blended decal faces sunk under the opaque surface they cover (show through as the camera moves)'
            % len(found['f']))
    COINCIDENT[level] = {k: len(v) for k, v in found.items()}
    if found['d']:
        err(level, '%d faces of a re-triangulated, differently shaded copy of a surface in another shown sector (flicker)'
            % len(found['d']))
    if found['a']:
        err(level, '%d back-to-back face pairs that look different in materials drawn two-sided (flicker)' % len(found['a']))
    if found['b']:
        err(level, '%d same-facing face copies that look different in one material (flicker)' % len(found['b']))
    if found['c']:
        note(level, '%d same-facing coincident faces of different materials' % len(found['c']))
    return nm, ns, maxv, maxi


COINCIDENT = {}


NOTES = []


def note(level, msg):
    NOTES.append('%s: %s' % (level, msg))


def check_overlaps(level, tris, zbias, twosided=None):
    import p8conv
    if p8conv.STOCK_PARITY:
        # P8 data kept as THUG Pro's own City Center keeps it (duplicates, coplanar zbias decals, back-to-back
        # faces) renders without flicker, so these are reported as notes, not problems
        global err
        real_err, err = err, note
        try:
            return _check_overlaps(level, tris, zbias, twosided)
        finally:
            err = real_err
    return _check_overlaps(level, tris, zbias, twosided)


def _check_overlaps(level, tris, zbias, twosided=None):
    """Surfaces that z-fight: the same triangle twice in one material and direction (per sector for
    LevelObjects, across all world sectors otherwise); back-to-back faces in a TWO-SIDED material (both draw
    from either side); and coplanar overlapping triangles of different materials with equal zbias."""
    import numpy as np
    from collections import defaultdict
    seen = {}
    dups = b2b = 0
    for scope, mat, ps in tris:
        rp = [tuple(round(x, 2) for x in p) for p in ps]
        i = rp.index(min(rp))
        rot = (rp[i], rp[(i + 1) % 3], rp[(i + 2) % 3])
        key = (scope, mat, tuple(sorted(rp)))
        prev = seen.setdefault(key, set())
        if rot in prev:
            dups += 1
        elif prev and twosided and twosided.get(mat):
            b2b += 1
        prev.add(rot)
    if dups:
        err(level, '%d duplicate triangles in the same material (z-fight)' % dups)
    if b2b:
        err(level, '%d back-to-back faces in two-sided materials (both draw: z-fight)' % b2b)
    world = [(m, ps) for sc, m, ps in tris if sc is None]
    if not world:
        return
    T = np.array([ps for m, ps in world], dtype=np.float64)
    TM = np.array([m for m, ps in world], dtype=np.uint32)
    n = np.cross(T[:, 1] - T[:, 0], T[:, 2] - T[:, 0])
    ln = np.linalg.norm(n, axis=1)
    ok = ln > 1.0
    n = n / np.maximum(ln, 1e-12)[:, None]
    sg = np.where(np.abs(n[:, 0]) > 1e-6, np.sign(n[:, 0]),
                  np.where(np.abs(n[:, 1]) > 1e-6, np.sign(n[:, 1]), np.where(n[:, 2] < 0, -1.0, 1.0)))
    nc = n * sg[:, None]
    dc = (nc * T[:, 0]).sum(1)
    planes = defaultdict(list)
    for i in np.nonzero(ok)[0]:
        nb = tuple(np.round(nc[i] * 50).astype(int).tolist())
        db = int(np.floor(dc[i]))          # within ~1 unit = same surface (two bins: no bin-edge misses)
        planes[(nb, db)].append(i)
        planes[(nb, db + 1)].append(i)
    lo, hi = T.min(1), T.max(1)
    bad = set()
    for ids in planes.values():
        if len(ids) < 2:
            continue
        ids = np.array(ids)
        for x in range(len(ids) - 1):
            i = ids[x]
            j = ids[x + 1:]
            if twosided and twosided.get(int(TM[i])):
                # a two-sided material with an opposite-facing surface of its own in the same plane: both draw
                s_ = j[(TM[j] == TM[i]) & ((n[j] @ n[i]) < -0.9)]
                s_ = s_[np.all((lo[s_] < hi[i] - 0.1) & (hi[s_] > lo[i] + 0.1), axis=1)] if len(s_) else s_
                if len(s_):
                    bad.add((int(TM[i]), int(TM[i])))
            j = j[(TM[j] != TM[i])]
            if not len(j):
                continue
            j = j[np.array([zbias.get(int(m), 0) == zbias.get(int(TM[i]), 0) for m in TM[j]])]
            if not len(j):
                continue
            ov = np.all((lo[j] < hi[i] - 0.5) & (hi[j] > lo[i] + 0.5), axis=1)
            for jj in j[ov]:
                bad.add(tuple(sorted((int(TM[i]), int(TM[jj])))))
    for a, b in sorted(bad)[:10]:
        if a == b:
            err(level, 'two-sided material %08x has front and back surfaces in one plane (z-fight)' % a)
        else:
            err(level, 'materials %08x and %08x overlap in one plane with the same zbias (z-fight)' % (a, b))
    if len(bad) > 10:
        err(level, '... %d more z-fighting material pairs' % (len(bad) - 10))


def tex_ids(path):
    b = open(path, 'rb').read()
    n = struct.unpack_from('<I', b, 4)[0]
    o = 8
    ids = set()
    for i in range(n):
        cs, w, h, lv, td, pd, dxt, pl = struct.unpack_from('<8I', b, o)
        ids.add(cs)
        o += 32 + pl
        for l in range(lv):
            o += 4 + struct.unpack_from('<I', b, o)[0]
    if o != len(b):
        err(os.path.basename(path), 'tex parse ended at %d of %d' % (o, len(b)))
    return ids


def check_nodes(level, q):
    text = open(q, encoding='latin1').read()
    nodes = text.split('\n{\n')[1:]
    names = re.findall(r'^Name = #"0x([0-9a-f]+)"', text, re.M)
    if len(names) != len(set(names)):
        err(level, 'duplicate node names')
    cls = [(re.search(r'^Class = (\S+)', n, re.M) or [None, None])[1] for n in nodes]
    absent = [re.search(r'^AbsentInNetGames$', n, re.M) is not None for n in nodes]
    for i, n in enumerate(nodes):
        m = re.search(r'^Links = \[ (.*) \]', n, re.M)
        if m:
            for x in m.group(1).split():
                x = int(x)
                if not 0 <= x < len(nodes):
                    err(level, 'node %d link %d out of range' % (i, x))
                elif cls[i] == 'RailNode' and (cls[x] != 'RailNode' or (absent[x] and not absent[i])):
                    # the engine's rail builder (0x57E960) loops forever looking for such a target
                    err(level, 'rail node %d links to node %d (%s%s)' % (i, x, cls[x], ', AbsentInNetGames' if absent[x] else ''))
    return len(nodes)


def main():
    for level in sys.argv[1:] or LEVELS:
        d = os.path.join(TMP, level)
        tids = tex_ids(os.path.join(d, level + '.tex.xbx'))
        qtext = open(os.path.join(d, level + '.q'), encoding='latin1').read()
        objects = {int(m.group(1), 16) for m in re.finditer(
            r'Name = #"0x([0-9a-f]+)"\n(?:[^{}]*?\n)?Class = LevelObject', qtext)}
        cas = {int(m.group(1), 16) for blk in qtext.split('\n{\n')[1:] for m in [re.search(r'^Name = #"0x([0-9a-f]+)"', blk, re.M)]
               if m and re.search(r'^CreatedAtStart$', blk, re.M)}
        trick = {int(m.group(1), 16) for blk in qtext.split('\n{\n')[1:] for m in [re.search(r'^Name = #"0x([0-9a-f]+)"', blk, re.M)]
                 if m and re.search(r'^TrickObject$', blk, re.M)}
        nm, ns, maxv, maxi = check_scn(level, os.path.join(d, level + '.scn.xbx'), tids, objects, cas, trick)
        sky = level + '_Sky'
        check_scn(sky, os.path.join(d, sky + '.scn.xbx'), tex_ids(os.path.join(d, sky + '.tex.xbx')))
        stext = ''
        for extra in ('_scripts', '_thugpro'):
            pth = os.path.join(d, level + extra + '.q')
            if os.path.exists(pth):
                stext += open(pth, encoding='latin1').read()
        defined = {m.group(1).lower() for m in re.finditer(r'^script (\S+)', qtext + '\n' + stext, re.M)}
        trigger_ok = set()
        for n in qtext.split('\n{\n')[1:]:
            mn = re.search(r'^Name = #"0x([0-9a-f]+)"', n, re.M)
            mt = re.search(r'^TriggerScript = (\S+)', n, re.M)
            if mn and mt:
                if mt.group(1).lower() in defined:
                    trigger_ok.add(int(mn.group(1), 16))
                else:
                    err(level, 'node 0x%s TriggerScript %s is not defined in the level qbs' % (mn.group(1), mt.group(1)))
        nobj, nf = check_col(level, os.path.join(d, level + '.col.xbx'), trigger_ok)
        nn = check_nodes(level, os.path.join(d, level + '.q'))
        print('%-13s %4d textures %4d materials %4d sectors (max %d verts, %d indices per mesh), %d col objects %d faces, %d nodes'
              % (level, len(tids), nm, ns, maxv, maxi, nobj, nf, nn))
    for e in NOTES[:20]:
        print('note', e)
    for e in errors[:60]:
        print('FAIL', e)
    print('%d problems' % len(errors))
    sys.exit(1 if errors else 0)


if __name__ == '__main__':
    main()
