r"""cars 2.0 GTA 3 style handling, extra cars and drivable props (Noah 2026-11-21 "make the handling for the cars in
dadmod work like gta 3", "a drivable traffic cone ... more cars like that").

  python -I mods/cars2/gen_cars2.py        (from work\; writes mods/cars2/cars2_gen.q, appended by the make script)

Reads the stock car setups from decompiled_stock (player_controlled_vehicle.q) only to keep each car's own wheel
layout (steering / draw offsets / radius) and to clone a stock setup as the base for the extra cars and props.
All tuning numbers come from our own rules (work/notes/cars2_gta3_handling_plan.md section 3) applied to a small
per-car feel profile we wrote ourselves; no GTA data file is read or copied.

Writes:
  dadmod_c2_tunes      { <control_type> = { overrides } }  merged into the setup in dadmod_cars_go when the
                       handling option is GTA 3 (default)
  dadmod_c2_cams       { <control_type> = { d = distance h = height a = alignment_rate } }
  dadmod_car_<x>_setup / dadmod_prop_<x>_setup  full setups (clone of a stock one + model/size changes)
  dadmod_c2_extra_map  { <control_type> = <setup global> } added to VehicleSetupMapping at boot (dadmod_cars_boot)
                       so dadmod players see each other's extra cars / props
  dadmod_c2_push_map   the whole stock mapping + inline { model skater_pos } for every extra, for the optional host
                       push to players without dadmod (dadmod_cars_push)
"""
import os, re

HERE = os.path.dirname(os.path.abspath(__file__))
WORK = os.path.dirname(os.path.dirname(HERE))
STOCK = os.path.join(WORK, 'decompiled_stock', 'thugpro_qb', 'qb', 'game', 'player_controlled_vehicle.q')
OUT = os.path.join(HERE, 'cars2_gen.q')
BS = chr(92)

# Our own feel profiles: kg, CoM z (m), grip mult, slide keep, front grip share, gears, top km/h, punch, drive,
# brake m/s2, front brake share, steer deg, spring level, damping level. Numbers chosen by us for each feel.
P = {
 'muscle':  (1600, 0.10, 0.82, 0.76, 0.54, 4, 160, 22, 'R', 8.0, 0.52, 35, 1.5, 0.10),
 'tuner':   (1400, -0.28, 0.96, 0.88, 0.50, 5, 195, 29, '4', 10.5, 0.46, 31, 2.5, 0.10),
 'cruiser': (1800, 0.02, 0.90, 0.80, 0.52, 5, 160, 18, 'R', 4.0, 0.58, 29, 1.1, 0.06),
 'cop':     (1600, 0.14, 1.04, 0.79, 0.52, 5, 195, 27, '4', 10.8, 0.53, 34, 2.0, 0.12),
 'cab':     (1450, -0.22, 0.99, 0.81, 0.52, 5, 178, 19, 'F', 9.0, 0.58, 34, 1.4, 0.10),
 'cart':    (550, 0.00, 0.95, 0.85, 0.50, 4, 45, 12, 'R', 6.0, 0.50, 35, 1.6, 0.10),
 'ute':     (1950, 0.10, 0.94, 0.84, 0.50, 5, 165, 17, 'R', 8.4, 0.50, 34, 2.0, 0.12),
 'pickup':  (1950, 0.10, 0.94, 0.84, 0.50, 5, 165, 17, '4', 8.4, 0.50, 34, 2.0, 0.12),
 'compact': (1000, 0.10, 0.99, 0.85, 0.50, 4, 158, 15, 'F', 8.0, 0.78, 30, 1.6, 0.08),
 'buggy':   (800, 0.00, 0.90, 0.80, 0.48, 4, 168, 34, 'R', 6.2, 0.46, 31, 2.0, 0.08),
 'limo':    (2200, 0.00, 0.70, 0.80, 0.50, 5, 178, 11, 'F', 9.8, 0.42, 30, 1.2, 0.07),
 'sedan':   (1500, 0.14, 0.88, 0.84, 0.48, 5, 178, 17, 'F', 7.2, 0.55, 30, 1.6, 0.10),
 'suv':     (2400, -0.12, 0.92, 0.79, 0.50, 5, 168, 19, '4', 8.2, 0.50, 31, 1.5, 0.10),
 'sports':  (1400, -0.24, 1.08, 0.84, 0.53, 5, 198, 32, 'R', 11.0, 0.52, 30, 2.0, 0.13),
 'fork':    (1300, 0.30, 1.00, 0.90, 0.50, 4, 30, 8, 'F', 6.0, 0.50, 40, 1.6, 0.12),
 'van':     (2300, 0.15, 0.85, 0.75, 0.47, 5, 150, 14, 'R', 6.0, 0.60, 30, 2.0, 0.08),
 'bus':     (5000, 0.10, 0.70, 0.85, 0.45, 4, 120, 9, 'R', 4.5, 0.42, 30, 1.3, 0.07),
 'truck':   (4000, 0.30, 0.80, 0.70, 0.46, 5, 140, 12, 'R', 5.5, 0.55, 30, 2.4, 0.11),
 'prop':    (300, 0.00, 0.95, 0.85, 0.50, 4, 40, 10, 'R', 6.0, 0.50, 36, 1.6, 0.10),
}
WORLD = 0.75   # skate levels are small: top speeds x0.75
GRIP = 4.5     # base grip

