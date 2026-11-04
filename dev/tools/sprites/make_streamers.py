"""Draws the New Year's paper streamers that hang from the cellar's ceiling beam: a twisted
ribbon 4 px wide, pinned at the top, its lit face ('A') and shaded back ('B') taking turns
down a zigzag so it reads as curling. Drawn at the room art's scale (1 px), light from above
left. Four streamers stacked top to bottom in streamers.png (each in a 4x30 frame): long
gold, short cyan, long pink, short green.

    python dev/tools/sprites/make_streamers.py [--preview out.png] [--force-aseprite]
"""

import argparse
import subprocess
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / "assets/textures/new_year/streamers.png"
ASEPRITE = Path("C:/Program Files (x86)/Steam/steamapps/common/Aseprite/Aseprite.exe")
ASEPRITE_SCRIPT = Path(__file__).resolve().parent / "aseprite_source.lua"
WIDTH, HEIGHT = 4, 30


def _hex(value: str) -> tuple[int, int, int, int]:
    return (int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16), 255)


PIN = ".kk."
# One turn of the twist: the face slides right, the back comes round to the left.
TWIST = [
    "AA..",
    ".AA.",
    "..BB",
    ".BB.",
]
TAIL = ["AA..", "A..."]
# (rows of twist turns, colour, shade)
STREAMERS = [
    (6, "fee761", "f77622"),
    (4, "2ce8f5", "0099db"),
    (6, "f6757a", "b55088"),
    (4, "63c74d", "3e8948"),
]


def rows_for(turns: int) -> list[str]:
    return [PIN] + TWIST * turns + TAIL


def draw() -> Image.Image:
    sheet = Image.new("RGBA", (WIDTH, HEIGHT * len(STREAMERS)), (0, 0, 0, 0))
    for index, (turns, colour, shade) in enumerate(STREAMERS):
        palette = {"A": _hex(colour), "B": _hex(shade), "k": _hex("3a4466")}
        rows = rows_for(turns)
        assert len(rows) <= HEIGHT, len(rows)
        for y, row in enumerate(rows):
            assert len(row) == WIDTH, row
            for x, char in enumerate(row):
                if char != ".":
                    sheet.putpixel((x, index * HEIGHT + y), palette[char])
    return sheet


def write_aseprite_source(png: Path, force: bool) -> None:
    out = png.with_suffix(".aseprite")
    if out.exists() and not force:
        print(f"kept {out.name} (pass --force-aseprite to redo it)")
        return
    if not ASEPRITE.exists():
        print("Aseprite not found, no .aseprite source written:", ASEPRITE)
        return
    subprocess.run([str(ASEPRITE), "-b", "--script-param", f"png={png}", "--script-param", f"out={out}",
                    "--script-param", f"frames={len(STREAMERS)}", "--script-param", "tag=streamers",
                    "--script", str(ASEPRITE_SCRIPT)], check=True)
    print(f"wrote {out.name}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="also write the streamers side by side, 10x")
    parser.add_argument("--force-aseprite", action="store_true")
    args = parser.parse_args()
    sheet = draw()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(OUT)
    print(f"wrote {OUT.relative_to(ROOT)}")
    write_aseprite_source(OUT, args.force_aseprite)
    if args.preview:
        image = Image.new("RGBA", ((WIDTH + 4) * len(STREAMERS), HEIGHT), (40, 36, 48, 255))
        for index in range(len(STREAMERS)):
            image.alpha_composite(sheet.crop((0, index * HEIGHT, WIDTH, (index + 1) * HEIGHT)), ((WIDTH + 4) * index + 2, 0))
        image.resize((image.width * 10, image.height * 10), Image.NEAREST).save(args.preview)


if __name__ == "__main__":
    main()
