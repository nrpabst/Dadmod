r"""Client build: dadmod_qb.prx (our own script archive) + binkw32.dll (client loader).

    python -I client/make_client.py [--out build/client] [--no-dll] [--gen] [--menulevels] [--package] [--release DIR]   (run from work/)

The output folder is laid out like a game folder (binkw32.dll, data\pre\dadmod_qb.prx,
data\dadmod_casidle.qb, dadmod\menulevels); the installer copies it in. --gen first refreshes client/qb/gen from the
server build tree (client/tools/gen_client_qb.py; run a server build before it). --menulevels remakes the
main menu scenes from a plain THUG Pro install (client/tools/build_menulevels.py; done anyway the first time).
--package also makes the player package (build/dadmod-client-<version>.zip; client/installer).

Never replaces thugpro_qb.prx and never writes into a game folder: it refuses an output folder
that has THUGPro.exe in it or above it. Installing is the installer's job.

What goes in (see client/README.md):
  client/qb/**/*.q   compiled to qb\\<same path>.qb, loaded in path order (gen/ = generated, dadmod/ = by hand)
  client/wrap.txt    stock scripts renamed to <name>_orig before ours load
  client/vault_levels.txt  extra level files (data\pre, data\sounds) the package ships from the Dev folder (--package)
The server build (build/obsspawn_test_make.sh) is not touched by this script.
"""
import os, re, shutil, subprocess, sys, tempfile

WORK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(WORK, 'tools'))
from qb import compile_q            # noqa: E402
from prx_pack import write_archive, stored  # noqa: E402

CLIENT = os.path.join(WORK, 'client')
# dadmod's version (Noah 2026-11-06: 0.9.0 beta first, 1.0 once players have used it a while). Scripts get it
# where they say @DADMOD_VERSION@; the installer reads dadmod\version.txt; the zip is named after it.
VERSION = open(os.path.join(CLIENT, 'VERSION')).read().strip()
# the extra built-in levels' files come from this game folder (read only) and must not exist in these plain installs
VAULT_SRC = os.path.join(WORK, '..', 'THUG Pro Kali v2 - 1.2 Dev')
# the game builds the recipes are made against (read only): plain THUG Pro, the newer and the older Kali Mod, and a
# fresh THUG Pro + the public Kali download with no thugpro_qe.prx (Noah 2026-11-18: players who only dragged in
# Kali's data folder have no thugpro_qe.prx; made by client/tools/make_recipe_game_kali.py)
KALI_DOWNLOAD_GAME = os.path.join(WORK, '..', 'recipe_games', 'THUG Pro + Kali download')
RECIPE_GAMES = [os.path.join(WORK, '..', 'cleanup_archive_20261116', 'THUG Pro REAL BASE INSTALL'),
                os.path.join(WORK, '..', 'THUG Pro Kali v2 - 1.2 Original'), r'E:\THUG Pro Kali v2 (use this)',
                KALI_DOWNLOAD_GAME]
RECIPE_SOURCES = [os.path.join('data', 'pre', 'thugpro_qb.prx'), os.path.join('data', 'pre', 'Skateshop_scripts.prx')]
PLAIN_GAMES = [os.path.join(WORK, '..', d) for d in (os.path.join('cleanup_archive_20261116', 'THUG Pro REAL BASE INSTALL'), 'THUG Pro Kali v2 - 1.2 Original')]


def refuse_game_folder(out):
    p = os.path.abspath(out)
    while True:
        if os.path.isfile(os.path.join(p, 'THUGPro.exe')):
            sys.exit(f'refusing to build into a game folder: {p}')
        up = os.path.dirname(p)
        if up == p:
            return
        p = up


def lines(path):
    if not os.path.isfile(path):
        return []
    out = []
    for ln in open(path, encoding='latin1').read().splitlines():
        ln = ln.strip()
        if ln and not ln.startswith('#'):
            out.append(ln)
    return out


# (dadmod_chatart_boot is Dev only: chat art is not in the release, Noah 2026-11-17)
MENU_BOOT_CALLS = ['dadmod_noclip_boot', 'dadmod_speed_boot', 'dadmod_levelthumbs_boot']


def check_menu_boot_calls():
    """Load_MainMenu must call every boot script (2026-11-17: a menu scene regenerate dropped them and the level
    select THPG tab crashed on its unloaded logo). Same list as BOOT_CALLS in mods/mainmenu/gen_menulevels.py."""
    gen = os.path.join(CLIENT, 'qb', 'gen')
    for f in sorted(os.listdir(gen)):
        if not f.endswith('.q'):
            continue
        text = open(os.path.join(gen, f), encoding='latin1').read().replace('\r', '')
        i = text.find('script Load_MainMenu\n')
        if i < 0:
            continue
        body = text[i:text.index('endscript', i)]
        missing = [b for b in MENU_BOOT_CALLS if ('    %s\n' % b) not in body]
        if missing:
            sys.exit('QB BUILD FAILED: Load_MainMenu is missing ' + ', '.join(missing))
        return
    sys.exit('QB BUILD FAILED: Load_MainMenu not found in client/qb/gen')


