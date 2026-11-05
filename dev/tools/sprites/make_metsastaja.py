"""Draws Metsästäjä, the moose hunter in from the hunt: a blaze-orange cap with ear flaps, an
orange safety vest over a camo jacket, dark trousers and rubber boots, his rifle cased and
slung over his back (no loaded guns at the bar), a red thermos in the
left hand and a wooden kuksa in the right. His female counterpart (metsastaja_naaras_32) is
slimmer, with a brown braid over her right shoulder and down her back. The orange cap and
vest make the silhouette. From behind the thermos and kuksa change hands; that row is drawn
again with the light still from the upper left, not mirrored.

The sheet follows the other customers' (see customer_sheet.py): 128x128, 32 px frames,
rows idle, idle_up, walk_towards and walk_right, light from above left.

    python dev/tools/sprites/make_metsastaja.py [--preview out.png] [--force-aseprite]
"""

import argparse
from pathlib import Path

from PIL import Image

from customer_sheet import (FRAME, HANDS_REST, ROOT, STILL, TEXTURE_DIR, Held, Look, check, draw_frame, draw_sheet,
                            hex_color)
from make_orveltaja import write_aseprite_source

NAME = "metsastaja_32"
NAARAS_NAME = "metsastaja_naaras_32"

PALETTE = {
    "s": hex_color("ead4aa"),  # skin
    "t": hex_color("e4a672"),  # skin shade
    "e": hex_color("3a4466"),  # eyes
    "R": hex_color("e43b44"),  # lips, braid tie, thermos
    "U": hex_color("a22633"),  # thermos shade
    "M": hex_color("733e39"),  # moustache, short hair
    "m": hex_color("3e2731"),  # kuksa shade
    "h": hex_color("c28569"),  # her braid
    "H": hex_color("b86f50"),  # braid shade
    "b": hex_color("b86f50"),  # kuksa wood
    "O": hex_color("f77622"),  # blaze orange cap and flaps
    "o": hex_color("be4a2f"),  # orange shade, brim underside
    "V": hex_color("f77622"),  # vest
    "v": hex_color("be4a2f"),  # vest shade, zip
    "J": hex_color("3e8948"),  # camo jacket
    "j": hex_color("265c42"),  # camo shade
    "K": hex_color("733e39"),  # camo patches
    "n": hex_color("b86f50"),  # rifle case leather
    "N": hex_color("733e39"),  # rifle case shade
    "C": hex_color("c0cbdc"),  # thermos cup
    "c": hex_color("8b9bb4"),  # thermos cup shade
    # Legs: dark green trousers, black rubber boots.
    "1": hex_color("265c42"), "4": hex_color("265c42"), "2": hex_color("262b44"), "3": hex_color("181425"),
}

