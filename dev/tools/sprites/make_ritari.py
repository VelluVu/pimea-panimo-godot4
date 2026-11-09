"""Draws Ritari, the medieval re-enactor who never steps out of character, in his best
armour with Finnish ornaments: a great helm with a gold rim and a gold cross on the face,
a blue and white plume, a white tabard with the flag's blue cross set toward the left as on
the flag (plain white at the back), hanging over the hips, a leather belt with a gold buckle,
a red heater shield with the gold lion of the Finnish arms (from behind its dark back), and a
steel sword with a gold crossguard, carried upright on a bent arm. One thing gives him away:
a striped drinking straw pokes out of the eye slit. Shield, sword and plume make the
silhouette. The shapes follow the user's hand-edited idle frames.

The sheet follows the other customers' (see customer_sheet.py): 128x128, 32 px frames,
rows idle, idle_up, walk_towards and walk_right, plus knight and walk_towards_carrying
(128x192), light from above left.

    python dev/tools/sprites/make_ritari.py [--preview out.png] [--force-aseprite]
"""

import argparse
from pathlib import Path

from PIL import Image

from customer_sheet import (BOX_X, FRAME, HANDS_REST, LEGS_TOP, ROOT, STILL, TEXTURE_DIR, TOWARDS, Held, Look, check,
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

# The great helm: a gold rim at the crown, the slit crossed by a gold bar so the face shows
# a cross, breathing slits on the right cheek. The plume is white and blue; the straw leaves
# the slit's right end, up and out.
HEAD_FRONT = [
    "....WWB.............",
    ".....WBB............",
    "......WB........R...",
    ".....yYYYYYyyoo.W...",
    ".....HWHHHHhhhG.R...",
    ".....HHHYHHhhhGW....",
    ".....kkkYkkkkkk.....",
    ".....HHHYHHhhhG.....",
    ".....HHyYyHgGgG.....",
    ".....HHHYHHhhhG.....",
    ".....GGGGGGGGGg.....",
]
HEAD_BACK = [
    "....WWB.............",
    ".....WBB............",
    "......WB........R...",
    ".....yYYYYYyyoo.W...",
    ".....HWHHHHhhhG.R...",
    ".....HHHHHHhhhGW....",
    ".....HHHHHHhhhG.....",
    ".....HHHHHHhhhG.....",
    ".....HHHHHHhhhG.....",
    ".....HHHHHHhhhG.....",
    ".....GGGGGGGGGg.....",
]
# Rows 10-18. The left arm's pauldron stands out past the tabard (the sword arm is drawn
# with the sword). The flag cross on the tabard sits left of centre, a leather belt with a
# gold buckle below it. The tabard narrows from the belt down.
TORSO_FRONT = [
    ".yHHhWWbbWWWWWw.....",
    ".yHhGWWbbWWWWWw.....",
    "..yyoWWbbWWWWWw.....",
    "..hG.bbbbbbbbbb.....",
    "..hG.bbbbbbbbbb.....",
    "..hG.WWbbWWWWWw.....",
    "......lllYllll......",
    "......WbbWWWWW......",
    "......WbbWWWWW......",
]
# From behind the tabard is plain white and the belt has no buckle. The red in the arm's
# gap is the shield behind it.
TORSO_BACK = [
    ".yHHhWWWWWWWWWw.....",
    ".yHhGWWWWWWWWWw.....",
    "..yyyWWWWWWWWWw.....",
    "..hGrWWWWWWWWWw.....",
    "..hGrWWWWWWWWWw.....",
    "..oorWWWWWWWWWw.....",
    "......llllllll......",
    "......WWWWWWWW......",
    "......WWWWWWWW......",
]
# The tabard hangs a row past the torso grid, over the hips; drawn last, it moves with the body.
HEM_FRONT = ["wbbwwwww"]
HEM_BACK = ["wwwwwwww"]
HEM_COLUMN = 6
# The sword carried upright on a bent arm, one rigid piece that keeps still in the walk so
# the blade doesn't flap. In frame columns 21-27; the top row is box row 1 from the front
# and 2 from behind, where the blade sits a row lower.
SWORD_ARM_FRONT = [
    "....H..",
    "....Hh.",
    "....Hh.",
    "....Hh.",
    "....Hh.",
    "....Hh.",
    "....Hh.",
    "...yYYo",
    "....Hh.",
    "h..HhG.",
    "hhyhG..",
    "GhyG...",
    ".Gy....",
]
SWORD_ARM_BACK = [
    "....H..",
    *["....Hh."] * 6,
    "...yYYo",
    "h..HHh.",
    "hhyhhG.",
    "GhyG...",
    ".Gy....",
]
SWORD_ARM_COLUMN = 15
SWORD_ARM_TOP_FRONT = 1
SWORD_ARM_TOP_BACK = 2
GAUNTLET = ["Hh", "hG"]
NO_HAND = ["..", ".."]
# In the knighting: upright in the right gauntlet, a steel blade with a lit edge, a gold crossguard.
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
# Idle from behind: the user's pose, the sword and shield on the opposite sides from the front as
# when he turns round. Drawn, not mirrored, so the light still comes from the upper left: the
# helm and tabard keep their shading, the far pauldron and arm take the shaded right side.
HEAD_BACK_TURNED = [
    ".............WWB....",
    "............WBB.....",
    "...R........WB......",
    "...W.yYYYYYyyoo.....",
    "...R.HWHHHHhhhG.....",
    "....WHHHHHHhhhG.....",
    ".....HHHHHHhhhG.....",
    ".....HHHHHHhhhG.....",
    ".....HHHHHHhhhG.....",
    ".....HHHHHHhhhG.....",
    ".....GGGGGGGGGg.....",
]
TORSO_BACK_TURNED = [
    ".....WWWWWWWWWwhGGy.",
    ".....WWWWWWWWWwGGgy.",
    ".....WWWWWWWWWwyyo..",
    ".....WWWWWWWWWwrGg..",
    ".....WWWWWWWWWwrGg..",
    ".....WWWWWWWWWwroo..",
    "......llllllll......",
    "......WWWWWWWW......",
    "......WWWWWWWW......",
]
# In frame columns 4-10, the top row is box row 2.
SWORD_ARM_TURNED = [
    "..h....",
    *[".Hh...."] * 6,
    "yYYo...",
    ".HHh..h",
    ".hhGyhh",
    "...GyhG",
    "....yG.",
]
SWORD_ARM_TURNED_COLUMN = -2
SHIELD_TURNED = [
    "....yyo",
    *["....RRr"] * 5,
    "rRrrrrr",
    "rrrrrr.",
    ".rrrr..",
    "..rr...",
]
SHIELD_TURNED_ANCHOR = (-2, -6)
# The shield from behind, in the knighting: its edge past the arm and its dark back showing
# below it, hiding the hand.
SHIELD_BACK = [
    "yyo....",
    "RRr....",
    "RRr....",
    "RRr....",
    "RRr....",
    "RRr....",
    "rRrrrrr",
    ".rrrrrr",
    "..rrrr.",
    "...rr..",
]
# The knighting, row 4, seen from behind at the counter: the sword arm rises from its
# pauldron and raises the sword by the helm, its tip glints, then it swings over the helm
# toward the brewer.
TORSO_BACK_ARM_UP = [
    TORSO_BACK[0][:15] + "hGGy.",
    TORSO_BACK[1][:15] + "GGgy.",
    TORSO_BACK[2][:15] + "yyo..",
    *TORSO_BACK[3:],
]
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
# Leaving with the beer, row 5 (the glass itself is the game's, see hand_offsets in
# ritari.tres): the sword is sheathed at the hip, the bent arm holds the glass up by the helm,
# and the straw turns down out of the slit into it.
CARRYING_ROW = 5
HEAD_FRONT_SIPPING = [row[:15] + "....." for row in HEAD_FRONT]
CARRYING_ARM = SWORD_ARM_FRONT[9:]
CARRYING_ARM_TOP = 10
STRAW_INTO_GLASS = [
    "W...",
    ".R..",
    "..W.",
    "...R",
]
STRAW_COLUMN = 15
STRAW_TOP = 5
# Worn on the free side, where the shield doesn't hide it: pommel, grip, crossguard, then
# the scabbard with a gold tip.
SHEATHED_SWORD = [
    ".yo.",
    ".Hh.",
    "yYYo",
    *[".ol."] * 5,
    ".yo.",
]
SHEATHED_SWORD_COLUMN = 13
SHEATHED_SWORD_TOP = 14


def _hem(frame: Image.Image, palette: dict, upper: int, back: bool) -> None:
    paint(frame, palette, HEM_BACK if back else HEM_FRONT, BOX_X + HEM_COLUMN, upper + LEGS_TOP)


def _hem_and_sword_arm(frame: Image.Image, palette: dict, upper: int, back: bool) -> None:
    _hem(frame, palette, upper, back)
    rows, top = (SWORD_ARM_BACK, SWORD_ARM_TOP_BACK) if back else (SWORD_ARM_FRONT, SWORD_ARM_TOP_FRONT)
    paint(frame, palette, rows, BOX_X + SWORD_ARM_COLUMN, upper + top)


def _hem_and_turned_sword_arm(frame: Image.Image, palette: dict, upper: int, back: bool) -> None:
    _hem(frame, palette, upper, back)
    paint(frame, palette, SWORD_ARM_TURNED, BOX_X + SWORD_ARM_TURNED_COLUMN, upper + SWORD_ARM_TOP_BACK)


def _hem_and_beer_arm(frame: Image.Image, palette: dict, upper: int, back: bool) -> None:
    _hem(frame, palette, upper, back)
    paint(frame, palette, SHEATHED_SWORD, BOX_X + SHEATHED_SWORD_COLUMN, upper + SHEATHED_SWORD_TOP)
    paint(frame, palette, CARRYING_ARM, BOX_X + SWORD_ARM_COLUMN, upper + CARRYING_ARM_TOP)
    paint(frame, palette, STRAW_INTO_GLASS, BOX_X + STRAW_COLUMN, upper + STRAW_TOP)


def _raised_arm(frame: Image.Image, palette: dict, upper: int) -> None:
    paint(frame, palette, ARM_RAISED, BOX_X + ARM_RAISED_AT[0], upper + ARM_RAISED_AT[1])


def look() -> Look:
    return Look(
        palette=PALETTE,
        head_front=HEAD_FRONT,
        head_back=HEAD_BACK,
        torso_front=TORSO_FRONT,
        torso_back=TORSO_BACK,
        hand=GAUNTLET,
        hands=(GAUNTLET, NO_HAND),
        held=(Held(SHIELD, SHIELD_ANCHOR, trails=False), None),
        extra=_hem_and_sword_arm,
    )


def draw_ritari_sheet() -> Image.Image:
    """The standard sheet, idle_up redrawn with the shield's back, the knighting row and
    the walk out with the beer."""
    front = look()
    sheet = draw_sheet(front, extra_rows=2)
    back = look()
    back.palette = front.palette
    back.head_back = HEAD_BACK_TURNED
    back.torso_back = TORSO_BACK_TURNED
    back.hands = (NO_HAND, NO_HAND)
    back.held = (None, Held(SHIELD_TURNED, SHIELD_TURNED_ANCHOR, trails=False))
    back.extra = _hem_and_turned_sword_arm
    check(back)
    sheet.paste((0, 0, 0, 0), (0, FRAME, FRAME * 4, FRAME * 2))
    for column, bob in enumerate((0, -1, 0)):
        draw_frame(sheet, back, column, 1, back=True, bob=bob, legs="stand", hands=HANDS_REST, trail=STILL)
    knight = look()
    knight.palette = front.palette
    knight.hands = (NO_HAND, GAUNTLET)
    knight.extra = _hem
    poses = ((SWORD, SWORD_ANCHOR, HAND_RAISED), (SWORD_GLINT, SWORD_ANCHOR, HAND_RAISED),
             (SWORD_SWUNG, SWORD_SWUNG_ANCHOR, HAND_SWUNG))
    for column, (sword, anchor, hand) in enumerate(poses):
        knight.held = (Held(SHIELD_BACK, SHIELD_ANCHOR, trails=False), Held(sword, anchor, trails=False))
        check(knight)
        arm = _raised_arm if hand == HAND_RAISED else None
        draw_frame(sheet, knight, column, KNIGHT_ROW, back=True, bob=0, legs="stand", hands=(HANDS_REST[0], hand),
                   trail=STILL, torso=TORSO_BACK_ARM_UP, extra=arm)
    carrying = look()
    carrying.palette = front.palette
    carrying.extra = _hem_and_beer_arm
    for column, (legs, bob, hands, trail) in enumerate(TOWARDS):
        draw_frame(sheet, carrying, column, CARRYING_ROW, back=False, bob=bob, legs=legs, hands=hands, trail=trail,
                   head=HEAD_FRONT_SIPPING)
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
