"""Draws Pubivisailija, the Irish pub quiz regular: a grey tweed flat cap, round glasses, a
ginger beard, a green cable-knit sweater, jeans and boots, his quiz answer sheet in the left
hand and a pencil held sideways in the right. His female counterpart
(pubivisailija_naaras_32) has long ginger hair instead of the beard. The flat cap's brim and the white
sheet make the silhouette. From behind the sheet and pencil change hands; that row is drawn
again with the light still from the upper left, not mirrored. The shapes follow the user's
hand-edited idle frames.

The sheet follows the other customers' (see customer_sheet.py): 128x128, 32 px frames,
rows idle, idle_up, walk_towards and walk_right, light from above left.

    python dev/tools/sprites/make_pubivisailija.py [--preview out.png] [--force-aseprite]
"""

import argparse
from pathlib import Path

from PIL import Image

from customer_sheet import (flat_clothes, FRAME, HANDS_REST, ROOT, STILL, TEXTURE_DIR, Held, Look, check, draw_frame, draw_sheet,
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
    "L": hex_color("63c74d"),  # sweater cables
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
    ".....hssssshH.......",
    ".....hhhkkhhH.......",
    "......hhhhhH........",
]
HEAD_BACK = [
    ".......CCCCCc.......",
    "......CCCCCCCc......",
    "......CCCCCCCccc....",
    "......hhhhhhhH......",
    "......hhhhhhhH......",
    "......hhhhhhhH......",
    "......hhhhhhHH......",
    "......hssssstH......",
    ".......ssssst.......",
]
# Rows 10-18: a chunky sweater with two lighter cables down the front; the shoulders run
# straight into the arms.
TORSO_FRONT = [
    "....GGGGGGGGGggg....",
    "...GGGLGGGGLGGggg...",
    "..GGGGLGGGGLGGgggg..",
    "..GG.GLGGGGLGGg.gg..",
    "..GG.GLGGGGLGGg.gg..",
    "..GG.GLGGGGLGGg.gg..",
    ".....GLGGGGLGGg.....",
    ".....gggggggggg.....",
    "......11111111......",
]
TORSO_BACK = [
    "....GGGGGGGGGggg....",
    "...GGGGGGGGGGGggg...",
    "..GGGGGGGGGGGGgggg..",
    "..GG.GGGGGGGGGg.gg..",
    "..GG.GGGGGGGGGg.gg..",
    "..GG.GGGGGGGGGg.gg..",
    ".....GGGGGGGGGg.....",
    ".....gggggggggg.....",
    "......11111111......",
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
    "....hhssRRssth......",
    "....hhhssssthhH.....",
    "....hhhhssthhhH.....",
]
NAARAS_HEAD_BACK = [
    "......CCCCCCc.......",
    ".....CCCCCCCCc......",
    ".....CCCCCCCCccc....",
    ".....hhhhhhhhhH.....",
    ".....hhHhhhhHhH.....",
    ".....hhHhhhhHhH.....",
    ".....hhHhhhhHhH.....",
    ".....hhhhhHhhhH.....",
    ".....hhhhhHhhHH.....",
    ".....hhHhhHhhHH.....",
]
NAARAS_TORSO_FRONT = [
    "....GGhGGGGGhggg....",
    "...GGGhLGGGLhgggg...",
    "...GG.hLGGGLhg.gg...",
    "...GG.GLGGGLGg.gg...",
    "...GG.GLGGGLGg.gg...",
    "...GG.GLGGGLGg.gg...",
    "......GLGGGLGg......",
    "......gggggggg......",
    "......11111111......",
]
NAARAS_TORSO_BACK = [
    ".....hhhhhhhhHH.....",
    "....GGhhhhhhHHgg....",
    "...GGGGhhhhHHgggg...",
    "...GG.GGhhHHGg.gg...",
    "...GG.GGLGGLGg.gg...",
    "...GG.GGLGGLGg.gg...",
    "......GGLGGLGg......",
    "......gggggggg......",
    "......11111111......",
]
# Clothes in one flat tone with a one-pixel right edge (customer_sheet.flat_clothes).
TORSO_FRONT = flat_clothes(TORSO_FRONT, {"G": "g"}, keep_rows=(7,))
TORSO_BACK = flat_clothes(TORSO_BACK, {"G": "g"}, keep_rows=(7,))
NAARAS_TORSO_FRONT = flat_clothes(NAARAS_TORSO_FRONT, {"G": "g"}, keep_rows=(7,))
NAARAS_TORSO_BACK = flat_clothes(NAARAS_TORSO_BACK, {"G": "g"}, keep_rows=(7,))
# The answer sheet at the side, its lines of answers facing out; the pencil lies sideways in
# the fist, drawn under the hand. Only his shows the lead from the front.
SHEET = [
    "WWWW",
    "wwww",
    "WWWW",
    "wwww",
    "WWWW",
]
SHEET_ANCHOR = (-3, -2)
PENCIL_WITH_LEAD = ["yYYYY"]
PENCIL_WITH_LEAD_ANCHOR = (-2, 1)
PENCIL = ["YYYY"]
PENCIL_ANCHOR = (-1, 1)
# From behind: the blank side of the sheet. His arm stays in front of its top corner.
SHEET_BACK = [
    ".WWw",
    ".WWw",
    "WWWw",
    "WWWw",
    "WWWw",
]
NAARAS_SHEET_BACK = ["WWWw"] * 5
SHEET_BACK_ANCHOR = (1, -2)


# Turned around, the head sat a pixel left of the back view's (and the legs'): one
# pixel right lines the front up, so the head no longer jumps when they turn.
HEAD_FRONT = ["." + row[:-1] for row in HEAD_FRONT]
NAARAS_HEAD_FRONT = ["." + row[:-1] for row in NAARAS_HEAD_FRONT]


def look(naaras: bool = False) -> Look:
    pencil = Held(PENCIL, PENCIL_ANCHOR, trails=False) if naaras else Held(PENCIL_WITH_LEAD, PENCIL_WITH_LEAD_ANCHOR, trails=False)
    return Look(
        palette=PALETTE,
        head_front=NAARAS_HEAD_FRONT if naaras else HEAD_FRONT,
        head_back=NAARAS_HEAD_BACK if naaras else HEAD_BACK,
        torso_front=NAARAS_TORSO_FRONT if naaras else TORSO_FRONT,
        torso_back=NAARAS_TORSO_BACK if naaras else TORSO_BACK,
        held=(Held(SHEET, SHEET_ANCHOR, trails=False), pencil),
        hand_inset=1 if naaras else 0,
    )


def draw_back_row(sheet: Image.Image, front: Look, naaras: bool) -> None:
    """From behind the sheet is in the hand on the right and the pencil on the left."""
    back = look(naaras)
    back.palette = front.palette
    back.held = (Held(PENCIL, PENCIL_ANCHOR, trails=False),
                 Held(NAARAS_SHEET_BACK if naaras else SHEET_BACK, SHEET_BACK_ANCHOR, trails=False))
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
