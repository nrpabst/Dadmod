r"""Which names the client build uses that only Kali defines (not plain THUG Pro).

    python -I client/tools/kali_audit.py            (run from work/, after make_client.py --gen)

Defined-by sets come from the decompiled script trees gen_client_qb.py already uses:
  stock = decompiled_stock/thugpro_qb (THUG Pro REAL BASE INSTALL), kali = decompiled/thugpro_qb (Kali v2 1.2 Original).
Our client scripts: client/qb/gen/*.q, client/qb/dadmod/*.q and the Edit Skater file (casidle sources).
A name counts as a Kali-only dependency when one of our client files mentions it, Kali defines it, plain THUG Pro
does not, and our client does not define it itself. Wrapped stock scripts (client/wrap.txt) that plain THUG Pro
lacks are listed too (their <name>_orig would not exist there).
Writes client/tools/kali_audit_report.txt.
"""
import collections, glob, os, re, sys

WORK = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.chdir(WORK)
sys.path.insert(0, os.path.join(WORK, 'client', 'tools'))
import gen_client_qb as g   # noqa: E402

CASIDLE = ['mods/mainmenu/casidle.q', 'mods/casmod/lists.q', 'mods/casmod/logo_adjust.q', 'mods/casmod/sexchange.q',
           'mods/casmod/offline.q', 'mods/casmod/undress.q', 'mods/casmod/menus.q', 'mods/casmod/removeitems.q',
           'mods/casmod/qol.q', 'mods/casmod/ownmenus.q']
NAME = re.compile(r'#"([^"]*)"|("(?:[^"\\]|\\.)*"|\'(?:[^\'\\]|\\.)*\')|([A-Za-z_][A-Za-z0-9_]*)')


def main():
    stock = g.effective(g.STOCK)
    kali = g.effective(g.KALI)
    files = sorted(glob.glob('client/qb/gen/*.q')) + sorted(glob.glob('client/qb/dadmod/*.q')) + CASIDLE
    ours = {}
    for p in files:
        for k in g.blocks(p):
            ours[g.name_of(k).lower()] = p
    wraps = [l.strip() for l in open('client/wrap.txt', encoding='latin-1') if l.strip() and not l.startswith('#')]
    for w in wraps:
        if w.lower() in stock:
            ours[(w + '_orig').lower()] = 'client/wrap.txt'
    uses = collections.defaultdict(list)   # kali-only name -> [(file, our block)]
    for p in files:
        for k, text in g.blocks(p).items():
            for m in NAME.finditer(text):
                if m.group(2):
                    continue
                n = (m.group(1) if m.group(1) is not None else m.group(3)).lower()
                if n in kali and n not in stock and n not in ours:
                    if (p, g.name_of(k)) not in uses[n]:
                        uses[n].append((p, g.name_of(k)))
    out = ['# Kali-only names the client build uses (defined by Kali, not by plain THUG Pro, not by our client)', '']
    for n in sorted(uses):
        out.append('%s  (Kali: %s %s)' % (kali[n][0].split(' ')[1], kali[n][0].split(' ')[0], kali[n][2]))
        for p, b in uses[n]:
            out.append('    used by %s in %s' % (b, p))
    out += ['', '# wrapped stock scripts plain THUG Pro does not have']
    out += ['%s (Kali: %s)' % (w, kali[w.lower()][2] if w.lower() in kali else 'not in Kali either') for w in wraps if w.lower() not in stock]
    open('client/tools/kali_audit_report.txt', 'w', encoding='latin-1').write('\n'.join(out) + '\n')
    print('%d Kali-only names used; report client/tools/kali_audit_report.txt' % len(uses))


if __name__ == '__main__':
    main()
