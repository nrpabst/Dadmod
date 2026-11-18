"""THUG2 / THUG Pro QScript (.qb) decompiler + compiler, lossless round trip.

  qb.py d [--names F]... [--bin F]... OUTDIR IN...   decompile .qb files/dirs to .q
  qb.py c IN.q OUT.qb                                 compile one .q
  qb.py verify [--names F]... [--bin F]... DIR...     decompile+recompile every .qb, compare bytes

Text format (one source line per 0x01 newline; indentation is cosmetic):
  name / #"Some Name" / #"0x1234abcd"   checksum name (0x16)
  <name>  <...>                         argument / all-args
  12  -3  0x1f                          int (0x17), hex int (0x18)
  1.5  -2.0                             float (0x1A)
  "text"  'text'                        string (0x1B), local string (0x1C)
  (1.0,2.0)  (1.0,2.0,3.0)              pair / vector, written with no spaces
  if / else / endif                     0x47 / 0x48 / 0x28 (branch offsets computed)
  switch / case / default / endswitch   0x3C/0x3E/0x3F/0x3D (0x49 jumps computed)
  random( @ ... @*3 ... )               0x2F (also random2( randomnorepeat( randompermute()
  #L(n) at end of line                  that newline is 0x02 with line number n
  #raw(hex)                             raw bytes (fallback, should not appear)
"""
import os, re, struct, sys

# ---------------------------------------------------------------- names
NAMES = {}

def qbkey(text):
    c = 0xFFFFFFFF
    for ch in text.lower().replace('/', '\\').encode('latin1', 'ignore'):
        c ^= ch
        for _ in range(8):
            c = (c >> 1) ^ (0xEDB88320 if c & 1 else 0)
    return c

def load_names(path):
    for ln in open(path, encoding='latin1'):
        p = ln.rstrip('\n').split(' ', 1)
        if len(p) == 2 and p[0].startswith('0x'):
            NAMES.setdefault(int(p[0], 16), p[1])

def harvest_binary(path):
    data = open(path, 'rb').read()
    for m in re.finditer(rb'[A-Za-z_][A-Za-z0-9_]{2,63}', data):
        s = m.group().decode('latin1')
        NAMES.setdefault(qbkey(s), s)

# ---------------------------------------------------------------- tokens
SIMPLE = {
    0x03: '{', 0x04: '}', 0x05: '[', 0x06: ']', 0x07: '=', 0x08: '.', 0x09: ',',
    0x0A: '-', 0x0B: '+', 0x0C: '/', 0x0D: '*', 0x0E: '(', 0x0F: ')', 0x11: '==',
    0x12: '<', 0x13: '<=', 0x14: '>', 0x15: '>=', 0x20: 'begin', 0x21: 'repeat',
    0x22: 'break', 0x23: 'script', 0x24: 'endscript', 0x28: 'endif', 0x29: 'return',
    0x2A: 'undefined', 0x2C: '<...>', 0x30: 'randomrange', 0x38: 'randomrange2',
    0x31: 'at', 0x32: 'or', 0x33: 'and', 0x34: 'xor', 0x35: '<<', 0x36: '>>',
    0x39: 'not', 0x3C: 'switch', 0x3D: 'endswitch', 0x42: ':',
}
KW2OP = {v: k for k, v in SIMPLE.items()}
RANDOMS = {0x2F: 'random(', 0x37: 'random2(', 0x40: 'randomnorepeat(', 0x41: 'randompermute('}
RAND2OP = {v: k for k, v in RANDOMS.items()}
RESERVED = set(KW2OP) | {'if', 'else', 'case', 'default', 'arg'} | {r[:-1] for r in RAND2OP}
FIXED = {0x02: 4, 0x16: 4, 0x17: 4, 0x18: 4, 0x1A: 4, 0x1E: 12, 0x1F: 8, 0x2E: 4,
         0x47: 2, 0x48: 2, 0x49: 2}

class QBError(Exception):
    pass

