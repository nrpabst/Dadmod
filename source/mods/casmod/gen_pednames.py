"""Writes pednames.q: readable Edit Skater names for the ped part lists.

  python -I gen_pednames.py

The game's ped lists (mods/casfix/cas_ped_m.q, cas_ped_f.q) give each part only a desc_id and no
frontend_desc, so the part menu rows came out blank. This makes one name per list entry, in list order,
from the desc_id (city codes spelled out, numbers kept). dadmod_es_part_menu (menus.q) uses a name only
when the entry at that index has the same desc_id, otherwise "<word> <n>". Extra "none" slots are skipped
so the list shows one "None". Entries that share a desc_id get their skin set added ("(Tan)").
"""
import os, re

here = os.path.dirname(os.path.abspath(__file__))
casfix = os.path.join(here, '..', 'casfix')

LISTS = [('ped_m_torso', 'Torso'), ('ped_f_torso', 'Torso'), ('ped_m_legs', 'Pants'), ('ped_f_legs', 'Pants'),
         ('ped_m_accessories', 'Accessory'), ('ped_f_accessories', 'Accessory'), ('ped_body', 'Ped')]

CITY = {'AU': 'Australia', 'BA': 'Barcelona', 'BO': 'Boston', 'SK': 'Skatopia', 'NO': 'New Orleans'}
WORD = {'legs': 'Pants', 'duplicate': 'Extra', 'duplilcate': 'Extra', 'bbq': 'BBQ', 'thps': 'THPS',
        'au6': 'AU6', 'sk8': 'Sk8', 'anl': 'Animal', 'grafiti': 'Graffiti', 'fem': 'Female', 'beany': 'Beanie',
        'thinman': 'Thin Man', 'richkid': 'Rich Kid', 'tshirt': 'T-Shirt', 'haltertop': 'Halter Top',
        'wifebeater': 'Tank Top', 'trackjacket': 'Track Jacket', 'jeanjacket': 'Jean Jacket',
        'tanktop': 'Tank Top', 'constr': 'Construction', 'bodyguard': 'Bodyguard', 'lostsoul': 'Lost Soul',
        'cutchemist': 'Cut Chemist', 'weeman': 'Wee-man', 'starwarskid': 'Star Wars Kid', 'steveo': 'Steve-O',
        'natas': 'Natas', 'bigfoot': 'Bigfoot', 'graf': 'Graffiti', 'pedpro': '', 'wee-man': 'Wee-man',
        'burnquist': 'Burnquist', 'koston': 'Koston', 'muska': 'Muska', 'margera': 'Margera', 'mullen': 'Mullen',
        'vallely': 'Vallely', 'hawk': 'Hawk', 'jordan': 'Jordan', 'sheckler': 'Sheckler', 'neversoft': 'Neversoft'}
FIXED = {'Hat_HArd': 'Hard Hat', 'ped_BBQ_extra': 'BBQ Extra', 'specs_hounddog': 'Hounddog Specs',
         'Ped_M_Cast01': 'Cast', 'baton2': 'Baton', 'spraycan2': 'Spray Can', 'cameraglasses': 'Camera Glasses',
         'labcoat': 'Lab Coat', 'Ped_welder_mask': 'Welder Mask', 'Ped_axe': 'Axe', 'ped_axe': 'Axe',
         'Mayan': 'Mayan', 'Tikiman': 'Tiki Man', 'Ped_F_Censored': 'Censored', 'BostonGuy': 'Boston Guy',
         'Bostonchick': 'Boston Girl', 'Johnny_Turbo': 'Johnny Turbo', 'paulie_full': 'Paulie Full',
         'Phil_FULL': 'Phil Full', 'PedPro_Hawk': 'Hawk', 'Skater_Paulie': 'Paulie Skater', 'Pro_Sheckler': 'Sheckler',
         'Skatopia_Robot': 'Skatopia Robot', 'Ped_Security_Body': 'Security', 'Ped_Video': 'Video Guy',
         'Ped_Photo': 'Photo Guy', 'Ped_Trooper': 'Trooper', 'Ped_Todd': 'Todd', 'Ped_Peralta': 'Peralta',
         'Ped_F_Head_tan': 'Tan Head', 'pedFem_F': 'Female F', 'Ped_SK_Glasses': 'Skatopia Glasses'}


def entries(name):
    for fn in ('cas_ped_m.q', 'cas_ped_f.q'):
        s = open(os.path.join(casfix, fn), encoding='latin1').read().replace('\r\n', '\n')
        m = re.search(r'^' + name + r' = \[\n', s, re.M)
        if m:
            body = s[m.end():s.index('\n]\n', m.end())]
            out = []
            for it in re.split(r'\n\{\n', '\n' + body):
                d = re.search(r'^desc_id = (#"[^"]+"|\S+)', it, re.M)
                if d:
                    rs = re.search(r'^random_set = (\w+)', it, re.M)
                    out.append((d.group(1), rs.group(1) if rs else None))
            return out
    raise SystemExit('list not found: ' + name)


def nice(desc, word):
    raw = desc[2:-1] if desc.startswith('#"') else desc
    if raw in FIXED:
        return FIXED[raw]
    if raw.lower().startswith('none'):
        return 'None'
    toks = [t for t in re.split(r'[_ ]+', raw) if t]
    lead = ''
    if toks and toks[0].lower() in ('ped', 'pedfem'):
        if toks[0].lower() == 'pedfem' or (len(toks) > 1 and len(toks[1]) == 1 and toks[1].upper() not in ('M', 'F')):
            lead = 'Female ' if toks[0].lower() == 'pedfem' else 'Ped '
        toks = toks[1:]
    if toks and toks[0].upper() in ('M', 'F'):
        toks = toks[1:]
    words = []
    for t in toks:
        m = re.match(r'^([A-Za-z\-]*?)(\d+)$', t)
        num = None
        if m and m.group(1).lower() not in ('au', 'sk'):
            t, num = m.group(1), str(int(m.group(2)))
        if t.upper() in CITY:
            words.append(CITY[t.upper()])
        elif t:
            low = t.lower()
            if low in WORD:
                if WORD[low]:
                    words.append(WORD[low])
            else:
                parts = re.findall(r'[A-Z]?[a-z]+|[A-Z]+(?![a-z])|\d+', t) or [t]
                words.extend(p[:1].upper() + p[1:].lower() for p in parts)
        if num:
            words.append(num)
    text = (lead + ' '.join(words)).strip()
    return text or word


def q(text):
    return text.replace('\\', '\\\\').replace('"', "'")


rows = ['dadmod_es_ped_names = [']
for name, word in LISTS:
    ents = entries(name)
    seen_none = False
    counts = {}
    for d, _ in ents:
        counts[d] = counts.get(d, 0) + 1
    names = []
    for d, rs in ents:
        t = nice(d, word)
        if t == 'None':
            if seen_none:
                names.append('{ id = %s skip }' % d)
                continue
            seen_none = True
        if counts[d] > 1 and rs:
            t = '%s (%s)' % (t, rs.capitalize())
        names.append('{ id = %s t = "%s" }' % (d, q(t)))
    rows.append('{ list = %s w = "%s" n = [' % (name, word))
    rows.extend(names)
    rows.append('] }')
rows.append(']')
open(os.path.join(here, 'pednames.q'), 'w', encoding='latin1', newline='\n').write('\n'.join(rows) + '\n')
print('pednames.q: %d lists' % len(LISTS))
