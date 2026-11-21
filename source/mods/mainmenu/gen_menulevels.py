"""Builds main menu versions of every level whose files are in the game folder (Noah, 2026-10-12: "i want
to put all the maps i can currently launch from the game files in").

For each level it makes what East LA's menu level (mods/mainmenu_el, level_Mainmenu_EL) was made from by hand:
  - the level's node array with people, animals and cars turned into plain Waypoints, and pigeons, ambient
    camera zones (ProximNode) and sound emitters no longer CreatedAtStart (the front end can't run them;
    a pigeon crashed it), plus a trg_playerrestart node at the level's first restart point (the skate
    shop's orient_skateshop_skater puts the skater there when no menu spot is marked for the level);
  - data/pre/mainmenu_<key>_scripts.prx = Skateshop_scripts.prx + the level's own thugpro_prx entries (if
    any) + levels/mainmenu_<key>/<Level>.qb;
  - a level_Mainmenu_<key> structure (the level's scene, sky and scripts, the skate shop's menu scripts).
Outputs:
  mods/mainmenu/menulevels.q   Load_MainMenu (appended to procrastination.q by the make script)
  mods/mainmenu/menulevels_data.q   structures + dadmod_menu_level_list (appended to Levels.q)
  mods/mainmenu/mainmenu.inc   kMenuLevels table between MENU_LEVELS_BEGIN/END (keys + names, same order)
  build/menulevels/data/pre/mainmenu_<key>_scripts.prx
  build/menulevels/report.txt  what was cleaned per level, and levels that could not be built
Run from work/:  python -I mods/mainmenu/gen_menulevels.py
"""
import os, re, sys, shutil, subprocess
sys.path.insert(0, 'tools')
import prx_extract, prx_pack
from qb import qbkey

GAME = r'..\THUG Pro Kali v2 - 1.2 Dev'  # read only (Modded was retired 2026-11-16)
PRE = os.path.join(GAME, 'data', 'pre')
THUG2_PRE = r"E:\Tony Hawk's Underground 2\Game\Data\pre"  # THUG2 levels, read only (Noah 2026-10-12)
OUT = r'build\menulevels'
TMP = os.path.join(OUT, 'tmp')
NAMES = r'decompiled\_names.txt'
LEVEL_SOURCES = [r'mods\host_observer\qb\game\Levels.q', r'mods\menuui\userslots.q', r'mods\thpg\thpg_levels.q']
# THPG: only the one the release ships gets a menu scene (Noah 2026-11-17); Larxian's cities are custom levels
THPG_MENU = {'level_dadmod_thpgtraining'}
SKIP = {'level_mainmenu', 'level_mainmenu2', 'level_mainmenu_el', 'level_test', 'level_default', 'level_emptydefault',
        'level_testlevel', 'level_skprodefault', 'level_z_el'}
USE_THUG2 = True  # read THUG2 levels from the THUG2 install
RENAME = {'level_mainmenu2': 'THUG2 main menu'}
# startup scripts other mods hook onto the first main menu (each guards itself so it runs once); Load_MainMenu must
# call every one (check_boot_calls fails the build otherwise)
BOOT_CALLS = ['dadmod_noclip_boot', 'dadmod_chatart_boot', 'dadmod_speed_boot', 'dadmod_levelthumbs_boot', 'dadmod_cars_boot']


def prx_entries(path):
    return prx_pack.read_entries(path)


def entry_bytes(e):
    if e['csz']:
        return prx_extract.lzss(e['data'], e['usz'])
    return bytes(e['data'][:e['usz']])


def levels():
    out = []
    for src in LEVEL_SOURCES:
        s = open(src, encoding='latin1').read()
        for m in re.finditer(r'^(\w+) = \{\n(.*?)\n\}', s, re.S | re.M):
            name, body = m.group(1), m.group(2)
            if 'load_script' not in body or name.lower() in SKIP:
                continue
            if name.lower().startswith('level_dadmod_thpg') and name.lower() not in THPG_MENU:
                continue
            out.append((name, body))
    return out


