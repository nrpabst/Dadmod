r"""Build the Project 8 (original Xbox) levels for THUG Pro from the disc files.

    python -I p8\tools\build_p8.py            (run from work\; writes p8\build\data\pre\*.prx and p8\build\userslots_p8.q)

Reads p8\disc (copied from Noah's own P8 Xbox disc image). Everything is converted by p8conv.py (our own code);
the level node arrays keep P8's rails, restarts and level geometry nodes and nothing else (no P8 scripts).
"""
import os, shutil, struct, subprocess, sys
HERE = os.path.dirname(os.path.abspath(__file__))
WORK = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(WORK, 'tools'))
import p8conv
from prx_pack import write_archive, stored

DISC = os.path.join(WORK, 'p8', 'disc', 'data')
OUT = os.path.join(WORK, 'p8', 'build')

# level name, zone pak, level select slot (THUG Pro's greyed P8 slot load script), menu name, P8 sky
LEVELS = [
    ('P8Training', 'worlds/worldZones/z_Training/z_training.pak.xbx', 0x1a69989e, 'Training', 'default_sky'),
    ('P8Suburbs', 'worlds/worldZones/z_houses/z_houses.pak.xbx', 0x16a10a9a, 'Suburbs', 'default_sky'),
    ('P8Downtown', 'worlds/worldZones/z_Shops/z_shops.pak.xbx', 0x896a81b2, 'Downtown', 'default_sky'),
    ('P8CarFactory', 'worlds/worldZones/z_CF/z_cf.pak.xbx', 0x27eeac8d, 'Car Factory', 'default_sky'),
    ('P8CretePark', 'worlds/worldZones/z_cretepark/z_cretepark.pak.xbx', 0x2843fdc8, 'Crete Park', 'Crete_Sky'),
]


def compile_q(q, qb):
    r = subprocess.run([sys.executable, '-I', os.path.join(WORK, 'tools', 'qb.py'), 'c', q, qb], capture_output=True, text=True)
    if r.returncode or not os.path.isfile(qb):
        raise SystemExit('compile failed for %s:\n%s%s' % (q, r.stdout[-500:], r.stderr[-500:]))


# stock ambient background tracks (THUG Pro's own P8 levels use bo_bg / au_bg; Training as stock Training)
AMBIENT = {'P8Training': 'tr_bg', 'P8Suburbs': 'bo_bg', 'P8Downtown': 'bo_bg', 'P8CarFactory': 'au_bg',
           'P8CretePark': 'st_bg'}
AMBIENT_IN_BUILD = True

# sound files (THUG2 data\sounds) behind each rigid body sound type p8conv.P8_SOUNDTYPES writes
BOUNCY_SOUNDS = {
    'SmallTrafficCone': ['BouncyObjects\\Bouncy_OrangeConeHit01'],
    'BigTrafficCone': ['BouncyObjects\\Bouncy_OrangeConeHit01'],
    'AluminumCan': ['BouncyObjects\\Bouncy_AluminumCanHit01', 'BouncyObjects\\Bouncy_AluminumCanHit02'],
    'PlasticTrashCan': ['BouncyObjects\\Bouncy_PlasticHit03', 'BouncyObjects\\Bouncy_PlasticHit02'],
    'PlasticChair': ['BouncyObjects\\Bouncy_PlasticChairHit02'],
    'Metal50GalDrum': ['BouncyObjects\\Bouncy_MetalDrumHit01', 'BouncyObjects\\Bouncy_MetalDrumHit02'],
    'CardboardBox': ['BouncyObjects\\Bouncy_CardboardBoxHit01', 'BouncyObjects\\Bouncy_CardboardBoxHit02'],
    'ST_BowlingPin': ['BouncyObjects\\Bouncy_BowlingPin_Hit01'],
    'MetalTrashCan': ['Shared\\Hits\\HitMetalCan', 'BouncyObjects\\Bouncy_MetalDrumHit02'],
    'NO_Barstool': ['BouncyObjects\\Bouncy_MetalHit02'],
    'BE_LargePlanter': ['Shared\\Hits\\BonkBush'],
}

