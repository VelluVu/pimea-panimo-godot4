"""Draws the Halloween skeletons that peek out in the cellar: from the open barrel by the
stairs, from behind the warehouse doorway's frame, and from behind a tank in the brewery
room.

Each spot's frames are cut to the scene: a skull shows only over the pixels that lie
behind it (the barrel's dark opening, the doorway, the gap between tanks), so the edge
in front covers it like a real one. Fingers are drawn over the edge they grip. For each
spot the script writes a horizontal sheet and its SpriteFrames, placed in main.tscn at
the spot's origin.

    python dev/tools/sprites/make_barrel_skeleton.py [--preview out.png]
"""

import argparse
from dataclasses import dataclass, field
from pathlib import Path
from typing import Callable

from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
BACKGROUND = ROOT / "assets/textures/underground_brewery_fixed-0001.png"
# The brewery room drawn over the background, where BreweryHoverArea places it.
BREWERY_VIEW = ROOT / "assets/textures/brewery_view.png"
BREWERY_VIEW_ORIGIN = (122, 94)
TEXTURE_DIR = ROOT / "assets/textures"
FRAMES_DIR = ROOT / "src/resources/sprite_frames"
ANIMATION_FPS = 10

# The bone ramp shifts hue: warm in the light, cool purple in the shade, like the cellar.
PALETTE = {
    "H": (240, 230, 200),  # bone highlight, warmest
    "B": (196, 186, 168),  # bone
    "S": (118, 104, 122),  # bone shade, toward the cellar's purple
    "D": (27, 16, 29),     # sockets, as dark as the barrel inside
    "E": (247, 118, 34),   # eye glint, the pumpkins' orange
}

SKULL = [
    "....BBBB....",
    "..BHHHHBBB..",
    ".BHHHHBBBBS.",
    ".BHHBBBBBBS.",
    "BHBBBBBBBBSS",
    "BBDDDBBDDDSS",
    "BBD{}DBBD{}DSS",
    "BBDDDBBDDDSS",
    ".BBBBDDBBBS.",
    "..SBBBBBBS..",
    "..BDBDBDBS..",
    "..SBBBBBBS..",
    "...SSSSSS...",
]
# The jaw dropped a row: a dark gap between the teeth.
SKULL_JAW_OPEN = SKULL[:10] + ["..BDBDBDBS..", "..DDDDDDDD..", "..BDBDBDBS..", "...SSSSSS..."]

# Far away in the brewery room: one glowing pixel per eye.
SMALL_SKULL = [
    ".BHHBB.",
    "BHBBBBS",
    "BEBBEBS",
    "BBBDBBS",
    ".SBBBS.",
    ".BDBDS.",
]

# Eye glint per gaze: the middle of the 3-pixel socket, or its left or right edge.
GAZES = {"ahead": ("DED", "DED"), "left": ("EDD", "EDD"), "right": ("DDE", "DDE")}

RIM_FINGERS_LEFT = ["B.B.", "HBHB", "S.S."]
RIM_FINGERS_RIGHT = [".B.B", "BHBH", ".S.S"]
# Curled round a wall edge from behind it: one knuckle per finger, a row apart.
EDGE_FINGERS = ["HB", "..", "BS", "..", "HB"]


@dataclass
class Frame:
    skull_pos: tuple[int, int]
    gaze: str = "ahead"
    jaw_open: bool = False
    fingers: bool = False


@dataclass
class Spot:
    name: str
    origin: tuple[int, int]
    size: tuple[int, int]
    frames: list[Frame]
    # Indexes into frames with their durations in animation ticks (1/ANIMATION_FPS s).
    sequence: list[tuple[int, float]]
    # (x, y) -> whether a skull pixel there is seen, given the scene image.
    visible: Callable[[Image.Image], Callable[[int, int], bool]]
    small: bool = False
    # A dark outline keeps the bone readable against a light background.
    outline: bool = False
    fingers: list[tuple[list[str], tuple[int, int]]] = field(default_factory=list)


def barrel_visible(scene: Image.Image) -> Callable[[int, int], bool]:
    """Inside the barrel's dark opening, or above the barrel altogether."""
    interior = {(27, 16, 29), (27, 17, 27), (26, 17, 27), (25, 16, 26)}
    opening_top = 259
    px = scene.load()
    bottoms = {}
    for x in range(70, 112):
        for y in range(opening_top, opening_top + 12):
            if px[x, y][:3] in interior:
                bottoms[x] = y
    return lambda x, y: y < opening_top or y <= bottoms.get(x, -1)


