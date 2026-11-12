"""Draws Ilmakitaristi, the air-guitar enthusiast (Oulu hosts the Air Guitar World
Championships): a mullet, short and spiky on top and long at the back, a black leather vest
over a red band T-shirt with a tiny logo, studded wristbands, black jeans and white
high-top sneakers. No guitar: the hands are empty. His female counterpart
(ilmakitaristi_naaras_32) has long bleached rock hair, the same vest and wristbands, and
black boots.

The sheet follows the other customers' (see customer_sheet.py): 32 px frames, rows idle,
idle_up, walk_towards and walk_right, light from above left, and a fifth row `solo`: an
air-guitar solo, the left hand up at the neck of the invisible guitar, the right hand
strumming at the hip, the head banging a pixel down and up with the hair swinging out.

    python dev/tools/sprites/make_ilmakitaristi.py [--preview out.png] [--force-aseprite]
"""

import argparse
from pathlib import Path
from typing import Callable

from PIL import Image

from customer_sheet import (BOX_X, FRAME, HANDS_REST, HEAD_LAST_ROW, ROOT, TEXTURE_DIR, Look, draw_frame,
                            draw_sheet, hex_color, paint)
from make_orveltaja import write_aseprite_source

NAME = "ilmakitaristi_32"
NAARAS_NAME = "ilmakitaristi_naaras_32"

PALETTE = {
    "s": hex_color("ead4aa"),  # skin
    "t": hex_color("e4a672"),  # skin shade
    "e": hex_color("3a4466"),  # eyes
    "k": hex_color("3e2731"),  # mouth
    "Q": hex_color("b86f50"),  # mullet, lit
    "P": hex_color("733e39"),  # mullet
    "p": hex_color("3e2731"),  # mullet shade
    "R": hex_color("a22633"),  # band T-shirt
    "r": hex_color("68386c"),  # T-shirt shade
    "W": hex_color("c0cbdc"),  # logo print
    "O": hex_color("ffffff"),  # eye whites
    "V": hex_color("3a4466"),  # leather vest
    "v": hex_color("262b44"),  # vest shade
    "X": hex_color("181425"),  # belt, wristbands
    "Z": hex_color("8b9bb4"),  # studs, buckle
    # Legs: black jeans and white high-tops with a grey sole.
    "1": hex_color("262b44"), "4": hex_color("262b44"), "2": hex_color("ffffff"), "3": hex_color("8b9bb4"),
}

# Short spiky top, short sides, and the long part hanging behind the neck.
HEAD_FRONT = [
    "......QPQPQPPp......",
    ".....QPPPPPPPPp.....",
    "......Pssssssp......",
    "......sOOssOOt......",
    "......sOestOet......",
    "......sssttsst......",
    "......ssskksst......",
    ".....PtssssstPp.....",
    ".....PPtsssstPp.....",
]
HEAD_BACK = [
    "......QPQPQPPp......",
    ".....QPPPPPPPPp.....",
    ".....QPPPPPPPPp.....",
    ".....PQPPPPPPPp.....",
    ".....PQPPPPPPpp.....",
    ".....PPPPPPPPpp.....",
    ".....PPPPPPPPpp.....",
    ".....PPPPPPPPpp.....",
    ".....PPPPPPPPpp.....",
]
# The vest hangs open over the shirt; T-shirt sleeves, bare forearms, studded wristbands.
TORSO_FRONT = [
    "....RPVVRRRRVVpr....",
    "...RRVVVRRRRVVVRr...",
    "..RR.VVVRRRRVVv.Rr..",
    "..ss.VVVRWWRVVv.st..",
    "..ss.VVVRRWRVVv.st..",
    "..ZX.VVVRRRRVVv.ZX..",
    ".....VVVRRRRVVv.....",
    ".....XXXXZZXXXX.....",
    "......11111111......",
]
# From behind the mullet tapers down over the vest's back.
TORSO_BACK = [
    "....RRVPPPPPpVVr....",
    "...RRVVVPPPpVVVRr...",
    "..RR.VVVVPpVVVv.Rr..",
    "..ss.VVVVVVVVVv.st..",
    "..ss.VVVVVVVVVv.st..",
    "..ZX.VVVVVVVVVv.ZX..",
    ".....VVVVVVVVVv.....",
    ".....XXXXXXXXXX.....",
    "......11111111......",
]
# Head down in the solo: the mouth open and the hair flung out at the neck.
SOLO_HEAD = HEAD_FRONT[:7] + [
    ".....PtsskkstPp.....",
    HEAD_FRONT[8],
]
SOLO_HEAD_SWUNG = SOLO_HEAD[:7] + [
    "....QPtsskkstPpp....",
    "....PPPtsssstPpp....",
]

