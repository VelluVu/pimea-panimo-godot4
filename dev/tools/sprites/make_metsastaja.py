"""Draws Metsästäjä, the moose hunter in from the hunt: a blaze-orange cap with ear flaps, an
orange safety vest with a dark strap across it, a green jacket, dark trousers and rubber boots,
a thick cased rifle on the back (no loaded guns at the bar) and only a wooden kuksa in the
hand. His grids follow the user's hand-edited idle and idle_up frames: big white eyes turned
inward and a toothy grin under the moustache. His female counterpart (metsastaja_naaras_32)
follows her own edited frames: the same kit and eyes, a slimmer vest and blonde hair over the
shoulders. The orange cap and vest make the silhouette. From behind the kuksa changes hands;
that row is drawn again with the light still from the upper left, not mirrored.

The sheet follows the other customers' (see customer_sheet.py): 128x128, 32 px frames,
rows idle, idle_up, walk_towards and walk_right, light from above left.

    python dev/tools/sprites/make_metsastaja.py [--preview out.png] [--force-aseprite]
"""

import argparse
from pathlib import Path

from PIL import Image

from customer_sheet import (flat_clothes, BOX_X, FRAME, HANDS_REST, LEGS_TOP, RIGHT, ROOT, STILL, TEXTURE_DIR, Held, Look, check, draw_frame,
                            draw_sheet, hex_color, paint)
from make_orveltaja import write_aseprite_source

NAME = "metsastaja_32"
NAARAS_NAME = "metsastaja_naaras_32"
# Head grid rows of the cap brim and of the eyes' pupils.
BRIM_ROW = 6
EYE_ROW = 8

PALETTE = {
    "s": hex_color("ead4aa"),  # skin
    "t": hex_color("e4a672"),  # skin shade
    "e": hex_color("3a4466"),  # pupils
    "W": hex_color("ffffff"),  # eye whites, teeth
    "M": hex_color("733e39"),  # moustache, kuksa shade
    # Hers, from the user's edit: warmer skin, blonde hair, a lit vest.
    "a": hex_color("eeca9e"),  # her skin
    "c": hex_color("c5a37a"),  # her nose
    "y": hex_color("e5d58e"),  # her hair
    "P": hex_color("fc7f2e"),  # her vest light
    "p": hex_color("cb6c2e"),  # her vest shadow under the hair
    "b": hex_color("b86f50"),  # kuksa wood
    "O": hex_color("f77622"),  # blaze orange cap and flaps
    "o": hex_color("be4a2f"),  # orange shade, brim underside
    "V": hex_color("f77622"),  # vest
    "v": hex_color("be4a2f"),  # vest shade, zip
    "J": hex_color("3e8948"),  # jacket
    "j": hex_color("265c42"),  # jacket shade
    "S": hex_color("462724"),  # rifle strap, his hair
    "n": hex_color("b86f50"),  # rifle case leather
    "N": hex_color("733e39"),  # rifle case shade
    # Legs: dark green trousers, black rubber boots.
    "1": hex_color("1c4330"), "4": hex_color("1c4330"), "2": hex_color("262b44"), "3": hex_color("181425"),
}

