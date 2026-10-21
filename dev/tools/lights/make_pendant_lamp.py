"""Makes assets/textures/pendant_lamp_48.png, the bar's pendant lamp, wide enough for its
light: the shade's rim is as wide as the light cone where it starts (46 px).

Redrawn from pendant_lamp_24.png's palette and banding: cord, cap, a highlight band, a mid
band, a dark band and the rim, then the bulb and three fading glow rows under it. Same
32 px height and centre, so the sprite drops into place at scale 1.

    python dev/tools/lights/make_pendant_lamp.py
"""

import os

from PIL import Image

WIDTH, HEIGHT = 48, 32
# The cord hangs one pixel left of centre, as in the 24 px lamp.
CORD_X = WIDTH // 2 - 1
CORD = "#28221c"
RIM = "#3c200c"
HIGHLIGHT = "#d48a48"
MID = "#a86028"
DARK = "#6e3e18"
BULB_LIGHT = "#ffd678"
BULB_HOT = "#fffad6"
GLOW = ["#ffcd6e", "#ffbe5a", "#ffaa46"]
GLOW_ALPHA = [70, 45, 20]

# Shade rows from the cap down: (width, colour). Even widths centre on CORD_X + 1.
SHADE = [
    (6, RIM),
    (10, HIGHLIGHT), (14, HIGHLIGHT),
    (20, MID), (24, MID), (28, MID),
    (32, DARK), (38, DARK), (42, DARK),
    (46, RIM),
]
CORD_ROWS = 6
# Under the rim: socket, bulb rows, then the glow rows fading out and widening.
BULB = [(6, RIM), (8, BULB_LIGHT), (6, BULB_HOT), (8, BULB_LIGHT)]
GLOW_WIDTHS = [30, 38, 46]
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "..", "assets", "textures", "pendant_lamp_48.png")


def rgba(colour: str, alpha: int = 255) -> tuple:
    return (int(colour[1:3], 16), int(colour[3:5], 16), int(colour[5:7], 16), alpha)


def row(image: Image.Image, y: int, width: int, colour: tuple) -> None:
    left = CORD_X + 1 - width // 2
    for x in range(left, left + width):
        image.putpixel((x, y), colour)


def main() -> None:
    image = Image.new("RGBA", (WIDTH, HEIGHT))
    for y in range(CORD_ROWS):
        image.putpixel((CORD_X, y), rgba(CORD))
    y = CORD_ROWS
    for width, colour in SHADE + BULB:
        row(image, y, width, rgba(colour))
        y += 1
    for width, colour, alpha in zip(GLOW_WIDTHS, GLOW, GLOW_ALPHA):
        row(image, y, width, rgba(colour, alpha))
        y += 1
    image.save(OUT)
    print("wrote", os.path.normpath(OUT), "rows used:", y)


if __name__ == "__main__":
    main()
