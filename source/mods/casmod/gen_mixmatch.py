"""Edit Skater "mix and match": builds edit_skater_*_options arrays from plain THUG Pro's ones.

  python -I gen_mixmatch.py <plain THUG Pro skateshop_cas.q> <out.q>

The input is work/decompiled_vanilla/Skateshop_scripts/skateshop_cas.q (from THUG Pro - vanilla), so neither
Kali's nor anyone else's Edit Skater changes go into the output.

Rules, applied to every option in the stock head / torso / leg / deck / tattoo / scaling lists:
- a part list that gives each sex its own skater part ([ skater_m_x skater_f_x ]) becomes two options,
  "Male ..." and "Female ...", each showing that sex's parts to any skater (Face, Backpack and the shirt
  logo items stay as they are: they follow the skater's own sex; both sexes have the same backpacks)
- Ped Heads ([ ped_m_head ped_f_head ]) splits the same way
- male and female ped torsos, accessories and pants (with colors) and whole-body peds are added
  (PED_EXTRAS); a ped option already in the input that only lists the male part gets a female twin
- Facial Hair and its color are male only: they have no female part, a female skater crashed
- plain "<part> Color" options are dropped: every part list now starts with its own Color item
  (gen_partmenu.py / qol.q dadmod_part_color_item); color options for another part (color_parts:
  sleeves, laces, grip, trucks, wheels) stay
- Sleeves / Shoelace Color become a second small tag ("sleeves", "laces") beside the shirt's / shoes' "color"
  tag, and each Adjust (logo / tattoo position) option becomes an "adjust" tag on its logo / tattoo item
  (fold_color_parts, dadmod_extra); Grip Tape / Truck / Wheel Color are dropped, their own item's color tag does the same
- Male / Female Skin Color are dropped too: the Face option's color tag edits the skater's own head
- each list is sorted into groups with a header line (GROUPS) and the text is color coded:
  male light blue, female pink, ped orange, logo/adjust purple, headers yellow (TEXT_COLORS)
- every option gets a menu title (its own text) so the part menu doesn't just say "Edit Skater"
The output only holds the arrays; build/obsspawn_test_make.sh compiles it into data/dadmod_casidle.qb,
which loads after the menu level's own scripts.
"""
import re, sys

LISTS = ['edit_skater_head_options', 'edit_skater_deck_options', 'edit_skater_torso_options',
         'edit_skater_leg_options', 'edit_skater_tattoo_options', 'edit_skater_scaling_options']
KEEP_TOGETHER = ('skater_m_head', 'skater_m_backpack')  # with create_part_cas_menu: Face and Backpack stay one option
LOGO_SCRIPTS = ('create_part_logo_menu', 'create_part_cas_pos_menu')
FEMALE_PED = {'ped_m_torso': 'ped_f_torso', 'ped_m_legs': 'ped_f_legs',
              'ped_m_accessories': 'ped_f_accessories'}
MALE_ONLY_FLAG = 'male_only'                # edit_skater_create_options_menu shows these to male skaters only
# (list, option after which they go, [(label, script, part, cam_pos)])
PED_EXTRAS = [
    ('edit_skater_torso_options', 'Adjust Back Logo', 'torso', [
        ('Male Ped Torso', 'ped_m_torso'), ('Female Ped Torso', 'ped_f_torso'),
        ('Male Ped Accessory', 'ped_m_accessories'), ('Female Ped Accessory', 'ped_f_accessories'),
        ('Ped Body', 'ped_body')]),
    ('edit_skater_leg_options', 'Pants Color', 'Legs', [
        ('Male Ped Pants', 'ped_m_legs'), ('Female Ped Pants', 'ped_f_legs')]),
]


