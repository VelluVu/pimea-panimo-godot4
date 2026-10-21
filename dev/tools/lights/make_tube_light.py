"""Makes assets/textures/light_tube.png, the brewery's fluorescent tube light.

White with the strength in alpha (the PointLight2D's colour tints it). Brightest along the
tube near the top, spreading down and wide over the tank rows, barely upward. Designed on an
80 x 80 grid and drawn at DRAWN_SCALE, one texel per game pixel, dithered by world pixel
(see pixel_dither.py); the light sits at (191, 171) in the world, which is (191, 172)
under the Lights node, with scale 1 and texture_scale 1.

    python dev/tools/lights/make_tube_light.py
"""

import math
import os

from PIL import Image

from pixel_dither import stepped

SIZE = 80
DRAWN_SCALE = 2
# The drawn texture's top-left corner in the world: light position minus half its size.
WORLD_ORIGIN = (191 - SIZE * DRAWN_SCALE // 2, 171 - SIZE * DRAWN_SCALE // 2)
TUBE_Y = 6.0
TUBE_HALF_LENGTH = 9.0
# How far the light reaches down and to the sides before it is faint.
REACH_DOWN = 66.0
REACH_SIDE = 34.0
# Light that goes up past the tube is cut this much: the ceiling takes it.
UPWARD_SCALE = 0.25
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "..", "assets", "textures", "light_tube.png")


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
    edge = min(x, SIZE - x, y, SIZE - y) / 6.0
    return value * min(1.0, edge)


def main() -> None:
    drawn = SIZE * DRAWN_SCALE
    image = Image.new("RGBA", (drawn, drawn))
    for py in range(drawn):
        for px in range(drawn):
            value = strength((px + 0.5) / DRAWN_SCALE, (py + 0.5) / DRAWN_SCALE)
            alpha = stepped(value, WORLD_ORIGIN[0] + px, WORLD_ORIGIN[1] + py)
            image.putpixel((px, py), (255, 255, 255, round(alpha * 255)))
    image.save(OUT)
    print("wrote", os.path.normpath(OUT), image.size)


if __name__ == "__main__":
    main()
