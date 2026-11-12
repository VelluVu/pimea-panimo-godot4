"""Draws Kännihirvi, a drunk moose who walks upright like a person (a cartoon animal like
Ämpärihamstraaja): big palmate antlers, ears out to the sides, heavy half-shut lids over
clear eyes, a long light muzzle with a dark nose, a grin with the tongue out, a dewlap
hanging over the chest, brown fur with a lighter muzzle and belly, hoof hands and hooves.
He carries a metal bucket of foaming beer in his left hand (screen right from the front,
screen left from behind, redrawn there with the light still from the upper left).

The antlers need room, so the sheet has 40 px frames like Joulupukki's: rows idle (3),
idle_up (3), walk_towards (4), walk_right (4), feet on row 37, no black outline, ENDESGA 32
colours, light from above left. Fur is one flat tone with a one-pixel shade on the right
edge of the body and the right arm, like the customers' clothes.

    python dev/tools/sprites/make_kannihirvi.py [--preview out.png] [--force-aseprite]
"""

import argparse
import subprocess
from pathlib import Path

from PIL import Image

from customer_sheet import TEXTURE_DIR, hex_color, paint

FRAME = 40
BOX_X = 6
BOX_WIDTH = 28
HEAD_TOP = 1
TORSO_TOP = 19
LEGS_TOP = 33
NAME = "kannihirvi_40"
ASEPRITE = Path("C:/Program Files (x86)/Steam/steamapps/common/Aseprite/Aseprite.exe")
ASEPRITE_SCRIPT = Path(__file__).resolve().parent / "aseprite_source.lua"

PALETTE = {
	"F": hex_color("733e39"), "f": hex_color("3e2731"),  # fur, its right edge and the lids
	"m": hex_color("b86f50"),  # muzzle, inner ears, belly
	"A": hex_color("e8b796"), "a": hex_color("c28569"),  # antlers
	"W": hex_color("ffffff"), "e": hex_color("181425"),  # eyes, beer foam
	"n": hex_color("3e2731"), "k": hex_color("181425"), "p": hex_color("f6757a"),  # nose, mouth, tongue, bags
	"H": hex_color("5a6988"), "h": hex_color("262b44"),  # near hooves and the hoof hands
	"J": hex_color("3a4466"), "j": hex_color("181425"),  # far hooves
	"M": hex_color("c0cbdc"), "G": hex_color("8b9bb4"), "g": hex_color("5a6988"),  # bucket
}