# the 17 stock cars on the Cars page: control_type -> profile, camera (distance, height, alignment_rate)
STOCK_CARS = [
    ('JunkerCar', 'TransCarSetup', 'muscle', 240, 55, 3.2),
    ('RallyCar', 'CustomCarSetup', 'tuner', 255, 58, 4.0),
    ('ImpalaCar', 'ImpalaCarSetup', 'cruiser', 255, 58, 3.0),
    ('PoliceCar', 'PoliceCarSetup', 'cop', 290, 66, 3.6),
    ('TaxiNY', 'TaxiNYSetup', 'cab', 345, 78, 3.2),
    ('SecurityCart', 'SecurityCartSetup', 'cart', 240, 55, 3.5),
    ('GardnersCart', 'GardnersCartSetup', 'cart', 240, 55, 3.5),
    ('ElCaminoCar', 'ElCaminoCarSetup', 'ute', 255, 58, 3.2),
    ('LadaCar', 'LadaCarSetup', 'compact', 250, 57, 3.6),
    ('MiniBajaCar', 'MiniBajaCarSetup', 'buggy', 240, 55, 4.0),
    ('LimoCar', 'LimoCarSetup', 'limo', 320, 73, 2.6),
    ('TaurusCar', 'TaurusCarSetup', 'sedan', 250, 57, 3.4),
    ('PickupTruck', 'PickupTruckSetup', 'pickup', 290, 66, 3.0),
    ('WranglerCar', 'WranglerCarSetup', 'suv', 240, 55, 3.2),
    ('SportsCar', 'SportsCarSetup', 'sports', 240, 55, 4.4),
    ('Forklift', 'ForkliftSetup', 'fork', 240, 55, 3.5),
]
# Blimp stays stock (floaty joke vehicle)

# extra THUG2 car models every player has (loose .mdl under Game\Data\models\veh): key, label, model, base setup,
# profile, camera distance, height, alignment
EXTRA_CARS = [
    ('hearse', 'Hearse', 'veh\\Veh_Hearse\\Veh_Hearse.mdl', 'TransCarSetup', 'cruiser', 290, 66, 3.0),
    ('woodie', 'Woodie Wagon', 'veh\\Veh_Woodie\\Veh_Woodie.mdl', 'TransCarSetup', 'cruiser', 270, 62, 3.0),
    ('sedan', 'Sedan', 'veh\\Veh_Sedan\\Veh_Sedan.mdl', 'TaurusCarSetup', 'sedan', 255, 58, 3.4),
    ('smart', 'Smart Car', 'veh\\Veh_Smart_car\\Veh_Smart_Car.mdl', 'LadaCarSetup', 'compact', 220, 52, 3.8),
    ('hippyvan', 'Hippie Van', 'veh\\veh_HippyVan\\veh_HippyVan.mdl', 'PickupTruckSetup', 'van', 290, 72, 2.8),
    ('benzvan', 'Delivery Van', 'veh\\veh_Benz_Van\\veh_Benz_Van.mdl', 'PickupTruckSetup', 'van', 300, 74, 2.8),
    ('minivan', 'Minivan', 'veh\\Veh_Minivan\\Veh_Minivan.mdl', 'PickupTruckSetup', 'van', 280, 66, 3.0),
    ('oldvan', 'Old Van', 'veh\\Veh_OldVan\\Veh_OldVan.mdl', 'PickupTruckSetup', 'van', 280, 68, 2.8),
    ('suv', 'SUV', 'veh\\Veh_SUV\\Veh_SUV.mdl', 'PickupTruckSetup', 'suv', 300, 70, 3.0),
    ('rust', 'Rust Bucket', 'veh\\veh_rust\\veh_rust.mdl', 'TransCarSetup', 'muscle', 260, 60, 3.2),
    ('liberty', 'Liberty', 'veh\\veh_liberty\\veh_liberty.mdl', 'TaurusCarSetup', 'sedan', 255, 58, 3.4),
    ('bcntaxi', 'Barcelona Taxi', 'veh\\veh_barcelona_taxi\\veh_barcelona_taxi.mdl', 'TaxiNYSetup', 'cab', 270, 62, 3.2),
    ('neon', 'Neon', 'veh\\Veh_NeonType\\Veh_NeonType.mdl', 'TaurusCarSetup', 'compact', 250, 57, 3.6),
    ('dctruck', 'Box Truck', 'veh\\Veh_DCShoeTruck\\Veh_DCShoeTruck.mdl', 'PickupTruckSetup', 'truck', 380, 90, 2.4),
    ('tourbus', 'Tour Bus', 'veh\\Veh_TourBus\\Veh_TourBus.mdl', 'LimoCarSetup', 'bus', 470, 110, 2.2),
    ('atv', 'ATV', 'veh\\Veh_ATV\\Veh_ATV.mdl', 'MiniBajaCarSetup', 'buggy', 220, 52, 4.0),
    ('mardi', 'Parade Float', 'veh\\Veh_Mardi\\Veh_Mardi.mdl', 'PickupTruckSetup', 'bus', 420, 100, 2.4),
    ('duck', 'Duck Boat', 'veh\\Veh_Duck\\veh_duck.mdl', 'PickupTruckSetup', 'bus', 420, 100, 2.4),
    ('sub', 'Submarine', 'veh\\veh_sub\\veh_sub.mdl', 'PickupTruckSetup', 'van', 330, 80, 2.6),
    ('streetcar', 'Streetcar', 'veh\\veh_streetcar\\veh_streetcar.mdl', 'LimoCarSetup', 'bus', 470, 110, 2.2),
]

