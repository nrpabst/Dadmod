"""Ambient life on the main menu (Noah, 2026-10-23): rebuilds the menu version of the allowlisted levels twice.

  python -I mods/mainmenu/gen_menu_ambient.py      (from work/)

Writes
  build/menulevels_ambient/data/pre/mainmenu_<key>_scripts.prx       the normal menu map, its human ambient
        pedestrians kept as real Pedestrian nodes (not created at load) for Ambient life = People
  build/menulevels_ambient/data/pre/mainmenu_<key>_live_scripts.prx  the "live" menu map: people and vehicles
        exactly as in free skate (Ambient life = People + traffic); animals stay stripped
  mods/mainmenu/menu_ambient.q   dadmod_menu_ambient_list (the peds per level, a script so it can be live-loaded)
        and the level_Mainmenu_<key>_live structures; appended to Levels.q by the make script
People: Levels.q dadmod_menu_ambient_spawn creates them, skipping any near the skater's spot or in the camera's line.
Traffic: Load_MainMenu loads level_Mainmenu_<key>_live (THUGRECOMP_MenuOpt key = "ambient_level").
Reads the level files from the Dev folder; everything else comes from gen_menulevels.py.
"""
import os, sys, subprocess, shutil
sys.path.insert(0, 'tools')
sys.path.insert(0, os.path.join('mods', 'mainmenu'))
import gen_menulevels as g
import prx_pack
from qb import qbkey

ALLOW = ['z_ho', 'z_bh']   # levels that get ambient life (keys as in kMenuLevels; also in mainmenu.inc kAmbientLevels)
g.PRE = os.path.join('..', 'THUG Pro Kali v2 - 1.2 Dev', 'data', 'pre')
OUT = os.path.join('build', 'menulevels_ambient')
TMP = os.path.join(OUT, 'tmp')
QB = os.path.join('tools', 'qb.py')


def compile_q(text, work, stem):
    q, qb = os.path.join(work, stem + '.q'), os.path.join(work, stem + '.qb')
    open(q, 'w', encoding='latin1', newline='\n').write(text)
    r = subprocess.run([sys.executable, '-I', QB, 'c', q, qb], capture_output=True, text=True)
    if r.returncode or not os.path.isfile(qb):
        raise RuntimeError('compile failed: ' + r.stdout[-300:] + r.stderr[-300:])
    return open(qb, 'rb').read()


def main():
    if os.path.isdir(TMP): shutil.rmtree(TMP)
    os.makedirs(os.path.join(OUT, 'data', 'pre'), exist_ok=True)
    os.makedirs(TMP)
    shop = g.prx_entries(os.path.join(g.PRE, 'Skateshop_scripts.prx'))
    files = {f.lower(): os.path.join(g.PRE, f) for f in os.listdir(g.PRE)}
    found, live = {}, []
    for name, body in g.levels():
        lvl = g.unq(g.field(body, 'level'))
        key = lvl.lower()
        if key not in ALLOW:
            continue
        pre = g.unq(g.field(body, 'pre'))
        archives = [files[pre.replace('.pre', '.prx').lower()]]
        tp = g.unq(g.field(body, 'thugpro_prx'))
        if tp and tp.replace('.pre', '.prx').lower() in files:
            archives.append(files[tp.replace('.pre', '.prx').lower()])
        qbpath = g.unq(g.field(body, 'qb')) or 'levels\\\\%s\\\\%s.qb' % (lvl, lvl)
        e = g.find_qb(archives, qbpath)
        base = e['name'].replace('/', '\\').split('\\')[-1]
        work = os.path.join(TMP, key)
        os.makedirs(work)
        open(os.path.join(work, base), 'wb').write(g.entry_bytes(e))
        subprocess.run([sys.executable, '-I', QB, 'd', '--names', g.NAMES, os.path.join(work, 'd'),
                        os.path.join(work, base)], capture_output=True, text=True)
        prefix = base[:-3]
        src = open(os.path.join(work, 'd', prefix + '.q'), encoding='latin1').read()
        g.AMBIENT_KEEP.add(prefix.upper())
        normal = compile_q(g.clean(src, prefix, []), work, 'clean')
        g.AMBIENT_KEEP.discard(prefix.upper())
        g.LIVE_KEEP.add(prefix.upper())
        livebin = compile_q(g.clean(src, prefix, []), work, 'live')
        g.LIVE_KEEP.discard(prefix.upper())
        ents = [dict(x) for x in shop]
        if len(archives) > 1:
            have = {x['name'].lower() for x in ents}
            for x in g.prx_entries(archives[1]):
                if x['name'].lower() not in have:
                    ents.append(dict(x))
        inner = 'levels\\mainmenu_%s\\%s' % (key, base)
        for data, out in ((normal, 'mainmenu_%s_scripts.prx' % key), (livebin, 'mainmenu_%s_live_scripts.prx' % key)):
            prx_pack.write_archive(ents + [{'name': inner, 'usz': len(data), 'csz': 0, 'ck': qbkey(inner), 'data': data}],
                                   os.path.join(OUT, 'data', 'pre', out))
        found[key] = g.AMBIENT_FOUND.get(prefix.upper(), [])
        live.append(key)
        print(key, len(found[key]), 'ambient peds; live map built')
    o = ['script dadmod_menu_ambient_list', '    peds = [ ]', '    switch <level>']
    for key, peds in found.items():
        o.append('    case %s' % key)
        o.append('        peds = [')
        for nm, pos in peds:
            o.append('        { n = %s p = %s }' % (nm, pos))
        o.append('        ]')
    o += ['    endswitch', '    return peds = <peds>', 'endscript']
    data = open(os.path.join('mods', 'mainmenu', 'menulevels_data.q'), encoding='latin1').read().replace('\r\n', '\n')
    for key in live:
        a = data.index('level_Mainmenu_%s = {' % key)
        b = data.index('\n}\n', a) + 2
        st = data[a:b].replace('level_Mainmenu_%s' % key, 'level_Mainmenu_%s_live' % key)
        st = st.replace('mainmenu_%s_scripts.pre' % key, 'mainmenu_%s_live_scripts.pre' % key)
        o += st.split('\n')
    open(os.path.join('mods', 'mainmenu', 'menu_ambient.q'), 'w', newline='\n').write('\n'.join(o) + '\n')


if __name__ == '__main__':
    main()