# Cap with its brim to the front left, big eyes, moustache and grin; the rifle's top end rises
# behind the head on the right, so these grids reach above the usual head rows.
HEAD_FRONT = [
    "...............nn...",
    "..............nnN...",
    "..............nnN...",
    "........OOOO.nnN....",
    "......OOOOOOOonN....",
    ".....OOOOOOOOOoN....",
    "...ooOOOOOOOOOo.....",
    ".....OWWssWWonN.....",
    ".....OWetseWonN.....",
    ".....OssttssoN......",
    ".....ssMMMMssN......",
    "......ssWWssnN......",
]
# The rifle crosses the head from the upper left and goes on below the hem (RIFLE_BUTT_BACK).
HEAD_BACK = [
    "...nnN..............",
    "...nnN..............",
    "....nnNOOOO.........",
    "....nnNOOOOOOO......",
    "....nnnNOOOOOOO.....",
    ".....nnNOOOOOOooo...",
    ".....nnnNOOOOo......",
    ".....nnnNSSSSo......",
    "......nnnNSSSo......",
    "......nnnNSSS.......",
    "......nnnNttt.......",
]
# Rows 10-18: the vest over the jacket, the zip down the middle, the strap from shoulder to hip.
TORSO_FRONT = [
    "...JJJVVVVVVvSSj....",
    "..JJJVVVVvVVSSjjj...",
    "..JJJVVVVvVSSVvjjj..",
    "..JJ.VVVVvSSVVv.jj..",
    "..JJ.VVVVSSVVVv.jj..",
    "..JJ.VVVSSVVVVv.jj..",
    ".....VVSSvVVVVv.....",
    ".....VSSVvVVVVv.....",
    ".....SSVVvVVVVv.....",
]
TORSO_BACK = [
    "...JSSVnnnNVvjjj....",
    "..JJJSSnnnNVVvjjj...",
    "..JJJVSnnnNVVVvjjj..",
    "..JJ.VVSnnnNVVv.jj..",
    "..JJ.VVVnnnNVVv.jj..",
    "..JJ.VVVnnnnNVv.jj..",
    ".....VVVnnnnSVv.....",
    ".....VVVVnnnSSv.....",
    ".....VVVVnnnNSS.....",
]
# Her, as the user drew her: a softer face and blonde hair framing it, down over the shoulders.
NAARAS_HEAD_FRONT = [
    "................nn..",
    "...............nnN..",
    "...............nnN..",
    "........OOOO..nnN...",
    "......OOOOOOOonnN...",
    ".....OOOOOOOOOoN....",
    "...ooOOOOOOOOOoN....",
    ".....OWWaaWWonnN....",
    ".....OWeaaeWonN.....",
    ".....OaacaaaonN.....",
    ".....yaaWWaaynN.....",
    ".....yyaaaayyN......",
]
NAARAS_HEAD_BACK = [
    "...nn...............",
    "...nnN..............",
    "...nnnN.OOOO........",
    "....nnNOOOOOOO......",
    "....nnnNOOOOOOO.....",
    ".....nnNOOOOOOooo...",
    ".....nnnNOOOOo......",
    ".....nnnNyyyyo......",
    "......nnnNyyyo......",
    "......nnnNyyyy......",
    "......nnnNyyyy......",
]
# The vest has a lit patch under her hair. The sleeves step out to meet the hands.
NAARAS_TORSO_FRONT = [
    "....yyyOOOOyyyj.....",
    "....JOyPPoPSyOoj....",
    "...JJpyPPoSSyPojj...",
    "...JJ.pPPSSPpp.jjj..",
    "..JJJ.OpSSppOo..jj..",
    "..JJ..OSSoOOOo..jj..",
    "......SSOoOOOo......",
    "......SOOoOOOo......",
    "......OOOoOOOo......",
]
NAARAS_TORSO_BACK = [
    ".....JynnnNyyyj.....",
    "....JJynnnNyyojj....",
    "...JJJOnnnNyOojjj...",
    "...JJ.OnnnnNOo.jj...",
    "..JJJ.OOnnnNOo.jjj..",
    "..JJ..OOnnnnNo..jj..",
    "......OOnnnnSo......",
    "......OOOnnnSS......",
    "......OOOnnnNS......",
]
# Clothes in one flat tone with a one-pixel right edge (customer_sheet.flat_clothes).
TORSO_FRONT = flat_clothes(TORSO_FRONT, {"J": "j", "V": "v"})
TORSO_BACK = flat_clothes(TORSO_BACK, {"J": "j", "V": "v"})
NAARAS_TORSO_FRONT = flat_clothes(NAARAS_TORSO_FRONT, {"J": "j", "O": "o"})
NAARAS_TORSO_BACK = flat_clothes(NAARAS_TORSO_BACK, {"J": "j", "O": "o"})
RIFLE_BUTT_BACK = [
    ".........nnnnN......",
    ".........nnnnN......",
    ".........nnnnnN.....",
    ".........NNNNNN.....",
]
# The kuksa: the handle's loop round the fingers, the bowl out to the side.
KUKSA = [
    ".M....",
    "MbbbbM",
    "...bbM",
    "...bbM",
    "MMbbM.",
]
KUKSA_ANCHOR = (0, -2)
KUKSA_BACK = [
    "Mbbb..",
    "Mbb...",
    "Mbb...",
    ".MbbMM",
]
KUKSA_BACK_ANCHOR = (-4, -1)
# The left hand from behind is lit on the other side, as the user drew it.
HANDS_BACK = (["ts", "ts"], ["st", "st"])


