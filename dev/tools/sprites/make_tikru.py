"""Draws Tikru, the cellar cat: the developer's own cat, a brown mackerel tabby and a true
gentleman. Grey-brown coat, near-black stripes running from the spine down the body and
legs, the tabby M on the forehead, warm tan bands on the chest, an ochre glow round the eyes,
a light jaw and muzzle, a darker reddish-brown nose, white whiskers and dark paws and pink ears, the tail held up with ringed stripes.

The sheet is assets/textures/cat_32.png: 32 px frames, one animation per row, all facing
left (cat_anim.tres plays them). Row 0 is the walk (`walk_left`, also the mouse chase), then
the poses of the cat who lives in the cellar: sit (tail flicks, a blink), sleep (curled up,
breathing), groom (paw to the mouth, licks, wipes the face) and stretch (a bow, a yawn).
The new poses reuse the head of walk frame 0, the user's hand-edited face, as a stamp.
Light from the upper left; the far legs are a shade darker.

    python dev/tools/sprites/make_tikru.py [--preview out.png] [--force-aseprite]
"""

import argparse
import subprocess
from pathlib import Path

from PIL import Image

from customer_sheet import ROOT, hex_color, paint
from make_orveltaja import ASEPRITE, ASEPRITE_SCRIPT

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


# --- the head as a stamp for the other poses ------------------------------------------------
# Walk frame 0's head with the user's edits (x <= 12, rows 15-22) plus its whiskers on the
# right; poses move it up or down. Overrides are in the same walk-frame coordinates.
def _head_stamp() -> dict:
    walk = draw_frame(0)
    stamp = {}
    for y in range(15, 23):
        for x in range(0, 13 if y < 22 else 12):
            color = walk.getpixel((x, y))
            if color[3]:
                stamp[(x, y)] = color
    for y in range(19, 23):
        for x in range(12, 17):
            if walk.getpixel((x, y)) == PALETTE["W"]:
                stamp[(x, y)] = PALETTE["W"]
    return stamp


def _pixels(rows: list[str], left: int, top: int) -> dict:
    return {(left + x, top + y): PALETTE[c] for y, row in enumerate(rows) for x, c in enumerate(row) if c != "."}


EYES_CLOSED = {**_pixels(["L....H"], 6, 18), **_pixels(["KK..KK"], 6, 19)}
# Eyes squeezed shut and the jaw dropped open, pink inside.
YAWN = {**EYES_CLOSED, **_pixels(["KKKK", "KPPK", "KPPK", "CKKC"], 7, 21)}
TONGUE = _pixels(["PP"], 8, 22)


def stamp_head(frame: Image.Image, dy: int, overrides: dict | None = None) -> None:
    for (x, y), color in {**HEAD, **(overrides or {})}.items():
        if 0 <= y + dy < FRAME:
            frame.putpixel((x, y + dy), color)


def blank() -> Image.Image:
    return Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))


# --- sit ---------------------------------------------------------------------------------------
SIT_LIFT = -4  # the head sits four rows higher than in the walk
SIT_BODY = [  # left 0, top 12: the back sloping down to the haunch, the near front leg at x7-8
    ".............F........",
    ".............FS.......",
    ".............FFF......",
    ".............KKFF.....",
    ".............FFKKF....",
    ".............FFFFKF...",
    "............FKKFFFKF..",
    "......FKKKKFFFKKFFFK..",
    "......FFCCFFFFFFKKFKD.",
    "......FFFFFFFFFFFFKKD.",
    "......FFFFFFKKFFFFFKD.",
    ".......FFDDFFKKKKFFKD.",
    ".......SFDKFFFFFFKKFD.",
    ".......FFDDFFFFFFFFKD.",
    ".......SFDKFKKKKFFFKD.",
    ".......FFDDFFFFKKFFDD.",
]
# The tail comes round the haunch and lies in front of the paws (rows 28-29), ringed every
# third pixel; its tip at the left lifts and curls for the flick.
_RING_TOP, _RING_BOTTOM = "LLK" * 6, "FFS" * 6
TAIL_LEFT, TAIL_TOP = 3, 24
TAILS = {
    "down": ["", "", "", "", "." + _RING_TOP[:17], "K" + _RING_BOTTOM[:16] + "D"],
    "up": ["", "", "KS", "LF", ".K" + _RING_TOP[:16], "..D" + _RING_BOTTOM[:14] + "D"],
    "curl": ["", ".KS", "LF.", "KS.", ".L" + _RING_TOP[:16], "..D" + _RING_BOTTOM[:14] + "D"],
}


