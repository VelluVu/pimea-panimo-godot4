"""Draws the Uudenvuoden örveltäjä, the New Year reveller who is drunk before he gets in:
a magenta tuulipuku tracksuit with a teal yoke and white sleeve stripes, a gold tinsel boa
round the neck, big teal novelty glasses (gold would melt into the skin under the warm lamps) over crossed eyes, a red nose, a flushed cheek, a
crooked grin, and both arms up with a roman candle in each fist. The raised candles make
the silhouette: they stand above his head. Idle, his head sways a pixel and the candle
mouths flicker; walking, he pumps one fist and then the other. The shots themselves are
fired in the game, not drawn here.

The sheet follows the other customers' (see customer_sheet.py): 128x128, 32 px frames,
rows idle, idle_up, walk_towards and walk_right, light from above left.

    python dev/tools/sprites/make_orveltaja.py [--preview out.png] [--force-aseprite]
"""

import argparse
import subprocess
from pathlib import Path

from PIL import Image

from customer_sheet import (FRAME, RIGHT, ROOT, STILL, TEXTURE_DIR, TOWARDS, Held, Look, check, draw_frame,
                            far_leg_colors, hex_color)

ASEPRITE = Path("C:/Program Files (x86)/Steam/steamapps/common/Aseprite/Aseprite.exe")
ASEPRITE_SCRIPT = Path(__file__).resolve().parent / "aseprite_source.lua"
NAME = "orveltaja_32"

PALETTE = {
    "s": hex_color("ead4aa"),  # skin
    "t": hex_color("e4a672"),  # skin shade
    "P": hex_color("f6757a"),  # flushed cheek
    "R": hex_color("e43b44"),  # red nose, candle tube
    "r": hex_color("a22633"),  # candle tube shade
    "e": hex_color("3a4466"),  # pupils
    "w": hex_color("ffffff"),  # eye whites, teeth, zip, sleeve stripes, candle bands
    "k": hex_color("181425"),  # open mouth
    "a": hex_color("733e39"),  # hair
    "A": hex_color("3e2731"),  # hair shade
    "Y": hex_color("fee761"),  # gold tinsel
    "y": hex_color("feae34"),  # gold shade
    "o": hex_color("f77622"),  # candle mouth glow
    "M": hex_color("b55088"),  # tracksuit
    "m": hex_color("68386c"),  # tracksuit shade
    "T": hex_color("0099db"),  # tracksuit yoke, collar, hem, glasses
    # Legs: tracksuit trousers and white trainers with grey soles.
    "1": hex_color("b55088"), "4": hex_color("b55088"), "2": hex_color("ffffff"), "3": hex_color("8b9bb4"),
}

# Rows 1-9: messy hair, the glasses over crossed eyes (each pupil on the inner side), the
# red nose between the lens rims, a flushed cheek and a grin pulled to one side.
HEAD_FRONT = [
    "......a.aa.a........",
    ".....aaaaaaaaaa.....",
    ".....aaaaaaaaaA.....",
    ".....asssssssst.....",
    ".....TTTTsTTTTt.....",
    ".....TweTsTewTt.....",
    ".....TTTTRTTTTt.....",
    ".....sPssskwwkt.....",
    "......sssssst.......",
]
HEAD_BACK = [
    "......a.aa.a........",
    ".....aaaaaaaaaa.....",
    ".....aaaaaaaaaA.....",
    ".....aaaaaaaaaA.....",
    ".....TaaaaaaaaT.....",
    ".....saaaaaaaAt.....",
    ".....ssaaaaaatt.....",
    "......ssssssss......",
    ".......ssssss.......",
]
# Rows 10-18. The sleeves rise from the shoulders beside the head (the fists are the hands,
# drawn above). The boa loops round the neck and hangs down the chest beside the zip.
TORSO_FRONT = [
    "..wM.YyYssssYyY.mw..",
    "..wMTTYyTwwTyYTTmw..",
    "...TTTTYTwTTYTTTT...",
    "....MMMYMwMMYMmm....",
    ".....MMYMwMMYMm.....",
    ".....MMMMwMMMMm.....",
    ".....MMMMwMMMMm.....",
    ".....TTTTTTTTTT.....",
    ".....MMMMmMMMMm.....",
]
TORSO_BACK = [
    "..wM.YyYYyYYyYy.mw..",
    "..wMTTTTTTTTTTTTmw..",
    "...TTTTTTTTTTTTTT...",
    "....MMMMMMMMMMmm....",
    ".....MMMMMMMMMm.....",
    ".....MMMMMMMMMm.....",
    ".....MMMMMMMMMm.....",
    ".....TTTTTTTTTT.....",
    ".....MMMMmMMMMm.....",
]
# Gripped upright, the tube runs down behind the fist; the mouth on top glows.
CANDLE = [
    "oY",
    "Rr",
    "ww",
    "Rr",
    "ww",
    "Rr",
]
CANDLE_FLICKER = ["Yo", *CANDLE[1:]]
CANDLE_ANCHOR = (0, -6)
# Fists up at the sides of the head; pumping, one rises a row.
HANDS_UP = ((2, 8), (16, 8))
PUMP_LEFT = ((2, 7), (16, 8))
PUMP_RIGHT = ((2, 8), (16, 7))