# drivable props (static .mdl every player has): key, label, model, half width, height, half length (inches, our
# guesses from the .col boxes), wheel radius, skater (hide / sit), sit offset, camera d, h, alignment
PROPS = [
    ('cone', 'Traffic Cone', 'Mdl_Cone\\Mdl_Cone.mdl', 9, 28, 9, 4, 'hide', None, 130, 34, 4.0),
    ('cart', 'Shopping Cart', 'veh\\Veh_Trolley\\veh_trolley.mdl', 12, 40, 25, 5, 'sit', (0.0, 18.0, -6.0), 170, 42, 3.8),
    ('scooter', 'Scooter', 'veh\\Veh_Scooter\\Veh_Scooter.mdl', 7, 40, 25, 6, 'sit', (0.0, 14.0, -4.0), 170, 42, 4.0),
    ('robot', 'Small Robot', 'veh\\veh_smallrobot\\veh_smallrobot.mdl', 16, 33, 24, 5, 'hide', None, 150, 38, 4.0),
    ('robot2', 'Robot 2', 'veh\\veh_smallrobot2\\veh_smallrobot2.mdl', 23, 42, 23, 5, 'hide', None, 160, 40, 4.0),
    ('chest', 'Treasure Chest', 'gameobjects\\pickups\\treasure_chest\\treasure_chest.mdl', 18, 24, 12, 4, 'hide', None, 140, 36, 4.0),
    ('bike', 'Copper Bike', 'veh\\Veh_CopperBike\\Veh_CopperBike.mdl', 12, 50, 40, 8, 'hide', None, 190, 48, 3.8),
    ('mini', 'Mini Car', 'veh\\Veh_Mini\\Veh_Mini.mdl', 30, 40, 60, 7, 'hide', None, 210, 50, 3.8),
    ('halfpipe', 'Half Pipe', 'veh\\Veh_Half_Pipe\\Veh_Half_Pipe.mdl', 190, 200, 360, 14, 'hide', None, 700, 170, 2.2),
]

STOCK_MAP = ['JunkerCar = TransCarSetup', 'RallyCar = CustomCarSetup', 'ImpalaCar = ImpalaCarSetup',
             'TaxiNY = TaxiNYSetup', 'PoliceCar = PoliceCarSetup', 'SecurityCart = SecurityCartSetup',
             'GardnersCart = GardnersCartSetup', 'ElCaminoCar = ElCaminoCarSetup', 'Blimp = BlimpSetup',
             'LadaCar = LadaCarSetup', 'MiniBajaCar = MiniBajaCarSetup', 'LimoCar = LimoCarSetup',
             'Forklift = ForkliftSetup', 'RCCar = RCCarSetup', 'TaurusCar = TaurusCarSetup',
             'PickupTruck = PickupTruckSetup', 'WranglerCar = WranglerCarSetup', 'SportsCar = SportsCarSetup',
             'OffroadCar = OffroadCarSetup']


def blocks():
    s = open(STOCK, encoding='latin1').read().replace('\r\n', '\n')
    out = {}
    lines = s.split('\n')
    i = 0
    while i < len(lines):
        m = re.match(r'^(\w+Setup) = \{$', lines[i])
        if not m:
            i += 1
            continue
        depth, j, body = 1, i + 1, []
        while j < len(lines):
            depth += lines[j].count('{') + lines[j].count('[') - lines[j].count('}') - lines[j].count(']')
            if depth == 0:
                break
            body.append(lines[j])
            j += 1
        out[m.group(1)] = '\n'.join(body)
        i = j + 1
    return out


def num(x):
    if isinstance(x, int):
        return str(x)
    s = ('%.3f' % x).rstrip('0')
    return s + '0' if s.endswith('.') else s


def stock_info(body):
    """wheel list (steering, draw offset, radius per wheel or None), all_wheels radius, gears, CoM text, moi, grip vels"""
    wheels = []
    m = re.search(r'\nWheels = \[\n(.*?)\n\](?:\n|$)', body, re.S)
    for w in re.findall(r'\{\n(.*?)\n\}', m.group(1), re.S):
        d = dict(re.findall(r'(\w+) = (\S+)', w))
        wheels.append(d)
    aw = dict(re.findall(r'(\w+) = (\S+)', re.search(r'all_wheels = \{\n(.*?)\n\}', body, re.S).group(1)))
    eng = re.search(r'engine = \{\n(.*?)\n\}\n', body, re.S).group(1)
    gears = [float(g) for g in re.search(r'gear_ratios = \[\n(.*?)\n\]', eng, re.S).group(1).split()]
    top = dict(re.findall(r'^(\w+) = (.+)$', body, re.M))
    return wheels, aw, gears, top