def raw_tokens(b):
    """Split bytecode into (pos, op, payload) up to and including the final 0x00."""
    i, n, out = 0, len(b), []
    while i < n:
        p, op = i, b[i]; i += 1
        if op == 0x00:
            out.append((p, 0, b''))
            return out, b[i:]
        if op in (0x1B, 0x1C):
            ln = struct.unpack_from('<I', b, i)[0]; i += 4 + ln
        elif op == 0x2B:
            i += 4; i = b.index(b'\0', i) + 1
        elif op in RANDOMS:
            c = struct.unpack_from('<I', b, i)[0]; i += 4 + c * 6
        elif op in FIXED:
            i += FIXED[op]
        elif not (op == 0x01 or op in SIMPLE or op in (0x2D, 0x2C, 0x3E, 0x3F)):
            raise QBError(f'unknown opcode 0x{op:02x} at 0x{p:x}')
        out.append((p, op, b[p + 1:i]))
    raise QBError('missing end-of-file token')

# ---------------------------------------------------------------- decompile
IDENT = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*$')

def name_text(c):
    s = NAMES.get(c)
    if s is not None and qbkey(s) == c:
        if IDENT.match(s) and s.lower() not in RESERVED:
            return s
        if '"' not in s and s and not s.lower().startswith('0x'):
            return f'#"{s}"'
    return f'#"0x{c:08x}"'

def f32(x):
    """Shortest decimal text that reads back as the same float32."""
    raw = struct.pack('<f', x)
    if x != x or x in (float('inf'), float('-inf')):
        return f'#f({raw.hex()})'
    for prec in range(1, 12):
        s = f'{x:.{prec}g}'
        if struct.pack('<f', float(s)) == raw:
            break
    if 'e' not in s and '.' not in s and 'n' not in s:
        s += '.0'
    if s == '0.0' and raw != b'\0\0\0\0':
        return f'#f({raw.hex()})'  # -0.0
    return s

def quote(s, q):
    return q + s.replace('\\', '\\\\').replace(q, '\\' + q).replace('\n', '\\n').replace('\r', '\\r') + q

