"""Draws the Tarjoushaukka customers (the Black Friday bargain hunter, male and female):
a puffer coat, a knit beanie and a shopping bag in each hand, and the look of someone who
barely got out of the Black Friday crowd: wild eyes, a black eye, a grin, a torn coat with
the stuffing out, and blood dripping on the floor.

The sheets follow the other customers': 128x128, 32 px frames, rows idle (3 frames),
idle_up (3), walk_towards (4) and walk_right (4); a figure about 16x24 px with a big head,
no black outline, and the ENDESGA 32 colours the rest of the cast uses. Light comes from
above left. The bags are the silhouette: they widen the figure at the bottom and swing a
frame behind the hands when walking.

Each frame is put together from parts drawn as character grids, so the head, coat and legs
stay the same between frames. The grids are in a 20x27 box at (6, 4) in the frame, the
same box the other sheets use.

    python dev/tools/sprites/make_tarjoushaukka.py [--preview out.png]
"""

import argparse
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
TEXTURE_DIR = ROOT / "assets/textures/characters"
FRAME = 32
BOX_X, BOX_Y = 6, 4


def _hex(value: str) -> tuple[int, int, int, int]:
    return (int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16), 255)


# Shared by both: skin, eyes, bags, boots. 'k' is the darkest outline-like tone.
BASE_PALETTE = {
    "s": _hex("ead4aa"),  # skin
    "t": _hex("e4a672"),  # skin shade
    "w": _hex("ffffff"),  # eye white, pompom
    "e": _hex("3a4466"),  # pupil
    "k": _hex("181425"),  # bag handles, soles
    "Y": _hex("fee761"),  # yellow bag
    "y": _hex("feae34"),  # yellow bag shade
    "P": _hex("f6757a"),  # pink bag
    "p": _hex("b55088"),  # pink bag shade
    "n": _hex("262b44"),  # trousers
    "N": _hex("181425"),  # trousers, the far leg walking right
    "B": _hex("733e39"),  # boots, his hair
    "b": _hex("3e2731"),  # boots, the far leg walking right
    "X": _hex("a22633"),  # blood
    "v": _hex("68386c"),  # bruise
}

# The coat and beanie change between him and her; everything else is shared.
LOOKS = {
    "male": {
        "Q": _hex("f6757a"), "R": _hex("e43b44"), "r": _hex("a22633"),  # beanie
        "O": _hex("f77622"),  # scarf
        "H": _hex("8b9bb4"), "C": _hex("5a6988"), "c": _hex("3a4466"),  # puffer coat
        "z": _hex("262b44"),  # zip
        "a": _hex("733e39"),  # hair
    },
    "female": {
        "Q": _hex("2ce8f5"), "R": _hex("0099db"), "r": _hex("124e89"),  # beanie
        "O": _hex("feae34"),  # scarf
        "H": _hex("f6757a"), "C": _hex("b55088"), "c": _hex("68386c"),  # puffer coat
        "z": _hex("3e2731"),  # zip
        "a": _hex("b86f50"),  # hair
    },
}

# Rows 1-9 of the box. The beanie covers the hair rows the other customers have, so the
# eyes sit on the same row as theirs. Its top left catches the lamp. The pupils look two
# ways, one eye is blackened, and blood runs from the corner of a tight grin.
HEAD_FRONT = [
    "........ww..........",
    ".......QQRRRR.......",
    "......QRRRRRRr......",
    ".....QRRRRRRRRr.....",
    ".....rrrrrrrrrr.....",
    ".....swwsssswwv.....",
    ".....sewsttsewv.....",
    ".....sstkwwktsv.....",
    ".......ssssXs.......",
]
HEAD_BACK = [
    "........ww..........",
    ".......QQRRRR.......",
    "......QRRRRRRr......",
    ".....QRRRRRRRRr.....",
    ".....rrrrrrrrrr.....",
    ".....saaaaaaaas.....",
    ".....ssaaaaaass.....",
    "......ssaaaass......",
    ".......ssssss.......",
]
# Her hair falls from under the beanie past the cheeks onto the shoulders, like the other
# women's.
HAIR_FRONT_FEMALE = [
    "....................",
    "....................",
    "....................",
    "....................",
    "....................",
    ".....a........a.....",
    ".....a........a.....",
    ".....aa......aa.....",
    ".....aa......aa.....",
    "....aa........aa....",
    "....a..........a....",
]
HAIR_BACK_FEMALE = [
    "....................",
    "....................",
    "....................",
    "....................",
    "....................",
    ".....aaaaaaaaaa.....",
    ".....aaaaaaaaaa.....",
    ".....aaaaaaaaaa.....",
    "......aaaaaaaa......",
    ".......aaaaaa.......",
    ".......aaaaaa.......",
    "........aaaa........",
]

