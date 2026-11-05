"""Draws the top bar's 9x9 stat icons into assets/textures/ui/top_bar_icons.png.

One frame per icon, stacked top to bottom (see TopBarIcon in src/ui/stat_chip.gd for the
order). The coin, star and mug reuse the icon font's grids so both stay the same; the LVV
siren (dark, then lit near a raid) and the day calendar are drawn here. Light falls from
above, like the cellar lamp. Writes an editable .aseprite source next to the PNG.

    python dev/tools/ui/make_top_bar_icons.py [--force-aseprite]
"""
import argparse
import subprocess
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "dev" / "tools" / "icons"))
import make_icon_font  # noqa: E402

OUT = ROOT / "assets" / "textures" / "ui" / "top_bar_icons.png"
ASEPRITE = Path("C:/Program Files (x86)/Steam/steamapps/common/Aseprite/Aseprite.exe")
ASEPRITE_SCRIPT = ROOT / "dev" / "tools" / "sprites" / "aseprite_source.lua"
SIZE = 9

# The icon font's colours, plus the siren's dome ramp: dark when risk is low, lit near a raid.
PALETTE = dict(make_icon_font.PALETTE)
PALETTE.update({
	"d": "#7e2c22",  # dark dome, shade
	"D": "#b0483a",  # dark dome, lit top
	"R": "#ff7a52",  # lit dome, hot top
})

SIREN_OFF = [
	".........",
	".........",
	"...DDD...",
	"..DDddd..",
	"..Ddddd..",
	"..ddddd..",
	".ddddddd.",
	"SSSSSSSSS",
	".sssssss.",
]
SIREN_ON = [
	"y...y...y",
	".y.....y.",
	"...RRR...",
	"..RwRrr..",
	"..Rwrrr..",
	"..rrrrr..",
	".rrrrrrr.",
	"SSSSSSSSS",
	".sssssss.",
]
CALENDAR = [
	".S.....S.",
	"rrrrrrrrr",
	"rrrrrrrrr",
	"wwwwwwwww",
	"wSwSwSwSw",
	"wwwwwwwww",
	"wSwSwSwww",
	"wwwwwwwww",
	".........",
]

# Order matters: StatChip's TopBarIcon enum indexes these frames.
ICONS = [
	("coin", make_icon_font.ICONS[0x1FA99]),
	("star", make_icon_font.ICONS[0x2B50]),
	("siren_off", SIREN_OFF),
	("siren_on", SIREN_ON),
	("mug", make_icon_font.ICONS[0x1F37A]),
	("calendar", CALENDAR),
]


def draw() -> Image.Image:
	sheet = Image.new("RGBA", (SIZE, SIZE * len(ICONS)), (0, 0, 0, 0))
	for index, (name, rows) in enumerate(ICONS):
		if len(rows) != SIZE or any(len(row) != SIZE for row in rows):
			raise SystemExit(f"{name}: the grid must be {SIZE}x{SIZE}")
		for y, row in enumerate(rows):
			for x, char in enumerate(row):
				if char != ".":
					sheet.putpixel((x, index * SIZE + y), _rgba(PALETTE[char]))
	return sheet


def _rgba(value: str) -> tuple:
	value = value.lstrip("#")
	return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


def write_aseprite_source(png: Path, force: bool) -> None:
	out = png.with_suffix(".aseprite")
	if out.exists() and not force:
		print(f"kept {out.name} (pass --force-aseprite to redo it)")
		return
	if not ASEPRITE.exists():
		print("Aseprite not found, no .aseprite source written:", ASEPRITE)
		return
	subprocess.run([str(ASEPRITE), "-b", "--script-param", f"png={png}", "--script-param", f"out={out}",
					"--script-param", f"frames={len(ICONS)}", "--script-param", "tag=icons",
					"--script", str(ASEPRITE_SCRIPT)], check=True)
	print(f"wrote {out.name}")


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--force-aseprite", action="store_true")
	args = parser.parse_args()
	OUT.parent.mkdir(parents=True, exist_ok=True)
	draw().save(OUT)
	print(f"wrote {OUT.relative_to(ROOT)}")
	write_aseprite_source(OUT, args.force_aseprite)


if __name__ == "__main__":
	main()
