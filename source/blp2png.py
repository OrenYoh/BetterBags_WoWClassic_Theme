"""Decode a BLP2 (DXT1/3/5 or uncompressed palette) mip 0 into an RGBA PNG. Stdlib only."""
import struct, sys, zlib


def c565(v):
    r = (v >> 11) & 31; g = (v >> 5) & 63; b = v & 31
    return (r * 255 // 31, g * 255 // 63, b * 255 // 31)


def colors(c0, c1, dxt1):
    a, b = c565(c0), c565(c1)
    if c0 > c1 or not dxt1:
        return [a + (255,), b + (255,),
                tuple((2 * x + y) // 3 for x, y in zip(a, b)) + (255,),
                tuple((x + 2 * y) // 3 for x, y in zip(a, b)) + (255,)]
    return [a + (255,), b + (255,), tuple((x + y) // 2 for x, y in zip(a, b)) + (255,), (0, 0, 0, 0)]


def decode(data):
    assert data[:4] == b"BLP2"
    _, comp, adepth, atype, _, w, h = struct.unpack_from("<IBBBBII", data, 4)
    off = struct.unpack_from("<16I", data, 20)[0]
    size = struct.unpack_from("<16I", data, 84)[0]
    px = [[(0, 0, 0, 0)] * w for _ in range(h)]
    src = data[off:off + size]
    if comp == 1:
        pal = [struct.unpack_from("<BBBB", data, 148 + i * 4) for i in range(256)]
        n = w * h
        for i in range(n):
            b, g, r, _ = pal[src[i]]
            a = 255
            if adepth == 8:
                a = src[n + i]
            elif adepth == 1:
                a = 255 if (src[n + i // 8] >> (i % 8)) & 1 else 0
            px[i // w][i % w] = (r, g, b, a)
        return w, h, px
    assert comp == 2
    kind = 1 if adepth <= 1 else (3 if atype == 1 else 5)
    bsize = 8 if kind == 1 else 16
    p = 0
    for by in range(0, h, 4):
        for bx in range(0, w, 4):
            blk = src[p:p + bsize]; p += bsize
            alphas = None
            if kind == 3:
                bits = int.from_bytes(blk[:8], "little")
                alphas = [((bits >> (4 * i)) & 15) * 17 for i in range(16)]
            elif kind == 5:
                a0, a1 = blk[0], blk[1]
                bits = int.from_bytes(blk[2:8], "little")
                tab = [a0, a1]
                if a0 > a1:
                    tab += [((6 - i) * a0 + (i + 1) * a1) // 7 for i in range(6)]
                else:
                    tab += [((4 - i) * a0 + (i + 1) * a1) // 5 for i in range(4)] + [0, 255]
                alphas = [tab[(bits >> (3 * i)) & 7] for i in range(16)]
            cb = blk[-8:]
            c0, c1, idx = struct.unpack("<HHI", cb)
            cols = colors(c0, c1, kind == 1)
            for i in range(16):
                c = cols[(idx >> (2 * i)) & 3]
                if alphas is not None:
                    c = c[:3] + (alphas[i],)
                y, x = by + i // 4, bx + i % 4
                if y < h and x < w:
                    px[y][x] = c
    return w, h, px


def png(path, w, h, px):
    raw = b"".join(b"\0" + bytes(v for p in row for v in p) for row in px)
    def chunk(t, d):
        return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d))
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
                + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


if __name__ == "__main__":
    w, h, px = decode(open(sys.argv[1], "rb").read())
    png(sys.argv[2], w, h, px)
    print(sys.argv[1], w, h)
