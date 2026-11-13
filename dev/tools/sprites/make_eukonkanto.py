"""Draws Eukonkantajat and Ukonkantajat, wife carriers in the Estonian carry: the carried one
hangs upside down on the carrier's back, legs over the shoulders and feet crossed on the
carrier's chest. From the front we see the carrier with the legs draped over the shoulders;
from behind, the carried one's body down the back, head at the carrier's waist, upside down
in a bike helmet (the race rules ask for one).

Eukonkantajat: a man in a red headband, tank top, shorts and running shoes carries his wife
in pink leggings and a white helmet. Ukonkantajat turns it round: a strong woman with a
ponytail carries her husband, hairy legs in blue shorts and big trainers, a moustache.

The sheets follow the other customers' (see customer_sheet.py): 128x128, 32 px frames, rows
idle, idle_up, walk_towards and walk_right, light from above left.

    python dev/tools/sprites/make_eukonkanto.py [--preview out.png] [--force-aseprite] [--no-write]
"""

import argparse
from pathlib import Path

from PIL import Image

from customer_sheet import (BOX_X, BOX_Y, FRAME, HANDS_REST, RIGHT, ROOT, STILL, TEXTURE_DIR, TORSO_TOP, Look,
                            draw_frame, draw_sheet, flat_clothes, hex_color, paint)
from make_orveltaja import write_aseprite_source

NAME = "eukonkantajat_32"
UKKO_NAME = "ukonkantajat_32"

BASE = {
    "s": hex_color("ead4aa"),  # carrier's skin
    "t": hex_color("e4a672"),  # skin shade, nose
    "e": hex_color("3a4466"),  # pupils
    "W": hex_color("ffffff"),  # eye whites, teeth, shoe
    "w": hex_color("c0cbdc"),  # shoe shade
    "k": hex_color("3e2731"),  # mouth
    "R": hex_color("e43b44"),  # headband
    "a": hex_color("eeca9e"),  # carried one's skin
    "c": hex_color("c5a37a"),  # carried one's skin shade, nose
    "H": hex_color("ffffff"),  # helmet
    "h": hex_color("8b9bb4"),  # helmet shade
}

# He carries her: a blond buzz, a red headband, a blue tank top and shorts; she wears pink
# leggings, a yellow T-shirt and white trainers.
EUKKO = {
    **BASE,
    "y": hex_color("e5d58e"),  # his hair
    "Y": hex_color("c5a37a"),  # hair shade
    "T": hex_color("124e89"),  # tank top
    "U": hex_color("0d3466"),  # tank top shade
    "P": hex_color("f6757a"),  # her leggings
    "p": hex_color("e43b44"),  # leggings shade
    "Q": hex_color("fee761"),  # her T-shirt
    "q": hex_color("feae34"),  # T-shirt shade
    "1": hex_color("124e89"), "4": hex_color("ead4aa"), "2": hex_color("e43b44"), "3": hex_color("a22633"),
}
# She carries him: a ponytail, a red headband, a green sports top, black tights; his hairy
# legs in blue shorts, big white trainers, a red T-shirt and a moustache.
UKKO = {
    **BASE,
    "y": hex_color("b86f50"),  # her hair
    "Y": hex_color("733e39"),  # hair shade
    "T": hex_color("3e8948"),  # sports top
    "U": hex_color("265c42"),  # top shade
    "P": hex_color("e4a672"),  # his bare legs
    "p": hex_color("b86f50"),  # leg hair, shade
    "Q": hex_color("e43b44"),  # his T-shirt
    "q": hex_color("a22633"),  # T-shirt shade
    "M": hex_color("733e39"),  # his moustache
    "1": hex_color("262b44"), "4": hex_color("ead4aa"), "2": hex_color("c0cbdc"), "3": hex_color("5a6988"),
}