# Antlers on the first five rows: two broad palms with tines along the top, their beams
# meeting the crown. The ears stick out under them, then the drunk eyes (one half shut under
# its lid, the other wide open, both crossed towards the nose, pink bags under them), the long
# muzzle widening to the dark nose, a grin with the tongue out, and the dewlap below.
ANTLERS = [
	"A.A.A.A..............A.A.A.a",
	"AAAAAAAA............AAAAAAAa",
	".AAAAAAAA..........AAAAAAAa.",
	"..aAAAAAAA........AAAAAAaa..",
	"....aaaAAAAFFFFFFAAAAaaa....",
	"......FFFFFFFFFFFFFfFFf.....",
	".....FmmFFFFFFFFFFFfFmmf....",
]
HEAD_FRONT = ANTLERS + [
	".....Ff..FffFFFFffFf..Ff....",
	".........FffFFFFWWf.........",
	".........FWeFFFFeWf.........",
	".........Fppmmmmppf.........",
	".........Fmmmmmmmmf.........",
	"........Fmmmmmmmmmmf........",
	".......Fmmnnmmmmnnmmf.......",
	".......Fmmknmmmmnkmmf.......",
	".......Fmkmmmmmmmmkmf.......",
	"........Fmkkkkkkkkmf........",
	".........Fmmmmppmmf.........",
	"..........FFFFppFf..........",
	"...........FFFFFf...........",
	"............FFf.............",
	"............FFf.............",
	"............FF..............",
]
HEAD_BACK = ANTLERS[:5] + [
	"......FFFFFFFFFFFFFfFFf.....",
	".....FFFFFFFFFFFFFFfFFFf....",
	".....Ff..FFFFFFFFFf..Ff.....",
	".........FFFFFFFFFf.........",
	".........FFFFFFFFFf.........",
	".........FFFFFFFFFf.........",
	".........FFFFFFFFFf.........",
	"........FFFFFFFFFFFf........",
	".......FFFFFFFFFFFFFf.......",
	".......FFFFFFFFFFFFFf.......",
	".......FFFFFFFFFFFFFf.......",
	"........FFFFFFFFFFFf........",
	".........FFFFFFFFFf.........",
	"..........FFFFFFFf..........",
]
# A high shoulder hump, the arms split from the body by the shade colour, a light belly,
# the hoof hands at the hips.
_ARM_ROW = "....FFFfFFmmmmmmmmFFfFFf...."
_BACK_ROW = "....FFFfFFFFFFFFFFFFfFFf...."
_HIPS = [
	"........FFmmmmmmmmFf........",
	"........FFFmmmmmmFFf........",
	"........FFFFFFFFFFFf........",
]
_BACK_HIPS = ["........FFFFFFFFFFFf........"] * 3
_TOP = [
	".........FFFFFFFFFf.........",
	".....FFFFFFFFFFFFFFFFFf.....",
]
TORSO_FRONT = _TOP + [_ARM_ROW] * 7 + [
	"....HHHfFFmmmmmmmmFFfHHH....",
	"....hhh.FFmmmmmmmmFFfhhh....",
] + _HIPS
TORSO_BACK = _TOP + [_BACK_ROW] * 7 + [
	"....HHHfFFFFFFFFFFFFfHHH....",
	"....hhh.FFFFFFFFFFFFfhhh....",
] + _BACK_HIPS

# The bucket hangs under the hand by its dark handle, beer foam over the lit rim, a ridge
# round the middle, tapering down.
BUCKET = [
	".hWWWh.",
	"hWWWWWh",
	"MMMMMMM",
	"GGGGGGg",
	"ggggggg",
	"GGGGGGg",
	".GGGGg.",
]
BUCKET_TOP = 30
BUCKET_FRONT_X = 19
BUCKET_BACK_X = 2

_HIP_ROW = "........FFFFFFFFFFFf........"
LEGS = {
	"stand": [
		_HIP_ROW,
		"........FFFf....FFFf........",
		"........FFFf....FFFf........",
		"........HHHH....HHHH........",
		"........hhhh....hhhh........",
	],
	# Walking towards: one hoof lifted a row.
	"lift_left": [
		_HIP_ROW,
		"........FFFf....FFFf........",
		"........HHHH....FFFf........",
		"........hhhh....HHHH........",
		"................hhhh........",
	],
	"lift_right": [
		_HIP_ROW,
		"........FFFf....FFFf........",
		"........FFFf....HHHH........",
		"........HHHH....hhhh........",
		"........hhhh................",
	],
	# Walking right, stepping like the user's walks: the pushing hoof heel up and toe down,
	# the landing one heel first, the lifted one hanging toe down. The far leg is darker.
	"stride_near": [
		_HIP_ROW,
		".......fff.......FFFf.......",
		"......fff.........FFFf......",
		".....JJJ...........HHHH.....",
		"......jj...........hhh......",
	],
	"pass_near": [
		_HIP_ROW,
		"..........fffFFFf...........",
		".........JJJ.FFFf...........",
		"..........jj.HHHH...........",
		".............hhhh...........",
	],
	"stride_far": [
		_HIP_ROW,
		".......FFf.......ffff.......",
		"......FFf.........ffff......",
		".....HHH...........JJJJ.....",
		"......hh...........jjj......",
	],
	"pass_far": [
		_HIP_ROW,
		"..........FFfffff...........",
		".........HHH.ffff...........",
		"..........hh.JJJJ...........",
		".............jjjj...........",
	],
}

