"""Draws Maajussi, the farmer: a green feed-company cap with a yellow patch, a moustache,
a blue flannel shirt under brown bib overalls (the straps cross on his back), green rubber
boots up to the knee and a sack of potatoes in one hand. From behind the sack changes
hands; that row is drawn again with the light still from the upper left, not mirrored.

The sheet follows the other customers' (see customer_sheet.py): 128x128, 32 px frames,
rows idle, idle_up, walk_towards and walk_right, light from above left.

    python dev/tools/sprites/make_maajussi.py [--preview out.png] [--force-aseprite]
"""

import argparse
from pathlib import Path

from PIL import Image

from customer_sheet import (FRAME, HANDS_REST, ROOT, STILL, TEXTURE_DIR, Held, Look, check, draw_frame,
                            draw_sheet, hex_color)
from make_orveltaja import write_aseprite_source

NAME = "maajussi_32"

PALETTE = {
    "s": hex_color("ead4aa"),  # skin
    "t": hex_color("e4a672"),  # skin shade
    "e": hex_color("3a4466"),  # eyes
    "h": hex_color("733e39"),  # moustache, hair
    "H": hex_color("3e2731"),  # hair shade
    "C": hex_color("3e8948"),  # cap
    "c": hex_color("265c42"),  # cap shade, brim
    "Y": hex_color("feae34"),  # cap patch
    "F": hex_color("0099db"),  # flannel
    "f": hex_color("124e89"),  # flannel shade, checks
    "O": hex_color("b86f50"),  # brown work overalls
    "o": hex_color("733e39"),  # overalls shade, bib pocket
    "U": hex_color("e8b796"),  # sack, lit
    "u": hex_color("c28569"),  # sack
    "v": hex_color("733e39"),  # sack shade, tie
    # Legs: overalls, then green rubber boots up to the knee.
    "1": hex_color("b86f50"), "4": hex_color("3e8948"), "2": hex_color("3e8948"), "3": hex_color("265c42"),
}

# The cap's brim throws a shade on the forehead.
HEAD_FRONT = [
    "......CCCYYCCc......",
    ".....CCCCYYCCcc.....",
    "....cccccccccccc....",
    "......tttttttt......",
    "......ssessest......",
    "......sssstsst......",
    "......sshhhhst......",
    ".......tsssst.......",
]
HEAD_BACK = [
    "......CCCCCCCc......",
    ".....CCCCCCCCcc.....",
    ".....cccccccccc.....",
    "......hhhhhhhh......",
    "......hhhhhhhH......",
    "......thhhhhHt......",
    ".......ssssst.......",
    ".......ssssst.......",
]
# The bib and its straps over the flannel; the sleeves' checks are rows of the two reds.
TORSO_FRONT = [
    "....FFOFFFFFFOff....",
    "...FFFOFFFFFFOfff...",
    "..ffFFOOOOOOOOffff..",
    "..FF.FOOOooOOOf.ff..",
    "..ff.FOOOooOOOf.ff..",
    "..FF.OOOOOOOOOo.ff..",
    ".....OOOOOOOOOo.....",
    ".....OOOOOOOOOo.....",
    "......11111111......",
]
TORSO_BACK = [
    "....FFFFFFFFFfff....",
    "...FFFOFFFFFFOfff...",
    "..ffFFFOFFFFOfffff..",
    "..FF.FFFOFFOFFf.ff..",
    "..ff.FFFFOOFFFf.ff..",
    "..FF.OOOOOOOOOo.ff..",
    ".....OOOOOOOOOo.....",
    ".....OOOOOOOOOo.....",
    "......11111111......",
]
# Gripped by its tied neck, so the hand hides the tie; it hangs and lags when walking.
SACK = [
    ".vv.",
    "UUuv",
    "UUuv",
    "Uuuv",
    "uuvv",
]
SACK_ANCHOR = (-1, 0)


def look() -> Look:
    return Look(palette=PALETTE, head_front=HEAD_FRONT, head_back=HEAD_BACK,
                torso_front=TORSO_FRONT, torso_back=TORSO_BACK, held=(Held(SACK, SACK_ANCHOR), None))


def draw_back_row(sheet: Image.Image, front: Look) -> None:
    """From behind the sack is in the hand on the right."""
    back = look()
    back.palette = front.palette
    back.held = (None, Held(SACK, SACK_ANCHOR))
    check(back)
    sheet.paste((0, 0, 0, 0), (0, FRAME, FRAME * 4, FRAME * 2))
    for column, bob in enumerate((0, -1, 0)):
        draw_frame(sheet, back, column, 1, back=True, bob=bob, legs="stand", hands=HANDS_REST, trail=STILL)


def build() -> Image.Image:
    front = look()
    sheet = draw_sheet(front)
    draw_back_row(sheet, front)
    return sheet


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="also write a 5x preview")
    parser.add_argument("--force-aseprite", action="store_true")
    args = parser.parse_args()
    sheet = build()
    path = TEXTURE_DIR / f"{NAME}.png"
    sheet.save(path)
    print(f"wrote {path.relative_to(ROOT)}")
    write_aseprite_source(path, args.force_aseprite)
    if args.preview:
        image = Image.new("RGBA", sheet.size, (40, 36, 48, 255))
        image.alpha_composite(sheet)
        image.resize((image.width * 5, image.height * 5), Image.NEAREST).save(args.preview)


if __name__ == "__main__":
    main()
