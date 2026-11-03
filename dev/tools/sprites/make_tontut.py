"""Draws the tontut, the Christmas elves who watch the brewer: knitted gnomes like the felt
ones in the cellar decor, a tall cone hat pulled over the eyes, a round pink nose, a white
beard and tiny red boots. About half a customer's height (12-14 px against 28), so the hat
tip reaches a customer's chest. Three of them for the group: a tall grey one with white
dots, a middle grey one with a red band and a white heart, and a small red one with dots.

32 px frames at the customers' scale, feet on row 29 like theirs. Rows: idle (3), idle_up
(3), walk_towards (4) and walk_right (4) as small hops, then run_right (4, the dash through the brewery) and
peek (2, leaning out from a hiding spot). No black outline, ENDESGA 32 colours, light from
above left, a dark edge only on the shade side. Leaning hats are hand-drawn grids, not a
shear of the straight ones.

    python dev/tools/sprites/make_tontut.py [--preview out.png] [--force-aseprite]
"""

import argparse
import subprocess
from pathlib import Path

from PIL import Image

from customer_sheet import TEXTURE_DIR, hex_color, paint

FRAME = 32
BOX_X = 11
BOX_WIDTH = 11
FLOOR = 29
ROWS = 6
ASEPRITE = Path("C:/Program Files (x86)/Steam/steamapps/common/Aseprite/Aseprite.exe")
ASEPRITE_SCRIPT = Path(__file__).resolve().parent / "aseprite_source.lua"

BASE_PALETTE = {
	"W": hex_color("ffffff"), "L": hex_color("c0cbdc"), "M": hex_color("8b9bb4"),  # beard, grey felt
	"D": hex_color("5a6988"), "Q": hex_color("3a4466"),  # felt shade, shade edge
	"P": hex_color("e8b796"), "F": hex_color("f6757a"), "f": hex_color("c28569"),  # nose
	"R": hex_color("e43b44"), "r": hex_color("a22633"), "K": hex_color("3e2731"),  # red felt, boots
	"p": hex_color("f6757a"),  # red felt lit
	"k": hex_color("6b1f2e"),  # far boot
}

# Beards hang from under the hat brim; the nose pokes out of the top. "_right" has the nose
# a pixel to the right, looking where it walks. The back shows the tunic (T lit, U, V shade)
# with the beard's edges at the sides. Red mittens rest at the beard's edges; walk_towards
# plays mirrored, so the glass hangs from the left one (CustomerHandOffsets).
BEARD_WIDE = {
	"front": [
		".WWWPFFWLM.",
		"RrWWFFfWLRr",
		"rrWWWWWLMrr",
		"...WWWLM...",
	],
	"right": [
		".WWWWPFFLM.",
		"RrWWWFFfLRr",
		"rrWWWWWLMrr",
		"...WWWLM...",
	],
	"back": [
		".WTUUUUVLM.",
		"RrTUUUUVLRr",
		"rrTUUUVV.rr",
		"...UUVV....",
	],
}
BEARD_NARROW = {
	"front": [
		"..WWPFFLM..",
		".RrWFFfLRr.",
		".rrWWWLMrr.",
	],
	"right": [
		"..WWWPFFM..",
		".RrWWFFfRr.",
		".rrWWWLMrr.",
	],
	"back": [
		"..WTUUVLM..",
		".RrTUUVLRr.",
		".rrUUVV.rr.",
	],
}

