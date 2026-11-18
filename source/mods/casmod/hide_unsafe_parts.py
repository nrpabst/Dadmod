"""Takes the Edit Skater parts listed in unsafe_parts.txt (models other players may not have) out of the normal
menus.

  python -I hide_unsafe_parts.py <build mod dir>

Every listed part gets `hidden` (the normal part menus skip it).
Touches qb/cas_ped_m.q, qb/cas_ped_f.q and qb/thugpro/procrastination.q (every definition of each list).
"""
import os, re, sys

here = os.path.dirname(os.path.abspath(__file__))
unsafe = {}
for line in open(os.path.join(here, 'unsafe_parts.txt')):
    f = line.split()
    if len(f) == 3:
        unsafe.setdefault(f[0], set()).add(f[1])
for rel in ('qb/cas_ped_m.q', 'qb/cas_ped_f.q', 'qb/thugpro/procrastination.q'):
    path = os.path.join(sys.argv[1], rel)
    src = open(path, encoding='latin1', newline='').read()
    nl = '\r\n' if '\r\n' in src else '\n'
    lines = src.split(nl)
    cur, n = None, 0
    for i, line in enumerate(lines):
        m = re.match(r'^(\w+) = \[\s*$', line)
        if m:
            cur = m.group(1)
        elif line.startswith(']'):
            cur = None
        elif cur in unsafe:
            m = re.match(r'^desc_id = (.+?)\s*$', line)
            if m and m.group(1) in unsafe[cur]:
                flags, j, depth = set(), i + 1, 0
                while depth > 0 or lines[j].strip() != '}':
                    if depth == 0:
                        flags.add(lines[j].strip())
                    depth += lines[j].count('{') - lines[j].count('}')
                    j += 1
                if 'hidden' not in flags:
                    lines[i] = nl.join([line, 'hidden'])
                    n += 1
    open(path, 'w', encoding='latin1', newline='').write(nl.join(lines))
    print('%s: %d parts moved out of the normal menus' % (rel, n))

