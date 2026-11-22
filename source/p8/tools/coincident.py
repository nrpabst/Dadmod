r"""Coincident surfaces that THUG Pro draws with an unstable winner (flicker), shared by p8conv (fixes them in
the P8 data) and validate_p8 (finds them in our written scenes).

Engine facts (THUG Pro exe): the material loader 0x4D3200 forces two_sided (mat+0xd) to 1 when single_sided is 0 and
pass 0 blends; 0x4D1F00 sets CULLMODE CW when two_sided is 0, NONE otherwise. So a material draws both sides
("effective two-sided") when two_sided, or (not single_sided and pass 0 blend != 0).

Each triangle is (scope, sector, mat, (p0, p1, p2), (c0, c1, c2), (uv0, uv1, uv2)); scope is None for world
geometry (all world sectors share one space) and the sector checksum for LevelObjects (local space).

    (a) back-to-back: the same three positions with reversed winding in one effective two-sided material, the two
        faces looking different (vertex colours or UVs) - both draw at one depth.
    (b) same-facing copies in one material (one sector or two) that look different.
    (c) same-facing coincident triangles of DIFFERENT materials (exact same three positions); reported only.
Identical copies (same material, facing, colours and UVs) draw identically and are harmless (stock keeps them).
"""


def effective_two_sided(two_sided, single_sided, blend0):
    return bool(two_sided) or (not single_sided and bool(blend0))


def _key(pts):
    rp = [tuple(round(x, 2) for x in p) for p in pts]
    i = rp.index(min(rp))
    rot = (rp[i], rp[(i + 1) % 3], rp[(i + 2) % 3])
    return tuple(sorted(rp)), rot


def _look(t):
    """{position: (colour, uv)} so two copies compare corner by corner whatever their winding"""
    return sorted((tuple(round(x, 2) for x in t[3][k]), bytes(t[4][k]), tuple(round(x, 3) for x in t[5][k]))
                  for k in range(3))


def find(tris, twosided):
    """-> dict(a=[(i, j)], b=[(i, j)], c=[(i, j)]) index pairs into tris (j is the later triangle)"""
    first = {}          # (scope, sorted positions) -> [(index, rotation)]
    out = dict(a=[], b=[], c=[])
    for i, t in enumerate(tris):
        k, rot = _key(t[3])
        lst = first.setdefault((t[0], k), [])
        for j, rj in lst:
            u = tris[j]
            if u[2] == t[2]:
                if rj == rot:
                    if _look(u) != _look(t):
                        out['b'].append((j, i))
                elif twosided.get(t[2]) and _look(u) != _look(t):
                    out['a'].append((j, i))
            elif rj == rot:
                out['c'].append((j, i))
        lst.append((i, rot))
    return out


def _inside(p, a, b, c, eps=1e-3):
    v0 = [c[k] - a[k] for k in range(3)]
    v1 = [b[k] - a[k] for k in range(3)]
    v2 = [p[k] - a[k] for k in range(3)]
    dot = lambda x, y: x[0] * y[0] + x[1] * y[1] + x[2] * y[2]
    d00, d01, d11, d20, d21 = dot(v0, v0), dot(v0, v1), dot(v1, v1), dot(v2, v0), dot(v2, v1)
    den = d00 * d11 - d01 * d01
    if abs(den) < 1e-12:
        return False
    u = (d11 * d20 - d01 * d21) / den
    w = (d00 * d21 - d01 * d20) / den
    return u >= eps and w >= eps and u + w <= 1 - eps