def look(flicker: bool = False) -> Look:
    candle = CANDLE_FLICKER if flicker else CANDLE
    return Look(
        palette=PALETTE,
        head_front=HEAD_FRONT,
        head_back=HEAD_BACK,
        torso_front=TORSO_FRONT,
        torso_back=TORSO_BACK,
        held=(Held(candle, CANDLE_ANCHOR, trails=False), Held(candle, CANDLE_ANCHOR, trails=False)),
    )


def _swayed(rows: list[str], shift: int) -> list[str]:
    """The head a pixel aside, for the drunk sway; the grid has empty columns on both sides."""
    if shift > 0:
        return ["." * shift + row[:-shift] for row in rows]
    return list(rows)


def draw_sheet() -> Image.Image:
    plain, flicker = look(), look(flicker=True)
    for one in (plain, flicker):
        one.palette = {**far_leg_colors(one.palette), **one.palette}
        check(one)
    sheet = Image.new("RGBA", (FRAME * 4, FRAME * 4), (0, 0, 0, 0))
    # idle and idle_up: a breath, the head sways right on it, the candle mouths flicker.
    for column, (bob, sway, lit) in enumerate(((0, 0, False), (-1, 1, True), (0, 0, False))):
        one = flicker if lit else plain
        draw_frame(sheet, one, column, 0, back=False, bob=bob, legs="stand", hands=HANDS_UP, trail=STILL,
                   head=_swayed(HEAD_FRONT, sway))
        draw_frame(sheet, one, column, 1, back=True, bob=bob, legs="stand", hands=HANDS_UP, trail=STILL,
                   head=_swayed(HEAD_BACK, sway))
    # Walking, the fist on the lifted foot's side pumps up.
    pumps = (HANDS_UP, PUMP_LEFT, HANDS_UP, PUMP_RIGHT)
    for row, poses in ((2, TOWARDS), (3, RIGHT)):
        for column, (legs, bob, _hands, _trail) in enumerate(poses):
            one = flicker if column % 2 else plain
            draw_frame(sheet, one, column, row, back=False, bob=bob, legs=legs, hands=pumps[column], trail=STILL)
    return sheet


def write_aseprite_source(png: Path, force: bool) -> None:
    """An editable source next to the PNG; an existing one is kept (it may hold hand edits)."""
    out = png.with_suffix(".aseprite")
    if out.exists() and not force:
        print(f"kept {out.name} (pass --force-aseprite to redo it)")
        return
    if not ASEPRITE.exists():
        print("Aseprite not found, no .aseprite source written:", ASEPRITE)
        return
    subprocess.run([str(ASEPRITE), "-b", "--script-param", f"png={png}", "--script-param", f"out={out}",
                    "--script", str(ASEPRITE_SCRIPT)], check=True)
    print(f"wrote {out.name}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="also write a 6x preview beside a normal customer")
    parser.add_argument("--force-aseprite", action="store_true")
    args = parser.parse_args()
    sheet = draw_sheet()
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
