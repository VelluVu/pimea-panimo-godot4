"""Draws Inttimies and Inttinainen, Finnish conscripts on leave: a green field cap with the
gold lion badge, an M05-style camouflage jacket (flat green with dark green, brown and
near-black flecks, a small Finnish flag on the sleeve), plain green trousers, black combat
boots ("maiharit") and a big rinkka on the back, its top and rolled sleeping mat showing over
the shoulder. He has a buzz cut and a leave-day grin; she has a low bun under the cap.

The sheets follow the other customers' (see customer_sheet.py): 128x128, 32 px frames, rows
idle, idle_up, walk_towards and walk_right, light from above left.

    python dev/tools/sprites/make_intti.py [--preview out.png] [--force-aseprite]
"""

import argparse
from pathlib import Path

from PIL import Image

from customer_sheet import FRAME, ROOT, TEXTURE_DIR, Look, draw_sheet, flat_clothes, hex_color
from make_orveltaja import write_aseprite_source

NAME = "inttimies_32"
NAARAS_NAME = "inttinainen_32"

PALETTE = {
    "s": hex_color("ead4aa"),  # skin
    "t": hex_color("e4a672"),  # skin shade, nose
    "e": hex_color("3a4466"),  # pupils
    "W": hex_color("ffffff"),  # eye whites, teeth
    "k": hex_color("3e2731"),  # mouth
    "h": hex_color("733e39"),  # buzz cut, her hair
    "L": hex_color("b86f50"),  # her bun highlight
    "C": hex_color("3e8948"),  # cap
    "c": hex_color("265c42"),  # cap shade, peak
    "Y": hex_color("feae34"),  # lion badge
    "G": hex_color("3e8948"),  # jacket
    "g": hex_color("265c42"),  # jacket shade
    "D": hex_color("265c42"),  # camo fleck, dark green
    "B": hex_color("3e2731"),  # camo fleck, dark brown
    "K": hex_color("193c3e"),  # camo fleck, near black
    "F": hex_color("ffffff"),  # flag
    "f": hex_color("124e89"),  # flag cross
    "S": hex_color("262b44"),  # rinkka straps
    "R": hex_color("5a6988"),  # rinkka
    "r": hex_color("3a4466"),  # rinkka shade
    "M": hex_color("8b9bb4"),  # rolled sleeping mat
    "m": hex_color("5a6988"),  # mat shade
    # Legs: green trousers bloused into black boots.
    "1": hex_color("265c42"), "4": hex_color("265c42"), "2": hex_color("262b44"), "3": hex_color("181425"),
}

# The rinkka's top and mat stick up behind the right shoulder.
HEAD_FRONT = [
    "....................",
    ".......CCCCCC.......",
    "......CCCCCCCc......",
    ".....CCCCYCCCCc.....",
    "....cccccccccccc....",
    ".....hsssssssst.....",
    ".....hsWWssWWth.....",
    ".....hsWestWeth.....",
    "...RRRsssttsstRRr...",
    "...RRRskWWWWktRRr...",
    "...RRRRtsssstRRRr...",
]
HEAD_BACK = [
    "....................",
    ".......CCCCCC.......",
    "......CCCCCCCc......",
    ".....CCCCCCCCCc.....",
    ".....ccccccccccc....",
    ".....hhhhhhhhhh.....",
    ".....thhhhhhhht.....",
    "...MMMhhhhhhhhMMMm..",
    "...MMMMsssssstMMMm..",
    "...RRRRRRRRRRRRRRr..",
    "...RRrrrrrrrrrrRRr..",
]
TORSO_FRONT = [
    "....GGSDDGGGSGGg....",
    "...GGGSGGGGGSKGGg...",
    "..GFfGSGGGBBSGGGGg..",
    "..GG.GSKGGGGSGg.DD..",
    "..DG.GKKGGGGGDg.Gg..",
    "..DG.GGGGGGGDDg.Gg..",
    ".....GGGBBGGGGg.....",
    ".....GGGGBGGGGg.....",
    ".....DDGGGGGKKg.....",
]
# From behind the rinkka covers the back, with a lid flap and side pockets.
TORSO_BACK = [
    "..GRRRRRRRRRRRRRrg..",
    "..GRRRRRRRRRRRRRrg..",
    "..GGRRRRRRRRRRRrGg..",
    "..GGRRRRRSRRRRRrGg..",
    "..DGRRRRRSRRRRRrGD..",
    "..GGRRRRRRRRRRRrGg..",
    "....RRRRRRRRRRRr....",
    ".....rrrrrrrrrrr....",
    ".....DDGGGGGKKg.....",
]

TORSO_FRONT = flat_clothes(TORSO_FRONT, {"G": "g"})

# Her: hair down to the jaw under the cap, lashes, a smaller smile, a low bun behind.
NAARAS_HEAD_FRONT = [
    "....................",
    ".......CCCCCC.......",
    "......CCCCCCCc......",
    ".....CCCCYCCCCc.....",
    "....cccccccccccc....",
    "....hhsssssssthh....",
    "....hhkWWssWWkhh....",
    "....hhsWestWethh....",
    "...RhhsssttssthhRr..",
    "...RRhtsskkssthRr...",
    "...RRRhtsssstRRRr...",
]
NAARAS_HEAD_BACK = [
    "....................",
    ".......CCCCCC.......",
    "......CCCCCCCc......",
    ".....CCCCCCCCCc.....",
    ".....ccccccccccc....",
    ".....hhhhhhhhhh.....",
    ".....thhhLhhhht.....",
    "...MMMhhLhhhhhMMMm..",
    "...MMMMhhhhhhtMMMm..",
    "...RRRRRRRRRRRRRRr..",
    "...RRrrrrrrrrrrRRr..",
]


def look(naaras: bool = False) -> Look:
    if naaras:
        return Look(palette=dict(PALETTE), head_front=NAARAS_HEAD_FRONT, head_back=NAARAS_HEAD_BACK,
                    torso_front=TORSO_FRONT, torso_back=TORSO_BACK, hand_inset=1)
    return Look(palette=dict(PALETTE), head_front=HEAD_FRONT, head_back=HEAD_BACK,
                torso_front=TORSO_FRONT, torso_back=TORSO_BACK)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="also write a 6x preview beside normaali_mies")
    parser.add_argument("--force-aseprite", action="store_true")
    parser.add_argument("--no-write", action="store_true", help="only the preview")
    args = parser.parse_args()
    sheets = {NAME: draw_sheet(look()), NAARAS_NAME: draw_sheet(look(True))}
    if not args.no_write:
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
