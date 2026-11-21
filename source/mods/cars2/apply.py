"""cars 2.0: hide the skater again at the end of exit_pause_menu (mods/cars2, 2026-11-21).

  python -I mods/cars2/apply.py <build mod dir>

Noah 2026-11-21: "upon unpausing you can see the skater for 1 frame but it goes away". Leaving the pause menu shows
the driving skater again (UnPauseSkaters / restore_skater_camera are CFuncs); dadmod_cars_beat only re-hid it on its
next 3-frame beat. exit_pause_menu now ends with dadmod_cars_rehide (cars2.q): hide now when driving a car whose setup
has no make_skater_visible (skater tag dadmod_c2_hide = 1), then every frame for 15 frames. No-op when not driving.
"""
import os, sys

mod = sys.argv[1]
p = os.path.join(mod, 'qb', 'thugpro', 'procrastination.q')
s = open(p, newline='').read()
nl = '\r\n' if '\r\n' in s else '\n'
old = '    Change is_quitting = 0\n    KillSpawnedScript Name = exit_pause_menu_delay\n'.replace('\n', nl)
new = ('    Change is_quitting = 0\n    dadmod_cars_rehide\n    KillSpawnedScript Name = exit_pause_menu_delay\n').replace('\n', nl)
assert s.count(old) == 1, 'cars2: exit_pause_menu anchor not found once'
open(p, 'w', newline='').write(s.replace(old, new))
print('cars2: exit_pause_menu re-hides the driving skater')
