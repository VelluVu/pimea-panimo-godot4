"""Draws the Christmas decorations of the cellar: the joulukuusi, the string lights along the
back wall's top pipe, the electric seven-light candlestick on the counter, two candles on the
stairs barrel and three felt tontut (a tall grey one, a sitting one with dangling legs and a
small red one).

Colours come from the same palette as the pumpkins (Endesga 32). Lit from above and left,
like the cellar lamp: the lit side keeps no outline, the shaded side and the bottom get a
dark one. The string lights are a sheet of three frames, so the bulbs twinkle in turn.

Each PNG also gets an editable .aseprite source next to it (through Aseprite's CLI and
aseprite_source.lua), with the art's colours as its palette and the lights' frames tagged.
An existing source is kept, as it may hold hand edits: after editing one, export the PNG
from Aseprite instead of rerunning this, or pass --force-aseprite to redo the sources.

    python dev/tools/sprites/make_christmas_decor.py [--preview out.png] [--force-aseprite]
"""

import argparse
import math
import subprocess
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
TEXTURE_DIR = ROOT / "assets/textures/christmas"
## The tree and the tontut are shown at this scale: chunkier than the cellar, but with
## more pixels for their details than the customers' 4.
SCALE = 2
SCALED = ("christmas_tree", "christmas_candlestick", "tonttu_felt_tall", "tonttu_felt_sitting", "tonttu_felt_small")
ASEPRITE = Path("C:/Program Files (x86)/Steam/steamapps/common/Aseprite/Aseprite.exe")
ASEPRITE_SCRIPT = Path(__file__).resolve().parent / "aseprite_source.lua"
FRAMES_DIR = ROOT / "src/resources/sprite_frames"

COLORS = {
	"O": (25, 60, 62),     # tree outline, deepest green
	"1": (38, 92, 66),     # tree shade
	"2": (62, 137, 72),    # tree
	"3": (99, 199, 77),    # tree highlight
	"Y": (254, 231, 97),   # star highlight, bulb core
	"y": (254, 174, 52),   # gold
	"o": (247, 118, 34),   # gold shade, flame base
	"R": (228, 59, 68),    # red
	"r": (162, 38, 51),    # red shade
	"p": (246, 117, 122),  # red highlight
	"s": (234, 212, 170),  # straw, candle wax
	"S": (228, 166, 114),  # straw shade
	"W": (255, 255, 255),  # white
	"B": (0, 153, 219),    # flag blue
	"n": (184, 111, 80),   # wood light
	"N": (115, 62, 57),    # wood
	"K": (62, 39, 49),     # wood dark
	"L": (192, 203, 220),  # felt light grey, beard shade
	"M": (139, 155, 180),  # felt grey
	"D": (90, 105, 136),   # felt shade
	"Q": (58, 68, 102),    # felt outline
	"P": (232, 183, 150),  # nose light
	"F": (246, 117, 122),  # nose
	"f": (194, 133, 105),  # nose shade
	"w": (38, 43, 68),     # light wire
	"g": (62, 137, 72),    # green bulb
	"G": (99, 199, 77),    # green bulb lit
	"b": (18, 78, 137),    # blue bulb
	"c": (44, 232, 245),   # blue bulb lit
	"e": (162, 38, 51),    # red bulb
	"E": (255, 0, 68),     # red bulb lit
	"a": (247, 118, 34),   # gold bulb
	"A": (254, 231, 97),   # gold bulb lit
}


def from_grid(rows: list[str]) -> Image.Image:
	width = max(len(row) for row in rows)
	image = Image.new("RGBA", (width, len(rows)), (0, 0, 0, 0))
	for y, row in enumerate(rows):
		for x, key in enumerate(row):
			if key != ".":
				image.putpixel((x, y), COLORS[key] + (255,))
	return image


# --- Joulukuusi -------------------------------------------------------------------------

