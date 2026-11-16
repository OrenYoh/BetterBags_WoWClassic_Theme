"""Hide the joins between the header, the money bar and the stone between them (images/header.png, images/footer.png).

The stone under the header's title bar is the classic art's own, the fill between is a seamless tile made from it
(stone_tile.py): the same colors, a different grain, so the line where they met showed (seen in game). The header's stone
now fades out over its last FADE rows (from the end of the ring and the plate to the right border), and the themes draw
the fill up under it (theme.lua, next.lua: FILL_UNDER_HEADER), so the two grains blend instead of meeting. The money bar's
first two rows were the bottom of the art's last row of item slots, a dark strip with gray notches over the stone; they
are now a plain shadow above its gold line.

Run after header_tile.py and footer_tile.py (it sets the alpha and the rows outright, so running it again changes
nothing), then next_pieces.py to cut the pieces again.
"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from blp2png import decode, png
from next_pieces import read_png

ROOT = os.path.dirname(HERE)
IMAGES = os.path.join(ROOT, 'images')

# The header: 332 x 44 in a 512 x 64 file. Its stone fades from row FROM (fully drawn) to row 44 (nothing): the rows
# under the title bar's shadow. The ring (columns 0-47, its cap) is left whole; so are the last 7 columns, the right
# border as the classic theme draws it (art x 244-251; Next's is its last 4).
HEADER_W, HEADER_H = 332, 44
FADE = 14
FROM = HEADER_H - FADE
FADE_LEFT, FADE_RIGHT = 47, HEADER_W - 7

# The ring's cap (columns 0-47, art x 67-114) kept the art's stone beside and under the ring: darker (the ring's shadow)
# and unfaded, so it showed as a darker corner with a hard edge against the faded title bar (seen in game). From row
# CAP_FROM, the cap's stone outside the ring's rim (centre CAP_CENTRE, radius CAP_RIM) becomes the title bar's own:
# the middle wraps seamlessly, so its last columns (header x 256-302) run on into its first (x 47) and fade as it does.
# Over CAP_RAMP pixels past the rim the two are blended, and the left border and its notch (columns before CAP_X0) are
# kept. Taken from the art each time, so running this again changes nothing.
CAP_FROM, CAP_X0 = 28, 15
CAP_CENTRE, CAP_RIM, CAP_RAMP = (21, 19), 23.5, 2.5

# The money bar: 329 wide, its first two rows (art y 227, 228) between the borders (art x 74-77, 248-251: 3 and 4
# columns) a shadow of the stone: the stone's mean darkened, then darker toward the gold line.
FOOTER_W = 329
STONE = (56, 45, 34)
SHADOW = [tuple(int(c * 0.55) for c in STONE), tuple(int(c * 0.27) for c in STONE)]
SHADOW_LEFT, SHADOW_RIGHT = 3, FOOTER_W - 4

header = read_png(os.path.join(IMAGES, 'header.png'))
for y in range(FROM, HEADER_H):
    alpha = int(round(255 * (HEADER_H - y - 0.5) / FADE))
    for x in range(FADE_LEFT, FADE_RIGHT):
        r, g, b, _ = header[y][x]
        header[y][x] = (r, g, b, alpha)
_, _, art = decode(open(os.path.join(HERE, 'UI-BackpackBackground.blp'), 'rb').read())
for y in range(CAP_FROM, HEADER_H):
    for x in range(CAP_X0, FADE_LEFT):
        cap, middle = art[y + 2][x + 67], header[y][x + 256]
        d = ((x - CAP_CENTRE[0]) ** 2 + (y - CAP_CENTRE[1]) ** 2) ** 0.5
        t = min(max((d - CAP_RIM) / CAP_RAMP, 0), 1)
        header[y][x] = tuple(int(round(c + (m - c) * t)) for c, m in zip(cap, middle))
png(os.path.join(IMAGES, 'header.png'), len(header[0]), len(header), header)

footer = read_png(os.path.join(IMAGES, 'footer.png'))
for y, color in enumerate(SHADOW):
    for x in range(SHADOW_LEFT, SHADOW_RIGHT):
        footer[y][x] = color + (255,)
png(os.path.join(IMAGES, 'footer.png'), len(footer[0]), len(footer), footer)