def find_retriangulated(tris, shown, trick=frozenset()):
    """(d) the same surface twice in one material, in two different world sectors that are both shown at start
    (shown: set of sector checksums, None = all), at the very same vertex positions but triangulated differently
    and shaded differently (P8 Downtown's awnings: the building's copy and a TrickObject copy). Both draw at one
    depth -> the two shadings fight. Returns indices into tris of the copy to drop, per (material, sector pair):
    the TrickObject copy (as THUG Pro's own z_center leaves out its TrickObject copies), else the later sector.
    A triangle counts only when all three corners exist in the other copy and its centre lies on it (no holes)."""
    import numpy as np
    from collections import defaultdict
    by = defaultdict(lambda: defaultdict(list))        # mat -> sector -> [index]
    order = {}
    for i, t in enumerate(tris):
        if t[0] is not None or (shown is not None and t[1] not in shown):
            continue
        by[t[2]][t[1]].append(i)
        order.setdefault(t[1], i)
    out = []
    rp = lambda p: tuple(round(x, 2) for x in p)
    for mat, secs in by.items():
        if len(secs) < 2:
            continue
        info = {}
        for sc, ids in secs.items():
            col = {}
            for i in ids:
                for k in range(3):
                    col[rp(tris[i][3][k])] = bytes(tris[i][4][k])
            info[sc] = col
        names = sorted(secs, key=lambda s: order[s])
        for x in range(len(names)):
            for y in range(x + 1, len(names)):
                a, b = names[x], names[y]
                common = set(info[a]) & set(info[b])
                if len(common) < 3 or all(info[a][p] == info[b][p] for p in common):
                    continue                            # no shared surface, or shaded the same: harmless
                drop, keep = (a, b) if a in trick and b not in trick else (b, a)
                kt = [tris[i][3] for i in secs[keep]]
                kn = []
                for p in kt:
                    n = np.cross(np.subtract(p[1], p[0]), np.subtract(p[2], p[0]))
                    ln = np.linalg.norm(n)
                    kn.append(n / ln if ln > 1e-9 else n)
                for i in secs[drop]:
                    p = tris[i][3]
                    if not all(rp(q) in common for q in p):
                        continue
                    n = np.cross(np.subtract(p[1], p[0]), np.subtract(p[2], p[0]))
                    ln = np.linalg.norm(n)
                    if ln < 1e-9:
                        continue
                    n = n / ln
                    cen = [(p[0][k] + p[1][k] + p[2][k]) / 3 for k in range(3)]
                    if any(float(n @ kn[j]) > 0.99 and _inside(cen, *kt[j]) for j in range(len(kt))):
                        out.append(i)
    return out


