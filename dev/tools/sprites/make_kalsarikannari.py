"""Draws Kalsarikännäri, the Finnish pantsdrunk: messy hair, stubble, a faded T-shirt over
white boxers, bare legs, grey woolly socks with a red stripe, brown felt slippers and a bag
of crisps in one hand. From behind the bag changes hands; that row is drawn again with the
light still from the upper left, not mirrored. The same script draws the female version
(kalsarikannari_naaras_32): a messy bun, an oversized grey T-shirt and pink pyjama shorts.

The sheet follows the other customers' (see customer_sheet.py): 128x128, 32 px frames,
rows idle, idle_up, walk_towards and walk_right, light from above left. The legs are its
own grids: the stepping walk of LEGS_STEPPED, but bare skin, socks and slippers.

    python dev/tools/sprites/make_kalsarikannari.py [--preview out.png] [--force-aseprite]
"""

import argparse
from pathlib import Path

from PIL import Image

from customer_sheet import (FRAME, HANDS_REST, ROOT, STILL, TEXTURE_DIR, Held,
                            Look, check, draw_frame, draw_sheet, hex_color)
from make_orveltaja import write_aseprite_source

NAME = "kalsarikannari_32"
NAARAS_NAME = "kalsarikannari_naaras_32"


SOCK = hex_color("c0cbdc")
STRIPE = hex_color("e43b44")

PALETTE = {
    "s": hex_color("ead4aa"),  # skin
    "t": hex_color("e4a672"),  # skin shade
    "e": hex_color("3a4466"),  # pupils
    "W": hex_color("ffffff"),  # eye whites
    "k": hex_color("3e2731"),  # mouth
    "b": hex_color("c28569"),  # stubble
    "L": hex_color("b86f50"),  # hair highlight
    "h": hex_color("733e39"),  # hair
    "H": hex_color("3e2731"),  # hair shade
    "G": hex_color("5a6988"),  # faded T-shirt
    "g": hex_color("3a4466"),  # T-shirt shade
    "w": hex_color("c0cbdc"),  # boxers shade
    "Y": hex_color("feae34"),  # crisps bag
    "y": hex_color("f77622"),  # crisps bag shade
    "C": hex_color("e43b44"),  # crisps bag band
    "c": hex_color("a22633"),  # band shade
    # Legs: white boxers, bare skin, woolly socks, slippers with a lighter top.
    "1": hex_color("ffffff"), "4": hex_color("ead4aa"), "2": hex_color("b86f50"), "3": hex_color("733e39"),
    "S": SOCK, "R": STRIPE,
    # The far leg: a shade of each, from the same ramps.
    "5": hex_color("c0cbdc"), "6": hex_color("e4a672"), "Z": hex_color("8b9bb4"), "X": hex_color("a22633"),
    "7": hex_color("733e39"), "8": hex_color("3e2731"),
}

# '1' boxers, '4' bare leg, 'S' sock, 'R' its stripe, '2' slipper, '3' its sole. Walking
# right the far leg is '5', '6', 'Z', 'X', '7' and '8'.
LEGS = {
    "stand": [
        "......111..111......",
        "......444..444......",
        "......444..444......",
        "......SSS..SSS......",
        "......RRR..RRR......",
        ".....2222..2222.....",
        ".....3333..3333.....",
    ],
    "lift_left": [
        "......111..111......",
        "......444..444......",
        "......SSS..444......",
        "......RRR..SSS......",
        ".....2222..RRR......",
        ".....3333..2222.....",
        "...........3333.....",
    ],
    "lift_right": [
        "......111..111......",
        "......444..444......",
        "......444..SSS......",
        "......SSS..RRR......",
        "......RRR..2222.....",
        ".....2222..3333.....",
        ".....3333...........",
    ],
    # The back foot pushes off heel up and toe down, the front one lands heel first.
    "stride_near": [
        ".......555.1111.....",
        "......666...444.....",
        ".....ZZZ.....SSS....",
        "....XXX......RRR....",
        "....777.......2222..",
        ".....777.....22222..",
        "......88.....333....",
    ],
    "pass_near": [
        ".......55111........",
        "......666444........",
        ".....ZZZ.444........",
        "....XXX..SSS........",
        "....777..RRR........",
        ".....88..2222.......",
        ".........3333.......",
    ],
    "stride_far": [
        ".......111.5555.....",
        "......444...666.....",
        ".....SSS.....ZZZ....",
        "....RRR......XXX....",
        "....222.......7777..",
        ".....222.....77777..",
        "......33.....888....",
    ],
    "pass_far": [
        ".......11555........",
        "......444666........",
        ".....SSS.666........",
        "....RRR..ZZZ........",
        "....222..XXX........",
        ".....33..7777.......",
        ".........8888.......",
    ],
}

