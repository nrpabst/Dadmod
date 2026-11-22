r"""THUG Pro PC .snd sounds and THPG PS2 VAG sound banks (our own code).

.snd = RIFF WAVE with a PCM-looking fmt (tag 1, mono, 16 bit) whose data is 4-bit ADPCM, decoded by THUGPro.exe
0x5F5A20: per nibble (low first) the step index moves FIRST (idx += IDX[n & 7], clamp 0..88), then
delta = (STEP[idx] * (n & 7) >> 2) + (STEP[idx] >> 3), negated when n & 8; sample clamped to 16 bit.
The fmt byte-rate field holds the decoded size (4x the data size). A 'smpl' chunk after the data marks loops.

PS2 VAG (Sony ADPCM): 16-byte frames: shift/filter byte, flags byte (1 = end, 2 = loop region, 4 = loop start),
14 bytes = 28 nibbles.
"""
import struct

IDX = [-1, -1, -1, -1, 2, 4, 6, 8]
STEP = [7, 8, 9, 10, 11, 12, 13, 14, 16, 17, 19, 21, 23, 25, 28, 31, 34, 37, 41, 45, 50, 55, 60, 66, 73, 80, 88, 97,
        107, 118, 130, 143, 157, 173, 190, 209, 230, 253, 279, 307, 337, 371, 408, 449, 494, 544, 598, 658, 724, 796,
        876, 963, 1060, 1166, 1282, 1411, 1552, 1707, 1878, 2066, 2272, 2499, 2749, 3024, 3327, 3660, 4026, 4428, 4871,
        5358, 5894, 6484, 7132, 7845, 8630, 9493, 10442, 11487, 12635, 13899, 15289, 16818, 18500, 20350, 22385, 24623,
        27086, 29794, 32767]


def _step(p, i, n):
    i = max(0, min(88, i + IDX[n & 7]))
    st = STEP[i]
    d = ((st * (n & 7)) >> 2) + (st >> 3)
    p = p - d if n & 8 else p + d
    return max(-32768, min(32767, p)), i


def decode(data, count=None):
    out = []
    p = i = 0
    for byte in data:
        for n in (byte & 15, byte >> 4):
            p, i = _step(p, i, n)
            out.append(p)
    return out[:count] if count else out


def encode(samples):
    """greedy: pick the nibble whose decoded sample is closest (the decoder's own state update)"""
    p = i = 0
    nibs = []
    for s in samples:
        best = None
        for n in range(16):
            q, j = _step(p, i, n)
            e = abs(q - s)
            if best is None or e < best[0]:
                best = (e, n, q, j)
        _, n, p, i = best
        nibs.append(n)
    if len(nibs) & 1:
        nibs.append(0)
    return bytes(nibs[k] | (nibs[k + 1] << 4) for k in range(0, len(nibs), 2))


def write_snd(path, samples, rate, loop=None):
    data = encode(samples)
    fmt = struct.pack('<HHIIHH', 1, 1, rate, len(samples) * 2, 2, 16)
    body = b'WAVE' + b'fmt ' + struct.pack('<I', 16) + fmt + b'data' + struct.pack('<I', len(data)) + data
    if len(data) & 1:
        body += b'\0'
    if loop is not None:
        a, e = loop
        smpl = struct.pack('<9I', 0, 0, 0, 60, 0, 0, 0, 1, 0) + struct.pack('<6I', 0, 0, a, e, 0, 0)
        body += b'smpl' + struct.pack('<I', len(smpl)) + smpl
    open(path, 'wb').write(b'RIFF' + struct.pack('<I', len(body)) + body)


VAG_F = [(0, 0), (60, 0), (115, -52), (98, -55), (122, -60)]


def decode_vag(b):
    """-> (samples, loop (start, end) in samples or None)"""
    out = []
    h1 = h2 = 0
    loop_start = loop_end = None
    for o in range(0, len(b) - 15, 16):
        sf, fl = b[o], b[o + 1]
        shift, filt = sf & 15, min(4, sf >> 4)
        if fl & 4:
            loop_start = len(out)
        f0, f1 = VAG_F[filt]
        for k in range(28):
            byte = b[o + 2 + k // 2]
            n = (byte >> 4) if k & 1 else (byte & 15)
            if n & 8:
                n -= 16
            s = (n << 12) >> shift
            s += (h1 * f0 + h2 * f1 + 32) >> 6
            s = max(-32768, min(32767, s))
            h2, h1 = h1, s
            out.append(s)
        if fl & 1:
            if fl & 2 and loop_start is not None:
                loop_end = len(out)
            break
    loop = (loop_start, loop_end) if loop_start is not None and loop_end else None
    return out, loop