def build_prx(out):
    qroot = os.path.join(CLIENT, 'qb')
    sources = sorted(os.path.join(d, f) for d, _, fs in os.walk(qroot) for f in fs if f.endswith('.q'))
    entries, qdir = [], []
    for src in sources:
        rel = os.path.relpath(src, CLIENT)[:-2] + '.qb'           # qb/dadmod/x.qb
        name = rel.replace('/', '\\').replace(os.sep, '\\')
        try:
            text = open(src, encoding='latin1').read().replace('@DADMOD_VERSION@', VERSION)
            data = compile_q(text)
        except Exception as e:
            sys.exit(f'QB BUILD FAILED: {os.path.relpath(src, WORK)}: {e}')
        if len(data) > 512 * 1024:
            sys.exit(f'QB TOO BIG: {name} is {len(data) // 1024} KB (limit 512 KB)')
        entries.append(stored(name, data))
        qdir.append('data\\' + name)
    # generated: the extra levels' level select pictures (build_levelthumbs makes the archive they load from)
    try:
        entries.append(stored('qb\\dadmod\\levelthumbs.qb', compile_q(levelthumbs_q(build_levelthumbs(out)))))
    except Exception as e:
        sys.exit(f'QB BUILD FAILED: levelthumbs: {e}')
    qdir.append('data\\qb\\dadmod\\levelthumbs.qb')
    wrap = lines(os.path.join(CLIENT, 'wrap.txt'))
    entries.insert(0, stored('code\\dadmod\\qdir.txt', ''.join(q + '\r\n' for q in qdir).encode('latin1')))
    entries.insert(1, stored('code\\dadmod\\wrap.txt', ''.join(w + '\r\n' for w in wrap).encode('latin1')))
    os.makedirs(os.path.join(out, 'data', 'pre'), exist_ok=True)
    dst = os.path.join(out, 'data', 'pre', 'dadmod_qb.prx')
    write_archive(entries, dst)
    print(f'dadmod_qb.prx: {len(qdir)} script files, {len(wrap)} wrapped stock scripts')


LEVELTHUMBS = os.path.join(CLIENT, 'levelthumbs')


def build_levelthumbs(out):
    """data\\pre\\dadmod_levelselect.prx from client/levelthumbs/<key>.png (keys in levels.txt) -> [(key, level checksum)]
    of the levels that got a picture. No pictures: no archive, and those levels keep their stock picture.
    Same code as the server build (tools/levelthumbs.py)."""
    import levelthumbs
    have = levelthumbs.archive(os.path.join(out, 'data', 'pre', 'dadmod_levelselect.prx'))
    print(f'dadmod_levelselect.prx: {len(have)} level pictures' + ('' if have else ' (none: no archive)'))
    return have


def levelthumbs_q(have):
    """dadmod_levelthumb_for + dadmod_levelthumbs_load (tools/levelthumbs.py; the client loads from the
    load_update_level_select_textures_to_main_memory wrap in client_boot.q)"""
    import levelthumbs
    return levelthumbs.qb_text(have)


def build_casidle(out):
    """data\\dadmod_casidle.qb: Edit Skater on the menu levels + mix and match (mods/casmod), same files as the server
    build. All our own code (Noah 2026-11-18): no generator reads THUG Pro's scripts any more, so the file ships as it
    is (no recipe) and works with any skate shop scripts the player has (plain THUG Pro, Kali, CAS mods)."""
    parts = [os.path.join(WORK, 'mods', *p.split('/')) for p in CASIDLE_PARTS]
    text = ''.join(open(p, encoding='latin1').read().replace('\r\n', '\n').rstrip('\n') + '\n' for p in parts)
    # mid-game Load Skater (mods/midload): Edit Skater changes mark the skater unsaved, same as the server build
    sys.path.insert(0, os.path.join(WORK, 'mods', 'midload'))
    from apply import hook_casidle   # noqa: E402
    text = hook_casidle(text)
    try:
        data = compile_q(text)
    except Exception as e:
        sys.exit(f'QB BUILD FAILED: dadmod_casidle.qb: {e}')
    if len(data) > 512 * 1024:
        sys.exit(f'QB TOO BIG: dadmod_casidle.qb is {len(data) // 1024} KB (limit 512 KB)')
    with open(os.path.join(out, 'data', 'dadmod_casidle.qb'), 'wb') as f:
        f.write(data)
    print(f'dadmod_casidle.qb: Edit Skater scripts ({len(data) // 1024} KB)')


