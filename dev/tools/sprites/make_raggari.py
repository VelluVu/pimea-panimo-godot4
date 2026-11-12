"""Draws Raggari, the American-car man: a tall black pompadour with long sideburns and a
ducktail at the back, a black leather jacket with the collar up over a white T-shirt, a gold
buckle and a key chain at the hip, jeans and black boots. The quiff and the white shirt
between the dark lapels make the silhouette. His female counterpart
(raggari_naaras_32) wears a red bandana knotted on top of black rolled bangs.

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


# Her: rockabilly, a red bandana knotted on top over black rolled bangs, red lips, hair to
# the jaw; the same leather jacket on a slimmer figure, and red flats.
NAARAS_NAME = "raggari_naaras_32"
NAARAS_PALETTE = {
    **PALETTE,
    "B": hex_color("e43b44"),  # bandana, lips
    "b": hex_color("a22633"),  # bandana shade
    "2": hex_color("e43b44"), "3": hex_color("a22633"),
}
NAARAS_HEAD_FRONT = [
    "......BB....Bb......",
    ".......BBbBBb.......",
    ".....BBBBBBBBBb.....",
    ".....QQPPQQPPPp.....",
    ".....Pssessestp.....",
    ".....Psssstsstp.....",
    ".....PsssBBsstp.....",
    ".....PPssssstPp.....",
    ".....PPPtssstPp.....",
]
NAARAS_HEAD_BACK = [
    "......BB....Bb......",
    ".......BBbBBb.......",
    ".....BBBBBBBBBb.....",
    ".....QPPPPPPPPp.....",
    ".....QPPPPPPPPp.....",
    ".....PPPPPPPPPp.....",
    ".....PPPPPPPPpp.....",
    ".....PPPPPPPPpp.....",
    "......PPPPPPpp......",
]
NAARAS_TORSO_FRONT = [
    "....JJJjWWWWjjKK....",
    "...JJJJjWWWWjjKKK...",
    "...JJ.JjWWWWjK.jK...",
    "...JJ.JjWwWWjK.jK...",
    "...JJ.JjWWWWjK.jK...",
    "...JJ.JjWwWWjK.jK...",
    "......JjWWWWjK......",
    "......KKKYYKKK......",
    "......11111111......",
]
NAARAS_TORSO_BACK = [
    "....JJJjjjjjjjKK....",
    "...JJJJjjjjjjjKKK...",
    "...JJ.JjjjjjjK.jK...",
    "...JJ.JjjjjjjK.jK...",
    "...JJ.JjjjjjjK.jK...",
    "...JJ.JjjjjjjK.jK...",
    "......JjjjjjjK......",
    "......KKKKKKKK......",
    "......11111111......",
]


def look(naaras: bool = False) -> Look:
    if naaras:
        return Look(palette=NAARAS_PALETTE, head_front=NAARAS_HEAD_FRONT, head_back=NAARAS_HEAD_BACK,
                    torso_front=NAARAS_TORSO_FRONT, torso_back=NAARAS_TORSO_BACK, hand_inset=1)
    return Look(palette=PALETTE, head_front=HEAD_FRONT, head_back=HEAD_BACK,
                torso_front=TORSO_FRONT, torso_back=TORSO_BACK)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="also write a 5x preview")
    parser.add_argument("--force-aseprite", action="store_true")
    args = parser.parse_args()
    sheets = {NAME: draw_sheet(look()), NAARAS_NAME: draw_sheet(look(True))}
    for name, sheet in sheets.items():
        path = TEXTURE_DIR / f"{name}.png"
        sheet.save(path)
        print(f"wrote {path.relative_to(ROOT)}")
        write_aseprite_source(path, args.force_aseprite)
    if args.preview:
        image = Image.new("RGBA", (FRAME * 8, FRAME * 4), (40, 36, 48, 255))
        for index, sheet in enumerate(sheets.values()):
            image.alpha_composite(sheet, (FRAME * 4 * index, 0))
        image.resize((image.width * 5, image.height * 5), Image.NEAREST).save(args.preview)


if __name__ == "__main__":
    main()