def vec(t):
    return tuple(float(v) for v in t.strip('()').split(','))


def tune(prof, wheels, aw, gears, top, mass_override=None):
    kg, comz, tm, tl, tb, ng, vk, acc, dr, bd, bb, lock, sf, sd = P[prof]
    m = mass_override or round(kg * 2.2)
    k = m / 2943.0
    r = float(aw.get('radius') or wheels[0].get('radius') or 13)
    v = vk / 1.609 * 17.6 * WORLD
    topg = min(523.6 * r / (v * 5), 12.0)
    nz = [g for g in gears if g > 0]
    f = topg / nz[-1]
    gr = [round(g * f, 3) for g in nz] + [0]
    torque = round(1600.0 / gr[0] * acc / 20.0 * k)
    st = round(GRIP * tm, 2)
    dfr = round(st * tl * 2 * tb, 2)
    drr = round(st * tl * 2 * (1 - tb), 2)
    bt = 2000 * bd / 8 * k
    bf, br = round(bt * 2 * bb), round(bt * 2 * (1 - bb))
    spr = round(200 * k * sf / 1.6)
    dmp = round(max(12, min(45, 28 * k * sd / 0.10)))
    com = -22 + 25 * comz
    comt = top.get('suspension_center_of_mass', '-22')
    comv = ('(0.0,%s,0.0)' % num(round(com, 1))) if comt.startswith('(') else num(round(com, 1))
    moi = vec(top.get('moment_of_inertia', '(6e+06,5e+06,6e+06)'))
    moit = '(%s,%s,%s)' % tuple(num(round(x * k)) for x in moi)
    eng = ['engine = {', 'drive_torque = %d' % torque, 'drag_torque = %s' % ('300' if prof in ('cart', 'prop', 'fork') else '800'),
           'upshift_rpm = 5000', 'differential_ratio = 5', 'reverse_torque_ratio = 1',
           'gear_ratios = [ %s ]' % ' '.join(num(g) for g in gr), '}']
    awl = ['all_wheels = {']
    if aw.get('radius'):
        awl.append('radius = %s' % aw['radius'])
    awl += ['moment = %s' % aw.get('moment', '3570'), 'spring_rate = %d' % spr, 'damping_rate = %d' % dmp,
            'static_friction = %s' % num(st), 'min_static_grip_velocity = %s' % aw.get('min_static_grip_velocity', '8'),
            'max_static_grip_velocity = %s' % aw.get('max_static_grip_velocity', '12'),
            'min_dynamic_grip_velocity = %s' % aw.get('min_dynamic_grip_velocity', '30'),
            'handbrake_torque = 4000', 'brake_torque = %d' % bf, '}']
    wl = ['Wheels = [']
    for w in wheels:
        front = w.get('steering', 'fixed') != 'fixed'
        drive = 'Yes' if dr == '4' or (dr == 'F') == front else 'No'
        dyn = dfr if front else drr
        hl = round(dyn * 1.15, 2) if front else round(dyn * 0.28, 2)
        ht = round(dyn, 2) if front else round(dyn * 0.5, 2)
        wl.append('{')
        if w.get('radius'):
            wl.append('radius = %s' % w['radius'])
        wl += ['max_draw_y_offset = %s' % w.get('max_draw_y_offset', '0'), 'steering = %s' % w.get('steering', 'fixed'),
               'drive = %s' % drive, 'brake_torque = %d' % (bf if front else br), 'dynamic_friction = %s' % num(dyn),
               'handbrake_throttle_friction = %s' % num(ht), 'handbrake_locked_friction = %s' % num(hl), '}']
    wl.append(']')
    head = ['mass = %d' % m, 'moment_of_inertia = %s' % moit, 'suspension_center_of_mass = %s' % comv,
            'max_steering_angle = %d' % lock, 'constant_rotational_damping = 600000']
    return head + eng + awl + wl


def clone(base_body, model, ct, sk, extra_top=None, drop=()):
    lines = base_body.split('\n')
    out = []
    skip_arr = 0
    i = 0
    while i < len(lines):
        ln = lines[i]
        key = ln.split(' = ')[0].strip() if ' = ' in ln else ln.strip()
        if key in drop:
            if ln.rstrip().endswith('['):
                depth = 0
                while True:
                    depth += lines[i].count('[') - lines[i].count(']')
                    i += 1
                    if depth <= 0:
                        break
                continue
            i += 1
            continue
        if key == 'control_type':
            ln = 'control_type = %s' % ct
        elif key == 'model' and model:
            ln = 'model = "%s"' % model.replace(BS, BS * 2)
        elif key in ('level', 'alternate_level'):
            i += 1
            continue
        out.append(ln)
        i += 1
    if extra_top:
        out = out[:1] + extra_top + out[1:]
    return out


