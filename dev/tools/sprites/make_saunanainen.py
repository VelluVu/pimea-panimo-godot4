"""Draws Saunanainen, Saunamies' counterpart, also straight from the smoke sauna and
munasillaan: a white towel turban with wet blonde hair under it, pink flip-flops and nothing
else, flushed skin, a birch whisk (vihta), and censor mosaics over the chest and the
crotch. Steam rises off her like off him. The turban and the mosaics make the silhouette.
From behind the vihta changes hands; that row is drawn again with the light still from the
upper left, not mirrored.

The sheet follows the other customers' (see customer_sheet.py): 128x128, 32 px frames,
rows idle, idle_up, walk_towards and walk_right, light from above left.

    python dev/tools/sprites/make_saunanainen.py [--preview out.png] [--force-aseprite]
"""

import argparse
from pathlib import Path

from PIL import Image

from customer_sheet import (BOX_X, FRAME, HANDS_REST, ROOT, STILL, TEXTURE_DIR, Held, Look, check, draw_frame,
                            draw_sheet, hex_color, paint)
from make_orveltaja import write_aseprite_source
from make_saunamies import CENSOR, CENSOR_AT, VIHTA, VIHTA_ANCHOR, add_steam

NAME = "saunanainen_32"

PALETTE = {
    "s": hex_color("e4a672"),  # skin, warm from the löyly
    "t": hex_color("b86f50"),  # skin shade
    "P": hex_color("f6757a"),  # flush
    "R": hex_color("e43b44"),  # lips
    "w": hex_color("ffffff"),  # eye white
    "e": hex_color("3a4466"),  # pupil
    "T": hex_color("ffffff"),  # towel turban
    "U": hex_color("c0cbdc"),  # turban shade
    "y": hex_color("feae34"),  # wet blonde hair
    "Y": hex_color("b86f50"),  # hair shade
    "M": hex_color("ead4aa"), "O": hex_color("d77643"),  # censor mosaic, with "t"
    "G": hex_color("63c74d"),  # birch leaves
    "g": hex_color("3e8948"),  # birch leaves shade
    "b": hex_color("733e39"),  # whisk handle
    # Legs: bare, with pink flip-flops.
    "1": hex_color("e4a672"), "4": hex_color("e4a672"), "2": hex_color("e4a672"), "3": hex_color("f6757a"),
    # The far leg in the skin shade: the default darkening turns bare skin grey, like trousers.
    "5": hex_color("b86f50"), "6": hex_color("b86f50"), "7": hex_color("b86f50"),
}

# A towel wrapped high on the head, wet hair hanging out of it by the cheeks, a flushed face
# with red lips.
HEAD_FRONT = [
    ".......TTTTU........",
    "......TTTTTTU.......",
    "......TTTTTUU.......",
    ".....UTTTTTTUU......",
    ".....yssssssy.......",
    ".....ywesewty.......",
    ".....yPsstsPy.......",
    ".....ysRRRsty.......",
    "......yssssty.......",
    ".......ssss.........",
]
HEAD_BACK = [
    ".......TTTTU........",
    "......TTTTTTU.......",
    "......TTTTTUU.......",
    ".....UTTTTTTUU......",
    ".....yyyyyyyy.......",
    ".....yyyyyyyY.......",
    ".....yyyyyyyY.......",
    ".....yyyyyyYY.......",
    "......yyyyyY........",
    ".......ssss.........",
]
# Rows 10-18: slim, narrow shoulders and arms close to the body, a censor mosaic over the chest, a waist and hips; the
# crotch mosaic is painted over the hips (CENSOR, shared with Saunamies). From behind the wet
# hair ends between the shoulder blades.
TORSO_FRONT = [
    "....ssssssssssst....",
    "...ss.sMMOOMMt.st...",
    "...ss.sMMOOMMt.st...",
    "...ss.ssssssst.st...",
    "...ss..ssssst..st...",
    "...ss.ssssssst.st...",
    "......ssssssst......",
    "......ssssssst......",
    "......ssssssst......",
]
TORSO_BACK = [
    "....sssssyyYssst....",
    "...ss.sssyYsst.st...",
    "...ss.sssyYsst.st...",
    "...ss.ssssssst.st...",
    "...ss..ssssst..st...",
    "...ss.ssssssst.st...",
    "......ssssssst......",
    "......sssstsst......",
    "......sssstsst......",
]


def _censor(frame: Image.Image, palette: dict, upper: int, back: bool) -> None:
    if not back:
        paint(frame, palette, CENSOR, BOX_X + CENSOR_AT[0], upper + CENSOR_AT[1])


def look() -> Look:
    return Look(
        palette=PALETTE,
        head_front=HEAD_FRONT,
        head_back=HEAD_BACK,
        torso_front=TORSO_FRONT,
        torso_back=TORSO_BACK,
        held=(None, Held(VIHTA, VIHTA_ANCHOR, trails=True)),
        extra=_censor,
    )


def draw_back_row(sheet: Image.Image, front: Look) -> None:
    """From behind the vihta is in the hand on the left."""
    back = look()
    back.palette = front.palette
    back.held = (Held(VIHTA, VIHTA_ANCHOR, trails=True), None)
    check(back)
    sheet.paste((0, 0, 0, 0), (0, FRAME, FRAME * 4, FRAME * 2))
    for column, bob in enumerate((0, -1, 0)):
        draw_frame(sheet, back, column, 1, back=True, bob=bob, legs="stand", hands=HANDS_REST, trail=STILL)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="also write a 6x preview beside Saunamies")
    parser.add_argument("--force-aseprite", action="store_true")
    args = parser.parse_args()
    front = look()
    sheet = draw_sheet(front)
    draw_back_row(sheet, front)
    add_steam(sheet)
    path = TEXTURE_DIR / f"{NAME}.png"
    sheet.save(path)
    print(f"wrote {path.relative_to(ROOT)}")
    write_aseprite_source(path, args.force_aseprite)
    if args.preview:
        partner = Image.open(TEXTURE_DIR / "saunamies_32.png").convert("RGBA")
        image = Image.new("RGBA", (FRAME * 5, FRAME * 4), (40, 36, 48, 255))
        image.alpha_composite(sheet, (0, 0))
        for row in range(4):
            image.alpha_composite(partner.crop((0, row * FRAME, 32, (row + 1) * FRAME)), (FRAME * 4, row * FRAME))
        image.resize((image.width * 6, image.height * 6), Image.NEAREST).save(args.preview)


if __name__ == "__main__":
    main()
