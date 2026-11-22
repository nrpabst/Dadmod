# Pause > dadmod > Gameplay: "Auto bail cancel" On/Off (setting auto_bail_cancel, default off) and "Bail cancel effects" On/Off (whoosh + sparkles + flash, setting bail_cancel_sound_on, default on) directly under Bail cancel.
# Runs after screenfx/bhra so it sits right under the Bail cancel row. Noah 2026-11-21.
import sys, os
p = os.path.join(sys.argv[1], 'qb', 'game', 'Levels.q')
s = open(p, newline='').read(); nl = '\r\n' if '\r\n' in s else '\n'
a = '    option_arrows_callback = dadmod_sqget_toggle' + nl + '    option_arrows' + nl + '    pad_choose' + nl + '    }' + nl
assert s.count(a) == 1, 'Bail cancel item: %d matches' % s.count(a)
item = ['    dadmod_abc_text', '    make_thugpro_menu_item {', '    id = dadmod_abc_item', '    text = "Auto bail cancel"',
        '    extra_text = <abc_text>',
        '    description_text = "Every bail ends on its own: you break apart and reappear on your board. Off in Firefight, King of the Hill and Capture the Flag."',
        '    option_arrows_callback = dadmod_abc_toggle', '    option_arrows', '    pad_choose', '    }',
        '    dadmod_abcsnd_text', '    make_thugpro_menu_item {', '    id = dadmod_abcsnd_item', '    text = "Bail cancel effects"',
        '    extra_text = <abcsnd_text>',
        '    description_text = "The whoosh sound and blue sparkles when you break apart on a bail cancel. Only you see and hear them."',
        '    option_arrows_callback = dadmod_abcsnd_toggle', '    option_arrows', '    pad_choose', '    }']

s = s.replace(a, a + nl.join(item) + nl)
open(p, 'w', newline='').write(s)
