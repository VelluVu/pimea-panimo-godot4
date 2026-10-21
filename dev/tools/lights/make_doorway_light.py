"""Makes assets/textures/light_warehouse_door.png, the warehouse's light seen from the bar.

A bare bulb inside the storeroom: it fills the doorway (brightest at the top) and spills
through the door onto the bar floor, widening toward the viewer. Built in world space from
the doorway's corners (main.tscn's WarehouseGlow polygon), one texel per 2x2 game pixels,
so the light sits at LIGHT_CENTRE with texture_scale 2. White with the strength in alpha;
the falloff steps through LEVELS with a 4x4 Bayer dither, like the tube light.

    python dev/tools/lights/make_doorway_light.py
"""

import math
import os

from PIL import Image, ImageDraw, ImageFilter

TEXEL = 2
# The world rect the light covers.
LEFT, TOP, RIGHT, BOTTOM = 500, 90, 640, 360
LIGHT_CENTRE = ((LEFT + RIGHT) / 2, (TOP + BOTTOM) / 2)
# The doorway on the right wall, as the WarehouseGlow polygon has it.
DOOR = [(565, 116), (610, 96), (610, 322), (565, 283)]
# The patch the light throws through the door onto the bar floor.
SPILL = [(565, 283), (610, 322), (596, 360), (522, 314)]
DOOR_TOP_STRENGTH = 1.0
DOOR_BOTTOM_STRENGTH = 0.55
SPILL_STRENGTH = 0.6
SOFTNESS = 1.6
LEVELS = 6
BAYER_4X4 = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "..", "assets", "textures", "light_warehouse_door.png")


def to_texel(point):
    return ((point[0] - LEFT) / TEXEL, (point[1] - TOP) / TEXEL)


def threshold_distance(x: float, y: float) -> float:
    """World distance from the door's bottom edge (the threshold)."""
    (ax, ay), (bx, by) = SPILL[0], SPILL[1]
    dx, dy = bx - ax, by - ay
    return abs(dy * (x - ax) - dx * (y - ay)) / math.hypot(dx, dy)


def main() -> None:
    width, height = (RIGHT - LEFT) // TEXEL, (BOTTOM - TOP) // TEXEL
    door_mask = Image.new("L", (width, height))
    ImageDraw.Draw(door_mask).polygon([to_texel(p) for p in DOOR], fill=255)
    spill_mask = Image.new("L", (width, height))
    ImageDraw.Draw(spill_mask).polygon([to_texel(p) for p in SPILL], fill=255)

    door_top = min(p[1] for p in DOOR)
    door_bottom = max(p[1] for p in DOOR)
    spill_reach = max(threshold_distance(*p) for p in SPILL)
    strength = Image.new("L", (width, height))
    for ty in range(height):
        for tx in range(width):
            x, y = LEFT + (tx + 0.5) * TEXEL, TOP + (ty + 0.5) * TEXEL
            value = 0.0
            if door_mask.getpixel((tx, ty)):
                down = (y - door_top) / (door_bottom - door_top)
                value = DOOR_TOP_STRENGTH + (DOOR_BOTTOM_STRENGTH - DOOR_TOP_STRENGTH) * down
            elif spill_mask.getpixel((tx, ty)):
                value = SPILL_STRENGTH * (1.0 - threshold_distance(x, y) / spill_reach)
            strength.putpixel((tx, ty), round(max(0.0, value) * 255))
    strength = strength.filter(ImageFilter.GaussianBlur(SOFTNESS))

    image = Image.new("RGBA", (width, height))
    for ty in range(height):
        for tx in range(width):
            value = strength.getpixel((tx, ty)) / 255.0
            limit = (BAYER_4X4[(ty % 4) * 4 + (tx % 4)] + 0.5) / 16.0
            stepped = min(1.0, math.floor(value * LEVELS + limit) / LEVELS)
            image.putpixel((tx, ty), (255, 255, 255, round(stepped * 255)))
    image.save(OUT)
    print("wrote", os.path.normpath(OUT), image.size, "light at", LIGHT_CENTRE)


if __name__ == "__main__":
    main()
