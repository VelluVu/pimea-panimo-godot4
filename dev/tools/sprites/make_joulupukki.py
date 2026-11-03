"""Draws Joulupukki, the Christmas customer who comes in through the winter door: bigger
than everyone else (about 1.3x a customer's height and wider), so his sheet has 40 px
frames instead of 32. A red suit with white fur trim, a red stocking cap whose tip flops to
the side with a pompom, bushy white brows, rosy cheeks and nose, a long white beard over the
chest, a big belly with a black belt and gold buckle, black mittens and boots, and a brown
sack over his left shoulder (it shows behind his right side, and on his back from behind).
After Christmas he keeps coming as Pukki (pukki_40.png): the same body off duty, no cap,
beard or sack, and a hard face.

Same rows as the other customers: idle (3), idle_up (3), walk_towards (4), walk_right (4),
no black outline, ENDESGA 32 colours, light from above left. The feet stand on row 37, two
rows above the frame's bottom like the 32 px sheets, so the sprite's offset is
(-width / 2, -height) for both sizes.

    python dev/tools/sprites/make_joulupukki.py [--preview out.png] [--force-aseprite]
"""

import argparse
import subprocess
from pathlib import Path

from PIL import Image

from customer_sheet import TEXTURE_DIR, hex_color, paint

FRAME = 40
BOX_X = 6
BOX_WIDTH = 28
HEAD_TOP = 4
TORSO_TOP = 20
LEGS_TOP = 33
ASEPRITE = Path("C:/Program Files (x86)/Steam/steamapps/common/Aseprite/Aseprite.exe")
ASEPRITE_SCRIPT = Path(__file__).resolve().parent / "aseprite_source.lua"

PALETTE = {
	"R": hex_color("e43b44"), "r": hex_color("a22633"), "q": hex_color("3e2731"),  # suit and cap
	"W": hex_color("ffffff"), "w": hex_color("c0cbdc"), "g": hex_color("8b9bb4"),  # fur, beard
	"s": hex_color("ead4aa"), "t": hex_color("e4a672"), "p": hex_color("f6757a"),  # skin, cheeks
	"e": hex_color("181425"),  # eyes
	"K": hex_color("262b44"), "L": hex_color("3a4466"), "k": hex_color("181425"),  # boots, belt, mittens
	"Y": hex_color("fee761"), "y": hex_color("feae34"),  # buckle
	"B": hex_color("b86f50"), "b": hex_color("733e39"), "c": hex_color("e4a672"),  # sack, its cord
	# Trousers and boots by the shared leg letters: thigh, shin, boot, sole.
	"1": hex_color("e43b44"), "4": hex_color("a22633"), "2": hex_color("262b44"), "3": hex_color("181425"),
	# The far leg walking right.
	"5": hex_color("a22633"), "6": hex_color("6b1f2e"), "7": hex_color("181425"), "8": hex_color("181425"),
}