def paint_rifle_butt(frame: Image.Image, palette: dict, upper: int, back: bool) -> None:
    """From behind the case hangs past the hem, over the legs."""
    if back:
        paint(frame, palette, RIFLE_BUTT_BACK, BOX_X, upper + LEGS_TOP)


def look(naaras: bool) -> Look:
    return Look(
        palette=PALETTE,
        head_front=NAARAS_HEAD_FRONT if naaras else HEAD_FRONT,
        head_back=NAARAS_HEAD_BACK if naaras else HEAD_BACK,
        torso_front=NAARAS_TORSO_FRONT if naaras else TORSO_FRONT,
        torso_back=NAARAS_TORSO_BACK if naaras else TORSO_BACK,
        held=(None, Held(KUKSA, KUKSA_ANCHOR, trails=False)),
        extra=paint_rifle_butt,
    )


def draw_back_row(sheet: Image.Image, front: Look, naaras: bool) -> None:
    """From behind the kuksa is in the hand on the left."""
    back = look(naaras)
    back.palette = front.palette
    back.held = (Held(KUKSA_BACK, KUKSA_BACK_ANCHOR, trails=False), None)
    back.hands = HANDS_BACK
    check(back)
    sheet.paste((0, 0, 0, 0), (0, FRAME, FRAME * 4, FRAME * 2))
    for column, bob in enumerate((0, -1, 0)):
        draw_frame(sheet, back, column, 1, back=True, bob=bob, legs="stand", hands=HANDS_REST, trail=STILL)


def facing_right(head: list[str]) -> list[str]:
    """Walking right the brim points right and both pupils look ahead; a brim on the left read
    as him facing left. The idle rows keep the user's inward eyes and left brim."""
    rows = list(head)
    brim = rows[BRIM_ROW]
    rows[BRIM_ROW] = "....." + brim[5:14] + "ooo" + brim[17:]
    eyes = rows[EYE_ROW]
    rows[EYE_ROW] = eyes[:10] + "We" + eyes[12:]
    return rows


def draw_walk_right_row(sheet: Image.Image, front: Look) -> None:
    walker = look(front.head_front is NAARAS_HEAD_FRONT)
    walker.palette = front.palette
    walker.head_front = facing_right(front.head_front)
    check(walker)
    sheet.paste((0, 0, 0, 0), (0, FRAME * 3, FRAME * 4, FRAME * 4))
    for column, (legs, bob, hands, trail) in enumerate(RIGHT):
        draw_frame(sheet, walker, column, 3, back=False, bob=bob, legs=legs, hands=hands, trail=trail)


def build(naaras: bool) -> Image.Image:
    front = look(naaras)
    sheet = draw_sheet(front)
    draw_back_row(sheet, front, naaras)
    draw_walk_right_row(sheet, front)
    return sheet


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="also write a 5x preview of both side by side")
    parser.add_argument("--force-aseprite", action="store_true")
    args = parser.parse_args()
    sheets = {NAME: build(False), NAARAS_NAME: build(True)}
    for name, sheet in sheets.items():
        path = TEXTURE_DIR / f"{name}.png"
        sheet.save(path)
        print(f"wrote {path.relative_to(ROOT)}")
        write_aseprite_source(path, args.force_aseprite)
    if args.preview:
        image = Image.new("RGBA", (FRAME * 8, FRAME * 4), (40, 36, 48, 255))
        for index, sheet in enumerate(sheets.values()):
            image.alpha_composite(sheet, (FRAME * 4 * index, 0))
        image.resize((image.width * 5, image.height * 5), Image.NEAREST).save(args.preview)


if __name__ == "__main__":
    main()
