"""Draws Snobi, the rich and difficult snob who wants only the best: a tall top hat, a gold
monocle, a curled moustache, a burgundy velvet jacket with a gold cravat and pocket square,
grey trousers, and a cane with a gold knob. The hat and the cane make the silhouette: the
only customer taller than the head line and the only one with a stick to the floor. The
eyelids hang half shut, looking down at the cellar; the monocle is a gold rim on the
outer side of his left eye.

    python dev/tools/sprites/make_snobi.py [--preview out.png]
"""

import argparse
from pathlib import Path

from customer_sheet import Held, Look, draw_sheet, hex_color, save

PALETTE = {
    "s": hex_color("ead4aa"),  # skin
    "t": hex_color("e4a672"),  # skin shade, eyelids
    "w": hex_color("ffffff"),  # eye white, shirt
    "e": hex_color("3a4466"),  # pupil
    "a": hex_color("3e2731"),  # hair, moustache
    "L": hex_color("3a4466"), "K": hex_color("262b44"), "k": hex_color("181425"),  # top hat
    "V": hex_color("b55088"), "U": hex_color("68386c"), "u": hex_color("3e2731"),  # velvet jacket
    "Y": hex_color("fee761"), "y": hex_color("feae34"),  # gold: cravat, monocle, knob
    "B": hex_color("733e39"),  # cane
    "1": hex_color("8b9bb4"), "4": hex_color("8b9bb4"), "2": hex_color("5a6988"), "3": hex_color("181425"),
}

# Eleven rows: the hat crown rises two rows above the other customers' heads. The band is
# the jacket's velvet. The monocle rings the right eye.
HEAD_FRONT = [
    "......LKKKKKk.......",
    "......LKKKKKk.......",
    "......LKKKKKk.......",
    "......VUUUUUu.......",
    "....LLKKKKKKKKk.....",
    ".....assssssssa.....",
    ".....sttsssttys.....",
    ".....swesssweyt.....",
    ".....ssstssssyt.....",
    ".....saaassaaat.....",
    ".......ssssss.......",
]
HEAD_BACK = [
    "......LKKKKKk.......",
    "......LKKKKKk.......",
    "......LKKKKKk.......",
    "......VUUUUUu.......",
    "....LLKKKKKKKKk.....",
    ".....aaaaaaaaaa.....",
    ".....aaaaaaaaaa.....",
    ".....saaaaaaaat.....",
    ".....ssaaaaaatt.....",
    "......ssssssss......",
    ".......ssssss.......",
]
# The shirt front narrows between the lapels to the cravat; the pocket square is on his
# left breast.
TORSO_FRONT = [
    ".....VVwYYywUuu.....",
    "....VVVUwYywUUuu....",
    "...VVVVUUwYwUUUuu...",
    "..VVVUUUUUwUYyUuuu..",
    "..VU.VUUUUyUUUu.uu..",
    "..VU.VUUUUUUUUu.uu..",
    "..Vu.VUUUUyUUUu.uu..",
    ".....VUUUUuUUUu.....",
    ".....VUUUUuUUUu.....",
]
TORSO_BACK = [
    ".....VVVVUUUUuu.....",
    "....VVVVUUUUUUuu....",
    "...VVVVUUUUUUUUuu...",
    "..VVVUUUUUUUUUUuuu..",
    "..VU.VUUUUUUUUu.uu..",
    "..VU.VUUUUUUUUu.uu..",
    "..Vu.VUUUUUUUUu.uu..",
    ".....VUUUUuUUUu.....",
    ".....VUUUUuUUUu.....",
]
# Gripped by the knob: the shaft runs behind the hand down to the floor.
CANE = [
    "Yy",
    ".B",
    ".B",
    ".B",
    ".B",
    ".B",
    ".B",
    ".B",
    ".B",
    ".B",
    ".k",
]


def look() -> Look:
    return Look(
        palette=PALETTE,
        head_front=HEAD_FRONT,
        head_back=HEAD_BACK,
        torso_front=TORSO_FRONT,
        torso_back=TORSO_BACK,
        held=(None, Held(CANE, (0, -1), trails=False)),
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="also write a 4x preview here")
    args = parser.parse_args()
    save({"snobi_32": draw_sheet(look())}, args.preview)


if __name__ == "__main__":
    main()
