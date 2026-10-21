"""Makes assets/textures/light_tube_80.png, the brewery's fluorescent tube light.

White with the strength in alpha (the PointLight2D's colour tints it). Brightest along the
tube near the top, spreading down and wide over the tank rows, barely upward. The falloff
steps through LEVELS with a 4x4 Bayer dither, so drawn at texture_scale 2 every texel is a
2x2 game-pixel block like the dithered screen effects.

    python dev/tools/lights/make_tube_light.py
"""

import math
import os

from PIL import Image

SIZE = 80
TUBE_Y = 6.0
TUBE_HALF_LENGTH = 9.0
# How far the light reaches down and to the sides before it is faint.
REACH_DOWN = 66.0
REACH_SIDE = 34.0
# Light that goes up past the tube is cut this much: the ceiling takes it.
UPWARD_SCALE = 0.25
LEVELS = 6
BAYER_4X4 = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "..", "assets", "textures", "light_tube_80.png")


def strength(x: float, y: float) -> float:
    centre = SIZE / 2.0
    # Distance to the tube segment, stretched so the light spreads more down than sideways.
    along = max(0.0, abs(x - centre) - TUBE_HALF_LENGTH)
    down = y - TUBE_Y
    if down < 0.0:
        down = -down / UPWARD_SCALE
    reach = math.hypot(along / REACH_SIDE, down / REACH_DOWN)
    value = max(0.0, 1.0 - reach) ** 1.6
    # Fades at the texture's edges, so the light never ends in a hard line.
    edge = min(x, SIZE - 1 - x, y, SIZE - 1 - y) / 6.0
    return value * min(1.0, edge)


def dithered(value: float, x: int, y: int) -> float:
    threshold = (BAYER_4X4[(y % 4) * 4 + (x % 4)] + 0.5) / 16.0
    return min(1.0, math.floor(value * LEVELS + threshold) / LEVELS)


def main() -> None:
    image = Image.new("RGBA", (SIZE, SIZE))
    for y in range(SIZE):
        for x in range(SIZE):
            alpha = dithered(strength(x + 0.5, y + 0.5), x, y)
            image.putpixel((x, y), (255, 255, 255, round(alpha * 255)))
    image.save(OUT)
    print("wrote", os.path.normpath(OUT))


if __name__ == "__main__":
    main()