def decompile(b):
    toks, _tail = raw_tokens(b)
    # harvest this file's own table
    for p, op, a in toks:
        if op == 0x2B:
            c = struct.unpack_from('<I', a)[0]
            NAMES.setdefault(c, a[4:-1].decode('latin1'))
    pos2i = {p: k for k, (p, op, a) in enumerate(toks)}
    # markers to insert before token index k
    before = {}
    def mark(k, text):
        before.setdefault(k, []).append(text)
    skip = set()
    RAWHDR = set()
    # random blocks: branch starts and end
    for k, (p, op, a) in enumerate(toks):
        if op in RANDOMS:
            cnt = struct.unpack_from('<I', a)[0]
            weights = struct.unpack_from(f'<{cnt}H', a, 4)
            offs = struct.unpack_from(f'<{cnt}I', a, 4 + cnt * 2)
            starts = []
            for j in range(cnt):
                slot_end = p + 1 + 4 + cnt * 2 + j * 4 + 4
                starts.append(slot_end + offs[j])
            end = None
            for j, s in enumerate(starts):
                if s not in pos2i:
                    raise QBError(f'random branch target 0x{s:x} not on token')
                bk = pos2i[s]
                if j > 0:
                    jk = bk - 1
                    jp, jop, ja = toks[jk]
                    if jop != 0x2E:
                        raise QBError(f'random branch {j} at 0x{s:x} not preceded by jump')
                    t = jp + 5 + struct.unpack('<i', ja)[0]
                    if end is not None and t != end:
                        raise QBError('random jumps disagree')
                    end = t; skip.add(jk)
                mark(bk, '@' if weights[j] == 1 else f'@*{weights[j]}')
            if end is None:  # one branch: keep header verbatim (offset is relative, stays valid)
                before[pos2i[starts[0]]].remove('@')
                RAWHDR.add(k)
                continue
            mark(pos2i[end], ')')
    out, line = [], []
    depth, pend = 0, 0
    def flush(ln=None):
        nonlocal line
        text = ' '.join(line)
        if ln is not None:
            text = (text + ' ' if text else '') + f'#L({ln})'
        out.append(text)
        line = []
    dedent_first = {'endscript', 'repeat', 'endif', 'endswitch', 'else', 'case', 'default'}
    k = 0
    while k < len(toks):
        p, op, a = toks[k]
        for m in before.get(k, []):
            line.append(m)
        if op == 0x00 or op == 0x2B:
            k += 1; continue
        if k in skip:
            k += 1; continue
        if op in (0x01, 0x02):
            flush(struct.unpack('<I', a)[0] if op == 0x02 else None)
            k += 1; continue
        if op == 0x16:
            line.append(name_text(struct.unpack('<I', a)[0]))
        elif op == 0x2D:
            if k + 1 < len(toks) and toks[k + 1][1] == 0x16 and k + 1 not in before:
                line.append('<' + name_text(struct.unpack('<I', toks[k + 1][2])[0]) + '>')
                k += 1
            else:
                line.append('#arg')
        elif op == 0x17:
            line.append(str(struct.unpack('<i', a)[0]))
        elif op == 0x18:
            line.append(f'0x{struct.unpack("<I", a)[0]:x}')
        elif op == 0x1A:
            line.append(f32(struct.unpack('<f', a)[0]))
        elif op in (0x1B, 0x1C):
            ln = struct.unpack_from('<I', a)[0]; data = a[4:]
            s = data[:-1].decode('latin1') if data.endswith(b'\0') else None
            if s is None or '\0' in s or len(data) != ln:
                line.append(f'#raw({bytes([op]).hex()}{a.hex()})')
            else:
                line.append(quote(s, '"' if op == 0x1B else "'"))
        elif op == 0x1E:
            line.append('(' + ','.join(f32(v) for v in struct.unpack('<3f', a)) + ')')
        elif op == 0x1F:
            line.append('(' + ','.join(f32(v) for v in struct.unpack('<2f', a)) + ')')
        elif op == 0x47:
            line.append('if')
        elif op == 0x48:
            line.append('else')
        elif op == 0x3E:
            line.append('case')
            if k + 1 < len(toks) and toks[k + 1][1] == 0x49:
                k += 1
        elif op == 0x3F:
            line.append('default')
            if k + 1 < len(toks) and toks[k + 1][1] == 0x49:
                k += 1
        elif op == 0x49:
            # end-of-case jump: implied by the following case/default
            if not (k + 1 < len(toks) and toks[k + 1][1] in (0x3E, 0x3F)):
                line.append(f'#raw({bytes([op]).hex()}{a.hex()})')
        elif op in RANDOMS:
            line.append(f'#raw({bytes([op]).hex()}{a.hex()})' if k in RAWHDR else RANDOMS[op])
        elif op == 0x2E:
            line.append(f'#raw(2e{a.hex()})')
        elif op in SIMPLE:
            line.append(SIMPLE[op])
        else:
            line.append(f'#raw({bytes([op]).hex()}{a.hex()})')
        k += 1
    if line:
        out.append(' '.join(line) + ' #noeol')
    if not out:
        return ''
    # indentation
    res, depth = [], 0
    for text in out:
        words = text.split(' ', 1)
        w0 = words[0].lstrip('@').lower() if words[0] else ''
        d = depth - (1 if w0 in dedent_first else 0)
        res.append('    ' * max(d, 0) + text if text else '')
        for w in text.split(' '):
            if w in ('script', 'begin', 'if', 'switch'): depth += 1
            elif w in ('endscript', 'repeat', 'endif', 'endswitch'): depth -= 1
    return '\n'.join(res) + '\n'