# Engine sounds (Noah 2026-11-21 "just go with thug 2 sounds for now"): only loops every player has (THUG2's
# Game\Data\sounds, read through thug2_path, or THUG Pro's own data\sounds). Never GTA audio.
# loop key -> (sound name, LoadSound path under sounds\)
LOOPS = {
    'v8': ('_8CylinderEngineLoop', 'Shared\\Auto\\_8CylinderEngineLoop'),
    'six': ('_6CylinderEngineLoop', 'Shared\\Auto\\_6CylinderEngineLoop'),
    'four': ('_4CylinderEngineLoop', 'Shared\\Auto\\_4CylinderEngineLoop'),
    'lowrider': ('LowriderLoop', 'Shared\\Auto\\LowriderLoop'),
    'mini': ('MiniEngineLoop', 'Shared\\Auto\\MiniEngineLoop'),
    'jalopy': ('CarLoop', 'Shared\\Auto\\CarLoop'),
    'kart': ('AU_KartLoop', 'AU\\AU_KartLoop'),
    'golfcart': ('SD_CartLoop', 'SD\\SD_CartLoop'),
    'scooter': ('SK6_BA_Scooter_Engine', 'Vehicles\\SK6_BA_Scooter_Engine'),
    'bus': ('UKBusEngineLoop', 'Shared\\Auto\\UKBusEngineLoop'),
    'parade': ('ParadeFloatEngineLoop', 'Shared\\Auto\\ParadeFloatEngineLoop'),
    'tram': ('TramEngineLoop', 'Shared\\Auto\\TramEngineLoop'),
    'zootram': ('ZooTramEngineLoop', 'Shared\\Auto\\ZooTramEngineLoop'),
    'ferry': ('FerryEngineLoop', 'Shared\\Misc\\FerryEngineLoop'),
    'ship': ('UKBusEngineLoop', 'Shared\\Auto\\UKBusEngineLoop'),
    'blimp': ('SJ_BlimpEngineLoop', 'SJ\\SJ_BlimpEngineLoop'),
    'moto': ('MotoIdle01', 'Terrains\\MotoX\\MotoIdle01'),
    'cartrattle': ('ShoppingCartLoop', 'BO\\ShoppingCartLoop'),
}
# tire sound: must loop too (LA_Skid_11 has no loop marker, so it played once and stopped)
SKID = ('Vehicle_Tire_Loop', 'Vehicles\\Vehicle_Tire_Loop')
# control_type -> loop, min pitch, max pitch
CAR_SOUND = {
    'JunkerCar': ('v8', 55, 125), 'RallyCar': ('four', 70, 150), 'ImpalaCar': ('lowrider', 50, 110),
    'PoliceCar': ('v8', 60, 135), 'TaxiNY': ('six', 60, 125), 'SecurityCart': ('golfcart', 80, 130),
    'GardnersCart': ('golfcart', 80, 130), 'ElCaminoCar': ('v8', 55, 120), 'LadaCar': ('mini', 65, 135),
    'MiniBajaCar': ('kart', 70, 150), 'LimoCar': ('six', 50, 105), 'TaurusCar': ('six', 60, 125),
    'PickupTruck': ('v8', 50, 115), 'WranglerCar': ('six', 55, 120), 'SportsCar': ('four', 75, 160),
    'Forklift': ('parade', 70, 110), 'Blimp': ('blimp', 80, 110),
    'dadmod_car_hearse': ('lowrider', 50, 105), 'dadmod_car_woodie': ('six', 55, 115), 'dadmod_car_sedan': ('six', 60, 125),
    'dadmod_car_smart': ('mini', 70, 140), 'dadmod_car_hippyvan': ('jalopy', 60, 115), 'dadmod_car_benzvan': ('bus', 60, 110),
    'dadmod_car_minivan': ('six', 55, 115), 'dadmod_car_oldvan': ('jalopy', 55, 110), 'dadmod_car_suv': ('v8', 50, 115),
    'dadmod_car_rust': ('jalopy', 60, 120), 'dadmod_car_liberty': ('six', 60, 125), 'dadmod_car_bcntaxi': ('four', 65, 140),
    'dadmod_car_neon': ('four', 70, 145), 'dadmod_car_dctruck': ('bus', 50, 100), 'dadmod_car_tourbus': ('bus', 45, 95),
    'dadmod_car_atv': ('kart', 70, 150), 'dadmod_car_mardi': ('parade', 60, 100), 'dadmod_car_duck': ('ferry', 60, 110),
    'dadmod_car_sub': ('ship', 70, 115), 'dadmod_car_streetcar': ('tram', 60, 110),
    'dadmod_prop_cone': ('cartrattle', 90, 130), 'dadmod_prop_cart': ('cartrattle', 85, 120),
    'dadmod_prop_scooter': ('scooter', 80, 150), 'dadmod_prop_robot': ('zootram', 80, 140),
    'dadmod_prop_robot2': ('zootram', 70, 130), 'dadmod_prop_chest': ('cartrattle', 80, 115),
    'dadmod_prop_bike': ('moto', 70, 145), 'dadmod_prop_mini': ('mini', 70, 140), 'dadmod_prop_halfpipe': ('parade', 50, 95),
}


