"""Finds the bulb(s) of every lamp in the v2 lamp plan (work/docs/lamp_lights_plan/v2_sure/<level>.csv) from the
lamp's collision vertices, and writes:
  - work/docs/lamp_lights_plan/v3_heads/lamplights.txt   per level: "bulb kind x y z" and "pool kind x y z radius"
  - work/docs/lamp_lights_plan/v3_heads/<level>.png       top-down map with lamps and bulbs
  - work/docs/lamp_lights_plan/v3_heads/<level>_side.png  side views of a few lamps with the found bulbs marked
  - work/docs/lamp_lights_plan/v3_heads/heads.csv + summary.txt
Coordinates are game world coordinates (= collision file coordinates; NodeArray "position" has z flipped).
Run from work:  python -I mods/lamplights/gen_lampheads.py <level> [<level>...]   (pictures + lists go to v3_heads/<level>/)
"""
import os, re, sys, csv, math, glob
sys.path.insert(0, 'tools'); sys.path.insert(0, 'p8/tools')
from qb import qbkey
import prx_extract, colparse
import numpy as np
from PIL import Image, ImageDraw, ImageFont

PRE = '../THUG Pro Kali v2 - 1.2 Dev/data/pre'
PLAN = 'docs/lamp_lights_plan/v2_sure'
OUT0 = 'docs/lamp_lights_plan/v3_heads'
OUT = OUT0
LAMPNAME = re.compile(r'spot_?light|flood_?light|lamp|streetlight|street_light|light_?pole|light_?post|lite_?post|globe_?light|lantern|street_?lite|lamppost', re.I)
NOTLAMP = re.compile(r'shad|coll|beam|flare|traf|halo|cone|wire|trg|rail|gap|trigger|_col\b|desk|table|floor_?lamp|lavalamp|ped_|veh_|cam', re.I)
POOL = {'street': 450, 'short': 300, 'indoor': 320, 'flood': 550, 'lantern': 260}
KC = {'street': (255, 190, 70), 'short': (255, 120, 200), 'indoor': (120, 230, 120), 'flood': (120, 200, 255), 'lantern': (255, 90, 60)}


def colfile(lvl):
    for f in os.listdir(PRE):
        if f.lower() in (lvl + 'col.prx', lvl + 'col_thugpro.prx'):
            return os.path.join(PRE, f)


def level_q(lvl):
    for q in glob.glob('decompiled/**/*.q', recursive=True):
        d = os.path.basename(os.path.dirname(q)).lower()
        if d == lvl and os.path.splitext(os.path.basename(q))[0].lower() == lvl and \
                os.path.basename(os.path.dirname(os.path.dirname(q))).lower() == 'levels':
            return q


def cluster(pts, gap):
    """single-link clusters of 2D points (horizontal)"""
    n = len(pts); lab = [-1] * n; k = 0
    for i in range(n):
        if lab[i] >= 0: continue
        lab[i] = k; st = [i]
        while st:
            j = st.pop()
            for m in range(n):
                if lab[m] < 0 and math.hypot(pts[m][0] - pts[j][0], pts[m][1] - pts[j][1]) < gap:
                    lab[m] = k; st.append(m)
        k += 1
    return [[pts[i] for i in range(n) if lab[i] == c] for c in range(k)]


def heads(kind, V):
    """V: fixture vertices (x,y,z). Returns (bulbs [(x,y,z)], pool (x,y,z), note)"""
    V = np.array(V)
    top, bot = V[:, 1].max(), V[:, 1].min(); h = top - bot
    low = V[V[:, 1] < bot + max(30, 0.3 * h)]
    ax, az = np.median(low[:, 0]), np.median(low[:, 2])  # pole / base axis
    note = ''
    if kind == 'indoor':
        # hanging lamp: bulb just under the fixture's lowest part
        b = V[V[:, 1] < bot + 15]
        return [(b[:, 0].mean(), bot - 6, b[:, 2].mean())], (ax, bot - 250, az), note
    band = max(25, min(130, 0.15 * h))
    up = V[V[:, 1] > top - band]
    d = np.hypot(up[:, 0] - ax, up[:, 2] - az)
    reach = d.max()
    if kind == 'street' and reach > 70:
        # arms: outermost clusters of the top band; bulb under the middle of the head panel at each tip
        far = up[d > reach * 0.55]
        cl = cluster([(p[0], p[2], p[1]) for p in far], 45)
        bulbs = []
        for c in cl:
            c = np.array(c)
            cd = np.hypot(c[:, 0] - ax, c[:, 1] - az)
            tip = c[cd > cd.max() - 60]  # last ~60 units of the arm = the head
            bulbs.append((tip[:, 0].mean(), tip[:, 2].min() - 5, tip[:, 1].mean()))
        if len(bulbs) not in (1, 2, 3, 4): note = f'{len(bulbs)} arm tips'
        if len(bulbs) > 4: bulbs = bulbs[:4]
        gy = bot
        return bulbs, (ax, gy + 150, az), note
    if kind in ('street', 'lantern', 'flood'):
        # globe / single head on top: bulb just under the top
        if kind == 'street' and h < 150: note = 'short street lamp'
        return [(up[:, 0].mean(), top - min(25, 0.2 * band + 10), up[:, 2].mean())], (ax, bot + 150, az), note
    # short / wall lamp: top of the fixture, centered on its top part
    return [(up[:, 0].mean(), top - 10, up[:, 2].mean())], (ax, bot + 100, az), note