def read_arrays(text):
    lines = text.replace('\r\n', '\n').split('\n')
    arrays = {}
    i = 0
    while i < len(lines):
        m = re.match(r'^(\w+) = \[\s*$', lines[i])
        if m and m.group(1) in LISTS:
            items, depth, cur = [], 0, None
            i += 1
            while not lines[i].startswith(']'):
                line = lines[i]
                if depth == 0 and line.strip() == '{':
                    cur = []
                if cur is not None:
                    cur.append(line)
                depth += line.count('{') - line.count('}')
                if depth == 0 and cur is not None:
                    items.append(cur)
                    cur = None
                i += 1
            arrays[m.group(1)] = items
        i += 1
    return arrays


def get(item, key):
    for line in item:
        m = re.match(r'^%s = (.*)$' % key, line)
        if m:
            return m.group(1)
    return None


def parts_of(item):
    v = get(item, 'parts')
    return v.strip('[] ').split() if v else []


def with_parts(item, parts, text, keep_group):
    out = []
    for line in item:
        if line.startswith('group_title') and not keep_group:
            continue
        if line.startswith('parts = '):
            line = 'parts = [ %s ]' % ' '.join(parts)
        elif line.startswith('text = '):
            line = "text = '%s'" % text
        out.append(line)
    return out


def sexed(text, sex):
    base = re.sub(r'^(Male|Female) ', '', text)
    return '%s %s' % (sex, base)


def add_title(item):
    if get(item, 'title') is not None or get(item, 'text') is None:
        return item
    title = get(item, 'text').strip("'")
    out = []
    for line in item:
        out.append(line)
        if line == 'pad_choose_params = {':
            out.append('title = "%s"' % title)
    return out


GROUPS = {
    'edit_skater_head_options': [
        ('FACE', [r'^Face$', r'Skin Color$', r'^Eyes', r'^Facial Hair']),
        ('HAIR', [r'^(Male|Female) Hair', r'^(Male|Female) Hat Hair']),
        ('HEADWEAR', [r'^Hats?\b', r'^Hat Logo', r'^Glasses']),
        ('PED HEADS', [r'Ped Heads'])],
    'edit_skater_deck_options': [
        ('BOARD', [r'^Board Type', r'^Deck Graphic']),
        ('GRIP TAPE', [r'^Grip Tape']),
        ('TRUCKS', [r'^Truck']),
        ('WHEELS', [r'^Wheel'])],
    'edit_skater_torso_options': [
        ('SHIRT', [r'Shirt Style', r'Sleeves Color']),
        ('LOGOS', [r'Logo$']),
        ('GEAR', [r'^Elbowpads', r'Backpack|Pack Color', r'^(Left|Right) Accessory', r'Gloves', r'^Misc Items']),
        ('PEDS', [r'^(Male|Female) Ped', r'^Ped Body'])],
    'edit_skater_leg_options': [
        ('PANTS', [r'^(Male|Female) Pants', r'^Kneepads']),
        ('FEET', [r'^Socks', r'^Shoes', r'^Shoelace']),
        ('PEDS', [r'Ped Pants'])],
    'edit_skater_tattoo_options': [
        ('HEAD AND BODY', [r'\b(Head|Chest|Back) Tattoo']),
        ('ARMS', [r'(Bicep|Sleeve|Forearm) Tattoo']),
        ('LEGS', [r'Leg Tattoo'])],
    'edit_skater_scaling_options': [
        ('BODY', [r'^Body$', r'^Chest$', r'^Waist$']),
        ('HEAD', [r'^Head Top$', r'^Face$', r'^Nose$', r'^Jaw$']),
        ('ARMS', [r'^Biceps$', r'^Forearms$', r'^Hands$']),
        ('LEGS', [r'^Thighs$', r'^Calves$', r'^Feet$']),
        ('BOARD', [r'^Wheels$', r'^Board$'])],
}
HEADER_CODE = '\\\\c5'
TEXT_COLORS = [(r'Ped', '\\\\cb'), (r'^Male ', '\\\\ca'), (r'^Female ', '\\\\cl'),
               (r'Logo$|^Adjust ', '\\\\c7')]


def text_of(item):
    return (get(item, 'text') or '').strip("'")


