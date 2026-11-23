"""Put a built release into a clone of the public Dadmod repo as release/ (the publish workflow's input).

    python -I client/tools/stage_release.py <release dir> <Dadmod clone> [--notes notes.md] [--push-maps]

<release dir> = build/release_<ver> from make_client.py --package: dadmod.zip, map_packs.txt, dadmod-maps-*.zip.
Writes release/VERSION, dadmod.zip.partNN + .md5, map_packs.txt, notes.md. Noah 2026-11-23: a map pack the newest
public release already carries (same name and size) is NOT pushed again; the workflow copies it over from that
release after checking its md5. --push-maps pushes every pack anyway.
"""
import hashlib, json, os, shutil, sys, urllib.request

PIECE = 90_000_000
REPO = 'nrpabst/Dadmod'


def split(src, dst_dir):
    names = []
    with open(src, 'rb') as f:
        n = 0
        while True:
            b = f.read(PIECE)
            if not b:
                break
            name = '%s.part%02d' % (os.path.basename(src), n)
            open(os.path.join(dst_dir, name), 'wb').write(b)
            names.append(name)
            n += 1
    return names


def published_assets():
    req = urllib.request.Request('https://api.github.com/repos/%s/releases/latest' % REPO,
                                 headers={'User-Agent': 'dadmod-stage', 'Accept': 'application/vnd.github+json'})
    try:
        rel = json.load(urllib.request.urlopen(req, timeout=20))
    except Exception as e:
        print('could not read the newest release (%s): every map pack is pushed' % e)
        return {}
    return {a['name']: a['size'] for a in rel.get('assets', [])}


def main(argv):
    if len(argv) < 2:
        sys.exit(__doc__)
    rel_dir, clone = argv[0], argv[1]
    notes = argv[argv.index('--notes') + 1] if '--notes' in argv else None
    push_all = '--push-maps' in argv
    ver = open(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'VERSION')).read().strip()
    out = os.path.join(clone, 'release')
    if os.path.isdir(out):
        shutil.rmtree(out)
    os.makedirs(out)
    z = os.path.join(rel_dir, 'dadmod.zip')
    split(z, out)
    open(os.path.join(out, 'dadmod.zip.md5'), 'w').write(hashlib.md5(open(z, 'rb').read()).hexdigest() + '\n')
    have = {} if push_all else published_assets()
    mp = os.path.join(rel_dir, 'map_packs.txt')
    rows = [l.split() for l in open(mp) if l.strip()]
    for pack, asset, size, md5 in rows:
        src = os.path.join(rel_dir, asset)
        if hashlib.md5(open(src, 'rb').read()).hexdigest() != md5 or os.path.getsize(src) != int(size):
            sys.exit('STAGE FAILED: %s does not match map_packs.txt' % asset)
        if have.get(asset) == int(size):
            print('%s: unchanged, the workflow copies it from the newest release' % asset)
        else:
            print('%s: pushed (%d pieces)' % (asset, len(split(src, out))))
    shutil.copyfile(mp, os.path.join(out, 'map_packs.txt'))
    if notes:
        shutil.copyfile(notes, os.path.join(out, 'notes.md'))
    open(os.path.join(out, 'VERSION'), 'w').write(ver + '\n')
    print('staged dadmod %s in %s' % (ver, out))


if __name__ == '__main__':
    main(sys.argv[1:])
