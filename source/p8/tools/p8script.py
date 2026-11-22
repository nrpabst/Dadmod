r"""Project 8 (Xbox) QB scripts: find, decompress and decompile them (our own code).

A script is a top-level qb item of type 7 whose value points at
    u32 checksum, u32 uncompressed size, u32 compressed size, LZSS data
(Neversoft LZSS: 4096 byte ring starting at 0xFEE, flag byte LSB first, 1 = literal byte,
 0 = 2 byte reference: offset = b0 | (b1 & 0xF0) << 4, length = (b1 & 0x0F) + 3).
The decompressed bytes are THUG2-style script tokens, so work\tools\qb.py decompiles them.
"""
import os, struct, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(HERE)), 'tools'))
import qb as QB


def lzss(src, size):
    ring = bytearray(4096)
    r = 0xFEE
    out = bytearray()
    i = 0
    flags = 0
    nbits = 0
    while len(out) < size and i < len(src):
        if nbits == 0:
            flags = src[i]
            i += 1
            nbits = 8
        if flags & 1:
            c = src[i]
            i += 1
            out.append(c)
            ring[r] = c
            r = (r + 1) & 0xFFF
        else:
            if i + 1 >= len(src):
                break
            b0, b1 = src[i], src[i + 1]
            i += 2
            off = b0 | ((b1 & 0xF0) << 4)
            ln = (b1 & 0x0F) + 3
            for k in range(ln):
                c = ring[(off + k) & 0xFFF]
                out.append(c)
                ring[r] = c
                r = (r + 1) & 0xFFF
        flags >>= 1
        nbits -= 1
    return bytes(out[:size])


def scripts(b):
    """{script name checksum: decompressed token bytes} for every script item in a P8 qb (item header
    [00][flags][07][00] name, file id, value -> compressed block; found by scanning, items aren't chained)"""
    out = {}
    for o in range(0x1C, len(b) - 24, 4):
        if b[o] != 0 or b[o + 2] != 7 or b[o + 3] != 0:
            continue
        name, fid, val = struct.unpack_from('<3I', b, o + 4)
        if not (o < val < len(b) - 12):
            continue
        cs, usize, csize = struct.unpack_from('<3I', b, val)
        if 0 < usize < 1 << 20 and 0 < csize <= len(b) - val - 12 and csize <= usize + usize // 8 + 16:
            # csize == usize: stored uncompressed (short scripts, e.g. trigger scripts that only call gaps)
            out[name] = b[val + 12:val + 12 + usize] if csize == usize else lzss(b[val + 12:val + 12 + csize], usize)
    return out


NAMES = {}


def load_names(xbe_path=None, extra=()):
    """checksum -> name from P8's executable strings, our THUG2 name tables and the given files"""
    import re
    QB.NAMES.clear()
    paths = [os.path.join(os.path.dirname(os.path.dirname(HERE)), p) for p in ('readable_qb/_names.txt', 'decompiled/_names.txt')]
    for p in paths:
        if os.path.exists(p):
            QB.load_names(p)
    for p in [xbe_path] + list(extra):
        if p and os.path.exists(p):
            QB.harvest_binary(p)
    NAMES.update(QB.NAMES)


def nm(c):
    return NAMES.get(c, '#%08x' % c)


def calls(code):
    """tolerant walk of P8 script tokens -> list of lines, each [(kind, value)] where kind is
    'name' (checksum), 'int', 'float', 'str', 'vec', 'op', 'struct' (P8 inline struct: list of (key, value))"""
    import p8qb
    out, line = [], []
    i, n = 0, len(code)
    while i < n:
        op = code[i]
        i += 1
        if op in (0x00,):
            break
        if op in (0x02, 0x16, 0x17, 0x18, 0x1A, 0x2E) and i + 4 > n:
            break                            # truncated token
        if op == 0x01:
            if line:
                out.append(line)
            line = []
        elif op == 0x02:
            i += 4
            if line:
                out.append(line)
            line = []
        elif op == 0x16:
            line.append(('name', struct.unpack_from('<I', code, i)[0]))
            i += 4
        elif op == 0x17:
            line.append(('int', struct.unpack_from('<i', code, i)[0]))
            i += 4
        elif op == 0x18:
            line.append(('int', struct.unpack_from('<I', code, i)[0]))
            i += 4
        elif op == 0x1A:
            line.append(('float', struct.unpack_from('<f', code, i)[0]))
            i += 4
        elif op in (0x1B, 0x1C):
            ln = struct.unpack_from('<I', code, i)[0]
            line.append(('str', code[i + 4:i + 4 + ln].rstrip(b'\0').decode('latin1')))
            i += 4 + ln
        elif op == 0x1E:
            line.append(('vec', struct.unpack_from('<3f', code, i)))
            i += 12
        elif op == 0x1F:
            line.append(('vec', struct.unpack_from('<2f', code, i)))
            i += 8
        elif op == 0x4A:                     # P8 inline struct: u16 size, block at the next 4-byte boundary
            size = struct.unpack_from('<H', code, i)[0]
            st = (i + 2 + 3) & ~3
            try:
                line.append(('struct', p8qb.read_struct(code[st:st + size], 0)))
            except Exception:
                line.append(('struct', None))
            i = st + size
        elif op in (0x47, 0x48, 0x49):
            line.append(('op', {0x47: 'if', 0x48: 'else', 0x49: 'jump'}[op]))
            i += 2
        elif op == 0x2E:
            i += 4
        elif op in QB.RANDOMS:
            c = struct.unpack_from('<I', code, i)[0]
            i += 4 + c * 6
        elif op in QB.SIMPLE or op in (0x2C, 0x2D, 0x3E, 0x3F):
            line.append(('op', QB.SIMPLE.get(op, '%02x' % op)))
        else:
            line.append(('op', 'raw%02x' % op))
            break                            # unknown token: stop (rest unreadable)
    if line:
        out.append(line)
    return out


def text(code):
    """decompile one script body (adds the trailing end-of-file token qb.py expects)"""
    try:
        return QB.decompile(code + b'\0')
    except Exception as e:
        return '#undecodable %r: %s' % (e, code[:64].hex())
