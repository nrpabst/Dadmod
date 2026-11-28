"""Writes cars2_stock_gen.q: the VehicleSetupMapping entries a dadmod host pushes to players without dadmod
(cars2_stock.q) so they see More Cars / Props as the real model instead of the green tuner.
Reads cars2_gen.q (each dadmod_*_setup: model, dadmod_prop_model, skater_pos, make_skater_visible).
A stock game's lock_car_to_non_local_skater reads only model, skater_pos (and NonLocalClientInVehicle
make_skater_visible), so each entry carries just those. Props are left out (stock players keep seeing the green tuner
for them): a static prop model on a stock game's car crashed it in the 2026-11-24 LAN test (Traffic Cone, crash at
0x433730 in the car code). A prop can be added to SAFE_PROPS once a LAN test shows a stock game survives it.
Run again after gen_cars2.py changes the setups:  python -I mods/cars2/gen_cars2_stock.py   (from work/)"""
import os, re
HERE = os.path.dirname(os.path.abspath(__file__))
STOCK_MAP = ['JunkerCar = TransCarSetup', 'RallyCar = CustomCarSetup', 'ImpalaCar = ImpalaCarSetup',
             'TaxiNY = TaxiNYSetup', 'PoliceCar = PoliceCarSetup', 'SecurityCart = SecurityCartSetup',
             'GardnersCart = GardnersCartSetup', 'ElCaminoCar = ElCaminoCarSetup', 'Blimp = BlimpSetup',
             'LadaCar = LadaCarSetup', 'MiniBajaCar = MiniBajaCarSetup', 'LimoCar = LimoCarSetup',
             'Forklift = ForkliftSetup', 'RCCar = RCCarSetup', 'TaurusCar = TaurusCarSetup',
             'PickupTruck = PickupTruckSetup', 'WranglerCar = WranglerCarSetup', 'SportsCar = SportsCarSetup',
             'OffroadCar = OffroadCarSetup']
SAFE_PROPS = set()
s = open(os.path.join(HERE, 'cars2_gen.q'), encoding='latin1').read().replace('\r\n', '\n')
m = re.search(r'^dadmod_c2_extra_map = \{\n(.*?)\n\}', s, re.S | re.M)
assert m, 'dadmod_c2_extra_map not found'
out = ['dadmod_c2_stock_tbl = {', 'm = {'] + STOCK_MAP + ['}', '}', 'dadmod_c2_stock_entries = {']
n = 0
for line in m.group(1).split('\n'):
    ct, setup = [x.strip() for x in line.split('=')]
    if ct.startswith('dadmod_prop_') and ct not in SAFE_PROPS:
        continue
    b = re.search(r'^' + re.escape(setup) + r' = \{\n(.*?)\n\}$', s, re.S | re.M)
    assert b, setup
    body = b.group(1)
    def get(k):
        r = re.search(r'^' + k + r' = (.+)$', body, re.M)
        return r.group(1) if r else None
    model = get('dadmod_prop_model') or get('model')
    pos = get('skater_pos') or '(0.0,0.0,0.0)'
    assert model and model.startswith('"'), setup
    vis = ' make_skater_visible' if re.search(r'^make_skater_visible$', body, re.M) else ''
    out.append('%s = { %s = { model = %s skater_pos = %s%s } }' % (ct, ct, model, pos, vis))
    n += 1
out.append('}')
open(os.path.join(HERE, 'cars2_stock_gen.q'), 'w', newline='\n').write('\n'.join(out) + '\n')
print('cars2_stock_gen.q: %d entries' % n)