def field(body, k):
    m = re.search(r'^' + k + r' = (.*)$', body, re.M)
    return m.group(1).strip() if m else ''


def unq(v):
    return v[1:-1] if len(v) >= 2 and v[0] == '"' else v


def find_qb(archives, qbpath):
    want = qbpath.replace('\\\\', '\\').lower()
    for a in archives:
        for e in prx_entries(a):
            if e['name'].lower() == want:
                return e
    return None


def blocks(lines, start):
    """top-level { } blocks of the array that starts after line `start`; returns (blocks, end index)"""
    out, i, depth, cur = [], start + 1, 0, None
    while i < len(lines):
        l = (lines[i] or '').strip()
        if depth == 0 and l == ']':
            return out, i
        if l == '{' and depth == 0:
            cur = [i]
        depth += l.count('{') - l.count('}') if l not in ('{', '}') else (1 if l == '{' else -1)
        if l == '}' and depth == 0 and cur is not None:
            cur.append(i)
            out.append(tuple(cur))
            cur = None
        i += 1
    return out, i


GROUPS = {'thps1': 'THPS1', 'thps2': 'THPS2', 'thps3': 'THPS3', 'thps4': 'THPS4', 'thug1': 'THUG', 'thug2': 'THUG2',
          'thaw': 'THAW', 'thp8': 'Project 8', 'thugpro': 'THUG Pro'}
SCENES = {'level_practice': 'Interiors & scenes', 'level_mainmenu2': 'Interiors & scenes'}  # interiors / non-map scenes get their own group
BAD_CLASS = ('pedestrian', 'vehicle')
NO_START_CLASS = ('proximnode', 'emitterobject')
BAD_MODEL = ('animals\\', 'peds\\', 'veh\\', 'animals/', 'peds/', 'veh/')
# Ambient people (2026-10-23, gen_menu_ambient.py): for these node-array prefixes, human pedestrians are kept as real
# Pedestrian nodes but not created at load; their names and positions land in AMBIENT_FOUND so the menu can
# create the ones the "Ambient people" option allows (animals and vehicles stay stripped)
AMBIENT_KEEP = set()
AMBIENT_FOUND = {}
LIVE_KEEP = set()  # prefixes built as "live" menu maps: people and vehicles stay exactly as in free skate (animals don't)


