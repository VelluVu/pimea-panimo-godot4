"""Draws the New Year's Eve party hats the customers wear (Uudenvuodenaatto): a 6x8 cone with
a white pompom, two stripes and a brim band, in four colours. Light comes from above left,
so the cone's left half is the lit colour and the right half its shade; no outline, like
the customers. The frames are stacked top to bottom in party_hats.png; PartyHat picks one
per customer and seats it on the head.

    python dev/tools/sprites/make_party_hats.py [--preview out.png] [--force-aseprite]
"""

import argparse
import subprocess
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / "assets/textures/new_year/party_hats.png"
ASEPRITE = Path("C:/Program Files (x86)/Steam/steamapps/common/Aseprite/Aseprite.exe")
ASEPRITE_SCRIPT = Path(__file__).resolve().parent / "aseprite_source.lua"
WIDTH, HEIGHT = 6, 8


def _hex(value: str) -> tuple[int, int, int, int]:
    return (int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16), 255)


# 'W' pompom, 'g' its shade, 'A' cone lit, 'B' cone shade, 'S' stripe lit, 'T' stripe shade.
HAT = [
    "..Wg..",
    "..Wg..",
    "..AB..",
    "..SB..",
    ".AABB.",
    ".SSTT.",
    "AAABBB",
    "SSSTTT",
]
SHARED = {"W": _hex("ffffff"), "g": _hex("c0cbdc")}
# ENDESGA 32: red with gold, cyan with white, green with gold, pink with white.
COLOURS = [
    {"A": _hex("e43b44"), "B": _hex("a22633"), "S": _hex("fee761"), "T": _hex("feae34")},
    {"A": _hex("2ce8f5"), "B": _hex("0099db"), "S": _hex("ffffff"), "T": _hex("c0cbdc")},
    {"A": _hex("63c74d"), "B": _hex("3e8948"), "S": _hex("fee761"), "T": _hex("feae34")},
    {"A": _hex("f6757a"), "B": _hex("b55088"), "S": _hex("ffffff"), "T": _hex("c0cbdc")},
]


def draw() -> Image.Image:
    for row in HAT:
        assert len(row) == WIDTH, row
    sheet = Image.new("RGBA", (WIDTH, HEIGHT * len(COLOURS)), (0, 0, 0, 0))
    for index, colours in enumerate(COLOURS):
        palette = {**SHARED, **colours}
        for y, row in enumerate(HAT):
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
                    "--script-param", f"frames={len(COLOURS)}", "--script-param", "tag=colours",
                    "--script", str(ASEPRITE_SCRIPT)], check=True)
    print(f"wrote {out.name}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="also write the hats on a customer's head, 8x")
    parser.add_argument("--force-aseprite", action="store_true")
    args = parser.parse_args()
    sheet = draw()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(OUT)
    print(f"wrote {OUT.relative_to(ROOT)}")
    write_aseprite_source(OUT, args.force_aseprite)
    if args.preview:
        customer = Image.open(ROOT / "assets/textures/characters/normaali_mies_32.png").convert("RGBA").crop((0, 0, 32, 32))
        image = Image.new("RGBA", (32 * len(COLOURS), 40), (40, 36, 48, 255))
        for index in range(len(COLOURS)):
            image.alpha_composite(customer, (32 * index, 8))
            hat = sheet.crop((0, index * HEIGHT, WIDTH, (index + 1) * HEIGHT))
            image.alpha_composite(hat, (32 * index + 13, 8 + 4 - HEIGHT + 2))
        image.resize((image.width * 8, image.height * 8), Image.NEAREST).save(args.preview)


if __name__ == "__main__":
    main()