# Twenty rows from the cap's tip to the beard's point, which hangs over the chest (the
# head is painted after the torso). The cap's tip flops to his left with the pompom.
HEAD_FRONT = [
	"...........RRRr.............",
	"..........RRRRRrrr..........",
	"..........RRRRRrrrrr........",
	".........RRRRRRrrr.rrWW.....",
	".........RRRRRRrr....Wwg....",
	"........WWWWWWWWWWww.wg.....",
	".......WWWWWWWWWWWWwww......",
	"........sWWWssWWWsst........",
	"........ssessssesstt........",
	".......wpptsspssppttw.......",
	"......WWWWwppppppWWwwg......",
	"......WWWWWWWWWWWWWwwg......",
	"......WWWWWWqqqqWWWwwg......",
	".......WWWWWWWWWWWwwg.......",
	".......WWWWWWWWWWWwwg.......",
	"........WWWWWWWWWwwg........",
	"........WWWWWWWWwwgg........",
	".........WWWWWWwwgg.........",
	"..........WWWWwwg...........",
	"...........WWwg.............",
]
HEAD_BACK = [
	"...........RRRr.............",
	"..........RRRRRrrr..........",
	"..........RRRRRrrrrr........",
	".........RRRRRRrrr.rrWW.....",
	".........RRRRRRrr....Wwg....",
	"........WWWWWWWWWWww.wg.....",
	".......WWWWWWWWWWWWwww......",
	"........WWWWWWWWWwww........",
	".......wWWWWWWWWwwwgg.......",
	".......wWWWWWWWwwwwgg.......",
	"......WWwWWWWWwwwwggWg......",
	"......WWW.wwwwwwgg..Wg......",
	"......WWW..sssstt..wWg......",
	".......WW..........wg.......",
]
# Shoulders, arms hanging by a round belly, the belt and buckle, the fur hem. The arms are
# split from the body by the shade colour; the mittens rest at the belt.
TORSO_FRONT = [
	"........RRRRRRRRRRrr........",
	"......RRRRRRRRRRRRRrrr......",
	".....RRRrRRRRRRRRRRrqrr.....",
	"....RRRRrRRRRRRRRRRrqrrr....",
	"....RRRrRRRRRRRRRRRRrqrr....",
	"...RRRrRRRRRRRRRRRRRrqrrr...",
	"...RRRrRRRRRRRRRRRRRRqrrr...",
	"...RRRrRRRRRRRRRRRRRRqrrr...",
	"...WWwkkkkkkkYYykkkkkkwww...",
	"...kkkqRRRRRRYyyRRRRrqkkk...",
	"...kkk.WWWWWWWWWWWWwww.kk...",
	"......WWWWWWWWWWWWWwwww.....",
	".......WWWWWWWWWWWwwwg......",
]
TORSO_BACK = [
	"........RRRRRRRRRRrr........",
	"......RRRRRRRRRRRRRrrr......",
	".....RRRrRRRRRRRRRRrqrr.....",
	"....RRRRrRRRRRRRRRRrqrrr....",
	"....RRRrRRRRRRRRRRRRrqrr....",
	"...RRRrRRRRRRRRRRRRRrqrrr...",
	"...RRRrRRRRRRRRRRRRRRqrrr...",
	"...RRRrRRRRRRRRRRRRRRqrrr...",
	"...WWwkkkkkkkkkkkkkkkkwww...",
	"...kkkqRRRRRRRRRRRRRrqkkk...",
	"...kkk.WWWWWWWWWWWWwww.kk...",
	"......WWWWWWWWWWWWWwwww.....",
	".......WWWWWWWWWWWwwwg......",
]
# The sack: over his left shoulder, so from the front it bulges out behind his right side
# (painted first, the body covers most of it); from behind it covers his back.
SACK_FRONT = [
	"......................cc....",
	".....................BBBb...",
	"....................BBBBbb..",
	"...................BBBBBbbb.",
	"...................BBBBBbbb.",
	"...................BBBBbbbb.",
	"...................BBBBbbbb.",
	"....................BBbbbb..",
]
SACK_FRONT_TOP = 14
SACK_BACK = [
	"...........cc...............",
	"..........BBBBb.............",
	"........BBBBBBBbb...........",
	".......BBBBBBBBBbbb.........",
	".......BBBBBBBBBbbb.........",
	".......BBBBBBBBbbbb.........",
	".......BBBBBBBbbbbb.........",
	".......BBBBBBbbbbbb.........",
	"........BBBbbbbbbb..........",
	"..........bbbbbb............",
]
SACK_BACK_TOP = 18

LEGS = {
	"stand": [
		".........11111111111........",
		"........1111.....1111.......",
		"........2222.....2222.......",
		".......22222.....22222......",
		".......33333.....33333......",
	],
	# Walking towards: one boot lifted a row.
	"lift_left": [
		".........11111111111........",
		"........2222.....1111.......",
		".......22222.....2222.......",
		".......33333.....22222......",
		".................33333......",
	],
	"lift_right": [
		".........11111111111........",
		"........1111.....2222.......",
		"........2222.....22222......",
		".......22222.....33333......",
		".......33333................",
	],
	# Walking right: reach with the near leg, pass, reach with the far leg, pass. Boots
	# point right; the far leg is the darker one.
	"stride_near": [
		".........11111111111........",
		".......5555.....11111.......",
		"......7777.......22222......",
		".....7777........222222.....",
		".....8888........333333.....",
	],
	"pass_near": [
		".........11111111111........",
		"..........11115555..........",
		"..........22227777..........",
		"..........222227777.........",
		"..........33333.............",
	],
	"stride_far": [
		".........11111111111........",
		".......1111.....55555.......",
		"......2222.......77777......",
		".....2222........777777.....",
		".....3333........888888.....",
	],
	"pass_far": [
		".........11111111111........",
		"..........55551111..........",
		"..........77772222..........",
		"..........777772222.........",
		"..........88888.............",
	],
}

TOWARDS = [("stand", 0), ("lift_left", -1), ("stand", 0), ("lift_right", -1)]
RIGHT = [("stride_near", 0), ("pass_near", -1), ("stride_far", 0), ("pass_far", -1)]