# Drawn at half size and shown at SCALE. The tree is too tall for the cellar: its top is
# bent over under the ceiling. The bent top is drawn by hand (BENT_TOP), as a computed bend
# would break the pixel grid like a rotation; the rest is the straight tree.
TREE_WIDTH, STRAIGHT_HEIGHT = 61, 113
TREE_CENTER = 30
# (top row, bottom row, half width at the bottom), drawn from the bottom tier up so each
# tier's fringe hangs over the one below. About half as wide as it is tall.
TIERS = [(5, 20, 6), (13, 36, 11), (26, 52, 16), (40, 68, 20), (55, 84, 24), (70, 98, 28)]
STAR = ["...y...", "...Y...", "yyyYyyy", ".yYYYy.", "..yYy..", ".yy.yy.", ".y...y."]
TRUNK_ROWS = (99, 107)
POT = [
	".rRRRRRRRRRr.",
	"RpRRWRRRWRRRr",
	"RpRRRRRRRRRRr",
	".RRWRRRWRRRr.",
	".rRRRRRRRRrr.",
	"..rrrrrrrrr..",
]
TREE_HEIGHT = 108
# The straight tree's top rows that the bent top replaces.
BEND_CUT = STRAIGHT_HEIGHT - TREE_HEIGHT
# (row, first column, pixels) of the bent top; the star rests against the ceiling.
BENT_TOP = [
	(0, 12, "y"),
	(1, 11, "yYy"),
	(2, 10, "yyYyy332O"),
	(3, 11, "yyy33222O"),
	(4, 11, "y.y.1322222O"),
	(5, 16, "1O3222222O"),
	(6, 18, "1.O32222221O"),
	(7, 21, "1.O3222211O"),
	(8, 23, "1.O322R21O"),
	(9, 26, "332222211O"),
	(10, 24, "1O1O111O1O1O"),
	(11, 29, "32O"),
	(12, 28, "3221O"),
	(13, 28, "3W2B1O"),
	(14, 27, "332221O"),
	(15, 27, "33y2211O"),
	(16, 26, "3322R211O"),
	(17, 26, "33222211O"),
	(18, 26, "3W2B2W11O"),
]
BENT_TOP_ROWS = len(BENT_TOP)
# Ornaments go on a jittered grid so they spread evenly without lining up.
ORNAMENT_STEP = 6
ORNAMENT_KINDS = ["red", "gold", "straw", "red", "gold", "red", "straw", "gold"]


def _tier_half_width(y: int, tier: tuple[int, int, int]) -> int:
	top, bottom, half = tier
	return max(1, round(half * (y - top + 1) / (bottom - top + 1)))


def _tree_shape() -> dict[tuple[int, int], int]:
	shade: dict[tuple[int, int], int] = {}
	for tier in reversed(TIERS):
		top, bottom, half = tier
		for y in range(top, bottom + 1):
			hw = _tier_half_width(y, tier)
			for x in range(TREE_CENTER - hw, TREE_CENTER + hw + 1):
				# Drooping tips: the bottom row is cut into needles.
				if y == bottom and (x - TREE_CENTER) % 3 != 1:
					continue
				u = (x - TREE_CENTER) / hw
				v = (y - top) / (bottom - top)
				level = 2
				if u < -0.55 and v < 0.75:
					level = 3
				elif u > 0.4 or v > 0.85:
					level = 1
				shade[(x, y)] = level
	# Each tier's fringe casts shade on the tier below.
	for _top, bottom, _half in TIERS[:-1]:
		for x in range(TREE_WIDTH):
			for dy in (1, 2):
				below = (x, bottom + dy)
				if below in shade:
					shade[below] = max(1, shade[below] - 1)
	# Selective outline: the shaded right side and the bottom.
	for (x, y) in list(shade):
		right_open = (x + 1, y) not in shade and x >= TREE_CENTER
		if right_open or (x, y + 1) not in shade:
			shade[(x, y)] = 0
	return shade