# Each variant: the hat straight, leaning back (the dash, tip trailing left) and leaning out
# (the peek, tip to the right); the last hat row is the brim.
TALL = {
	"straight": [
		".....M.....",
		"....LMD....",
		"....LWD....",
		"...LMMDQ...",
		"...LWMDQ...",
		"..LMMMWDQ..",
		"..LWMMMDQ..",
		".MDDDDDDDQ.",
	],
	"dash": [
		"...M.......",
		"...LMD.....",
		"....LWD....",
		"...LMMDQ...",
		"...LWMDQ...",
		"..LMMMWDQ..",
		"..LWMMMDQ..",
		".MDDDDDDDQ.",
	],
	"peek": [
		".......M...",
		".....LMD...",
		"....LWD....",
		"...LMMDQ...",
		"...LWMDQ...",
		"..LMMMWDQ..",
		"..LWMMMDQ..",
		".MDDDDDDDQ.",
	],
}
BAND = {
	"straight": [
		".....M.....",
		"....LMD....",
		"....LMD....",
		"...LMMDQ...",
		"..RRWRWrr..",
		"..RRRWRrr..",
		".MDDDDDDDQ.",
	],
	"dash": [
		"...M.......",
		"...LMD.....",
		"....LMD....",
		"...LMMDQ...",
		"..RRWRWrr..",
		"..RRRWRrr..",
		".MDDDDDDDQ.",
	],
	"peek": [
		".......M...",
		".....LMD...",
		"....LMD....",
		"...LMMDQ...",
		"..RRWRWrr..",
		"..RRRWRrr..",
		".MDDDDDDDQ.",
	],
}
SMALL = {
	"straight": [
		".....R.....",
		".....Rr....",
		"....pRr....",
		"....pWr....",
		"...pRRrK...",
		"...pWRrK...",
		"..prrrrrK..",
	],
	"dash": [
		"...R.......",
		"....Rr.....",
		"....pRr....",
		"....pWr....",
		"...pRRrK...",
		"...pWRrK...",
		"..prrrrrK..",
	],
	"peek": [
		".......R...",
		"......Rr...",
		"....pRr....",
		"....pWr....",
		"...pRRrK...",
		"...pWRrK...",
		"..prrrrrK..",
	],
}

# Boots, bottom row on the floor. A planted boot under a raised body gets a leg row (D).
FEET = {
	"stand": ["...........", "...Rr.Rr...", "...rr.rr..."],
	# In the air the boots come together under the beard.
	"tuck": ["...........", "....Rrr....", "....rrr...."],
	# The dash: long strides and a hop with both boots tucked up.
	"run_reach_near": ["...........", ".kk.....Rr.", ".kk.....rr."],
	"run_hop_near": ["....kkRr...", "....kkrr...", "...........", "..........."],
	"run_reach_far": ["...........", ".Rr.....kk.", ".rr.....kk."],
	"run_hop_far": ["....Rrkk...", "....rrkk...", "...........", "..........."],
}

# They hop instead of walking, a small one: a crouch onto the boots, off the floor, the top
# two pixels up, and down again. With a negative bob the boots leave the floor with the body.
HOP = [("stand", 1), ("stand", -1), ("tuck", -2), ("stand", -1)]
RUN = [("run_reach_near", 0), ("run_hop_near", -2), ("run_reach_far", 0), ("run_hop_far", -2)]
PEEK = [("stand", 0), ("stand", 1)]

VARIANTS = {
	"tonttu_harmaa_32": dict(hat=TALL, beard=BEARD_WIDE,
		tunic={"T": hex_color("8b9bb4"), "U": hex_color("5a6988"), "V": hex_color("3a4466")}),
	"tonttu_sydan_32": dict(hat=BAND, beard=BEARD_WIDE,
		tunic={"T": hex_color("e43b44"), "U": hex_color("a22633"), "V": hex_color("3e2731")}),
	"tonttu_punainen_32": dict(hat=SMALL, beard=BEARD_NARROW,
		tunic={"T": hex_color("8b9bb4"), "U": hex_color("5a6988"), "V": hex_color("3a4466")}),
}


def check(variant: dict) -> None:
	palette = {**BASE_PALETTE, **variant["tunic"]}
	grids = [*variant["hat"].values(), *variant["beard"].values(), *FEET.values()]
	for grid in grids:
		for row in grid:
			assert len(row) == BOX_WIDTH, f"row is {len(row)} wide: {row!r}"
			for char in row:
				assert char == "." or char in palette, f"no colour for {char!r} in {row!r}"


