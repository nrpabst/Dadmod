# Square during a bail gets back on the board (mods/squaregetup): GeneralBail spawns dadmod_square_getup
# on the skater. Patches the GeneralBail in procrastination.q, which loads after bails.q and wins.
import sys, os
p = os.path.join(sys.argv[1], 'qb', 'thugpro', 'procrastination.q')
s = open(p, newline='').read(); nl = '\r\n' if '\r\n' in s else '\n'
a = '    ClearExceptions' + nl + '    DisablePlayerInput AllowCameraControl' + nl + '    BailSkaterTricks' + nl
assert s.count(a) == 1, 'GeneralBail hook: %d matches' % s.count(a)
s = s.replace(a, a + '    Obj_KillSpawnedScript Name = dadmod_bail_reform' + nl + '    unhide' + nl + '    Obj_KillSpawnedScript Name = dadmod_square_getup' + nl + '    Obj_SpawnScript dadmod_square_getup' + nl)
open(p, 'w', newline='').write(s)

# Pause > dadmod > Gameplay: "Bail cancel" On/Off item right after Player speed (setting square_getup, default on)
p = os.path.join(sys.argv[1], 'qb', 'game', 'Levels.q')
s = open(p, newline='').read(); nl = '\r\n' if '\r\n' in s else '\n'
a = '    option_arrows_callback = dadmod_speed_cycle' + nl + '    option_arrows' + nl + '    pad_choose' + nl + '    }' + nl
assert s.count(a) == 1, 'dadmod menu hook: %d matches' % s.count(a)
item = ['    dadmod_sqget_text', '    make_thugpro_menu_item {', '    id = dadmod_sqget_item', '    text = "Bail cancel"',
        '    extra_text = <sqget_text>',
        '    description_text = "When you bail, press Square to get straight back on your board. Off in Firefight, King of the Hill and Capture the Flag."',
        '    option_arrows_callback = dadmod_sqget_toggle', '    option_arrows', '    pad_choose', '    }']
s = s.replace(a, a + nl.join(item) + nl)
open(p, 'w', newline='').write(s)
