"""Draws Lavatanssija, the dance pavilion regular: silver hair combed back, a pencil
moustache, a plum velvet jacket with a red rose on the lapel, a white shirt and a black bow
tie, dark trousers and two-tone dance shoes. A slim, upright figure; the rose, the bow tie
and the light shoes make him read at 1x.

The sheet follows the other customers' (see customer_sheet.py): 128x128, 32 px frames,
rows idle, idle_up, walk_towards and walk_right, light from above left, and a fifth row
`dance`: a twirl for when he dances with the brewer (front with his hand raised, side, back
with the same hand raised, side flipped).

    python dev/tools/sprites/make_lavatanssija.py [--preview out.png] [--force-aseprite]
"""

import argparse
from pathlib import Path

from PIL import Image

from customer_sheet import (BOX_X, FRAME, HANDS_REST, RIGHT, ROOT, STILL, TEXTURE_DIR, Look, draw_frame, draw_sheet,
                            hex_color, paint)
from make_orveltaja import write_aseprite_source

NAME = "lavatanssija_32"

PALETTE = {
    "s": hex_color("ead4aa"),  # skin
    "t": hex_color("e4a672"),  # skin shade
    "e": hex_color("3a4466"),  # eyes
    "k": hex_color("3e2731"),  # mouth
    "Q": hex_color("c0cbdc"),  # silver hair, lit
    "P": hex_color("8b9bb4"),  # silver hair
    "p": hex_color("5a6988"),  # hair shade
    "J": hex_color("b55088"),  # velvet, lit
    "j": hex_color("68386c"),  # velvet
    "K": hex_color("3e2731"),  # velvet shade
    "W": hex_color("ffffff"),  # shirt
    "w": hex_color("c0cbdc"),  # shirt collar from behind
    "b": hex_color("181425"),  # bow tie
    "R": hex_color("e43b44"),  # rose
    "r": hex_color("a22633"),  # rose shade
    # Legs: dark trousers and two-tone dance shoes.
    "1": hex_color("3a4466"), "4": hex_color("3a4466"), "2": hex_color("c0cbdc"), "3": hex_color("181425"),
}

HEAD_FRONT = [
    "......QQQPPPPp......",
    ".....QQPPPPPPPp.....",
    "......Pssssssp......",
    "......sWWssWWt......",
    "......sWestWet......",
    "......sssttsst......",
    "......ssppppst......",
    "......tsskksst......",
    ".......tsssst.......",
]
HEAD_BACK = [
    "......QQQPPPPp......",
    ".....QQPPPPPPPp.....",
    ".....QPPPPPPPPp.....",
    "......PPPPPPPp......",
    "......PPPPPPPp......",
    "......PPPPPPPp......",
    "......tPPPPPpt......",
    ".......ssssst.......",
]
# Slim: the arms hang close to the body (hand_inset 1). The shirt narrows from the bow tie
# into the buttoned jacket; the rose sits on his left lapel.
TORSO_FRONT = [
    "....jjjWbbbbWjjj....",
    "...jjjRRWWWWjjjjj...",
    "...jj.jrjWWjjj.jj...",
    "...jj.jjjjjjjj.jj...",
    "...jj.jjjjjjjj.jj...",
    "...jj.jjjjjjjj.jj...",
    "......jjjjjjjj......",
    "......jjjjjjjj......",
    "......11111111......",
]
TORSO_BACK = [
    "....jjjjwwwwjjjj....",
    "...jjjjjjjjjjjjjj...",
    "...jj.jjjjjjjj.jj...",
    "...jj.jjjjjjjj.jj...",
    "...jj.jjjjjjjj.jj...",
    "...jj.jjjjjjjj.jj...",
    "......jjjjjjjj......",
    "......jjjjjjjj......",
    "......11111111......",
]


# The raised arm: sleeve from the shoulder up past the head, the hand on top.
RAISED_ARM_FRONT = ["st", "st", "jj", "jj", "jj", "jj", "jj", "jj"]
RAISED_ARM_BACK = ["st", "st", "jj", "jj", "jj", "jj", "jj", "jj"]
RAISED_ARM_TOP = 3


def _without_arm(torso: list[str], first: int) -> list[str]:
    """The torso with the arm at columns first..first+1 cleared below the shoulders."""
    rows = list(torso)
    for index in range(2, 6):
        row = rows[index]
        rows[index] = row[:first] + ".." + row[first + 2:]
    return rows


def draw_dance_row(sheet: Image.Image, front: Look, arm_front: list[str], arm_back: list[str]) -> None:
    def raised(arm: list[str], column: int):
        return lambda frame, palette, upper: paint(frame, palette, arm, BOX_X + column, upper + RAISED_ARM_TOP)

    draw_frame(sheet, front, 0, 4, back=False, bob=0, legs="stand", hands=(HANDS_REST[0], None),
               torso=_without_arm(front.torso_front, 15), extra=raised(arm_front, 15))
    legs, bob, hands, _trail = RIGHT[1]
    draw_frame(sheet, front, 1, 4, back=False, bob=bob, legs=legs, hands=hands, trail=STILL)
    draw_frame(sheet, front, 2, 4, back=True, bob=0, legs="stand", hands=(None, HANDS_REST[1]),
               torso=_without_arm(front.torso_back, 3), extra=raised(arm_back, 3))
    side = sheet.crop((FRAME, FRAME * 4, FRAME * 2, FRAME * 5)).transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    sheet.alpha_composite(side, (FRAME * 3, FRAME * 4))