NAARAS_PALETTE = {
    **PALETTE,
    "Q": hex_color("fee761"),  # bleached hair, lit
    "P": hex_color("feae34"),  # hair
    "p": hex_color("be4a2f"),  # hair shade
    "L": hex_color("a22633"),  # dark red lips
    # Legs: black jeans and black boots with a lighter blue-black upper.
    "2": hex_color("5a6988"), "3": hex_color("3a4466"),
}
NAARAS_HEAD_FRONT = [
    ".....QQPQPPPPpp.....",
    "....QQPPPPPPPPpp....",
    "....QPssssssssPp....",
    "....PPsOOssOOtPp....",
    "....PPsOestOetPp....",
    "....PPsssttsstPp....",
    "....PPsssLLsstPp....",
    "....PPPssssstPPp....",
    "....PPPtsssstPpp....",
]
NAARAS_HEAD_BACK = [
    ".....QQPQPPPPpp.....",
    "....QQPPPPPPPPpp....",
    "....QPPPPPPPPPPp....",
    "....PQPPPPPPPPPp....",
    "....PPQPPPPPPPpp....",
    "....PPPPPPPPPPpp....",
    "....PPPPPPPPPPpp....",
    "....PPPPPPPPPPpp....",
    "....PPPPPPPPPPpp....",
]
# Slim: the arms hang close to the body (hand_inset 1); the hair falls over the shoulders.
NAARAS_TORSO_FRONT = [
    "....PPVVRRRRVVPp....",
    "...RPPVVRRRRVVPpr...",
    "...RR.VVRWWRVv.Rr...",
    "...ss.VVRRWRVv.st...",
    "...ss.VVRRRRVv.st...",
    "...ZX.VVRRRRVv.ZX...",
    "......VVRRRRVv......",
    "......XXXZZXXX......",
    "......11111111......",
]
NAARAS_TORSO_BACK = [
    "....PPPPPPPPPPpp....",
    "...RRPPPPPPPPppRr...",
    "...RR.VPPPPPpv.Rr...",
    "...ss.VVPPPpVv.st...",
    "...ss.VVVVVVVv.st...",
    "...ZX.VVVVVVVv.ZX...",
    "......VVVVVVVv......",
    "......XXXXXXXX......",
    "......11111111......",
]
NAARAS_SOLO_HEAD = NAARAS_HEAD_FRONT[:6] + [
    "....PPsssLLsstPp....",
    "....PPPssLLsstPp....",
    "....PPPtsssstPpp....",
]
NAARAS_SOLO_HEAD_SWUNG = NAARAS_SOLO_HEAD[:7] + [
    "...QPPPssLLsstPpp...",
    "...PPPPtsssstPppp...",
]

# The fretting arm (her left, on the right of the picture): the sleeve, the upper arm out to
# the elbow, two pixels thick, the forearm up to the hand on the neck. The hand slides a row up the neck.
FRET_LOW = [
    "......",
    "......",
    "....st",
    "....st",
    "Rr..ZX",
    "Rrssst",
    ".sssst",
]
FRET_HIGH = [
    "......",
    "....st",
    "....st",
    "....ZX",
    "Rr..st",
    "Rrssst",
    ".sssst",
]
FRET_TOP = 8
# The strumming arm (his right, on the left of the picture): bent in to the hip, the hand
# at the belt; the stud and band of the wristband sit across the wrist.
STRUM_UP = [
    "RR....",
    "ss....",
    "sssZst",
    "sssXst",
]
STRUM_DOWN = [
    "RR....",
    "ss....",
    "ss....",
    "sssZst",
    "sssXst",
]
STRUM_TOP = 12


