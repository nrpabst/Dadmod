# Trick Screen Effects On/Off (mods/screenfx, asked for by player shibe 2026-11-19): some special tricks (the 3D
# Scary Grind) fill the screen with old-film effects through FullScreenEffect = CreatureScaryGrindEffect. Off makes
# that script do nothing; the trick's exit scripts already check the effect objects exist, so skipping the start is safe.
# The setting (screen_fx, default on) is read when the trick starts, so a change applies at once.
import sys, os, shutil
WORK = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
p = os.path.join(sys.argv[1], 'qb', 'game', 'skater', 'grindscripts.q')
if not os.path.exists(p):  # the stock file, unless another mod (bhra) already put it in the tree
    os.makedirs(os.path.dirname(p), exist_ok=True)
    shutil.copy(os.path.join(WORK, 'decompiled', 'thugpro_qb', 'qb', 'game', 'skater', 'grindscripts.q'), p)
s = open(p, newline='').read(); nl = '\r\n' if '\r\n' in s else '\n'
a = 'script CreatureScaryGrindEffect' + nl + '    start_oldtime_effects' + nl + 'endscript' + nl
assert s.count(a) == 1, 'CreatureScaryGrindEffect: %d matches' % s.count(a)
b = nl.join(['script CreatureScaryGrindEffect', '    dadmod_tsfx_get', '    if ( <tsfx_on> = 1 )', '        start_oldtime_effects',
             '    endif', 'endscript']) + nl
s = s.replace(a, b)
open(p, 'w', newline='').write(s)

# Pause > dadmod > Gameplay: "Trick Screen Effects" On/Off right after Bail cancel
p = os.path.join(sys.argv[1], 'qb', 'game', 'Levels.q')
s = open(p, newline='').read(); nl = '\r\n' if '\r\n' in s else '\n'
a = '    option_arrows_callback = dadmod_sqget_toggle' + nl + '    option_arrows' + nl + '    pad_choose' + nl + '    }' + nl
assert s.count(a) == 1, 'Bail cancel item: %d matches' % s.count(a)
item = ['    dadmod_tsfx_text', '    make_thugpro_menu_item {', '    id = dadmod_tsfx_item', '    text = "Trick Screen Effects"',
        '    extra_text = <tsfx_text>',
        '    description_text = "The full-screen effects of special tricks, like the 3D Scary Grind film look."',
        '    option_arrows_callback = dadmod_tsfx_toggle', '    option_arrows', '    pad_choose', '    }']
s = s.replace(a, a + nl.join(item) + nl)
open(p, 'w', newline='').write(s)
