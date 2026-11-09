"""Draws Presidentti ("onko tämä laillista?"), who ran here mid-triathlon and drinks only
alcohol-free: an Ironman winner in very good shape, so taller than the others (lift 2) with
broad bare shoulders, muscled arms and a narrow waist. A sleeveless blue tri-suit, long
shorts, the finisher's medal on a red ribbon, neon running shoes. Short light hair, big
sports glasses (a black rim over cyan lenses, the arms showing from behind) and a huge smile
with big front teeth hanging two rows down. The shapes follow the user's hand-edited idle frames.

    python dev/tools/sprites/make_presidentti.py [--preview out.png] [--force-aseprite]
"""

import argparse
from pathlib import Path

from customer_sheet import TEXTURE_DIR, Look, draw_sheet, hex_color, save
from make_orveltaja import write_aseprite_source

NAME = "presidentti_32"

PALETTE = {
    "s": hex_color("ead4aa"),  # skin
    "t": hex_color("e4a672"),  # skin shade, muscle lines
    "a": hex_color("c28569"), "A": hex_color("e8b796"),  # hair, its lit side
    "g": hex_color("181425"),  # glasses frame
    "k": hex_color("3e2731"),  # mouth
    "w": hex_color("ffffff"),  # teeth
    "H": hex_color("2ce8f5"), "C": hex_color("0099db"), "c": hex_color("124e89"),  # tri-suit, H also the lenses
    "R": hex_color("e43b44"), "Y": hex_color("fee761"), "y": hex_color("feae34"),  # ribbon, medal
    "1": hex_color("124e89"), "4": hex_color("ead4aa"), "2": hex_color("63c74d"), "3": hex_color("ffffff"),
}

# Eleven rows, a long face: a high forehead and a nose row between the glasses and the
# smile. The glasses: big, a pixel past the face on each side, a black rim over two cyan
# lenses. The two front teeth hang from the middle of the smile.
HEAD_FRONT = [
    "......AAAaaaaa......",
    ".....AAAaaaaaaa.....",
    ".....Aasssssssa.....",
    ".....ssssssssst.....",
    ".....sgggssgggt.....",
    "....ggHHHggHHHgg....",
    "....tsHHHtsHHHst....",
    "....tssssttsssst....",
    ".....sskkwwkkst.....",
    "......sskwwkst......",
    ".......ssssst.......",
]
HEAD_BACK = [
    "......AAAaaaaa......",
    ".....AAAaaaaaaa.....",
    ".....AAaaaaaaaa.....",
    ".....Aaaaaaaaaa.....",
    ".....Aaaaaaaaaa.....",
    "....gsaaaaaaaatg....",
    "....tsaaaaaaaatt....",
    "....tssaaaaaastt....",
    ".....sssssssstt.....",
    "......ssssssst......",
    ".......ssssst.......",
]
# A V from broad bare shoulders to a narrow waist, a gap under each arm. The ribbon runs
# from the neck to the medal on the chest.
TORSO_FRONT = [
    "....ssHRCCCCRctt....",
    "...sssHCRCCRCcttt...",
    "..sstsHCCRRCCcsttt..",
    "..sst.HCCCYCCc.ttt..",
    "..ss..HCCCyCCc..tt..",
    "..ss..HCCCCCCc..tt..",
    "..st..HCCCCCCc..tt..",
    "......HCCCCCCc......",
    ".....HCCCCCCCcc.....",
]
TORSO_BACK = [
    "....ssHCCCCCCctt....",
    "...sssHCCCCCCcttt...",
    "..sstsHCCCCCCcsttt..",
    "..sst.HCCCCCCc.ttt..",
    "..ss..HCCCCCCc..tt..",
    "..ss..HCCCCCCc..tt..",
    "..st..HCCCCCCc..tt..",
    "......HCCCCCCc......",
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
        long_shorts=1,
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="also write a 4x preview here")
    parser.add_argument("--force-aseprite", action="store_true")
    args = parser.parse_args()
    save({NAME: draw_sheet(look())}, args.preview)
    write_aseprite_source(TEXTURE_DIR / f"{NAME}.png", args.force_aseprite)


if __name__ == "__main__":
    main()