def draw_frame(sheet: Image.Image, variant: dict, column: int, row: int, *, hat: str, beard: str,
		feet: str, bob: int) -> None:
	palette = {**BASE_PALETTE, **variant["tunic"]}
	frame = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
	feet_rows = FEET[feet]
	airborne = bob < 0 and len(feet_rows) == 3
	paint(frame, palette, feet_rows, BOX_X, FLOOR + 1 - len(feet_rows) + (bob if airborne else 0))
	beard_rows = variant["beard"][beard]
	# The body sits on the boots' top row, two rows above the floor, then bobs.
	beard_top = FLOOR - 1 - len(beard_rows) + bob
	paint(frame, palette, beard_rows, BOX_X, beard_top)
	hat_rows = variant["hat"][hat]
	paint(frame, palette, hat_rows, BOX_X, beard_top - len(hat_rows))
	sheet.alpha_composite(frame, (column * FRAME, row * FRAME))


def draw_sheet(variant: dict) -> Image.Image:
	check(variant)
	sheet = Image.new("RGBA", (FRAME * 4, FRAME * ROWS), (0, 0, 0, 0))
	for column, bob in enumerate((0, 1, 0)):
		# A breath is the hat settling a pixel, the felt is soft.
		draw_frame(sheet, variant, column, 0, hat="straight", beard="front", feet="stand", bob=bob)
		draw_frame(sheet, variant, column, 1, hat="straight", beard="back", feet="stand", bob=bob)
	for column, (feet, bob) in enumerate(HOP):
		draw_frame(sheet, variant, column, 2, hat="straight", beard="front", feet=feet, bob=bob)
	for column, (feet, bob) in enumerate(HOP):
		draw_frame(sheet, variant, column, 3, hat="straight", beard="right", feet=feet, bob=bob)
	for column, (feet, bob) in enumerate(RUN):
		draw_frame(sheet, variant, column, 4, hat="dash", beard="right", feet=feet, bob=bob)
	for column, (feet, bob) in enumerate(PEEK):
		draw_frame(sheet, variant, column, 5, hat="peek", beard="right", feet=feet, bob=bob)
	return sheet


def write_aseprite_source(png: Path, force: bool) -> None:
	"""An editable source next to the PNG; an existing one is kept (it may hold hand edits)."""
	out = png.with_suffix(".aseprite")
	if out.exists() and not force:
		print(f"kept {out.name} (pass --force-aseprite to redo it)")
		return
	if not ASEPRITE.exists():
		print("Aseprite not found, no .aseprite source written:", ASEPRITE)
		return
	subprocess.run([str(ASEPRITE), "-b", "--script-param", f"png={png}", "--script-param", f"out={out}",
		"--script", str(ASEPRITE_SCRIPT)], check=True)
	print(f"wrote {out.name}")


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--preview", type=Path, help="also write a 4x preview beside a normal customer")
	parser.add_argument("--force-aseprite", action="store_true")
	args = parser.parse_args()
	sheets = {name: draw_sheet(variant) for name, variant in VARIANTS.items()}
	for name, sheet in sheets.items():
		path = TEXTURE_DIR / f"{name}.png"
		sheet.save(path)
		print(f"wrote {path.name}")
		write_aseprite_source(path, args.force_aseprite)
	if args.preview:
		normal = Image.open(TEXTURE_DIR / "normaali_mies_32.png").convert("RGBA")
		image = Image.new("RGBA", (FRAME * 13, FRAME * ROWS), (40, 36, 48, 255))
		for index, sheet in enumerate(sheets.values()):
			image.alpha_composite(sheet, (FRAME * 4 * index, 0))
		for row in range(4):
			image.alpha_composite(normal.crop((0, row * FRAME, FRAME, (row + 1) * FRAME)), (FRAME * 12, row * FRAME))
		image.resize((image.width * 4, image.height * 4), Image.NEAREST).save(args.preview)


if __name__ == "__main__":
	main()
