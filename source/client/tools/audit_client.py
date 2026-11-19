r"""Audit: does the client build run the same scripts as the Dev (server) build?

    python -I client/tools/audit_client.py      (from work/, after make_client.py --gen)

Starting from every client script (client/qb/gen + client/qb/dadmod), follows every script and global they use,
the way the game would resolve it on a plain THUG Pro install and on a Kali install with dadmod's client on top,
and lists each one that ends up different from what the Dev build runs. Writes client/tools/audit_report.txt.
"""
import collections, glob, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import gen_client_qb as g   # noqa: E402  (chdirs to work/)

IDENT = re.compile(r'#"0x([0-9a-fA-F]+)"|"(?:[^"\\]|\\.)*"|\'(?:[^\'\\]|\\.)*\'|([A-Za-z_][A-Za-z0-9_]*)')


def refs(text):
    out = set()
    for m in IDENT.finditer(text):
        if m.group(1):
            out.add('#"0x%08x"' % int(m.group(1), 16))
        elif m.group(2):
            out.add(m.group(2).lower())
    return out


def keyed(d):
    """also index by checksum so #"0x..." references find named blocks"""
    out = dict(d)
    for n, v in d.items():
        if not n.startswith('#"0x'):
            out.setdefault('#"0x%08x"' % g.qbkey(n), v)
    return out


def indented_in(tree):
    """scripts a decompiled tree defines with leading spaces (g.blocks only sees definitions at column 0)"""
    found = {}
    for p in sorted(glob.glob(os.path.join(tree, '**', '*.q'), recursive=True)):
        if g.SKIP.search(os.path.basename(p)):
            continue
        for m in re.finditer(r'(?m)^[ \t]+script[ \t]+(\S+)', open(p, encoding='latin-1').read()):
            found.setdefault(m.group(1).lower(), os.path.relpath(p, tree).replace('\\', '/'))
    for n in list(found):
        if not n.startswith('#"0x'):
            found.setdefault('#"0x%08x"' % g.qbkey(n), found[n])
    return found


def main():
    stock, kali = g.effective(g.STOCK), g.effective(g.KALI)
    dev = g.effective(g.KALI, overlay=g.TREE)
    client = {}
    for p in sorted(glob.glob(os.path.join(g.OUT, '*.q'))) + sorted(glob.glob(os.path.join(g.HANDDIR, '**', '*.q'), recursive=True)):
        for k, v in g.blocks(p).items():
            client[g.name_of(k).lower()] = (k, v, p)
    wrapped = {x.strip().lower() for x in open('client/wrap.txt', encoding='latin-1') if x.strip() and not x.startswith('#')}
    devk = keyed(dev)
    indented = indented_in(g.TREE)
    # the stock and Kali trees also define some scripts with leading spaces (thugpro/control_setup.q): those exist there
    base_indented = {'STOCK': indented_in(g.STOCK), 'KALI': indented_in(g.KALI)}
    report = []
    for label, base in (('STOCK', stock), ('KALI', kali)):
        eff = dict(base)
        for n in wrapped:
            if n in base:
                eff[n + '_orig'] = base[n]
        eff.update(client)
        effk = keyed(eff)
        seen, todo = set(), list(client)
        missing, differs = collections.defaultdict(set), collections.defaultdict(set)
        while todo:
            n = todo.pop()
            if n in seen:
                continue
            seen.add(n)
            blk = effk.get(n)
            if not blk:
                continue
            for r in refs(blk[1]):
                if r == n:
                    continue
                if r not in devk:
                    if r in indented and r not in effk and r not in base_indented[label]:
                        missing[r].add(n)
                    continue
                if r not in effk:
                    missing[r].add(n)
                    continue
                if r not in client and g.norm(effk[r][1]) != g.norm(devk[r][1]):
                    differs[r].add(n)
                todo.append(r)
        report.append('## %s: Dev has these, this install does not (used by)' % label)
        for r in sorted(missing):
            report.append('%s  [%s]  <- %s' % (r, devk[r][2] if r in devk else indented[r] + ', indented', ', '.join(sorted(missing[r])[:4])))
        report.append('')
        report.append('## %s: differ from Dev (used by)' % label)
        for r in sorted(differs):
            src = 'server change' if r in kali and g.norm(kali[r][1]) != g.norm(devk[r][1]) else ('kali' if label == 'STOCK' else '?')
            report.append('%s  [%s, %s]  <- %s' % (r, devk[r][2], src, ', '.join(sorted(differs[r])[:4])))
        report.append('')
    open(os.path.join(HERE, 'audit_report.txt'), 'w', encoding='latin-1').write('\n'.join(report) + '\n')
    print('\n'.join(x for x in report if x.startswith('##')))
    print(sum(1 for x in report if x and not x.startswith('##')), 'entries -> client/tools/audit_report.txt')


if __name__ == '__main__':
    main()
