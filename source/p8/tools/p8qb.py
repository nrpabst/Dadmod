"""Reader for Project 8 (original Xbox) structured .qb files (the newer QB layout, little endian).

Layout as worked out from the disc files:
  0x00 u32 0, u32 file size, 20 byte magic (1C 08 02 04 10 04 08 0C 0C 08 02 04 14 02 04 0C 10 10 0C 00)
  then top level items from 0x1C: [00][flags][type][00] u32 name, u32 file id, u32 value/pointer, u32 next
  struct item:  [00][(type << 1) | 1][00][00] u32 name, u32 value/pointer, u32 next (0 = last)
  struct:       [00][00][01][00] u32 first item
  array:        [00][01][element type][00] u32 count, u32 value (count 1) or pointer to the element list
  vector/pair:  [00][01][00][00] floats
types: 1 int, 2 float, 3 string, 4 wide string, 5 pair, 6 vector, 7 script, 10 struct, 12 array, 13 checksum, 26 pointer
"""
import struct

INT, FLOAT, STRING, WSTRING, PAIR, VECTOR, SCRIPT, STRUCT, ARRAY, KEY, PTR = 1, 2, 3, 4, 5, 6, 7, 10, 12, 13, 26


class Key(int):
    """a checksum value (as opposed to a plain int)"""


class Ptr(int):
    pass


def _u32(b, o):
    return struct.unpack_from('<I', b, o)[0]


def _cstr(b, o, wide=False):
    if wide:
        e = o
        while b[e:e + 2] != b'\0\0':
            e += 2
        return b[o:e].decode('utf-16-le', 'replace')
    e = b.index(b'\0', o)
    return b[o:e].decode('latin1')


def _value(b, t, v):
    if t == INT:
        return struct.unpack('<i', struct.pack('<I', v))[0]
    if t == FLOAT:
        return struct.unpack('<f', struct.pack('<I', v))[0]
    if t == KEY:
        return Key(v)
    if t == PTR:
        return Ptr(v)
    if t == STRING:
        return _cstr(b, v)
    if t == WSTRING:
        return _cstr(b, v, True)
    if t == VECTOR:
        return tuple(struct.unpack_from('<3f', b, v + 4))
    if t == PAIR:
        return tuple(struct.unpack_from('<2f', b, v + 4))
    if t == STRUCT:
        return read_struct(b, v)
    if t == ARRAY:
        return read_array(b, v)
    if t == SCRIPT:
        return ('script', v)
    raise ValueError('unknown qb type %d at %#x' % (t, v))


def read_struct(b, o):
    """list of (name or None, value) pairs; an unnamed checksum is a flag"""
    out = []
    p = _u32(b, o + 4)
    seen = set()
    while p and p not in seen:
        seen.add(p)
        t = b[p + 1] >> 1
        name = _u32(b, p + 4)
        val = _u32(b, p + 8)
        out.append((name or None, _value(b, t, val)))
        p = _u32(b, p + 12)
    return out


def read_array(b, o):
    t = b[o + 2]
    n = _u32(b, o + 4)
    if n == 0:
        return []
    if n == 1 and t in (INT, FLOAT, KEY, PTR):
        return [_value(b, t, _u32(b, o + 8))]
    lst = _u32(b, o + 8)
    if t in (INT, FLOAT, KEY, PTR):
        return [_value(b, t, _u32(b, lst + 4 * i)) for i in range(n)]
    if n == 1:
        return [_value(b, t, lst)]
    return [_value(b, t, _u32(b, lst + 4 * i)) for i in range(n)]


def read_qb(b):
    """{name checksum: value} for the top level items"""
    out = {}
    p = 0x1C
    while p + 20 <= len(b):
        t = b[p + 2]
        name, fid, val, nxt = struct.unpack_from('<4I', b, p + 4)
        if t == 0 and name == 0:
            break
        try:
            out[name] = _value(b, t, val)
        except Exception as e:  # keep going; scripts etc. are skipped
            out[name] = ('error', str(e))
        if t in (INT, FLOAT, KEY):
            p += 20
        else:
            p = None
            break
    return out


def top_items(b):
    """walk the top level item list by scanning for item headers (items are not chained)"""
    out = []
    p = 0x1C
    end = _u32(b, 4) or len(b)
    while p + 20 <= min(end, len(b)):
        if b[p] == 0 and b[p + 3] == 0 and b[p + 2] in (INT, FLOAT, STRING, WSTRING, PAIR, VECTOR, SCRIPT, STRUCT, ARRAY, KEY):
            out.append((p, b[p + 2], _u32(b, p + 4), _u32(b, p + 12)))
        break
    return out
