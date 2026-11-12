"""Draws Keppihevosratsastaja, the adult hobby-horse rider, and her male version: a black
riding helmet with a peak, a hoodie (her) or a red riding jacket (him), white breeches, tall
black boots with a lighter shaft and Salama, a white stick horse with a grey mane and a
small bridle. Salama's head rises from the hand at chest height, facing out, and the stick
reaches the floor. From behind the horse is in the other hand on the other side, drawn again
with the light still from the upper left, not mirrored. Walking right she rides it: the head
points ahead and the stick runs back between the legs, behind them, to the floor.

The sheet follows the other customers' (see customer_sheet.py): 32 px frames, rows idle,
idle_up, walk_towards and walk_right, light from above left, and a fifth row `bow`: a
dressage salute (upright, bowing, deepest bow, back up) where the rider dips with a hand on
the belly and Salama dips its head too.

    python dev/tools/sprites/make_keppihevosratsastaja.py [--preview out.png] [--force-aseprite]
"""

import argparse
from pathlib import Path

from PIL import Image

from customer_sheet import (BOX_X, FRAME, HANDS_REST, LEGS, RIGHT, ROOT, STILL, TEXTURE_DIR, Held, Look, check,
                            draw_frame, draw_sheet, hex_color, paint)
from make_orveltaja import write_aseprite_source

NAME = "keppihevosratsastaja_32"
MIES_NAME = "keppihevosratsastaja_mies_32"

PALETTE = {
    "s": hex_color("ead4aa"),  # skin
    "t": hex_color("e4a672"),  # skin shade
    "e": hex_color("181425"),  # pupils, Salama's eye
    "W": hex_color("ffffff"),  # eye whites, drawstrings
    "k": hex_color("3e2731"),  # mouth
    "G": hex_color("3a4466"),  # helmet, lit
    "H": hex_color("262b44"),  # helmet
    "h": hex_color("181425"),  # helmet peak and rim
    "Y": hex_color("feae34"),  # blonde hair
    "y": hex_color("b86f50"),  # hair shade
    "P": hex_color("b55088"),  # hoodie
    "p": hex_color("68386c"),  # hoodie shade, hem band, hood
    # Salama
    "A": hex_color("ffffff"),  # head
    "B": hex_color("c0cbdc"),  # head shade
    "m": hex_color("5a6988"),  # mane
    "r": hex_color("e43b44"),  # bridle
    "w": hex_color("c28569"),  # stick
    # Legs: white dressage breeches (beige read as bare skin at 1x), tall boots with a lighter shaft.
    "1": hex_color("ffffff"), "4": hex_color("3a4466"), "2": hex_color("262b44"), "3": hex_color("181425"),
}

HEAD_FRONT = [
    "......GGGHHHHh......",
    ".....GGHHHHHHHh.....",
    "....hhhhhhhhhhhh....",
    ".....YttttttttY.....",
    ".....YsWWssWWty.....",
    ".....YsWestWety.....",
    ".....Ysssttssty.....",
    ".....Yssskksssy.....",
    ".......tsssst.......",
]
HEAD_BACK = [
    "......GGGHHHHh......",
    ".....GGHHHHHHHh.....",
    ".....GHHHHHHHHh.....",
    ".....hhhhhhhhhh.....",
    ".....YYYYYYYYYy.....",
    ".....YYYYYYYYYy.....",
    "......tYYYYYYt......",
    ".......ssYyst.......",
]
# A hoodie: drawstrings at the neck, a ribbed hem band; from behind the hood lies on the back.
TORSO_FRONT = [
    "....PPPPssssPPPp....",
    "...PPPPPWPPWPPPPp...",
    "...PP.PPWPPWPp.Pp...",
    "...PP.PPPPPPPp.Pp...",
    "...PP.PPPPPPPp.Pp...",
    "...PP.PPPPPPPp.Pp...",
    "......PPPPPPPp......",
    "......pppppppp......",
    "......11111111......",
]
TORSO_BACK = [
    "....PPPPPPPPPPPp....",
    "...PPPPpPPPPpPPPp...",
    "...PP.PpPPPPpp.Pp...",
    "...PP.PPppppPp.Pp...",
    "...PP.PPPPPPPp.Pp...",
    "...PP.PPPPPPPp.Pp...",
    "......PPPPPPPp......",
    "......pppppppp......",
    "......11111111......",
]
PONYTAIL = ["Yy", "Yy", "yy"]


def _ponytail(frame: Image.Image, palette: dict, upper: int, back: bool) -> None:
    if back:
        paint(frame, palette, PONYTAIL, BOX_X + 9, upper + 10)


