"""Makes the light a lit room throws through its doorway, seen from the bar.

Two profiles:
  warehouse -> assets/textures/light_warehouse_door.png: a bare bulb inside the storeroom
               fills the doorway (brightest at the top) and spills onto the bar floor.
  brewery   -> assets/textures/light_brewery_spill.png: the tube light already lights the
               brewery itself; this is only its bleed through the arch onto the bar floor.

Built in world space from the doorways' corners in main.tscn, one texel per game pixel
(see pixel_dither.py), so each light sits at its profile's centre with scale 1 and
texture_scale 1. White with the strength in alpha.

    python dev/tools/lights/make_doorway_light.py [warehouse|brewery]
"""

import math
import os
import sys

from PIL import Image, ImageDraw, ImageFilter

from pixel_dither import stepped

TEXEL = 1
TEXTURES = os.path.join(os.path.dirname(__file__), "..", "..", "..", "assets", "textures")

PROFILES = {
    "warehouse": {
        "out": "light_warehouse_door.png",
        # left, top, right, bottom of the world rect the light covers
        "rect": (500, 90, 640, 360),
        # The doorway on the right wall, as the WarehouseGlow polygon has it.
        "door": [(565, 116), (610, 96), (610, 322), (565, 283)],
        "door_strength": (1.0, 0.55),
        # The patch thrown onto the bar floor; its first two points are the threshold.
        "spill": [(565, 283), (610, 322), (596, 360), (522, 314)],
        "spill_strength": 0.6,
        "softness": 3.2,
    },
    "brewery": {
        "out": "light_brewery_spill.png",
        "rect": (80, 200, 300, 330),
        "door": None,
        # The arch's threshold at y 251 (opening x 124..260), widening toward the viewer.
        "spill": [(124, 251), (260, 251), (290, 318), (94, 318)],
        "spill_strength": 0.55,
        # Softer, so a little light also creeps up the arch's jambs.
        "softness": 5.2,
    },
}


def threshold_distance(spill, x: float, y: float) -> float:
    """World distance from the spill's first edge, the doorway's threshold."""
    (ax, ay), (bx, by) = spill[0], spill[1]
    dx, dy = bx - ax, by - ay
    return abs(dy * (x - ax) - dx * (y - ay)) / math.hypot(dx, dy)


def make(profile: dict) -> None:
    left, top, right, bottom = profile["rect"]
    width, height = (right - left) // TEXEL, (bottom - top) // TEXEL
    to_texel = lambda p: ((p[0] - left) / TEXEL, (p[1] - top) / TEXEL)

    door_mask = Image.new("L", (width, height))
    if profile["door"]:
        ImageDraw.Draw(door_mask).polygon([to_texel(p) for p in profile["door"]], fill=255)
    spill = profile["spill"]
    spill_mask = Image.new("L", (width, height))
    ImageDraw.Draw(spill_mask).polygon([to_texel(p) for p in spill], fill=255)
    spill_reach = max(threshold_distance(spill, *p) for p in spill)

    strength = Image.new("L", (width, height))
    for ty in range(height):
        for tx in range(width):
            x, y = left + (tx + 0.5) * TEXEL, top + (ty + 0.5) * TEXEL
            value = 0.0
            if door_mask.getpixel((tx, ty)):
                door = profile["door"]
                door_top, door_bottom = min(p[1] for p in door), max(p[1] for p in door)
                high, low = profile["door_strength"]
                value = high + (low - high) * (y - door_top) / (door_bottom - door_top)
            elif spill_mask.getpixel((tx, ty)):
                value = profile["spill_strength"] * (1.0 - threshold_distance(spill, x, y) / spill_reach)
            strength.putpixel((tx, ty), round(max(0.0, value) * 255))
    strength = strength.filter(ImageFilter.GaussianBlur(profile["softness"]))

    image = Image.new("RGBA", (width, height))
    for ty in range(height):
        for tx in range(width):
            alpha = stepped(strength.getpixel((tx, ty)) / 255.0, left + tx, top + ty)
            image.putpixel((tx, ty), (255, 255, 255, round(alpha * 255)))
    out = os.path.normpath(os.path.join(TEXTURES, profile["out"]))
    image.save(out)
    print("wrote", out, image.size, "light at", ((left + right) / 2, (top + bottom) / 2))


def main() -> None:
    names = sys.argv[1:] or list(PROFILES)
    for name in names:
        make(PROFILES[name])


if __name__ == "__main__":
    main()