# the Edit Skater qb, in load order (build/obsspawn_test_make.sh concatenates the same list)
CASIDLE_PARTS = ['mainmenu/casidle.q', 'casmod/lists.q', 'casmod/logo_adjust.q', 'casmod/sexchange.q', 'casmod/offline.q',
                 'casmod/undress.q', 'casmod/menus.q', 'casmod/removeitems.q', 'casmod/qol.q', 'casmod/ownmenus.q']


def copy_menulevels(out, rebuild):
    """dadmod\\menulevels: one cleaned node array per main menu scene + list.txt (client/tools/build_menulevels.py,
    which reads a plain THUG Pro install; --menulevels reruns it). The DLL builds the scene archives from them."""
    src = os.path.join(WORK, 'build', 'client_menulevels', 'dadmod', 'menulevels')
    if rebuild or not os.path.isfile(os.path.join(src, 'list.txt')):
        r = subprocess.run([sys.executable, '-I', os.path.join(CLIENT, 'tools', 'build_menulevels.py')], cwd=WORK)
        if r.returncode:
            sys.exit('MENU LEVELS FAILED: build_menulevels.py')
    rows = lines(os.path.join(src, 'list.txt'))
    dst = os.path.join(out, 'dadmod', 'menulevels')
    os.makedirs(dst, exist_ok=True)
    for f in sorted({r.split()[1] for r in rows} | {'list.txt'}):
        shutil.copyfile(os.path.join(src, f), os.path.join(dst, f))
    print(f'dadmod\\menulevels: {len(rows)} main menu scenes')


def build_dll(out):
    """MSVC on Windows (native/build.bat, like the server build); elsewhere clang targeting MinGW,
    which understands the MSVC-style __asm blocks some mods use."""
    nat = os.path.join(CLIENT, 'native')
    dll = os.path.join(out, 'binkw32.dll')
    if os.name == 'nt':
        r = subprocess.run(['cmd', '/c', os.path.join(nat, 'build.bat')], capture_output=True, text=True)
        built = os.path.join(nat, 'binkw32.dll')
        log = r.stdout + r.stderr
        if r.returncode or ' error' in log.lower() or not os.path.isfile(built):
            sys.exit('DLL BUILD FAILED:\n' + log)
        shutil.move(built, dll)
        for junk in ('loader.obj', 'binkw32.exp', 'binkw32.lib'):
            if os.path.isfile(os.path.join(nat, junk)):
                os.remove(os.path.join(nat, junk))
        print('binkw32.dll: client loader (MSVC)')
        return
    clang = shutil.which('clang++')
    if not clang or not shutil.which('i686-w64-mingw32-ld'):
        sys.exit('DLL BUILD FAILED: needs Windows + MSVC, or clang++ with the i686 MinGW toolchain (use --no-dll to skip)')
    r = subprocess.run([clang, '--target=i686-w64-mingw32', '-fms-extensions', '-fasm-blocks', '-O2', '-std=c++17',
                        '-shared', '-static', '-static-libgcc', '-static-libstdc++', '-o', dll,
                        os.path.join(nat, 'loader.cpp'), os.path.join(nat, 'binkw32.def'),
                        '-Wl,--enable-stdcall-fixup', '-ld3d9', '-ldinput8', '-ldxguid', '-lsetupapi', '-lhid'],
                       capture_output=True, text=True)
    if r.returncode:
        sys.exit('DLL BUILD FAILED:\n' + r.stdout + r.stderr)
    print('binkw32.dll: client loader (clang/MinGW)')