def colours_visible(colours: set[tuple[int, int, int]]) -> Callable[[Image.Image], Callable[[int, int], bool]]:
    """Wherever the scene shows one of these colours: what lies behind the skull's edge."""
    def build(scene: Image.Image) -> Callable[[int, int], bool]:
        px = scene.load()
        return lambda x, y: px[x, y][:3] in colours
    return build


def columns_visible(first: int, last: int) -> Callable[[Image.Image], Callable[[int, int], bool]]:
    """Between two columns: an opening such as a doorway."""
    return lambda scene: lambda x, y: first <= x <= last


# The gap between the brewery room's centre tank and the right-hand row, pipe included.
TANK_GAP = {(59, 63, 64), (138, 136, 132), (163, 166, 160)}

SPOTS = [
    Spot(
        name="barrel_skeleton",
        origin=(71, 244), size=(40, 26),
        frames=[
            Frame((85, 264)),                        # 0 crown only
            Frame((85, 259)),                        # 1 eyes over the rim
            Frame((85, 259), "left"),                # 2
            Frame((85, 259), "right"),               # 3
            Frame((85, 254), fingers=True),          # 4 up to the jaw, gripping the rim
            Frame((85, 254), jaw_open=True, fingers=True),  # 5
        ],
        sequence=[(0, 4), (1, 8), (2, 6), (3, 6), (1, 3), (4, 3), (5, 1.5), (4, 1.5), (5, 1.5), (4, 5), (1, 4), (0, 3)],
        visible=barrel_visible,
        fingers=[(RIM_FINGERS_LEFT, (79, 264)), (RIM_FINGERS_RIGHT, (99, 264))],
    ),
    Spot(
        name="corner_skeleton",
        # In the warehouse doorway, behind the right-hand door frame.
        origin=(590, 262), size=(24, 22),
        frames=[
            Frame((605, 270)),                       # 0 the crown's edge
            Frame((601, 270)),                       # 1 one eye round the frame
            Frame((601, 270), "left"),               # 2 looking into the cellar
            Frame((599, 270), "left", fingers=True),           # 3 leaning out, gripping
            Frame((599, 270), "left", jaw_open=True, fingers=True),  # 4
        ],
        sequence=[(0, 4), (1, 6), (2, 8), (3, 4), (4, 1.5), (3, 1.5), (4, 1.5), (3, 4), (2, 3), (1, 3), (0, 3)],
        visible=columns_visible(578, 607),
        outline=True,
        # Gripping the frame above the head, so the knuckles do not read as teeth.
        fingers=[(EDGE_FINGERS, (608, 264))],
    ),
    Spot(
        name="tank_skeleton",
        origin=(200, 156), size=(14, 12),
        frames=[
            Frame((200, 160)),                       # 0 a sliver past the tank
            Frame((202, 160)),                       # 1 one eye
            Frame((204, 160)),                       # 2 both eyes
        ],
        sequence=[(0, 5), (1, 6), (2, 10), (1, 4), (2, 6), (1, 4), (0, 4)],
        visible=colours_visible(TANK_GAP),
        small=True,
    ),
]


def skull_rows(spot: Spot, frame: Frame) -> list[str]:
    if spot.small:
        return SMALL_SKULL
    left, right = GAZES[frame.gaze]
    rows = SKULL_JAW_OPEN if frame.jaw_open else SKULL
    return [row.replace("D{}D", left, 1).replace("D{}D", right, 1) if "{}" in row else row for row in rows]


