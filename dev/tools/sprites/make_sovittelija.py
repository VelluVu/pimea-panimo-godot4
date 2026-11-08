"""Draws Sovittelija, the national labour mediator on the third night of talks: messy grey
hair with a tuft standing up, dark rings under half-shut eyes, a rumpled grey suit with the
shirt tail out, a loosened red tie, a leather briefcase in one hand and a pulla in the other.
The female counterpart (sovittelija_naaras_32) is slimmer, with a grey bob and red lips.
The briefcase makes the silhouette. From behind the hands swap; that row is drawn again with
the light still from the upper left, not mirrored.

The sheet follows the other customers' (see customer_sheet.py): 128x128, 32 px frames,
rows idle, idle_up, walk_towards and walk_right, light from above left.

    python dev/tools/sprites/make_sovittelija.py [--preview out.png] [--force-aseprite]
"""

import argparse
from pathlib import Path

from PIL import Image

from customer_sheet import (FRAME, HANDS_REST, ROOT, STILL, TEXTURE_DIR, Held, Look, check, draw_frame, draw_sheet,
                            hex_color)
from make_orveltaja import write_aseprite_source

NAME = "sovittelija_32"
NAARAS_NAME = "sovittelija_naaras_32"

PALETTE = {
    "s": hex_color("ead4aa"),  # skin
    "t": hex_color("e4a672"),  # skin shade
    "b": hex_color("c28569"),  # rings under the eyes
    "e": hex_color("262b44"),  # eyes
    "k": hex_color("3e2731"),  # mouth
    "r": hex_color("e43b44"),  # tie, lips
    "W": hex_color("c0cbdc"),  # lit grey hair
    "G": hex_color("8b9bb4"),  # grey hair
    "c": hex_color("5a6988"),  # hair shade
    "w": hex_color("ffffff"),  # shirt
    "J": hex_color("5a6988"),  # suit
    "j": hex_color("3a4466"),  # suit shade
    "B": hex_color("733e39"),  # briefcase
    "D": hex_color("3e2731"),  # briefcase shade
    "Y": hex_color("feae34"),  # briefcase clasp
    "P": hex_color("d77643"),  # pulla
    "p": hex_color("be4a2f"),  # pulla shade
    # Legs: the suit's trousers, tired black shoes.
    "1": hex_color("5a6988"), "4": hex_color("5a6988"), "2": hex_color("3e2731"), "3": hex_color("181425"),
}

