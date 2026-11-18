"""Copies stock Edit Skater menu scripts from plain THUG Pro and adds our hooks.

  python -I gen_partmenu.py <plain THUG Pro skateshop_cas.q> <out.q>

create_part_cas_menu: items choose dadmod_choose_part (keeps the item), back runs dadmod_part_menu_back
  (puts back a previewed-but-not-chosen item); dadmod_undo_save + dadmod_part_remove_item before the item loop, a focus_script
  (dadmod_preview_part) on every item, dadmod_part_menu_ready before finalize (focus on the worn item,
  L1/R1 page jump).
create_part_cas_color_menu: dadmod_undo_save, then Copy/Paste Color items after the color sliders.
edit_skater_create_options_menu: BareFeet and Hands no longer grey out color; dadmod_header entries are
  shown as greyed header lines; Undo item at the bottom.
cas_set_part: dadmod_before_set_part runs first (saves hair color), dadmod_after_set_part runs before the
  model refresh (puts the hair color back ; Kali's Null pants also clear the bare legs).
create_part_cas_menu also gets dadmod_part_color_item (a Color item at the top of every part list).
launch_pre_cas_menu, confirm_skater_sexchange: plain THUG Pro copies (so Kali's versions aren't used).
thugpro_scaling_menu_add_options_to_menu (from plain THUG Pro engine/menu/sliderbar.q): sliders call
  dadmod_scale_step (faster on the analog stick).
"""
import os, sys


def script(lines, name):
    start = next(i for i, l in enumerate(lines) if l == 'script %s' % name or l == 'script %s {' % name)
    end = next(i for i in range(start + 1, len(lines)) if lines[i] == 'endscript')
    return lines[start:end + 1]


def insert_before(body, line, new):
    hits = [i for i, l in enumerate(body) if l == line]
    assert len(hits) == 1, 'not found once: %r' % line
    body[hits[0]:hits[0]] = new


def insert_after(body, line, new):
    hits = [i for i, l in enumerate(body) if l == line]
    assert len(hits) == 1, 'not found once: %r' % line
    body[hits[0] + 1:hits[0] + 1] = new


src, out = sys.argv[1], sys.argv[2]
lines = open(src, encoding='utf-8').read().replace('\r\n', '\n').split('\n')

part = script(lines, 'create_part_cas_menu')
insert_before(part, '    GetArraySize <array>', ['    dadmod_undo_save_part', '    dadmod_part_remove_item <...>'])
choose = '            pad_choose_params = { structure = ( <array> [ <index> ] ) desc_id = ( ( <array> [ <index> ] ) . desc_id ) part = <array> }'
insert_after(part, choose, ['            focus_script = dadmod_preview_part',
                            choose.replace('pad_choose_params', 'focus_params')])
insert_before(part, '    thugpro_menu_finalize <...>', ['    dadmod_part_menu_ready <...>'])
# part lists bind L3/R3 (dadmod_page_jump), so their controls bar gets the Skip hint too (qol.q)
assert part.count('    helper_text = generic_helper_text_cas') == 1
part[part.index('    helper_text = generic_helper_text_cas')] = '    helper_text = dadmod_helper_text_cas_part'
n = part.index(choose)
assert part[n - 1] == '            pad_choose_script = cas_set_part'
part[n - 1] = '            pad_choose_script = dadmod_choose_part'
for old, new in (('    pad_back_script = <callback>', '    pad_back_script = dadmod_part_menu_back'),
                 ('    pad_back_params = <callback_params>', '    pad_back_params = { callback = <callback> callback_params = <callback_params> }')):
    assert part.count(old) == 1, old
    part[part.index(old)] = new

color = script(lines, 'create_part_cas_color_menu')
insert_before(color, '    thugpro_color_menu_add_options_to_menu part = <part>', ['    dadmod_undo_save_color <...>'])
insert_after(color, '    thugpro_color_menu_add_options_to_menu part = <part>', ['    dadmod_color_copy_items part = <part>'])
assert color.count('    helper_text = generic_helper_text') == 1
color[color.index('    helper_text = generic_helper_text')] = '    helper_text = dadmod_helper_text_color'

opts = script(lines, 'edit_skater_create_options_menu')
grey = '                        if ArrayContains array = [ none , Shirtless , BareFeet , Hands ] contains = <desc_id>'
insert_before(opts, grey, [grey.replace(' , BareFeet , Hands ]', ' ]')])
opts.remove(grey)
insert_after(opts, '            <focusable> = focusable', [
    '            if StructureContains structure = ( <options_array> [ <index> ] ) dadmod_header',
    '                <focusable> = not_focusable',
    '            endif'])
insert_before(opts, '    thugpro_menu_create_remainder_items', ['    dadmod_undo_keys'])
# the menu camera DLL picks the screen's close-up from the first line it sees; the section headers (BOARD, SHIRT...)
# come first now, so tell it the screen before any item is made (Noah 2026-11-07: deck options zoomed on the wrong part)
insert_after(opts, '    SpawnSkaterScript SkateshopCasIdle params = { cam_pos = <cam_pos> }', ['    dadmod_es_cam_ctx cam_pos = <cam_pos> options_array = <options_array>'])
# every option is made by dadmod_es_item (qol.q): part lists get a small "Color" tag (right = pick it)
made = [i for i, l in enumerate(opts) if l.strip() == 'make_thugpro_menu_item {']
assert len(made) == 2, made
for i in reversed(made):
    assert opts[i + 5].strip() == '}' and opts[i + 4].strip() == '<focusable>', opts[i:i + 6]
    ind = opts[i][:len(opts[i]) - len(opts[i].lstrip())]
    opts[i:i + 6] = [ind + 'dadmod_es_item item = ( <options_array> [ <index> ] ) <focusable> index = <index> options_array = <options_array> cam_pos = <cam_pos>']

setp = script(lines, 'cas_set_part')
insert_before(setp, '    if ArrayContains array = __cas_refresh_skater_parts contains = <part>', ['    dadmod_after_set_part part = <part> desc_id = <desc_id>'])
insert_before(setp, '    cas_handle_disqualifications <...>', ['    dadmod_before_set_part part = <part>'])

plain = script(lines, 'launch_pre_cas_menu') + script(lines, 'confirm_skater_sexchange')

slider_src = os.path.join(os.path.dirname(os.path.abspath(src)), '..', 'thugpro_qb', 'engine', 'menu', 'sliderbar.q')
slider_lines = open(slider_src, encoding='utf-8').read().replace('\r\n', '\n').split('\n')
scale = script(slider_lines, 'thugpro_scaling_menu_add_options_to_menu')
hits = [i for i, l in enumerate(scale) if l.strip() == 'option_arrows_callback = __thugpro_scaling_menu_change_uniform']
assert len(hits) >= 5, 'scaling callbacks not found'
for i in hits:
    pass  # sliders keep the stock step script; dadmod_stick_watch (ownmenus.q) changes the increment

scale.insert(len(scale) - 1, '    dadmod_undo_keys')
scale.insert(len(scale) - 1, '    dadmod_stick_watch_start')
open(out, 'w', encoding='utf-8', newline='\n').write('\n'.join(part + color + opts + setp + plain + scale) + '\n')