# THUG Pro's terrain ids in collision-face order (index = the face's u16 terrain field; P8 uses the same ids, as
# THUG Pro's own City Center port shows: its P8 collision file is used as is)
TERRAIN_IDS = ['DEFAULT', 'CONCSMOOTH', 'CONCROUGH', 'METALSMOOTH', 'METALROUGH', 'METALCORRUGATED', 'METALGRATING',
               'METALTIN', 'WOOD', 'WOODMASONITE', 'WOODPLYWOOD', 'WOODFLIMSY', 'WOODSHINGLE', 'WOODPIER', 'BRICK',
               'TILE', 'ASPHALT', 'ROCK', 'GRAVEL', 'SIDEWALK', 'GRASS', 'GRASSDRIED', 'DIRT', 'DIRTPACKED', 'WATER',
               'ICE', 'SNOW', 'SAND', 'PLEXIGLASS', 'FIBERGLASS', 'CARPET', 'CONVEYOR', 'CHAINLINK', 'METALFUTURE',
               'GENERIC1', 'GENERIC2', 'WHEELS', 'WETCONC', 'METALFENCE', 'GRINDTRAIN', 'GRINDROPE', 'GRINDWIRE',
               'GRINDCONC', 'GRINDROUNDMETALPOLE', 'GRINDCHAINLINK', 'GRINDMETAL', 'GRINDWOODRAILING',
               'GRINDWOODLOG', 'GRINDWOOD', 'GRINDPLASTIC', 'GRINDELECTRICWIRE', 'GRINDCABLE', 'GRINDCHAIN',
               'GRINDPLASTICBARRIER', 'GRINDNEONLIGHT', 'GRINDGLASSMONSTER', 'GRINDBANYONTREE', 'GRINDBRASSRAIL',
               'GRINDRUSTYRAIL', 'GRINDCATWALK', 'GRINDTANKTURRET']


def load_terrain_script(col_path, q_path):
    """load_level (Levels.q) loads terrain sounds only by calling the level's own LoadTerrain script after the
    level qbs (and removes it again at unload); without one only TERRAIN_DEFAULT has sounds, so rolling, landing
    and most grind sounds are silent. Ours loads every terrain the level uses: collision faces and rail nodes."""
    import re
    import colparse
    used = {'DEFAULT'}
    b = open(col_path, 'rb').read()
    s = colparse.sections(b, 0x20)
    for o in s['objs']:
        for fl, tt, vi in colparse.obj_faces(s, o):
            if tt < len(TERRAIN_IDS):
                used.add(TERRAIN_IDS[tt])
    by_crc = {p8conv.crc('TERRAIN_' + t): t for t in TERRAIN_IDS}
    for m in re.finditer(r'^TerrainType = (?:TERRAIN_(\w+)|#"0x([0-9a-f]+)")', open(q_path, encoding='latin1').read(), re.M):
        t = m.group(1) or by_crc.get(int(m.group(2), 16))
        if t in TERRAIN_IDS:
            used.add(t)
    lines = ['script LoadTerrain']
    lines += ['    LoadTerrainSounds Terrain = TERRAIN_%s' % t for t in TERRAIN_IDS if t in used]
    return lines + ['endscript'], sorted(used, key=TERRAIN_IDS.index)


# P8 classic-mode missions: the mission pak whose node array holds the level's S-K-A-T-E and C-O-M-B-O letters and
# secret tape (same spots P8 uses). They become THUG Pro classic goals (stock AddGoal_* helpers, letter objects named
# the way those helpers look them up, the stock THUG2 letter / tape models P8 also names).
CLASSIC = {'P8Suburbs': 'm_hoclas', 'P8Downtown': 'm_sh_ccr', 'P8CarFactory': 'm_cf_career_classic',
           'P8CretePark': 'm_cpclasstier0'}