def sit_frame(tail: str = "down", face: dict | None = None) -> Image.Image:
    frame = blank()
    paint(frame, PALETTE, SIT_BODY, 0, 12)
    paint(frame, PALETTE, TAILS[tail], TAIL_LEFT, TAIL_TOP)
    stamp_head(frame, SIT_LIFT, face)
    return frame


# --- groom: the near front leg lifted to the mouth, behind it only the far leg -----------------
GROOM_GAP = [".D"] * 5  # left 7, top 23: where the near leg stood
GROOM_POSES = {  # pose: (head dy, face, (left, top, rows) of the lifted leg with its lit forearm)
    "lift": (SIT_LIFT, None, (5, 21, ["..LF", ".LF.", "DD..", "KK.."])),
    "lick": (SIT_LIFT + 1, TONGUE, (6, 20, ["DDD..", "KKLF.", "..LF.", "...LF"])),
    "lick2": (SIT_LIFT + 1, None, (6, 21, ["DDD..", "KKLF.", "..LF."])),
    "wipe": (SIT_LIFT, EYES_CLOSED, (5, 14, ["DD...", "KKL..", ".LF..", "..LF.", "..LF.", "...LF", "...LF"])),
}


def groom_frame(pose: str) -> Image.Image:
    head_dy, face, (left, top, leg) = GROOM_POSES[pose]
    frame = blank()
    paint(frame, PALETTE, SIT_BODY, 0, 12)
    paint(frame, PALETTE, GROOM_GAP, 7, 23)
    paint(frame, PALETTE, TAILS["down"], TAIL_LEFT, TAIL_TOP)
    stamp_head(frame, head_dy, face)
    paint(frame, PALETTE, leg, left, top)
    return frame


# --- sleep: curled up, head down on the paws, the back rising with each breath -----------------
SLEEP_DY = 5
SLEEP_BODY = [  # left 11, top 20
    "....FFKKFF...",
    "..FFKKFFKKFF.",
    ".FFFKKFFKKFFD",
    "FFFKKFFKKFFKD",
    "FFFKKFFKKFFKD",
    "FFFKKFFKKFFKD",
    "FFFFKKFFKKFKD",
    "FFFFKKFFKKFDD",
    "DDDDDDDDDDDD.",
]
SLEEP_BREATH_IN = "....FFKKF...."  # one row on top, at row 19


def sleep_frame(breath_in: bool) -> Image.Image:
    frame = blank()
    if breath_in:
        paint(frame, PALETTE, [SLEEP_BREATH_IN], 11, 19)
    paint(frame, PALETTE, SLEEP_BODY, 11, 20)
    paint(frame, PALETTE, TAILS["down"], TAIL_LEFT, TAIL_TOP)
    stamp_head(frame, SLEEP_DY, EYES_CLOSED)
    return frame


# --- stretch: a bow (chin down, front legs out, rump up), a yawn, then up on four legs -------
BOW_DY = 5
# The torso slanting from the shoulders (x12) up to the rump: row -> (first x, last x).
BOW_TORSO = {18: (17, 22), 19: (14, 22), 20: (12, 22), 21: (12, 22), 22: (12, 22),
             23: (12, 18), 24: (12, 16), 25: (12, 14), 26: (12, 13)}
BOW_STRIPES = (14, 15, 18, 19)  # the walk's stripe rhythm
BOW_HIND_NEAR = ["FF", "SF", "FF", "SF", "DD", "DD", "KK"]  # x19-20, rows 23-29
BOW_HIND_FAR = ["DD", "KD", "DD", "KD", "DD", "DD", "KK"]  # x21-22
BOW_FRONT_LEGS = ["KFFSFFSFFFF", "KKDDDDDDDD."]  # left 1, top 28: stretched along the floor
BOW_TAIL = ["KS", "LF", "KS", "LF", "SK", "LF", "KS"]  # left 21, top 11


def _bow_body() -> list[str]:
    rows = [["."] * 24 for _ in range(18, 30)]
    for y, (first, last) in BOW_TORSO.items():
        below = BOW_TORSO.get(y + 1)
        for x in range(first, last + 1):
            underside = below is None or not below[0] <= x <= below[1]
            rows[y - 18][x] = "D" if underside or x == 22 else ("K" if x in BOW_STRIPES else "F")
    for index in range(7):
        rows[23 - 18 + index][19:21] = list(BOW_HIND_NEAR[index])
        rows[23 - 18 + index][21:23] = list(BOW_HIND_FAR[index])
    return ["".join(row) for row in rows]


