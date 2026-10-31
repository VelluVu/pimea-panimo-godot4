"""Draws Persuasiakas: bald, a bit bulky and always cross. A shining bald head, brows pulled
down into a glare, flushed cheeks, a frown and a goatee; a sage bomber jacket open over a
white T-shirt and a belly, jeans and boots, and a pistol grip out of the waistband (he fires
it into the air when he does not get his beer: the fifth row, `shoot`). Wider at the shoulders and the belly than
the other customers, a bigger head and a row taller (lift 1), so the bulk reads in the
silhouette.

    python dev/tools/sprites/make_persuasiakas.py [--preview out.png]
"""

import argparse
from pathlib import Path

from customer_sheet import BOX_X, HANDS_REST, Look, draw_frame, draw_sheet, hex_color, paint, save

PALETTE = {
    "s": hex_color("ead4aa"),  # skin
    "t": hex_color("e4a672"),  # skin shade
    "h": hex_color("ffffff"),  # shine on the head, T-shirt
    "w": hex_color("ffffff"),  # eye white
    "e": hex_color("3a4466"),  # pupil
    "r": hex_color("f6757a"),  # flushed cheeks
    "a": hex_color("733e39"),  # brows, goatee
    "g": hex_color("c28569"),  # stubble
    "k": hex_color("3e2731"),  # mouth
    "L": hex_color("3e8948"), "J": hex_color("265c42"), "j": hex_color("193c3e"),  # bomber
    "O": hex_color("f77622"),  # bomber lining
    "c": hex_color("c0cbdc"),  # T-shirt shade
    "M": hex_color("8b9bb4"), "m": hex_color("3a4466"),  # pistol
    "Y": hex_color("fee761"), "W": hex_color("ffffff"), "o": hex_color("f77622"),  # muzzle flash
    "G": hex_color("8b9bb4"), "q": hex_color("c0cbdc"),  # gun smoke
    "1": hex_color("124e89"), "4": hex_color("124e89"), "2": hex_color("262b44"), "3": hex_color("181425"),
}

# Ten rows and eleven wide: a bigger head than the others'. The brows sit over the inner
# corners of the eyes and the pupils look in: a glare. The mouth corners turn down into the
# goatee.
HEAD_FRONT = [
    ".....shhssssst......",
    "....shsssssssst.....",
    "....ssssssssstt.....",
    "....sssssssssst.....",
    "....saaasssaaat.....",
    "...sswessssewstt....",
    "....srssttsssrt.....",
    "....sgskkkkksgt.....",
    "....sgkgggggkgt.....",
    "......gaaaaag.......",
]
HEAD_BACK = [
    ".....shhssssst......",
    "....shsssssssst.....",
    "....ssssssssstt.....",
    "....ssssssssstt.....",
    "....ssssssssstt.....",
    "...ssssssssssstt....",
    "....ssssssssstt.....",
    "....sssssssssst.....",
    "....ttttttttttt.....",
    ".....sssssssst......",
]
# The jacket hangs open: the lining shows down both edges and the T-shirt stretches over
# the belly, which pushes out past the hem.
TORSO_FRONT = [
    ".....LJOhhhhOJj.....",
    "...LLLJOhhhhOJjjj...",
    "..LLLLJOhhhhOJJjjj..",
    ".LLLLJJOhhhhOJJjjjj.",
    ".LLL.LJOhhhhcOj.jjj.",
    ".LLL.JOhhhhhhcO.jjj.",
    ".LLj.JOhhhhhhcO.jjj.",
    ".....JJhhhhhhcJM....",
    ".....jjjjjjjjjMm....",
]
TORSO_BACK = [
    ".....LJJJJJJJjj.....",
    "...LLLJJJJJJJJjjj...",
    "..LLLLJJJJJJJJJjjj..",
    ".LLLLJJJJJJJJJJjjjj.",
    ".LLL.LJJJJJJJJj.jjj.",
    ".LLL.LJJJJJJJJj.jjj.",
    ".LLj.LJJJJJJJJj.jjj.",
    ".....JJJJJJJJJj.....",
    ".....jjjjjjjjjj.....",
]