# Hair sticking up in tufts and over the ears, stubble round the mouth.
HEAD_FRONT = [
    ".......h..hh.h......",
    "......hhhhhhhhh.....",
    ".....hLLhhhhhhH.....",
    ".....hhhhhhhhhH.....",
    ".....hhshhsshhH.....",
    ".....hsWWssWWtH.....",
    ".....hsWestWetH.....",
    "......sssttsst......",
    "......sbbskkbt......",
    ".......bbbbbb.......",
]
HEAD_BACK = [
    ".......h..hh.h......",
    "......hhhhhhhhh.....",
    ".....hLLhhhhhhH.....",
    ".....hLhhhhhhhH.....",
    ".....hhhhhhhhhH.....",
    ".....hhhhhhhhhH.....",
    ".....hhhhhhhhhH.....",
    "......hhhhhhhH......",
    "......thhhhhHt......",
    ".......ssssst.......",
]
# A plain T-shirt, short sleeves, the boxers' waistband under the hem.
TORSO_FRONT = [
    "....GGGGGGGGGGGg....",
    "...GGGGGGGGGGGGGg...",
    "..GGGGGGGGGGGGGGGg..",
    "..GG.GGGGGGGGGg.Gg..",
    "..ss.GGGGGGGGGg.st..",
    "..ss.GGGGGGGGGg.st..",
    ".....GGGGGGGGGg.....",
    ".....GGGGGGGGGg.....",
    "......1111111w......",
]
TORSO_BACK = TORSO_FRONT

# Held by its crimped top; it hangs and lags when walking.
CRISPS = [
    "CCCc",
    "YYYy",
    "YCYy",
    "YYYy",
    "YYYy",
    "yyyy",
]
CRISPS_ANCHOR = (-2, 0)
# In the right hand (from behind) it hangs on the outer side of that hand.
CRISPS_BACK_ANCHOR = (-1, 0)


# Her: a messy bun with a red scrunchie, an oversized grey T-shirt with sleeves to the
# elbow, pink pyjama shorts.
NAARAS_PALETTE = {
    **PALETTE,
    "G": hex_color("8b9bb4"),  # oversized T-shirt
    "g": hex_color("5a6988"),  # T-shirt shade
    "w": hex_color("e43b44"),  # shorts shade
    "1": hex_color("f6757a"),  # pyjama shorts
    "5": hex_color("e43b44"),  # far leg's shorts
}
NAARAS_HEAD_FRONT = [
    "........hLhh........",
    ".......hhhhhH.......",
    "........RRRR........",
    "......hLhhhhhH......",
    ".....hLhhhhhhhH.....",
    ".....hhhshhhshH.....",
    ".....hsWWssWWtH.....",
    ".....hsWestWetH.....",
    ".....hsssttsst......",
    "......tssskkst......",
    ".......tsssst.......",
]
NAARAS_HEAD_BACK = [
    "........hLhh........",
    ".......hhhhhH.......",
    "........RRRR........",
    "......hLhhhhhH......",
    ".....hLhhhhhhhH.....",
    ".....hhhhhhhhhH.....",
    ".....hhhhhhhhhH.....",
    ".....hhhhhhhhhH.....",
    "......hhhhhhhH......",
    "......tsssssst......",
    ".......ssssst.......",
]
NAARAS_TORSO_FRONT = [
    "....GGGGGGGGGGGg....",
    "...GGGGGGGGGGGGGg...",
    "..GGGGGGGGGGGGGGGg..",
    "..GG.GGGGGGGGGg.Gg..",
    "..GG.GGGGGGGGGg.Gg..",
    "..ss.GGGGGGGGGg.st..",
    ".....GGGGGGGGGg.....",
    ".....GGGGGGGGGg.....",
    "......1111111w......",
]


def look(naaras: bool = False) -> Look:
    if naaras:
        return Look(legs=LEGS, palette=NAARAS_PALETTE, head_front=NAARAS_HEAD_FRONT, head_back=NAARAS_HEAD_BACK,
                    torso_front=NAARAS_TORSO_FRONT, torso_back=NAARAS_TORSO_FRONT,
                    held=(Held(CRISPS, CRISPS_ANCHOR), None))
    return Look(legs=LEGS, palette=PALETTE, head_front=HEAD_FRONT, head_back=HEAD_BACK,
                torso_front=TORSO_FRONT, torso_back=TORSO_BACK, held=(Held(CRISPS, CRISPS_ANCHOR), None))


def draw_back_row(sheet: Image.Image, front: Look, naaras: bool) -> None:
    """From behind the bag is in the hand on the right."""
    back = look(naaras)
    back.palette = front.palette
    back.held = (None, Held(CRISPS, CRISPS_BACK_ANCHOR))
    check(back)
    sheet.paste((0, 0, 0, 0), (0, FRAME, FRAME * 4, FRAME * 2))
    for column, bob in enumerate((0, -1, 0)):
        draw_frame(sheet, back, column, 1, back=True, bob=bob, legs="stand", hands=HANDS_REST, trail=STILL)


def build(naaras: bool = False) -> Image.Image:
    front = look(naaras)
    sheet = draw_sheet(front)
    draw_back_row(sheet, front, naaras)
    return sheet


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="also write a 6x preview beside normaali_mies")
    parser.add_argument("--force-aseprite", action="store_true")
    args = parser.parse_args()
    sheets = {NAME: build(), NAARAS_NAME: build(True)}
    for name, sheet in sheets.items():
        path = TEXTURE_DIR / f"{name}.png"
        sheet.save(path)
        print(f"wrote {path.relative_to(ROOT)}")
        write_aseprite_source(path, args.force_aseprite)
    if args.preview:
        normal = Image.open(TEXTURE_DIR / "normaali_mies_32.png").convert("RGBA")
        images = [normal, *sheets.values()]
        image = Image.new("RGBA", (FRAME * 4 * len(images), FRAME * 4), (40, 36, 48, 255))
        for index, sheet in enumerate(images):
            image.alpha_composite(sheet, (FRAME * 4 * index, 0))
        image.resize((image.width * 6, image.height * 6), Image.NEAREST).save(args.preview)


if __name__ == "__main__":
    main()