# Him: short brown hair under the helmet, a red riding jacket with dark lapels over a white
# stock tie, the jacket's skirt flaring at the hips with a vent at the back.
MIES_PALETTE = {
    **PALETTE,
    "Y": hex_color("733e39"),  # hair
    "y": hex_color("3e2731"),  # hair shade
    "R": hex_color("a22633"),  # jacket
    "K": hex_color("3e2731"),  # jacket shade, lapels
    "r": hex_color("0099db"),  # bridle
}
MIES_HEAD_FRONT = [
    "......GGGHHHHh......",
    ".....GGHHHHHHHh.....",
    "....hhhhhhhhhhhh....",
    "......tttttttt......",
    "......sWWssWWt......",
    "......sWestWet......",
    "......sssttsst......",
    "......ssskksst......",
    ".......tsssst.......",
]
MIES_HEAD_BACK = [
    "......GGGHHHHh......",
    ".....GGHHHHHHHh.....",
    ".....GHHHHHHHHh.....",
    ".....hhhhhhhhhh.....",
    "......YYYYYYYy......",
    "......YYYYYYYy......",
    "......tYYYYYyt......",
    ".......ssssst.......",
]
MIES_TORSO_FRONT = [
    "....RRRRsWWsRRRK....",
    "...RRRRRKWWKRRRRK...",
    "...RR.RRKWWKRK.RK...",
    "...RR.RRRKKRRK.RK...",
    "...RR.RRRRRRRK.RK...",
    "...RR.RRRRRRRK.RK...",
    "......RRRRRRRK......",
    ".....RRRRRRRRRK.....",
    "......11111111......",
]
MIES_TORSO_BACK = [
    "....RRRRWWWWRRRK....",
    "...RRRRRRRRRRRRRK...",
    "...RR.RRRRRRRK.RK...",
    "...RR.RRRRRRRK.RK...",
    "...RR.RRRRRRRK.RK...",
    "...RR.RRRRRRRK.RK...",
    "......RRRRRRRK......",
    ".....RRRRKRRRRK.....",
    "......11111111......",
]

# Tall boots: the shaft ('4') reaches the knee, lighter than the foot so the boot reads on
# the dark floor. Walking right the shoe's top ('3') becomes the shaft's colour as well.
def _boots(grid: list[str]) -> list[str]:
    return [row.replace("3", "4").replace("8", "6") for row in grid]


LEGS_BOOTS = {name: _boots(LEGS[name]) for name in ("stride_near", "pass_near", "stride_far", "pass_far")}

# Salama facing right, held by the neck: the hand covers the neck's lower rows ('|' marks
# where the hand sits), then the stick goes down to the floor.
HORSE_RIGHT = [
    "...AB...",
    "..mAAA..",
    ".mmAeAA.",
    ".mAAAAAA",
    ".mAArrrA",
    ".mAAB.BB",
    ".mAA....",
    ".mAB....",
]
# Bowing: the head dips and the muzzle points down.
HORSE_RIGHT_DIP = [
    "........",
    "...AB...",
    "..mAAA..",
    ".mmAeAA.",
    ".mAAAAA.",
    ".mAArrA.",
    ".mAA.AB.",
    ".mAB.BB.",
]
HORSE_RIGHT_DEEP = [
    "........",
    "........",
    "..mAB...",
    ".mmAAA..",
    ".mAAeA..",
    ".mAAAAA.",
    ".mAArrA.",
    ".mAB.BB.",
]
# Facing left, in the other hand from behind; the light still comes from the upper left.
HORSE_LEFT = [
    "...AB...",
    "..AAAm..",
    ".AAeAmm.",
    "AAAAAAm.",
    "ArrrAAm.",
    "BB.BAAm.",
    "....AAm.",
    "....ABm.",
]
STICK_FRONT = 8
HAND_ROWS = 2


def _with_stick(head: list[str], column: int, length: int) -> list[str]:
    stick = "." * column + "w" + "." * (len(head[0]) - column - 1)
    return head + [stick] * (HAND_ROWS + length)


# The hand grips the neck: the right-facing head sits with its neck at the hand's columns.
RIGHT_ANCHOR = (-2, -len(HORSE_RIGHT))
LEFT_ANCHOR = (-4, -len(HORSE_LEFT))
HELD_RIGHT = Held(_with_stick(HORSE_RIGHT, 2, STICK_FRONT), RIGHT_ANCHOR, trails=False)
HELD_LEFT = Held(_with_stick(HORSE_LEFT, 5, STICK_FRONT), LEFT_ANCHOR, trails=False)
# Riding right the stick runs back behind the legs to the floor: (dx, dy) from the hand.
RIDE_STICK = [(0, 2), (-1, 3), (-2, 4), (-3, 5), (-4, 6), (-5, 7), (-6, 8), (-7, 9)]


