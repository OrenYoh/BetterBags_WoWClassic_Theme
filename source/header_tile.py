"""Make the bag header (portrait, title bar, close plate) with a middle that repeats seamlessly.

The ends are the classic backpack art's own (art x 67-114 and 222-251, y 2-46). The middle is
MIDDLE pixels wide, built from full-height slices of the art's middle (x 114-222), each blended
into its neighbours over OVERLAP pixels and wrapping around, so it repeats without a seam. Slices
keep their rows, so the title bar's lines stay where they are. Written into a 512x64 file:
the header in its top left 332x44.
"""
import math, os, random, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from blp2png import decode, png

os.makedirs(os.path.join(HERE, 'preview'), exist_ok=True)

MIDDLE = 256
PW, SX = 40, 32                       # slice width and step: overlap 8, 256 is a whole number of steps
OVERLAP = PW - SX
Y0, Y1 = 2, 46
LEFT_CAP = (67, 114)
RIGHT_CAP = (222, 251)
SRC = (114, 222)
W, H = 512, 64

random.seed(int(sys.argv[1]) if len(sys.argv) > 1 else 7)
_, _, art = decode(open(os.path.join(HERE, 'UI-BackpackBackground.blp'), 'rb').read())
rows = Y1 - Y0

def ramp(i):
    if i < OVERLAP:
        return math.sin((i + 0.5) / OVERLAP * math.pi / 2) ** 2
    if i >= PW - OVERLAP:
        return math.sin((PW - i - 0.5) / OVERLAP * math.pi / 2) ** 2
    return 1.0

acc = [[[0.0] * 4 for _ in range(MIDDLE)] for _ in range(rows)]
wsum = [0.0] * MIDDLE
for col in range(MIDDLE // SX):
    sx = SRC[0] + random.randrange(SRC[1] - SRC[0] - PW + 1)
    for i in range(PW):
        w = ramp(i)
        tx = (col * SX + i) % MIDDLE
        wsum[tx] += w
        for j in range(rows):
            p = art[Y0 + j][sx + i]
            a = acc[j][tx]
            for c in range(4):
                a[c] += w * p[c]

img = [[(0, 0, 0, 0)] * W for _ in range(H)]
x = 0
for j in range(rows):
    x = 0
    for sx in range(*LEFT_CAP):
        img[j][x] = art[Y0 + j][sx]; x += 1
    for i in range(MIDDLE):
        img[j][x] = tuple(round(v / wsum[i]) for v in acc[j][i]); x += 1
    for sx in range(*RIGHT_CAP):
        img[j][x] = art[Y0 + j][sx]; x += 1
png(os.path.join(HERE, '..', 'images', 'header.png'), W, H, img)
print('header', x, 'x', rows, 'left margin', LEFT_CAP[1] - LEFT_CAP[0], 'right margin', RIGHT_CAP[1] - RIGHT_CAP[0])

# Preview: the header drawn 700 wide, its middle repeated as the game will.
L, R = LEFT_CAP[1] - LEFT_CAP[0], RIGHT_CAP[1] - RIGHT_CAP[0]
PV = 700
pv = []
for j in range(rows):
    row = []
    for px in range(PV):
        if px < L: sx = px
        elif px >= PV - R: sx = x - (PV - px)
        else: sx = L + (px - L) % MIDDLE
        c = img[j][sx]
        bg = (60, 60, 90)
        row.append(tuple((c[k] * c[3] + bg[k] * (255 - c[3])) // 255 for k in range(3)) + (255,))
    pv.append(row)
png(os.path.join(HERE, 'preview', 'header_preview.png'), PV, rows, pv)
