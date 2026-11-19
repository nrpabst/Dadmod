"""Check: every THUGRECOMP_ function the client scripts call is registered in the client DLL.

    python -I client/tools/check_cfuncs.py      (from work/)

Reads client/qb/**/*.q and the g_cfuncs table in client/native/loader.cpp. Needs nothing but the repo.
Names in client/tools/cfuncs_allowed.txt are let through (one per line, with the reason after a #).
make_client.py runs this before it builds and stops on a gap.
"""
import glob, os, re

WORK = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
STRING = re.compile(r'"(?:[^"\\]|\\.)*"|\'(?:[^\'\\]|\\.)*\'')
NAME = re.compile(r'\bTHUGRECOMP_[A-Za-z0-9_]+')


def registered():
    src = open(os.path.join(WORK, 'client', 'native', 'loader.cpp'), encoding='latin-1').read()
    m = re.search(r'g_cfuncs\[\]\s*=\s*\{(.*?)\n\};', src, re.S)
    if not m:
        raise SystemExit('check_cfuncs: g_cfuncs table not found in client/native/loader.cpp')
    return {x.lower() for x in re.findall(r'\{\s*"(THUGRECOMP_[A-Za-z0-9_]+)"', m.group(1))}


def allowed():
    p = os.path.join(WORK, 'client', 'tools', 'cfuncs_allowed.txt')
    if not os.path.isfile(p):
        return set()
    return {x.split('#')[0].strip().lower() for x in open(p, encoding='latin-1') if x.split('#')[0].strip()}


def gaps():
    """{name: [(file, line number, script it is in)]} for calls with no entry in g_cfuncs"""
    have = registered() | allowed()
    out = {}
    for p in sorted(glob.glob(os.path.join(WORK, 'client', 'qb', '**', '*.q'), recursive=True)):
        cur = ''
        for i, line in enumerate(open(p, encoding='latin-1').read().replace('\r', '').split('\n'), 1):
            m = re.match(r'\s*script\s+(\S+)', line)
            if m:
                cur = m.group(1)
            code = STRING.sub('""', line.split('//')[0])
            for n in NAME.findall(code):
                if n.lower() not in have:
                    out.setdefault(n, []).append((os.path.relpath(p, WORK).replace('\\', '/'), i, cur))
    return out


def main():
    g = gaps()
    for n in sorted(g):
        f, i, s = g[n][0]
        print('%s is not in the client DLL: %s:%d (script %s)%s' % (n, f, i, s, ', +%d more' % (len(g[n]) - 1) if len(g[n]) > 1 else ''))
    print('check_cfuncs: %d missing' % len(g))
    return 1 if g else 0


if __name__ == '__main__':
    raise SystemExit(main())