def _without_arms(torso: list[str], left: int, right: int) -> list[str]:
    """The torso with both arms cleared below the shoulders (they are drawn by the solo)."""
    rows = list(torso)
    for index in range(2, 6):
        row = rows[index]
        row = row[:left] + ".." + row[left + 2:]
        rows[index] = row[:right] + ".." + row[right + 2:]
    return rows


def _solo_painter(head: list[str], drop: int, fret: list[str], strum: list[str], left: int,
                  right: int) -> Callable[[Image.Image, dict, int], None]:
    def painter(frame: Image.Image, palette: dict, upper: int) -> None:
        paint(frame, palette, head, BOX_X, upper + HEAD_LAST_ROW + 1 - len(head) + drop)
        paint(frame, palette, strum, BOX_X + left, upper + STRUM_TOP)
        paint(frame, palette, fret, BOX_X + right, upper + FRET_TOP)
    return painter


def draw_solo_row(sheet: Image.Image, look: Look, heads: tuple[list[str], list[str], list[str]], inset: int) -> None:
    """Four frames that loop: head up and strum up, head down with the hair swung out and
    strum down, then the same with the fretting hand a row higher up the neck."""
    left, right = 2 + inset, 16 - inset
    torso = _without_arms(look.torso_front, left, right)
    up, down, swung = heads
    poses = ((up, 0, FRET_LOW, STRUM_UP), (swung, 1, FRET_LOW, STRUM_DOWN),
             (up, 0, FRET_HIGH, STRUM_UP), (down, 1, FRET_HIGH, STRUM_DOWN))
    for column, (head, drop, fret, strum) in enumerate(poses):
        draw_frame(sheet, look, column, 4, back=False, bob=0, legs="stand", hands=(None, None), torso=torso,
                   head=[], extra=_solo_painter(head, drop, fret, strum, left, right))


def look(naaras: bool = False) -> Look:
    if naaras:
        return Look(palette=NAARAS_PALETTE, head_front=NAARAS_HEAD_FRONT, head_back=NAARAS_HEAD_BACK,
                    torso_front=NAARAS_TORSO_FRONT, torso_back=NAARAS_TORSO_BACK, hand_inset=1)
    return Look(palette=PALETTE, head_front=HEAD_FRONT, head_back=HEAD_BACK, torso_front=TORSO_FRONT,
                torso_back=TORSO_BACK)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="also write a 6x preview beside a normal customer")
    parser.add_argument("--force-aseprite", action="store_true")
    args = parser.parse_args()
    sheets = {}
    for name, naaras, heads, inset in (
            (NAME, False, (HEAD_FRONT, SOLO_HEAD, SOLO_HEAD_SWUNG), 0),
            (NAARAS_NAME, True, (NAARAS_HEAD_FRONT, NAARAS_SOLO_HEAD, NAARAS_SOLO_HEAD_SWUNG), 1)):
        front = look(naaras)
        sheet = draw_sheet(front, extra_rows=1)
        draw_solo_row(sheet, front, heads, inset)
        path = TEXTURE_DIR / f"{name}.png"
        sheet.save(path)
        print(f"wrote {path.relative_to(ROOT)}")
        write_aseprite_source(path, args.force_aseprite)
        sheets[name] = sheet
    if args.preview:
        normal = Image.open(TEXTURE_DIR / "normaali_mies_32.png").convert("RGBA")
        image = Image.new("RGBA", (FRAME * 9, FRAME * 5), (40, 36, 48, 255))
        for index, sheet in enumerate(sheets.values()):
            image.alpha_composite(sheet, (FRAME * 4 * index, 0))
        for row in range(5):
            image.alpha_composite(normal.crop((0, 0, FRAME, FRAME)), (FRAME * 8, row * FRAME))
        image.resize((image.width * 6, image.height * 6), Image.NEAREST).save(args.preview)


if __name__ == "__main__":
    main()