# Her knees come over his shoulders beside his neck.
HEAD_FRONT = [
    ".......yyyyyy.......",
    "......yyyyyyyY......",
    ".....RRRRRRRRRR.....",
    ".....yssssssssY.....",
    ".....ysWWssWWtY.....",
    ".....ysWestWetY.....",
    ".....ysssttsssY.....",
    "...PPyyyyyyyyyYPp...",
    "..PPPPyyykkyyYPPPp..",
    "..PPPPPyyyyyyYPPPPp.",
]
HEAD_BACK = [
    ".......yyyyyy.......",
    "......yyyyyyyY......",
    ".....RRRRRRRRRR.....",
    ".....yyyyyyyyyY.....",
    ".....yyyyyyyyyY.....",
    ".....yyyyyyyyyY.....",
    "......yyyyyyyY......",
    ".....ytyyyyyytY.....",
    "...PPPyssssssYPPp...",
    "..PPPPPPPPPPPPPPp...",
]
# Her shins down his chest, her trainers crossed at the bottom.
TORSO_FRONT = [
    "..sPPpTyyyyyyYPPpt..",
    "..ssPPpTyYTyYPPpt...",
    "..ss.PPpyYTyYPp.tt..",
    "..ss..PPhTThPp..tt..",
    "...sssWWWwWWWwttt...",
    ".....TTTTTTTTTTU....",
    ".....TTTTTTTTTTU....",
    ".....TTTTTTTTTTU....",
    ".....TTTTTTTTTTU....",
]
# Her back down his back: hips at his shoulders, the shirt, her arms round his waist and
# her head upside down at the bottom, chin up and helmet down.
TORSO_BACK = [
    "..ssPPPPPPPPPPPPst..",
    "..ssQQQQQQQQQQQqst..",
    "..ss.QQQQQQQQQqqst..",
    "..ssaaQQQQQQQqaast..",
    "..ss.aaQQQQQQaa.st..",
    ".....TTTTTTTTTTU....",
    ".....TTTTTTTTTTU....",
    ".....TTTTTTTTTTU....",
    ".....TTTTTTTTTTU....",
]
TORSO_FRONT = flat_clothes(TORSO_FRONT, {"T": "U"})

# She carries him: a ponytail behind, his hairy knees by her neck.
UKKO_HEAD_FRONT = [
    ".......yyyyyy.......",
    "......yyyyyyyY......",
    ".....RRRRRRRRRR.....",
    ".....yssssssssY.....",
    ".....ysWWssWWtY.....",
    ".....ysWestWetY.....",
    ".....ysssttsstY.....",
    "...PP.tsskkst..PPp..",
    "..PpPp.tsssst.PpPp..",
    "..PPPPPssssssPPpPp..",
]
UKKO_HEAD_BACK = [
    ".......yyyyyy.......",
    "......yyyyyyyY......",
    ".....RRRRRRRRRR.....",
    ".....yyyyyyyyyY.....",
    ".....yyyyyyyyyY.....",
    ".....yyyyyyyyyY.....",
    "......yyyyyyyY......",
    "......tyyyYyyt......",
    "...PpP.ssyYss.PpP...",
    "..PpPPpPPyYPPpPPp...",
]
UKKO_TORSO_FRONT = [
    "..sPpPTTTTTTTTPpPt..",
    "..ssPPpTTTTTTPPpt...",
    "..ss.PpPTTTTPpP.tt..",
    "..ss..PPpTTPPp..tt..",
    "...sssWWWwWWWwttt...",
    ".....33333333333....",
    ".....TTTTTTTTTTU....",
    ".....TTTTTTTTTTU....",
    ".....TTTTTTTTTTU....",
]
UKKO_TORSO_BACK = [
    "..ss111111111111st..",
    "..ssQQQQQQQQQQQqst..",
    "..ss.QQQQQQQQQqqst..",
    "..ssaaQQQQQQQqaast..",
    "..ss.aaQQQQQQaa.st..",
    ".....TTTTTTTTTTU....",
    ".....TTTTTTTTTTU....",
    ".....TTTTTTTTTTU....",
    ".....TTTTTTTTTTU....",
]
UKKO_TORSO_FRONT = flat_clothes(UKKO_TORSO_FRONT, {"T": "U"})

# The carried one's head, drawn the right way up and painted upside down below the shirt.
CARRIED_HEAD = [
    "..HHHHHH..",
    ".HHHHHHHHh",
    "HHHHHHHHHh",
    "hhhhhhhhhh",
    ".aaaaaaac.",
    "aaWWaaWWca",
    "aaWeacWeca",
    ".aaaccaac.",
    ".aakkkkac.",
    "..aaaaac..",
]
UKKO_CARRIED_HEAD = [
    "..HHHHHH..",
    ".HHHHHHHHh",
    "HHHHHHHHHh",
    "hhhhhhhhhh",
    ".aaaaaaac.",
    "aaWWaaWWca",
    "aaWeacWeca",
    ".aaaccaac.",
    ".MMMMMMMc.",
    "..akkkac..",
]
# Painted from this torso row, so the helmet hangs over the carrier's shorts.
CARRIED_HEAD_ROW = 4


