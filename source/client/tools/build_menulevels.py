r"""Client build: the custom main menu scenes, made from a plain THUG Pro install's level files.

    python -I client/tools/build_menulevels.py [--pre "<stock game>\data\pre"] [--out build/client_menulevels]
                                               (run from work/; reads the stock install, never writes to it)

For every level in kMenuLevels (mods/mainmenu/mainmenu.inc) whose files a plain THUG Pro install has, this makes
the same cleaned node array the server build makes (mods/mainmenu/gen_menulevels.py clean(); z_ho and z_bh also
get the "live" one from gen_menu_ambient.py). Only that one file per level is shipped:
  <out>/dadmod/menulevels/<key>.qb  (and <key>_live.qb)
  <out>/dadmod/menulevels/list.txt  one line per archive:
        <archive name> <qb file> <name inside> <extra archive or -> <file data\pre must have, or ->
The client DLL (client/native/menulevels.inc) puts data\pre\mainmenu_<key>_scripts.prx together on the player's
machine from those and the player's own Skateshop_scripts.prx (+ the level's thugpro_prx), so a Kali install
keeps Kali's skate shop scripts. East LA's menu node array comes from mods/mainmenu_el (made by hand). THUG2 levels and levels added
to a game folder by hand can't be cleaned from a plain install, so theirs come from the server build
(build/menulevels, mods/mainmenu/gen_menulevels.py); a hand-added level is only put together where its scene is installed.
"""
import os, re, sys, shutil, subprocess, tempfile

WORK = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.chdir(WORK)
sys.path.insert(0, 'tools')
sys.path.insert(0, os.path.join('mods', 'mainmenu'))
import gen_menulevels as g          # noqa: E402
import gen_menu_ambient as amb      # noqa: E402

g.LEVEL_SOURCES = [os.path.join('mods', 'host_observer', 'qb', 'game', 'Levels.q'), os.path.join('mods', 'menuui', 'userslots.q'), os.path.join('mods', 'thpg', 'thpg_levels.q')]
g.NAMES = os.path.join('decompiled', '_names.txt')
QB = os.path.join('tools', 'qb.py')


def menu_keys():
    src = open(os.path.join('mods', 'mainmenu', 'mainmenu.inc'), encoding='latin1').read()
    a, b = src.index('// MENU_LEVELS_BEGIN'), src.index('// MENU_LEVELS_END')
    return re.findall(r'\{"(\w+)", "', src[a:b])


def from_server_build(key):
    """(name inside, bytes) of the cleaned node array in the server build's mainmenu_<key>_scripts.prx"""
    p = os.path.join('build', 'menulevels', 'data', 'pre', 'mainmenu_%s_scripts.prx' % key)
    if not os.path.isfile(p):
        return None
    for e in g.prx_entries(p):
        if e['name'].lower().startswith('levels\\mainmenu_%s\\' % key):
            return e['name'], g.entry_bytes(e)
    return None


def compile_q(text, work, stem):
    q, qb = os.path.join(work, stem + '.q'), os.path.join(work, stem + '.qb')
    open(q, 'w', encoding='latin1', newline='\n').write(text)
    r = subprocess.run([sys.executable, '-I', QB, 'c', q, qb], capture_output=True, text=True)
    if r.returncode or not os.path.isfile(qb):
        raise RuntimeError('compile failed: ' + r.stdout[-300:] + r.stderr[-300:])
    return open(qb, 'rb').read()