def package(out, release=None):
    """build/dadmod-client-<version>.zip: what players unzip (one folder, dadmod-install). README.txt, Install dadmod.bat /
    Uninstall dadmod.bat, installer\\dadmod.ps1 and files\\ (copied into the game folder by the installer).
    Only the files this build makes go in, never leftovers in the output folder."""
    import zipfile
    inst = os.path.join(CLIENT, 'installer')
    with open(os.path.join(out, 'dadmod', 'version.txt'), 'w', newline='\r\n') as f:
        f.write(VERSION + '\n')
    want = ['dadmod/version.txt'.replace('/', os.sep), 'binkw32.dll', os.path.join('data', 'pre', 'dadmod_qb.prx'), os.path.join('data', 'dadmod_casidle.qb')]
    # the game's updater (Pause > dadmod > Update dadmod; native/update.inc) runs this copy of the installer from
    # <game>\dadmod\updater (Noah 2026-11-18)
    os.makedirs(os.path.join(out, 'dadmod', 'updater'), exist_ok=True)
    shutil.copyfile(os.path.join(inst, 'dadmod.ps1'), os.path.join(out, 'dadmod', 'updater', 'dadmod.ps1'))
    want.append(os.path.join('dadmod', 'updater', 'dadmod.ps1'))
    if os.path.isfile(os.path.join(out, 'data', 'pre', 'dadmod_levelselect.prx')):     # built only when there are pictures
        want.append(os.path.join('data', 'pre', 'dadmod_levelselect.prx'))
    ml = os.path.join('dadmod', 'menulevels')
    rows = lines(os.path.join(out, ml, 'list.txt'))
    want += [os.path.join(ml, 'list.txt')] + sorted({os.path.join(ml, r.split()[1]) for r in rows})
    want += default_settings(out)
    # files made partly from THUG Pro / Kali scripts ship as recipes (tools/dadpatch.py): the installer rebuilds
    # them byte for byte from the player's own game files (Noah 2026-11-17: no stock bytes in the release)
    import dadpatch, scene_recipes
    rdir = os.path.join(WORK, 'build', 'recipes')
    os.makedirs(rdir, exist_ok=True)
    recipes = []
    # the extra levels' files the release installs (read from the Dev folder at build time) count as the player's
    for row in lines(os.path.join(CLIENT, 'vault_levels.txt')):
        rel = row.split()[0]
        dadpatch.OVERLAY[rel.lower()] = os.path.join(VAULT_SRC, rel)
    extra = [r for r in dadpatch.OVERLAY if r.endswith('_scripts.prx')]
    if not os.path.isfile(os.path.join(KALI_DOWNLOAD_GAME, 'data', 'pre', 'thugpro_qb.prx')):
        sys.exit('PACKAGE FAILED: %s is missing; run python -I client/tools/make_recipe_game_kali.py first' % KALI_DOWNLOAD_GAME)
    games = [g for g in RECIPE_GAMES if os.path.isfile(os.path.join(g, 'data', 'pre', 'thugpro_qb.prx'))]
    # build reuse (Noah 2026-11-17: "reuse everything from the previous build when the source hasn't changed"): each
    # recipe and audit result is kept in build/recipes/reuse.json under a hash of its inputs (the target file, every
    # stock source file's size and time, the tool code); only targets whose inputs changed are remade
    import hashlib, json
    cache_path = os.path.join(rdir, 'reuse.json')
    try:
        old_cache = json.load(open(cache_path))
    except Exception:
        old_cache = {}
    new_cache = {}
    h = hashlib.sha1()
    for t in ('dadpatch.py', 'scene_recipes.py', 'stock_audit.py'):
        h.update(open(os.path.join(WORK, 'tools', t), 'rb').read())
    for g in games:
        for src in dadpatch.all_script_sources(g) + extra:
            full = dadpatch.resolve(g, src)
            st = os.stat(full) if full and os.path.isfile(full) else None
            h.update(('%s|%s|%s|%s;' % (g, src, st.st_size if st else -1, int(st.st_mtime) if st else -1)).encode('utf-8', 'replace'))
    corpus_key = h.hexdigest()
    corpora_box = []
    noshop_box = []

    def get_corpora():
        if not corpora_box:
            # one corpus per game: every stock script archive the player has (THUG Pro, Kali, THUG2 levels) + the extra levels
            corpora_box.extend(dadpatch.Corpus(g, dadpatch.all_script_sources(g) + extra) for g in games)
            print('recipe sources: ' + '; '.join('%s %d files' % (os.path.basename(c.game), len(c.sources)) for c in corpora_box))
        return corpora_box

    # dadmod_qb.prx must not depend on Skateshop_scripts.prx (Noah 2026-11-18: the CAS mod replaces that file and
    # dadmod must install with or without it), so its recipe is made from every source except that one
    def no_shop(srcs):
        return [s for s in srcs if os.path.basename(s).lower() != 'skateshop_scripts.prx']

    def get_corpora_noshop():
        if not noshop_box:
            noshop_box.extend(dadpatch.Corpus(g, no_shop(dadpatch.all_script_sources(g) + extra)) for g in games)
            print('recipe sources (no Skateshop_scripts.prx): ' + '; '.join('%s %d files' % (os.path.basename(c.game), len(c.sources)) for c in noshop_box))
        return noshop_box

    def reuse(key, path):
        e = old_cache.get(key)
        if e and os.path.isfile(path) and hashlib.sha1(open(path, 'rb').read()).hexdigest() == e:
            new_cache[key] = e
            return True
        return False

    def remember(key, path):
        new_cache[key] = hashlib.sha1(open(path, 'rb').read()).hexdigest()

    reused = 0
    # dadmod_casidle.qb is all our own code (2026-11-18) and ships as a normal file
    for rel in (os.path.join('data', 'pre', 'dadmod_qb.prx'),):
        want.remove(rel)
        name = os.path.splitext(os.path.basename(rel))[0] + '.dpr'
        key = 'recipe-noshop|%s|%s|%s' % (name, corpus_key, hashlib.sha1(open(os.path.join(out, rel), 'rb').read()).hexdigest())
        recipes.append(name)
        if reuse(key, os.path.join(rdir, name)):
            reused += 1
            continue
        b, variants, target = dadpatch.make(os.path.join(out, rel), rel.replace(os.sep, chr(92)), None, corpora=get_corpora_noshop())
        if b'skateshop_scripts.prx' in b.lower():
            sys.exit('PACKAGE FAILED: recipe %s still reads Skateshop_scripts.prx' % name)
        open(os.path.join(rdir, name), 'wb').write(b)
        for g in games:
            if dadpatch.apply_recipe(b, g) != target:
                sys.exit('PACKAGE FAILED: recipe %s does not rebuild on %s' % (name, g))
        remember(key, os.path.join(rdir, name))
        print('recipe %s: %d variants, %s' % (name, len(variants), '; '.join(dadpatch.stats(variants, target))))
    # main menu scenes: rebuilt from the player's own level script archives (THUG2 levels from the THUG2 folder THUG Pro
    # uses, the extra levels from the files the release installs)
    mdir = os.path.join(rdir, 'menulevels')
    os.makedirs(mdir, exist_ok=True)
    mlsrc = os.path.join(out, 'dadmod', 'menulevels')
    made, bad, seen = [], [], set()
    for row in scene_recipes.rows(mlsrc):
        qb = row[1]
        if qb in seen:
            continue
        seen.add(qb)
        name = os.path.splitext(qb)[0] + '.dpr'
        tfile = os.path.join(mlsrc, qb)
        key = 'scene|%s|%s|%s' % (name, corpus_key, hashlib.sha1(open(tfile, 'rb').read()).hexdigest())
        if reuse(key, os.path.join(mdir, name)):
            reused += 1
            made.append(name)
            continue
        cs = get_corpora()
        b, variants, target = dadpatch.make(tfile, os.path.join('dadmod', 'menulevels', qb), None, corpora=cs)
        if not any(dadpatch.apply_recipe(b, c.game) == target for c in cs):
            bad.append('%s: NO GAME REBUILDS IT' % qb)
            continue
        open(os.path.join(mdir, name), 'wb').write(b)
        remember(key, os.path.join(mdir, name))
        made.append(name)
    if bad:
        sys.exit('PACKAGE FAILED: ' + '; '.join(bad))
    print('recipes reused from the previous build: %d' % reused)
    for name in made:
        rel = os.path.join('dadmod', 'menulevels', os.path.splitext(name)[0] + '.qb')
        if rel in want:
            want.remove(rel)
        recipes.append('menulevels/' + name)
    print('recipes: %d main menu scenes' % len(made))
    # Noah 2026-11-17: the player's zip holds only Setup.bat, README.txt and files.dad. files.dad is a zip of
    # installer\ and files\ behind a 16-byte header (DADMODPK1, key in byte 15) with every byte XORed with the key, so
    # zip tools don't open it; Setup.bat unpacks it to a temp folder with plain PowerShell and runs the installer there
    # audit (Noah 2026-11-17): nothing in files.dad may carry THUG Pro / Kali bytes. Allowed: the extra levels Noah
    # chose (vault_levels.txt: Larxian's cities, P8/Vault/THPG maps) and binkw32.dll (ours, the game's own is renamed)
    import stock_audit
    # a recipe's own bytes are its inserts (its header only names the player's files it copies from)
    check = [('%s#%d' % (n, k), ins) for n in recipes for k, ins in enumerate(dadpatch.inserts(open(os.path.join(rdir, n), 'rb').read()))]
    check += [(rel, open(os.path.join(out, rel), 'rb').read()) for rel in want if os.path.basename(rel).lower() != 'binkw32.dll']
    for f in ('dadmod.ps1', 'recipes.cs', 'README.txt', 'Setup.bat'):
        check.append(('installer/' + f, open(os.path.join(inst, f), 'rb').read()))
    def akey(n, d):
        return 'audit|%s|%s|%s' % (corpus_key, n, hashlib.sha1(d).hexdigest())
    todo = [(n, d) for n, d in check if akey(n, d) not in old_cache]
    for n, d in check:
        if akey(n, d) in old_cache:
            new_cache[akey(n, d)] = 1
    ncorpus = old_cache.get('audit_ncorpus|' + corpus_key, 0)
    hits = []
    if todo or not ncorpus:
        hits, ncorpus = stock_audit.audit(todo, [g for g in RECIPE_GAMES if os.path.isdir(g)])
    print('audit: %d files reused as clean, %d checked' % (len(check) - len(todo), len(todo)))
    if not hits:
        for n, d in todo:
            new_cache[akey(n, d)] = 1
        new_cache['audit_ncorpus|' + corpus_key] = ncorpus
    json.dump(new_cache, open(cache_path, 'w'))
    if hits:
        for h in hits[:20]:
            print('  STOCK BYTES: %s at %d (same as %s)' % h)
        sys.exit('PACKAGE FAILED: %d files carry THUG Pro / Kali bytes' % len(hits))
    print('audit: %d files clean (no run of %d+ bytes from %d stock script files)' % (len(check), stock_audit.RUN, ncorpus))
    z = os.path.join(release or os.path.join(WORK, 'build', 'release_%s' % VERSION), 'dadmod.zip')
    os.makedirs(os.path.dirname(z), exist_ok=True)
    inner = os.path.join(WORK, 'build', 'dadmod-client-%s.inner.zip' % VERSION)
    # Noah 2026-11-18 (max compression): the inner zip is stored (no compression) and the whole zip is packed with
    # LZMA preset 9 extreme (solid, so files share one dictionary) -> DADMODPK2. Windows 10's tar.exe has no xz/LZMA,
    # so Setup.bat and the updater in dadmod.ps1 carry our own C# LZMA reader (installer\DadmodPack2.cs, the same text
    # pasted into both; checked here)
    dcs = open(os.path.join(inst, 'DadmodPack2.cs'), encoding='ascii').read().replace('\r\n', '\n').rstrip('\n')
    for f in ('Setup.bat', 'dadmod.ps1'):
        if dcs not in open(os.path.join(inst, f), encoding='ascii').read().replace('\r\n', '\n'):
            sys.exit('PACKAGE FAILED: installer/%s does not hold the current DadmodPack2.cs' % f)
    with zipfile.ZipFile(inner, 'w', zipfile.ZIP_STORED) as zf:
        zf.write(os.path.join(inst, 'dadmod.ps1'), 'installer/dadmod.ps1')
        zf.write(os.path.join(inst, 'recipes.cs'), 'installer/recipes.cs')
        for name in recipes:
            zf.write(os.path.join(rdir, name), 'recipes/' + name)
        for rel in want:
            src = os.path.join(out, rel)
            if not os.path.isfile(src):
                sys.exit('PACKAGE FAILED: missing ' + rel)
            zf.write(src, 'files/' + rel.replace(os.sep, '/'))
        vault = vault_files()
        for rel, src in vault:
            zf.write(src, 'files/' + rel.replace('\\', '/'))
        # the installer keeps a player's own copy of these instead of replacing it; the md5 tells it whether the
        # player's copy is the same version (installer names a different one in its summary)
        md5s = {row.split()[0].lower(): row.split()[1].lower() for row in lines(os.path.join(CLIENT, 'vault_levels.txt'))}
        zf.writestr('installer/vault_levels.txt', ''.join('%s %s\r\n' % (rel, md5s[rel.lower()]) for rel, _ in vault))
    key = 0xA7
    table = bytes(b ^ key for b in range(256))
    dpk = os.path.join(WORK, 'build', 'files.dad')
    import lzma, time
    t0 = time.time()
    lz = lzma.LZMACompressor(format=lzma.FORMAT_ALONE, filters=[{'id': lzma.FILTER_LZMA1, 'preset': 9 | lzma.PRESET_EXTREME}])
    with open(inner, 'rb') as fi, open(dpk, 'wb') as fo:
        fo.write(b'DADMODPK2' + bytes(6) + bytes([key]))
        while True:
            chunk = fi.read(1 << 22)
            if not chunk:
                break
            fo.write(lz.compress(chunk).translate(table))
        fo.write(lz.flush().translate(table))
    print('files.dad: %d MB stored -> %d MB LZMA (%d s)' % (os.path.getsize(inner) >> 20, os.path.getsize(dpk) >> 20, time.time() - t0))
    os.remove(inner)
    with zipfile.ZipFile(z, 'w', zipfile.ZIP_DEFLATED) as zf:
        zf.write(os.path.join(inst, 'Setup.bat'), 'dadmod-install/Setup.bat')
        # README.txt (was INSTALL.txt until Noah 2026-11-18) is UTF-8 (block-letter art, Noah 2026-11-17); a BOM so Notepad always shows it right
        txt = open(os.path.join(inst, 'README.txt'), encoding='utf-8-sig').read().replace('@DADMOD_VERSION@', VERSION)
        zf.writestr('dadmod-install/README.txt', ('\ufeff' + txt.replace('\r\n', '\n').replace('\n', '\r\n')).encode('utf-8'))  # Notepad-friendly
        zf.write(dpk, 'dadmod-install/files.dad', compress_type=zipfile.ZIP_STORED)  # scrambled: doesn't compress
    os.remove(dpk)
    size = sum(os.path.getsize(s) for _, s in vault)
    print(f'package: {len(want)} game files + {len(vault)} level files ({size // 1024} KB) + installer -> {os.path.relpath(z, WORK)}')