def classic_goals(level):
    """-> (node array entries, node-array qb scripts, <level>_goals script lines) or None"""
    m = CLASSIC.get(level)
    if not m:
        return None
    C = p8conv.crc
    fs = p8conv.read_pak(open(os.path.join(WORK, 'p8', 'disc', 'data', 'missions', 'worldzones', m, m + '.pak.xbx'), 'rb').read())
    nodes = []
    for f in fs:
        if f['name'].lower().endswith('\\%s.qb.xbx' % m):
            nodes = p8conv.nodes_from_qb(f['data'])
    want = {C('letter_%s' % c): ('TRG_Goal_Letter_%s' % c.upper(), 'letter_%s' % c,
                                 'gameobjects\\skate\\letter_%s\\letter_%s.mdl' % (c, c), 'SKATE_Letter') for c in 'skate'}
    for c in 'CMB':
        want[C('Combo_%s' % c)] = ('TRG_Goal_COMBO_%s' % c, 'Combo_%s' % c,
                                   'gameobjects\\combo\\goal_combo_%s\\goal_combo_%s.mdl' % (c.lower(), c.lower()), 'COMBO_Letter')
    tape = C('Secret_Tape')
    entries, scripts, seen, os_ = [], [], set(), 0
    for n in nodes:
        t = n.get(C('Type'))
        if t == C('Combo_O'):
            os_ += 1
            spec = ('TRG_Goal_COMBO_O' + ('2' if os_ == 2 else ''), 'Combo_O',
                    'gameobjects\\combo\\goal_combo_o\\goal_combo_o.mdl', 'COMBO_Letter')
        elif t == tape:
            spec = ('TRG_P8_SecretTape', 'Secret_Tape', 'gameobjects\\secret_tape\\secret_tape.mdl', None)
        else:
            spec = want.get(t)
        if not spec or spec[0] in seen:
            continue
        seen.add(spec[0])
        name, typ, model, handler = spec
        pos = '(%s)' % ','.join(p8conv.q_value(float(x)) for x in n[C('Pos')])
        ang = '(%s)' % ','.join(p8conv.q_value(float(x)) for x in n.get(C('Angles'), (0.0, 0.0, 0.0)))
        entries += ['{', 'Name = %s' % name, 'Pos = %s' % pos, 'Angles = %s' % ang, 'Class = GameObject',
                    'Type = %s' % typ, 'model = "%s"' % model.replace('\\', '\\\\'), 'SuspendDistance = 0',
                    'lod_dist1 = 2500', 'lod_dist2 = 5000', 'TriggerScript = %sScript' % name]
        if t == tape:
            entries.append('AbsentInNetGames')
        entries.append('}')
        scripts += ['script %sScript' % name] + (['    %s' % handler] if handler else []) + ['endscript']
    goals = ['script %s_goals' % level, '    if InMultiplayergame', '        add_multiplayer_mode_goals', '    endif',
             '    if ( ( InMultiplayergame ) or ( GameModeEquals is_classic ) )']
    for kind, txt, glob in (('HighScore', 'High Score', 'THUGPRO_G_HighScore'), ('ProScore', 'Pro Score', 'THUGPRO_G_ProScore'),
                            ('SickScore', 'Sick Score', 'THUGPRO_G_SickScore')):
        goals += ['        AddGoal_%s {' % kind, '        unlimited_Time', '        goal_text = "%s"' % txt,
                  '        View_Goals_Text = "%s"' % txt, '        goal_description = "%s"' % txt,
                  '        score = %s' % glob, '        }']
    if {'TRG_Goal_COMBO_C', 'TRG_Goal_COMBO_O', 'TRG_Goal_COMBO_M', 'TRG_Goal_COMBO_B', 'TRG_Goal_COMBO_O2'} <= seen:
        goals += ['        AddGoal_Combo {', '        goal_text = "Collect C-O-M-B-O"',
                  '        View_Goals_Text = "Collect the C-O-M-B-O letters"',
                  '        goal_description = "Collect the C-O-M-B-O letters"', '        unlimited_Time',
                  '        letter_info = [', '        { obj_id = TRG_Goal_COMBO_C text = "C" }',
                  '        { obj_id = TRG_Goal_COMBO_O text = "O" }', '        { obj_id = TRG_Goal_COMBO_M text = "M" }',
                  '        { obj_id = TRG_Goal_COMBO_B text = "B" }', '        { obj_id = TRG_Goal_COMBO_O2 text = "O" }',
                  '        ]', '        }']
    if {'TRG_Goal_Letter_%s' % c for c in 'SKATE'} <= seen:
        goals += ['        AddGoal_Skate {', '        goal_text = "Collect S-K-A-T-E"',
                  '        View_Goals_Text = "Collect the S-K-A-T-E letters"',
                  '        goal_description = "Collect the S-K-A-T-E letters"', '        unlimited_Time', '        }']
    if 'TRG_P8_SecretTape' in seen:
        goals += ['        if not InMultiplayergame', '            AddGoal_SecretTape {',
                  '            goal_text = "Get the secret tape"', '            View_Goals_Text = "Get the secret tape"',
                  '            classic_mode_goal', '            goal_description = "Get the secret tape"',
                  '            secret_tape_id = TRG_P8_SecretTape', '            }', '        endif']
    goals += ['    endif', 'endscript']
    return entries, scripts, goals


# P8 level sound banks (data/sounds/pak/<zone>_sfx.pak.xbx, pulled from Noah's P8 disc image into p8\disc_sounds)
SFX_BANK = {'P8Training': 'Z_Training', 'P8Suburbs': 'Z_houses', 'P8Downtown': 'Z_shops', 'P8CarFactory': 'Z_CF',
            'P8CretePark': 'Z_cretepark'}


STREAM_MAX = 120.0     # seconds: longer P8 streams (2 of 4270 - music) are not loaded as sounds


