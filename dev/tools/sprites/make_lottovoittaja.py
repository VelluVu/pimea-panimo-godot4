"""Draws Lottovoittaja, the lottery winner out to spend it: slicked-back hair, a fresh tan,
aviator sunglasses, a grin with one gold tooth, a brand-new blue tracksuit with a white stripe
on the cheque-side sleeve (seen from behind), open at the neck for the gold chain, white trainers, and the giant cardboard cheque
under his left arm. The cheque makes the silhouette. From behind it is under the other arm;
that row is drawn again with the light still from the upper left, not mirrored.

The sheet follows the other customers' (see customer_sheet.py): 128x128, 32 px frames,
rows idle, idle_up, walk_towards and walk_right, light from above left.

    python dev/tools/sprites/make_lottovoittaja.py [--preview out.png] [--force-aseprite]
"""

import argparse
from pathlib import Path

from PIL import Image

from customer_sheet import (BOX_X, FRAME, HANDS_REST, ROOT, STILL, TEXTURE_DIR, Held, Look, check, draw_frame,
                            draw_sheet, hex_color, paint)
from make_orveltaja import write_aseprite_source

NAME = "lottovoittaja_32"

PALETTE = {
    "s": hex_color("e4a672"),  # tanned skin
    "t": hex_color("b86f50"),  # skin shade
    "n": hex_color("d98663"),  # chest in the collar's shadow
    "h": hex_color("3e2731"),  # slicked hair
    "H": hex_color("181425"),  # hair shade
    "i": hex_color("5a6988"),  # hair gel shine
    "o": hex_color("262b44"),  # sunglasses
    "w": hex_color("c0cbdc"),  # lens glint, cheque shade
    "W": hex_color("ffffff"),  # teeth, stripes, cheque
    "g": hex_color("feae34"),  # gold chain, gold tooth
    "A": hex_color("0099db"),  # tracksuit
    "a": hex_color("124e89"),  # tracksuit shade, zip
    "B": hex_color("124e89"),  # cheque's header band
    "k": hex_color("3a4466"),  # the amount on the cheque
    "r": hex_color("e43b44"),  # signature
    # Legs: tracksuit trousers, white trainers.
    "1": hex_color("0099db"), "4": hex_color("0099db"), "2": hex_color("ffffff"), "3": hex_color("8b9bb4"),
}

HEAD_FRONT = [
    "......hhhhhh........",
    ".....hiihhhhH.......",
    ".....hhiihhhH.......",
    ".....hssssssh.......",
    ".....owooowot.......",
    ".....sssstsst.......",
    ".....sWWgWWst.......",
    "......ssssst........",
]
HEAD_BACK = [
    ".......hhhhhh.......",
    "......hhiihhhH......",
    "......hhhiihhH......",
    "......hhhhhhhH......",
    "......hhhhhhhH......",
    "......shhhhhht......",
    "......sssssstt......",
    ".......ssssst.......",
]
# Rows 10-18, shaped by the user's hand-edited idle frames: the tracksuit top open at the
# neck, the chain hanging in a V to its pendant, the shoulder joining the arm, a low hem.
TORSO_FRONT = [
    "....AAAnnnnAAaaa....",
    "...AAAAgnngAAaaaa...",
    "...A.AAAggAAAAaaaa..",
    "...A.AAAAaAAAAa.aa..",
    "...A.AAAAaAAAAa.aa..",
    "...A.AAAAaAAAAa.aa..",
    ".....AAAAaAAAAa.....",
    ".....AAAAaAAAAa.....",
    ".....aaaaaaaaaa.....",
]
TORSO_BACK = [
    "...AAAAAAAAAAaa.....",
    "..AAAAAAAAAAAaaa....",
    "..AAAAAAAAAAAAa.aW..",
    "..AA.AAAAAAAAAa.aW..",
    "..AA.AAAAAAAAAa.aW..",
    "..AA.AAAAAAAAAa.aW..",
    ".....AAAAAAAAAa.....",
    ".....AAAAAAAAAa.....",
    ".....aaaaaaaaaa.....",
]
# The giant cheque: a blue header, a long amount, a red signature; pressed under the arm.
CHEQUE = [
    "BBBBBBBBB",
    "WWWWWWWWw",
    "WkWkkWkkw",
    "WWWWWWWWw",
    "WWWWWrrrw",
    "wwwwwwwww",
]
# From the front the hand grips the bottom edge, so only one short stroke of the signature
# shows above it.
CHEQUE_FRONT = [*CHEQUE[:4], "WWWWWrWWw", CHEQUE[5]]
HAND_ON_CHEQUE = ["..", "st"]
CHEQUE_ANCHOR = (-6, -4)
CHEQUE_BACK_ANCHOR = (-2, -4)
# From behind the sleeve and hand come down in front of the cheque.
SLEEVE_BACK = [
    "aaa.",
    "aaaa",
    "aWaa",
    "aWaa",
    "awst",
]
SLEEVE_BACK_COLUMN = 14
SLEEVE_BACK_TOP = 13


def look() -> Look:
    return Look(
        palette=PALETTE,
        head_front=HEAD_FRONT,
        head_back=HEAD_BACK,
        torso_front=TORSO_FRONT,
        torso_back=TORSO_BACK,
        held=(Held(CHEQUE_FRONT, CHEQUE_ANCHOR, trails=False), None),
        hands=(HAND_ON_CHEQUE, ["st", "st"]),
    )


def draw_back_row(sheet: Image.Image, front: Look) -> None:
    """From behind the cheque is under the arm on the right."""
    back = look()
    back.palette = front.palette
    back.held = (None, Held(CHEQUE, CHEQUE_BACK_ANCHOR, trails=False))
    back.hands = None
    check(back)
    sheet.paste((0, 0, 0, 0), (0, FRAME, FRAME * 4, FRAME * 2))
    for column, bob in enumerate((0, -1, 0)):
        draw_frame(sheet, back, column, 1, back=True, bob=bob, legs="stand", hands=HANDS_REST, trail=STILL,
                   extra=lambda frame, palette, upper: paint(frame, palette, SLEEVE_BACK, BOX_X + SLEEVE_BACK_COLUMN,
                                                             upper + SLEEVE_BACK_TOP))


def build() -> Image.Image:
    front = look()
    sheet = draw_sheet(front)
    draw_back_row(sheet, front)
    return sheet


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="also write a 5x preview")
    parser.add_argument("--force-aseprite", action="store_true")
    args = parser.parse_args()
    sheet = build()
    path = TEXTURE_DIR / f"{NAME}.png"
    sheet.save(path)
    print(f"wrote {path.relative_to(ROOT)}")
    write_aseprite_source(path, args.force_aseprite)
    if args.preview:
        image = Image.new("RGBA", (FRAME * 4, FRAME * 4), (40, 36, 48, 255))
        image.alpha_composite(sheet, (0, 0))
        image.resize((image.width * 5, image.height * 5), Image.NEAREST).save(args.preview)


if __name__ == "__main__":
    main()
