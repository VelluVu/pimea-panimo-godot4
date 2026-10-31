"""Shared frame assembly for the customer sheets drawn in code (make_amparihamstraaja.py,
make_snobi.py, make_persuasiakas.py, make_presidentti.py).

The sheets follow the other customers': 128x128, 32 px frames, rows idle (3 frames),
idle_up (3), walk_towards (4) and walk_right (4); a figure about 16x24 px with a big head,
no black outline, ENDESGA 32 colours, light from above left. Each frame is put together
from parts drawn as character grids in a 20x27 box at (6, 4) in the frame, so the head,
torso and legs stay the same between frames.

A Look gives the grids and the palette. Heads end on box row 9 (a top hat may reach above),
torsos take rows 10-18 and legs rows 19-25; a Look's `lift` raises the head and torso that
many rows and lengthens the legs to match, for a taller customer. The leg grids use '1'
(thigh), '4' (shin), '2' (shoe or boot) and '3' (sole), so a look maps them to trousers,
bare legs or paws. Walking right, the far leg is '5', '6', '7' and '8': the same colours
darkened toward the palette's darkest (see far_leg_colors), so the legs read apart.
"""

from dataclasses import dataclass, field
from pathlib import Path
from typing import Callable, Optional

from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
TEXTURE_DIR = ROOT / "assets/textures/characters"
FRAME = 32
BOX_X, BOX_Y = 6, 4
BOX_WIDTH = 20
HEAD_LAST_ROW = 9
TORSO_TOP = 10
LEGS_TOP = 19


def hex_color(value: str) -> tuple[int, int, int, int]:
    return (int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16), 255)


LEGS = {
    "stand": [
        "......11111111......",
        "......111..111......",
        "......444..444......",
        "......444..444......",
        "......222..222......",
        "......222..222......",
        "......333..333......",
    ],
    # Walking towards: one foot lifted (it ends two rows higher).
    "lift_left": [
        "......11111111......",
        "......111..111......",
        "......222..444......",
        "......222..444......",
        "......333..222......",
        "...........222......",
        "...........333......",
    ],
    "lift_right": [
        "......11111111......",
        "......111..111......",
        "......444..222......",
        "......444..222......",
        "......222..333......",
        "......222...........",
        "......333...........",
    ],
    # Walking right, a four-frame cycle: a reach with the near leg forward, a pass where the
    # near leg takes the weight and the far one swings by it, a reach with the far leg
    # forward, and a pass the other way round. The feet point right.
    "stride_near": [
        "......11111111......",
        ".....5555..1111.....",
        "....6666....4444....",
        "....666......444....",
        "...7777......2222...",
        "...7777......22222..",
        "...8888......33333..",
    ],
    "pass_near": [
        "......11111111......",
        ".......1115555......",
        ".......44466666.....",
        ".......444.7777.....",
        ".......222.8888.....",
        ".......2222.........",
        ".......3333.........",
    ],
    "stride_far": [
        "......11111111......",
        ".....1111..5555.....",
        "....4444....6666....",
        "....444......666....",
        "...2222......7777...",
        "...2222......77777..",
        "...3333......88888..",
    ],
    "pass_far": [
        "......11111111......",
        ".......5551111......",
        ".......66644444.....",
        ".......666.2222.....",
        ".......777.3333.....",
        ".......7777.........",
        ".......8888.........",
    ],
}
# The far leg's letters and the near-leg letters they darken.
FAR_LEG = {"5": "1", "6": "4", "7": "2", "8": "3"}
FAR_LEG_SHADE = (24, 20, 37)
FAR_LEG_DARKENING = 0.35


def far_leg_colors(palette: dict) -> dict:
    """The far leg's colours, unless the look gives its own: each near-leg colour moved a
    third of the way to the palette's darkest, a cool purple, so the shade shifts cool."""
    colors = {}
    for far, near in FAR_LEG.items():
        if far in palette:
            continue
        r, g, b, a = palette[near]
        colors[far] = tuple(round(c + (shade - c) * FAR_LEG_DARKENING) for c, shade in zip((r, g, b), FAR_LEG_SHADE)) + (a,)
    return colors

Hands = tuple[Optional[tuple[int, int]], Optional[tuple[int, int]]]
# Hands at rest by the hem. Walking towards, the arm on the lifted side swings forward (its
# hand one row up and out); walking right the hands stay and the held things trail behind.
HANDS_REST: Hands = ((2, 16), (16, 16))
# The trail is each hand's (dx, dy) for what it carries, a pixel behind the swing.
Trail = tuple[tuple[int, int], tuple[int, int]]
STILL: Trail = ((0, 0), (0, 0))
TOWARDS = [
    ("stand", 0, HANDS_REST, STILL),
    ("lift_left", -1, ((1, 15), (16, 17)), ((1, 1), (0, 0))),
    ("stand", 0, HANDS_REST, STILL),
    ("lift_right", -1, ((2, 17), (17, 15)), ((0, 0), (-1, 1))),
]
RIGHT = [
    ("stride_near", 0, HANDS_REST, ((-1, 0), (-1, 0))),
    ("pass_near", -1, HANDS_REST, STILL),
    ("stride_far", 0, HANDS_REST, ((-1, 0), (-1, 0))),
    ("pass_far", -1, HANDS_REST, STILL),
]


@dataclass
class Held:
    """Something carried in one hand, drawn under the hand. `anchor` is the grid's top left
    relative to the hand. `trails`: it hangs and lags a pixel behind the swing when walking
    (a bucket); a cane is gripped and moves with the hand."""
    rows: list[str]
    anchor: tuple[int, int]
    trails: bool = True