def look(mies: bool = False) -> Look:
    if mies:
        return Look(palette=MIES_PALETTE, head_front=MIES_HEAD_FRONT, head_back=MIES_HEAD_BACK,
                    torso_front=MIES_TORSO_FRONT, torso_back=MIES_TORSO_BACK, hand_inset=1,
                    legs=LEGS_BOOTS, held=(None, HELD_RIGHT))
    return Look(palette=PALETTE, head_front=HEAD_FRONT, head_back=HEAD_BACK, torso_front=TORSO_FRONT,
                torso_back=TORSO_BACK, hand_inset=1, legs=LEGS_BOOTS, held=(None, HELD_RIGHT), extra=_ponytail)


def _clear_row(sheet: Image.Image, row: int) -> None:
    sheet.paste((0, 0, 0, 0), (0, FRAME * row, FRAME * 4, FRAME * (row + 1)))


def draw_back_row(sheet: Image.Image, front: Look, mies: bool) -> None:
    """From behind Salama is in the hand on the left, facing left."""
    back = look(mies)
    back.palette = front.palette
    back.held = (HELD_LEFT, None)
    check(back)
    _clear_row(sheet, 1)
    for column, bob in enumerate((0, -1, 0)):
        draw_frame(sheet, back, column, 1, back=True, bob=bob, legs="stand", hands=HANDS_REST, trail=STILL)


def draw_ride_row(sheet: Image.Image, front: Look, mies: bool) -> None:
    """Walking right: the stick is painted first so the legs cover it."""
    ride = look(mies)
    ride.palette = front.palette
    ride.held = (None, Held(HORSE_RIGHT, RIGHT_ANCHOR, trails=False))
    _clear_row(sheet, 3)
    hand_x = BOX_X + HANDS_REST[1][0] - ride.hand_inset
    for column, (legs, bob, hands, _trail) in enumerate(RIGHT):
        hand_y = 4 + bob + HANDS_REST[1][1]
        for dx, dy in RIDE_STICK:
            sheet.putpixel((column * FRAME + hand_x + dx, 3 * FRAME + hand_y + dy), ride.palette["w"])
        draw_frame(sheet, ride, column, 3, back=False, bob=bob, legs=legs, hands=hands, trail=STILL)


def _bow_torso(torso: list[str]) -> list[str]:
    """The left arm bends in: the forearm crosses to the belly, where the hand rests."""
    rows = list(torso)
    main = rows[3][3]
    for index in (4, 5):
        rows[index] = rows[index][:3] + "." + main + main + rows[index][6:]
    return rows


BOW_HAND = ["st", "st"]


def draw_bow_row(sheet: Image.Image, front: Look, mies: bool) -> None:
    poses = ((0, HORSE_RIGHT, False), (1, HORSE_RIGHT_DIP, True), (2, HORSE_RIGHT_DEEP, True),
             (1, HORSE_RIGHT_DIP, True))
    for column, (bob, horse, hand_in) in enumerate(poses):
        bow = look(mies)
        bow.palette = front.palette
        bow.held = (None, Held(_with_stick(horse, 2, STICK_FRONT - bob), RIGHT_ANCHOR, trails=False))
        if not hand_in:
            draw_frame(sheet, bow, column, 4, back=False, bob=bob, legs="stand", hands=HANDS_REST, trail=STILL)
            continue
        draw_frame(sheet, bow, column, 4, back=False, bob=bob, legs="stand", hands=(None, HANDS_REST[1]),
                   trail=STILL, torso=_bow_torso(bow.torso_front),
                   extra=lambda frame, palette, upper: paint(frame, palette, BOW_HAND, BOX_X + 6, upper + 14))


def build(mies: bool = False) -> Image.Image:
    front = look(mies)
    sheet = draw_sheet(front, extra_rows=1)
    draw_back_row(sheet, front, mies)
    draw_ride_row(sheet, front, mies)
    draw_bow_row(sheet, front, mies)
    return sheet


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="also write a 6x preview beside normaali_mies")
    parser.add_argument("--force-aseprite", action="store_true")
    args = parser.parse_args()
    sheets = {NAME: build(), MIES_NAME: build(True)}
    for name, sheet in sheets.items():
        path = TEXTURE_DIR / f"{name}.png"
        sheet.save(path)
        print(f"wrote {path.relative_to(ROOT)}")
        write_aseprite_source(path, args.force_aseprite)
    if args.preview:
        normal = Image.open(TEXTURE_DIR / "normaali_mies_32.png").convert("RGBA")
        image = Image.new("RGBA", (FRAME * 9, FRAME * 5), (40, 36, 48, 255))
        for index, sheet in enumerate(sheets.values()):
            image.alpha_composite(sheet, (FRAME * 4 * index, 0))
        image.alpha_composite(normal.crop((0, 0, FRAME, FRAME)), (FRAME * 8, 0))
        image.resize((image.width * 6, image.height * 6), Image.NEAREST).save(args.preview)


if __name__ == "__main__":
    main()
