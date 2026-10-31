"""Draws Presidentti ("onko tämä laillista?"), who ran here mid-triathlon and drinks only
alcohol-free: an Ironman winner in very good shape, so taller than the others (lift 2) with
broad bare shoulders, muscled arms and a narrow waist. A sleeveless blue tri-suit with
white side panels, a race number on its belt, the finisher's medal on a red ribbon, neon
running shoes. Short light hair, big clear glasses (a connected black frame with the eyes
showing through) and a huge smile with big front teeth hanging two rows down.

    python dev/tools/sprites/make_presidentti.py [--preview out.png]
"""

import argparse
from pathlib import Path

from customer_sheet import Look, draw_sheet, hex_color, save

PALETTE = {
    "s": hex_color("ead4aa"),  # skin
    "t": hex_color("e4a672"),  # skin shade, muscle lines
    "a": hex_color("c28569"), "A": hex_color("e8b796"),  # hair, its lit side
    "g": hex_color("181425"),  # glasses frame
    "e": hex_color("181425"),  # pupil
    "k": hex_color("3e2731"),  # mouth
    "w": hex_color("ffffff"),  # teeth, suit panels, race number
    "n": hex_color("181425"),  # race number digits
    "H": hex_color("2ce8f5"), "C": hex_color("0099db"), "c": hex_color("124e89"),  # tri-suit
    "R": hex_color("e43b44"), "Y": hex_color("fee761"), "y": hex_color("feae34"),  # ribbon, medal
    "1": hex_color("124e89"), "4": hex_color("ead4aa"), "2": hex_color("63c74d"), "3": hex_color("ffffff"),
}

# Eleven rows, a long face: a high forehead and a nose row between the glasses and the
# smile. The glasses: big, a pixel past the face on each side. A black frame, one bar over both
# eyes joined to a frame each side of them, with white either side of the pupil showing
# through, so they read as clear lenses and not as sunglasses. The two front teeth hang from the
# middle of the smile.
HEAD_FRONT = [
    "......AAAaaaaa......",
    ".....AAAaaaaaaa.....",
    ".....Aasssssssa.....",
    ".....ssssssssst.....",
    "....ggggggggggg.....",
    "....gwewgggwewgt....",
    "....tsssstssssst....",
    ".....ssssttsssst....",
    ".....skwwwwwwkt.....",
    "......sskwwkst......",
    ".......ssssst.......",
]
HEAD_BACK = [
    "......AAAaaaaa......",
    ".....AAAaaaaaaa.....",
    ".....AAaaaaaaaa.....",
    ".....Aaaaaaaaaa.....",
    ".....Aaaaaaaaaa.....",
    ".....gaaaaaaaag.....",
    "....tsaaaaaaaast....",
    ".....ssaaaaaatt.....",
    ".....sssssssstt.....",
    "......ssssssst......",
    ".......sssssst......",
]
# A V from broad bare shoulders to a narrow waist. The ribbon runs from the neck to the
# medal on the chest; the race number sits on the belt.
TORSO_FRONT = [
    "......sRCCCCRt......",
    "...sssHCRCCRCcttt...",
    "..sstsHCCRRCCcsttt..",
    "..sstswHCCYCcwsttt..",
    "..ss..wHCCyCcw..tt..",
    "..ss..wHCCCCcw..tt..",
    "..st..wHCCCCcw..tt..",
    "......cwnwnwwc......",
    ".....HCCCCCCCcc.....",
]
TORSO_BACK = [
    "......sCCCCCCt......",
    "...sssHCCCCCCcttt...",
    "..sstsHCCCCCCcsttt..",
    "..sstswHCCCCcwsttt..",
    "..ss..wHCCCCcw..tt..",
    "..ss..wHCCCCcw..tt..",
    "..st..wHCCCCcw..tt..",
    "......cccccccc......",
    ".....HCCCCCCCcc.....",
]


def look() -> Look:
    return Look(
        palette=PALETTE,
        head_front=HEAD_FRONT,
        head_back=HEAD_BACK,
        torso_front=TORSO_FRONT,
        torso_back=TORSO_BACK,
        lift=2,
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="also write a 4x preview here")
    args = parser.parse_args()
    save({"presidentti_32": draw_sheet(look())}, args.preview)


if __name__ == "__main__":
    main()