# Cap with its brim to the front left and the ear flaps down by the cheeks; a thick moustache.
HEAD_FRONT = [
    "........OOOO........",
    "......OOOOOOOo......",
    ".....OOOOOOOOOo.....",
    "...ooOOOOOOOOOo.....",
    ".....Osssssso.......",
    ".....Osesseso.......",
    ".....Osssstso.......",
    ".....ssMMMMtt.......",
    "......ssssst........",
]
HEAD_BACK = [
    "........OOOO........",
    "......OOOOOOOo......",
    ".....OOOOOOOOOo.....",
    ".....oOOOOOOOOoo....",
    ".....OOOOOOOOo......",
    ".....OMMMMMMo.......",
    ".....sMMMMMMt.......",
    ".....sssssstt.......",
    "......ssssst........",
]
# Rows 10-18: the vest over the jacket, its zip down the middle; camo sleeves and hem.
TORSO_FRONT = [
    "....JJVVVVVVvjj.....",
    "...JJVVVVvVVVvjj....",
    "..JJ.VVVVvVVVVv.jj..",
    "..JK.VVVVvVVVVv.jj..",
    "..JJ.VVVVvVVVVv.jK..",
    "..KJ.VVVVvVVVVv.jj..",
    ".....JJKJjJJJKj.....",
    ".....jjjjjjjjjj.....",
    ".....1111111111.....",
]
TORSO_BACK = [
    "....JJVVVVVVvjj.....",
    "...JJVVVVVVVVvjj....",
    "..JJ.VVVVVVVVVv.jj..",
    "..JJ.VVVVVVVVVv.Kj..",
    "..KJ.VVVVVVVVVv.jj..",
    "..JJ.VVVVVVVVVv.jj..",
    ".....JKJJjJJKJj.....",
    ".....jjjjjjjjjj.....",
    ".....1111111111.....",
]
# Her: no moustache, red lips, brown hair by the flaps and a braid over the right shoulder.
NAARAS_HEAD_FRONT = [
    "........OOOO........",
    "......OOOOOOOo......",
    ".....OOOOOOOOOo.....",
    "...ooOOOOOOOOOo.....",
    "....hOssssssoh......",
    "....hOsessesoh......",
    "....hOsssstsoh......",
    "....hsssRRsstH......",
    "....hh.sssst.HH.....",
]
NAARAS_HEAD_BACK = [
    "........OOOO........",
    "......OOOOOOOo......",
    ".....OOOOOOOOOo.....",
    ".....oOOOOOOOOoo....",
    "....hOOOOOOOOoh.....",
    "....hOhhhhhhoh......",
    "....hhhhhhhhhH......",
    "....shhhhHHhtt......",
    ".....ssssHHtt.......",
]
NAARAS_TORSO_FRONT = [
    "....JJVVVVVVHjj.....",
    "...JJ.VVVvVHHv.jj...",
    "...JJ.VVVvVVHv.jj...",
    "...JK.VVVvVVHv.jK...",
    "...JJ.VVVvVVRv.jj...",
    "...KJ.VVVvVVVv.jj...",
    "......JJKJjJKj......",
    "......jjjjjjjj......",
    "......11111111......",
]
NAARAS_TORSO_BACK = [
    "....JJVVHHVVvjj.....",
    "...JJ.VVVHHVVv.jj...",
    "...JJ.VVVHHVVv.jj...",
    "...JJ.VVVHHVVv.Kj...",
    "...KJ.VVVRRVVv.jj...",
    "...JJ.VVVVVVVv.jj...",
    "......JKJjJKJj......",
    "......jjjjjjjj......",
    "......11111111......",
]
# A red thermos with its steel cup on top, gripped round the middle.
THERMOS = [
    "Cc",
    "RU",
    "RU",
    "RU",
    "RU",
]
THERMOS_ANCHOR = (0, -2)
# The kuksa: a wooden cup held by its handle, the bowl out to the side.
KUKSA = [
    "bbbm",
    "bbbm",
    ".bm.",
]
KUKSA_ANCHOR = (1, -1)
KUKSA_LEFT = [
    "bbbm",
    "bbbm",
    ".bm.",
]
KUKSA_LEFT_ANCHOR = (-3, -1)

# The cased rifle slung over the back, on a clean 1:3 diagonal from the hip to up beside the
# head, in box coordinates: (column, row) at its butt end, out one column every three rows.
RIFLE_BUTT = (12, 18)
RIFLE_TOP_ROW = -1
RIFLE_RISE = 3


def rifle_rows(back: bool) -> list[tuple[int, int]]:
    """(column, row) of the case's lit side, bottom to top. Facing away it is the same sling
    seen from behind: the top end comes over the shoulder on the other side."""
    butt_col, butt_row = RIFLE_BUTT
    points = []
    for row in range(butt_row, RIFLE_TOP_ROW - 1, -1):
        col = butt_col + (butt_row - row) // RIFLE_RISE
        points.append((19 - col - 1 if back else col, row))
    return points


def paint_rifle(frame: Image.Image, palette: dict, upper: int, back: bool) -> None:
    """Behind the body from the front (only empty pixels are painted), over it from behind.
    The lit side is the left one; the top end is capped in the shade colour."""
    top = rifle_rows(back)[-1]
    for col, row in rifle_rows(back):
        for dx, char in ((0, "n"), (1, "N")):
            x, y = 6 + col + dx, upper + row
            if not (0 <= x < frame.width and 0 <= y < frame.height):
                continue
            if not back and frame.getpixel((x, y))[3] != 0:
                continue
            frame.putpixel((x, y), palette["N" if (col, row) == top else char])


def look(naaras: bool = False) -> Look:
    return Look(
        palette=PALETTE,
        head_front=NAARAS_HEAD_FRONT if naaras else HEAD_FRONT,
        head_back=NAARAS_HEAD_BACK if naaras else HEAD_BACK,
        torso_front=NAARAS_TORSO_FRONT if naaras else TORSO_FRONT,
        torso_back=NAARAS_TORSO_BACK if naaras else TORSO_BACK,
        held=(Held(THERMOS, THERMOS_ANCHOR, trails=False), Held(KUKSA, KUKSA_ANCHOR, trails=False)),
        extra=paint_rifle,
    )


def draw_back_row(sheet: Image.Image, front: Look, naaras: bool) -> None:
    """From behind the kuksa is in the hand on the left and the thermos on the right."""
    back = look(naaras)
    back.palette = front.palette
    back.held = (Held(KUKSA_LEFT, KUKSA_LEFT_ANCHOR, trails=False), Held(THERMOS, THERMOS_ANCHOR, trails=False))
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
    parser.add_argument("--preview", type=Path, help="also write a 5x preview of both side by side")
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
