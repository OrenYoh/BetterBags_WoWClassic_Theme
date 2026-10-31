"""Cut the bag's art into the pieces BetterBags Next's theme draws (next.lua).

BetterBags Next has no nine-slice for a panel's ornaments: a piece is either drawn once at a corner or repeated along a
side, the whole file every Tile. So the header (images/header.png) and the money bar (images/footer.png) are cut into
their two ends and their seamless middle, each its own file, and the side borders come from the classic backpack art.
Every file is a power of two, the piece in its top left, the rest transparent; next.lua crops each with TexCoords.

  header_left    images/header.png x 0-47,    y 0-44  (the portrait in its gold ring)
  header_middle  images/header.png x 47-303,  y 0-44  (the title bar, 256 wide, repeats seamlessly)
  header_right   images/header.png x 303-332, y 0-44  (the close button's plate)
  footer_left    images/footer.png x 0-22,    y 0-33  (the money bar's gold cap)
  footer_middle  images/footer.png x 22-278,  y 0-33  (the money bar, 256 wide, repeats seamlessly)
  footer_right   images/footer.png x 278-329, y 0-33  (the cap and the shadow it darkens into)
  edge_left      the art's left border,  x 74-77,  y 52-63, 16 rows (its rows repeat every 4)
  edge_right     the art's right border, x 248-251, y 52-63, the same (the header's and money bar's last 3 columns)

The classic theme's right border is 7 wide, art x 244-251, a shadow then the border; Next's is the border alone. So
header_right, under the close button's plate, has its shadow (header x 321-329) replaced by the stone beside it
(SHADOW_FROM), faded as that stone is (seams.py): no shadow above a border that has none.
"""
import os, struct, sys, zlib
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from blp2png import decode, png

ROOT = os.path.dirname(HERE)
OUT = os.path.join(ROOT, 'images', 'next')
os.makedirs(OUT, exist_ok=True)


def read_png(path):
    """Read an 8-bit RGBA, non-interlaced PNG into rows of (r, g, b, a)."""
    data = open(path, 'rb').read()
    pos, idat = 8, b''
    while pos < len(data):
        n = struct.unpack('>I', data[pos:pos + 4])[0]
        kind, body = data[pos + 4:pos + 8], data[pos + 8:pos + 8 + n]
        pos += 12 + n
        if kind == b'IHDR':
            w, h, depth, ctype, _, _, interlace = struct.unpack('>IIBBBBB', body)
            assert depth == 8 and ctype == 6 and interlace == 0, path
        elif kind == b'IDAT':
            idat += body
    raw, stride, rows, prev, p = zlib.decompress(idat), w * 4, [], bytearray(w * 4), 0
    for _ in range(h):
        f, line = raw[p], bytearray(raw[p + 1:p + 1 + stride])
        p += 1 + stride
        for x in range(stride):
            a = line[x - 4] if x >= 4 else 0
            b, c = prev[x], prev[x - 4] if x >= 4 else 0
            if f == 1: line[x] = (line[x] + a) & 255
            elif f == 2: line[x] = (line[x] + b) & 255
            elif f == 3: line[x] = (line[x] + (a + b) // 2) & 255
            elif f == 4:
                q = a + b - c
                pa, pb, pc = abs(q - a), abs(q - b), abs(q - c)
                line[x] = (line[x] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        rows.append([tuple(line[i:i + 4]) for i in range(0, stride, 4)])
        prev = line
    return rows


def write(name, w, h, piece):
    """Write piece (rows of pixels) into the top left of a w x h transparent file."""
    px = [[(0, 0, 0, 0)] * w for _ in range(h)]
    for y, row in enumerate(piece):
        for x, c in enumerate(row):
            px[y][x] = c
    png(os.path.join(OUT, name + '.png'), w, h, px)


# Under the plate (from header row PLATE_BOTTOM), the shadow left of the right border, replaced by the stone SHADOW_SHIFT
# columns to its left.
PLATE_BOTTOM = 26
SHADOW_FROM, SHADOW_SHIFT = 321, 21


def cut(rows, x0, x1, y0, y1):
    return [row[x0:x1] for row in rows[y0:y1]]


if __name__ == "__main__":
    header = read_png(os.path.join(ROOT, 'images', 'header.png'))
    footer = read_png(os.path.join(ROOT, 'images', 'footer.png'))
    _, _, art = decode(open(os.path.join(HERE, 'UI-BackpackBackground.blp'), 'rb').read())

    write('header_left', 64, 64, cut(header, 0, 47, 0, 44))
    write('header_middle', 256, 64, cut(header, 47, 303, 0, 44))
    right = cut(header, 303, 332, 0, 44)
    for y in range(PLATE_BOTTOM, 44):
        for x in range(SHADOW_FROM - 303, 329 - 303):
            right[y][x] = header[y][x + 303 - SHADOW_SHIFT]
    write('header_right', 32, 64, right)
    write('footer_left', 32, 64, cut(footer, 0, 22, 0, 33))
    write('footer_middle', 256, 64, cut(footer, 22, 278, 0, 33))
    write('footer_right', 64, 64, cut(footer, 278, 329, 0, 33))

    # The borders: rows 52-63 of the art are the same every 4 rows, so 16 rows repeat without a seam.
    rows = list(range(52, 64)) + list(range(52, 56))
    write('edge_left', 8, 16, [list(art[y][74:77]) for y in rows])
    write('edge_right', 8, 16, [list(art[y][248:251]) for y in rows])