# ---------------------------------------------------------------- compile
TOKEN_RE = re.compile(r'''
   (?P<ws>[ \t]+)
 | (?P<str>"(?:[^"\\]|\\.)*")
 | (?P<lstr>'(?:[^'\\]|\\.)*')
 | (?P<hashname>\#"[^"]*")
 | (?P<line>\#L\(\d+\))
 | (?P<raw>\#raw\([0-9a-f]*\))
 | (?P<fbits>\#f\([0-9a-f]{8}\))
 | (?P<noeol>\#noeol)
 | (?P<arg>\#arg)
 | (?P<vec>\((?:-?[0-9.]+(?:e[-+]?\d+)?|\#f\([0-9a-f]{8}\))(?:,(?:-?[0-9.]+(?:e[-+]?\d+)?|\#f\([0-9a-f]{8}\))){1,2}\))
 | (?P<rand>(?:random|random2|randomnorepeat|randompermute)\()
 | (?P<allargs><\.\.\.>)
 | (?P<argname><(?:[A-Za-z_][A-Za-z0-9_]*|\#"[^"]*")>)
 | (?P<branch>@(?:\*\d+)?)
 | (?P<hex>0x[0-9a-fA-F]+\b)
 | (?P<num>-?\d+(?:\.\d*)?(?:e[-+]?\d+)?(?![A-Za-z_0-9.]))
 | (?P<ident>[A-Za-z_0-9][A-Za-z0-9_]*)
 | (?P<op>==|<=|>=|<<|>>|[{}\[\]=.,\-+/*()<>:])
''', re.X | re.I)

def unquote(s):
    out, i = [], 1
    while i < len(s) - 1:
        ch = s[i]
        if ch == '\\':
            nx = s[i + 1]; out.append({'n': '\n', 'r': '\r'}.get(nx, nx)); i += 2
        else:
            out.append(ch); i += 1
    return ''.join(out)

def parse_float(t):
    if t.startswith('#f('):
        return bytes.fromhex(t[3:11])
    return struct.pack('<f', float(t))