def level_ambience(level, zone, nodes, tmp):
    """P8 ambience -> our proximity sound scripts (p8conv.p8_ambience) + the sounds they play converted to WAV
    (p8sound) as tmp\\sounds\\<level>\\p8s_<checksum>.snd, installed to Dev data\\sounds\\<level>.
    Returns (scripts q text, {P8 proxim TriggerScript: ours}, {sound checksums})."""
    import p8sound
    bank = os.path.join(WORK, 'p8', 'disc_sounds', 'data_sounds_pak_%s_sfx.pak.xbx' % SFX_BANK[level])
    zpak = os.path.join(DISC, zone)
    if not os.path.isfile(bank):
        return '\n', {}, set()
    table = p8sound.sound_table(zpak)
    b = open(bank, 'rb').read()
    ok = {n for n, e in table.items() if e['offset'] + 8 <= len(b) and struct.unpack_from('<H', b, e['offset'])[0] == 0x69}
    qbs = [f['data'] for f in p8conv.read_pak(open(zpak, 'rb').read()) if f['name'].lower().endswith('.qb.xbx')]
    # P8 stream loops (data/streams/pcm/pcm.dat + .wad, pulled into p8\disc_streams) up to STREAM_MAX seconds are
    # played as ordinary sounds (THUG Pro's own stream wad is left alone)
    sdat = os.path.join(WORK, 'p8', 'disc_streams', 'data_streams_pcm_pcm.dat')
    swad = sdat[:-4] + '.wad'
    streams = {}
    if os.path.isfile(sdat) and os.path.isfile(swad):
        streams = {c: e for c, e in p8sound.stream_table(sdat).items()
                   if e[1] / (36.0 * e[2]) * 65 / e[3] <= STREAM_MAX}
    loops = {n for n, e in table.items() if p8conv.crc('looping') in e['flags']}
    text, trig, used = p8conv.p8_ambience(qbs, nodes, ok, set(streams), loops)
    d = os.path.join(tmp, 'sounds', level)
    os.makedirs(d, exist_ok=True)
    for s in used:
        if s == p8conv.crc('BonkBush'):
            continue
        if s not in table:
            open(os.path.join(d, 'p8s_%08x.snd' % s), 'wb').write(p8sound.stream_wav(swad, streams[s]))
            continue
        e = table[s]
        fmt, ch, rate = struct.unpack_from('<HHI', b, e['offset'])
        pcm = p8sound.decode_xbox_adpcm(b[e['offset'] + 0x80:e['offset'] + 0x80 + e['size']], ch)
        open(os.path.join(d, 'p8s_%08x.snd' % s), 'wb').write(p8sound.thug_snd(pcm, rate, ch, s in loops))
    return text, trig, used


def arm_joints(zone_pak):
    """Car Factory robot arms: the main part's top joint (centre of its highest vertices) and the middle part's far
    end (centre of its farthest +X vertices), model space - where the next part hangs in the rest pose"""
    files = p8conv.read_pak(open(zone_pak, 'rb').read())
    out, cur = {}, None
    for f in files:
        nm = f['name'].lower()
        if nm.startswith('models\\veh\\') and nm.endswith('.qb.xbx'):
            cur = os.path.basename(nm)[:-len('.qb.xbx')]
        elif f['type'] == 0x9bcc234d and cur in ('veh_robot_arm_main', 'veh_robot_arm_middle'):
            mats, secs = p8conv.read_p8_scene(f['data'])
            vs = [v[0] for s in secs for me in s['meshes'] for v in me['verts']]
            if cur == 'veh_robot_arm_main':
                top = max(v[1] for v in vs)
                sel = [v for v in vs if v[1] >= top - 8]
            else:
                far = max(v[0] for v in vs)
                sel = [v for v in vs if v[0] >= far - 8]
            out[cur] = tuple(sum(v[k] for v in sel) / len(sel) for k in range(3))
            cur = None
    return out if len(out) == 2 else {}


# models every P8 node of which carries the nocollision flag (checked 2026-11-16: all 15 Car Factory robot arm
# nodes; P8's middle / tip collision files are empty, the main part's 414-face one is never used)
NO_COLLISION = {'veh_robot_arm_main', 'veh_robot_arm_middle', 'veh_robot_arm_tip'}
# P8's own empty collision file (the robot arm middle / tip .mcol, byte for byte: header, no objects)
EMPTY_MCOL = bytes.fromhex('0a000000' + '00' * 44 + '00007a4400007a4400007a440000803f00007ac400007ac400007ac40000803f' + '00000000')