def find_sunk(tris, blended, tol=0.5, eps=0.02):
    """(f) blended decals sunk under the opaque surface they cover: a blended world face whose centre lies on an
    opaque same-facing face's area but 0.02..0.5 units BEHIND its plane (P8 Downtown's shadow decals: the awning
    shadow acd48f32 sits up to 0.3 under the pavement). The engine's material zbias depth bias (-2e-6 per step)
    only wins over a coplanar surface, so a sunk decal shows through in patches that change as the camera moves.
    Stock City Center has one such face. -> [(i, j, depth)] (i sunk under j by depth > 0)."""
    import numpy as np
    from collections import defaultdict
    ids = [k for k, t in enumerate(tris) if t[0] is None]
    if not ids:
        return []
    A = np.array([tris[k][3] for k in ids], dtype=float)
    n = np.cross(A[:, 1] - A[:, 0], A[:, 2] - A[:, 0])
    ln = np.linalg.norm(n, axis=1)
    ok = ln > 1e-6
    n[ok] /= ln[ok, None]
    d = (n * A[:, 0]).sum(1)
    cen = A.mean(1)
    lo, hi = A.min(1) - 0.5, A.max(1) + 0.5
    bl = np.array([bool(blended(tris[k][2])) for k in ids])
    cell = 64.0
    grid, big = defaultdict(list), []
    for a in np.where(ok & ~bl)[0]:                 # opaque faces are the bases
        x0, x1 = int(lo[a][0] // cell), int(hi[a][0] // cell)
        z0, z1 = int(lo[a][2] // cell), int(hi[a][2] // cell)
        if (x1 - x0 + 1) * (z1 - z0 + 1) > 1024:
            big.append(a)
            continue
        for x in range(x0, x1 + 1):
            for z in range(z0, z1 + 1):
                grid[(x, z)].append(a)
    big = np.array(big, dtype=int)
    grid = {k: np.array(v) for k, v in grid.items()}
    v0, v1 = A[:, 2] - A[:, 0], A[:, 1] - A[:, 0]
    d00, d01, d11 = (v0 * v0).sum(1), (v0 * v1).sum(1), (v1 * v1).sum(1)
    den = d00 * d11 - d01 * d01
    out = []
    for a in np.where(ok & bl)[0]:
        c = cen[a]
        cand = grid.get((int(c[0] // cell), int(c[2] // cell)))
        if len(big):
            cand = big if cand is None else np.concatenate([cand, big])
        if cand is None:
            continue
        dd = n[cand] @ c - d[cand]
        m = (n[cand] @ n[a] >= 0.99) & (dd <= -eps) & (dd >= -tol)
        m &= np.all((c >= lo[cand]) & (c <= hi[cand]), axis=1)
        cand, dd = cand[m], dd[m]
        if not len(cand):
            continue
        p = c - dd[:, None] * n[cand]               # centre projected onto each base plane
        v2 = p - A[cand, 0]
        d20, d21 = (v2 * v0[cand]).sum(1), (v2 * v1[cand]).sum(1)
        dn = np.where(np.abs(den[cand]) < 1e-12, np.nan, den[cand])
        u = (d11[cand] * d20 - d01[cand] * d21) / dn
        w = (d00[cand] * d21 - d01[cand] * d20) / dn
        hit = (u >= -1e-3) & (w >= -1e-3) & (u + w <= 1 + 1e-3)
        if hit.any():
            k = np.argmin(np.where(hit, dd, np.inf))
            out.append((ids[a], ids[cand[k]], float(-dd[k])))
    return out


def find_unstable(tris, mkey):
    """(e) same-facing coplanar overlaps with no stable winner: triangle i's centre lies on triangle j (same plane
    within 0.3, same facing), both world geometry (scope None), and neither the material sort key (sorted, draw
    order, zbias: mkey(mat)) nor identity settles it - different materials with equal keys, or the same material
    with different shading. Faces triangulated differently give per-pixel depth noise, so draw order alone
    doesn't help. -> [(i, j)] (i covered by j)."""
    import numpy as np
    from collections import defaultdict
    ids = [k for k, t in enumerate(tris) if t[0] is None]
    if not ids:
        return []
    A = np.array([tris[k][3] for k in ids], dtype=float)
    n = np.cross(A[:, 1] - A[:, 0], A[:, 2] - A[:, 0])
    ln = np.linalg.norm(n, axis=1)
    ok = ln > 1e-6
    n[ok] /= ln[ok, None]
    d = (n * A[:, 0]).sum(1)
    cen = A.mean(1)
    lo, hi = A.min(1) - 0.5, A.max(1) + 0.5
    cell = 64.0
    grid = defaultdict(list)
    big = []            # faces spanning more than 32x32 cells (sky domes, huge ground) are checked against every face
    for a in np.where(ok)[0]:
        x0, x1 = int(lo[a][0] // cell), int(hi[a][0] // cell)
        z0, z1 = int(lo[a][2] // cell), int(hi[a][2] // cell)
        if (x1 - x0 + 1) * (z1 - z0 + 1) > 1024:
            big.append(a)
            continue
        for x in range(x0, x1 + 1):
            for z in range(z0, z1 + 1):
                grid[(x, z)].append(a)
    big = np.array(big, dtype=int)
    grid = {k: np.array(v) for k, v in grid.items()}
    # barycentric precompute
    v0, v1 = A[:, 2] - A[:, 0], A[:, 1] - A[:, 0]
    d00, d01, d11 = (v0 * v0).sum(1), (v0 * v1).sum(1), (v1 * v1).sum(1)
    den = d00 * d11 - d01 * d01
    out = []
    for a in np.where(ok)[0]:
        c = cen[a]
        cand = grid.get((int(c[0] // cell), int(c[2] // cell)))
        if len(big):
            cand = big if cand is None else np.sort(np.concatenate([cand, big]))   # keep index order
        if cand is None:
            continue
        cand = cand[cand != a]
        m = (n[cand] @ n[a] >= 0.99) & (np.abs(n[cand] @ c - d[cand]) <= 0.3)
        m &= np.all((c >= lo[cand]) & (c <= hi[cand]), axis=1)
        cand = cand[m]
        if not len(cand):
            continue
        v2 = c - A[cand, 0]
        d20, d21 = (v2 * v0[cand]).sum(1), (v2 * v1[cand]).sum(1)
        dn = np.where(np.abs(den[cand]) < 1e-12, np.nan, den[cand])
        u = (d11[cand] * d20 - d01[cand] * d21) / dn
        w = (d00[cand] * d21 - d01[cand] * d20) / dn
        cand = cand[(u >= 1e-3) & (w >= 1e-3) & (u + w <= 1 - 1e-3)]
        i = ids[a]
        for b in cand:
            j = ids[b]
            mi, mj = tris[i][2], tris[j][2]
            if mi != mj:
                if mkey(mi) != mkey(mj):
                    continue
            elif sorted(map(bytes, tris[i][4])) == sorted(map(bytes, tris[j][4])):
                continue
            out.append((i, j))
            break
    return out