TOWARDS = [("stand", 0), ("lift_left", -1), ("stand", 0), ("lift_right", -1)]
RIGHT = [("stride_near", 0), ("pass_near", -1), ("stride_far", 0), ("pass_far", -1)]


def check() -> None:
	for grid in [HEAD_FRONT, HEAD_BACK, TORSO_FRONT, TORSO_BACK, *LEGS.values()]:
		for row in grid:
			assert len(row) == BOX_WIDTH, f"row is {len(row)} wide: {row!r}"
	for grid in [HEAD_FRONT, HEAD_BACK, TORSO_FRONT, TORSO_BACK, BUCKET, *LEGS.values()]:
		for row in grid:
			for char in row:
				assert char == "." or char in PALETTE, f"no colour for {char!r} in {row!r}"


def draw_frame(sheet: Image.Image, column: int, row: int, *, back: bool, bob: int, legs: str) -> None:
	frame = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
	# The bucket hangs at his side behind the legs, so a stepping leg is never hidden.
	paint(frame, PALETTE, BUCKET, BOX_X + (BUCKET_BACK_X if back else BUCKET_FRONT_X), BUCKET_TOP + bob)
	leg_rows = LEGS[legs]
	paint(frame, PALETTE, leg_rows, BOX_X, LEGS_TOP)
	# The hips sit a row higher on a bob up, so the top leg row fills the gap.
	for gap_row in range(bob, 0):
		paint(frame, PALETTE, leg_rows[:1], BOX_X, LEGS_TOP + gap_row)
	paint(frame, PALETTE, TORSO_BACK if back else TORSO_FRONT, BOX_X, TORSO_TOP + bob)
	paint(frame, PALETTE, HEAD_BACK if back else HEAD_FRONT, BOX_X, HEAD_TOP + bob)
	sheet.alpha_composite(frame, (column * FRAME, row * FRAME))


def draw_sheet() -> Image.Image:
	check()
	sheet = Image.new("RGBA", (FRAME * 4, FRAME * 4), (0, 0, 0, 0))
	for column, bob in enumerate((0, -1, 0)):
		draw_frame(sheet, column, 0, back=False, bob=bob, legs="stand")
		draw_frame(sheet, column, 1, back=True, bob=bob, legs="stand")
	for row, poses in ((2, TOWARDS), (3, RIGHT)):
		for column, (legs, bob) in enumerate(poses):
			draw_frame(sheet, column, row, back=False, bob=bob, legs=legs)
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


def write_preview(sheet: Image.Image, out: Path) -> None:
	"""The sheet beside Joulupukki's and a normal customer's idle frames, feet on one row, 6x."""
	santa = Image.open(TEXTURE_DIR / "joulupukki_40.png").convert("RGBA").crop((0, 0, FRAME, FRAME))
	normal = Image.open(TEXTURE_DIR / "normaali_mies_32.png").convert("RGBA").crop((0, 0, 32, 32))
	image = Image.new("RGBA", (FRAME * 6, FRAME * 4), (40, 36, 48, 255))
	image.alpha_composite(sheet, (0, 0))
	for row in range(4):
		image.alpha_composite(santa, (FRAME * 4, row * FRAME))
		image.alpha_composite(normal, (FRAME * 5 + 4, row * FRAME + 8))
	image.resize((image.width * 6, image.height * 6), Image.NEAREST).save(out)


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--preview", type=Path, help="also write a 6x preview beside Joulupukki and a normal customer")
	parser.add_argument("--force-aseprite", action="store_true")
	args = parser.parse_args()
	sheet = draw_sheet()
	path = TEXTURE_DIR / f"{NAME}.png"
	sheet.save(path)
	print(f"wrote {path.name}")
	write_aseprite_source(path, args.force_aseprite)
	if args.preview:
		write_preview(sheet, args.preview)


if __name__ == "__main__":
	main()