def compile_q(text):
    code = bytearray()
    used = []          # checksum order for name table
    spelled = {}
    def name_ck(t):
        if t.startswith('#"'):
            inner = t[2:-1]
            if inner.lower().startswith('0x'):
                c = int(inner, 16)
            else:
                c = qbkey(inner); spelled.setdefault(c, inner)
        else:
            c = qbkey(t); spelled.setdefault(c, t)
        if c not in used:
            used.append(c)
        return c
    def emit_name(t):
        code.append(0x16); code.extend(struct.pack('<I', name_ck(t)))
    ifs = []       # stack of [if_operand_pos, else_operand_pos or None]
    switches = []  # stack of {'skip': pos or None, 'ends': [], 'first': bool}
    randoms = []   # stack of {'op':, 'hdr': pos, 'weights': [], 'starts': [], 'jumps': []}
    lines = text.split('\n')
    if lines and lines[-1] == '':
        lines.pop()
    for li, src in enumerate(lines):
        pos, noeol, lineno = 0, False, None
        src = src.strip()
        while pos < len(src):
            m = TOKEN_RE.match(src, pos)
            if not m:
                raise QBError(f'line {li + 1}: cannot parse at: {src[pos:pos + 30]!r}')
            pos = m.end(); kind = m.lastgroup; t = m.group()
            if kind == 'ws':
                continue
            if kind == 'str' or kind == 'lstr':
                s = unquote(t).encode('latin1') + b'\0'
                code.append(0x1B if kind == 'str' else 0x1C); code += struct.pack('<I', len(s)) + s
            elif kind == 'hashname':
                emit_name(t)
            elif kind == 'line':
                lineno = int(t[3:-1])
            elif kind == 'raw':
                code += bytes.fromhex(t[5:-1])
            elif kind == 'fbits':
                code.append(0x1A); code += parse_float(t)
            elif kind == 'noeol':
                noeol = True
            elif kind == 'arg':
                code.append(0x2D)
            elif kind == 'vec':
                parts = t[1:-1].split(',')
                code.append(0x1F if len(parts) == 2 else 0x1E)
                for v in parts: code += parse_float(v)
            elif kind == 'rand':
                op = RAND2OP[t.lower()]
                hdr = len(code); code.append(op)
                randoms.append({'op': op, 'hdr': hdr, 'weights': [], 'starts': [], 'jumps': []})
            elif kind == 'branch':
                r = randoms[-1]
                if r['starts']:
                    r['jumps'].append(len(code)); code.append(0x2E); code += b'\0\0\0\0'
                r['weights'].append(int(t[2:]) if len(t) > 1 else 1)
                r['starts'].append(len(code))
            elif kind == 'allargs':
                code.append(0x2C)
            elif kind == 'argname':
                code.append(0x2D); emit_name(t[1:-1])
            elif kind == 'hex':
                code.append(0x18); code += struct.pack('<I', int(t, 16) & 0xFFFFFFFF)
            elif kind == 'num':
                if re.fullmatch(r'-?\d+', t):
                    code.append(0x17); code += struct.pack('<i', int(t))
                else:
                    code.append(0x1A); code += parse_float(t)
            elif kind == 'ident':
                lw = t.lower()
                if lw == 'if':
                    code.append(0x47); ifs.append([len(code), None]); code += b'\0\0'
                elif lw == 'else':
                    code.append(0x48); ifs[-1][1] = len(code); code += b'\0\0'
                elif lw == 'endif':
                    code.append(0x28)
                    ip, ep = ifs.pop(); end = len(code)
                    if ep is None:
                        struct.pack_into('<H', code, ip, end - ip)
                    else:
                        struct.pack_into('<H', code, ip, ep + 2 - ip)
                        struct.pack_into('<H', code, ep, end - ep)
                elif lw == 'switch':
                    code.append(0x3C); switches.append({'skip': None, 'ends': [], 'n': 0})
                elif lw in ('case', 'default'):
                    sw = switches[-1]
                    if sw['n']:
                        sw['ends'].append(len(code) + 1); code += b'\x49\0\0'
                    if sw['skip'] is not None:
                        struct.pack_into('<H', code, sw['skip'], len(code) - sw['skip']); sw['skip'] = None
                    sw['n'] += 1
                    code += b'\x3e\x49' if lw == 'case' else b'\x3f\x49'
                    sw['skip'] = len(code); code += b'\0\0'
                elif lw == 'endswitch':
                    sw = switches.pop()
                    if sw['skip'] is not None:
                        struct.pack_into('<H', code, sw['skip'], len(code) - sw['skip'])
                    code.append(0x3D)
                    for e in sw['ends']:
                        struct.pack_into('<H', code, e, len(code) - e)
                elif lw in KW2OP and lw not in ('<', '>'):
                    code.append(KW2OP[lw])
                else:
                    emit_name(t)
            elif kind == 'op':
                if t == ')' and randoms and randoms[-1].get('open_paren', 0) == 0 and _rand_close(randoms[-1], src, m):
                    r = randoms.pop(); end = len(code)
                    cnt = len(r['starts'])
                    hdr = bytearray(struct.pack('<I', cnt) + struct.pack(f'<{cnt}H', *r['weights']))
                    offs_base = r['hdr'] + 1 + 4 + cnt * 2
                    # header is inserted now; everything after it shifts
                    hsize = len(hdr) + cnt * 4
                    code[r['hdr'] + 1:r['hdr'] + 1] = bytes(hsize)
                    shift = lambda x: x + hsize
                    starts = [shift(s) for s in r['starts']]; jumps = [shift(j) for j in r['jumps']]
                    end = shift(end)
                    _fix_inner(code, r['hdr'] + 1, hsize, randoms, ifs, switches)
                    for j, s in enumerate(starts):
                        slot = offs_base + j * 4
                        hdr += struct.pack('<I', s - (slot + 4))
                    code[r['hdr'] + 1:r['hdr'] + 1 + hsize] = hdr
                    for jp in jumps:
                        struct.pack_into('<i', code, jp + 1, end - (jp + 5))
                else:
                    if randoms and t == '(':
                        randoms[-1]['open_paren'] = randoms[-1].get('open_paren', 0) + 1
                    elif randoms and t == ')' and randoms[-1].get('open_paren', 0):
                        randoms[-1]['open_paren'] -= 1
                    code.append(KW2OP[t])
        if not noeol:
            if lineno is not None:
                code.append(0x02); code += struct.pack('<I', lineno)
            else:
                code.append(0x01)
    if ifs or switches or randoms:
        raise QBError('unclosed if/switch/random at end of file')
    for c in used:
        if c in spelled:
            code.append(0x2B); code += struct.pack('<I', c) + spelled[c].encode('latin1') + b'\0'
    code += b'\0\0'  # end-of-file token plus the pad byte Neversoft's compiler leaves
    return bytes(code)

