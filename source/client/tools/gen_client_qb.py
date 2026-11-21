"""Generates the client build's script files from the server build.

    python -I client/tools/gen_client_qb.py [--check]      (run from work/, after a server build)

Reads the server build's script tree (build/obsspawn_test/mod/qb) and the decompiled stock and Kali Original
scripts, and writes client/qb/gen/*.q: every script or global we added or changed that belongs to a client
mod (mods/MANIFEST.tsv client = yes/later), plus the client parts of host_observer (by name, CLIENT_NAMES).

Rules (client/README.md):
  * a block that Kali changed from stock (KALI-DIFFERS) is never shipped from the server build, because ours
    is built on Kali's text; it needs a hand-written version or wrap in client/qb/dadmod (HAND), or it fails
  * a block defined in client/qb/dadmod (hand-written) is never generated
  * server-only blocks are left out; client blocks that call them are listed in client/tools/gen_report.txt
  * Edit Skater part lists (ped_*) are rebuilt from stock with our hidden flags (mods/casmod/unsafe_parts.txt)
--check only reports, it writes nothing but the report.
"""
import collections, glob, os, re, sys

WORK = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.chdir(WORK)
sys.path.insert(0, os.path.join(WORK, 'tools'))
from qb import qbkey                        # noqa: E402
TREE = 'build/obsspawn_test/mod/qb'
KALI = 'decompiled/thugpro_qb/qb'          # THUG Pro Kali v2 - 1.2 Original, decompiled
STOCK = 'decompiled_stock/thugpro_qb/qb'   # THUG Pro REAL BASE INSTALL, decompiled
OUT = 'client/qb/gen'
HANDDIR = 'client/qb/dadmod'
SKIP = re.compile(r'\.(before|bak|broken|failed|held|new|after|with|old)')
LIMIT = int(os.environ.get('DADMOD_GEN_LIMIT', 300 * 1024))                          # source bytes per generated file (compiled .qb must stay < 512 KB)

# host_observer is a whole-tree copy with client and server parts mixed: these names are the client parts
CLIENT_NAMES = re.compile(r'^(dadmod_menu|dadmod_mm_|dadmod_mmopt_|dadmod_custom_cam_|dadmod_custom_random_pick|dadmod_balance_|'
                          r'dadmod_pause_gfx|dadmod_pause_graphics|dadmod_pause_weather|dadmod_gfx_from_pause|dadmod_free_cam|'
                          r'dadmod_set_menu_here|dadmod_back_to_main|dadmod_reload_menu_scene|dadmod_saved_|dadmod_menu_ambient_|'
                          r'dadmod_menu_watch|dadmod_lobby_fade_in|dadmod_main_green_focus|dadmod_dirty|'
                          r'thugpro_main_|thugpro_menu_|thugpro_mark_|thugpro_freecam_|thugpro_orient_menu_skater|thugpro_shop_|'
                          r'level_mainmenu_el|thugpro_mainmenu_east_la|swap_themes_menu|themes_menu_edit_custom|'
                          r'thugpro_custom_theme_options|taunt|toggleviewmode|handle_start_pressed|level_select_|'
                          r'create_dadmod_mainmenu_menu|create_edit_theme_color_menu|edit_theme_color_item_focus|'
                          r'dadmod_join_fade|choose_selected_server|create_joining_lobby_dialog|net_chosen_join_server|'
                          r'create_new_ss_menu|new_select_skater_hmenu_focus|select_skater_menu_back|thugpro_mainmenu_el_startup|'
                          r'generalbail|startingnewnetgame|userselectselect|walk_maybe_throw_projectile2|dadmod_)', re.I)