# Her: a silver-grey perm with a red rose pinned in it, red lips, a pearl necklace and a
# royal blue dance dress whose skirt swings over the knees; red dance shoes.
NAARAS_NAME = "lavatanssija_naaras_32"
NAARAS_PALETTE = {
    **PALETTE,
    "Q": hex_color("c0cbdc"),  # perm, lit
    "P": hex_color("8b9bb4"),  # perm
    "p": hex_color("5a6988"),  # perm shade
    "D": hex_color("0099db"),  # dress, lit
    "d": hex_color("124e89"),  # dress
    "K": hex_color("262b44"),  # dress shade
    "W": hex_color("ffffff"),  # pearls
    "R": hex_color("e43b44"),  # lips, rose
    # Legs: skin under the skirt, red shoes.
    "1": hex_color("ead4aa"), "4": hex_color("ead4aa"), "2": hex_color("e43b44"), "3": hex_color("a22633"),
}
NAARAS_HEAD_FRONT = [
    ".....QQPQQPPPpp.....",
    "....QQPPQPPPPRr.....",
    ".....QPssssssPp.....",
    ".....PsWWssWWtp.....",
    ".....PsWestWetp.....",
    ".....Psssttsstp.....",
    ".....PsssRRsstp.....",
    ".....PPssssstPp.....",
    "......PPtsssPp......",
]
NAARAS_HEAD_BACK = [
    ".....QQPQQPPPpp.....",
    "....QQPPQPPPPRr.....",
    ".....QPPQPPPPPp.....",
    ".....PQPPPPQPpp.....",
    ".....PPPPPPPPpp.....",
    ".....PPPPPPPPpp.....",
    ".....tPPPPPPPpt.....",
    ".......ssssst.......",
]
NAARAS_TORSO_FRONT = [
    "....DDDssssssDDD....",
    "...DDDDDWWWWDDDDD...",
    "...DD.DDDDDDDD.DD...",
    "...DD.DDDDDDDD.DD...",
    "...DD.DDDDDDDD.DD...",
    "...DD.DDDDDDDD.DD...",
    "....DDDDDDDDDDD.....",
    "...DDDDDDDDDDDDD....",
    "...DDDDDDDDDDDDD....",
]
NAARAS_TORSO_BACK = [
    "....DDDDDDDDDDDD....",
    "...DDDDDDDDDDDDDD...",
    "...DD.DDDDDDDD.DD...",
    "...DD.DDDDDDDD.DD...",
    "...DD.DDDDDDDD.DD...",
    "...DD.DDDDDDDD.DD...",
    "....DDDDDDDDDDD.....",
    "...DDDDDDDDDDDDD....",
    "...DDDDDDDDDDDDD....",
]
# The skirt goes on over the knees, so the legs show only from the calf down.
SKIRT_HEM = ["...DDDDDDDDDDDDD....", "...ddddddddddddd...."]
NAARAS_ARM_FRONT = ["st", "st", "DD", "DD", "DD", "DD", "DD", "DD"]
NAARAS_ARM_BACK = ["st", "st", "DD", "DD", "DD", "DD", "DD", "DD"]


def _skirt(frame: Image.Image, palette: dict, upper: int, _back: bool) -> None:
    paint(frame, palette, SKIRT_HEM, BOX_X, upper + 19)


def look(naaras: bool = False) -> Look:
    if naaras:
        return Look(palette=NAARAS_PALETTE, head_front=NAARAS_HEAD_FRONT, head_back=NAARAS_HEAD_BACK,
                    torso_front=NAARAS_TORSO_FRONT, torso_back=NAARAS_TORSO_BACK, hand_inset=1, extra=_skirt)
    return Look(palette=PALETTE, head_front=HEAD_FRONT, head_back=HEAD_BACK,
                torso_front=TORSO_FRONT, torso_back=TORSO_BACK, hand_inset=1)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="also write a 5x preview")
    parser.add_argument("--force-aseprite", action="store_true")
    args = parser.parse_args()
    sheets = {}
    for name, naaras, arms in ((NAME, False, (RAISED_ARM_FRONT, RAISED_ARM_BACK)),
                               (NAARAS_NAME, True, (NAARAS_ARM_FRONT, NAARAS_ARM_BACK))):
        front = look(naaras)
        sheet = draw_sheet(front, extra_rows=1)
        draw_dance_row(sheet, front, *arms)
        path = TEXTURE_DIR / f"{name}.png"
        sheet.save(path)
        print(f"wrote {path.relative_to(ROOT)}")
        write_aseprite_source(path, args.force_aseprite)
        sheets[name] = sheet
    if args.preview:
        image = Image.new("RGBA", (FRAME * 8, FRAME * 5), (40, 36, 48, 255))
        for index, sheet in enumerate(sheets.values()):
            image.alpha_composite(sheet, (FRAME * 4 * index, 0))
        image.resize((image.width * 5, image.height * 5), Image.NEAREST).save(args.preview)


if __name__ == "__main__":
    main()
