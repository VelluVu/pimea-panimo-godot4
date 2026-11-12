"""Draws Raggari, the American-car man: a tall black pompadour with long sideburns and a
ducktail at the back, a black leather jacket with the collar up over a white T-shirt, a gold
buckle and a key chain at the hip, jeans and black boots. The quiff and the white shirt
between the dark lapels make the silhouette.

The sheet follows the other customers' (see customer_sheet.py): 128x128, 32 px frames,
rows idle, idle_up, walk_towards and walk_right, light from above left.

    python dev/tools/sprites/make_raggari.py [--preview out.png] [--force-aseprite]
"""

import argparse
from pathlib import Path

from PIL import Image

from customer_sheet import FRAME, ROOT, TEXTURE_DIR, Look, draw_sheet, hex_color
from make_orveltaja import write_aseprite_source

NAME = "raggari_32"

PALETTE = {
    "s": hex_color("ead4aa"),  # skin
    "t": hex_color("e4a672"),  # skin shade
    "e": hex_color("3a4466"),  # eyes
    "k": hex_color("3e2731"),  # mouth
    "Q": hex_color("3a4466"),  # hair shine
    "P": hex_color("262b44"),  # hair
    "p": hex_color("181425"),  # hair shade
    "J": hex_color("5a6988"),  # leather, lit
    "j": hex_color("3a4466"),  # leather
    "K": hex_color("262b44"),  # leather shade
    "W": hex_color("ffffff"),  # T-shirt
    "w": hex_color("c0cbdc"),  # T-shirt shade
    "Y": hex_color("feae34"),  # buckle, key chain
    # Legs: jeans and black boots.
    "1": hex_color("124e89"), "4": hex_color("124e89"), "2": hex_color("262b44"), "3": hex_color("181425"),
}

# The quiff rises and leans forward to the left; long sideburns and a lopsided grin.
HEAD_FRONT = [
    ".....QQQQPPp........",
    "....QQPPPPPPPp......",
    "...QPPPPPPPPPp......",
    "....pPPPPPPPPp......",
    "......PPssssPp......",
    "......Psessesp......",
    "......Psssstsp......",
    "......Pssssssp......",
    "......tssskkst......",
    ".......tsssst.......",
]
# From behind: the top of the quiff, and the ducktail where the two sides meet at the neck.
HEAD_BACK = [
    ".....QQQPPPp........",
    "....QPPPPPPPPp......",
    "...QPPPPPPPPPp......",
    "....QPPPPPPPPp......",
    "......PPPPPPPp......",
    "......PPPpPPPp......",
    "......PPPpPPPp......",
    "......PPPpPPPp......",
    "......tPPpPPpt......",
    ".......ssPpss.......",
]
# The collar stands up at the neck; the white shirt shows between the lapels down to the
# belt, with the gold buckle and a key chain on the right hip.
TORSO_FRONT = [
    "....JJJjWWWWjjjK....",
    "...JJJjjWWWWjjjKK...",
    "..JJJJjjWWWWjjjKKK..",
    "..JJ.JjjWwWWjjK.jK..",
    "..JJ.JjjWWWWjjK.jK..",
    "..JJ.JjjWwWWjjK.jK..",
    ".....JjjWWWWjjK.....",
    ".....KKKKYYKKKK.....",
    "......1111111Y......",
]
TORSO_BACK = [
    "....JJJjjjjjjjjK....",
    "...JJJjjjjjjjjjKK...",
    "..JJJJjjjjjjjjjKKK..",
    "..JJ.JjjjjjjjjK.jK..",
    "..JJ.JjjjjjjjjK.jK..",
    "..JJ.JjjjjjjjjK.jK..",
    ".....JjjjjjjjjK.....",
    ".....KKKKKKKKKK.....",
    "......Y1111111......",
]


def look() -> Look:
    return Look(palette=PALETTE, head_front=HEAD_FRONT, head_back=HEAD_BACK,
                torso_front=TORSO_FRONT, torso_back=TORSO_BACK)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="also write a 5x preview")
    parser.add_argument("--force-aseprite", action="store_true")
    args = parser.parse_args()
    sheet = draw_sheet(look())
    path = TEXTURE_DIR / f"{NAME}.png"
    sheet.save(path)
    print(f"wrote {path.relative_to(ROOT)}")
    write_aseprite_source(path, args.force_aseprite)
    if args.preview:
        image = Image.new("RGBA", sheet.size, (40, 36, 48, 255))
        image.alpha_composite(sheet)
        image.resize((image.width * 5, image.height * 5), Image.NEAREST).save(args.preview)


if __name__ == "__main__":
    main()