def default_settings(out):
    """Noah 2026-11-17: a new install starts with his Dev dadmod settings. Only dadmod's own settings: the Menu UI,
    text box, animations and player speed keys of dadmod\\panel_settings.txt (no server, host, chat or balance keys),
    dadmod\\gfx.ini, and dadmod\\mainmenu.ini. They go to dadmod\\defaults\\; the installer copies each one into
    dadmod\\ only when the player has none yet, so an update never touches a player's own settings."""
    dev = os.path.join(VAULT_SRC, 'dadmod')
    d = os.path.join(out, 'dadmod', 'defaults')
    os.makedirs(d, exist_ok=True)
    keep = ('ui_', 'desc_')
    keep_exact = {'anim_move', 'anim_loop', 'anim_star', 'player_speed'}
    rows = []
    for line in open(os.path.join(dev, 'panel_settings.txt'), encoding='latin-1'):
        k = line.split()[0] if line.split() else ''
        if k.startswith(keep) or k in keep_exact:
            rows.append(line.rstrip('\r\n'))
    with open(os.path.join(d, 'panel_settings.txt'), 'w', encoding='latin-1', newline='\r\n') as f:
        f.write('\n'.join(rows) + '\n')
    gl = [l.rstrip('\r\n') for l in open(os.path.join(dev, 'gfx.ini'), encoding='latin-1')
          if not l.split('=')[0].strip() in ('gfx_debug', 'gfx_shotdir')]
    # Noah 2026-11-18: a new install starts with every Graphics option off (the game as THUG Pro draws it); only the
    # non-graphics keys (screenshot key, controls, weather choices) keep Dev's values
    gfx_off = ('gfx_aniso', 'gfx_lodbias', 'gfx_uismooth', 'gfx_msaa', 'gfx_vsync', 'gfx_fxaa', 'gfx_sharpen', 'gfx_bloom',
               'gfx_ssao', 'gfx_fog', 'gfx_dof', 'gfx_outline', 'gfx_mblur', 'gfx_pixelate', 'gfx_vignette', 'gfx_grain',
               'gfx_chroma', 'gfx_crt', 'gfx_preset', 'gfx_bright', 'gfx_contrast', 'gfx_sat', 'gfx_vibrance', 'gfx_gamma',
               'gfx_temp', 'gfx_tint', 'gfx_galaxy', 'gfx_tod', 'gfx_weather', 'gfx_fireworks', 'gfx_lamps', 'gfx_skypop',
               'gfx_fps', 'gfx_shothud', 'gfx_mirror')
    gl = [(l.split('=')[0].strip() + ' = 0') if l.split('=')[0].strip() in gfx_off else l for l in gl]
    with open(os.path.join(d, 'gfx.ini'), 'w', encoding='latin-1', newline='\r\n') as f:
        f.write('\n'.join(gl) + '\n')
    ml = [l.rstrip('\r\n') for l in open(os.path.join(dev, 'mainmenu.ini'), encoding='latin-1')
          if not l.split('=')[0].strip() in ('random_last', 'custom_prev_pick')]
    # Noah 2026-11-17: no starred animations in the release; Pose mode starts on Default (the idle loops)
    ml = [l for l in ml if l.split('=')[0].strip() not in ('favorites', 'pose_one', 'pose_one_label')]
    # Noah 2026-11-17: Ambient life starts on People + cars
    ml = ['ambient_people = traffic' if l.split('=')[0].strip() == 'ambient_people' else l for l in ml]
    ml = ['pose_mode = default' if l.split('=')[0].strip() == 'pose_mode' else l for l in ml]
    # Noah 2026-11-17: ship his saved main menu spots with Custom menus = Random (each start picks one)
    ml = ['custom_random = on' if l.split('=')[0].strip() == 'custom_random' else l for l in ml]
    if not any(l.split('=')[0].strip() == 'custom_random' for l in ml):
        ml.insert(next(i for i, l in enumerate(ml) if l.strip() == '[menu]') + 1, 'custom_random = on')
    # Noah 2026-11-17: the East LA tram spot joins the random saved spots: a [home east_la] at the tram spot
    # (the [spot] marked on east_la in his Dev settings) when his settings have no saved East LA home yet
    if not any(l.strip().lower() == '[home east_la]' for l in ml):
        sec, spot = None, {}
        for l in ml:
            t = l.strip()
            if t.startswith('['):
                sec = t.lower()
            elif sec and sec.startswith('[spot') and '=' in t.split(';')[0]:
                k, v = [x.strip() for x in t.split(';')[0].split('=', 1)]
                spot.setdefault(sec, {})[k] = v
        tram = next((s for s in spot.values() if s.get('level', '').lower() == 'east_la' and 'pos' in s), None)
        if tram:
            ml += ['', '[home east_la]', 'name = East LA tram', 'pos = ' + tram['pos'], 'dir = ' + tram.get('dir', '0.0, 0.0, 1.0'),
                   'camera = none       ; none = the Camera mode / Camera shot cameras, aimed from this spot\'s front']
    with open(os.path.join(d, 'mainmenu.ini'), 'w', encoding='latin-1', newline='\r\n') as f:
        f.write('\n'.join(ml) + '\n')
    print('default settings: %d panel keys, gfx.ini, mainmenu.ini from Dev' % len(rows))
    return [os.path.join('dadmod', 'defaults', n) for n in ('panel_settings.txt', 'gfx.ini', 'mainmenu.ini')]


