"""Draws the winter door at the top of the stairs: a plank door with a Z brace and iron
straps, hinged on the left, in four frames from shut to open (it swings out, away from
the cellar, so the panel narrows toward the hinge and its far edge shortens a little).
The opened part shows the snowy night outside.

Each frame is the doorway's own size (17x56 at (74, 44) in the cellar background) and
keeps only the doorway's pixels, so the ceiling's shadow wedge at its top right stays in
front of the door. Colours come from the cellar background, plus four cold blues for
outside. Writes assets/textures/winter_door.png, frames side by side.

Also writes assets/textures/winter_stair_treads.png for the snow shader: one pixel per
tread, top to bottom, starting with the landing under the door. Red * 255 is the tread's
top row, green * 255 its left end and blue * 255 its right end, in the snow rect's pixels.
"""

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
BACKGROUND = ROOT / "assets/textures/underground_brewery_fixed-0001.png"
OUT = ROOT / "assets/textures/winter_door.png"
TREADS_OUT = ROOT / "assets/textures/winter_stair_treads.png"

DOOR_X, DOOR_Y = 74, 44
WIDTH, HEIGHT = 17, 56
DOORWAY_COLOR = (0x57, 0x65, 0x63)
# Panel width and how many rows the far edge loses top and bottom, per frame.
FRAMES = [(17, 0), (12, 1), (7, 2), (3, 2)]
PLANKS = 4
BRACE_ROWS = [(7, 10), (45, 48)]
HANDLE_ROW = 28
# The snow shader's rect in the background. The landing under the door has no lit edge,
# so it is found by its own colour on its first row.
SNOW_RECT = (0, 40, 100, 200)
LANDING_ROW = 100
LANDING_COLOR = (0x50, 0x34, 0x2D)
TREAD_TOP_COLOR = (0x86, 0x64, 0x49)
# A row with at least this many lit-edge pixels is a tread top (not a riser's detail).
TREAD_MIN_PIXELS = 20


def rgb(value: str) -> tuple[int, int, int, int]:
    return (int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16), 255)


SEAM = rgb("0a0819")
SHADOW = rgb("231621")
DARK = rgb("3d2423")
BASE = rgb("594535")
LIGHT = rgb("866449")
SHINE = rgb("8b6e51")
IRON = rgb("232330")
IRON_LIGHT = rgb("3a4143")
BRASS = rgb("86765a")
BRASS_LIGHT = rgb("ceb58c")
SKY_TOP = rgb("141a2e")
SKY_LOW = rgb("26344f")
SNOW = rgb("8fa8c0")
SNOW_LIGHT = rgb("c8dae8")
# As the door turns away, the cellar light falls on it less: each colour one step darker.
DARKER = {SHINE: LIGHT, LIGHT: BASE, BASE: DARK, DARK: SHADOW, SHADOW: SEAM,
          IRON_LIGHT: IRON, IRON: SEAM, BRASS: LIGHT, BRASS_LIGHT: BRASS}
# The night sky turns lighter toward the horizon through a checker band this many rows tall.
SKY_DITHER_TOP, SKY_DITHER_ROWS = 24, 6


def outside(x: int, y: int) -> tuple[int, int, int, int]:
    # A snow bank, higher toward the right, under a night sky.
    snow_top = HEIGHT - 6 - (1 if x > 10 else 0)
    if y == snow_top:
        return SNOW_LIGHT
    if y > snow_top:
        return SNOW
    if y < SKY_DITHER_TOP:
        return SKY_TOP
    if y < SKY_DITHER_TOP + SKY_DITHER_ROWS:
        return SKY_LOW if (x + y) % 2 == 0 else SKY_TOP
    return SKY_LOW