# and these are its server parts (host commands, votes, AFK, observer host, net game flow)
SERVER_NAMES = re.compile(r'^(thugpro_bang_|thugpro_mapvote_|thugpro_afk_|thugpro_airbounce_|thugpro_help_|thugpro_qhelp_|'
                          r'thugpro_cmaps_|thugpro_caps_|thugpro_cap_show|thugpro_pw_|thugpro_qcmd_|thugpro_hostasobserver|'
                          r'thugpro_hostobserverwatch|thugpro_cmd_log|thugpro_whitelist_check|thugpro_fix_observer_name|'
                          r'thugpro_anyone_loading|thugpro_park_loads|thugpro_panel_pos|chosen_host_game|spawned_chosen_host_game|'
                          r'quit_network_game|create_net_panel_message|create_console_message|dadmod_afkstart_|'
                          r'#"0x328eb84c"|#"0xd70bd595"|'
                          r'create_network_host_options_menu|tp_host_option_|create_object_label|dadmod_welcome_(show|morph|off)$|'
                          r'horse_allowed_characters|thugpro_cmd_text|thugpro_panel_|thugpro_kali_quick_menu|'
                          r'thugpro_quick_menu_chat_cmd|dadmod_levelthumb_for|dadmod_levelthumbs_load)', re.I)
# (the server build's level select picture scripts come from tools/levelthumbs.py; make_client.py makes the client's own)
# files of client mods that are host parts
SERVER_FILES = {'mods/anims/qanims.q', 'mods/anims/pmanims.q'}
# host parts of client mods that live in the same file as the client part (!ammo is answered by the host)
SERVER_BLOCKS = {'thugpro_throw_parse', 'thugpro_throw_parse2', 'thugpro_throw_chat', 'thugpro_throw_give', 'thugpro_throw_confirm',
                 'dadmod_bang_online_level_command',
                 # our THPG Baltimore conversion is Dev only (Noah 2026-11-20: only Larxian's Baltimore in the release)
                 'level_dadmod_thpgbaltimore', 'load_dadmod_thpgbaltimore'}
# blocks of stock scripts that Kali changed: handled by hand in client/qb/dadmod (wrap or our own version)
HAND = {'create_main_menu', 'create_pause_menu', 'exit_pause_menu', 'thugpro_show_quick_menu', 'thugpro_update_tod',
        'thugpro_menu_create_title', 'load_level'}