def qname(n):
    return '#"%s"' % n if n[0] == '_' else n


def sounds_q():
    """dadmod_c2_sounds: one PlayerVehicleSounds entry per car (added to PlayerVehicleSounds by dadmod_cars_boot),
    dadmod_c2_car_sounds: control_type -> entry name, dadmod_cars_load_sound: LoadSound of the car's engine loop"""
    roots = [r"E:\Tony Hawk's Underground 2\Game\Data\sounds",
             os.path.join(WORK, '..', 'THUG Pro Kali v2 - 1.2 Original', 'data', 'sounds')]
    missing = [p for _, p in list(LOOPS.values()) + [SKID]
               if not any(os.path.isfile(os.path.join(r, p) + '.snd') for r in roots)]
    if missing:
        raise SystemExit('gen_cars2: sound files not found: ' + ', '.join(missing))
    # 2026-11-21 (Noah: "not all cars have sounds"): the car sound component needs a looping sound; a .snd without a
    # 'smpl' (loop) chunk plays once and goes quiet (ST_JalopyEngineLoop, SK6_SE_ShipEngineLoop, LA_Skid_11).
    # Chunks are walked like the game does (no pad byte after an odd-sized chunk).
    def has_loop(path):
        for r in roots:
            f = os.path.join(r, path) + '.snd'
            if os.path.isfile(f):
                b = open(f, 'rb').read()
                i = 12
                while i + 8 <= len(b):
                    if b[i:i + 4] == b'smpl':
                        return True
                    i += 8 + int.from_bytes(b[i + 4:i + 8], 'little')
        return False
    noloop = [p for _, p in list(LOOPS.values()) + [SKID] if not has_loop(p)]
    if noloop:
        raise SystemExit('gen_cars2: sounds without a loop marker (they would play once): ' + ', '.join(noloop))
    ents = ['dadmod_c2_sounds = {']
    cmap = ['dadmod_c2_car_sounds = {']
    for ct, (loop, lo, hi) in CAR_SOUND.items():
        name = LOOPS[loop][0]
        small = loop in ('cartrattle',)
        ents += ['dadmod_snd_%s = {' % ct, 'EngineSound = %s' % qname(name),
                 'MinEngineVol = %d' % (40 if small else 120), 'MaxEngineVol = %d' % (110 if small else 190),
                 'MinEnginePitch = %d' % lo, 'MaxEnginePitch = %d' % hi, 'MinEngineRPM = 0', 'MaxEngineRPM = 100',
                 'Gears = [',
                 '{', 'DownshiftPoint = 0', 'UpshiftPoint = 35', 'BottomRPM = 30', 'TopRPM = 100', '}',
                 '{', 'DownshiftPoint = 25', 'UpshiftPoint = 60', 'BottomRPM = 45', 'TopRPM = 100', '}',
                 '{', 'DownshiftPoint = 50', 'UpshiftPoint = 82', 'BottomRPM = 55', 'TopRPM = 100', '}',
                 '{', 'DownshiftPoint = 72', 'UpshiftPoint = 100', 'BottomRPM = 60', 'TopRPM = 100', '}',
                 ']',
                 'TireSound = %s' % SKID[0], 'FullTireSlipVelocity = 1100', 'MinTireVol = 0', 'MaxTireVol = 220',
                 'MinTirePitch = 85', 'MaxTirePitch = 110',
                 'CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }',
                 'FullCollision = 5000', '}']
        cmap.append('%s = dadmod_snd_%s' % (ct, ct))
    ents.append('}')
    cmap.append('}')
    s = ['script dadmod_cars_load_sound', '    LoadSound "%s"' % SKID[1].replace(BS, BS * 2), '    switch <c>']
    for ct, (loop, lo, hi) in CAR_SOUND.items():
        s.append('    case %s' % ct)
        s.append('        LoadSound "%s" vol = 100 dropoff = 150 PosUpdateWithDoppler' % LOOPS[loop][1].replace(BS, BS * 2))
        s.append('        THUGRECOMP_Log text = "cars2: %s engine %s (%s), tires %s"' % (ct, LOOPS[loop][0], LOOPS[loop][1].replace(BS, '/'), SKID[0]))
    s += ['    default', '        THUGRECOMP_Log text = "cars2: no engine sound entry for this car"', '    endswitch', 'endscript']
    return ents + cmap + s


