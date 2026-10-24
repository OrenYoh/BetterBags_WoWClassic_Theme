"""Make a seamless stone tile from the classic backpack art's plain stone.

Patches cut at random from the stone (art x 112-240, y 34-62) are laid in staggered rows on a
torus, each feathered into its neighbours over OVERLAP pixels, so the tile wraps without a seam.
Each patch is shifted to the stone's mean first (the source darkens slightly toward its edges),
and the result is matched to the source's mean and contrast per channel.
"""
import math, os, random, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from blp2png import decode, png

os.makedirs(os.path.join(HERE, 'preview'), exist_ok=True)

SIZE = 256
PW, PH = 40, 24          # patch size
SX, SY = 32, 16          # steps: overlap 8 both ways, 256 is a whole number of steps
OVERLAP_X, OVERLAP_Y = PW - SX, PH - SY
SRC = (112, 240, 34, 62)

random.seed(int(sys.argv[1]) if len(sys.argv) > 1 else 7)
_, _, art = decode(open(os.path.join(HERE, 'UI-BackpackBackground.blp'), 'rb').read())
x0, x1, y0, y1 = SRC
src = [[art[y][x][:3] for x in range(x0, x1)] for y in range(y0, y1)]
sw, sh = x1 - x0, y1 - y0

def stats(pixels):
    n = len(pixels)
    mean = [sum(p[c] for p in pixels) / n for c in range(3)]
    std = [math.sqrt(sum((p[c] - mean[c]) ** 2 for p in pixels) / n) for c in range(3)]
    return mean, std

all_src = [p for row in src for p in row]
src_mean, src_std = stats(all_src)

def ramp(i, size, overlap):
    # sin^2 ramps: two neighbours' ramps over the same pixels sum to 1
    if i < overlap:
        return math.sin((i + 0.5) / overlap * math.pi / 2) ** 2
    if i >= size - overlap:
        return math.sin((size - i - 0.5) / overlap * math.pi / 2) ** 2
    return 1.0

acc = [[[0.0, 0.0, 0.0] for _ in range(SIZE)] for _ in range(SIZE)]
wsum = [[0.0] * SIZE for _ in range(SIZE)]
for row in range(SIZE // SY):
    stagger = random.randrange(SX)          # rows start at different places: no grid
    for col in range(SIZE // SX):
        sx = random.randrange(sw - PW + 1)
        sy = random.randrange(sh - PH + 1)
        patch = [src[sy + j][sx:sx + PW] for j in range(PH)]
        pmean, _ = stats([p for r in patch for p in r])
        shift = [src_mean[c] - pmean[c] for c in range(3)]
        ox, oy = col * SX + stagger, row * SY
        for j in range(PH):
            wy = ramp(j, PH, OVERLAP_Y)
            ty = (oy + j) % SIZE
            for i in range(PW):
                w = wy * ramp(i, PW, OVERLAP_X)
                tx = (ox + i) % SIZE
                p = patch[j][i]
                a = acc[ty][tx]
                for c in range(3):
                    a[c] += w * (p[c] + shift[c])
                wsum[ty][tx] += w

out = [[[a[c] / wsum[y][x] for c in range(3)] for x, a in enumerate(r)] for y, r in enumerate(acc)]
flat = [p for r in out for p in r]
m, s = stats(flat)
rows = []
for r in out:
    rows.append([tuple(max(0, min(255, round(src_mean[c] + (p[c] - m[c]) * src_std[c] / s[c]))) for c in range(3)) + (255,)
                 for p in r])
png(os.path.join(HERE, '..', 'images', 'stone.png'), SIZE, SIZE, rows)
# a 3x2 repeat to look for seams
rep = [[rows[y % SIZE][x % SIZE] for x in range(SIZE * 3)] for y in range(SIZE * 2)]
png(os.path.join(HERE, 'preview', 'stone_tile_repeat.png'), SIZE * 3, SIZE * 2, rep)
print('source mean', [round(v, 1) for v in src_mean], 'std', [round(v, 1) for v in src_std])