def panel(width: int, taper: int) -> dict[tuple[int, int], tuple[int, int, int, int]]:
    pixels: dict[tuple[int, int], tuple[int, int, int, int]] = {}
    seams = {round(k * width / PLANKS) for k in range(1, PLANKS)} if width >= 7 else set()
    for x in range(width):
        cut = round(taper * x / max(width - 1, 1))
        for y in range(cut, HEIGHT - cut):
            if x == width - 1 and width < WIDTH:
                color = SHADOW  # the door's own edge
            elif x in seams:
                color = SEAM
            elif x - 1 in seams or x == 0:
                color = LIGHT
            else:
                color = BASE
            pixels[(x, y)] = color
        if pixels[(x, cut)] != SEAM:
            pixels[(x, cut)] = SHINE
        pixels[(x, HEIGHT - 1 - cut)] = SEAM
    for top, bottom in BRACE_ROWS:
        for x in range(1, width - 1):
            for y in range(top, bottom):
                if (x, y) in pixels:
                    pixels[(x, y)] = LIGHT if y == top else (SHADOW if y == bottom - 1 else BASE)
    # The Z brace climbs from the lower brace on the left to the upper one on the right.
    low, high = BRACE_ROWS[1][0], BRACE_ROWS[0][1]
    for y in range(high, low):
        x = round((low - 1 - y) * (width - 3) / (low - 1 - high)) + 1
        for dx, color in ((0, LIGHT), (1, BASE), (2, SHADOW)):
            if (x + dx, y) in pixels and x + dx < width - 1:
                pixels[(x + dx, y)] = color
    # Iron straps from the hinge side over each brace, with a nail head.
    strap_length = min(width - 1, 9)
    for top, _bottom in BRACE_ROWS:
        for x in range(strap_length):
            pixels[(x, top + 1)] = IRON_LIGHT
            pixels[(x, top + 2)] = IRON
        if strap_length > 4:
            pixels[(strap_length - 2, top + 1)] = SEAM
    if width >= 7:
        handle_x = width - 3
        pixels[(handle_x, HANDLE_ROW)] = BRASS_LIGHT
        pixels[(handle_x, HANDLE_ROW + 1)] = BRASS
        pixels[(handle_x - 1, HANDLE_ROW + 1)] = BRASS_LIGHT
        pixels[(handle_x, HANDLE_ROW + 2)] = SEAM
    return pixels


def frame(width: int, taper: int, doorway: Image.Image) -> Image.Image:
    image = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    door = panel(width, taper)
    for x in range(WIDTH):
        for y in range(HEIGHT):
            if doorway.getpixel((DOOR_X + x, DOOR_Y + y)) != DOORWAY_COLOR:
                continue
            color = door.get((x, y))
            if color is None:
                color = outside(x, y)
            elif width < WIDTH:
                color = DARKER.get(color, color)
            image.putpixel((x, y), color)
    return image


def tread_map(background: Image.Image) -> Image.Image:
    left, top, width, height = SNOW_RECT
    columns = range(left, left + width)
    landing = [x for x in columns if background.getpixel((x, LANDING_ROW)) == LANDING_COLOR]
    treads = [(LANDING_ROW, min(landing), _run_end(background, min(landing), LANDING_ROW, LANDING_COLOR))]
    previous_was_tread = True
    for y in range(LANDING_ROW + 1, top + height):
        lit = [x for x in columns if background.getpixel((x, y)) == TREAD_TOP_COLOR]
        is_tread = len(lit) >= TREAD_MIN_PIXELS
        if is_tread and not previous_was_tread:
            treads.append((y, min(lit), _run_end(background, min(lit), y, TREAD_TOP_COLOR)))
        previous_was_tread = is_tread
    image = Image.new("RGBA", (len(treads), 1))
    for index, (row, start, end) in enumerate(treads):
        image.putpixel((index, 0), (row - top, start - left, end - left, 255))
    return image


def _run_end(background: Image.Image, x: int, y: int, color: tuple[int, int, int]) -> int:
    while background.getpixel((x + 1, y)) == color:
        x += 1
    return x


def main() -> None:
    doorway = Image.open(BACKGROUND).convert("RGB")
    sheet = Image.new("RGBA", (WIDTH * len(FRAMES), HEIGHT), (0, 0, 0, 0))
    for index, (width, taper) in enumerate(FRAMES):
        sheet.paste(frame(width, taper, doorway), (index * WIDTH, 0))
    sheet.save(OUT)
    treads = tread_map(doorway)
    treads.save(TREADS_OUT)
    print(f"Wrote {OUT.relative_to(ROOT)} and {TREADS_OUT.relative_to(ROOT)} ({treads.width} treads)")


if __name__ == "__main__":
    main()
