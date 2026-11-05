"""Draws Pubivisailija, the Irish pub quiz regular: a grey tweed flat cap, round glasses, a
ginger beard, a green cable-knit sweater with a shamrock pin, jeans and boots, his quiz
answer sheet in the left hand and a pencil in the right. The flat cap's brim and the white
sheet make the silhouette. From behind the sheet and pencil change hands; that row is drawn
again with the light still from the upper left, not mirrored.

The sheet follows the other customers' (see customer_sheet.py): 128x128, 32 px frames,
rows idle, idle_up, walk_towards and walk_right, light from above left.

    python dev/tools/sprites/make_pubivisailija.py [--preview out.png] [--force-aseprite]
"""

import argparse
from pathlib import Path

from PIL import Image

from customer_sheet import (FRAME, HANDS_REST, ROOT, STILL, TEXTURE_DIR, Held, Look, check, draw_frame, draw_sheet,
                            hex_color)
from make_orveltaja import write_aseprite_source

NAME = "pubivisailija_32"

PALETTE = {
    "s": hex_color("ead4aa"),  # skin
    "t": hex_color("e4a672"),  # skin shade
    "e": hex_color("3a4466"),  # pupils
    "o": hex_color("262b44"),  # glasses frames
    "k": hex_color("3e2731"),  # mouth
    "h": hex_color("d77643"),  # ginger beard and hair
    "H": hex_color("be4a2f"),  # beard shade
    "C": hex_color("8b9bb4"),  # grey tweed cap
    "c": hex_color("5a6988"),  # tweed cap shade
    "w": hex_color("c0cbdc"),  # glasses lenses, sheet lines
    "G": hex_color("3e8948"),  # sweater
    "g": hex_color("265c42"),  # sweater shade
    "L": hex_color("63c74d"),  # sweater cables, shamrock
    "W": hex_color("ffffff"),  # answer sheet
    "Y": hex_color("feae34"),  # pencil
    "y": hex_color("181425"),  # pencil lead
    # Legs: jeans and brown boots.
    "1": hex_color("124e89"), "4": hex_color("124e89"), "2": hex_color("733e39"), "3": hex_color("3e2731"),
}

# The flat cap sits low, its brim sticking out to the front left; round glasses, a ginger
# beard round a mouth open mid-answer.
HEAD_FRONT = [
    "......CCCCCCc.......",
    ".....CCCCCCCCc......",
    "...ccCCCCCCCCc......",
    ".....hssssssh.......",
    ".....oweoweot.......",
    ".....ssstssst.......",
    ".....hsssssht.......",
    ".....hhhkkhhH.......",
    "......hhhhhH........",
]
HEAD_BACK = [
    "......CCCCCCc.......",
    ".....CCCCCCCCc......",
    ".....cCCCCCCCcc.....",
    ".....hhhhhhhh.......",
    ".....hhhhhhhH.......",
    ".....shhhhhhtt......",
    ".....ssssssstt......",
    ".....shsssssh.......",
    "......ssssst........",
]
# Rows 10-18: a chunky sweater with two lighter cables down the front and a shamrock pin.
TORSO_FRONT = [
    "....GGGGGGGGGgg.....",
    "...GGGLGGGGLGLgg....",
    "..GG.GLGGGGLGGgg....",
    "..GG.GLGGLGLGGg.gg..",
    "..GG.GLGGGGLGGg.gg..",
    "..GG.GLGGGGLGGg.gg..",
    ".....GLGGGGLGGg.....",
    ".....gggggggggg.....",
    ".....1111111111.....",
]
TORSO_BACK = [
    "....GGGGGGGGGgg.....",
    "...GGGGGGGGGGGgg....",
    "..GG.GGLGGLGGGg.gg..",
    "..GG.GGLGGLGGGg.gg..",
    "..GG.GGLGGLGGGg.gg..",
    "..GG.GGLGGLGGGg.gg..",
    ".....GGLGGLGGGg.....",
    ".....gggggggggg.....",
    ".....1111111111.....",
]
# The answer sheet, held up at the side, its lines of answers; the pencil gripped point up.
SHEET = [
    "WWWw",
    "wwWw",
    "WWWw",
    "wwWw",
    "WWWw",
]
SHEET_ANCHOR = (-2, -2)
PENCIL = [
    "y",
    "Y",
    "Y",
    "Y",
]
PENCIL_ANCHOR = (1, -4)


def look() -> Look:
    return Look(
        palette=PALETTE,
        head_front=HEAD_FRONT,
        head_back=HEAD_BACK,
        torso_front=TORSO_FRONT,
        torso_back=TORSO_BACK,
        held=(Held(SHEET, SHEET_ANCHOR, trails=False), Held(PENCIL, PENCIL_ANCHOR, trails=False)),
    )


def draw_back_row(sheet: Image.Image, front: Look) -> None:
    """From behind the sheet is in the hand on the right and the pencil on the left."""
    back = look()
    back.palette = front.palette
    back.held = (Held(PENCIL, PENCIL_ANCHOR, trails=False), Held(SHEET, (0, -2), trails=False))
    check(back)
    sheet.paste((0, 0, 0, 0), (0, FRAME, FRAME * 4, FRAME * 2))
    for column, bob in enumerate((0, -1, 0)):
        draw_frame(sheet, back, column, 1, back=True, bob=bob, legs="stand", hands=HANDS_REST, trail=STILL)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="also write a 6x preview beside a normal customer")
    parser.add_argument("--force-aseprite", action="store_true")
    args = parser.parse_args()
    front = look()
    sheet = draw_sheet(front)
    draw_back_row(sheet, front)
    path = TEXTURE_DIR / f"{NAME}.png"
    sheet.save(path)
    print(f"wrote {path.relative_to(ROOT)}")
    write_aseprite_source(path, args.force_aseprite)
    if args.preview:
        normal = Image.open(TEXTURE_DIR / "normaali_mies_32.png").convert("RGBA")
        image = Image.new("RGBA", (FRAME * 5, FRAME * 4), (40, 36, 48, 255))
        image.alpha_composite(sheet, (0, 0))
        for row in range(4):
            image.alpha_composite(normal.crop((0, 0, 32, 32)), (FRAME * 4, row * FRAME))
        image.resize((image.width * 6, image.height * 6), Image.NEAREST).save(args.preview)


if __name__ == "__main__":
    main()
