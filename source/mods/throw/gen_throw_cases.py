r"""Mod-only throw types: THUG2 / THUG Pro models every player already has (THUG Pro reads THUG2's Game\Data through
thug2_path), for the Throwables menu and !ammo car etc.

Writes:
  throw_cases.txt  extra ClientLaunchProjectile cases; apply.py inserts them before its default (COMBO O) case
  throw_types.q    thugpro_throw_parse2 (chat words), the category arrays used by the random options
                   (dadmod_throw_vehicles / _animals / _peds / _junk / _all) and dadmod_throw_cat_label
Players without the mod don't have these cases, so they see a COMBO O instead.

2026-11-21 (Noah: "i like all those throwable ideas, lets do them"): Random Animal, Random Pedestrian, Random Junk,
Skateboard, Bowling Ball, Mystery Box. Skinned models (.skin) get their skeleton component first; only skeletons THUG
Pro loads at boot (skeleton.q) are allowed. Every model path is checked against the THUG2 / THUG Pro model folders
here, so a typo fails the build instead of crashing the game (a missing projectile model crashes, 0x40786F).
"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
BS = chr(92)
NL = chr(10)
THUG2_MODELS = r"E:\Tony Hawk's Underground 2\Game\Data\models"
TP_MODELS = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(HERE))), 'THUG Pro Kali v2 - 1.2 Original', 'data', 'models')
LOADED_SKELETONS = {'THPS6_human', 'Ped_Female', 'anl_bull', 'anl_dog', 'anl_pigeon', 'anl_seagull', 'Anl_shark', 'anl_cat'}

# key, chat words, label, model path under models\, skeleton (None = static .mdl), category
# category: car (thrown cars, crash-tested in VehTest 2026-11-02), animal, ped, junk, board, ball
TYPES = [
    ('car', ['CAR', 'CARS'], 'cars', 'veh/Veh_Chevy_Impala/Veh_Chevy_Impala.mdl', None, 'car'),
    ('limo', ['LIMO', 'LIMOS'], 'limos', 'veh/Veh_Limo/Veh_Limo.mdl', None, 'car'),
    ('truck', ['TRUCK', 'TRUCKS'], 'trucks', 'veh/Veh_Pickup/Veh_Pickup.mdl', None, 'car'),
    ('van', ['VAN', 'VANS'], 'vans', 'veh/Veh_OldVan/Veh_OldVan.mdl', None, 'car'),
    ('hearse', ['HEARSE', 'HEARSES'], 'hearses', 'veh/Veh_Hearse/Veh_Hearse.mdl', None, 'car'),
    ('bus', ['BUS', 'BUSES'], 'buses', 'veh/Veh_TourBus/Veh_TourBus.mdl', None, 'car'),
    ('blimp', ['BLIMP', 'BLIMPS'], 'blimps', 'veh/Veh_Blimp/Veh_Blimp.mdl', None, 'car'),
    ('boat', ['BOAT', 'BOATS'], 'duck boats', 'veh/Veh_Duck/Veh_Duck.mdl', None, 'car'),
    ('halfpipe', ['HALFPIPE', 'HALFPIPES'], 'half pipes', 'veh/Veh_Half_Pipe/Veh_Half_Pipe.mdl', None, 'car'),
    # animals (skeletons from THUG2's own model viewer list)
    ('anl_dog', [], 'dogs', 'animals/anl_dog/anl_dog.skin', 'anl_dog', 'animal'),
    ('anl_dog_grey', [], 'dogs', 'animals/anl_dog/anl_dog_grey.skin', 'anl_dog', 'animal'),
    ('anl_cat', [], 'cats', 'animals/anl_cat/anl_cat.skin', 'anl_cat', 'animal'),
    ('anl_pigeon', [], 'pigeons', 'animals/anl_pigeon/anl_pigeon.skin', 'anl_pigeon', 'animal'),
    ('anl_seagull', [], 'seagulls', 'animals/anl_seagull/anl_seagull.skin', 'anl_seagull', 'animal'),
    ('anl_bat', [], 'bats', 'animals/anl_bat/anl_bat.skin', 'anl_pigeon', 'animal'),
    ('anl_parrot', [], 'parrots', 'animals/anl_parrot/anl_parrot.skin', 'anl_pigeon', 'animal'),
    ('anl_bull', [], 'bulls', 'animals/anl_bull/anl_bull.skin', 'anl_bull', 'animal'),
    ('anl_shark', [], 'sharks', 'animals/anl_shark/anl_shark.skin', 'Anl_shark', 'animal'),
    ('anl_fish', [], 'fish', 'animals/anl_fish/anl_fish.skin', 'Anl_shark', 'animal'),
    ('anl_eel', [], 'eels', 'animals/anl_electriceel/anl_electriceel.skin', 'Anl_shark', 'animal'),
    # pedestrians (one-piece bodies)
    ('ped_mime', [], 'mimes', 'peds/ped_mime/ped_mime.skin', 'THPS6_human', 'ped'),
    ('ped_pirate', [], 'pirates', 'peds/ped_pirate/ped_pirate.skin', 'THPS6_human', 'ped'),
    ('ped_jester', [], 'jesters', 'peds/ped_jester/ped_jester.skin', 'THPS6_human', 'ped'),
    ('ped_natas', [], 'peds', 'peds/ped_natas/ped_natas.skin', 'THPS6_human', 'ped'),
    ('ped_bigfoot', [], 'bigfoots', 'peds/ped_bigfoot/ped_bigfoot.skin', 'THPS6_human', 'ped'),
    ('ped_benfranklin', [], 'peds', 'peds/ped_benfranklin/ped_benfranklin.skin', 'THPS6_human', 'ped'),
    ('ped_zombie', [], 'zombies', 'peds/ped_zombiemale01/ped_zombiemale01.skin', 'THPS6_human', 'ped'),
    ('ped_boxer', [], 'boxers', 'peds/ped_boxer/ped_boxer.skin', 'THPS6_human', 'ped'),
    ('ped_wienerman', [], 'peds', 'peds/ped_wienerman/ped_wienerman.skin', 'THPS6_human', 'ped'),
    ('ped_bullfighter', [], 'peds', 'peds/ped_bullfighter/ped_bullfighter.skin', 'THPS6_human', 'ped'),
    ('ped_lifeguard', [], 'peds', 'peds/ped_lifeguard/ped_lifeguard.skin', 'THPS6_human', 'ped'),
    ('ped_copaussie', [], 'peds', 'peds/ped_copaussie/ped_copaussie.skin', 'THPS6_human', 'ped'),
    ('ped_germancop', [], 'peds', 'peds/ped_germancop/ped_germancop.skin', 'THPS6_human', 'ped'),
    ('ped_alien', [], 'aliens', 'peds/ped_alien/ped_alien.skin', 'THPS6_human', 'ped'),
    ('ped_imp', [], 'peds', 'peds/ped_imp/ped_imp.skin', 'THPS6_human', 'ped'),
    ('ped_judge', [], 'peds', 'peds/ped_judge/ped_judge.skin', 'THPS6_human', 'ped'),
    ('ped_nurse', [], 'peds', 'peds/ped_nurse/ped_nurse.skin', 'Ped_Female', 'ped'),
    ('ped_zombiefem', [], 'zombies', 'peds/ped_zombiefem01/ped_zombiefem01.skin', 'Ped_Female', 'ped'),
    # junk (static models)
    ('junk_cone', [], 'junk', 'mdl_cone/mdl_cone.mdl', None, 'junk'),
    ('junk_dogfood', [], 'junk', 'gameobjects/pickups/dog_food/dog_food.mdl', None, 'junk'),
    ('junk_hoagie', [], 'junk', 'gameobjects/pickups/hoagie/hoagie.mdl', None, 'junk'),
    ('junk_skunk', [], 'junk', 'gameobjects/pickups/skunk/skunk.mdl', None, 'junk'),
    ('junk_chest', [], 'junk', 'gameobjects/pickups/treasure_chest/treasure_chest.mdl', None, 'junk'),
    ('junk_pot', [], 'junk', 'gameobjects/pickups/flower_pot/flower_pot.mdl', None, 'junk'),
    ('junk_shoebox', [], 'junk', 'gameobjects/vc/shoebox_pickup/shoebox_pickup.mdl', None, 'junk'),
    ('junk_tomato', [], 'junk', 'gameobjects/projectiles/tomato/tomato.mdl', None, 'junk'),
    ('junk_apple', [], 'junk', 'gameobjects/projectiles/apple/apple.mdl', None, 'junk'),
    ('junk_paintcan', [], 'junk', 'gameobjects/projectiles/paintcan/paintcan.mdl', None, 'junk'),
    ('junk_crown', [], 'junk', 'crown/crown.mdl', None, 'junk'),
    ('junk_letter_s', [], 'junk', 'gameobjects/skate/letter_s/letter_s.mdl', None, 'junk'),
    # single types
    ('board', [], 'skateboards', 'board_default/board_default.mdl', None, 'board'),
    ('ball', [], 'bowling balls', 'gameobjects/pickups/crystal_ball/crystal_ball.mdl', None, 'ball'),
]
ARRAYS = [('dadmod_throw_vehicles', ('car',)), ('dadmod_throw_animals', ('animal',)), ('dadmod_throw_peds', ('ped',)),
          ('dadmod_throw_junk', ('junk',)), ('dadmod_throw_all', ('car', 'animal', 'ped', 'junk', 'board', 'ball'))]
LABEL = {'car': 'Cars', 'animal': 'Animals', 'ped': 'Pedestrians', 'junk': 'Junk', 'board': 'Skateboards', 'ball': 'Bowling balls'}


def exists(path):
    for root in (THUG2_MODELS, TP_MODELS):
        p = os.path.join(root, path.replace('/', os.sep)) + '.xbx'
        if os.path.isfile(p):
            return True
        # Windows is case-insensitive, so the plain check covers case
    return False


def main():
    bad = [t[3] for t in TYPES if not exists(t[3])]
    bad += ['%s: skeleton %s not loaded' % (t[0], t[4]) for t in TYPES if t[4] and t[4] not in LOADED_SKELETONS]
    if bad:
        print('gen_throw_cases: missing models / skeletons:\n  ' + '\n  '.join(bad))
        sys.exit(1)
    # procrastination.qb is near the 512 KB limit: it only gets a small hook in ClientLaunchProjectile's default
    # case (throw_cases.txt, apply.py); the type -> model switch is dadmod_throw_model in throw_types.q (ButtonScripts)
    cases = ['        dadmod_throw_model ammo_type = <ammo_type>',
             '        if GotParam dadmod_tmodel',
             '            <model> = <dadmod_tmodel>',
             '            <projectilecollision> = [ { component = projectilecollision projectile_type = tomato } ]',
             '            dadmod_throw_next_car <...>',
             '        endif']
    open(os.path.join(HERE, 'throw_cases.txt'), 'w').write(NL.join(cases) + NL)
    m = ['script dadmod_throw_model', '    switch <ammo_type>']
    for key, words, label, path, skel, cat in TYPES:
        qpath = path.replace('/', BS * 2)
        m.append('    case dadmod_throw_%s' % key)
        if skel:
            m.append('        return dadmod_tmodel = [ { component = skeleton skeletonName = %s } { component = model model = "%s" } ]' % (skel, qpath))
        else:
            m.append('        return dadmod_tmodel = [ { component = model model = "%s" } ]' % qpath)
    m += ['    endswitch', 'endscript']
    p = ['script thugpro_throw_parse2', '    switch <msg>']
    for key, words, label, path, skel, cat in TYPES:
        if not words:
            continue
        # bare !<word> only for the plural: !car is the (switched off) vehicles parking command
        for w in words:
            for pre in ('!AMMO ', ' !AMMO ') + (('!', ' !') if w == words[-1] else ()):
                p.append('    case "%s%s"' % (pre, w))
        p.append('        return ammo = dadmod_throw_%s label = "%s" modonly = 1' % (key, label))
    p += ['    endswitch', 'endscript'] + m
    for name, cats in ARRAYS:
        p.append('%s = [ %s ]' % (name, ' '.join('dadmod_throw_%s' % t[0] for t in TYPES if t[5] in cats)))
    p.append('dadmod_throw_cat_label = {')
    for key, words, label, path, skel, cat in TYPES:
        p.append('dadmod_throw_%s = "%s"' % (key, LABEL[cat]))
    p.append('}')
    open(os.path.join(HERE, 'throw_types.q'), 'w').write('\n'.join(p) + '\n')
    print('throw: %d types' % len(TYPES))


main()
