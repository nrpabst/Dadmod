"""Hooks the mod-only throw types into THUG Pro's ClientLaunchProjectile in procrastination.q: throw_cases.txt (a
6-line block calling dadmod_throw_model, which lives in throw_types.q / ButtonScripts because procrastination.qb is near
its 512 KB limit) goes at the end of the default (COMBO O) case.  Usage: apply.py <mod tree>"""
import os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__))
p = os.path.join(sys.argv[1], 'qb', 'thugpro', 'procrastination.q')
s = open(p, newline='').read()
nl = '\r\n' if '\r\n' in s else '\n'
start = s.index('script ClientLaunchProjectile' + nl)
end = s.index('endscript', start)
body = s[start:end]
a = '    default' + nl + '        <model> = [ { component = model model = "GameObjects\\\\COMBO\\\\Goal_COMBO_O\\\\Goal_COMBO_O.mdl" } ]' + nl
m = re.search(re.escape(a) + r'        <projectilecollision> = [^\r\n]*' + re.escape(nl), body)
assert m and body.count(a) == 1, 'ClientLaunchProjectile default case not found'
cases = open(os.path.join(HERE, 'throw_cases.txt')).read().replace('\n', nl)
s = s[:start] + body.replace(m.group(0), m.group(0) + cases) + s[end:]
open(p, 'w', newline='').write(s)
print('throw: dadmod_throw_model hook added to ClientLaunchProjectile')
