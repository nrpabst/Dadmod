r"""Project 8 (Xbox) level sound banks -> plain 16-bit PCM WAV files (THUG2 PC .snd files are plain RIFF WAVs).

    python -I p8\tools\p8sound.py <zone>_sfx.pak.xbx <zone pak> <out dir>

Our own code. Layout (worked out from the disc files):
  * data/sounds/pak/<zone>_sfx.pak.xbx is one blob of sounds. Each sound = a 0x80 byte header (WAVEFORMATEX:
    format 0x69 Xbox ADPCM, channels, rate, avg bytes, block align 36 * channels, 4 bits, extra = 64 samples
    per block) then its ADPCM data; the next sound starts at the next 128-byte boundary.
  * the zone pak's <zone>_sfx_dat_xbx.qb holds the table: one array of structs per sound
    { offset, size, name checksum, [frequency], [flag] } (keys by checksum; see SFX_KEYS).
  * Xbox ADPCM = IMA ADPCM in 36-byte blocks per channel: s16 first sample, u8 step index, u8 pad, then 32 bytes
    = 64 4-bit codes (low nibble first) -> 65 samples per block; stereo interleaves 4-byte groups per channel.
"""
import os, struct, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

STEPS = [7, 8, 9, 10, 11, 12, 13, 14, 16, 17, 19, 21, 23, 25, 28, 31, 34, 37, 41, 45, 50, 55, 60, 66, 73, 80, 88, 97,
         107, 118, 130, 143, 157, 173, 190, 209, 230, 253, 279, 307, 337, 371, 408, 449, 494, 544, 598, 658, 724, 796,
         876, 963, 1060, 1166, 1282, 1411, 1552, 1707, 1878, 2066, 2272, 2499, 2749, 3024, 3327, 3660, 4026, 4428,
         4871, 5358, 5894, 6484, 7132, 7845, 8630, 9493, 10442, 11487, 12635, 13899, 15289, 16818, 18500, 20350,
         22385, 24623, 27086, 29794, 32767]
INDEX = [-1, -1, -1, -1, 2, 4, 6, 8]


def _nib(code, pred, idx):
    step = STEPS[idx]
    diff = step >> 3
    if code & 1:
        diff += step >> 2
    if code & 2:
        diff += step >> 1
    if code & 4:
        diff += step
    if code & 8:
        diff = -diff
    pred = max(-32768, min(32767, pred + diff))
    idx = max(0, min(88, idx + INDEX[code & 7]))
    return pred, idx


def decode_xbox_adpcm(data, channels):
    """-> interleaved s16 samples (bytes)"""
    out = []
    bsz = 36 * channels
    for b in range(0, len(data) - bsz + 1, bsz):
        blk = data[b:b + bsz]
        chans = []
        for c in range(channels):
            pred, idx = struct.unpack_from('<hB', blk, 4 * c)
            idx = min(idx, 88)
            s = [pred]
            codes = []
            for g in range(8):                       # 8 groups of 4 bytes per channel
                o = 4 * channels + 4 * (g * channels + c)
                for byte in blk[o:o + 4]:
                    codes += [byte & 15, byte >> 4]
            for code in codes:
                pred, idx = _nib(code, pred, idx)
                s.append(pred)
            chans.append(s)
        for i in range(65):
            for c in range(channels):
                out.append(chans[c][i])
    return struct.pack('<%dh' % len(out), *out)


def wav(pcm, rate, channels):
    return (b'RIFF' + struct.pack('<I', 36 + len(pcm)) + b'WAVEfmt ' +
            struct.pack('<IHHIIHH', 16, 1, channels, rate, rate * 2 * channels, 2 * channels, 16) +
            b'data' + struct.pack('<I', len(pcm)) + pcm)


