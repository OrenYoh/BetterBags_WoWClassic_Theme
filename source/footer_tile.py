"""Make the bag's money bar with a middle that repeats seamlessly, GROWTH pixels taller than the art.

The ends are the classic backpack art's own (art x 74-96 and 200-251, y 227-250). The middle is
MIDDLE pixels wide, built from full-height slices of the art's even middle (x 96-200), each
blended into its neighbours over OVERLAP pixels and wrapping around. The bar is made taller by
adding GROWTH rows taken in random order from its straight rows (art y 233-240), so neither
direction shows a repeat. Written into a 512x64 file: the bar in its top left 329 x (23 + GROWTH).
"""
import math, os, random, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from blp2png import decode, png

os.makedirs(os.path.join(HERE, 'preview'), exist_ok=True)

MIDDLE = 256
PW, SX = 40, 32
OVERLAP = PW - SX
Y0, Y1 = 227, 250
BAND = (233, 240)
GROWTH = 10
LEFT_CAP = (74, 96)
RIGHT_CAP = (200, 251)
SRC = (96, 200)
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
            for c in range(4):
                acc[j][tx][c] += w * p[c]

# The bar at the art's height: caps and the seamless middle.
bar = []
for j in range(rows):
    row = [art[Y0 + j][sx] for sx in range(*LEFT_CAP)]
    row += [tuple(round(v / wsum[i]) for v in acc[j][i]) for i in range(MIDDLE)]
    row += [art[Y0 + j][sx] for sx in range(*RIGHT_CAP)]
    bar.append(row)

# Taller: the straight band's rows, then GROWTH more of them in random order (never the same row
# twice in a row), inserted after the band.
b0, b1 = BAND[0] - Y0, BAND[1] - Y0
band = list(range(b0, b1))
order, last = [], None
for _ in range(GROWTH):
    choice = random.choice([r for r in band if r != last])
    order.append(choice)
    last = choice
tall = bar[:b1] + [bar[r] for r in order] + bar[b1:]

width = len(tall[0])
img = [[(0, 0, 0, 0)] * W for _ in range(H)]
for j, row in enumerate(tall):
    img[j][:width] = row
png(os.path.join(HERE, '..', 'images', 'footer.png'), W, H, img)
print('footer', width, 'x', len(tall), 'left margin', LEFT_CAP[1] - LEFT_CAP[0], 'right margin', RIGHT_CAP[1] - RIGHT_CAP[0])

# Preview: drawn 700 wide, its middle repeated as the game will.
L, R = LEFT_CAP[1] - LEFT_CAP[0], RIGHT_CAP[1] - RIGHT_CAP[0]
PV = 700
pv = []
for row in tall:
    out = []
    for px in range(PV):
        if px < L: sx = px
        elif px >= PV - R: sx = width - (PV - px)
        else: sx = L + (px - L) % MIDDLE
        c = row[sx]
        out.append(tuple((c[k] * c[3] + (60, 60, 90)[k] * (255 - c[3])) // 255 for k in range(3)) + (255,))
    pv.append(out)
png(os.path.join(HERE, 'preview', 'footer_preview.png'), PV, len(tall), pv)
