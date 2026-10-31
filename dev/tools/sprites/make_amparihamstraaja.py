"""Draws Ämpärihamstraaja, the bucket hoarder: a humanoid hamster who queued outside because
he thought there were free buckets, and now wants a bucket of beer. He wears his haul: a blue
bucket as his body, arms and legs out of it, and a yellow bucket upside down as a hat, his
round ears poking out under its rim. Cheeks stuffed full and buck teeth below. The two
buckets make the silhouette: a trapezoid on top, a bigger one under it. Blue is the
fur's opposite, so the body bucket never reads as a shirt.

He leaves with a third, red bucket full of bottles in hand (CustomerData.hand_item), drawn
here too as assets/textures/bucket_of_bottles.png at the sprite's own pixel size.

    python dev/tools/sprites/make_amparihamstraaja.py [--preview out.png]
"""

import argparse
from pathlib import Path

from PIL import Image

from customer_sheet import ROOT, Look, draw_sheet, hex_color, paint, save

PALETTE = {
    "F": hex_color("d77643"),  # fur
    "f": hex_color("be4a2f"),  # fur shade
    "m": hex_color("ead4aa"),  # muzzle, belly
    "M": hex_color("e4a672"),  # muzzle shade
    "P": hex_color("f6757a"),  # ears, nose, paws
    "k": hex_color("181425"),  # eyes, mouth, bucket handle
    "w": hex_color("ffffff"),  # eye glint, teeth
    "R": hex_color("0099db"), "r": hex_color("124e89"), "Q": hex_color("2ce8f5"),  # body bucket
    "C": hex_color("feae34"), "c": hex_color("f77622"), "H": hex_color("fee761"),  # hat bucket
    "1": hex_color("d77643"), "4": hex_color("be4a2f"), "2": hex_color("be4a2f"), "3": hex_color("f6757a"),
}

# Twelve rows: the hat bucket rises above the head line, a ridge round its bottom (now its
# top) and its rim the widest, lit part; the ears stick out under the rim. The cheeks stick out past the head on both sides.
HEAD_FRONT = [
    ".......HCCCCc.......",
    "......cccccccc......",
    "......HCCCCCCc......",
    ".....HCCCCCCCCc.....",
    "....PHHHHHHHHHHP....",
    "....FFFFFFFFFFFf....",
    "...FFFFFFFFFFFFFf...",
    "...FFwkFFFFFFwkFf...",
    "...FFkkFFFFFFkkff...",
    "..FmmmmmmPPmmmmmMf..",
    "..fmmmmmkwwkmmmmMf..",
    "...fMmmmmwwmmmmMf...",
]
HEAD_BACK = [
    ".......HCCCCc.......",
    "......cccccccc......",
    "......HCCCCCCc......",
    ".....HCCCCCCCCc.....",
    "....PHHHHHHHHHHP....",
    "....FFFFFFFFFFFf....",
    "...FFFFFFFFFFFFFf...",
    "...FFFFFFFFFFFFFf...",
    "...FFFFFFFFFFFFff...",
    "..FFFFFFFFFFFFFfff..",
    "..fFFFFFFFFFFFffff..",
    "...ffffffffffffff...",
]
# The body bucket: a lit rim under the chin, narrowing to the bottom, the arms out of its
# sides. The handle hangs in an arc across the front.
TORSO_FRONT = [
    "....QQQQQQQQQQQr....",
    "....kRRRRRRRRRRk....",
    "..FFRkRRRRRRRRkrff..",
    "..FF.RkRRRRRRkr.ff..",
    "..FF.RRkkkkkkRr.ff..",
    "..Ff.RRRRRRRRRr.ff..",
    "......rrrrrrrr......",
    "......RRRRRRRr......",
    "......rrrrrrrr......",
]
TORSO_BACK = [
    "....QQQQQQQQQQQr....",
    "....kRRRRRRRRRRk....",
    "..FFRRRRRRRRRRRrff..",
    "..FF.RRRRRRRRRr.ff..",
    "..FF.RRRRRRRRRr.ff..",
    "..Ff.RRRRRRRRRr.ff..",
    "......rrrrrrrr......",
    "......RRRRRRRr......",
    "......rrrrrrrr......",
]


def look() -> Look:
    return Look(
        palette=PALETTE,
        head_front=HEAD_FRONT,
        head_back=HEAD_BACK,
        torso_front=TORSO_FRONT,
        torso_back=TORSO_BACK,
        hand=["PP", "Pf"],
    )


# The bucket he carries out: the handle up to his paw, three bottle necks with their caps
# over the lit rim, the body narrowing to the bottom. Red, apart from the two he wears.
BUCKET_OF_BOTTLES = [
    ".kkkkkk.",
    "k.y.y.yk",
    "k.B.G.Bk",
    "XqqqqqqX",
    "XXXXXXXx",
    ".XXXXXx.",
    ".xxxxxx.",
]
BUCKET_PALETTE = {
    "k": hex_color("181425"),  # handle
    "y": hex_color("feae34"),  # bottle caps
    "B": hex_color("733e39"), "G": hex_color("3e8948"),  # brown and green bottles
    "q": hex_color("f6757a"), "X": hex_color("e43b44"), "x": hex_color("a22633"),  # bucket
}
BUCKET_PATH = ROOT / "assets/textures/bucket_of_bottles.png"


def draw_bucket() -> Image.Image:
    image = Image.new("RGBA", (len(BUCKET_OF_BOTTLES[0]), len(BUCKET_OF_BOTTLES)), (0, 0, 0, 0))
    paint(image, BUCKET_PALETTE, BUCKET_OF_BOTTLES, 0, 0)
    return image


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="also write a 4x preview here")
    args = parser.parse_args()
    save({"amparihamstraaja_32": draw_sheet(look())}, args.preview)
    draw_bucket().save(BUCKET_PATH)
    print(f"wrote {BUCKET_PATH.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