def drop_color_twins(items):
    menus = {tuple(parts_of(i)) for i in items if get(i, 'pad_choose_script') == 'create_part_cas_menu'}
    return [i for i in items if not (get(i, 'pad_choose_script') == 'create_part_cas_color_menu'
                                     and get(i, 'color_parts') is None
                                     and (tuple(parts_of(i)) in menus or text_of(i).endswith('Skin Color')))]


SECOND_TAGS = {'sleeves': 'sleeves', 'shoe_laces': 'laces'}   # color_parts -> small label beside "color"


def params_block(item):
    """The lines inside an item's pad_choose_params = { ... }."""
    start = item.index('pad_choose_params = {')
    depth, out = 0, []
    for line in item[start:]:
        depth += line.count('{') - line.count('}')
        out.append(line)
        if depth == 0:
            break
    return out[1:-1]


def extra_tag(label, script, item):
    params = [l for l in params_block(item) if not l.startswith('title = ')]
    return (['dadmod_extra = {', 'label = "%s"' % label, 'dx = (%.1f,0.0)' % (22 + 2 * (len(label) - 5)),
             'run = %s' % script, 'params = {', 'title = "%s"' % text_of(item)] + params + ['}', '}'])


def fold_color_parts(items):
    """Second small tags. A color option for a second part (color_parts) becomes a tag on the item it belongs to:
    Sleeves Color beside the shirt's "color", Shoelace Color beside the shoes'. An Adjust option (logo or tattoo
    position) becomes an "adjust" tag on its logo / tattoo item. Grip / truck / wheel colors are dropped: their own
    list item's "color" tag already colors that same part."""
    menus, owners = {}, {}
    for n, i in enumerate(items):
        if get(i, 'pad_choose_script') == 'create_part_cas_menu' and get(i, 'logo_parts') is None:
            menus.setdefault(tuple(parts_of(i)), n)
            owners.setdefault(tuple(parts_of(i)), n)
        if get(i, 'pad_choose_script') == 'create_part_logo_menu' and get(i, 'logo_parts') is not None:
            owners.setdefault(tuple(get(i, 'logo_parts').strip('[] ').split()), n)
    extras, drop = {}, set()
    for n, i in enumerate(items):
        script = get(i, 'pad_choose_script')
        cp = get(i, 'color_parts')
        if script == 'create_part_cas_pos_menu':
            owner = owners.get(tuple(parts_of(i)))
            if owner is not None and owner not in extras:
                extras[owner] = extra_tag('adjust', 'create_part_cas_pos_menu', i)
                drop.add(n)
            continue
        if script != 'create_part_cas_color_menu' or cp is None:
            continue
        cparts = tuple(cp.strip('[] ').split())
        if cparts in menus:
            drop.add(n)
        elif cparts[0] in SECOND_TAGS and tuple(parts_of(i)) in menus and menus[tuple(parts_of(i))] not in extras:
            extras[menus[tuple(parts_of(i))]] = extra_tag(SECOND_TAGS[cparts[0]], 'dadmod_part_color_go', i)
            drop.add(n)
    out = []
    for n, i in enumerate(items):
        if n in drop:
            continue
        out.append(i[:-1] + extras[n] + [i[-1]] if n in extras else i)
    return out

def header(text):
    return ['{', "text = '%s%s'" % (HEADER_CODE, text), 'pad_choose_script = nullscript',
            'pad_choose_params = { }', 'dadmod_header', '}']


def grouped(name, items):
    groups = GROUPS.get(name)
    if not groups:
        return items
    items = [[l for l in i if not l.startswith('group_title')] for i in items]
    out, used = [], set()
    for title, rules in groups:
        members = []
        for rule in rules:
            for n, i in enumerate(items):
                if n not in used and re.search(rule, text_of(i)):
                    members.append(i)
                    used.add(n)
        if members:
            out.append(header(title))
            out.extend(members)
    rest = [i for n, i in enumerate(items) if n not in used]
    if rest:
        out.append(header('OTHER'))
        out.extend(rest)
    return out


