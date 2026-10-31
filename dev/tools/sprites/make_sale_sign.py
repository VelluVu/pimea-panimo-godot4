"""Draws the cardboard sale sign for Black Week: a piece of box cardboard with a torn corner,
two torn notches and tape on top. The text is a Label over it in main.tscn, so it gets
translated.

Lit from above like the cellar lamp: the top lip catches the light, the bottom row is in
shade, and the outline is selective (lighter along the lit top, dark below). The face stays
flat so the hand-written text reads. The tears show the corrugated flutes inside.

    python dev/tools/sprites/make_sale_sign.py [--preview out.png]
"""

import argparse
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / "assets/textures/sale_sign_cardboard.png"
WIDTH, HEIGHT = 46, 20
# Row 0 is for the tape that overhangs the top edge.
TOP, BOTTOM = 1, HEIGHT - 1

# Six colours. The cardboard ramp shifts warm (yellow) in the light, cool (purple-brown)
# in the shade, like the rest of the cellar.
LIGHT = (222, 178, 112)
BASE = (186, 136, 84)
SHADE = (138, 92, 72)
EDGE = (78, 50, 52)
TAPE = (232, 226, 188)
TAPE_SHADE = (184, 176, 150)

# The torn top-right corner: per row from the top, how many pixels the tear eats in.
CORNER_TEAR = [4, 2, 2, 1]
# Torn bottom notches: (first x, depths per column). Deeper in the middle, like a rip.
NOTCHES = [(9, [1, 2, 2, 1]), (31, [1, 1, 1])]
# Tape pieces: (first x, width). Hang one pixel over the top edge.
TAPES = [(2, 5), (34, 5)]


def _right_edge(y: int) -> int:
    row = y - TOP
    return WIDTH - 1 - (CORNER_TEAR[row] if row < len(CORNER_TEAR) else 0)


def _bottom_edge(x: int) -> int:
    for first, depths in NOTCHES:
        if first <= x < first + len(depths):
            return BOTTOM - depths[x - first]
    return BOTTOM


def _is_tear(x: int, y: int) -> bool:
    """On a torn edge rather than a cut one."""
    if y - TOP < len(CORNER_TEAR) and x == _right_edge(y):
        return True
    return y == _bottom_edge(x) and _bottom_edge(x) != BOTTOM


def draw() -> Image.Image:
    image = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    px = image.load()
    middle = (TOP + BOTTOM) // 2
    for y in range(TOP, BOTTOM + 1):
        for x in range(0, _right_edge(y) + 1):
            bottom = _bottom_edge(x)
            if y > bottom:
                continue
            if _is_tear(x, y):
                # Exposed flutes: light and dark in turn along the rip.
                px[x, y] = LIGHT if (x + y) % 2 == 0 else EDGE
            elif y == bottom:
                px[x, y] = EDGE
            elif y == TOP:
                px[x, y] = SHADE
            elif x == 0 or x == _right_edge(y):
                px[x, y] = SHADE if y <= middle else EDGE
            elif y == TOP + 1:
                px[x, y] = LIGHT
            elif y == bottom - 1:
                px[x, y] = SHADE
            else:
                px[x, y] = BASE
    for first, width in TAPES:
        for x in range(first, first + width):
            px[x, 0] = TAPE
            px[x, TOP] = TAPE
            px[x, TOP + 1] = TAPE_SHADE
    return image


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="also write an 8x preview here")
    args = parser.parse_args()
    image = draw()
    image.save(OUT)
    print(f"wrote {OUT.relative_to(ROOT)}")
    if args.preview:
        image.resize((WIDTH * 8, HEIGHT * 8), Image.NEAREST).save(args.preview)


if __name__ == "__main__":
    main()
