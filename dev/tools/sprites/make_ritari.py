"""Draws Ritari, the medieval re-enactor who never steps out of character, in his best
armour with Finnish ornaments: a great helm with a gold rim and a gold cross on the face,
a blue and white plume, gold-trimmed pauldrons, a white tabard with the flag's blue cross
set toward the left as on the flag (plain white at the back), hanging over the hips, a leather belt with a gold buckle, a red heater shield with the gold
lion of the Finnish arms, and a steel sword with a gold crossguard. One thing gives him away:
a striped drinking straw pokes out of the eye slit. Shield, sword and plume make the silhouette.

The sheet follows the other customers' (see customer_sheet.py): 128x128, 32 px frames,
rows idle, idle_up, walk_towards and walk_right, plus knight (128x160), light from above left.

    python dev/tools/sprites/make_ritari.py [--preview out.png] [--force-aseprite]
"""

import argparse
from pathlib import Path

from PIL import Image

from customer_sheet import (BOX_X, FRAME, HANDS_REST, LEGS_TOP, ROOT, STILL, TEXTURE_DIR, Held, Look, check,
                            draw_frame, draw_sheet, hex_color, paint)
from make_orveltaja import write_aseprite_source

NAME = "ritari_32"

PALETTE = {
    "W": hex_color("ffffff"),  # tabard, plume, glint, straw stripe
    "w": hex_color("c0cbdc"),  # tabard shade
    "H": hex_color("c0cbdc"),  # steel lit
    "h": hex_color("8b9bb4"),  # steel
    "G": hex_color("5a6988"),  # steel shade
    "g": hex_color("3a4466"),  # deepest steel
    "k": hex_color("181425"),  # eye slit
    "b": hex_color("124e89"),  # flag blue
    "B": hex_color("0099db"),  # plume blue
    "Y": hex_color("fee761"),  # gold lit
    "y": hex_color("feae34"),  # gold
    "o": hex_color("b86f50"),  # gold shade
    "l": hex_color("733e39"),  # belt leather
    "R": hex_color("e43b44"),  # shield, straw
    "r": hex_color("a22633"),  # shield shade
    # Legs: mail thighs, plate greaves and sabatons.
    "1": hex_color("5a6988"), "4": hex_color("8b9bb4"), "2": hex_color("c0cbdc"), "3": hex_color("3a4466"),
}

# The great helm, a pixel wider than a head each side: a gold rim at the crown,
# the slit crossed by a gold bar so the face shows a cross, breathing slits on the right
# cheek. The plume is white and blue; the straw leaves the slit's right end, up and out.
HEAD_FRONT = [
    "....WWB.............",
    ".....WBB............",
    "......WB........R...",
    "....yYYYYYYyyo..W...",
    "...hHWHHHHHhhhG.R...",
    "...hHHHHYHHhhhGW....",
    "...hkkkkYkkkkkk.....",
    "...hHHHHYHHhhhG.....",
    "...hHHHyYyHgGgG.....",
    "...hHHHHYHHhhhG.....",
    "....GGGGGGGGGGg.....",
]
HEAD_BACK = [
    "....WWB.............",
    ".....WBB............",
    "......WB............",
    "....yYYYYYYyyo......",
    "...hHWHHHHHhhhG.....",
    "...hHHHHHHHhhhG.....",
    "...hHHHHHHHhhhG.....",
    "...hHHHHHHHhhhG.....",
    "...hHHHHHHHhhhG.....",
    "...hHHHHHHHhhhG.....",
    "....GGGGGGGGGGg.....",
]
# Rows 10-18. Pauldrons with gold edges stand out past the tabard; steel arms down to the
# gauntlets at the hem. The flag cross on the tabard sits left of centre, a leather
# belt with a gold buckle below it, the mail skirt at the hem.
TORSO_FRONT = [
    ".yHHhWWbbWWWWWwhGGy.",
    ".yHhGWWbbWWWWWwGGgy.",
    "..yyoWWbbWWWWWwyoo..",
    "..hG.bbbbbbbbbb.Gg..",
    "..hG.WWbbWWWWWw.Gg..",
    "..hG.llllYllllo.Gg..",
    ".....WWbbWWWWWw.....",
    ".....WWbbWWWWWw.....",
    ".....WWbbWWWWWw.....",
]
# From behind the tabard is plain white and the belt has no buckle.
TORSO_BACK = [
    ".yHHhWWWWWWWWWwhGGy.",
    ".yHhGWWWWWWWWWwGGgy.",
    "..yyyWWWWWWWWWwyyo..",
    "..hG.WWWWWWWWWw.Gg..",
    "..hG.WWWWWWWWWw.Gg..",
    "..hG.llllllllll.Gg..",
    ".....WWWWWWWWWw.....",
    ".....WWWWWWWWWw.....",
    ".....WWWWWWWWWw.....",
]
# The tabard hangs a row past the torso grid, over the hips; drawn last, it moves with the body.
HEM_FRONT = ["wwbbwwwwwG"]
HEM_BACK = ["wwwwwwwwwG"]
HEM_COLUMN = 5
# Upright in the right gauntlet: a steel blade with a lit edge, a gold crossguard.
SWORD = [
    ".H..",
    ".Hh.",
    ".Hh.",
    ".Hh.",
    ".Hh.",
    ".Hh.",
    ".Hh.",
    "yYYo",
]
SWORD_ANCHOR = (-1, -8)
# On the left arm: a red heater shield with a gold rim and the crowned lion of the arms,
# reduced to a rampant gold mark.
SHIELD = [
    "oyyyyyyo",
    "RRYYRRRr",
    "RYYYRRRr",
    "RRYYYYRr",
    "RRRYYRYr",
    "RRYYYRRr",
    "RRYRRYRr",
    ".rRRRRr.",
    "..rRRr..",
    "...rr...",
]
SHIELD_ANCHOR = (-3, -6)
# From behind his sides swap: the sword is in the hand on the right and the shield, on his
# far arm on the left, shows only its edge past the body. The light still comes from the
# upper left, so these are drawn, not mirrored.
SHIELD_EDGE = [
    "yyo",
    "RRr",
    "RRr",
    "RRr",
    "RRr",
    "RRr",
    ".Rr",
    "..r",
]
SHIELD_EDGE_ANCHOR = (-3, -6)
# The knighting, row 4, seen from behind at the counter: the sword arm leaves the side
# (TORSO_BACK without it) and raises the sword by the helm, its tip glints, then it swings
# over the helm toward the brewer.
TORSO_BACK_ARM_UP = [row[:16] + ".." + row[18:] if 3 <= index <= 5 else row for index, row in enumerate(TORSO_BACK)]
HAND_RAISED = (18, 7)
# The raised upper arm, from the pauldron up to the gauntlet, in box columns 17-18.
ARM_RAISED = ["hG"]
ARM_RAISED_AT = (17, 9)
SWORD_GLINT = ["WH..", *SWORD[1:]]
HAND_SWUNG = (16, 8)
# Swung over the helm the blade is in shade, dark steel, so it reads against the lit helm.
SWORD_SWUNG = [
    ".G........",
    ".Gg.......",
    "..Gg......",
    "...Gg.....",
    "....Gg....",
    ".....Ggy..",
    "......g...",
    ".....o....",
]
SWORD_SWUNG_ANCHOR = (-8, -7)
KNIGHT_ROW = 4