def bow_frame(yawn: bool) -> Image.Image:
    frame = blank()
    paint(frame, PALETTE, BOW_TAIL, 21, 11)
    paint(frame, PALETTE, _bow_body(), 0, 18)
    paint(frame, PALETTE, BOW_FRONT_LEGS, 1, 28)
    stamp_head(frame, BOW_DY, YAWN if yawn else None)
    return frame


def stand_frame(yawn: bool) -> Image.Image:
    frame = draw_frame(1)
    for (x, y), color in (YAWN if yawn else {}).items():
        frame.putpixel((x, y), color)
    return frame


# --- walking away, towards the back wall: the same walk, the head seen from behind -------------
# No face and no whiskers: the backs of the ears and the tabby lines running down the back of
# the head, lit from the upper left like the rest. The chest under the chin turns to coat.
BACK_HEAD = [  # left 5, top 15
    ".L....H.",
    "LLL..HHH",
    "LLLKKHHH",
    "LFFKKFFH",
    "HFFKKFFH",
    "HFKFFKFD",
    "HKFFFFKD",
    ".DFFFFD.",
]
BACK_CHEST = {"K": "F", "C": "F"}  # rows 23-24, x5-12


def back_frame(column: int) -> Image.Image:
    frame = draw_frame(column)
    inverse = {color: letter for letter, color in PALETTE.items()}
    for y in range(15, 23):
        for x in range(0, 17):
            if x <= 12 or frame.getpixel((x, y)) == PALETTE["W"]:
                frame.putpixel((x, y), (0, 0, 0, 0))
    for y in (23, 24):
        for x in range(5, 13):
            letter = inverse.get(frame.getpixel((x, y)))
            if letter in BACK_CHEST:
                frame.putpixel((x, y), PALETTE[BACK_CHEST[letter]])
    paint(frame, PALETTE, BACK_HEAD, 5, 15)
    return frame


HEAD = _head_stamp()

# The sheet rows, top to bottom: (animation, frames). cat_anim.tres sets the timings.
ROWS = [
    ("walk_left", lambda: [draw_frame(column) for column in range(4)]),
    ("sit", lambda: [sit_frame("down"), sit_frame("up"), sit_frame("curl"), sit_frame("down", EYES_CLOSED)]),
    ("sleep", lambda: [sleep_frame(False), sleep_frame(True)]),
    ("groom", lambda: [groom_frame(pose) for pose in ("lift", "lick", "lick2", "wipe")]),
    ("stretch", lambda: [bow_frame(False), bow_frame(True), stand_frame(True), stand_frame(False)]),
    ("walk_back", lambda: [back_frame(column) for column in range(4)]),
]
COLUMNS = 4


def draw_sheet() -> Image.Image:
    sheet = Image.new("RGBA", (FRAME * COLUMNS, FRAME * len(ROWS)), (0, 0, 0, 0))
    for row, (_name, frames) in enumerate(ROWS):
        for column, frame in enumerate(frames()):
            sheet.alpha_composite(frame, (column * FRAME, row * FRAME))
    return sheet


def write_aseprite_source(png: Path, force: bool) -> None:
    """An editable source with one tag per animation row; an existing one is kept."""
    out = png.with_suffix(".aseprite")
    if out.exists() and not force:
        print(f"kept {out.name} (pass --force-aseprite to redo it)")
        return
    if not ASEPRITE.exists():
        print("Aseprite not found, no .aseprite source written:", ASEPRITE)
        return
    rows = ",".join(f"{name}:{len(frames())}" for name, frames in ROWS)
    subprocess.run([str(ASEPRITE), "-b", "--script-param", f"png={png}", "--script-param", f"out={out}",
                    "--script-param", f"cell={FRAME}", "--script-param", f"rows={rows}",
                    "--script", str(ASEPRITE_SCRIPT)], check=True)
    print(f"wrote {out.name}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="also write an 8x preview")
    parser.add_argument("--force-aseprite", action="store_true")
    args = parser.parse_args()
    sheet = draw_sheet()
    sheet.save(OUT)
    print(f"wrote {OUT.relative_to(ROOT)}")
    write_aseprite_source(OUT, args.force_aseprite)
    if args.preview:
        image = Image.new("RGBA", sheet.size, (40, 36, 48, 255))
        image.alpha_composite(sheet)
        image.resize((image.width * 8, image.height * 8), Image.NEAREST).save(args.preview)


if __name__ == "__main__":
    main()
