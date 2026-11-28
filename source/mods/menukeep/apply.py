"""menukeep (Noah 2026-11-22): the pause menu and the chat box stay open when a game mode ends or starts.

    python -I mods/menukeep/apply.py build/obsspawn_test/mod      (run from work/, by obsspawn_test_make.sh)

The server build does what the client loader does with client/wrap.txt: every definition of the stock scripts
below is renamed to <name>_orig, and menukeep.q (our wrappers, which call <name>_orig <...>) goes into
qb/dadmod/dadmod_cars.qb. Files that only exist in the base prx (gamemode.q, keyboard.q) are copied in from the
decompiled Kali Original first, so no unrenamed copy is left behind.
client/qb/dadmod/menukeep.q must be the same file (the client build loads it from there).
menukeep_server.q (server build only) wraps exit_pause_menu; the client build has its own exit_pause_menu wrapper in
client/qb/dadmod/menus.q, which does the same dadmod_mk_keeping check.
"""
import os, re, shutil, sys

WRAP = ['create_rankings', 'create_console_message', 'create_onscreen_keyboard', 'enter_kb_chat',
        'launch_chat_keyboard', 'launch_quick_menu_keyboard', 'entered_chat_message', 'cancel_enter_chat_menu',
        'cancel_chat_menu', 'sound_options_exit', 'edit_tricks_menu_exit', 'exit_pause_menu',
        'destroy_onscreen_keyboard']
COPY_IN = ['gamemodes/gamemode.q', 'engine/menu/keyboard.q', 'game/menu/soundoptions.q', 'game/menu/edit_tricks_menu.q',
           'game/menu/gamemenu_pause.q']
# 2026-11-26 (Noah: pausing free skate left the skater with no input): gamemenu_pause.q was missing above, so its stock
# exit_pause_menu (base prx, loaded after qb/dadmod/dadmod_cars.qb) replaced our wrapper. That copy never gives input
# back offline, where freeskate_menu blocks it with NetDisablePlayerInput. Any other base file that defines a wrapped
# script is now copied in too (see main), so this can't happen again.
KALI = 'decompiled/thugpro_qb/qb'


def main(root):
    here = os.path.dirname(os.path.abspath(__file__))
    src = os.path.join(here, 'menukeep.q')
    cli = os.path.join(here, '..', '..', 'client', 'qb', 'dadmod', 'menukeep.q')
    a = open(src, encoding='latin-1').read().replace('\r\n', '\n')
    if not os.path.isfile(cli) or open(cli, encoding='latin-1').read().replace('\r\n', '\n') != a:
        print('menukeep: client/qb/dadmod/menukeep.q differs from mods/menukeep/menukeep.q (copy it over)')
        return 1
    qb = os.path.join(root, 'qb')
    pat = re.compile(r'^script (%s)\b' % '|'.join(WRAP), re.M | re.I)
    extra = []
    for d, _, fs in os.walk(KALI):
        for f in fs:
            p = os.path.join(d, f)
            rel = os.path.relpath(p, KALI).replace(os.sep, '/')
            if f.endswith('.q') and rel not in COPY_IN and not os.path.isfile(os.path.join(qb, rel)):
                if pat.search(open(p, encoding='latin-1').read()):
                    extra.append(rel)
    if extra:
        print('menukeep: also copied in from the base prx (they define wrapped scripts): %s' % ', '.join(extra))
    for rel in COPY_IN + extra:
        dst = os.path.join(qb, rel)
        if not os.path.isfile(dst):
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.copy(os.path.join(KALI, rel), dst)
    found = {n: 0 for n in WRAP}
    pat = re.compile(r'^script (%s)\b' % '|'.join(WRAP), re.M | re.I)
    for d, _, fs in os.walk(qb):
        for f in fs:
            if not f.endswith('.q'):
                continue
            p = os.path.join(d, f)
            s = open(p, encoding='latin-1', newline='').read()
            def ren(m):
                found[[n for n in WRAP if n.lower() == m.group(1).lower()][0]] += 1
                return 'script %s_orig' % m.group(1)
            t = pat.sub(ren, s)
            if t != s:
                open(p, 'w', encoding='latin-1', newline='').write(t)
    missing = [n for n, c in found.items() if c == 0]
    if missing:
        print('menukeep: no definition found for %s' % ', '.join(missing))
        return 1
    out = os.path.join(qb, 'dadmod', 'dadmod_cars.q')
    if not os.path.isfile(out):
        print('menukeep: %s missing (cars2 step must run first)' % out)
        return 1
    srv = open(os.path.join(here, 'menukeep_server.q'), encoding='latin-1').read().replace('\r\n', '\n')
    with open(out, 'a', encoding='latin-1', newline='') as fh:
        fh.write('\n' + a + '\n' + srv)
    print('menukeep: wrapped %s' % ', '.join('%s x%d' % (n, c) for n, c in found.items()))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1]))