def boot_maps_q(extra_map, sound_entries):
    """dadmod_cars_boot_maps: Change VehicleSetupMapping / PlayerVehicleSounds to LITERAL structs (stock entries +
    ours). 2026-11-21 crash fix: `Change X = { <local holding X's name> ... }` made X include itself (a struct
    reference, not a copy) and every lookup recursed until the stack overflowed (0xC00000FD at 0x478CF6, stack full
    of 0x476AD6) as soon as a car was picked."""
    stock_snd = open(os.path.join(os.path.dirname(STOCK), 'playervehiclesounds.q'), encoding='latin1').read().replace('\r\n', '\n')
    lines = stock_snd.split('\n')
    i = lines.index('PlayerVehicleSounds = {') + 1
    depth, body = 1, []
    while i < len(lines):
        depth += lines[i].count('{') + lines[i].count('[') - lines[i].count('}') - lines[i].count(']')
        if depth == 0:
            break
        body.append(lines[i])
        i += 1
    q = ['script dadmod_cars_boot_maps',
         '    Change VehicleSetupMapping = {'] + STOCK_MAP + extra_map[1:-1] + ['}',
         '    Change PlayerVehicleSounds = {'] + body + sound_entries[1:-1] + ['}', 'endscript']
    return q


def physfix_q():
    """dadmod_c2_physfix: stock setups that drive badly get another stock car's physics (merged in dadmod_cars_go).
    2026-11-21 (Noah: "the sportscar has broken physics. can we replace it with another car's physics?"): stock
    SportsCarSetup is the only one with front wheels that don't drive, static grip 2.0 (others 4.0), rear dynamic grip
    1.6, low rotational damping (500000) and zero body restitution, so it spins out. It now uses the TransAm's
    (TransCarSetup) physics: mass, damping, body, engine and wheel grip, with its own wheel radius (11) and wheel draw
    offsets (-25 front, -21 rear) so the wheels still sit on its model. Model, colliders, sounds, control_type stay."""
    # 2026-11-21 later (Noah: "the sports car is really floaty too. can we make a drift car out of it?"): a drift setup of
    # our own on top of that: rear-wheel drive, more power, grippy front / loose rear tires (they let go above ~18 mph),
    # low spin damping so the tail swings, a big steering lock; stiffer springs, more damping and a lower center of
    # mass so it sits down instead of floating; heavier body. Then (video 03:30: body rolled far over in turns, inner
    # wheels hanging): springs 600 / damping 70, roll inertia 9e6, center of mass -40 (the Blimp's, lowest stock value).
    t = """SportsCar = {
mass = 4400
moment_of_inertia = (40000000.0,5600000.0,40000000.0)
suspension_center_of_mass = (0.0,-22.0,30.0)
colliders = [
[
(36.0,26.0,125.0)
(-36.0,26.0,125.0)
(36.0,26.0,-35.0)
]
[
(26.0,44.0,70.0)
(-26.0,44.0,70.0)
(26.0,44.0,0.0)
]
]
body_restitution = 0.2
body_friction = 0.2
body_wipeout_friction = 0.4
body_spring = 1200
collision_control = 0.3
max_steering_angle = 38
constant_rotational_damping = 200000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 8
in_air_slerp_time_delay = 0.3
engine = {
drive_torque = 600
drag_torque = 600
upshift_rpm = 6000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [ 4.2 3 1.8 0.9 0 ]
}
all_wheels = {
radius = 11
moment = 3570
spring_rate = 455
damping_rate = 60
static_friction = 2.6
min_static_grip_velocity = 4
max_static_grip_velocity = 8
min_dynamic_grip_velocity = 18
handbrake_torque = 4000
brake_torque = 2930
}
Wheels = [
{
max_draw_y_offset = -25
steering = left
drive = No
brake_torque = 3200
dynamic_friction = 2.6
handbrake_throttle_friction = 2.2
handbrake_locked_friction = 2.2
}
{
max_draw_y_offset = -25
steering = right
drive = No
brake_torque = 3200
dynamic_friction = 2.6
handbrake_throttle_friction = 2.2
handbrake_locked_friction = 2.2
}
{
max_draw_y_offset = -21
steering = fixed
drive = Yes
brake_torque = 2130
dynamic_friction = 1.5
handbrake_throttle_friction = 1.2
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = -21
steering = fixed
drive = Yes
brake_torque = 2130
dynamic_friction = 1.5
handbrake_throttle_friction = 1.2
handbrake_locked_friction = 1.0
}
]
}"""
    # 2026-11-21 08:40, the real cause (Noah: "it feels awful still. what is wrong with it?"): stock SportsCarSetup's
    # body colliders sit at y = 0 (every other car's are at ~28 and ~48) and reach 82 in behind the rear axle, so the
    # body box scrapes along the ground and the car rides on it (floaty, leaning, and stuck when the center of mass
    # went lower). Its colliders are now our own boxes at the TransAm's heights, sized to the sports car's wheels
    # (Veh_SmallSportscar.qb: wheels at z 94.6 / -2.0, x +-26, axle height 13).
    # 08:52 (Noah: "the car rolls over immediately and doesnt seem like it wants to drift"): the body no longer
    # props it up, so the narrow car tipped on grippy tires. Less grip all round (static 2.6, front 2.6, rear
    # 1.5) so it slides before it can tip, roll inertia 2e7 (resists rolling), less spin damping (200000).
    # 08:55 (Noah: "still flips over when you hit the handbrake"): with the handbrake on, the fronts used their
    # locked grip 3.0 against the rears' 0.5, so the nose bit and the car tripped over. Fronts now 2.2 under the
    # handbrake, rears 1.0 (stock TransAm value), handbrake torque 3000 (stock), roll inertia 3e7.
    # 08:56 (Noah: "car needs more weight too i think, its floaty"): mass 4400 (1.5x the TransAm), and engine,
    # brakes, handbrake, springs, damping and inertia scaled by 4400/3300 so it accelerates, stops and sits the same.
    # (No per-car gravity setting exists; Vehicle_AdjustGravity is only a short timed override.)
    # 09:00 (Noah: "the front end still wants to lift off the ground"): the model's origin (and so the center of
    # mass) is at the rear axle (wheels at z -2 and 94.6), so power lifts the nose. Center of mass moved 30 in forward
    # (z = +30, toward the middle of the wheelbase), drive torque 600.
    return ['dadmod_c2_physfix = {'] + t.split('\n') + ['}']


