"""Draws Pubivisailija, the Irish pub quiz regular: a grey tweed flat cap, round glasses, a
ginger beard, a green cable-knit sweater with a shamrock pin, jeans and boots, his quiz
answer sheet in the left hand and a pencil in the right. His female counterpart
(pubivisailija_naaras_32) has long ginger hair instead of the beard. The flat cap's brim and the white
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
NAARAS_NAME = "pubivisailija_naaras_32"

PALETTE = {
    "s": hex_color("ead4aa"),  # skin
    "t": hex_color("e4a672"),  # skin shade
    "e": hex_color("3a4466"),  # pupils
    "o": hex_color("262b44"),  # glasses frames
    "k": hex_color("3e2731"),  # mouth
    "R": hex_color("e43b44"),  # lips
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
    ".....hhhhhhhH.......",
    ".....hhhhhhHH.......",
    ".....hssssstH.......",
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
# Her: slimmer, the same cap, glasses and sweater, long ginger hair down by the cheeks and over the
# shoulders instead of the beard, red lips; from behind the hair hangs down her back.
NAARAS_HEAD_FRONT = [
    "......CCCCCCc.......",
    ".....CCCCCCCCc......",
    "...ccCCCCCCCCc......",
    "....hhsssssshh......",
    "....howeoweoth......",
    "....hssstsssth......",
    "....hsssssssth......",
    "....hHssRRssth......",
    "....hh.sssst.hH.....",
    "....hh..ss...hH.....",
]
NAARAS_HEAD_BACK = [
    "......CCCCCCc.......",
    ".....CCCCCCCCc......",
    ".....cCCCCCCCcc.....",
    "....hhhhhhhhhh......",
    "....hhHhhhhHhH......",
    "....hhHhhhhHhH......",
    "....hhHhhhhHhH......",
    "....hhhhhHhhhH......",
    "....hhhhhHhhHH......",
    "....hhHhhHhhHH......",
]
NAARAS_TORSO_FRONT = [
    "....hGGGGGGGGGhH....",
    "...GG.hLGGGLhg.gg...",
    "...GG.hLGGGLhg.gg...",
    "...GG.GLGGGLGg.gg...",
    "...GG.GLGGGLGg.gg...",
    "...GG.GLGGGLGg.gg...",
    "......GLGGGLGg......",
    "......gggggggg......",
    "......11111111......",
]
NAARAS_TORSO_BACK = [
    "....hhhhhhhhhhHH....",
    "...GG.hhhhhhHg.gg...",
    "...GG.GhhhhHGg.gg...",
    "...GG.GGhhHGGg.gg...",
    "...GG.GGLGGLGg.gg...",
    "...GG.GGLGGLGg.gg...",
    "......GGLGGLGg......",
    "......gggggggg......",
    "......11111111......",
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


def look(naaras: bool = False) -> Look:
    return Look(
        palette=PALETTE,
        head_front=NAARAS_HEAD_FRONT if naaras else HEAD_FRONT,
        head_back=NAARAS_HEAD_BACK if naaras else HEAD_BACK,
        torso_front=NAARAS_TORSO_FRONT if naaras else TORSO_FRONT,
        torso_back=NAARAS_TORSO_BACK if naaras else TORSO_BACK,
        held=(Held(SHEET, SHEET_ANCHOR, trails=False), Held(PENCIL, PENCIL_ANCHOR, trails=False)),
    )


def draw_back_row(sheet: Image.Image, front: Look, naaras: bool) -> None:
    """From behind the sheet is in the hand on the right and the pencil on the left."""
    back = look(naaras)
    back.palette = front.palette
    back.held = (Held(PENCIL, PENCIL_ANCHOR, trails=False), Held(SHEET, (0, -2), trails=False))
    check(back)
    sheet.paste((0, 0, 0, 0), (0, FRAME, FRAME * 4, FRAME * 2))
    for column, bob in enumerate((0, -1, 0)):
        draw_frame(sheet, back, column, 1, back=True, bob=bob, legs="stand", hands=HANDS_REST, trail=STILL)


def build(naaras: bool) -> Image.Image:
    front = look(naaras)
    sheet = draw_sheet(front)
    draw_back_row(sheet, front, naaras)
    return sheet


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="also write a 6x preview of both side by side")
    parser.add_argument("--force-aseprite", action="store_true")
    args = parser.parse_args()
    sheets = {NAME: build(False), NAARAS_NAME: build(True)}
    for name, sheet in sheets.items():
        path = TEXTURE_DIR / f"{name}.png"
        sheet.save(path)
        print(f"wrote {path.relative_to(ROOT)}")
        write_aseprite_source(path, args.force_aseprite)
    if args.preview:
        image = Image.new("RGBA", (FRAME * 8, FRAME * 4), (40, 36, 48, 255))
        for index, sheet in enumerate(sheets.values()):
            image.alpha_composite(sheet, (FRAME * 4 * index, 0))
        image.resize((image.width * 5, image.height * 5), Image.NEAREST).save(args.preview)


if __name__ == "__main__":
    main()
