"""Adds our own qb file (qb\\dadmod\\dadmod_cars.qb: cars 2.0 + throwables, compiled by tools/build.py from
$T/mod/qb/dadmod/dadmod_cars.q) to the script list THUG Pro loads (code\\qb\\qdir.txt in thugpro_qb.prx), right after
ButtonScripts.qb (or at the end if that line isn't there). Own file because ButtonScripts.qb and procrastination.qb
are at their 512 KB limit (2026-11-21). Does nothing if the entry is already listed.
  python -I mods/cars2/add_qdir.py <thugpro_qb.prx>"""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), 'tools'))
import prx_pack
from prx_extract import lzss
NEW = 'data\\qb\\dadmod\\dadmod_cars.qb'
p = sys.argv[1]
ents = prx_pack.read_entries(p)
if not any(e['name'].lower() == 'qb\\dadmod\\dadmod_cars.qb' for e in ents):
    sys.exit('add_qdir: qb\\dadmod\\dadmod_cars.qb is not in the prx (cars2.q / throw.q did not compile?)')
q = [e for e in ents if e['name'].lower().replace('/', '\\').endswith('qdir.txt')]
if len(q) != 1:
    sys.exit('add_qdir: found %d qdir.txt entries' % len(q))
e = q[0]
raw = lzss(e['data'], e['usz']) if e['csz'] else bytes(e['data'][:e['usz']])
t = raw.decode('latin1')
nl = '\r\n' if '\r\n' in t else '\n'
lines = t.split(nl)
key = lambda l: l.strip().lower().replace('/', '\\')
if any(key(l) == NEW.lower() for l in lines):
    print('qdir: dadmod_cars.qb already listed')
    sys.exit(0)
at = [k for k, l in enumerate(lines) if key(l).split('\\')[-1] == 'buttonscripts.qb']
if at:
    lines.insert(at[0] + 1, NEW)
    where = 'after ButtonScripts.qb'
else:
    end = len(lines)
    while end and not lines[end - 1].strip():
        end -= 1
    lines.insert(end, NEW)
    where = 'at the end (no ButtonScripts.qb line)'
e.update(prx_pack.stored(e['name'], nl.join(lines).encode('latin1')))
prx_pack.write_archive(ents, p)
print('qdir: dadmod_cars.qb added ' + where)