def main():
    B = blocks()
    q = []
    tunes = ['dadmod_c2_tunes = {']
    cams = ['dadmod_c2_cams = {']
    extra_map = ['dadmod_c2_extra_map = {']
    push = ['dadmod_c2_push_map = {'] + STOCK_MAP
    for ct, setup, prof, d, h, a in STOCK_CARS:
        w, aw, gears, top = stock_info(B[setup])
        tunes += ['%s = {' % ct] + tune(prof, w, aw, gears, top) + ['}']
        cams.append('%s = { d = %d h = %d a = %s }' % (ct, d, h, num(a)))
    labels = []
    for key, label, model, base, prof, d, h, a in EXTRA_CARS:
        ct = 'dadmod_car_' + key
        body = clone(B[base], model, ct, None)
        q += ['dadmod_car_%s_setup = {' % key] + body + ['}']
        w, aw, gears, top = stock_info(B[base])
        tunes += ['%s = {' % ct] + tune(prof, w, aw, gears, top) + ['}']
        cams.append('%s = { d = %d h = %d a = %s }' % (ct, d, h, num(a)))
        extra_map.append('%s = dadmod_car_%s_setup' % (ct, key))
        push.append('%s = { model = "%s" skater_pos = (0.0,0.0,0.0) }' % (ct, model.replace(BS, BS * 2)))
        labels.append(('car', label, ct))
    for key, label, model, hw, ht, hl, rad, sk, sitpos, d, h, a in PROPS:
        # 2026-11-21 crash fix (props crashed at 0x43BA80): the vehicle takes its wheel positions from the body
        # model's car bones; a prop .mdl has none (NULL). Props now drive a stock body (Security Cart, or the Limo
        # for the half pipe) that dadmod_cars_go hides, and the prop model is a separate object locked on top
        # (dadmod_prop_model in the setup, read by dadmod_cars_prop_show).
        ct = 'dadmod_prop_' + key
        bname = 'LimoCarSetup' if key == 'halfpipe' else 'SecurityCartSetup'
        drop = [] if sk == 'sit' else ['make_skater_visible', 'skater_pos', 'skater_anim']
        body = clone(B[bname], None, ct, sk, drop=drop)
        extra = ['dadmod_prop_model = "%s"' % model.replace(BS, BS * 2)]
        if sk != 'sit':
            extra.append('skater_pos = (0.0,0.0,0.0)')
        else:
            body = [l if not l.startswith('skater_anim') else 'skater_anim = Ped_SIT_Idle' for l in body]
        body = body[:1] + extra + body[1:]
        q += ['dadmod_prop_%s_setup = {' % key] + body + ['}']
        cams.append('%s = { d = %d h = %d a = %s }' % (ct, d, h, num(a)))
        extra_map.append('%s = dadmod_prop_%s_setup' % (ct, key))
        bm = re.search(r'^model = "(.*)"$', B[bname], re.M).group(1)
        push.append('%s = { model = "%s" skater_pos = (0.0,0.0,0.0) }' % (ct, bm))
        labels.append(('prop', label, ct))
    tunes.append('}')
    cams.append('}')
    extra_map.append('}')
    push.append('}')
    sq = sounds_q()
    sound_entries = sq[:sq.index('dadmod_c2_car_sounds = {')]
    # GTA 3 handling removed 2026-11-21 (Noah: 'ok nvm lets just use thugpro stock handling'): tunes not written
    q += cams + extra_map + push + sq + boot_maps_q(extra_map, sound_entries) + physfix_q()
    for kind in ('car', 'prop'):
        q.append('script dadmod_cars_%s_items' % ('extra' if kind == 'car' else 'prop'))
        for k2, label, ct in labels:
            if k2 == kind:
                q.append('    dadmod_cars_item_x t = "%s" c = %s' % (label, ct))
        q.append('endscript')
    open(OUT, 'w', newline='\n').write('\n'.join(q) + '\n')
    print('cars2_gen.q: %d stock cars, %d extra cars, %d props' % (len(STOCK_CARS), len(EXTRA_CARS), len(PROPS)))


main()