def clean(text, prefix, report):
    lines = text.split('\n')
    # templates: X_compressed_node_N = { ... }
    templ = {}
    i = 0
    while i < len(lines):
        m = re.match(r'^(\w+) = \{$', lines[i])
        if m:
            j, depth = i + 1, 1
            while j < len(lines):
                t = lines[j].strip()
                if t == '{' or t.endswith('= {'):
                    depth += 1
                elif t == '}':
                    depth -= 1
                    if depth == 0:
                        break
                j += 1
            templ[m.group(1)] = (i, j)
            i = j
        i += 1
    def body_info(a, b):
        cls = mdl = ''
        for l in lines[a:b]:
            if l is None:
                continue
            l = l.strip()
            if l.lower().startswith('class = '): cls = l[8:].lower()
            if l.lower().startswith('model = '): mdl = l[8:].lower()
        return cls, mdl
    bad_templ, nostart = set(), 0
    for name, (a, b) in templ.items():
        cls, mdl = body_info(a + 1, b)
        if cls in BAD_CLASS and prefix.upper() in LIVE_KEEP and not any(m in mdl for m in ('animals\\', 'animals/')):
            continue  # live menu map: templated people and vehicles stay as they are
        if cls in BAD_CLASS:
            bad_templ.add(name)
        if cls in BAD_CLASS + NO_START_CLASS or any(x in mdl for x in BAD_MODEL):
            for k in range(a + 1, b):
                if lines[k].strip() == 'CreatedAtStart':
                    lines[k] = None
                    nostart += 1
    # the node array
    head = None
    for k, l in enumerate(lines):
        if l is None:
            continue
        ck = '#"0x%08x"' % qbkey(prefix + '_NodeArray')
        m = re.search(r'(^|\s)(' + re.escape(prefix) + r'_NodeArray|' + re.escape(ck) + r') =( \[)?$', l, re.I)
        if m:
            if m.start(2) > 0:  # the decompiler ran it onto the previous line ("endscript #"0x.." =")
                lines[k] = l[:m.start(2)].rstrip()
                lines.insert(k + 1, l[m.start(2):])
                l = lines[k + 1]
                k += 1
            head = k if l.rstrip().endswith('[') else k + 1
            break
    if head is None:
        raise RuntimeError('no %s_NodeArray' % prefix)
    bl, end = blocks(lines, head)
    conv = 0
    restart = None
    names = set()
    for a, b in bl:
        nb = [x for x in lines[a + 1:b] if x is not None]
        cls = ''
        tname = None
        for x in nb:
            s = x.strip()
            if s.lower().startswith('class = '): cls = s[8:].lower()
            if s in templ: tname = s
            if s.lower().startswith('name = '): names.add(s[7:].lower())
        if tname and not cls:
            ta, tb = templ[tname]
            cls, mdl = body_info(ta + 1, tb)
        else:
            mdl = ''
            for x in nb:
                if x.strip().lower().startswith('model = '): mdl = x.strip()[8:].lower()
        if restart is None and cls == 'restart':
            pos = ang = None
            for x in nb:
                s = x.strip()
                if s.lower().startswith('pos = '): pos = s[6:]
                if s.lower().startswith('position = '): pos = s[11:]
                if s.startswith('Angles = '): ang = s[9:]
            if pos:
                restart = (pos, ang or '(0.0,0.0,0.0)')
        nm_low = next((x.strip()[7:].lower() for x in nb if x.strip().lower().startswith('name = ')), '')
        if cls == 'pedestrian' and prefix.upper() in AMBIENT_KEEP and '_ped_' in nm_low and 'scene' not in nm_low and \
                any(x.strip().lower() == 'skeletonname = thps6_human' for x in nb) and not any(m in mdl for m in BAD_MODEL):
            nm = pos = None
            for x in nb:
                xs = x.strip()
                if xs.lower().startswith('name = '): nm = xs[7:]
                if xs.lower().startswith('pos = '): pos = xs[6:]
            for k in range(a + 1, b):
                s = lines[k].strip() if lines[k] is not None else ''
                if s == 'CreatedAtStart' or s.lower().startswith('createdfromvariable = '):
                    lines[k] = None
            if nm and pos:
                AMBIENT_FOUND.setdefault(prefix.upper(), []).append((nm, pos))
            continue
        if cls in BAD_CLASS and prefix.upper() in LIVE_KEEP and not any(m in mdl for m in ('animals\\', 'animals/')) and \
                not any('animal' in x.lower() for x in nb if x.strip().lower().startswith('skeletonname')):
            continue
        if cls in BAD_CLASS:
            conv += 1
            for k in range(a + 1, b):
                s = lines[k].strip() if lines[k] is not None else ''
                if s in bad_templ or s.lower().startswith('class = '):
                    lines[k] = 'Class = Waypoint'
                elif s in ('CreatedAtStart',) or s.lower().startswith('type = ') or s.lower().startswith('triggerscript = '):
                    lines[k] = None
        elif cls in NO_START_CLASS or any(x in mdl for x in BAD_MODEL):
            for k in range(a + 1, b):
                if lines[k] is not None and lines[k].strip() == 'CreatedAtStart':
                    lines[k] = None
                    nostart += 1
    if restart is None:  # no Class = restart node: any node that looks like a restart, else the first node
        for a, b in bl:
            nb = [x.strip() for x in lines[a + 1:b] if x is not None]
            if any('restart' in x.lower() for x in nb):
                pos = [x[6:] for x in nb if x.lower().startswith('pos = ')] + [x[11:] for x in nb if x.lower().startswith('position = ')]
                if pos:
                    restart = (pos[0], '(0.0,0.0,0.0)')
                    break
    if restart is None and bl:
        nb = [x.strip() for x in lines[bl[0][0] + 1:bl[0][1]] if x is not None]
        pos = [x[6:] for x in nb if x.lower().startswith('pos = ')] + [x[11:] for x in nb if x.lower().startswith('position = ')]
        if pos:
            restart = (pos[0], '(0.0,0.0,0.0)')
    added = False
    if 'trg_playerrestart' not in names and restart:
        lines[end:end] = ['{', 'Name = trg_playerrestart', 'Pos = ' + restart[0], 'position = ' + restart[0], 'Angles = ' + restart[1],
                          'Class = restart', 'Type = Generic', 'RestartName = "Menu"', 'restart_types = [', 'Generic', ']', '}']
        added = True
    report.append('  %d people/cars turned into waypoints, %d auto-start items stopped, menu spawn %s'
                  % (conv, nostart, ('added at ' + restart[0]) if added else ('already there' if 'trg_playerrestart' in names else 'MISSING')))
    if not added and 'trg_playerrestart' not in names:
        raise RuntimeError('no restart point for the menu spawn')
    return '\n'.join(x for x in lines if x is not None)