def main():
    rows_out = []; summary = []; txt = ['; lamp bulbs + light pools per level (work/mods/lamplights/gen_lampheads.py).',
                                         '; world coordinates. bulb <kind> x y z   |   pool <kind> x y z radius']
    try: font = ImageFont.truetype('DejaVuSans-Bold.ttf', 15)
    except Exception: font = ImageFont.load_default()
    global OUT
    for lvl in sys.argv[1:]:
        plan = os.path.join(PLAN, lvl + '.csv')
        OUT = os.path.join(OUT0, lvl); os.makedirs(OUT, exist_ok=True)
        prx, q = colfile(lvl), level_q(lvl)
        if not prx or not q: print('skip', lvl); continue
        data = [d for n, c, d, u in prx_extract.entries(prx) if n.lower().endswith('.col.xbx')][0]
        s = colparse.sections(data, 0x20)
        objs = {o['cs']: o for o in s['objs']}
        names = set(re.findall(r'\bName = (\S+)', open(q, encoding='latin1').read()))
        lampobjs = []
        for nm in names:
            if not LAMPNAME.search(nm) or NOTLAMP.search(nm): continue
            o = objs.get(qbkey(nm))
            if not o: continue
            try: v = colparse.obj_verts(s, o)
            except Exception: continue
            lampobjs.append((nm, o, [tuple(p) for p in v]))
        plan_rows = list(csv.DictReader(open(plan)))
        txt.append(f'[{lvl}]')
        lvl_rows = []
        for r in plan_rows:
            x, y, z = float(r['x']), float(r['y']), float(r['z']); kind = r['kind']
            top = y + 20
            V = []; parts = []
            for nm, o, v in lampobjs:
                cx = (o['bmin'][0] + o['bmax'][0]) / 2; cz = (o['bmin'][2] + o['bmax'][2]) / 2
                if math.hypot(cx - x, cz - z) < 200 and abs(o['bmax'][1] - top) < 400:
                    V += v; parts.append(nm)
            if not V:
                note = 'no collision'; bulbs = [(x, y, z)]; pool = (x, y - 300, z)
            else:
                bulbs, pool, note = heads(kind, V)
            pr = POOL[kind]
            for b in bulbs: txt.append(f'bulb {kind} {b[0]:.0f} {b[1]:.0f} {b[2]:.0f}')
            txt.append(f'pool {kind} {pool[0]:.0f} {pool[1]:.0f} {pool[2]:.0f} {pr}')
            if V:
                VV = np.array(V); top_, bot_ = VV[:, 1].max(), VV[:, 1].min()
            else:
                top_, bot_ = y + 20, y - 300
            reach = max(350, min(950, (top_ - bot_) * 1.5))
            row = dict(light_pos=(pool[0], top_ - 60, pool[2]), reach=reach, level=lvl, light=r['light'], kind=kind, obj=r['lamp object'], bulbs=len(bulbs), note=note,
                       heads=' '.join(f'({b[0]:.0f},{b[1]:.0f},{b[2]:.0f})' for b in bulbs), V=V, B=bulbs, P=pool, x=x, z=z)
            lvl_rows.append(row); rows_out.append(row)
        nb = sum(r['bulbs'] for r in lvl_rows); unsure = [r for r in lvl_rows if r['note']]
        summary.append(f'{lvl}: {len(lvl_rows)} lamps, {nb} bulbs, {len(unsure)} unsure' +
                       ''.join(f'\n    #{r["light"]} {r["kind"]} {r["obj"]}: {r["note"]}' for r in unsure))
        draw_map(lvl, s, lvl_rows, font)
        draw_side(lvl, lvl_rows, font)
    open(os.path.join(OUT, 'lamplights.txt'), 'w', newline='\r\n').write('\n'.join(txt) + '\n')
    with open(os.path.join(OUT, 'heads.csv'), 'w', newline='') as f:
        w = csv.writer(f); w.writerow(['level', 'light', 'kind', 'lamp object', 'bulbs', 'bulb positions', 'note'])
        for r in rows_out: w.writerow([r['level'], r['light'], r['kind'], r['obj'], r['bulbs'], r['heads'], r['note']])
    open(os.path.join(OUT, 'summary.txt'), 'w').write('\n'.join(summary) + '\n')
    print('\n'.join(summary))
    # game data: mods/lamplights/data/lamps_<level>.q (appended to dadmod_cars.qb by the make script)
    os.makedirs('mods/lamplights/data', exist_ok=True)
    for lvl in sys.argv[1:]:
        lr = [r for r in rows_out if r['level'] == lvl]
        q = [f'dadmod_lamps_{lvl} = [']
        for i, r in enumerate(lr):
            pr = POOL[r["kind"]]
            bl = ' '.join('{ Pos = (%.1f,%.1f,%.1f) }' % (b[0], b[1], b[2]) for b in r['B'])
            lp = r['light_pos']
            q.append('{ id = %d light = (%.1f,%.1f,%.1f) reach = %.1f pool = (%.1f,%.1f,%.1f) poolr = %d bulbs = [ %s ] }' % (
                i + 1, lp[0], lp[1], lp[2], r['reach'], r['P'][0], r['P'][1], r['P'][2], pr * (1.15 if len(r['B']) > 1 else 1.0), bl))
        q.append(']')
        open(f'mods/lamplights/data/lamps_{lvl}.q', 'w', newline='\n').write('\n'.join(q) + '\n')