@dataclass
class Look:
    palette: dict
    head_front: list[str]
    head_back: list[str]
    torso_front: list[str]
    torso_back: list[str]
    hand: list[str] = field(default_factory=lambda: ["st", "st"])
    lift: int = 0
    held: tuple[Optional[Held], Optional[Held]] = (None, None)
    # Drawn last in each frame, for anything the grids cannot hold. Gets (frame, palette, upper, back).
    extra: Optional[Callable[[Image.Image, dict, int, bool], None]] = None


def paint(image: Image.Image, palette: dict, rows: list[str], left: int, top: int) -> None:
    for dy, row in enumerate(rows):
        for dx, char in enumerate(row):
            if char == ".":
                continue
            x, y = left + dx, top + dy
            if 0 <= x < image.width and 0 <= y < image.height:
                image.putpixel((x, y), palette[char])


def check(look: Look) -> None:
    """Every grid row is the box width and every letter has a colour."""
    grids = [look.head_front, look.head_back, look.torso_front, look.torso_back, *LEGS.values()]
    for grid in grids:
        for row in grid:
            assert len(row) == BOX_WIDTH, f"row is {len(row)} wide: {row!r}"
    for grid in grids + [look.hand] + [held.rows for held in look.held if held]:
        for row in grid:
            for char in row:
                assert char == "." or char in look.palette, f"no colour for {char!r} in {row!r}"


def draw_frame(sheet: Image.Image, look: Look, column: int, row: int, *, back: bool, bob: int,
               legs: str, hands: Hands, trail: Trail = STILL, torso: Optional[list[str]] = None,
               head: Optional[list[str]] = None,
               extra: Optional[Callable[[Image.Image, dict, int], None]] = None) -> None:
    """One frame into the sheet. `torso` and `head` replace the look's grids (an action pose),
    a None hand is left out (that arm is drawn by `extra`), and `extra` paints last, with
    (frame, palette, upper) where upper is the frame row of box row 0."""
    frame = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
    upper = BOX_Y + bob - look.lift
    leg_rows = _lengthened(LEGS[legs], look.lift)
    legs_top = BOX_Y + LEGS_TOP - look.lift
    paint(frame, look.palette, leg_rows, BOX_X, legs_top)
    # The feet stay on the floor when the body rises: the waist stretches up with it, so no
    # empty row opens between the torso and the legs.
    for gap_row in range(bob, 0):
        paint(frame, look.palette, leg_rows[:1], BOX_X, legs_top + gap_row)
    if torso is None:
        torso = look.torso_back if back else look.torso_front
    paint(frame, look.palette, torso, BOX_X, upper + TORSO_TOP)
    if head is None:
        head = look.head_back if back else look.head_front
    paint(frame, look.palette, head, BOX_X, upper + HEAD_LAST_ROW + 1 - len(head))
    for hand, held, side_trail in zip(hands, look.held, trail):
        if hand is None:
            continue
        hand_x, hand_y = hand
        if held is not None:
            shift_x, shift_y = side_trail if held.trails else (0, 0)
            paint(frame, look.palette, held.rows, BOX_X + hand_x + held.anchor[0] + shift_x,
                  upper + hand_y + held.anchor[1] + shift_y)
        paint(frame, look.palette, look.hand, BOX_X + hand_x, upper + hand_y)
    if look.extra is not None:
        look.extra(frame, look.palette, upper, back)
    if extra is not None:
        extra(frame, look.palette, upper)
    sheet.alpha_composite(frame, (column * FRAME, row * FRAME))


def _lengthened(rows: list[str], lift: int) -> list[str]:
    """Longer legs: the upper leg row again, in the shin colour so shorts stay short."""
    return rows[:2] + [rows[1].replace("1", "4").replace("5", "6")] * lift + rows[2:]


def draw_sheet(look: Look, extra_rows: int = 0) -> Image.Image:
    """The four standard rows; `extra_rows` leaves that many empty rows below for actions."""
    look.palette = {**far_leg_colors(look.palette), **look.palette}
    check(look)
    sheet = Image.new("RGBA", (FRAME * 4, FRAME * (4 + extra_rows)), (0, 0, 0, 0))
    # idle and idle_up: a breath every few frames.
    for column, bob in enumerate((0, -1, 0)):
        draw_frame(sheet, look, column, 0, back=False, bob=bob, legs="stand", hands=HANDS_REST, trail=STILL)
        draw_frame(sheet, look, column, 1, back=True, bob=bob, legs="stand", hands=HANDS_REST, trail=STILL)
    for row, poses in ((2, TOWARDS), (3, RIGHT)):
        for column, (legs, bob, hands, trail) in enumerate(poses):
            draw_frame(sheet, look, column, row, back=False, bob=bob, legs=legs, hands=hands, trail=trail)
    return sheet


def save(sheets: dict[str, Image.Image], preview: Optional[Path]) -> None:
    """Writes each sheet as <name>.png; `preview` also gets a 4x side by side copy."""
    for name, sheet in sheets.items():
        path = TEXTURE_DIR / f"{name}.png"
        sheet.save(path)
        print(f"wrote {path.relative_to(ROOT)}")
    if preview:
        height = max(sheet.height for sheet in sheets.values())
        image = Image.new("RGBA", (FRAME * 4 * len(sheets), height), (40, 36, 48, 255))
        for index, sheet in enumerate(sheets.values()):
            image.alpha_composite(sheet, (FRAME * 4 * index, 0))
        image.resize((image.width * 4, image.height * 4), Image.NEAREST).save(preview)