def color_coded(item):
    if 'dadmod_header' in item:
        return item
    text = text_of(item)
    for rule, code in TEXT_COLORS:
        if re.search(rule, text):
            return [("text = '%s%s'" % (code, text)) if l.startswith('text = ') else l for l in item]
    return item


def color_twin(item):
    out = []
    for line in item:
        if line.startswith('group_title'):
            continue
        if line.startswith('pad_choose_script = '):
            line = 'pad_choose_script = create_part_cas_color_menu'
        elif line.startswith('text = '):
            line = "text = '%s Color'" % get(item, 'text').strip("'")
        out.append(line)
    return out


def add_missing_colors(items):
    colored = set()
    for i in items:
        if get(i, 'pad_choose_script') == 'create_part_cas_color_menu':
            cp = get(i, 'color_parts')
            colored.add(tuple(cp.strip('[] ').split()) if cp else tuple(parts_of(i)))
    out = []
    for item in items:
        out.append(item)
        parts = tuple(parts_of(item))
        if (get(item, 'pad_choose_script') == 'create_part_cas_menu' and parts and parts[0] not in KEEP_TOGETHER
                and parts not in colored):
            out.append(color_twin(item))
            colored.add(parts)
    return out


def transform(name, items):
    out = []
    for item in items:
        text = (get(item, 'text') or '').strip("'")
        parts = parts_of(item)
        script = get(item, 'pad_choose_script')
        has_group = get(item, 'group_title') is not None
        if parts == ['skater_m_jaw']:
            out.append(item if MALE_ONLY_FLAG in item else item[:1] + [MALE_ONLY_FLAG] + item[1:])
        elif (len(parts) == 2 and parts[0] != parts[1] and script not in LOGO_SCRIPTS
              and get(item, 'logo_parts') is None
              and not (parts[0] in KEEP_TOGETHER and script == 'create_part_cas_menu')
              and parts[0] != 'skater_m_backpack'
              and re.match(r'(skater|ped)_m_', parts[0]) and re.match(r'(skater|ped)_f_', parts[1])):
            out.append(with_parts(item, [parts[0]] * 2, sexed(text, 'Male'), has_group))
            out.append(with_parts(item, [parts[1]] * 2, sexed(text, 'Female'), False))
        elif len(parts) == 2 and parts[0] == parts[1] and parts[0] in FEMALE_PED:
            female = FEMALE_PED[parts[0]]
            out.append(with_parts(item, parts, sexed(text, 'Male'), has_group))
            out.append(with_parts(item, [female] * 2, sexed(text, 'Female'), False))
        else:
            out.append(item)
        for lst, anchor, cam, extras in PED_EXTRAS:
            if lst == name and text == anchor:
                for label, part in extras:
                    if any(parts_of(i) == [part, part] for i in items):
                        continue
                    for suffix, script in (('', 'create_part_cas_menu'), (' Color', 'create_part_cas_color_menu')):
                        out.append(['{', "text = '%s%s'" % (label, suffix), 'pad_choose_script = %s' % script,
                                    'pad_choose_params = {', 'parts = [ %s %s ]' % (part, part),
                                    'callback = edit_skater_create_options_menu', 'callback_params = {',
                                    'options_array = %s' % name, 'cam_pos = %s' % cam, '}', '}', '}'])
    return [color_coded(add_title(i)) for i in grouped(name, fold_color_parts([add_title(i) for i in drop_color_twins(out)]))]


def main(src, dst):
    arrays = read_arrays(open(src, encoding='latin1').read())
    missing = [n for n in LISTS if n not in arrays]
    if missing:
        sys.exit('not found in %s: %s' % (src, missing))
    lines = []
    for name in LISTS:
        lines.append('%s = [' % name)
        for item in transform(name, arrays[name]):
            lines.extend(item)
        lines.append(']')
    open(dst, 'w', encoding='latin1', newline='\n').write('\n'.join(lines) + '\n')


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
