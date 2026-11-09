"""Draws Saunamies, who walks in straight from the smoke sauna, munasillaan: a tan felt
sauna hat and blue flip-flops and nothing else, his skin flushed red with soot smudges from
the savusauna, a big moustache and a content grin, a birch whisk (vihta) in his right hand,
and a censor mosaic blurring the crotch. Steam rises off his shoulders and hat. The hat,
the bare red body and the mosaic make the silhouette. The shapes follow the user's
hand-edited idle frames.

The sheet follows the other customers' (see customer_sheet.py): 128x128, 32 px frames,
rows idle, idle_up, walk_towards and walk_right, light from above left.

    python dev/tools/sprites/make_saunamies.py [--preview out.png] [--force-aseprite]
"""

import argparse
from pathlib import Path

from PIL import Image

from customer_sheet import (BOX_X, FRAME, HANDS_REST, ROOT, STILL, TEXTURE_DIR, Held, Look, check, draw_frame,
                            draw_sheet, hex_color, paint)
from make_orveltaja import write_aseprite_source

NAME = "saunamies_32"

PALETTE = {
    "s": hex_color("e4a672"),  # skin, warm from the löyly
    "t": hex_color("b86f50"),  # skin shade
    "P": hex_color("f6757a"),  # flush
    "k": hex_color("5a6988"),  # soot
    "w": hex_color("ffffff"),  # eye white
    "e": hex_color("3a4466"),  # pupil
    "m": hex_color("3e2731"),  # mouth
    "a": hex_color("733e39"),  # moustache, wet hair
    "R": hex_color("b19779"),  # felt hat
    "r": hex_color("9c876d"),  # felt hat shade
    "M": hex_color("ead4aa"), "O": hex_color("d77643"),  # censor mosaic, with "t"
    "G": hex_color("63c74d"),  # birch leaves
    "g": hex_color("3e8948"),  # birch leaves shade
    "b": hex_color("733e39"),  # whisk handle
    # Legs: bare, with blue flip-flops.
    "1": hex_color("e4a672"), "4": hex_color("e4a672"), "2": hex_color("e4a672"), "3": hex_color("0099db"),
    # The far leg in the skin shade: the default darkening turns bare skin grey, like trousers.
    "5": hex_color("b86f50"), "6": hex_color("b86f50"), "7": hex_color("b86f50"),
}
STEAM = (hex_color("c0cbdc"), hex_color("8b9bb4"))

# The felt hat: a rounded crown and a wide floppy brim. Under it wet hair, a flushed face, a
# soot smudge on the cheek, the moustache and a content grin.
HEAD_FRONT = [
    ".......RRRRr........",
    "......RRRRRRr.......",
    "......RRRRRRr.......",
    "....rRRRRRRRRrr.....",
    ".....awwssswwa......",
    ".....swetssewt......",
    ".....PssttssPt......",
    ".....saaaaaaat......",
    ".....ssmmmmsst......",
    "......sssssst.......",
]
HEAD_BACK = [
    ".......RRRRr........",
    "......RRRRRRr.......",
    "......RRRRRRr.......",
    "....rRRRRRRRRrr.....",
    ".....aaaaaaaaa......",
    ".....aaaaaaaat......",
    ".....saaaaaast......",
    ".....ssssssstt......",
    ".....ssssssstt......",
    "......sssssst.......",
]
# Rows 10-18. Bare shoulders and arms, a flushed chest, a round belly. Nothing else on:
# the front gets the censor mosaic (CENSOR), the back a bare behind.
TORSO_FRONT = [
    "...sssssssssssstt...",
    "..ssssPPsssPPssstt..",
    "..ss.ssssssssst.st..",
    "..ss.ssssssssst.st..",
    "..ss.sssssssstt.st..",
    "..ss.sssssssstt.st..",
    ".....ssssssssst.....",
    ".....ssssssssst.....",
    ".....ssssssssst.....",
]
TORSO_BACK = [
    "...sssssssssssstt...",
    "..sssssssssksssstt..",
    "..ss.ssssssssst.st..",
    "..ss.ssssssssst.st..",
    "..ss.ssssssssst.st..",
    "..ss.sssssssstt.st..",
    ".....ssssssssst.....",
    ".....sssstsssst.....",
    ".....sssstsssst.....",
]
# Over the crotch, box rows 17-20 (torso to upper legs): a 6x4 mosaic of 2x2 blocks in
# skin tones a clear step apart, the way a TV blur looks.
CENSOR = [
    "MMOOtt",
    "MMOOtt",
    "ttMMOO",
    "ttMMOO",
]
CENSOR_AT = (7, 17)

# The vihta hangs from the right hand, leaves down, and swings behind it when he walks.
VIHTA = [
    ".b..",
    ".b..",
    "gGg.",
    "GgGg",
    "gGgG",
    ".gG.",
]
VIHTA_ANCHOR = (0, 1)

# Steam puffs per column: (x, y) frame pixels of a light and a dark grain, rising a row
# a frame so the loop drifts up.
STEAM_PUFFS = [
    [((10, 4), 0), ((21, 9), 1), ((9, 13), 1)],
    [((11, 3), 1), ((22, 8), 0), ((8, 12), 0)],
    [((10, 2), 0), ((22, 7), 1), ((8, 11), 1)],
    [((11, 1), 1), ((21, 6), 0), ((9, 10), 0)],
]


def _censor(frame: Image.Image, palette: dict, upper: int, back: bool) -> None:
    if not back:
        paint(frame, palette, CENSOR, BOX_X + CENSOR_AT[0], upper + CENSOR_AT[1])


def look() -> Look:
    return Look(
        palette=PALETTE,
        head_front=HEAD_FRONT,
        head_back=HEAD_BACK,
        torso_front=TORSO_FRONT,
        torso_back=TORSO_BACK,
        held=(None, Held(VIHTA, VIHTA_ANCHOR, trails=True)),
        extra=_censor,
    )


def add_steam(sheet: Image.Image) -> None:
    """Steam grains over every frame, only on empty pixels so it never covers him."""
    for row in range(sheet.height // FRAME):
        for column in range(4):
            if sheet.crop((column * FRAME, row * FRAME, (column + 1) * FRAME, (row + 1) * FRAME)).getbbox() is None:
                continue
            for (x, y), shade in STEAM_PUFFS[column]:
                for dx, dy in ((0, 0), (1, 0), (0, -1)):
                    point = (column * FRAME + x + dx, row * FRAME + y + dy)
                    if sheet.getpixel(point)[3] == 0:
                        sheet.putpixel(point, STEAM[shade if (dx, dy) == (0, 0) else 1 - shade])


def draw_back_row(sheet: Image.Image, front: Look) -> None:
    """From behind his sides swap, so the vihta is in the hand on the left; the light still
    comes from the upper left, so the row is drawn again, not mirrored."""
    back = look()
    back.palette = front.palette
    back.held = (Held(VIHTA, VIHTA_ANCHOR, trails=True), None)
    check(back)
    sheet.paste((0, 0, 0, 0), (0, FRAME, FRAME * 4, FRAME * 2))
    for column, bob in enumerate((0, -1, 0)):
        draw_frame(sheet, back, column, 1, back=True, bob=bob, legs="stand", hands=HANDS_REST, trail=STILL)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="also write a 6x preview beside a normal customer")
    parser.add_argument("--force-aseprite", action="store_true")
    args = parser.parse_args()
    front = look()
    sheet = draw_sheet(front)
    draw_back_row(sheet, front)
    add_steam(sheet)
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