def outlined(rows: list[str]) -> list[str]:
    """The rows grown by one pixel each side, with a dark pixel next to every bone pixel."""
    width = max(len(row) for row in rows) + 2
    grid = ["." * width] + ["." + row.ljust(width - 2, ".") + "." for row in rows] + ["." * width]
    out = []
    for y, row in enumerate(grid):
        line = ""
        for x, ch in enumerate(row):
            filled_beside = any(0 <= y + dy < len(grid) and 0 <= x + dx < width and grid[y + dy][x + dx] in PALETTE
                                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
            line += "D" if ch not in PALETTE and filled_beside else "."
        out.append(line)
    return out


def draw(canvas: Image.Image, spot: Spot, rows: list[str], left: int, top: int, clip=None) -> None:
    px = canvas.load()
    for dy, row in enumerate(rows):
        for dx, ch in enumerate(row):
            if ch not in PALETTE:
                continue
            x, y = left + dx, top + dy
            if clip is not None and not clip(x, y):
                continue
            fx, fy = x - spot.origin[0], y - spot.origin[1]
            if 0 <= fx < spot.size[0] and 0 <= fy < spot.size[1]:
                px[fx, fy] = PALETTE[ch] + (255,)


def build(spot: Spot, scene: Image.Image) -> Image.Image:
    visible = spot.visible(scene)
    width, height = spot.size
    sheet = Image.new("RGBA", (width * len(spot.frames), height), (0, 0, 0, 0))
    for i, frame in enumerate(spot.frames):
        canvas = Image.new("RGBA", spot.size, (0, 0, 0, 0))
        rows = skull_rows(spot, frame)
        if spot.outline:
            draw(canvas, spot, outlined(rows), frame.skull_pos[0] - 1, frame.skull_pos[1] - 1, visible)
        draw(canvas, spot, rows, *frame.skull_pos, visible)
        if frame.fingers:
            for rows, pos in spot.fingers:
                draw(canvas, spot, rows, *pos)
        sheet.alpha_composite(canvas, (i * width, 0))
    return sheet


def write_sprite_frames(spot: Spot) -> Path:
    width, height = spot.size
    lines = ['[gd_resource type="SpriteFrames" format=3]', "",
             f'[ext_resource type="Texture2D" path="res://assets/textures/{spot.name}.png" id="1_sheet"]', ""]
    for i in range(len(spot.frames)):
        lines += [f'[sub_resource type="AtlasTexture" id="AtlasTexture_{i}"]', 'atlas = ExtResource("1_sheet")',
                  f"region = Rect2({i * width}, 0, {width}, {height})", ""]
    frames = ", ".join('{\n"duration": %s,\n"texture": SubResource("AtlasTexture_%d")\n}' % (duration, index)
                       for index, duration in spot.sequence)
    lines += ["[resource]", "animations = [{", f'"frames": [{frames}],', '"loop": false,', '"name": &"peek",',
              f'"speed": {float(ANIMATION_FPS)}', "}]", ""]
    path = FRAMES_DIR / f"{spot.name}_anim.tres"
    path.write_text("\n".join(lines), encoding="utf-8", newline="\n")
    return path


def preview(spots_and_sheets, scene: Image.Image, path: Path) -> None:
    """Every frame of every spot over its scene, 6x, one row per spot."""
    pad = 6
    rows = []
    for spot, sheet in spots_and_sheets:
        width, height = spot.size
        x0, y0 = spot.origin
        crop = (x0 - pad, y0 - pad, x0 + width + pad, y0 + height + pad)
        row = Image.new("RGBA", ((crop[2] - crop[0] + 2) * len(spot.frames), crop[3] - crop[1]), (0, 0, 0, 255))
        for i in range(len(spot.frames)):
            tile = scene.crop(crop)
            tile.alpha_composite(sheet.crop((i * width, 0, (i + 1) * width, height)), (pad, pad))
            row.alpha_composite(tile, (i * (crop[2] - crop[0] + 2), 0))
        rows.append(row)
    out = Image.new("RGBA", (max(r.width for r in rows), sum(r.height + 2 for r in rows)), (0, 0, 0, 255))
    y = 0
    for row in rows:
        out.alpha_composite(row, (0, y))
        y += row.height + 2
    out.resize((out.width * 6, out.height * 6), Image.NEAREST).save(path)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--preview", type=Path, help="also write a 6x preview of every spot")
    args = parser.parse_args()
    scene = Image.open(BACKGROUND).convert("RGBA")
    scene.alpha_composite(Image.open(BREWERY_VIEW).convert("RGBA"), BREWERY_VIEW_ORIGIN)
    built = []
    for spot in SPOTS:
        sheet = build(spot, scene)
        sheet.save(TEXTURE_DIR / f"{spot.name}.png")
        frames_path = write_sprite_frames(spot)
        built.append((spot, sheet))
        print(f"{spot.name}: {len(spot.frames)} frames, {frames_path.relative_to(ROOT)}")
    if args.preview:
        preview(built, scene, args.preview)


if __name__ == "__main__":
    main()
