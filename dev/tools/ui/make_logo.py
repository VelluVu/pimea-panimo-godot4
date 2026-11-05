"""Draws the main menu's "PIMEÄ PANIMO" wordmark into assets/textures/ui/logo_wordmark.png,
gold sign lettering like a painted pub sign: a bright top edge on every stroke, a darker
amber foot, and a dark red shadow down and to the right (light from above, as in the
cellar). The letters are drawn at 1x with 3 px strokes, not an enlarged font, so the
logo has the same pixel size as everything else.

    python dev/tools/ui/make_logo.py

Writes an editable .aseprite source next to the PNG (dev/tools/sprites/aseprite_source.lua)
unless one exists; --force-aseprite rewrites it.
"""
import subprocess
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / "assets" / "textures" / "ui" / "logo_wordmark.png"
ASEPRITE = Path("C:/Program Files (x86)/Steam/steamapps/common/Aseprite/Aseprite.exe")
ASEPRITE_SCRIPT = ROOT / "dev" / "tools" / "sprites" / "aseprite_source.lua"

LIGHT = (255, 236, 150, 255)
GOLD = (242, 201, 76, 255)
FOOT = (214, 150, 52, 255)
SHADOW = (110, 34, 22, 255)

LETTER_GAP = 2
WORD_GAP = 7
## Room above the capitals for the umlaut dots.
HEADROOM = 3

LETTERS = {
	"P": [
		"#########..",
		"##########.",
		"###########",
		"###.....###",
		"###.....###",
		"###.....###",
		"###########",
		"##########.",
		"#########..",
	] + ["###........"] * 7,
	"I": ["#######"] * 3 + ["..###.."] * 10 + ["#######"] * 3,
	"M": [
		"####.....####",
		"#####...#####",
		"######.######",
		"#############",
		"###.#####.###",
		"###..###..###",
		"###...#...###",
	] + ["###.......###"] * 9,
	"E": ["##########"] * 3 + ["###......."] * 3 + ["########.."] * 3 + ["###......."] * 4 + ["##########"] * 3,
	"A": [
		"..########..",
		".##########.",
		"############",
	] + ["###......###"] * 4 + ["############"] * 3 + ["###......###"] * 6,
	"N": [
		"####.....###",
		"#####....###",
		"######...###",
		"###.###..###",
		"###..###.###",
		"###...######",
		"###....#####",
		"###.....####",
	] + ["###......###"] * 8,
	"O": [
		"..########..",
		".##########.",
		"############",
	] + ["###......###"] * 10 + [
		"############",
		".##########.",
		"..########..",
	],
}
## Ä is A with two 2x2 dots over its legs.
UMLAUT_DOTS = ((2, 0), (8, 0))


def word_mask(text: str) -> list:
	height = HEADROOM + 16
	columns = []
	for index, char in enumerate(text):
		if char == " ":
			columns += [[False] * height for _ in range(WORD_GAP)]
			continue
		rows = LETTERS["A" if char == "Ä" else char]
		width = len(rows[0])
		for x in range(width):
			column = [False] * HEADROOM + [rows[y][x] == "#" for y in range(16)]
			if char == "Ä":
				for dx, dy in UMLAUT_DOTS:
					if dx <= x < dx + 2:
						column[dy] = column[dy + 1] = True
			columns.append(column)
		if index < len(text) - 1 and text[index + 1] != " ":
			columns += [[False] * height for _ in range(LETTER_GAP)]
	return [[columns[x][y] for x in range(len(columns))] for y in range(height)]


def draw(mask: list) -> Image.Image:
	height, width = len(mask), len(mask[0])
	on = lambda x, y: 0 <= x < width and 0 <= y < height and mask[y][x]
	img = Image.new("RGBA", (width + 1, height + 2), (0, 0, 0, 0))
	px = img.load()
	# Shadow first: one pixel right, one and two down.
	for y in range(height):
		for x in range(width):
			if on(x, y):
				px[x + 1, y + 1] = SHADOW
				px[x + 1, y + 2] = SHADOW
	for y in range(height):
		for x in range(width):
			if not on(x, y):
				continue
			if not on(x, y - 1):
				px[x, y] = LIGHT
			elif not on(x, y + 1) or not on(x, y + 2):
				px[x, y] = FOOT
			else:
				px[x, y] = GOLD
	return img


def write_aseprite_source(force: bool) -> None:
	source = OUT.with_suffix(".aseprite")
	if not ASEPRITE.exists():
		print("Aseprite not found, no .aseprite source written:", ASEPRITE)
		return
	if source.exists() and not force:
		return
	subprocess.run([str(ASEPRITE), "-b", "--script-param", f"png={OUT}", "--script-param", f"out={source}",
					"--script", str(ASEPRITE_SCRIPT)], check=True)
	print("wrote", source.relative_to(ROOT))


def main() -> None:
	img = draw(word_mask("PIMEÄ PANIMO"))
	OUT.parent.mkdir(parents=True, exist_ok=True)
	img.save(OUT)
	print("wrote", OUT.relative_to(ROOT), img.size)
	write_aseprite_source("--force-aseprite" in sys.argv)


if __name__ == "__main__":
	main()