def main(argv):
    # DADMOD_BASE_INSTALL: another plain install (read only) when the cleanup_archive copy is gone (2026-11-24)
    pre = os.path.join(os.environ.get('DADMOD_BASE_INSTALL') or os.path.join('..', 'cleanup_archive_20261116', 'THUG Pro REAL BASE INSTALL'), 'data', 'pre')
    out = os.path.join('build', 'client_menulevels')
    while argv:
        if argv[0] == '--pre':
            pre, argv = argv[1], argv[2:]
        elif argv[0] == '--out':
            out, argv = argv[1], argv[2:]
        else:
            sys.exit('unknown arg ' + argv[0])
    dst = os.path.join(out, 'dadmod', 'menulevels')
    os.makedirs(dst, exist_ok=True)
    for f in os.listdir(dst):  # stale files: emptied (the device VM can't delete)
        open(os.path.join(dst, f), 'wb').close()
    files = {f.lower(): f for f in os.listdir(pre)}
    devpre = os.path.join('..', 'THUG Pro Kali v2 - 1.2 Dev', 'data', 'pre')
    dev = {f.lower() for f in os.listdir(devpre)} if os.path.isdir(devpre) else set()
    keys = set(menu_keys()) - {'skateshop', 'east_la'}
    rows, report = [], []
    tmp = tempfile.mkdtemp()
    try:
        for name, body in g.levels():
            lvl = g.unq(g.field(body, 'level'))
            key = lvl.lower()
            if key not in keys:
                continue
            p = g.unq(g.field(body, 'pre')).replace('.pre', '.prx').lower()
            tp = g.unq(g.field(body, 'thugpro_prx')).replace('.pre', '.prx').lower()
            extra = files[tp] if tp and tp in files else '-'
            scene = any((lvl + x).lower() in files for x in ('scn.prx', 'scn_thugpro.prx'))
            if p not in files or not scene:
                # not built from a plain install: THUG2 levels (THUG Pro reads them from the player's THUG2 game)
                # and levels added to a game folder by hand. Their cleaned node array comes from the server build.
                got = from_server_build(key)
                if not got:
                    report.append('%s: not in a plain THUG Pro install or the server build' % key)
                    continue
                inner, data = got
                # the server build read it from the THUG2 game (every THUG Pro player has it) unless the Dev folder
                # has the level's files itself: then it was added by hand and only some players have it
                need = '-' if scene or p not in dev else lvl + 'scn.prx'
                open(os.path.join(dst, key + '.qb'), 'wb').write(data)
                rows.append('mainmenu_%s_scripts.prx %s.qb %s %s %s' % (key, key, inner, extra, need))
                report.append('%s: from the server build%s' % (key, '' if need == '-' else ' (only where %s is installed)' % need))
                continue
            archives = [os.path.join(pre, files[p])]
            if extra != '-':
                archives.append(os.path.join(pre, extra))
            qbpath = g.unq(g.field(body, 'qb')) or 'levels\\\\%s\\\\%s.qb' % (lvl, lvl)
            e = g.find_qb(archives, qbpath)
            if not e:
                report.append('%s: node array %s not found' % (key, qbpath))
                continue
            base = e['name'].replace('/', '\\').split('\\')[-1]
            work = os.path.join(tmp, key)
            os.makedirs(work)
            open(os.path.join(work, base), 'wb').write(g.entry_bytes(e))
            subprocess.run([sys.executable, '-I', QB, 'd', '--names', g.NAMES, os.path.join(work, 'd'),
                            os.path.join(work, base)], capture_output=True, text=True)
            prefix = base[:-3]
            qf = os.path.join(work, 'd', prefix + '.q')
            if not os.path.isfile(qf):
                report.append('%s: decompile failed' % key)
                continue
            src = open(qf, encoding='latin1').read()
            inner = 'levels\\mainmenu_%s\\%s' % (key, base)
            builds = []
            if key in amb.ALLOW:
                g.AMBIENT_KEEP.add(prefix.upper())
            try:
                builds.append((key, compile_q(g.clean(src, prefix, []), work, 'clean')))
            finally:
                g.AMBIENT_KEEP.discard(prefix.upper())
            if key in amb.ALLOW:
                g.LIVE_KEEP.add(prefix.upper())
                try:
                    builds.append((key + '_live', compile_q(g.clean(src, prefix, []), work, 'live')))
                finally:
                    g.LIVE_KEEP.discard(prefix.upper())
            for k, data in builds:
                open(os.path.join(dst, k + '.qb'), 'wb').write(data)
                rows.append('mainmenu_%s_scripts.prx %s.qb %s %s -' % (k, k, inner, extra))
            report.append('%s: built%s' % (key, ' (+ live map)' if len(builds) > 1 else ''))
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    # East LA (level_Mainmenu_EL, the default menu level): its menu node array is kept as source in mods/mainmenu_el
    # (on the build machine only; the level data isn't in the repo)
    el = os.path.join('mods', 'mainmenu_el', 'levels', 'mainmenu_el', 'z_el.q')
    if 'z_el_scripts.prx' in files and 'z_elscn.prx' in files and os.path.isfile(el):
        work = tempfile.mkdtemp()
        try:
            data = compile_q(open(el, encoding='latin1').read(), work, 'z_el')
        finally:
            shutil.rmtree(work, ignore_errors=True)
        open(os.path.join(dst, 'el.qb'), 'wb').write(data)
        rows.insert(0, 'mainmenu_el_scripts.prx el.qb levels\\mainmenu_el\\z_el.qb - -')
        report.insert(0, 'east_la: built from mods/mainmenu_el')
    else:
        report.insert(0, 'east_la: not built (z_el files or mods/mainmenu_el missing)')
    open(os.path.join(dst, 'list.txt'), 'w', encoding='latin1', newline='\r\n').write('\n'.join(rows) + '\n')
    open(os.path.join(out, 'report.txt'), 'w', encoding='latin1').write('\n'.join(report) + '\n')
    print('%d menu level archives; %d levels not in a plain install' % (len(rows), sum('not in' in r for r in report)))


if __name__ == '__main__':
    main(sys.argv[1:])