def _draw_straight_tree() -> Image.Image:
	shade = _tree_shape()
	image = Image.new("RGBA", (TREE_WIDTH, STRAIGHT_HEIGHT), (0, 0, 0, 0))
	for (x, y), level in shade.items():
		image.putpixel((x, y), COLORS["O123"[level]] + (255,))

	def inside(x: int, y: int) -> bool:
		return shade.get((x, y), 0) > 0

	def put(x: int, y: int, key: str) -> None:
		if inside(x, y):
			image.putpixel((x, y), COLORS[key] + (255,))

	# A Finnish flag garland across each tier, sagging a little.
	for top, bottom, _half in TIERS:
		y0 = top + round((bottom - top) * 0.6)
		hw = _tier_half_width(y0, (top, bottom, _half))
		for i, x in enumerate(range(TREE_CENTER - hw, TREE_CENTER + hw + 1)):
			t = i / max(1, 2 * hw)
			y = round(y0 - 2 * t + 2 * math.sin(math.pi * t))
			put(x, y, "B" if i % 3 == 1 else "W")
	kind = 0
	for row, y in enumerate(range(10, TIERS[-1][1] - 1, ORNAMENT_STEP)):
		for x in range(TREE_CENTER % ORNAMENT_STEP + (row % 2) * 3, TREE_WIDTH, ORNAMENT_STEP):
			jx, jy = x + (x * 7 + y) % 3 - 1, y + (x * 5 + y * 3) % 3 - 1
			if not all(inside(jx + dx, jy + dy) for dx in (-1, 0, 1, 2) for dy in (-1, 0, 1, 2)):
				continue
			name = ORNAMENT_KINDS[kind % len(ORNAMENT_KINDS)]
			kind += 1
			if name == "straw":
				for dx, dy in ((0, -1), (-1, 0), (1, 0), (0, 1)):
					put(jx + dx, jy + dy, "s")
				put(jx, jy, "S")
			elif name == "red":
				put(jx, jy, "p"); put(jx + 1, jy, "R"); put(jx, jy + 1, "R"); put(jx + 1, jy + 1, "r")
			else:
				put(jx, jy, "Y"); put(jx + 1, jy, "y"); put(jx, jy + 1, "y"); put(jx + 1, jy + 1, "o")
	image.alpha_composite(from_grid(STAR), (TREE_CENTER - 3, 0))
	for y in range(*TRUNK_ROWS):
		for x in range(TREE_CENTER - 1, TREE_CENTER + 2):
			image.putpixel((x, y), COLORS["K" if x > TREE_CENTER else "N"] + (255,))
	image.alpha_composite(from_grid(POT), (TREE_CENTER - 6, STRAIGHT_HEIGHT - len(POT)))
	return image


def draw_tree() -> Image.Image:
	straight = _draw_straight_tree()
	image = Image.new("RGBA", (TREE_WIDTH, TREE_HEIGHT), (0, 0, 0, 0))
	lower = straight.crop((0, BENT_TOP_ROWS + BEND_CUT, TREE_WIDTH, STRAIGHT_HEIGHT))
	image.alpha_composite(lower, (0, BENT_TOP_ROWS))
	for y, first, row in BENT_TOP:
		for i, key in enumerate(row):
			if key != ".":
				image.putpixel((first + i, y), COLORS[key] + (255,))
	return image


# --- String lights ----------------------------------------------------------------------

LIGHTS_WIDTH, LIGHTS_HEIGHT = 431, 10
LIGHTS_SWAG = 43
LIGHTS_SAG = 4
BULB_GAP = 9
# Dim and lit key of each bulb colour, in the order they hang.
BULBS = [("e", "E"), ("a", "A"), ("g", "G"), ("b", "c")]
LIGHTS_FRAMES = 3
LIGHTS_FPS = 1.5


def _wire_y(x: int) -> int:
	t = (x % LIGHTS_SWAG) / LIGHTS_SWAG
	return round(LIGHTS_SAG * math.sin(math.pi * t))