# Rows 10-18: scarf, puffer coat, arms down to the elbow. Two quilt seams make it a puffer;
# they break off on the lit left side, so the bulges there catch the light instead of
# reading as stripes. A tear shows the white stuffing, with blood stains around it. The
# hands are drawn separately (_arm).
TORSO_FRONT = [
    ".....OOOOOOOOOO.....",
    "....HCCCCzOCCCcc....",
    "...HHCCXCzOCCCccc...",
    "..HHCCcccccccccccc..",
    "..HC.HCCCzCCwwc.cc..",
    "..HC.HCCCzCwCXc.cc..",
    "..Hc.HCcccccccc.cc..",
    ".....HXCCzCCCCc.....",
    ".....HCCCzCCCCc.....",
]
TORSO_BACK = [
    ".....OOOOOOOOOO.....",
    "....HCCCCCCCCCcc....",
    "...HHCCCCCCCCCccc...",
    "..HHCCcccccccccccc..",
    "..HC.HCwwCCCCCc.cc..",
    "..HC.HCCwCCCCCc.cc..",
    "..Hc.HCcccccccc.cc..",
    ".....HCCCCCCXCc.....",
    ".....HCCCCCCCCc.....",
]

# Rows 19-25 for each leg pose.
LEGS = {
    "stand": [
        "......nnnnnnnn......",
        "......nnn..nnn......",
        "......nnn..nnn......",
        "......nnn..nnn......",
        "......BBB..BBB......",
        "......BBB..BBB......",
        "......kkk..kkk......",
    ],
    # Walking towards: one foot lifted (it ends two rows higher).
    "lift_left": [
        "......nnnnnnnn......",
        "......nnn..nnn......",
        "......BBB..nnn......",
        "......BBB..nnn......",
        "......kkk..BBB......",
        "...........BBB......",
        "...........kkk......",
    ],
    "lift_right": [
        "......nnnnnnnn......",
        "......nnn..nnn......",
        "......nnn..BBB......",
        "......nnn..BBB......",
        "......BBB..kkk......",
        "......BBB...........",
        "......kkk...........",
    ],
    # Walking right, a four-frame cycle: a reach with the near leg forward, a pass where the
    # near leg takes the weight and the far one swings by it, a reach with the far leg
    # forward, and a pass the other way round. The far leg is darker (N, b), so the legs
    # read apart; the boots point right.
    "stride_near": [
        "......nnnnnnnn......",
        ".....NNNN..nnnn.....",
        "....NNNN....nnnn....",
        "....NNN......nnn....",
        "...bbbb......BBBB...",
        "...bbbb......BBBBB..",
        "...kkkk......kkkkk..",
    ],
    "pass_near": [
        "......nnnnnnnn......",
        ".......nnnNNNN......",
        ".......nnnNNNNN.....",
        ".......nnn.bbbb.....",
        ".......BBB.kkkk.....",
        ".......BBBB.........",
        ".......kkkk.........",
    ],
    "stride_far": [
        "......nnnnnnnn......",
        ".....nnnn..NNNN.....",
        "....nnnn....NNNN....",
        "....nnn......NNN....",
        "...BBBB......bbbb...",
        "...BBBB......bbbbb..",
        "...kkkk......kkkkk..",
    ],
    "pass_far": [
        "......nnnnnnnn......",
        ".......NNNnnnn......",
        ".......NNNnnnnn.....",
        ".......NNN.BBBB.....",
        ".......bbb.kkkk.....",
        ".......bbbb.........",
        ".......kkkk.........",
    ],
}

BAG_YELLOW = [
    "..k.",
    "YYYy",
    "YYYy",
    "RRRr",
    "YYYy",
    "yyyy",
]
BAG_PINK = [
    ".k..",
    "PPPp",
    "PPPp",
    "wwwp",
    "PPPp",
    "pppp",
]


def _paint(image: Image.Image, palette: dict, rows: list[str], left: int, top: int) -> None:
    for dy, row in enumerate(rows):
        for dx, char in enumerate(row):
            if char == ".":
                continue
            x, y = left + dx, top + dy
            if 0 <= x < image.width and 0 <= y < image.height:
                image.putpixel((x, y), palette[char])


def _arm(image: Image.Image, palette: dict, left: int, top: int, hand_x: int, hand_y: int) -> None:
    """A hand (two pixels, skin and shade) at box column hand_x, rows hand_y and below."""
    _paint(image, palette, ["st", "st"], left + hand_x, top + hand_y)