def thug_snd(pcm, rate, channels, loop=False):
    """interleaved s16 PCM -> a THUG Pro .snd file (bytes). THUGPro.exe always decodes .snd data as its own 4-bit
    ADPCM (0x47C870 -> 0x5F5A20, fmt byte-rate field = decoded size), so a plain PCM WAV plays as ~1 s of noise
    (Noah 2026-11-22: the P8 Suburbs fountain). Stereo is mixed down to mono. Encoder: thpg\\tools\\thugsnd.py."""
    sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
                                    'thpg', 'tools'))
    import thugsnd
    n = len(pcm) // (2 * channels)
    x = struct.unpack('<%dh' % (n * channels), pcm[:n * 2 * channels])
    if channels > 1:
        x = [sum(x[k * channels:(k + 1) * channels]) // channels for k in range(n)]
    data = thugsnd.encode(list(x))
    body = (b'WAVE' + b'fmt ' + struct.pack('<IHHIIHH', 16, 1, 1, rate, n * 2, 2, 16) +
            b'data' + struct.pack('<I', len(data)) + data + (b'\0' if len(data) & 1 else b''))
    if loop:            # loop the whole sound (thugsnd.write_snd's 'smpl' layout)
        smpl = struct.pack('<9I', 0, 0, 0, 60, 0, 0, 0, 1, 0) + struct.pack('<6I', 0, 0, 0, n - 1, 0, 0)
        body += b'smpl' + struct.pack('<I', len(smpl)) + smpl
    return b'RIFF' + struct.pack('<I', len(body)) + body


def sound_table(zone_pak):
    """{name checksum: dict(offset, size, rate?, flag?)} from the zone's _sfx_dat_xbx.qb"""
    import p8conv, p8qb
    crc = p8conv.crc
    files = p8conv.read_pak(open(zone_pak, 'rb').read())
    d = [f for f in files if 'sfx_dat' in f['name'].lower()]
    if not d:
        return {}
    q = p8qb.read_qb(d[0]['data'])
    items = q.items() if isinstance(q, dict) else q
    K_OFF, K_SIZE, K_NAME, K_RATE = crc('offset'), crc('size'), crc('name'), crc('frequency')
    out = {}
    for _, v in items:
        if not isinstance(v, list):
            continue
        for e in v:
            if not isinstance(e, list):
                continue
            kv = {k: x for k, x in e if k is not None}
            keys = list(kv)
            if len(keys) < 3:
                continue
            # keys by checksum when named, else by position (offset, size, name, rate)
            off = kv.get(K_OFF, kv[keys[0]])
            size = kv.get(K_SIZE, kv[keys[1]])
            name = kv.get(K_NAME, kv[keys[2]]) & 0xFFFFFFFF
            out[name] = dict(offset=off, size=size, rate=kv.get(K_RATE, kv[keys[3]] if len(keys) > 3 else None),
                             flags=[x for k, x in e if k is None])
    return out


def stream_table(dat_path):
    """P8 streams (data/streams/pcm/pcm.dat + pcm.wad): u32 count, then 32-byte entries
    { u32 checksum, u32 offset in the .wad, u32 size, WAVEFORMATEX (0x69 Xbox ADPCM ...) }; the .wad holds the raw
    ADPCM data (no header). -> {checksum: (offset, size, channels, rate)}"""
    d = open(dat_path, 'rb').read()
    n = struct.unpack_from('<I', d, 0)[0]
    out = {}
    for i in range(n):
        o = 4 + 32 * i
        if o + 32 > len(d):
            break
        cs, off, size, fmt, ch, rate = struct.unpack_from('<IIIHHI', d, o)
        if fmt == 0x69 and ch in (1, 2):
            out[cs] = (off, size, ch, rate)
    return out


def stream_wav(wad_path, entry, max_seconds=None):
    off, size, ch, rate = entry
    if max_seconds:
        size = min(size, int(max_seconds * rate / 65) * 36 * ch)
    with open(wad_path, 'rb') as f:
        f.seek(off)
        data = f.read(size)
    return thug_snd(decode_xbox_adpcm(data, ch), rate, ch)


def convert(bank_path, zone_pak, out_dir):
    b = open(bank_path, 'rb').read()
    os.makedirs(out_dir, exist_ok=True)
    n = 0
    for name, e in sound_table(zone_pak).items():
        o = e['offset']
        fmt, ch, rate = struct.unpack_from('<HHI', b, o)
        if fmt != 0x69 or ch not in (1, 2):
            continue
        pcm = decode_xbox_adpcm(b[o + 0x80:o + 0x80 + e['size']], ch)
        open(os.path.join(out_dir, '%08x.wav' % name), 'wb').write(wav(pcm, rate, ch))
        n += 1
    return n


if __name__ == '__main__':
    print('converted', convert(sys.argv[1], sys.argv[2], sys.argv[3]))