def look() -> Look:
    return Look(
        palette=PALETTE,
        head_front=HEAD_FRONT,
        head_back=HEAD_BACK,
        torso_front=TORSO_FRONT,
        torso_back=TORSO_BACK,
        lift=1,
    )


# The shoot row: his right arm is drawn by the action grids, so this torso has only the
# shoulder on that side, and the pistol is out of the waistband.
TORSO_SHOOTING = [
    ".....LJOhhhhOJj.....",
    "...LLLJOhhhhOJjjj...",
    "..LLLLJOhhhhOJJjjj..",
    ".LLLLJJOhhhhOJJjj...",
    ".LLL.LJOhhhhcOj.....",
    ".LLL.JOhhhhhhcO.....",
    ".LLj.JOhhhhhhcO.....",
    ".....JJhhhhhhcJ.....",
    ".....jjjjjjjjjj.....",
]
# Shouting as he fires: the mouth opens wide in the frown.
HEAD_SHOUTING = HEAD_FRONT[:7] + [
    "....sgkkkkkkkgt.....",
    "....sgkkkkkkkgt.....",
    "......gaaaaag.......",
]
# Action grids for box columns 14-21, from box row -3 down to 12: the right arm, the pistol
# pointing up, and the flash or smoke over the muzzle. Light from the left: the lit side of
# the barrel is M.
SHOOT_ACTIONS = [
    # Drawn: the arm bends out, the pistol comes up beside the shoulder.
    [
        "........",
        "........",
        "........",
        "........",
        "........",
        "........",
        "........",
        "........",
        "........",
        ".....Mm.",
        ".....Mm.",
        ".....st.",
        ".....st.",
        "....Jj..",
        "...Jj...",
        "..Jj....",
    ],
    # Fired: the arm straight up, the flash burst over the muzzle.
    [
        ".o..YY..",
        "..oYWWYo",
        ".oYWWWWY",
        "..oYWWYo",
        "....Mm..",
        "....Mm..",
        "....st..",
        "....st..",
        "....Jj..",
        "....Jj..",
        "...Jj...",
        "...Jj...",
        "..Jj....",
        "..Jj....",
        "........",
        "........",
    ],
    # The flash dies to a spark, the first smoke curls out.
    [
        "...qG...",
        "..q..Y..",
        "...YWY..",
        "....Y...",
        "....Mm..",
        "....Mm..",
        "....st..",
        "....st..",
        "....Jj..",
        "....Jj..",
        "...Jj...",
        "...Jj...",
        "..Jj....",
        "..Jj....",
        "........",
        "........",
    ],
    # The smoke drifts up and off to the right; the pistol stays up.
    [
        "....qqG.",
        "...q..G.",
        "....qG..",
        "....G...",
        "....Mm..",
        "....Mm..",
        "....st..",
        "....st..",
        "....Jj..",
        "....Jj..",
        "...Jj...",
        "...Jj...",
        "..Jj....",
        "..Jj....",
        "........",
        "........",
    ],
]
SHOOT_ROW = 4
ACTION_LEFT_COLUMN = 14
ACTION_TOP_ROW = -3


def _draw_shoot_row(sheet, character: Look) -> None:
    for column, action in enumerate(SHOOT_ACTIONS):
        head = HEAD_SHOUTING if column in (1, 2) else None

        def arm(frame, palette, upper, action=action) -> None:
            paint(frame, palette, action, BOX_X + ACTION_LEFT_COLUMN, upper + ACTION_TOP_ROW)

        draw_frame(sheet, character, column, SHOOT_ROW, back=False, bob=0, legs="stand",
                   hands=(HANDS_REST[0], None), torso=TORSO_SHOOTING, head=head, extra=arm)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="also write a 4x preview here")
    args = parser.parse_args()
    character = look()
    sheet = draw_sheet(character, extra_rows=1)
    _draw_shoot_row(sheet, character)
    save({"persuasiakas_32": sheet}, args.preview)


if __name__ == "__main__":
    main()