def main():
    if os.path.isdir(TMP): shutil.rmtree(TMP)
    os.makedirs(os.path.join(OUT, 'data', 'pre'), exist_ok=True)
    os.makedirs(TMP)
    shop = prx_entries(os.path.join(PRE, 'Skateshop_scripts.prx'))
    files = {}  # lower name -> full path; THUG Pro's own files win over the THUG2 install's
    if USE_THUG2 and os.path.isdir(THUG2_PRE):
        files.update({f.lower(): os.path.join(THUG2_PRE, f) for f in os.listdir(THUG2_PRE)})
    files.update({f.lower(): os.path.join(PRE, f) for f in os.listdir(PRE)})
    report, structs, table = [], [], []
    for name, body in levels():
        lvl = unq(field(body, 'level'))
        title = RENAME.get(name.lower()) or unq(field(body, 'Name'))
        pre = unq(field(body, 'pre'))
        scn = unq(field(body, 'scnpre'))
        if not pre or pre.replace('.pre', '.prx').lower() not in files or (lvl + 'scn.prx').lower() not in files:
            report.append('%s (%s): skipped, its files are not in data\\pre or the THUG2 install' % (title, name))
            continue
        key = lvl.lower()
        if os.environ.get('MENULEVELS_ONLY') and files[pre.replace('.pre', '.prx').lower()].startswith(THUG2_PRE) and key not in os.environ['MENULEVELS_ONLY'].split(','):
            continue
        report.append('%s (%s, key %s):' % (title, name, key))
        try:
            archives = [files[pre.replace('.pre', '.prx').lower()]]
            tp = unq(field(body, 'thugpro_prx'))
            if tp and tp.replace('.pre', '.prx').lower() in files:
                archives.append(files[tp.replace('.pre', '.prx').lower()])
            qbpath = unq(field(body, 'qb')) or 'levels\\\\%s\\\\%s.qb' % (lvl, lvl)
            e = find_qb(archives, qbpath)
            if not e:
                raise RuntimeError('node array %s not found' % qbpath)
            base = e['name'].replace('/', '\\').split('\\')[-1]          # e.g. Z_HO.qb
            work = os.path.join(TMP, key)
            os.makedirs(work)
            open(os.path.join(work, base), 'wb').write(entry_bytes(e))
            r = subprocess.run([sys.executable, '-I', r'tools\qb.py', 'd', '--names', NAMES, os.path.join(work, 'd'),
                                os.path.join(work, base)], capture_output=True, text=True)
            q = os.path.join(work, 'd', base[:-3] + '.q')
            if not os.path.isfile(q):
                raise RuntimeError('decompile failed: ' + r.stdout[-200:] + r.stderr[-200:])
            prefix = base[:-3]
            txt = clean(open(q, encoding='latin1').read(), prefix, report)
            cq = os.path.join(work, 'clean.q')
            open(cq, 'w', encoding='latin1', newline='\n').write(txt)
            cqb = os.path.join(work, 'clean.qb')
            r = subprocess.run([sys.executable, '-I', r'tools\qb.py', 'c', cq, cqb], capture_output=True, text=True)
            if r.returncode or not os.path.isfile(cqb):
                raise RuntimeError('compile failed: ' + r.stdout[-300:] + r.stderr[-300:])
            ents = [dict(x) for x in shop]
            if len(archives) > 1:
                have = {x['name'].lower() for x in ents}
                for x in prx_entries(archives[1]):
                    if x['name'].lower() not in have:
                        ents.append(dict(x))
            inner = 'levels\\mainmenu_%s\\%s' % (key, base)
            data = open(cqb, 'rb').read()
            ents.append({'name': inner, 'usz': len(data), 'csz': 0, 'ck': qbkey(inner), 'data': data})
            prx_name = 'mainmenu_%s_scripts.prx' % key
            prx_pack.write_archive(ents, os.path.join(OUT, 'data', 'pre', prx_name))
            # the structure: the level's own fields, the skate shop's menu scripts on top
            sname = 'level_Mainmenu_' + key
            keep, skip_arr = [], False
            for l in body.split('\n'):
                if skip_arr:  # inside the old more_level_qbs array
                    if l.strip() == ']':
                        skip_arr = False
                    continue
                k = l.split(' = ')[0].strip()
                if k == 'more_level_qbs':
                    skip_arr = not l.rstrip().endswith(']')
                    continue
                if k in ('structure_name', 'load_script', 'Name', 'level_name', 'qb', 'level_qb', 'thugpro_prx',
                         'startup_script', 'goals_script', 'setup_script', 'level_number', 'HasClassicGoals',
                         'ambient_track', 'default_stats', 'default_stats_classic', 'skip_teammate_pro', 'frontend_level'):
                    skip_arr = '[' in l and not l.rstrip().endswith(']')  # a dropped array value spanning lines (SE's ambient_track)
                    continue
                keep.append(l)
            kept = '\n'.join(keep)
            lqb = unq(field(body, 'level_qb'))
            more = re.search(r'more_level_qbs = \[\n(.*?)\n\]', body, re.S)
            moreq = [x.strip() for x in more.group(1).split('\n')] if more else []
            qbs = ([('"%s"' % lqb)] if lqb else []) + moreq + ['"levels\\\\skateshop\\\\skateshop.qb"', '"levels\\\\skateshop\\\\skateshop_cas.qb"', '"levels\\\\skateshop\\\\colormenu.qb"']
            st = ['%s = {' % sname, 'structure_name = %s' % sname, 'load_script = Load_MainMenu', 'Name = "Skate Shop"',
                  'level_name = "skateshop"', kept.strip(),
                  'thugpro_prx = "mainmenu_%s_scripts.pre"' % key,
                  'qb = "levels\\\\mainmenu_%s\\\\%s"' % (key, base),
                  'level_qb = "levels\\\\skateshop\\\\skateshop_scripts.qb"',
                  'more_level_qbs = [', *qbs, ']',
                  'startup_script = skateshop_startup', 'default_stats = 8', 'level_number = LevelNum_Skateshop',
                  'frontend_level = 1', 'skip_teammate_pro', '}']
            structs.append('\n'.join(x for x in st if x))
            g = unq(field(body, 'game')).lower()
            group = 'Built-in maps' if name.lower().startswith('level_dadmod_') else SCENES.get(name.lower()) or GROUPS.get(g, 'Other')
            table.append((key, title, sname, group))
        except Exception as ex:
            report.append('  NOT BUILT: %s' % ex)
    # The level structures and the picker list go in menulevels_data.q, which the make script appends to Levels.q:
    # procrastination.qb must stay under 512 KB (bigger and the game hangs at boot, 2026-10-12).
    d = ['dadmod_menu_levels_block = "Main menu levels (generated by mods/mainmenu/gen_menulevels.py)"']
    d += structs
    q = []
    # Load_MainMenu: the menu level index from THUGRECOMP_MenuLevel (same order as kMenuLevels)
    # Ambient life = People + traffic: the live version of the map (gen_menu_ambient.py) when it has one
    # Load_MainMenu loads the scene, then dadmod_menu_watch starts the menu driver if no screen did (quitting a server
    # lands straight on the server list, which never runs thugpro_orient_menu_skater)
    # then the first-main-menu startup calls of other mods (2026-11-17: a regenerate once dropped them, and without
    # dadmod_levelthumbs_boot the level select THPG tab crashed at 0x49F3D0 on its missing logo)
    q += ['script Load_MainMenu', '    Load_MainMenu_scene', '    KillSpawnedScript Name = dadmod_menu_watch',
          '    SpawnScript dadmod_menu_watch'] + ['    %s' % b for b in BOOT_CALLS] + ['endscript']
    q += ['script Load_MainMenu_scene', '    level = 1', '    THUGRECOMP_MenuLevel',
          '    THUGRECOMP_MenuOpt key = "ambient_level" step = 0 index = <level>',
          '    if GotParam live_level', '        if GlobalExists Name = <live_level> Type = structure',
          '            Change thugpro_mainmenu_east_la = 1', '            load_level <live_level>', '            return',
          '        endif', '    endif', '    if (<level> = 0)',
          '        Change thugpro_mainmenu_east_la = 0', '        load_level level_Mainmenu', '        return', '    endif',
          '    Change thugpro_mainmenu_east_la = 1', '    switch <level>']
    for i, (_, _, sname, _) in enumerate(table):
        q += ['    case %d' % (i + 2), '        load_level %s' % sname]
    q += ['    default', '        load_level level_Mainmenu_EL', '    endswitch', 'endscript']
    # the Menu level picker list, grouped by game (index = position in kMenuLevels)
    rows = [(0, 'Skate Shop', 'THUG'), (1, 'East LA tram', 'THAW')] + [(i + 2, t, g) for i, (_, t, _, g) in enumerate(table)]
    order = ['THPS1', 'THPS2', 'THPS3', 'THPS4', 'THUG', 'THUG2', 'THAW', 'Project 8', 'THUG Pro', 'Other', 'Built-in maps', 'Interiors & scenes']
    rows.sort(key=lambda r: (order.index(r[2]) if r[2] in order else 99, r[1].lower()))
    d.append('dadmod_menu_level_list = [')
    for i, t, g in rows:
        d.append('{ i = %d name = "%s" game = "%s" }' % (i, t.replace('"', "'"), g))
    d.append(']')
    check_boot_calls('\n'.join(q))
    open(r'mods\mainmenu\menulevels.q', 'w', encoding='latin1', newline='\n').write('\n'.join(q) + '\n')
    open(r'mods\mainmenu\menulevels_data.q', 'w', encoding='latin1', newline='\n').write('\n'.join(d) + '\n')
    inc = r'mods\mainmenu\mainmenu.inc'
    src = open(inc, encoding='latin1', newline='').read()
    a = src.index('// MENU_LEVELS_BEGIN')
    a = src.index('\n', a) + 1
    b = src.index('// MENU_LEVELS_END')
    rows = [('skateshop', 'Skate Shop'), ('east_la', 'East LA tram')] + [(k, t) for k, t, _, _ in table]
    body = 'static const MenuLevel kMenuLevels[] = {\n' + ''.join('    {"%s", "%s"},\n' % (k, t.replace('"', '\\"')) for k, t in rows) + '};\n'
    open(inc, 'w', encoding='latin1', newline='').write(src[:a] + body + src[b:])
    open(os.path.join(OUT, 'report.txt'), 'w', encoding='latin1').write('\n'.join(report) + '\n')
    print('%d menu levels built' % len(table))
    print('\n'.join(report[-12:]))


def check_boot_calls(text):
    """Fail the build if Load_MainMenu lost any of the BOOT_CALLS."""
    i = text.index('script Load_MainMenu\n')
    body = text[i:text.index('endscript', i)]
    missing = [b for b in BOOT_CALLS if ('    %s\n' % b) not in body]
    if missing:
        sys.exit('gen_menulevels: Load_MainMenu is missing ' + ', '.join(missing))


if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == '--check':
        check_boot_calls(open(sys.argv[2], encoding='latin1').read())
        print('boot calls ok')
        sys.exit(0)
    main()
