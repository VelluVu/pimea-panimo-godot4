"""Draws the Kyborgi customer: an AI humanoid from Cyber Week, a white and chrome body with
a dark visor, two glowing cyan eyes, an antenna light, a grille for a mouth and a cyan core
in the chest. It drinks Tekoälyolut, the beer any recipe becomes with a Kehote.

The sheet follows the other customers': 128x128, 32 px frames, rows idle (3 frames),
idle_up (3), walk_towards (4) and walk_right (4); a figure about 16x24 px with a big head,
no black outline, and the ENDESGA 32 colours the rest of the cast uses. Light comes from
above left: the white edge is on the left, the shade on the right. Idle, the eyes glance
aside and the antenna light blinks, so it reads as a machine thinking.

Each frame is put together from parts drawn as character grids, so the head, body and legs
stay the same between frames. The grids are in a 20x27 box at (6, 4) in the frame, the
same box the other sheets use.

    python dev/tools/sprites/make_kyborgi.py [--preview out.png]
"""

import argparse
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
TEXTURE_DIR = ROOT / "assets/textures/characters"
FRAME = 32
BOX_X, BOX_Y = 6, 4
GRID_WIDTH = 20


def _hex(value: str) -> tuple[int, int, int, int]:
    return (int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16), 255)


PALETTE = {
    "W": _hex("ffffff"),  # lit edge
    "S": _hex("c0cbdc"),  # shell
    "g": _hex("8b9bb4"),  # shell shade
    "d": _hex("5a6988"),  # joints, seams
    "k": _hex("262b44"),  # soles, grille gaps
    "C": _hex("2ce8f5"),  # glow: eyes, core, antenna
    "b": _hex("0099db"),  # dimmed glow
    "v": _hex("124e89"),  # visor
    "s": _hex("ead4aa"),  # skin, the human half of the face
    "t": _hex("e4a672"),  # skin shade
}

# Rows 1-9 of the box: the antenna, a rounded chrome head lit at its top left, the visor
# with the eyes, and a face half human, half plate: skin on the left, a seam, chrome on the
# right. The eyes sit on the same rows as the other customers'. At the back, a data port
# sits by the ear, off the middle, so the back of the head does not read as a face.
HEAD_FRONT = [
    ".........C..........",
    ".........g..........",
    ".......WWSSSg.......",
    "......WSSSSSSg......",
    ".....WSSSSSSSSg.....",
    ".....vvvvvvvvvv.....",
    ".....vCCvvvvCCv.....",
    ".....WssssdSSSg.....",
    "......sstdSSSg......",
]
HEAD_BACK = [
    ".........C..........",
    ".........g..........",
    ".......WWSSSg.......",
    "......WSSSSSSg......",
    ".....WSSSSSSSSg.....",
    ".....WSSSSSSSSg.....",
    ".....WSSSSSSddg.....",
    ".....WSSSSSSdbg.....",
    "......sssSSSSg......",
]
# Idle: the eyes glance one pixel aside, and the antenna light dims between blinks.
EYES_GLANCE = ".....vvCCvvvCCv....."
ANTENNA_DIM = ".........b.........."

# Rows 10-18: neck joint, shoulders, the glowing core, arms down to the elbow joints, the
# waist joint and the hips. A panel seam on each side breaks up the white.
TORSO_FRONT = [
    "........dddd........",
    "....WSSSSSSSSSSg....",
    "...WSSSSSCCSSSSgg...",
    "..WSWSSSSbbSSSSgdg..",
    "..Sg.WSdSSSSdSg.gd..",
    "..Sg.WSdSSSSdSg.gd..",
    "..dd.WSSSSSSSSg.dd..",
    ".....dddddddddd.....",
    ".....WSSSSSSSSg.....",
]
TORSO_BACK = [
    "........dddd........",
    "....WSSSSSSSSSSg....",
    "...WSSSSSSSSSSSgg...",
    "..WSWSSSddSSSSSgdg..",
    "..Sg.WSSddSSSSg.gd..",
    "..Sg.WSSSSSSSSg.gd..",
    "..dd.WSSSSSSSSg.dd..",
    ".....dddddddddd.....",
    ".....WSSSSSSSSg.....",
]