HEAD_FRONT = [
    "......W.GW..........",
    "......WWWWGG........",
    ".....WWWGGGGc.......",
    ".....Wsssssst.......",
    ".....sesssest.......",
    ".....bbssbbst.......",
    ".....ssstssst.......",
    ".....ssskksst.......",
    "......ssssst........",
]
HEAD_BACK = [
    "......W.GW..........",
    "......WWWWGG........",
    ".....WWWGGGGc.......",
    ".....WWGGGGGc.......",
    ".....WGGGGGGc.......",
    ".....WGGGGGGc.......",
    ".....sGGGGGGt.......",
    ".....sssssstt.......",
    "......sssst.........",
]
# Rows 10-18: the jacket open at a loosened tie, the shirt tail out at the hem.
TORSO_FRONT = [
    "....JJJswwsJJjj.....",
    "...JJJJwrrwJJjjj....",
    "..JJ.JJwrrwJJjj.jj..",
    "..JJ.JJJwrJJJjj.jj..",
    "..JJ.JJJJrJJJjj.jj..",
    "..JJ.JJJJjJJJjj.jj..",
    ".....JJJJjJJJjj.....",
    ".....jjjjjwwjjj.....",
    ".....1111111111.....",
]
TORSO_BACK = [
    "....JJJJJJJJJjj.....",
    "...JJJJJJJJJJjjj....",
    "..JJ.JJJJJJJJjj.jj..",
    "..JJ.JJJJJJJJjj.jj..",
    "..JJ.JJJJJJJJjj.jj..",
    "..JJ.JJJJJJJJjj.jj..",
    ".....JJJJJJJJjj.....",
    ".....jjjjjjjwjj.....",
    ".....1111111111.....",
]
NAARAS_HEAD_FRONT = [
    ".......WWGG.........",
    ".....WWWWGGGc.......",
    "....WWGssssGGc......",
    "....WGsssssstGc.....",
    "....WGsesssesGc.....",
    "....WGbbssbbtGc.....",
    "....WGssstsssGc.....",
    "....GGsssrrstcc.....",
    ".....c.sssst.c......",
]
NAARAS_HEAD_BACK = [
    ".......WWGG.........",
    ".....WWWWGGGc.......",
    "....WWWGGGGGGc......",
    "....WWGGGGGGGGc.....",
    "....WGGGGGGGGGc.....",
    "....WGGGGGGGGcc.....",
    "....WGGGGGGGGcc.....",
    ".....GGGGGGGcc......",
    "......ssssst........",
]
NAARAS_TORSO_FRONT = [
    "....JJJJswsJJJjj....",
    "...JJ.JJwrwJJj.jj...",
    "...JJ.JJJrJJJj.jj...",
    "...JJ.JJJrJJJj.jj...",
    "...JJ.JJJjJJJj.jj...",
    "...JJ.JJJjJJJj.jj...",
    "......JJJjJJJj......",
    "......jjjjjwjj......",
    "......11111111......",
]
NAARAS_TORSO_BACK = [
    "....JJJJJJJJJjjj....",
    "...JJ.JJJJJJJj.jj...",
    "...JJ.JJJJJJJj.jj...",
    "...JJ.JJJJJJJj.jj...",
    "...JJ.JJJJJJJj.jj...",
    "...JJ.JJJJJJJj.jj...",
    "......JJJJJJJj......",
    "......jjjjjjwj......",
    "......11111111......",
]
BRIEFCASE = [
    ".DDD.",
    "BBBBD",
    "BBYBD",
    "BBBBD",
    "DDDDD",
]
BRIEFCASE_ANCHOR = (-2, 2)
# Golden, with pearl sugar on top; the hand grips its underside.
PULLA = [
    ".PPP.",
    "PPsPp",
    "ppppp",
]
PULLA_ANCHOR = (-2, -2)


def look(naaras: bool = False) -> Look:
    return Look(
        palette=PALETTE,
        head_front=NAARAS_HEAD_FRONT if naaras else HEAD_FRONT,
        head_back=NAARAS_HEAD_BACK if naaras else HEAD_BACK,
        torso_front=NAARAS_TORSO_FRONT if naaras else TORSO_FRONT,
        torso_back=NAARAS_TORSO_BACK if naaras else TORSO_BACK,
        held=(Held(BRIEFCASE, BRIEFCASE_ANCHOR, trails=False), Held(PULLA, PULLA_ANCHOR, trails=False)),
    )


def draw_back_row(sheet: Image.Image, front: Look, naaras: bool) -> None:
    """From behind the briefcase is in the hand on the right and the pulla on the left."""
    back = look(naaras)
    back.palette = front.palette
    back.held = (Held(PULLA, PULLA_ANCHOR, trails=False), Held(BRIEFCASE, BRIEFCASE_ANCHOR, trails=False))
    check(back)
    sheet.paste((0, 0, 0, 0), (0, FRAME, FRAME * 4, FRAME * 2))
    for column, bob in enumerate((0, -1, 0)):
        draw_frame(sheet, back, column, 1, back=True, bob=bob, legs="stand", hands=HANDS_REST, trail=STILL)


def build(naaras: bool) -> Image.Image:
    front = look(naaras)
    sheet = draw_sheet(front)
    draw_back_row(sheet, front, naaras)
    return sheet


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="also write a 5x preview of both side by side")
    parser.add_argument("--force-aseprite", action="store_true")
    args = parser.parse_args()
    sheets = {NAME: build(False), NAARAS_NAME: build(True)}
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
