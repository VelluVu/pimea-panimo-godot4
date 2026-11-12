"""Draws Tikru, the cellar cat: the developer's own cat, a brown mackerel tabby and a true
gentleman. Grey-brown coat, near-black stripes running from the spine down the body and
legs, the tabby M on the forehead, warm tan bands on the chest, an ochre glow round the eyes,
a light jaw and muzzle, a darker reddish-brown nose, white whiskers and dark paws and pink ears, the tail held up with ringed stripes.

The sheet replaces assets/textures/cat_32.png in place: four 32 px frames side by side, a
walk facing left (cat_anim.tres plays it as `walk_left`), the cat on the same floor row as
before. Light from the upper left; the far legs are a shade darker.

    python dev/tools/sprites/make_tikru.py [--preview out.png] [--force-aseprite]
"""

import argparse
from pathlib import Path

from PIL import Image

from customer_sheet import ROOT, hex_color, paint
from make_orveltaja import write_aseprite_source

OUT = ROOT / "assets/textures/cat_32.png"
FRAME = 32
LEFT, TOP = 5, 15  # where the cat's grid starts in each frame; the paws land on row 29, as before

PALETTE = {
    "K": hex_color("151210"),  # deepest stripes, eye line
    "S": hex_color("2a221c"),  # stripes
    "D": hex_color("31271f"),  # belly shade, far legs
    "F": hex_color("4e4036"),  # grey-brown coat
    "L": hex_color("8a7762"),  # lit top of the head and ears
    "H": hex_color("6e5c4c"),  # the head, a shade lighter than the body
    "T": hex_color("a88458"),  # warm tan bands on the chest
    "O": hex_color("a8743e"),  # ochre glow round the eyes and nose
    "C": hex_color("e2d6c2"),  # cream chin and muzzle
    "N": hex_color("7d4436"),  # darker reddish-brown nose
    "P": hex_color("c98f80"),  # ear insides
    "E": hex_color("b8a646"),  # eye
    "e": hex_color("181425"),  # pupil
    "W": hex_color("ffffff"),  # whiskers
}

# Head, body and tail, facing left; legs are drawn per frame below. Rows 0-10 of the grid.
BODY = [
    ".L....H...........KS",
    "LPL..HPH..........LF",
    "LLKLLKHH..........SK",
    "LKLOOLKH..........LF",
    "LEeOOeEHKKFFKKF..SK.",
    "HOONNOOHKKFFKKFFKKF.",
    "HCCCCCCHKKFFKKFFKKF.",
    "..TTTTFFFKKFFKKFFKK.",
    "..KKKKFFFKKFFKKFFKD.",
    "...TTFFFFKKFFKKFFKD.",
    "....DDDDDDDDDDDDDD..",
]
for _row in BODY:
    assert len(_row) == 20, _row
# White whiskers drooping from the muzzle on both sides: each starts at the face and slopes
# down and out, drawn over the body on the right. The grid starts three columns left of
# BODY's, so the left ones can hang out of the face.
WHISKERS = [
    "..W........W...",
    "WW..........WW.",
]
WHISKERS_X, WHISKERS_ROW = -3, 6  # they start on the jaw row, under the nose


# One leg, 2 px wide, rows 11-14: the coat, a stripe, then darkening down to his dark paws.
LEG_NEAR = ["FF", "SF", "DD", "KK"]
LEG_FAR = ["DD", "KD", "DD", "KK"]
LEG_TOP = 11

# The walk: (front near, front far, back near, back far) as (x at the top, x at the paw).
# Facing left, forward is to the left. Contact poses reach, passing poses gather the legs.
WALK = [
    ((4, 2), (6, 7), (14, 16), (12, 11)),
    ((5, 5), (6, 6), (13, 13), (14, 14)),
    ((6, 7), (4, 2), (12, 11), (14, 16)),
    ((6, 6), (5, 5), (14, 14), (13, 13)),
]


def draw_leg(frame: Image.Image, rows: list[str], top_x: int, paw_x: int) -> None:
    for index, row in enumerate(rows):
        x = top_x + round((paw_x - top_x) * index / (len(rows) - 1))
        paint(frame, PALETTE, [row], LEFT + x, TOP + LEG_TOP + index)


# The user's own hand edit of frame 0 in Aseprite (2026-11-12): the mouth under the light
# jaw, the whiskers and the tail tip. (x, y, RGBA) in the frame, applied to every frame.
USER_EDITS = [
    (23, 12, (21, 18, 16, 255)),
    (23, 13, (21, 18, 16, 255)),
    (24, 13, (42, 34, 28, 255)),
    (23, 14, (138, 119, 98, 255)),
    (24, 14, (78, 64, 54, 255)),
    (3, 19, (255, 255, 255, 255)),
    (4, 19, (255, 255, 255, 255)),
    (13, 19, (255, 255, 255, 255)),
    (14, 19, (255, 255, 255, 255)),
    (2, 20, (255, 255, 255, 255)),
    (5, 20, (255, 255, 255, 255)),
    (12, 20, (255, 255, 255, 255)),
    (15, 20, (255, 255, 255, 255)),
    (7, 21, (168, 132, 88, 255)),
    (8, 21, (168, 132, 88, 255)),
    (9, 21, (168, 132, 88, 255)),
    (10, 21, (168, 132, 88, 255)),
    (2, 22, (0, 0, 0, 0)),
    (6, 22, (21, 18, 16, 255)),
    (7, 22, (226, 214, 194, 255)),
    (8, 22, (226, 214, 194, 255)),
    (9, 22, (226, 214, 194, 255)),
    (10, 22, (226, 214, 194, 255)),
    (11, 22, (21, 18, 16, 255)),
    (15, 22, (21, 18, 16, 255)),
    (8, 24, (226, 214, 194, 255)),
    (9, 24, (226, 214, 194, 255)),
]


def draw_frame(column: int) -> Image.Image:
    frame = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
    front_near, front_far, back_near, back_far = WALK[column]
    # The far legs first, behind the body.
    draw_leg(frame, LEG_FAR, *front_far)
    draw_leg(frame, LEG_FAR, *back_far)
    paint(frame, PALETTE, BODY, LEFT, TOP)
    paint(frame, PALETTE, WHISKERS, LEFT + WHISKERS_X, TOP + WHISKERS_ROW)
    draw_leg(frame, LEG_NEAR, *front_near)
    draw_leg(frame, LEG_NEAR, *back_near)
    for x, y, color in USER_EDITS:
        frame.putpixel((x, y), color)
    return frame


def draw_sheet() -> Image.Image:
    sheet = Image.new("RGBA", (FRAME * 4, FRAME), (0, 0, 0, 0))
    for column in range(4):
        sheet.alpha_composite(draw_frame(column), (column * FRAME, 0))
    return sheet


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="also write an 8x preview beside the old cat")
    parser.add_argument("--force-aseprite", action="store_true")
    args = parser.parse_args()
    old = Image.open(OUT).convert("RGBA") if args.preview and OUT.exists() else None
    sheet = draw_sheet()
    sheet.save(OUT)
    print(f"wrote {OUT.relative_to(ROOT)}")
    write_aseprite_source(OUT, args.force_aseprite)
    if args.preview:
        image = Image.new("RGBA", (FRAME * 4, FRAME * 2), (40, 36, 48, 255))
        image.alpha_composite(sheet, (0, 0))
        if old is not None:
            image.alpha_composite(old, (0, FRAME))
        image.resize((image.width * 8, image.height * 8), Image.NEAREST).save(args.preview)


if __name__ == "__main__":
    main()