def build_models(zone_pak, tmp):
    """P8 moving-object models (Suburbs playground rides, Car Factory machinery, Downtown cars' P8 versions...): in
    the zone pak each is a run of files - .stex textures, its models\\veh\\<n>\\<n>.qb, .mdl (P8 scene layout, read
    by p8conv.read_p8_scene), .rnb, .mcol (P8 collision with the 0x50 header). Written as THUG2 model files
    models\\veh\\<n>\\<n>.{mdl,tex,col}.xbx for the level's scripts .pre (as THUG Pro's own Z_SR ships its
    machinery). Returns [(archive name, local file)]."""
    import colparse
    files = p8conv.read_pak(open(zone_pak, 'rb').read())
    T = dict(stex=0x2b0a3095, mdl=0x9bcc234d, mcol=0x6290993b)
    groups, cur = [], None
    for f in files:
        if f['type'] == T['stex']:
            cur = {'stex': f['data']}
            groups.append(cur)
        elif cur is not None:
            nm = f['name'].lower()
            if nm.startswith('models\\veh\\') and nm.endswith('.qb.xbx'):
                cur['name'] = os.path.basename(nm)[:-len('.qb.xbx')]
            for k, t in T.items():
                if f['type'] == t and k != 'stex':
                    cur[k] = f['data']
    out = []
    for g in groups:
        n = g.get('name')
        if not n or 'mdl' not in g or n in ('veh_cop', 'veh_explorer') :
            continue        # street cars use THUG2's own car models (p8conv.P8_CARS) - keep their paths unshadowed
        d = os.path.join(tmp, 'models', n)
        os.makedirs(d, exist_ok=True)
        texs = p8conv.read_p8_tex(g['stex'])
        mats, secs = p8conv.read_p8_scene(g['mdl'])
        p8conv.keep_culling(mats, secs)                  # same flicker rules as the level scene
        p8conv.fix_coincident(mats, secs)
        arc = 'models\\veh\\%s\\%s' % (n, n)
        p8conv.write_thug_tex(os.path.join(d, n + '.tex.xbx'), texs)
        p8conv.write_thug_scene(os.path.join(d, n + '.mdl.xbx'), mats, secs, {t.checksum for t in texs})
        out += [(arc + '.mdl.xbx', os.path.join(d, n + '.mdl.xbx')), (arc + '.tex.xbx', os.path.join(d, n + '.tex.xbx'))]
        # the model's own node array qb (as THUG Pro's Z_SR machinery ships one: a ModelExport node naming the
        # model); a Vehicle without it crashed the game at load in single player (exe 0x408D79 / 0x40A632)
        mq = os.path.join(d, n + '.q')
        open(mq, 'w', newline='\n').write('%s_NodeArray = [\n{\nPos = (0.0,0.0,0.0)\nAngles = (0.0,0.0,0.0)\n'
                                          'Name = %s_model\nClass = ModelExport\nExportName = %s\n}\n]\n' % (n, n, n))
        compile_q(mq, os.path.join(d, n + '.qb'))
        out.append((arc + '.qb', os.path.join(d, n + '.qb')))
        # every model ships a collision file, even an empty one (a model with none - the robot arm middle / tip -
        # crashed the single-player load at exe 0x40A2F6)
        if 'mcol' in g:
            mcol = g['mcol']
            if n in NO_COLLISION:
                # P8 places these with the nocollision flag (every robot arm node): their collision is never used,
                # so they get an empty one (P8's own empty arm-part file, 0 objects)
                mcol = EMPTY_MCOL
            open(os.path.join(d, n + '.col.xbx'), 'wb').write(p8conv.verbatim_col(mcol))
            out.append((arc + '.col.xbx', os.path.join(d, n + '.col.xbx')))
    return out


