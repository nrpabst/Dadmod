"""Mid-game Load Skater (mods/midload): the "unsaved changes" hooks.

    python -I mods/midload/apply.py <server build mod tree>     (build/obsspawn_test_make.sh, server build)
    python -I mods/midload/apply.py --casidle <casidle .q file>  (both builds, Edit Skater qb text before compiling)

Server build: inserts one call at the top of each hooked stock script in the build tree (copying the stock file
from decompiled/thugpro_qb first when the tree doesn't carry it). The client build wraps the same scripts instead
(client/wrap.txt + client/qb/dadmod/midload.q), so PRX_MARK / PRX_IO there must stay in step with this file.
Edit Skater (data/dadmod_casidle.qb, our casmod scripts): marks are inserted into the commit scripts, and the three
stock-only pages (Pre-made Skaters, Information, Face Mapping) mark when they are opened.
"""
import os, re, sys

WORK = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
KALI = os.path.join(WORK, 'decompiled', 'thugpro_qb', 'qb')

MARK = '    dadmod_midload_mark'
IO = '    dadmod_midload_io <...>'
# stock prx script -> file under qb/ (stats + trick edits mark, a skater save or load clears)
PRX_MARK = {
    'stat_menu_change_stat': 'game/menu/gamemenu_stats.q',
    'edit_tricks_menu_bind_trick': 'game/menu/edit_tricks_menu.q',
    'edit_tricks_menu_unassign_trick': 'game/menu/edit_tricks_menu.q',
    'special_tricks_menu_select_trick': 'game/menu/edit_tricks_menu.q',
    'special_tricks_menu_select_key_combo': 'game/menu/edit_tricks_menu.q',
    'special_tricks_menu_unassign_trick': 'game/menu/edit_tricks_menu.q',
    'bind_boneless_trick': 'game/menu/edit_tricks_menu.q',
    'Toggle_boneless_anim_type': 'game/menu/edit_tricks_menu.q',
}
PRX_IO = {
    'post_load_from_memory_card': 'game/menu/memcard.q',
    'mcmess_SaveSuccessful': 'game/menu/memcardmessages.q',
    'mcmess_OverwriteSuccessful': 'game/menu/memcardmessages.q',
}
# Edit Skater commit scripts (mods/casmod + casidle): parts, colors, scale, logos, clothes, sex, undo/redo
CAS_MARK = ['dadmod_choose_part', 'dadmod_clear_part', 'dadmod_color_step', 'dadmod_scale_step', 'dadmod_random_color',
            'dadmod_color_paste', 'dadmod_remove_clothes', 'cas_apply_skater_sex', 'dadmod_undo', 'dadmod_redo',
            'posmenu_adjust_uv_position', 'posmenu_adjust_uv_rotation', 'posmenu_adjust_uv_scale']
# Edit Skater main menu entries that open stock pages we have no commit hook in: they mark when opened
CAS_OPEN = ['edit_skater_premade_skater_menu', 'edit_skater_info_menu', 'create_face_map_menu']


def insert_top(text, name, line, nl):
    """Adds <line> as the first line of every definition of script <name>; returns (text, count)."""
    pat = re.compile(r'^script %s\b[^\r\n]*\r?\n' % re.escape(name), re.M | re.I)
    hits = list(pat.finditer(text))
    out, last = [], 0
    for m in hits:
        hdr_end = m.end()
        if re.search(r'\{\s*\r?\n$', m.group(0)):          # script x { default params spanning lines }
            close = re.compile(r'^\s*\}\s*\r?\n', re.M).search(text, hdr_end)
            hdr_end = close.end()
        if text[hdr_end:hdr_end + len(line) + 2].startswith(line + nl):
            continue                                         # already hooked
        out.append(text[last:hdr_end] + line + nl)
        last = hdr_end
    out.append(text[last:])
    return ''.join(out), len(hits)


def apply_tree(tree):
    qb = os.path.join(tree, 'qb')
    done = 0
    for table, line in ((PRX_MARK, MARK), (PRX_IO, IO)):
        for name, rel in table.items():
            p = os.path.join(qb, rel)
            if not os.path.isfile(p):
                os.makedirs(os.path.dirname(p), exist_ok=True)
                with open(os.path.join(KALI, rel), 'rb') as f, open(p, 'wb') as g:
                    g.write(f.read())
            s = open(p, newline='', encoding='latin-1').read()
            nl = '\r\n' if '\r\n' in s else '\n'
            s, n = insert_top(s, name, line, nl)
            if n != 1:
                sys.exit('midload: %s defined %d times in %s (expected 1)' % (name, n, rel))
            open(p, 'w', newline='', encoding='latin-1').write(s)
            done += 1
    print('midload: %d stock scripts hooked' % done)


def hook_casidle(text):
    """Edit Skater qb text (casidle + casmod) with the unsaved-change marks; used by both builds."""
    nl = '\r\n' if '\r\n' in text else '\n'
    for name in CAS_MARK:
        text, n = insert_top(text, name, MARK, nl)
        if n < 1:
            raise SystemExit('midload: casidle has no script %s' % name)
    for run in CAS_OPEN:
        a = re.compile(r'run = %s with = \{ ' % run)
        b = re.compile(r'run = %s \}' % run)
        if a.search(text):
            text = a.sub('run = dadmod_midload_mark_run with = { dadmod_run = %s ' % run, text, 1)
        elif b.search(text):
            text = b.sub('run = dadmod_midload_mark_run with = { dadmod_run = %s } }' % run, text, 1)
        else:
            raise SystemExit('midload: Edit Skater entry for %s not found' % run)
    return text


def main(argv):
    if argv[:1] == ['--casidle'] and len(argv) == 2:
        p = argv[1]
        s = open(p, newline='', encoding='latin-1').read()
        open(p, 'w', newline='', encoding='latin-1').write(hook_casidle(s))
        print('midload: Edit Skater hooks added')
    elif len(argv) == 1:
        apply_tree(argv[0])
    else:
        sys.exit(__doc__)


if __name__ == '__main__':
    main(sys.argv[1:])
