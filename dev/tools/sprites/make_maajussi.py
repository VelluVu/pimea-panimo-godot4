"""Draws Maajussi, the farmer: a green feed-company cap with a yellow patch, a moustache,
a blue flannel shirt under brown bib overalls (the straps cross on his back), green rubber
boots up to the knee and a sack of potatoes in one hand. From behind the sack changes
hands; that row is drawn again with the light still from the upper left, not mirrored. The same script draws Emäntä
(emanta_32), the farm wife: a red dotted headscarf, a white apron over a blue dress.

The sheet follows the other customers' (see customer_sheet.py): 128x128, 32 px frames,
rows idle, idle_up, walk_towards and walk_right, light from above left.

    python dev/tools/sprites/make_maajussi.py [--preview out.png] [--force-aseprite]
"""

import argparse
from pathlib import Path

from PIL import Image

from customer_sheet import (BOX_X, FRAME, HANDS_REST, ROOT, STILL, TEXTURE_DIR, Held, Look, check, draw_frame,
                            draw_sheet, hex_color, paint)
from make_orveltaja import write_aseprite_source

NAME = "maajussi_32"

PALETTE = {
    "s": hex_color("ead4aa"),  # skin
    "t": hex_color("e4a672"),  # skin shade
    "e": hex_color("3a4466"),  # pupils
    "W": hex_color("ffffff"),  # eye whites
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
    "......sWWssWWt......",
    "......sWestWet......",
    "......sssttsst......",
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
    "....FFOFFFFFFOFf....",
    "...FFFOFFFFFFOFFf...",
    "..ffFFOOOOOOOOFFff..",
    "..FF.FOOOooOOOf.Ff..",
    "..ff.FOOOooOOOf.ff..",
    "..FF.OOOOOOOOOo.Ff..",
    ".....OOOOOOOOOo.....",
    ".....OOOOOOOOOo.....",
    "......11111111......",
]
TORSO_BACK = [
    "....FFFFFFFFFFFf....",
    "...FFFOFFFFFFOFFf...",
    "..ffFFFOFFFFOFFFff..",
    "..FF.FFFOFFOFFf.Ff..",
    "..ff.FFFFOOFFFf.ff..",
    "..FF.OOOOOOOOOo.Ff..",
    ".....OOOOOOOOOo.....",
    ".....OOOOOOOOOo.....",
    "......11111111......",
]
# Gripped by its tied neck, so the hand hides the tie; it hangs and lags when walking.
SACK = [
    ".vv..",
    "UUUuv",
    "UUUuv",
    "UUuuv",
    "Uuuuv",
    ".vvv.",
]
SACK_ANCHOR = (-2, 0)
# In the right hand (from behind) it hangs on the outer side of that hand.
SACK_BACK_ANCHOR = (-1, 0)


# Emäntä, the farm wife: a red headscarf with white dots tied under the chin, rosy cheeks,
# a blue dress under a white apron, the skirt over the knees, the same rubber boots and sack.
EMANTA_NAME = "emanta_32"
EMANTA_PALETTE = {
    **PALETTE,
    "H": hex_color("e43b44"),  # headscarf
    "g": hex_color("a22633"),  # headscarf shade
    "W": hex_color("ffffff"),  # scarf dots, apron
    "w": hex_color("c0cbdc"),  # apron shade
    "C": hex_color("f6757a"),  # rosy cheeks
    "k": hex_color("3e2731"),  # mouth
    "D": hex_color("0099db"),  # dress, lit
    "d": hex_color("124e89"),  # dress
    "K": hex_color("262b44"),  # dress shade
    "1": hex_color("124e89"),
}
EMANTA_HEAD_FRONT = [
    "......HHHHHHHg......",
    ".....HHWHHHWHgg.....",
    ".....Hhhhhhhhhg.....",
    ".....HsWWssWWsg.....",
    ".....HsWestWesg.....",
    ".....HCssttssCg.....",
    ".....Hssskksssg.....",
    ".......tsssst.......",
    ".........Hg.........",
]
EMANTA_HEAD_BACK = [
    "......HHHHHHHg......",
    ".....HHWHHHWHgg.....",
    ".....HHHHWHHHgg.....",
    ".....HHHHHHHHgg.....",
    ".....HWHHHHWHgg.....",
    ".....HHHHHHHHgg.....",
    "......HHHHHHgg......",
    "........HHgg........",
]
EMANTA_TORSO_FRONT = [
    "....DDDDDDDDDDDd....",
    "...DDDDDDDDDDDDDd...",
    "...DD.DDWWWWDd.Dd...",
    "...DD.DDWWWWDd.Dd...",
    "...DD.Dwwwwwwd.Dd...",
    "...DD.DWWWWWWd.Dd...",
    "....DDDWWWWWWDDd....",
    "...DDDDWWWWWWDDDd...",
    "...DDDDWWWWWWDDDd...",
]
EMANTA_TORSO_BACK = [
    "....DDDDDDDDDDDd....",
    "...DDDDDDDDDDDDDd...",
    "...DD.DDDDDDDd.Dd...",
    "...DD.DDDDDDDd.Dd...",
    "...DD.WWWWWWWd.Dd...",
    "...DD.DDDDDDDd.Dd...",
    "....DDDDDDDDDDDd....",
    "...DDDDDDDDDDDDDd...",
    "...DDDDDDDDDDDDDd...",
]
# The skirt and apron go on over the knees; below them only the boots show.
SKIRT_HEM = ["...DDDDWWWWWWDDDd...", "...ddddwwwwwwdddd..."]
SKIRT_HEM_BACK = ["...DDDDDDDDDDDDDd...", "...dddddddddddddd..."]


def _skirt(frame: Image.Image, palette: dict, upper: int, back: bool) -> None:
    paint(frame, palette, SKIRT_HEM_BACK if back else SKIRT_HEM, BOX_X, upper + 19)


def look(emanta: bool = False) -> Look:
    if emanta:
        return Look(palette=EMANTA_PALETTE, head_front=EMANTA_HEAD_FRONT, head_back=EMANTA_HEAD_BACK,
                    torso_front=EMANTA_TORSO_FRONT, torso_back=EMANTA_TORSO_BACK, hand_inset=1,
                    held=(Held(SACK, SACK_ANCHOR), None), extra=_skirt)
    return Look(palette=PALETTE, head_front=HEAD_FRONT, head_back=HEAD_BACK,
                torso_front=TORSO_FRONT, torso_back=TORSO_BACK, held=(Held(SACK, SACK_ANCHOR), None))


def draw_back_row(sheet: Image.Image, front: Look, emanta: bool) -> None:
    """From behind the sack is in the hand on the right."""
    back = look(emanta)
    back.palette = front.palette
    back.held = (None, Held(SACK, SACK_BACK_ANCHOR))
    check(back)
    sheet.paste((0, 0, 0, 0), (0, FRAME, FRAME * 4, FRAME * 2))
    for column, bob in enumerate((0, -1, 0)):
        draw_frame(sheet, back, column, 1, back=True, bob=bob, legs="stand", hands=HANDS_REST, trail=STILL)


def build(emanta: bool = False) -> Image.Image:
    front = look(emanta)
    sheet = draw_sheet(front)
    draw_back_row(sheet, front, emanta)
    return sheet


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="also write a 5x preview")
    parser.add_argument("--force-aseprite", action="store_true")
    args = parser.parse_args()
    sheets = {NAME: build(), EMANTA_NAME: build(True)}
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