def build_level(level, zone, sky):
    tmp = os.path.join(OUT, 'tmp', level)
    os.makedirs(tmp, exist_ok=True)   # files are overwritten in place (no deletes)
    info = p8conv.convert(os.path.join(DISC, zone), tmp, level)
    skyname = level + '_Sky'
    skypak = os.path.join(DISC, 'skies', sky, sky.lower() + '.pak.xbx')
    p8conv.convert(skypak, tmp, skyname)
    nodes = p8conv.nodes_from_qb(info['qb'])
    q = os.path.join(tmp, level + '.q')
    p8conv.ARM_JOINTS.clear()
    p8conv.ARM_JOINTS.update(arm_joints(os.path.join(DISC, zone)))
    amb_q, prox_trig, used = level_ambience(level, zone, nodes, tmp)
    counts = p8conv.write_nodearray_q(q, level, nodes, info['sectors'], info.get('trigger_ok'), info.get('col'),
                                      prox_trig)
    print('  ambience: %d proximity triggers, %d sounds' % (len(prox_trig), len(used)))
    print('  nodes:', counts)
    cg = classic_goals(level)
    if cg:
        entries, cscripts, goals = cg
        text = open(q, encoding='latin1').read()
        k = text.index('\n]\n')                        # end of <level>_NodeArray (inner arrays are one-line)
        text = text[:k + 1] + '\n'.join(entries) + text[k:] + '\n'.join(cscripts) + '\n'
        open(q, 'w', encoding='latin1', newline='\n').write(text)
        print('  classic goals: %d objects' % entries.count('{'))
    import validate_p8
    bad, _ = validate_p8.node_link_errors(open(q, encoding='latin1').read())
    if bad:
        # a rail / ladder Link to the wrong node hangs the level load forever (rail builder 0x57E960)
        sys.exit('BUILD FAILED %s: %d bad node links, first: %s' % (level, len(bad), bad[0]))
    compile_q(q, os.path.join(tmp, level + '.qb'))
    sq = info.get('scripts_q') or '\n'     # converted P8 trigger scripts: gaps, kill zones, doors
    if cg:
        sq += '\n'.join(cg[2]) + '\n'       # <level>_goals: run by load_level through the level struct's goals_script
    # <level>_LoadingSounds: the engine runs it by name at level load (Levels.q), after load_level has set the
    # ambient track from the level struct - ours has none (our structs live in the shared userslots.q), so the
    # level's stock ambient background track is set here the way load_level does it for stock levels.
    # (AMBIENT_IN_BUILD: the ambient track line is held back until the sound build; Noah tests one fix at a time)
    sq += amb_q
    sounds = ['script %s_LoadingSounds' % level]
    BONK = p8conv.crc('BonkBush')            # stock THUG2 bush / tree hit sound (rustle boxes)
    sounds += ['    LoadSound "%s\\\\p8s_%08x"' % (level, s) for s in sorted(used) if s != BONK]
    if BONK in used:
        sounds += ['    LoadSound "Shared\\\\Hits\\\\BonkBush"']
    if AMBIENT_IN_BUILD:
        sounds += ['    load_level_handle_ambient_sfx ambient_track = "%s"' % AMBIENT.get(level, 'bo_bg')]
    if 'dadmod_p8_door' in sq:
        # door swing sounds (stock shared sounds)
        sounds += ['    LoadSound "Shared\\\\Misc\\\\elevatordooropen"', '    LoadSound "Shared\\\\Misc\\\\elevatordoorclose"']
    # knock-around object hit sounds: the THUG2 sound files each rigid body sound type we write plays
    qtext = open(q, encoding='latin1').read()
    for snd in sorted({s for t, ss in BOUNCY_SOUNDS.items() if ('SoundType = %s\n' % t) in qtext for s in ss}):
        if ('    LoadSound "%s"' % snd.replace('\\', '\\\\')) not in sounds:     # BonkBush may already be in for rustle boxes
            sounds.append('    LoadSound "%s"' % snd.replace('\\', '\\\\'))
    if 'HitGlassPane2x' in sq:
        # breakable glass (P8 trigger scripts that shatter a piece): stock shared glass sound
        sounds += ['    LoadSound "Shared\\\\Hits\\\\HitGlassPane2x" vol = 100 dropoff = 50']
    if len(sounds) > 1:
        sq += '\n'.join(sounds + ['endscript']) + '\n'
    tl, used = load_terrain_script(os.path.join(tmp, level + '.col.xbx'), q)
    sq += '\n'.join(tl) + '\n'
    print('  terrain sounds:', ' '.join(used))
    open(os.path.join(tmp, level + '_scripts.q'), 'w', newline='\n').write(sq)
    open(os.path.join(tmp, level + '_thugpro.q'), 'w', newline='\n').write(level_options_q(level, q, info['boxes'], info.get('colboxes')))
    for extra in ('_scripts', '_thugpro'):
        compile_q(os.path.join(tmp, level + extra + '.q'), os.path.join(tmp, level + extra + '.qb'))
    pre = os.path.join(OUT, 'data', 'pre')
    os.makedirs(pre, exist_ok=True)
    rd = lambda n: open(os.path.join(tmp, n), 'rb').read()
    L = 'Levels\\%s\\' % level
    S = 'Levels\\%s\\' % skyname
    write_archive([stored(L + level + '.scn.xbx', rd(level + '.scn.xbx')), stored(L + level + '.tex.xbx', rd(level + '.tex.xbx')),
                   stored(S + skyname + '.scn.xbx', rd(skyname + '.scn.xbx')), stored(S + skyname + '.tex.xbx', rd(skyname + '.tex.xbx'))],
                  os.path.join(pre, level + 'scn.prx'))
    write_archive([stored(L + level + '.col.xbx', rd(level + '.col.xbx'))], os.path.join(pre, level + 'col.prx'))
    models = build_models(os.path.join(DISC, zone), tmp)
    print('  models:', ' '.join(sorted({os.path.basename(a).split('.')[0] for a, _ in models})))
    write_archive([stored(L + level + ext, rd(level + ext)) for ext in ('.qb', '_scripts.qb', '_thugpro.qb')]
                  + [stored(a, open(p, 'rb').read()) for a, p in models],
                  os.path.join(pre, level + '_scripts.prx'))