# lines that look like Kali's but are our own choice (checked: crillee is a stock font)
OWN_LINES = {'make_thugpro_menu_item': ['font = crillee']}
# a generated block that needs a small client-only change: name -> [(text, replacement)]
PATCHES = {
    # Kali-only item styles go to Kali's own version; the pause / quick menu get our items inserted (menus.q)
    'make_thugpro_menu_item': [(
        '    if not GotParam dadmod_replay\n',
        '    if GotParam id\n'
        '        if not GotParam dadmod_ins_inner\n'
        '            dadmod_ins_check id = <id>\n'
        '            if (<dadmod_ins> = 1)\n'
        '                make_thugpro_menu_item <...> dadmod_ins_inner\n'
        '                dadmod_ins_items\n'
        '                return\n'
        '            endif\n'
        '        endif\n'
        '    endif\n'
        '    if not GotParam dadmod_replay\n'), (
        '    if ScreenElementExists ID = <ID>\n',
        '    if GotParam #"0x1d710c47"\n'
        '        make_thugpro_menu_item_orig <...>\n'
        '        return\n'
        '    endif\n'
        '    if GotParam #"0x8f12a08c"\n'
        '        make_thugpro_menu_item_orig <...>\n'
        '        return\n'
        '    endif\n'
        '    if ScreenElementExists ID = <ID>\n')],
    # infinite balance is offline only in the client build (Noah 2026-11-05, 2026-11-17: fine in Freeskate, off
    # online): online it counts as Default and the menu skips it; qb/dadmod/balance.q re-applies the setting when
    # you go online or back offline. THUG Pro's Freeskate is a net game too, so "online" = a net game that isn't
    # single session (dadmod_balance_online, balance.q). The default stays Default (balance_mode 1).
    'dadmod_balance_get': [(
        '    return lvl = <lvl>\n',
        '    dadmod_balance_online\n    if ( <online> = 1 )\n        if ( <lvl> = 3 )\n            lvl = 1\n        endif\n    endif\n    return lvl = <lvl>\n')],
    'dadmod_balance_cycle': [(
        '    THUGRECOMP_SettingSave key = "balance_mode" value = <lvl>\n',
        '    dadmod_balance_online\n    if ( <online> = 1 )\n        if ( <lvl> = 3 )\n            if GotParam left\n                lvl = 2\n            else\n'
        '                lvl = 0\n            endif\n        endif\n    endif\n'
        '    THUGRECOMP_SettingSave key = "balance_mode" value = <lvl>\n')],
    'dadmod_tod_watch_start': [(
        '    SpawnScript dadmod_tod_watch NotSessionSpecific = 1\n',
        '    SpawnScript dadmod_tod_watch NotSessionSpecific = 1\n    SpawnScript dadmod_balance_net_watch NotSessionSpecific = 1\n')],
    # Free Cam shows online too (Noah 2026-11-19). Online, leaving the pause menu resets the camera (stock unpause) but
    # view_mode stays 1, so the row would do nothing: online it turns view mode off first, then on again
    'dadmod_free_cam_on': [(
        '    if not IsTrue view_mode\n        ToggleViewMode\n',
        '    if IsTrue view_mode\n        if InNetGame\n            ToggleViewMode\n        endif\n    endif\n'
        '    if not IsTrue view_mode\n        ToggleViewMode\n')],
    # the Menu level list shows only the levels this install has (client/native/menulevels.inc)
    'dadmod_menu_level_menu': [(
        '        e = ( dadmod_menu_level_list [ <i> ] )\n        g = ( <e> . game )\n',
        '        e = ( dadmod_menu_level_list [ <i> ] )\n        g = ( <e> . game )\n'
        '        if not THUGRECOMP_MenuLevelHas index = ( <e> . i )\n            g = <last_game>\n        endif\n'), (
        '        make_thugpro_menu_item {\n        text = <t>\n',
        '        if THUGRECOMP_MenuLevelHas index = ( <e> . i )\n'
        '        make_thugpro_menu_item {\n        text = <t>\n'), (
        '        pad_choose_params = { pick = ( <e> . i ) }\n        }\n',
        '        pad_choose_params = { pick = ( <e> . i ) }\n        }\n        endif\n')],
    # thugpro_update_tod (wrapped in menus.q) flags its call instead of passing from_update
    'thugpro_change_time_of_day': [(
        '\n', '\n    if (dadmod_tod_upd = 1)\n        <from_update> = 1\n    endif\n')],
    # release THPG tab (Noah 2026-11-17): Larxian's Philly, Baltimore, Washington DC + our THPG Training; our own
    # THPG Baltimore conversion is not shipped (Larxian's Baltimore replaces it), so its entry goes
    # chat art (Alt+F12) stays out of the release, Dev only (Noah 2026-11-17: a throwaway idea; MANIFEST client = no)
    'load_mainmenu': [('    dadmod_chatart_boot\n', '')],
    'list_level_thpg': [(
        '{ text = "BALTIMORE (THPG)" exclude = 0 enabled = 1 num_votes = 0 level = Load_dadmod_THPGBaltimore level_thumb = thumb_default level_num = LevelNum_Default }\n',
        '')],
    # Noah 2026-11-20: only Larxian's Baltimore in the release; without it the row says not installed (no conversion fallback)
    'load_dadmod_thpglarxbaltimore': [(
        '        if ScriptExists Load_dadmod_THPGBaltimore\n            Load_dadmod_THPGBaltimore <...>\n        else\n'
        '            dadmod_thpg_not_installed\n        endif\n',
        '        dadmod_thpg_not_installed\n')],
    'dadmod_added_levels': [(' Load_dadmod_THPGBaltimore ', ' ')],
}
PED = re.compile(r'^ped_[mf]_|^ped_body$', re.I)
# Dev-only log calls a server mod adds into client scripts (mods/bhra_probe): the line goes, the script stays
LOG_ONLY = re.compile(r'^[ \t]*dadmod_bhra_log\b[^\n]*\n', re.M)