def carried_head(rows: list[str]):
    flipped = list(reversed(rows))

    def paint_head(frame: Image.Image, palette: dict, upper: int, back: bool) -> None:
        if back:
            paint(frame, palette, flipped, BOX_X + 5, upper + TORSO_TOP + CARRIED_HEAD_ROW)

    return paint_head


# Walking across, the carried one hangs down the carrier's back, so the carry reads from the
# side: hips over the shoulder, the shirt, arms round the waist, the face upside down and the
# helmet by the carrier's knees. Drawn behind the carrier, from box row 8, two columns left.
HANGING = [
    ".PPPPp.",
    "PPPPPPp",
    ".PPPPp.",
    ".QQQQq.",
    ".QQQQq.",
    ".QQQQq.",
    ".aQQqa.",
    "..aac..",
    ".akkka.",
    "aacaacc",
    "aWeaWec",
    "aWWaWWc",
    ".aaaac.",
    "hhhhhhh",
    "HHHHHHH",
    ".HHHHH.",
]
UKKO_HANGING = [
    ".1111..",
    "111111.",
    ".PPPPp.",
    ".QQQQq.",
    ".QQQQq.",
    ".QQQQq.",
    ".aQQqa.",
    "..aac..",
    ".akkka.",
    "MMMMMMc",
    "aWeaWec",
    "aWWaWWc",
    ".aaaac.",
    "hhhhhhh",
    "HHHHHHH",
    ".HHHHH.",
]
HANGING_TOP = 8
HANGING_LEFT = -2


def draw_walk_right(sheet: Image.Image, look: Look, hanging: list[str]) -> None:
    """Redraws the walk_right row with the carried one hanging behind."""
    for column, (legs, bob, hands, _trail) in enumerate(RIGHT):
        cell = (column * FRAME, 3 * FRAME, (column + 1) * FRAME, 4 * FRAME)
        sheet.paste((0, 0, 0, 0), cell)
        behind = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
        paint(behind, look.palette, hanging, BOX_X + HANGING_LEFT, BOX_Y + bob - look.lift + HANGING_TOP)
        sheet.alpha_composite(behind, (column * FRAME, 3 * FRAME))
        draw_frame(sheet, look, column, 3, back=False, bob=bob, legs=legs, hands=hands, trail=STILL)


def sheet_for(ukko: bool) -> Image.Image:
    carrier = look(ukko)
    sheet = draw_sheet(carrier)
    draw_walk_right(sheet, carrier, UKKO_HANGING if ukko else HANGING)
    return sheet


def look(ukko: bool = False) -> Look:
    if ukko:
        return Look(palette=dict(UKKO), head_front=UKKO_HEAD_FRONT, head_back=UKKO_HEAD_BACK,
                    torso_front=UKKO_TORSO_FRONT, torso_back=UKKO_TORSO_BACK,
                    extra=carried_head(UKKO_CARRIED_HEAD), hand=["..", ".."])
    return Look(palette=dict(EUKKO), head_front=HEAD_FRONT, head_back=HEAD_BACK,
                torso_front=TORSO_FRONT, torso_back=TORSO_BACK,
                extra=carried_head(CARRIED_HEAD), hand=["..", ".."])


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="also write a 6x preview beside normaali_mies")
    parser.add_argument("--force-aseprite", action="store_true")
    parser.add_argument("--no-write", action="store_true", help="only the preview")
    args = parser.parse_args()
    sheets = {NAME: sheet_for(False), UKKO_NAME: sheet_for(True)}
    if not args.no_write:
        for name, sheet in sheets.items():
            path = TEXTURE_DIR / f"{name}.png"
            sheet.save(path)
            print(f"wrote {path.relative_to(ROOT)}")
            write_aseprite_source(path, args.force_aseprite)
    if args.preview:
        normal = Image.open(TEXTURE_DIR / "normaali_mies_32.png").convert("RGBA")
        images = [normal, *sheets.values()]
        image = Image.new("RGBA", (FRAME * 4 * len(images), FRAME * 4), (40, 36, 48, 255))
        for index, sheet in enumerate(images):
            image.alpha_composite(sheet, (FRAME * 4 * index, 0))
        image.resize((image.width * 6, image.height * 6), Image.NEAREST).save(args.preview)


if __name__ == "__main__":
    main()