def _rand_close(r, src, m):
    return True

def _fix_inner(code, at, size, randoms, ifs, switches):
    """Shift pending patch positions recorded after `at` by `size` (header insertion)."""
    for r in randoms:
        if r['hdr'] >= at: r['hdr'] += size
        r['starts'] = [s + size if s >= at else s for s in r['starts']]
        r['jumps'] = [j + size if j >= at else j for j in r['jumps']]
    for f in ifs:
        if f[0] >= at: f[0] += size
        if f[1] is not None and f[1] >= at: f[1] += size
    for sw in switches:
        if sw['skip'] is not None and sw['skip'] >= at: sw['skip'] += size
        sw['ends'] = [e + size if e >= at else e for e in sw['ends']]

# ---------------------------------------------------------------- cli
def gather(paths):
    files = []
    for a in paths:
        if os.path.isdir(a):
            for root, _, fs in os.walk(a):
                files += [os.path.join(root, f) for f in fs if f.lower().endswith('.qb')]
        else:
            files.append(a)
    return files

def code_part(b):
    toks, tail = raw_tokens(b)
    end = next(p for p, op, a in toks if op in (0x2B, 0x00))
    return b[:end], {struct.unpack_from('<I', a)[0] for p, op, a in toks if op == 0x2B}

def main(argv):
    mode, args = argv[0], argv[1:]
    while args and args[0] in ('--names', '--bin'):
        (load_names if args[0] == '--names' else harvest_binary)(args[1]); args = args[2:]
    if mode == 'c':
        open(args[1], 'wb').write(compile_q(open(args[0], encoding='latin1').read()))
        return
    files = gather(args[1:] if mode == 'd' else args)
    blobs = {f: open(f, 'rb').read() for f in files}
    for f, b in blobs.items():  # harvest every table first
        try:
            toks, _ = raw_tokens(b)
            for p, op, a in toks:
                if op == 0x2B:
                    NAMES.setdefault(struct.unpack_from('<I', a)[0], a[4:-1].decode('latin1'))
        except QBError:
            pass
    ok = bad = 0
    if mode == 'd':
        outdir = args[0]
        common = os.path.commonpath([os.path.abspath(f) for f in files]) if len(files) > 1 else os.path.dirname(os.path.abspath(files[0]))
        for f, b in blobs.items():
            dst = os.path.join(outdir, os.path.splitext(os.path.relpath(os.path.abspath(f), common))[0] + '.q')
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            try:
                open(dst, 'w', encoding='latin1', newline='\n').write(decompile(b)); ok += 1
            except QBError as e:
                bad += 1; print(f'{f}: {e}')
        with open(os.path.join(outdir, '_names.txt'), 'w', encoding='latin1') as fh:
            for c, s in sorted(NAMES.items(), key=lambda x: x[1].lower()):
                fh.write(f'0x{c:08x} {s}\n')
        print(f'decompiled {ok}, failed {bad}')
    elif mode == 'verify':
        tabmiss = 0
        for f, b in blobs.items():
            try:
                rb = compile_q(decompile(b))
                oc, ot = code_part(b); nc, nt = code_part(rb)
                if oc != nc:
                    n = next((i for i in range(min(len(oc), len(nc))) if oc[i] != nc[i]), min(len(oc), len(nc)))
                    bad += 1; print(f'MISMATCH {f}: first diff at 0x{n:x} (orig {len(oc)}, new {len(nc)})')
                else:
                    ok += 1
                    if not ot <= nt: tabmiss += 1
            except QBError as e:
                bad += 1; print(f'ERROR {f}: {e}')
        print(f'verified {ok} byte-exact, {bad} mismatched, {tabmiss} with name-table entries dropped')

if __name__ == '__main__':
    main(sys.argv[1:])
