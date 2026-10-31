"""Draw the group tabs BetterBags Next's theme puts down the bag's inner side (next.lua), in the classic look.

The classic character sheet's tabs hang below its window: a dark body in a light, bevelled border with rounded corners,
open where it joins the window. BetterBags Next's tabs stick out sideways from the bag, so these are drawn turned: rounded
on their outer (left) side, open on their right, where they meet the bag (Next mirrors them on the other panels). The
body is the theme's own stone (images/stone.png), the border the classic backpack art's bevel colors. Next stretches a
tab's art over the tab, so every tab is one size (next.lua: 100 x 30) and the art is drawn at twice that, W x H, in the
top left of a 256 x 64 file: drawn at half its size, never distorted.

  tab_inactive   a tab not chosen: the stone darkened
  tab_active     the chosen tab: the stone as the bag shows it, its border lighter
  tab_highlight  the tab's body in white, faded toward its open side: added over a tab under the pointer
"""
import math, os, struct, sys, zlib
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from blp2png import png
from next_pieces import read_png

ROOT = os.path.dirname(HERE)
OUT = os.path.join(ROOT, 'images', 'next')
FW, FH = 256, 64
W, H = 200, 60
RADIUS = 14
SS = 4

stone = read_png(os.path.join(ROOT, 'images', 'stone.png'))

# The backpack art's bevel (art x 74-76, 248-251): its light and dark lines.
DARK = (16, 12, 8)
LIGHT = (139, 129, 115)
MID = (98, 90, 79)


def inside(x, y):
    """Whether a point is inside the tab: a rectangle W x H, its left corners rounded, its right side open."""
    if x < 0 or x >= W or y < 0 or y >= H:
        return False
    for cy in (RADIUS, H - RADIUS):
        if x < RADIUS and ((y < RADIUS and cy == RADIUS) or (y >= H - RADIUS and cy == H - RADIUS)):
            return (x - RADIUS) ** 2 + (y - cy) ** 2 <= RADIUS ** 2
    return True


def coverage(px, py):
    hit = 0
    for i in range(SS):
        for j in range(SS):
            if inside(px + (i + 0.5) / SS, py + (j + 0.5) / SS):
                hit += 1
    return hit / (SS * SS)


def depth(x, y):
    """How far a pixel is from the tab's border (top, left, bottom; the right side is open), in pixels of the art."""
    d = min(y + 0.5, H - y - 0.5)
    if x < RADIUS:
        for cy in (RADIUS, H - RADIUS):
            if (y < RADIUS and cy == RADIUS) or (y >= H - RADIUS and cy == H - RADIUS):
                return RADIUS - math.hypot(x + 0.5 - RADIUS, y + 0.5 - cy)
        d = min(d, x + 0.5)
    return d


def border(d, light):
    """The bevel by depth (in pixels of the art, twice a pixel on screen): a dark line, the light bevel, a dark line."""
    if d < 2:
        return DARK
    if d < 6:
        return light
    if d < 8:
        return DARK
    return None


def stone_at(x, y, shade):
    # The art is drawn at half its size: its stone at twice the scale, so on screen it matches the bag's.
    c = stone[(y // 2) % len(stone)][(x // 2) % len(stone[0])]
    return tuple(min(255, int(c[k] * shade)) for k in range(3))


def draw(name, shade, light, highlight=False):
    px = [[(0, 0, 0, 0)] * FW for _ in range(FH)]
    for y in range(H):
        for x in range(W):
            a = coverage(x, y)
            if a <= 0:
                continue
            d = depth(x, y)
            if highlight:
                fade = max(0.0, 1.0 - x / W) ** 0.7
                c, alpha = (255, 255, 255), a * fade if d >= 8 else 0
            else:
                c = border(d, light) or stone_at(x, y, shade)
                alpha = a
            px[y][x] = c + (int(round(alpha * 255)),)
    png(os.path.join(OUT, name + '.png'), FW, FH, px)


draw('tab_inactive', 0.55, MID)
draw('tab_active', 1.0, LIGHT)
draw('tab_highlight', 1.0, LIGHT, highlight=True)