# P8 piece swaps that become one Level Options toggle. intact: pieces P8 creates at start that the variant replaces
# (checked against P8's geometry: the same footprint as the variant pieces); the variant is every not-created-at-start
# piece within 300 units of them. Rails standing on the intact pieces (inside their render bounds, outside the
# variant's bounds) go with them.
SWAPS = {
    'P8CretePark': [('Coffee Cup Destroyed', [0xbbc07aac, 0x7977c2a7, 0xbd834f87, 0xfd40fff7, 0x83e5d3c3])],
}


def level_options_q(level, q_path, boxes, colboxes=None):
    """THUG Pro's Level Options menu lists <level>_option_items (create_level_options_menu in thugpro_server.q;
    stock example hisch_thugpro.q): toggles that create / kill level pieces, with a preview camera. P8 keeps
    story variants as level pieces that are not created at start; they become our options here (at most 8: the
    menu has SERVER_LEVEL_CHANGE_01..08_ON flags), off by default as P8 starts them. Known swaps (SWAPS) also kill
    the pieces they replace; P8's collectibles are one toggle; other groups are numbered story pieces west to east."""
    import math, re
    colboxes = colboxes or {}
    text = open(q_path, encoding='latin1').read()
    allb = dict(colboxes)
    allb.update(boxes)
    hidden, rails, restarts = [], [], []
    for n in text.split('\n{\n')[1:]:
        m = re.search(r'^Name = #"0x([0-9a-f]+)"', n, re.M)
        pm = re.search(r'^Pos = \(([^)]*)\)', n, re.M)
        if not m or not pm:
            continue
        cs = int(m.group(1), 16)
        pos = [float(x) for x in pm.group(1).split(',')]
        if re.search(r'^Class = RailNode$', n, re.M) and re.search(r'^CreatedAtStart$', n, re.M):
            rails.append((cs, pos))
        rn = re.search(r'^RestartName = "([^"]*)"', n, re.M)
        if re.search(r'^Class = Restart$', n, re.M) and rn:
            restarts.append((rn.group(1), pos))
        if not re.search(r'^Class = (LevelGeometry|LevelObject)$', n, re.M) or re.search(r'^CreatedAtStart$', n, re.M):
            continue
        if cs in allb and not re.search(r'^Class = LevelObject$', n, re.M):
            lo, hi = allb[cs]
            c = [(lo[k] + hi[k]) / 2 for k in range(3)]
            r = max(hi[k] - lo[k] for k in range(3)) / 2
        else:
            c, r = pos, 100.0
        hidden.append((cs, c, r))
    if not hidden:
        return '\n'

    def near(c, b, e):
        return all(b[0][k] - e <= c[k] <= b[1][k] + e for k in range(3))

    groups = []          # (desc, [hidden], [killed names])
    for desc, intact in SWAPS.get(level, []):
        ib = [allb[i] for i in intact if i in allb]
        var = [h for h in hidden if any(near(h[1], b, 300 + h[2]) for b in ib)]
        hidden = [h for h in hidden if h not in var]
        vb = [allb[h[0]] for h in var if h[0] in allb]
        kill = list(intact) + [cs for cs, p in rails if any(near(p, boxes[i], 10) for i in intact if i in boxes)
                               and not any(near(p, b, 10) for b in vb)]   # rails the variant also has stay
        groups.append((desc, var, kill))
    coll = {p8conv.crc('Collectible_%02d' % i) for i in range(1, 21)}
    cg = [h for h in hidden if h[0] in coll]          # P8 career collectibles (story pickups)
    if cg:
        hidden = [h for h in hidden if h not in cg]
        groups.append(('Collectibles', cg, []))
    rest = [[h] for h in hidden]
    centre = lambda g: [sum(h[1][k] for h in g) / len(g) for k in range(3)]
    while len(rest) > 1:
        best = None
        for i in range(len(rest)):
            for j in range(i + 1, len(rest)):
                d = math.dist(centre(rest[i]), centre(rest[j]))
                if best is None or d < best[0]:
                    best = (d, i, j)
        if len(rest) + len(groups) <= 8 and best[0] > 1500:
            break
        d, i, j = best
        rest[i] += rest.pop(j)
    rest.sort(key=lambda g: centre(g)[0])
    for i, g in enumerate(rest, 1):
        groups.append(('Story pieces %d' % i if len(rest) > 1 else 'Story pieces', g, []))
    items, scripts = [], []
    for gi, (desc, g, kill) in enumerate(groups[:8], 1):
        c = centre(g)
        r = max(math.dist(c, h[1]) + h[2] for h in g)
        cam = [c[0] + (r + 400) * 0.6, c[1] + (r + 400) * 0.5, c[2] + (r + 400) * 0.6]
        v = [cam[k] - c[k] for k in range(3)]
        ln = math.sqrt(sum(x * x for x in v)) or 1.0
        sname = '%s_LEVEL_CHANGE_%02d' % (level, gi)
        items += ['{', 'desc = "%s"' % desc.replace('"', "'")[:40],
                  'flag = SERVER_LEVEL_CHANGE_%02d_ON' % gi,
                  'toggle_script = {', 'on_script = %s' % sname, 'on_script_params = { on }',
                  'off_script = %s' % sname, 'off_script_params = { off }', '}',
                  'camera_pos = (%.3f,%.3f,%.3f)' % tuple(cam),
                  'camera_dir = (%.3f,%.3f,%.3f)' % tuple(x / ln for x in v), '}']
        scripts += ['script %s' % sname, '    if GotParam on']
        scripts += ['        kill name = #"0x%08x"' % k for k in kill]
        scripts += ['        create name = #"0x%08x"' % h[0] for h in g]
        scripts += ['    else']
        scripts += ['        kill name = #"0x%08x"' % h[0] for h in g]
        scripts += ['        create name = #"0x%08x"' % k for k in kill]
        scripts += ['    endif', 'endscript']
    return '\n'.join(['%s_option_items = [' % level] + items + [']'] + scripts) + '\n'


