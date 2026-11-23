r"""Lit windows (mods/lamplights): the window textures of a level, picked by hand from the level's texture sheet,
written as dadmod\lampwindows.txt lines the DLL can match against the game's own Direct3D textures:
    <level> <width> <height> <dxt> <fnv1a of the first 128 bytes of mip 0>   ; <texture checksum>
Run from work:  python -I mods/lamplights/gen_windows.py   (writes mods/lamplights/data/lampwindows.txt)
"""
import os, sys
sys.path.insert(0, 'tools')
import io, random
import prx_extract, texxbx
import numpy as np
from PIL import Image

PRE = '../THUG Pro Kali v2 - 1.2 Dev/data/pre'
# hof (Chicago): building fronts and windows (2026-11-22, from the 308-texture sheet; shop shutters/doors left out)
WINDOWS = {
    'hof': '041e03e8 09d7166c 13a3ee7c 14735660 18ae8790 18e16ba0 2ad1fde4 3361c724 3b5d7a88 3d8e16e8 40d52038 '
           '4d4c8b94 6668a7f4 6ab60e0c 7153aff8 9e9b5330 a6d91f50 affb6264 b37c3d18 b738dba0 bd7be184 c0fa7558 '
           'c1b06c10 c637687c c8f503d8 d2bf26e4 d3cb5e94 d4776d70 d7355e40 d8496fd8 f2c99064 f2c9e6fc fd927680',
    # sf2 (San Francisco): building fronts, blinds and shop windows (2026-11-23, panes in windows_sf2.txt)
    'sf2': '47ed2014 ded1d28c 51b9eb28 826d5b14 772c4fd4 7f0cbd00 e3b33088 19f1248c 48de5498 daf3d124 b68d9bb4 414c721c 1cf40044 0609731c 105c26b8 588d83f0 79c37670 43c1b898 969f73d8 c5d03c44 4e7eca3c 6c906ff0 22f41914 d3d0f098 443e1ddc 024398ac 9dd81be0 eb03e0e0 c44ff5e0 12c24364 6ba1a9d0 fca931c0 9916bbc8 42005af0',
}


def fnv(b):
    h = 0x811C9DC5
    for x in b:
        h = ((h ^ x) * 0x01000193) & 0xFFFFFFFF
    return h


def read_panes(lvl):
    """mods/lamplights/windows_<lvl>.txt: per texture checksum, pane rectangles (tenths of the texture) or a grid"""
    out = {}
    path = f'mods/lamplights/windows_{lvl}.txt'
    if not os.path.exists(path): return out
    for line in open(path):
        line = line.split(';')[0].strip()
        if not line: continue
        ck, rest = line.split(None, 1)
        rects = []
        if rest.startswith('grid'):
            xs, ys = rest[4:].split('/')
            rng = lambda t: [tuple(float(v) / 10 for v in r.split('-')) for r in t.split()]
            for (y0, y1) in rng(ys):
                for (x0, x1) in rng(xs): rects.append((x0, y0, x1, y1))
        else:
            for part in rest.split('|'):
                v = [float(x) / 10 for x in part.split()]
                rects.append(tuple(v))
        out[int(ck, 16)] = rects
    return out


def write_mask(t, hsh, rects, sheet_items):
    # one byte per texel: 0 = not a window, 1..255 = which pane (the shader lights or darkens a whole pane)
    W, H = t.width, t.height
    lab = np.zeros((H, W), np.uint8)
    rnd = random.Random(hsh)
    for (x0, y0, x1, y1) in rects:
        lab[int(round(y0 * H)):int(round(y1 * H)), int(round(x0 * W)):int(round(x1 * W))] = rnd.randint(1, 255)
    os.makedirs('mods/lamplights/data/lampwindows', exist_ok=True)
    open(f'mods/lamplights/data/lampwindows/{hsh:08x}.raw', 'wb').write(lab.tobytes())
    sheet_items.append((t, rects))


def contact_sheet(lvl, items):
    from PIL import ImageDraw
    D = 256; cols = 6
    rows = (len(items) + cols - 1) // cols
    sheet = Image.new('RGB', (cols * (D + 8), rows * (D + 22)), (0, 0, 0)); d = ImageDraw.Draw(sheet)
    for k, (t, rects) in enumerate(items):
        img = Image.open(io.BytesIO(texxbx.to_dds(t))).convert('RGB').resize((D, D))
        x = (k % cols) * (D + 8); y = (k // cols) * (D + 22)
        sheet.paste(img, (x, y))
        for (x0, y0, x1, y1) in rects:
            d.rectangle((x + x0 * D, y + y0 * D, x + x1 * D - 1, y + y1 * D - 1), outline=(255, 176, 60), width=2)
        d.text((x + 2, y + D + 4), f'{t.checksum:08x}  {len(rects)} panes', fill=(255, 255, 255))
    os.makedirs(f'docs/lamp_lights_plan/windows_{lvl}', exist_ok=True)
    sheet.save(f'docs/lamp_lights_plan/windows_{lvl}/panes_{lvl}.png')


def main():
    out = ['; lit windows (mods/lamplights/gen_windows.py): level width height dxt hash   ; texture checksum']
    for lvl, ids in WINDOWS.items():
        want = {int(x, 16) for x in ids.split()}
        prx = os.path.join(PRE, lvl.upper() + 'scn.prx')
        data = [d for n, c, d, u in prx_extract.entries(prx) if n.lower().endswith(f'{lvl}.tex.xbx')][0]
        tmp = os.path.join(os.environ.get('TEMP', '.'), f'_{lvl}_win.tex.xbx')
        open(tmp, 'wb').write(data)
        _, texs, _ = texxbx.read(tmp)
        os.remove(tmp)
        found = 0
        panes = read_panes(lvl); items = []
        for t in texs:
            if t.checksum in want and t.mips:
                hsh = fnv(t.mips[0][:128])
                out.append(f'{lvl} {t.width} {t.height} {t.dxt} {hsh:08x}   ; {t.checksum:08x}')
                if t.checksum in panes: write_mask(t, hsh, panes[t.checksum], items)
                found += 1
        print(f'{lvl}: {found} of {len(want)} window textures, {len(items)} with marked panes')
        contact_sheet(lvl, items)
    os.makedirs('mods/lamplights/data', exist_ok=True)
    open('mods/lamplights/data/lampwindows.txt', 'w', newline='\r\n').write('\n'.join(out) + '\n')


main()