def draw_map(lvl, s, rows, font):
    tris = []
    for o in s['objs']:
        try:
            v = colparse.obj_verts(s, o)
            for fl, tt, vi in colparse.obj_faces(s, o):
                if max(vi) < len(v): tris.append((v[vi[0]], v[vi[1]], v[vi[2]]))
        except Exception: pass
    A = np.array(tris)
    xs, zs, ys = A[..., 0], A[..., 2], A[..., 1]
    x0, x1 = np.percentile(xs, 0.5), np.percentile(xs, 99.5); z0, z1 = np.percentile(zs, 0.5), np.percentile(zs, 99.5)
    for r in rows:
        for b in r['B']: x0 = min(x0, b[0]); x1 = max(x1, b[0]); z0 = min(z0, b[2]); z1 = max(z1, b[2])
    S = 1800 / max(x1 - x0, z1 - z0); W = int((x1 - x0) * S) + 80; H = int((z1 - z0) * S) + 80
    img = Image.new('RGB', (W, H), (18, 20, 26)); dr = ImageDraw.Draw(img)
    y0, y1 = np.percentile(ys, 2), np.percentile(ys, 98)
    for i in np.argsort(A[..., 1].mean(1)):
        tr = A[i]; c = int(60 + 150 * np.clip((tr[:, 1].mean() - y0) / (y1 - y0 + 1e-6), 0, 1))
        dr.polygon([((p[0] - x0) * S + 40, (p[2] - z0) * S + 40) for p in tr], fill=(c, c, c + 8))
    for r in rows:
        px, pz = (r['P'][0] - x0) * S + 40, (r['P'][2] - z0) * S + 40; rad = POOL[r['kind']] * S
        dr.ellipse((px - rad, pz - rad, px + rad, pz + rad), outline=KC[r['kind']])
        for b in r['B']:
            bx, bz = (b[0] - x0) * S + 40, (b[2] - z0) * S + 40
            dr.ellipse((bx - 4, bz - 4, bx + 4, bz + 4), fill=(255, 176, 80), outline=(0, 0, 0))
        col = (255, 60, 60) if r['note'] else (255, 255, 255)
        dr.text((px + 7, pz - 8), r['light'], fill=col, font=font, stroke_width=2, stroke_fill=(0, 0, 0))
    dr.text((10, 8), f'{lvl}: {len(rows)} lamps, {sum(r["bulbs"] for r in rows)} bulbs (amber dots), circle = light pool. '
            'red number = unsure', fill=(255, 255, 255), font=font)
    img.save(os.path.join(OUT, f'{lvl}.png'))


def draw_side(lvl, rows, font):
    pick = []
    for kind in ('street', 'short', 'indoor', 'flood', 'lantern'):
        k = [r for r in rows if r['kind'] == kind and r['V']]
        if k: pick.append(k[0])
        if len(k) > 1 and k[-1] is not k[0]: pick.append(k[-1])
    pick += [r for r in rows if r['note'] and r['V'] and r not in pick][:3]
    pick = pick[:6]
    if not pick: return
    cw, ch = 420, 420
    img = Image.new('RGB', (cw * len(pick), ch + 30), (18, 20, 26)); dr = ImageDraw.Draw(img)
    for i, r in enumerate(pick):
        V = np.array(r['V'])
        # side view along the direction the lamp is widest in (x or z)
        hor = 0 if np.ptp(V[:, 0]) >= np.ptp(V[:, 2]) else 2
        h0, h1 = V[:, hor].min(), V[:, hor].max(); v0, v1 = V[:, 1].min(), V[:, 1].max()
        S = (min(cw, ch) - 60) / max(h1 - h0, v1 - v0, 1)
        ox = i * cw + cw / 2 - (h0 + h1) / 2 * S; oy = ch - 20 + v0 * S
        for p in V: dr.point((ox + p[hor] * S, oy - p[1] * S), fill=(170, 170, 180))
        for b in r['B']:
            bx, by = ox + b[hor] * S, oy - b[1] * S
            dr.ellipse((bx - 6, by - 6, bx + 6, by + 6), outline=(255, 176, 80), width=3)
        dr.text((i * cw + 8, ch + 6), f'#{r["light"]} {r["kind"]} {r["obj"][:22]} {r["note"]}', fill=(255, 255, 255), font=font)
    img.save(os.path.join(OUT, f'{lvl}_side.png'))


main()
