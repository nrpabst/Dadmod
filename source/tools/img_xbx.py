r"""THUG Pro .img.xbx textures (the level select thumbnails and other loose 2D images): read and write.

    python -I tools/img_xbx.py png <in.img.xbx> <out.png>        decode to PNG
    python -I tools/img_xbx.py img <in.png> <out.img.xbx>        encode (crop to square, 512x512, 256 colours)
    python -I tools/img_xbx.py check <stock.img.xbx>             decode + re-encode the same palette/indexes, must be
                                                                byte-identical (tests the header and the swizzle)

Layout (as in data\pre\thugpro_levelselect.prx): a 32-byte header of u32 version 2, u32 bits per pixel 8, u32 width,
u32 height, u32 format 0x13, u32 0, u16 width, u16 height, u32 palette size 0x400; then a 256-entry BGRA palette;
then one palette index per pixel in Xbox swizzled (Morton) order, bottom row first (PNGs here are upright).
"""
import struct, sys

SIZE = 512


def _swizzle_table(w, h):
    """linear index (y * w + x) -> swizzled index"""
    def morton(x, y):
        o = bit = 0
        mx = my = 1
        while mx < w or my < h:
            if mx < w:
                if x & mx:
                    o |= 1 << bit
                bit += 1
                mx <<= 1
            if my < h:
                if y & my:
                    o |= 1 << bit
                bit += 1
                my <<= 1
        return o
    return [morton(x, y) for y in range(h) for x in range(w)]


def read(data):
    """-> (width, height, palette [(r, g, b, a)] * 256, indexes in linear order)"""
    ver, bpp, w, h, fmt, _, w2, h2, psize = struct.unpack_from('<6I2HI', data, 0)
    if bpp != 8 or psize != 0x400:
        raise ValueError('not an 8-bit palettised .img.xbx (bpp %d, palette %d bytes)' % (bpp, psize))
    pal = [(data[32 + i * 4 + 2], data[32 + i * 4 + 1], data[32 + i * 4], data[32 + i * 4 + 3]) for i in range(256)]
    pix = data[32 + psize:32 + psize + w * h]
    sw = _swizzle_table(w, h)
    return w, h, pal, bytes(pix[sw[i]] for i in range(w * h))


def write(w, h, pal, indexes):
    """palette [(r, g, b, a)] * 256 and linear indexes -> .img.xbx bytes"""
    out = bytearray(struct.pack('<6I2HI', 2, 8, w, h, 0x13, 0, w, h, 0x400))
    for r, g, b, a in pal:
        out += bytes((b, g, r, a))
    pix = bytearray(w * h)
    sw = _swizzle_table(w, h)
    for i in range(w * h):
        pix[sw[i]] = indexes[i]
    return bytes(out + pix)


def to_png(data, path):
    from PIL import Image
    w, h, pal, idx = read(data)
    im = Image.new('RGBA', (w, h))
    im.putdata([pal[i] for i in idx])
    im.transpose(Image.FLIP_TOP_BOTTOM).save(path)       # stored bottom row first


def from_image(path):
    """any picture -> 512x512 .img.xbx: centre-cropped to a square, scaled, 256 colours, opaque"""
    from PIL import Image
    im = Image.open(path).convert('RGB')
    s = min(im.size)
    l, t = (im.width - s) // 2, (im.height - s) // 2
    im = im.crop((l, t, l + s, t + s)).resize((SIZE, SIZE), Image.LANCZOS).transpose(Image.FLIP_TOP_BOTTOM)
    q = im.quantize(256, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.FLOYDSTEINBERG)
    p = q.getpalette()[:768]
    p += [0] * (768 - len(p))
    pal = [(p[i * 3], p[i * 3 + 1], p[i * 3 + 2], 255) for i in range(256)]
    return write(SIZE, SIZE, pal, q.tobytes())


def main(argv):
    if len(argv) >= 3 and argv[0] == 'png':
        to_png(open(argv[1], 'rb').read(), argv[2])
    elif len(argv) >= 3 and argv[0] == 'img':
        open(argv[2], 'wb').write(from_image(argv[1]))
    elif len(argv) >= 2 and argv[0] == 'check':
        data = open(argv[1], 'rb').read()
        w, h, pal, idx = read(data)
        again = write(w, h, pal, idx)
        print('identical' if again == data else 'DIFFERENT (%d vs %d bytes)' % (len(again), len(data)))
        return 0 if again == data else 1
    else:
        print(__doc__)
        return 2
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