def draw_lights(frame: int) -> Image.Image:
	image = Image.new("RGBA", (LIGHTS_WIDTH, LIGHTS_HEIGHT), (0, 0, 0, 0))
	for x in range(LIGHTS_WIDTH):
		image.putpixel((x, _wire_y(x)), COLORS["w"] + (255,))
	for index, x in enumerate(range(BULB_GAP // 2, LIGHTS_WIDTH - 1, BULB_GAP)):
		dim, lit = BULBS[index % len(BULBS)]
		# One bulb in three rests each frame, so the string twinkles without a pattern
		# running along it.
		key = dim if (index * 2 + frame) % LIGHTS_FRAMES == 0 else lit
		y = _wire_y(x) + 1
		image.putpixel((x, y), COLORS["w"] + (255,))
		for dx in (0, 1):
			for dy in (1, 2):
				image.putpixel((x + dx, y + dy), COLORS[key] + (255,))
	return image


# --- Candles ----------------------------------------------------------------------------

# The electric seven-light candlestick in the window of every Finnish home: a red stepped
# arch, open underneath, with a white candle standing on each step and a green sprig at
# its foot.
CANDLESTICK_WIDTH, CANDLESTICK_HEIGHT = 22, 18
CANDLESTICK_CENTER = 10
CANDLE_SPACING = 3
CANDLE_ROWS = 5
TOP_STEP_ROW = 8


## Each candle is two pixels wide, so the arch is centred between the middle candle's two.
def _step(x: int) -> int:
	return min(3, round(abs(x - CANDLESTICK_CENTER - 0.5) / CANDLE_SPACING))


def draw_candlestick() -> Image.Image:
	image = Image.new("RGBA", (CANDLESTICK_WIDTH, CANDLESTICK_HEIGHT), (0, 0, 0, 0))
	base = CANDLESTICK_HEIGHT - 2

	def put(x: int, y: int, key: str) -> None:
		image.putpixel((x, y), COLORS[key] + (255,))

	# The arch: a two pixel thick stair up to the middle and down again, standing on a
	# base board. The step tops catch the lamp's light.
	for x in range(CANDLESTICK_WIDTH):
		top = TOP_STEP_ROW + 2 * _step(x)
		put(x, top, "R")
		put(x, top + 1, "r")
		if _step(x) == 3:
			for y in range(top + 2, base):
				put(x, y, "r" if x in (0, CANDLESTICK_WIDTH - 1) else "R")
	for x in range(CANDLESTICK_WIDTH):
		put(x, base, "R")
		put(x, base + 1, "r")
	for k in range(-3, 4):
		x = CANDLESTICK_CENTER + k * CANDLE_SPACING
		top = TOP_STEP_ROW + 2 * abs(k)
		# Two pixels wide, so the wax can take light on the left and shade on the right.
		for y in range(top - CANDLE_ROWS, top):
			put(x, y, "s")
			put(x + 1, y, "L")
		put(x, top - CANDLE_ROWS - 1, "Y")
		put(x + 1, top - CANDLE_ROWS - 1, "y")
		put(x, top - CANDLE_ROWS - 2, "Y")
		for dx in (-1, 2):
			if 0 <= x + dx < CANDLESTICK_WIDTH:
				put(x + dx, top - 1, "g")
	return image


BARREL_CANDLES = [
	"......Y..",
	"......o..",
	".Y...sss.",
	".o...ssL.",
	"sss..ssL.",
	"ssL..ssL.",
	"ssL..ssL.",
	"ssL..ssL.",
]

# --- Felt tontut ------------------------------------------------------------------------

# Shown at SCALE like the tree. A knitted cone hat over the eyes, a round pink nose and a
# long white beard; the tall one is grey with white dots.
TONTTU_TALL = [
	"......Q......",
	".....LQ......",
	".....LMQ.....",
	"....LMMQ.....",
	"....LMWDQ....",
	"....LMMDQ....",
	"...LWMMMDQ...",
	"...LMMMWDQ...",
	"...LMMMMDQ...",
	"..LMWMMMMDQ..",
	"..LMMMMWMDQ..",
	"..LMMMMMMDQ..",
	".LMMWMMMMMDQ.",
	".LMMMMMMWMDQ.",
	"LMMMMMMMMMMDQ",
	"DDDDDDDDDDDDQ",
	".WWWWPFFWWWL.",
	"WWWWPFFFfWWLL",
	"WWWWWFFffWWLL",
	"WWWWWWffWWWLL",
	"WWWLWWWWWWWLL",
	".WWLWWWLWWLL.",
	".WWWWWWLWWLL.",
	"..WWWWWWWLL..",
	"..rRR...rRR..",
	"..rrr...rrr..",
]
# Sits on the shelf with its legs dangling: a red band with white hearts on the grey hat.
TONTTU_SITTING = [
	".....Q.....",
	"....LQ.....",
	"....LMQ....",
	"...LMMQ....",
	"...LMMDQ...",
	"...LMMDQ...",
	"..LMMMMDQ..",
	"..LMMMMDQ..",
	".WRWRWRWRQ.",
	".WWWRWWWRQ.",
	"LRWRRRWRRDQ",
	"DDDDDDDDDDQ",
	".WWWPFFWWL.",
	"WWWPFFFfWWL",
	"WWWWFffWWLL",
	"WWLWWWWWWLL",
	".WWLWWWWWL.",
	"..WWWWWWL..",
	"...MD.MD...",
	"...Rr.Rr...",
	"...MD.MD...",
	"...Rr.Rr...",
	"..RRr.RRr..",
	"..rrr.rrr..",
]
TONTTU_SMALL = [
	"....r....",
	"...pr....",
	"...pRr...",
	"...pRr...",
	"..pRWRr..",
	"..pRRRr..",
	"..pRRWr..",
	".pRWRRRr.",
	".pRRRRRr.",
	"pRRRRWRRr",
	"rrrrrrrrK",
	".WWPFFWL.",
	"WWPFFfWWL",
	"WWWFffWWL",
	"WWLWWWWLL",
	".WWLWWWL.",
	"..rR.rR..",
	"..rr.rr..",
]


SINGLE_SPRITES = {
	"christmas_barrel_candles": BARREL_CANDLES,
	"tonttu_felt_tall": TONTTU_TALL,
	"tonttu_felt_sitting": TONTTU_SITTING,
	"tonttu_felt_small": TONTTU_SMALL,
}


def write_lights_frames() -> None:
	path = "res://assets/textures/christmas/christmas_lights.png"
	lines = ['[gd_resource type="SpriteFrames" format=3]', "",
			 f'[ext_resource type="Texture2D" path="{path}" id="1_sheet"]', ""]
	for i in range(LIGHTS_FRAMES):
		lines += [f'[sub_resource type="AtlasTexture" id="AtlasTexture_{i}"]', 'atlas = ExtResource("1_sheet")',
				  f"region = Rect2(0, {i * LIGHTS_HEIGHT}, {LIGHTS_WIDTH}, {LIGHTS_HEIGHT})", ""]
	frames = ", ".join('{\n"duration": 1.0,\n"texture": SubResource("AtlasTexture_%d")\n}' % i for i in range(LIGHTS_FRAMES))
	lines += ["[resource]", "animations = [{", f'"frames": [{frames}],', '"loop": true,', '"name": &"twinkle",',
			  f'"speed": {LIGHTS_FPS}', "}]", ""]
	(FRAMES_DIR / "christmas_lights_anim.tres").write_text("\n".join(lines), encoding="utf-8")


def write_aseprite_sources(names: list[str], force: bool) -> list[str]:
	"""Returns the names whose source was written; the rest were kept or Aseprite is missing."""
	if not ASEPRITE.exists():
		print("Aseprite not found, no .aseprite sources written:", ASEPRITE)
		return []
	written = []
	for name in names:
		source = TEXTURE_DIR / f"{name}.aseprite"
		if source.exists() and not force:
			continue
		command = [str(ASEPRITE), "-b", "--script-param", f"png={TEXTURE_DIR / name}.png",
				   "--script-param", f"out={source}"]
		if name == "christmas_lights":
			ms = round(1000 / LIGHTS_FPS)
			command += ["--script-param", f"frames={LIGHTS_FRAMES}", "--script-param", "tag=twinkle",
						"--script-param", f"ms={ms}"]
		subprocess.run(command + ["--script", str(ASEPRITE_SCRIPT)], check=True)
		written.append(name)
	return written


def main() -> None:
	parser = argparse.ArgumentParser()
	parser.add_argument("--preview")
	parser.add_argument("--force-aseprite", action="store_true")
	args = parser.parse_args()
	TEXTURE_DIR.mkdir(parents=True, exist_ok=True)
	images = {"christmas_tree": draw_tree(), "christmas_candlestick": draw_candlestick()}
	sheet = Image.new("RGBA", (LIGHTS_WIDTH, LIGHTS_HEIGHT * LIGHTS_FRAMES), (0, 0, 0, 0))
	for frame in range(LIGHTS_FRAMES):
		sheet.alpha_composite(draw_lights(frame), (0, frame * LIGHTS_HEIGHT))
	images["christmas_lights"] = sheet
	for name, rows in SINGLE_SPRITES.items():
		images[name] = from_grid(rows)
	for name, image in images.items():
		image.save(TEXTURE_DIR / f"{name}.png")
	write_lights_frames()
	sources = write_aseprite_sources(list(images), args.force_aseprite)
	if sources:
		print("aseprite sources:", ", ".join(sources))
	if args.preview:
		small = [img.resize((img.width * SCALE, img.height * SCALE), Image.NEAREST) if name in SCALED else img
				 for name, img in images.items() if name != "christmas_lights"]
		width = sum(img.width + 4 for img in small)
		preview = Image.new("RGBA", (width, 180), (24, 20, 37, 255))
		x = 0
		for img in small:
			preview.alpha_composite(img, (x, 180 - img.height))
			x += img.width + 4
		preview.resize((width * 3, 140 * 3), Image.NEAREST).save(args.preview)
	print("wrote", ", ".join(images))


if __name__ == "__main__":
	main()