# Off duty, after Christmas: no cap, no beard, no sack. Short white hair, brows pulled down
# into a V, a scar through his left brow, narrowed eyes, a smirk, grey stubble on a square
# jaw and a thick neck. The coat hangs open over a black tee.
OFF_HEAD_FRONT = [
	"........WWWWWWWWwww.........",
	".......WWWWWWWWWWwwg........",
	".......wwWWWWWWWwwggg.......",
	".......wssssssssspstg.......",
	".......sggssssssspggt.......",
	".......ssgggssssgggtt.......",
	".......ssseessssseett.......",
	".......ssssssttsssptt.......",
	".......wsssssttssssst.......",
	".......wwskkkkkkqsswg.......",
	".......wwwwwwwwwwwwwg.......",
	"........wwwwwwwwwwgg........",
	".........ttsssssstt.........",
	".........ttsssssstt.........",
]
OFF_HEAD_BACK = [
	"........WWWWWWWWwww.........",
	".......WWWWWWWWWWwwg........",
	".......wWWWWWWWWWwwgg.......",
	".......wWWWWWWWWWwwgg.......",
	".......wWWWWWWWWwwwgg.......",
	".......wwWWWWWWwwwggg.......",
	".......swwwwwwwwwgggt.......",
	".......ssssssssssssst.......",
	".......ssssssssssssst.......",
	".......sssssssssssstt.......",
	"........sssssssssstt........",
	"........ssssssssstt.........",
	".........ttsssssstt.........",
	".........ttsssssstt.........",
]
OFF_HEAD_TOP = 6
# The tee under the open coat, lit on the left, with a gold chain hanging in a V.
TEE = ["WYKKKKYW", "WLYKKYKW", "WLKYyKKW", "WLKKKKKW", "WLKKKKKW", "WLKKKKKW", "WLKKKKKW", "WLKKKKKW"]


def _open_coat(rows: list[str]) -> list[str]:
	"""The coat open from the collar to the belt: fur edges with the tee between."""
	return [row[:10] + TEE[index] + row[18:] if index < len(TEE) else row for index, row in enumerate(rows)]


OFF_TORSO_FRONT = _open_coat(TORSO_FRONT)

LOOKS = {
	"joulupukki_40": dict(head_front=HEAD_FRONT, head_back=HEAD_BACK, head_top=HEAD_TOP,
		torso_front=TORSO_FRONT, torso_back=TORSO_BACK, sack=True),
	"pukki_40": dict(head_front=OFF_HEAD_FRONT, head_back=OFF_HEAD_BACK, head_top=OFF_HEAD_TOP,
		torso_front=OFF_TORSO_FRONT, torso_back=TORSO_BACK, sack=False),
}


def check(look: dict) -> None:
	grids = [look["head_front"], look["head_back"], look["torso_front"], look["torso_back"],
		SACK_FRONT, SACK_BACK, *LEGS.values()]
	for grid in grids:
		for row in grid:
			assert len(row) == BOX_WIDTH, f"row is {len(row)} wide: {row!r}"
			for char in row:
				assert char == "." or char in PALETTE, f"no colour for {char!r} in {row!r}"


def draw_frame(sheet: Image.Image, look: dict, column: int, row: int, *, back: bool, bob: int, legs: str) -> None:
	frame = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
	leg_rows = LEGS[legs]
	paint(frame, PALETTE, leg_rows, BOX_X, LEGS_TOP)
	# The belly sits a row lower on a bob up, so no gap opens above the legs.
	for gap_row in range(bob, 0):
		paint(frame, PALETTE, leg_rows[:1], BOX_X, LEGS_TOP + gap_row)
	if look["sack"] and not back:
		paint(frame, PALETTE, SACK_FRONT, BOX_X, SACK_FRONT_TOP + bob)
	paint(frame, PALETTE, look["torso_back"] if back else look["torso_front"], BOX_X, TORSO_TOP + bob)
	paint(frame, PALETTE, look["head_back"] if back else look["head_front"], BOX_X, look["head_top"] + bob)
	if look["sack"] and back:
		paint(frame, PALETTE, SACK_BACK, BOX_X, SACK_BACK_TOP + bob)
	sheet.alpha_composite(frame, (column * FRAME, row * FRAME))


def draw_sheet(look: dict) -> Image.Image:
	check(look)
	sheet = Image.new("RGBA", (FRAME * 4, FRAME * 4), (0, 0, 0, 0))
	for column, bob in enumerate((0, -1, 0)):
		draw_frame(sheet, look, column, 0, back=False, bob=bob, legs="stand")
		draw_frame(sheet, look, column, 1, back=True, bob=bob, legs="stand")
	for row, poses in ((2, TOWARDS), (3, RIGHT)):
		for column, (legs, bob) in enumerate(poses):
			draw_frame(sheet, look, column, row, back=False, bob=bob, legs=legs)
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
	sheets = {name: draw_sheet(look) for name, look in LOOKS.items()}
	for name, sheet in sheets.items():
		path = TEXTURE_DIR / f"{name}.png"
		sheet.save(path)
		print(f"wrote {path.name}")
		write_aseprite_source(path, args.force_aseprite)
	if args.preview:
		normal = Image.open(TEXTURE_DIR / "normaali_mies_32.png").convert("RGBA")
		image = Image.new("RGBA", (FRAME * 9, FRAME * 4), (40, 36, 48, 255))
		for index, sheet in enumerate(sheets.values()):
			image.alpha_composite(sheet, (FRAME * 4 * index, 0))
		for row in range(4):
			# A normal customer's idle frame, feet on the same row, for scale.
			image.alpha_composite(normal.crop((0, 0, 32, 32)), (FRAME * 8 + 4, row * FRAME + 8))
		image.resize((image.width * 4, image.height * 4), Image.NEAREST).save(args.preview)


if __name__ == "__main__":
	main()