def overview_cam(level):
    """a point above the middle of the level, high enough to see most of it: the 5..95 % range of the collision
    objects' centres (far-off pieces left out), raised above their tops by ~0.8 x the level's size"""
    import colparse
    p = os.path.join(OUT, 'tmp', level, level + '.col.xbx')
    if not os.path.isfile(p):
        return None
    objs = colparse.sections(open(p, 'rb').read(), 0x20)['objs']
    if not objs:
        return None
    pick = lambda vals: (sorted(vals)[len(vals) // 20], sorted(vals)[len(vals) * 19 // 20])
    x0, x1 = pick([(o['bmin'][0] + o['bmax'][0]) / 2 for o in objs])
    z0, z1 = pick([(o['bmin'][2] + o['bmax'][2]) / 2 for o in objs])
    top = pick([o['bmax'][1] for o in objs])[1]
    size = max(x1 - x0, z1 - z0)
    return ((x0 + x1) / 2, top + 0.8 * size, (z0 + z1) / 2)


def userslots_q():
    out = []  # the block that goes in mods/menuui/userslots.q (Project 8 levels in THUG Pro's greyed P8 slots)
    for level, zone, slot, name, sky in LEVELS:
        out += ['Level_dadmod_%s = {' % level,
                'game = THP8',
                'structure_name = Level_dadmod_%s' % level,
                'load_script = #"0x%08x"' % slot,
                'Name = "%s"' % name,
                'loading_time = 8.5',
                'level = "%s"' % level,
                'sky = "%s_Sky"' % level,
                'qb = "levels\\\\%s\\\\%s.qb"' % (level, level),
                'level_qb = "levels\\\\%s\\\\%s_scripts.qb"' % (level, level),
                'more_level_qbs = [', '"levels\\\\%s\\\\%s_thugpro.qb"' % (level, level), ']',
                'pre = "%s_scripts.pre"' % level,
                'scnpre = "%sscn.pre"' % level,
                'colpre = "%scol.pre"' % level,
                'default_level_stuff']
        # like THUG Pro's own P8 ports (Level_z_center): no goal editor / goal attack nodes; classic goals where P8
        # has a classic mission (build_p8.CLASSIC -> <level>_goals in the level's _scripts.qb)
        out += ['DisableGoalEditor', 'DisableGoalAttack']
        ov = overview_cam(level)
        if ov:
            # thugpro_set_overview_cam_active puts the observer overview camera at overview_cam_pos looking straight
            # down (x = 90); GetSceneCenterPos + overview_cam_zoom would be thrown off by far-away pieces (Crete Park)
            out += ['overview_cam_pos = (%s)' % ','.join('%.1f' % v for v in ov), 'overview_cam_angle = 0']
        if level in CLASSIC:
            out += ['HasClassicGoals', 'goals_script = %s_goals' % level]
        out += ['}',
                'script #"0x%08x"' % slot,
                '    load_level Level_dadmod_%s' % level,
                'endscript']
    return '\n'.join(out) + '\n'


def main():
    only = sys.argv[1:]
    for level, zone, slot, name, sky in LEVELS:
        if only and level not in only:
            continue
        print(level)
        build_level(level, zone, sky)
    open(os.path.join(OUT, 'userslots_p8.q'), 'w', newline='\n').write(userslots_q())
    print('done:', os.path.join(OUT, 'data', 'pre'))


if __name__ == '__main__':
    main()