def blocks(path):
    """script NAME ... endscript, and top-level NAME = value (up to where its braces/brackets close)."""
    out = collections.OrderedDict()
    if not os.path.isfile(path):
        return out
    cur, depth = None, 0
    for line in open(path, encoding='latin-1').read().replace('\r', '').split('\n'):
        if cur and cur.startswith('script '):
            out[cur] += line + '\n'
            if line.startswith('endscript'):
                cur = None
            continue
        if cur and depth > 0:
            out[cur] += line + '\n'
            depth += line.count('{') + line.count('[') - line.count('}') - line.count(']')
            if depth <= 0:
                cur = None
            continue
        m = re.match(r'^script\s+(\S+)', line)
        if m:
            cur = 'script ' + m.group(1)
            out.pop(cur, None)          # a later definition in the same file wins and goes last
            out[cur] = line + '\n'
            continue
        m = re.match(r'^([^\s=]+)\s*=', line)
        if m:
            cur = 'global ' + m.group(1)
            out.pop(cur, None)
            out[cur] = line + '\n'
            depth = line.count('{') + line.count('[') - line.count('}') - line.count(']')
            if depth <= 0:
                cur = None
    return out


TOKEN = re.compile(r'#"0x([0-9a-fA-F]+)"|#"([^"]*)"|("(?:[^"\\]|\\.)*"|\'(?:[^\'\\]|\\.)*\')|([A-Za-z_][A-Za-z0-9_]*)')


def norm_line(line):
    """one line with every name as its checksum, so Name / name / #"0x..." spellings compare equal."""
    def sub(m):
        if m.group(1):
            return '%08x' % int(m.group(1), 16)
        if m.group(2) is not None:
            return '%08x' % qbkey(m.group(2))
        if m.group(3):
            return m.group(3)
        return '%08x' % qbkey(m.group(4))
    return TOKEN.sub(sub, ' '.join(line.split()))


def norm(text):
    return [norm_line(x) for x in text.split('\n') if x.strip()]


TRIVIAL = {norm_line(x) for x in ('endif', 'else', '}', '{', 'endscript', ']', '[', 'repeat', 'begin', 'endswitch')}


def kali_lines_in(ours_text, kali_text, stock_text, own=()):
    """lines Kali added to a stock block that ours still has (ours built on Kali's text)."""
    added = set(norm(kali_text)) - set(norm(stock_text)) - TRIVIAL - {norm_line(x) for x in own}
    return [x for x in norm(ours_text) if x in added]


def name_of(k):
    return k.split(' ', 1)[1]


def qdir_files(root):
    qdir = os.path.join(os.path.dirname(root), 'code', 'qb', 'qdir.txt')
    for ln in open(qdir, encoding='latin-1').read().splitlines():
        ln = ln.strip().replace('\\', '/')
        if ln.startswith('data/') and ln.endswith('.qb'):
            yield ln[5:-3] + '.q'               # qb/game/x.q, custom.q


def effective(root, overlay=None, order=None):
    """name -> (key, text, file) as the game ends up with it: files load in qdir order, later wins."""
    d = {}
    base = os.path.dirname(root)
    for rel in qdir_files(root):
        p = os.path.join(base, rel)
        if overlay and rel.startswith('qb/') and os.path.isfile(os.path.join(overlay, rel[3:])):
            p = os.path.join(overlay, rel[3:])
        for k, v in blocks(p).items():
            d[name_of(k).lower()] = (k, v, rel)
            if order is not None:
                order['#n'] = order.get('#n', 0) + 1
                order[name_of(k).lower()] = order['#n']
    return d


def manifest():
    side, client = {}, {}
    for ln in open('mods/MANIFEST.tsv', encoding='latin-1'):
        if ln.startswith('#') or not ln.strip():
            continue
        f = ln.rstrip('\n').split('\t')
        side[f[0]], client[f[0]] = f[1], f[2]
    return side, client


def origins():
    """name -> {(mod, file)} for every definition in mods/ (host_observer is the base tree, not an origin)."""
    o = collections.defaultdict(set)
    for p in glob.glob('mods/**/*.q', recursive=True):
        p = p.replace(os.sep, '/')
        if SKIP.search(p) or '/host_observer/' in p or '_live' in p:
            continue
        for k in blocks(p):
            o[name_of(k).lower()].add((p.split('/')[1], p))
    return o