def _frame(sheet: Image.Image, palette: dict, column: int, row: int, *, back: bool, female: bool,
           bob: int, legs: str, hands: tuple[tuple[int, int], tuple[int, int]],
           bags: tuple[tuple[int, int], tuple[int, int]], drops: tuple[tuple[int, int], ...] = ()) -> None:
    frame = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
    upper = BOX_Y + bob
    if female and back:
        _paint(frame, palette, HAIR_BACK_FEMALE, BOX_X, upper + 1)
    _paint(frame, palette, LEGS[legs], BOX_X, BOX_Y + 19)
    # The feet stay on the floor when the body rises: the waistband stretches up with it,
    # so no empty row opens between the coat and the legs.
    for gap_row in range(bob, 0):
        _paint(frame, palette, LEGS[legs][:1], BOX_X, BOX_Y + 19 + gap_row)
    _paint(frame, palette, TORSO_BACK if back else TORSO_FRONT, BOX_X, upper + 10)
    _paint(frame, palette, HEAD_BACK if back else HEAD_FRONT, BOX_X, upper + 1)
    if female and not back:
        _paint(frame, palette, HAIR_FRONT_FEMALE, BOX_X, upper + 1)
    if female and back:
        # The hair falls over the scarf at the back.
        _paint(frame, palette, HAIR_BACK_FEMALE[5:], BOX_X, upper + 6)
    for (hand_x, hand_y), (bag_x, bag_y), bag in zip(hands, bags, (BAG_YELLOW, BAG_PINK)):
        # The bags hang from the hands, so they rise and fall with the body.
        _paint(frame, palette, bag, BOX_X + bag_x, upper + bag_y)
        _arm(frame, palette, BOX_X, upper, hand_x, hand_y)
    for drop_x, drop_y in drops:
        frame.putpixel((BOX_X + drop_x, BOX_Y + drop_y), palette["X"])
    sheet.alpha_composite(frame, (column * FRAME, row * FRAME))


# Hands at rest by the coat hem; bags hang from them.
HANDS_REST = ((2, 16), (16, 16))
BAGS_REST = ((1, 17), (15, 17))
# Standing, blood has dripped on the floor by the boots. Walking, a drop falls from under
# the pink bag, one row a frame.
FLOOR_DROPS = ((4, 25), (5, 25), (17, 24), (18, 25))
FALLING_DROP_ROWS = (23, 24, 25, None)


def _falling_drop(column: int, bags: tuple[tuple[int, int], tuple[int, int]]) -> tuple[tuple[int, int], ...]:
    row = FALLING_DROP_ROWS[column]
    if row is None:
        return ()
    pink_x = bags[1][0]
    return ((pink_x + 2, row),)


def draw(look: str) -> Image.Image:
    palette = {**BASE_PALETTE, **LOOKS[look]}
    female = look == "female"
    sheet = Image.new("RGBA", (FRAME * 4, FRAME * 4), (0, 0, 0, 0))
    # idle: a breath every few frames, the bags still.
    for column, bob in enumerate((0, -1, 0)):
        _frame(sheet, palette, column, 0, back=False, female=female, bob=bob, legs="stand",
               hands=HANDS_REST, bags=BAGS_REST, drops=FLOOR_DROPS)
    for column, bob in enumerate((0, -1, 0)):
        _frame(sheet, palette, column, 1, back=True, female=female, bob=bob, legs="stand",
               hands=HANDS_REST, bags=BAGS_REST, drops=FLOOR_DROPS)
    # walk_towards: the body rises on the lifted-foot frames; the arm on the lifted side
    # swings forward (its hand one row up and out), and its bag trails a pixel behind.
    towards = [
        ("stand", 0, HANDS_REST, BAGS_REST),
        ("lift_left", -1, ((1, 15), (16, 17)), ((1, 17), (15, 18))),
        ("stand", 0, HANDS_REST, BAGS_REST),
        ("lift_right", -1, ((2, 17), (17, 15)), ((1, 18), (15, 17))),
    ]
    for column, (legs, bob, hands, bags) in enumerate(towards):
        _frame(sheet, palette, column, 2, back=False, female=female, bob=bob, legs=legs,
               hands=hands, bags=bags, drops=_falling_drop(column, bags))
    # walk_right: the bags swing left, behind the step, on the stride frames.
    right = [
        ("stride_near", 0, ((2, 16), (16, 16)), ((0, 17), (14, 17))),
        ("pass_near", -1, HANDS_REST, BAGS_REST),
        ("stride_far", 0, ((2, 16), (16, 16)), ((0, 17), (14, 17))),
        ("pass_far", -1, HANDS_REST, BAGS_REST),
    ]
    for column, (legs, bob, hands, bags) in enumerate(right):
        _frame(sheet, palette, column, 3, back=False, female=female, bob=bob, legs=legs,
               hands=hands, bags=bags, drops=_falling_drop(column, bags))
    return sheet


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="also write a 4x preview of both sheets here")
    args = parser.parse_args()
    sheets = {}
    for look, name in (("male", "tarjoushaukka_32"), ("female", "tarjoushaukka_naaras_32")):
        sheets[look] = draw(look)
        path = TEXTURE_DIR / f"{name}.png"
        sheets[look].save(path)
        print(f"wrote {path.relative_to(ROOT)}")
    if args.preview:
        preview = Image.new("RGBA", (FRAME * 8, FRAME * 4), (40, 36, 48, 255))
        preview.alpha_composite(sheets["male"], (0, 0))
        preview.alpha_composite(sheets["female"], (FRAME * 4, 0))
        preview.resize((preview.width * 4, preview.height * 4), Image.NEAREST).save(args.preview)


if __name__ == "__main__":
    main()
