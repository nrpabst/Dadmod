r"""Level select pictures for the extra levels (mods/menuui/userslots.q), shared by the client and the server build.

    python -I tools/levelthumbs.py <out folder>        (run from work/; the server build: build/obsspawn_test_make.sh)

Reads client/levelthumbs/levels.txt (<key> <level slot checksum>) and client/levelthumbs/<key>.png, and writes
  <out>/dadmod_levelselect.prx   images\dadmod\levelselect\dadmod_thumb_<key>.img.xbx (tools/img_xbx.py, like stock)
  <out>/levelthumbs.q            dadmod_levelthumb_for + dadmod_levelthumbs_load (see qb_text)
A level with no PNG is left out and keeps its stock picture. make_client.py uses archive() and qb_text() the same way.
"""
import os, sys

WORK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(WORK, 'tools'))
import img_xbx                               # noqa: E402
from prx_pack import write_archive, stored    # noqa: E402

LEVELTHUMBS = os.path.join(WORK, 'client', 'levelthumbs')


def _rows():
    out = []
    for ln in open(os.path.join(LEVELTHUMBS, 'levels.txt'), encoding='latin1').read().splitlines():
        ln = ln.strip()
        if ln and not ln.startswith('#'):
            out.append(ln.split())
    return out


def archive(dst):
    """dadmod_levelselect.prx -> [(key, level checksum)] of the levels that got a picture (no pictures: no archive)"""
    if os.path.isfile(dst):
        os.remove(dst)
    have, entries = [], []
    for key, level in _rows():
        png = os.path.join(LEVELTHUMBS, key + '.png')
        ready = os.path.join(LEVELTHUMBS, key + '.img.xbx')   # a ready-made image (THPG tab logo, work/thpg/tools/logo_img.py)
        if os.path.isfile(png):
            entries.append(stored('images\\dadmod\\levelselect\\dadmod_thumb_%s.img.xbx' % key, img_xbx.from_image(png)))
            have.append((key, level))
        elif os.path.isfile(ready):
            entries.append(stored('images\\dadmod\\levelselect\\dadmod_thumb_%s.img.xbx' % key, open(ready, 'rb').read()))
            have.append((key, level))
    if entries:
        os.makedirs(os.path.dirname(dst) or '.', exist_ok=True)
        write_archive(entries, dst)
    return have


def qb_text(have):
    """dadmod_levelthumb_for (create_thugpro_level_menu_item in userslots.q asks it for a level's picture) and
    dadmod_levelthumbs_load [unload] (loads dadmod_levelselect.pre the way stock loads thugpro_levelselect.pre).
    The client calls the load from its load_update_level_select_textures_to_main_memory wrap, the server build from
    dadmod_levelthumbs_boot (mods/menuui/levelthumbs.q, first main menu); the flag makes it load once."""
    q = ['dadmod_levelthumbs_loaded = 0', 'script dadmod_levelthumb_for', '    switch <level>']
    for key, level in have:
        q += ['    case %s' % level, '        return level_thumb = dadmod_thumb_%s' % key]
    q += ['    endswitch', 'endscript', 'script dadmod_levelthumbs_load']
    if have:
        tex = ' '.join('"dadmod/levelselect/dadmod_thumb_%s"' % k for k, _ in have)
        q += ['    if GotParam unload',
              '        if ( dadmod_levelthumbs_loaded = 0 )', '            return', '        endif',
              '        Change dadmod_levelthumbs_loaded = 0',
              '        load_array_of_textures pre_file = "dadmod_levelselect.pre" mem_context = BottomUpHeap unload textures = [ %s ]' % tex,
              '    else',
              '        if ( dadmod_levelthumbs_loaded = 1 )', '            return', '        endif',
              '        Change dadmod_levelthumbs_loaded = 1',
              '        load_array_of_textures pre_file = "dadmod_levelselect.pre" mem_context = BottomUpHeap textures = [ %s ]' % tex,
              '    endif']
    q += ['endscript']
    return '\n'.join(q) + '\n'


def main(argv):
    if len(argv) != 1:
        print(__doc__)
        return 2
    out = argv[0]
    os.makedirs(out, exist_ok=True)
    have = archive(os.path.join(out, 'dadmod_levelselect.prx'))
    open(os.path.join(out, 'levelthumbs.q'), 'w', encoding='latin1', newline='\n').write(qb_text(have))
    print('levelthumbs: %d level pictures (%s)' % (len(have), ' '.join(k for k, _ in have) or 'none'))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