def _hem(frame: Image.Image, palette: dict, upper: int, back: bool) -> None:
    paint(frame, palette, HEM_BACK if back else HEM_FRONT, BOX_X + HEM_COLUMN, upper + LEGS_TOP)


def _raised_arm(frame: Image.Image, palette: dict, upper: int) -> None:
    paint(frame, palette, ARM_RAISED, BOX_X + ARM_RAISED_AT[0], upper + ARM_RAISED_AT[1])


def look() -> Look:
    return Look(
        palette=PALETTE,
        head_front=HEAD_FRONT,
        head_back=HEAD_BACK,
        torso_front=TORSO_FRONT,
        torso_back=TORSO_BACK,
        hand=["Hh", "hG"],
        held=(Held(SHIELD, SHIELD_ANCHOR, trails=False), Held(SWORD, SWORD_ANCHOR, trails=False)),
        extra=_hem,
    )


def draw_ritari_sheet() -> Image.Image:
    """The standard sheet, idle_up redrawn with the arms' things swapped round, and the
    knighting row."""
    front = look()
    sheet = draw_sheet(front, extra_rows=1)
    back = look()
    back.palette = front.palette
    back.held = (Held(SHIELD_EDGE, SHIELD_EDGE_ANCHOR, trails=False), Held(SWORD, SWORD_ANCHOR, trails=False))
    check(back)
    sheet.paste((0, 0, 0, 0), (0, FRAME, FRAME * 4, FRAME * 2))
    for column, bob in enumerate((0, -1, 0)):
        draw_frame(sheet, back, column, 1, back=True, bob=bob, legs="stand", hands=HANDS_REST, trail=STILL)
    poses = ((SWORD, SWORD_ANCHOR, HAND_RAISED), (SWORD_GLINT, SWORD_ANCHOR, HAND_RAISED),
             (SWORD_SWUNG, SWORD_SWUNG_ANCHOR, HAND_SWUNG))
    for column, (sword, anchor, hand) in enumerate(poses):
        back.held = (Held(SHIELD_EDGE, SHIELD_EDGE_ANCHOR, trails=False), Held(sword, anchor, trails=False))
        check(back)
        arm = _raised_arm if hand == HAND_RAISED else None
        draw_frame(sheet, back, column, KNIGHT_ROW, back=True, bob=0, legs="stand", hands=(HANDS_REST[0], hand),
                   trail=STILL, torso=TORSO_BACK_ARM_UP, extra=arm)
    return sheet


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="also write a 6x preview beside a normal customer")
    parser.add_argument("--force-aseprite", action="store_true")
    args = parser.parse_args()
    sheet = draw_ritari_sheet()
    path = TEXTURE_DIR / f"{NAME}.png"
    sheet.save(path)
    print(f"wrote {path.relative_to(ROOT)}")
    write_aseprite_source(path, args.force_aseprite)
    if args.preview:
        normal = Image.open(TEXTURE_DIR / "normaali_mies_32.png").convert("RGBA")
        image = Image.new("RGBA", (FRAME * 5, FRAME * 4), (40, 36, 48, 255))
        image.alpha_composite(sheet, (0, 0))
        for row in range(4):
            image.alpha_composite(normal.crop((0, 0, 32, 32)), (FRAME * 4, row * FRAME))
        image.resize((image.width * 6, image.height * 6), Image.NEAREST).save(args.preview)


if __name__ == "__main__":
    main()