def vault_files():
    """client/vault_levels.txt: [(path in the game folder, source path)] after checking each file's md5 and that no
    plain install has a file at that path"""
    import hashlib
    for d in PLAIN_GAMES:
        if not os.path.isfile(os.path.join(d, 'THUGPro.exe')):
            sys.exit('PACKAGE FAILED: plain install not found: ' + d)
    out = []
    for row in lines(os.path.join(CLIENT, 'vault_levels.txt')):
        rel, md5 = row.split()
        src = os.path.join(VAULT_SRC, rel)
        if not os.path.isfile(src):
            sys.exit('PACKAGE FAILED: level file missing: ' + src)
        if hashlib.md5(open(src, 'rb').read()).hexdigest() != md5.lower():
            sys.exit('PACKAGE FAILED: %s changed (md5 is not the one in vault_levels.txt)' % src)
        for d in PLAIN_GAMES:
            p = os.path.join(d, rel)
            if os.path.exists(p):     # Windows: not case-sensitive
                # Larxian's THPG cities ship with the Kali release too: the same file is fine (the installer keeps the
                # player's copy), a different one would replace theirs
                if hashlib.md5(open(p, 'rb').read()).hexdigest() == md5.lower():
                    continue
                sys.exit('PACKAGE FAILED: %s is a THUG Pro / Kali file; the package must never replace one' % rel)
        out.append((rel, src))
    return out