def hide_unsafe(text, list_name, unsafe):
    """mods/casmod/hide_unsafe_parts.py's rule on one part list: listed desc_ids get `hidden`."""
    want = unsafe.get(list_name, set())
    lines = text.split('\n')
    for i, line in enumerate(lines):
        m = re.match(r'^desc_id = (.+?)\s*$', line)
        if m and m.group(1) in want:
            flags, j, depth = set(), i + 1, 0
            while depth > 0 or lines[j].strip() != '}':
                if depth == 0:
                    flags.add(lines[j].strip())
                depth += lines[j].count('{') - lines[j].count('}')
                j += 1
            if 'hidden' not in flags:
                lines[i] = line + '\nhidden'
    return '\n'.join(lines)


def main(argv):
    check = '--check' in argv
    side, client = manifest()
    org = origins()
    stock, kali = effective(STOCK), effective(KALI)
    # load order matters: a global struct can pull in another one by name ({ other_struct }), and that one
    # has to be defined first or the game crashes while loading the file. Blocks go out in the order the
    # game itself defines them (qdir order, then file order; a redefinition counts where it happens).
    order = {}
    ours = effective(KALI, overlay=TREE, order=order)
    hand = set()
    for p in glob.glob(os.path.join(HANDDIR, '**', '*.q'), recursive=True):
        hand |= {name_of(k).lower() for k in blocks(p)}
    unsafe = {}
    for line in open('mods/casmod/unsafe_parts.txt', encoding='latin-1'):
        f = line.split()
        if len(f) == 3:
            unsafe.setdefault(f[0].lower(), set()).add(f[1])

    changed = {n: v for n, v in ours.items() if n not in kali or norm(kali[n][1]) != norm(v[1])}
    keep, drop, report = {}, {}, collections.defaultdict(list)
    for n, (k, v, rel) in sorted(changed.items()):
        if n in hand:
            continue
        src = org.get(n)
        if src:
            files = {f for _, f in src}
            is_client = any(client.get(m) in ('yes', 'later') for m, f in src if f not in SERVER_FILES) and n not in SERVER_BLOCKS
            why = ','.join(sorted({m for m, _ in src}))
        elif SERVER_NAMES.match(n):
            is_client, why = False, 'host_observer (server part)'
        elif CLIENT_NAMES.match(n):
            is_client, why = True, 'host_observer (client part)'
        else:
            is_client, why = False, 'host_observer (UNCLASSIFIED)'
            report['unclassified: changed in the server build, no rule says client or server'].append(
                '%s  (%s, %s)' % (k, rel, 'new' if n not in kali else 'changed'))
        (keep if is_client else drop)[n] = (k, v, rel, why)

    gen, fail = {}, []
    for n, (k, v, rel, why) in sorted(keep.items()):
        if n in hand:
            continue
        if PED.match(n) and n in stock:
            continue                                # rebuilt from stock below
        if n in kali and n in stock and norm(kali[n][1]) != norm(stock[n][1]) and (
                n in HAND or kali_lines_in(v, kali[n][1], stock[n][1], OWN_LINES.get(n, ()))):
            if n in HAND:
                fail.append('%s: in HAND but client/qb/dadmod does not define it' % n)
            else:
                fail.append('%s: Kali changed it from stock, ours is built on Kali\'s; needs a hand-written version (%s); Kali lines in ours: %s'
                            % (n, why, kali_lines_in(v, kali[n][1], stock[n][1], OWN_LINES.get(n, ()))[:4]))
            continue
        if n in kali and n not in stock:
            fail.append('%s: Kali-only, we changed it (%s)' % (n, why))
            continue
        for a, b in PATCHES.get(n, []):
            if v.count(a) < 1:
                fail.append('%s: patch anchor not found: %r' % (n, a[:50]))
            v = v.replace(a, b, 1)
        v = LOG_ONLY.sub('', v)
        gen[n] = (k, v, rel)
    # Edit Skater part lists: stock text + our hidden flags, so Kali's own edits are never shipped
    for n in sorted(set(unsafe) | {x for x in keep if PED.match(x)}):
        if n in stock and n not in hand:
            k, v, rel = stock[n]
            nv = hide_unsafe(v, n, unsafe)
            if nv != v or n in keep:
                gen[n] = (k, nv, rel)
    for n in sorted(set(PATCHES) - set(gen)):
        fail.append('%s: has a patch but is not generated' % n)

    # menu items that open a left-out server script go
    def gone(x):
        x = x.lower()
        return x in drop and x not in gen and x not in hand
    for n, (k, v, rel) in list(gen.items()):
        lines, out, i = v.split('\n'), [], 0
        while i < len(lines):
            m = re.match(r'^(\s*)make_thugpro_menu_item \{\s*$', lines[i])
            if m:
                j = i + 1
                while not re.match(r'^%s\}\s*$' % m.group(1), lines[j]):
                    j += 1
                item = lines[i:j + 1]
                pc = [re.match(r'^\s*pad_choose_script = (\S+)', x) for x in item]
                pc = [x.group(1) for x in pc if x]
                if pc and gone(pc[0]):
                    report['menu items taken out (they open a server script)'].append('%s: %s' % (k, pc[0]))
                    i = j + 1
                    continue
            out.append(lines[i])
            i += 1
        gen[n] = (k, '\n'.join(out), rel)
    cf = collections.defaultdict(set)
    for n, (k, v, rel) in gen.items():
        for c in re.findall(r'THUGRECOMP_\w+', v, re.I):
            cf[c].add(name_of(k))
    for c in sorted(cf):
        report['DLL functions the client scripts call'].append('%s  (%d blocks, e.g. %s)' % (c, len(cf[c]), sorted(cf[c])[0]))
    # client blocks that call left-out server blocks: those calls just log "not found" in game; menu items
    # that open them should be taken out (see report)
    tok = re.compile(r'[A-Za-z_][A-Za-z0-9_]*')
    for n, (k, v, rel) in sorted(gen.items()):
        miss = sorted({t for t in tok.findall(v) if t.lower() in drop and t.lower() not in gen and t.lower() not in hand})
        if miss:
            report['client blocks that use left-out server blocks'].append('%s -> %s' % (k, ' '.join(miss)))

    os.makedirs('client/tools', exist_ok=True)
    with open('client/tools/gen_report.txt', 'w', newline='\n') as f:
        f.write('client script generator report (gen_client_qb.py)\n')
        f.write('generated blocks: %d   left out (server): %d   hand-written: %d\n\n' % (len(gen), len(drop), len(hand)))
        for t, rows in report.items():
            f.write('## %s (%d)\n' % (t, len(rows)))
            f.writelines(r + '\n' for r in rows)
            f.write('\n')
        f.write('## generated (%d)\n' % len(gen))
        f.writelines('%s  [%s]\n' % (k, rel) for n, (k, v, rel) in sorted(gen.items()))
        f.write('\n')
        f.write('## left out: server blocks (%d)\n' % len(drop))
        f.writelines('%s  [%s]\n' % (k, why) for n, (k, v, rel, why) in sorted(drop.items()))
    if fail:
        print('CLIENT QB GENERATION FAILED:')
        print('\n'.join('  ' + x for x in fail))
        return 1
    if check:
        print('generated blocks: %d (check only, nothing written)' % len(gen))
        return 0

    # write, grouped by the file each block came from, split under LIMIT
    os.makedirs(OUT, exist_ok=True)
    old = set(glob.glob(os.path.join(OUT, '*.q')))
    parts, cur, size = [], [], 0
    for n, (k, v, rel) in sorted(gen.items(), key=lambda x: order.get(x[0], 0)):
        if cur and size + len(v) > LIMIT:
            parts.append(cur)
            cur, size = [], 0
        cur.append((rel, v))
        size += len(v)
    if cur:
        parts.append(cur)
    for i, part in enumerate(parts):
        with open(os.path.join(OUT, 'gen%02d.q' % i), 'w', encoding='latin-1', newline='\n') as f:
            # the QB compiler has no comments: where each block came from is in gen_report.txt
            for rel, v in part:
                f.write(v.rstrip('\n') + '\n\n')
    for stale in old - {os.path.join(OUT, 'gen%02d.q' % i) for i in range(len(parts))}:
        try:
            os.remove(stale)
        except OSError:
            open(stale, 'w').close()            # can't delete here: leave it empty
    print('client qb: %d blocks in %d files (%s), %d server blocks left out' % (len(gen), len(parts), OUT, len(drop)))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