# Rows 19-25 for each leg pose, the shells' shade on the right leg.
LEGS = {
    "stand": [
        "......SSSggggg......",
        "......SSg..Sgg......",
        "......ddd..ddd......",
        "......SSg..Sgg......",
        "......SSg..Sgg......",
        "......ddd..ddd......",
        "......kkk..kkk......",
    ],
    # Walking towards: one foot lifted (it ends two rows higher).
    "lift_left": [
        "......SSSggggg......",
        "......SSg..Sgg......",
        "......ddd..ddd......",
        "......SSg..Sgg......",
        "......kkk..Sgg......",
        "...........ddd......",
        "...........kkk......",
    ],
    "lift_right": [
        "......SSSggggg......",
        "......SSg..Sgg......",
        "......ddd..ddd......",
        "......SSg..Sgg......",
        "......SSg..kkk......",
        "......ddd...........",
        "......kkk...........",
    ],
    # Walking right: legs apart, the feet point right.
    "stride": [
        "......SSSggggg......",
        ".....SSSg..Sggg.....",
        "....ddd......ddd....",
        "....SSg......Sgg....",
        "...SSSg......SSgg...",
        "...dddd......ddddd..",
        "...kkkk......kkkkk..",
    ],
    "pass": [
        "......SSSggggg......",
        "......SSSggggg......",
        ".......dddddd.......",
        ".......SSSggg.......",
        ".......SSSSggg......",
        ".......dddddddd.....",
        ".......kkkkkkk......",
    ],
}

HAND = ["Sg", "dd"]


def _check_grids() -> None:
    grids = [HEAD_FRONT, HEAD_BACK, TORSO_FRONT, TORSO_BACK, [EYES_GLANCE, ANTENNA_DIM], *LEGS.values()]
    for grid in grids:
        for row in grid:
            assert len(row) == GRID_WIDTH, f"grid row is {len(row)} wide: {row!r}"


def _paint(image: Image.Image, rows: list[str], left: int, top: int) -> None:
    for dy, row in enumerate(rows):
        for dx, char in enumerate(row):
            if char == ".":
                continue
            x, y = left + dx, top + dy
            if 0 <= x < image.width and 0 <= y < image.height:
                image.putpixel((x, y), PALETTE[char])


def _frame(sheet: Image.Image, column: int, row: int, *, back: bool, bob: int, legs: str,
           hands: tuple[tuple[int, int], tuple[int, int]], glance: bool = False, dim: bool = False) -> None:
    frame = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
    upper = BOX_Y + bob
    _paint(frame, LEGS[legs], BOX_X, BOX_Y + 19)
    # The feet stay on the floor when the body rises: the hips stretch up with it, so no
    # empty row opens between the body and the legs.
    for gap_row in range(bob, 0):
        _paint(frame, LEGS[legs][:1], BOX_X, BOX_Y + 19 + gap_row)
    _paint(frame, TORSO_BACK if back else TORSO_FRONT, BOX_X, upper + 10)
    head = list(HEAD_BACK if back else HEAD_FRONT)
    if glance and not back:
        head[6] = EYES_GLANCE
    if dim:
        head[0] = ANTENNA_DIM
    _paint(frame, head, BOX_X, upper + 1)
    for hand_x, hand_y in hands:
        _paint(frame, HAND, BOX_X + hand_x, upper + hand_y)
    sheet.alpha_composite(frame, (column * FRAME, row * FRAME))


# Hands at rest below the elbow joints.
HANDS_REST = ((2, 17), (16, 17))


def draw() -> Image.Image:
    _check_grids()
    sheet = Image.new("RGBA", (FRAME * 4, FRAME * 4), (0, 0, 0, 0))
    # idle: a breath-like hum, the eyes glance aside on the last frame, the light blinks.
    idle = [(0, False, False), (-1, False, True), (0, True, False)]
    for column, (bob, glance, dim) in enumerate(idle):
        _frame(sheet, column, 0, back=False, bob=bob, legs="stand", hands=HANDS_REST, glance=glance, dim=dim)
    for column, (bob, _glance, dim) in enumerate(idle):
        _frame(sheet, column, 1, back=True, bob=bob, legs="stand", hands=HANDS_REST, dim=dim)
    # walk_towards: the body rises on the lifted-foot frames, the arm on that side swings
    # forward (its hand one row up and out).
    towards = [
        ("stand", 0, HANDS_REST),
        ("lift_left", -1, ((1, 16), (16, 17))),
        ("stand", 0, HANDS_REST),
        ("lift_right", -1, ((2, 17), (17, 16))),
    ]
    for column, (legs, bob, hands) in enumerate(towards):
        _frame(sheet, column, 2, back=False, bob=bob, legs=legs, hands=hands)
    right = [
        ("stride", 0, HANDS_REST),
        ("pass", -1, HANDS_REST),
        ("stride", 0, HANDS_REST),
        ("pass", -1, HANDS_REST),
    ]
    for column, (legs, bob, hands) in enumerate(right):
        _frame(sheet, column, 3, back=False, bob=bob, legs=legs, hands=hands)
    return sheet


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="also write a 4x preview of the sheet here")
    args = parser.parse_args()
    sheet = draw()
    path = TEXTURE_DIR / "kyborgi_32.png"
    sheet.save(path)
    print(f"wrote {path.relative_to(ROOT)}")
    if args.preview:
        preview = Image.new("RGBA", (FRAME * 4, FRAME * 4), (40, 36, 48, 255))
        preview.alpha_composite(sheet, (0, 0))
        preview.resize((preview.width * 6, preview.height * 6), Image.NEAREST).save(args.preview)


if __name__ == "__main__":
    main()