def main(argv):
    out = os.path.join(WORK, 'build', 'client')
    no_dll = gen = menulevels = pkg = False
    release = None
    while argv:
        a = argv.pop(0)
        if a == '--out':
            out = argv.pop(0)
        elif a == '--no-dll':
            no_dll = True
        elif a == '--gen':
            gen = True
        elif a == '--menulevels':
            menulevels = True
        elif a == '--package':
            pkg = True
        elif a == '--release':
            release = os.path.abspath(argv.pop(0))
        else:
            sys.exit(__doc__)
    refuse_game_folder(out)
    os.makedirs(out, exist_ok=True)
    if gen:
        r = subprocess.run([sys.executable, '-I', os.path.join(CLIENT, 'tools', 'gen_client_qb.py')], cwd=WORK)
        if r.returncode:
            sys.exit('QB BUILD FAILED: gen_client_qb.py')
    check_menu_boot_calls()
    sys.path.insert(0, os.path.join(CLIENT, 'tools'))
    import check_cfuncs
    if check_cfuncs.main():
        sys.exit('QB BUILD FAILED: client scripts call functions the client DLL does not have (client/tools/check_cfuncs.py)')
    build_prx(out)
    build_casidle(out)
    copy_menulevels(out, menulevels)
    if not no_dll:
        build_dll(out)
    if pkg:
        package(out, release)
    print('client build OK ->', os.path.abspath(out))


if __name__ == '__main__':
    main(sys.argv[1:])
