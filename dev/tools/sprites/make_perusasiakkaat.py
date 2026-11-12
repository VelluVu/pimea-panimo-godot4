"""Draws four more everyday Perusasiakas bodies, each with its own build so the silhouettes
read apart from the user's normaali_mies and normaali_nainen:

- tuulipuku: tall and thin (lift 2), a purple shell suit with a teal panel, grey hair and
  a moustache, white trainers.
- flanelli: wide and heavy (lift 1), a red check flannel shirt, a green cap, a beard, jeans
  and boots.
- toppatakki: a puffy blue winter coat down to the knees, long blonde hair, a red scarf and
  matching mittens.
- huppari: short and slim, a grey hoodie with its hood down, a red ponytail, glasses,
  leggings and white trainers.

ENDESGA 32 colours, no outline, light from the upper left; shades shift cool. The sheets
follow the other customers' (see customer_sheet.py).

    python dev/tools/sprites/make_perusasiakkaat.py [--preview out.png] [--force-aseprite]
"""

import argparse
import re
from pathlib import Path

from customer_sheet import BOX_WIDTH, TEXTURE_DIR, Look, draw_sheet, hex_color, save
from make_orveltaja import write_aseprite_source

SKIN = {"s": hex_color("ead4aa"), "t": hex_color("e4a672"), "e": hex_color("262b44"),
        "w": hex_color("ffffff"), "k": hex_color("3e2731")}


def pad(rows: list[str]) -> list[str]:
    return [row.ljust(BOX_WIDTH, ".") for row in rows]


def fabric(mask: list[str], lit: str, shade: str, shade_from: int, lines: dict[str, str] | None = None,
           line_cols: tuple[int, ...] = (), line_rows: tuple[int, ...] = ()) -> list[str]:
    """Fills each X of a mask with the lit letter and draws check or quilt lines (`lines`
    maps the lit and shade letter to their line); the shade is one pixel on the right edge
    of the body and the right arm, like the user's customers. `shade_from` is no longer used:
    it once started the shade at that column."""
    out = []
    for y, row in enumerate(pad(mask)):
        chars = []
        for x, char in enumerate(row):
            if char != "X":
                chars.append(char)
                continue
            base = lit
            if lines and (x in line_cols or y in line_rows):
                base = lines[base]
            chars.append(base)
        runs = [(m.start(), m.end()) for m in re.finditer(r"[^.]+", row)]
        for number, (start, end) in enumerate(runs):
            if len(runs) > 1 and number == 0:
                continue
            x = end - 1
            if row[x] == "X":
                chars[x] = lines[shade] if lines and chars[x] == lines.get(lit) else shade
        out.append("".join(chars))
    return out


# --- Tuulipukumies -------------------------------------------------------------------------
TUULIPUKU = Look(
    palette={**SKIN,
             "W": hex_color("c0cbdc"), "G": hex_color("8b9bb4"), "c": hex_color("5a6988"),  # grey hair
             "P": hex_color("b55088"), "p": hex_color("68386c"),  # shell suit
             "T": hex_color("2ce8f5"), "U": hex_color("0099db"),  # teal panel
             "1": hex_color("68386c"), "4": hex_color("68386c"), "2": hex_color("ffffff"), "3": hex_color("8b9bb4")},
    head_front=pad([
        "......WWGGc",
        ".....WWGGGGc",
        ".....Wssssssc",
        ".....swwsswwt",
        ".....swestwet",
        ".....sssttsst",
        ".....sGGGGGst",
        ".....sssssstt",
        "......sssst",
    ]),
    head_back=pad([
        "......WWGGc",
        ".....WWGGGGc",
        ".....WGGGGGGc",
        ".....WGGGGGGc",
        ".....WGGGGGcc",
        ".....sGGGGGct",
        ".....sssssstt",
        "......sssst",
    ]),
    torso_front=pad([
        "......PPPwwPpp",
        "....PPPPPTwPPppp",
        "...PPPPPPTwPPpppp",
        "...PP.PPPTwPPpp.pp",
        "...PP.PPPTwPPpp.pp",
        "...TT.PPPTwPPpp.UU",
        "......PPPTwPPpp",
        "......TTTTwTTUU",
        "......11111111",
    ]),
    torso_back=pad([
        "......PPPPPPpp",
        "....PPPPPPPPPppp",
        "...PPPPPPPPPPpppp",
        "...PP.PPPPPPPpp.pp",
        "...PP.TTTTTTUUU.pp",
        "...TT.PPPPPPPpp.UU",
        "......PPPPPPPpp",
        "......TTTTTTUUU",
        "......11111111",
    ]),
    lift=2,
    hand_inset=1,
)

# --- Flanellimies --------------------------------------------------------------------------
FLANNEL_MASK = [
    ".....XXXXssXXX",
    "...XXXXXXXXXXXXXX",
    "..XXXXXXXXXXXXXXXX",
    ".XXXXXXXXXXXXXXXXXX",
    ".XXX.XXXXXXXXXX.XXX",
    ".XXX.XXXXXXXXXX.XXX",
    ".XXX.XXXXXXXXXX.XXX",
    ".....XXXXXXXXXX",
    ".....BBBBYBBBBB",
]
FLANNEL_LINES = {"R": "q", "r": "Q"}
FLANELLI = Look(
    palette={**SKIN,
             "C": hex_color("3e8948"), "c": hex_color("265c42"), "V": hex_color("193c3e"),  # cap
             "a": hex_color("b86f50"), "b": hex_color("733e39"),  # hair, beard
             "R": hex_color("e43b44"), "r": hex_color("a22633"),  # flannel
             "q": hex_color("733e39"), "Q": hex_color("3e2731"),  # its check lines
             "B": hex_color("3e2731"), "Y": hex_color("feae34"),  # belt
             "1": hex_color("124e89"), "4": hex_color("124e89"), "2": hex_color("733e39"), "3": hex_color("3e2731")},
    head_front=pad([
        ".....CCCCCcc",
        "....CCCCCCCcc",
        "...VVVVVVVVVVV",
        "....asssssssa",
        "....swwssswwt",
        "....swesstwet",
        "....ssssttsst",
        "....abbbbbbba",
        "....abkkkkkba",
        "....aabbbbbaa",
        ".....abbbbba",
    ]),
    head_back=pad([
        ".....CCCCCcc",
        "....CCCCCCCcc",
        "....CCCCCCCCc",
        "....aaCCCCCaa",
        "....aaaaaaaaa",
        "....aaaaaaaab",
        "....aaaaaaaab",
        "....baaaaaaab",
        "....bsssssssb",
        ".....sssssss",
    ]),
    torso_front=fabric(FLANNEL_MASK, "R", "r", 12, FLANNEL_LINES, line_cols=(4, 8, 12, 16), line_rows=(3, 6)),
    torso_back=fabric([row.replace("ss", "XX").replace("Y", "B") for row in FLANNEL_MASK], "R", "r", 12,
                      FLANNEL_LINES, line_cols=(4, 8, 12, 16), line_rows=(3, 6)),
    lift=1,
)

# --- Toppatakkinainen ----------------------------------------------------------------------
COAT_MASK = [
    "......SSSSSS",
    "...XXXXSSSSSSXXXX",
    "..XXXXXXSSSSXXXXXX",
    "..XX.XXXXXXXXXX.XX",
    "..XX.XXXXXXXXXX.XX",
    "..XX.XXXXXXXXXX.XX",
    "....XXXXXXXXXXXX",
    "....XXXXXXXXXXXX",
    "....XXXXXXXXXXXX",
]
TOPPATAKKI = Look(
    palette={**SKIN,
             "Y": hex_color("fee761"), "y": hex_color("feae34"), "o": hex_color("d77643"),  # blonde hair
             "B": hex_color("0099db"), "b": hex_color("124e89"),  # coat
             "q": hex_color("124e89"), "Q": hex_color("262b44"),  # its quilt seams
             "S": hex_color("e43b44"), "R": hex_color("a22633"),  # scarf, mittens
             "1": hex_color("0099db"), "4": hex_color("262b44"), "2": hex_color("3e2731"), "3": hex_color("181425")},
    head_front=pad([
        ".......YYYy",
        ".....YYYYYyyo",
        "....YYsssssyyo",
        "....Yswwsswwyo",
        "....Yswestweyo",
        "....Ysssttssyo",
        "....Ysssksssyo",
        "....YYssssstyo",
        "....YY..ss..yo",
    ]),
    head_back=pad([
        ".......YYYy",
        ".....YYYYYyyo",
        "....YYYYYYyyyo",
        "....YYYYYYyyyo",
        "....YYYYYyyyyo",
        "....YYYYyyyyyo",
        "....YYYyyyyyoo",
        "....YYyyyyyyoo",
    ]),
    torso_front=[row.replace("SSSSSS", "SSSSRR").replace("SSSS", "SSRR") for row in
                 fabric(COAT_MASK, "B", "b", 11, {"B": "q", "b": "Q"}, line_rows=(2, 5, 8))],
    torso_back=None,
    hand=["SR", "SR"],
)
# From behind the long hair falls over the scarf and the coat's shoulders, narrowing to tips.
HAIR_OVER_BACK = [
    ".....YYYYyyyyoo",
    ".....YYYYyyyyoo",
    "......YYYyyyoo",
    ".......Yyyyo",
]


def overlay(rows: list[str], over: list[str]) -> list[str]:
    out = list(rows)
    for y, row in enumerate(pad(over)):
        out[y] = "".join(o if o != "." else r for r, o in zip(out[y], row))
    return out


TOPPATAKKI.torso_back = overlay(fabric([row.replace("S", "X") for row in COAT_MASK], "B", "b", 11,
                                       {"B": "q", "b": "Q"}, line_rows=(2, 5, 8)), HAIR_OVER_BACK)

# --- Hupparinainen -------------------------------------------------------------------------
HUPPARI = Look(
    palette={**SKIN,
             "H": hex_color("d77643"), "h": hex_color("be4a2f"), "o": hex_color("733e39"),  # red hair
             "g": hex_color("3a4466"),  # glasses
             "G": hex_color("8b9bb4"), "D": hex_color("5a6988"), "W": hex_color("c0cbdc"),  # hoodie
             "1": hex_color("262b44"), "4": hex_color("262b44"), "2": hex_color("ffffff"), "3": hex_color("c0cbdc")},
    head_front=pad([
        "......HHHho",
        ".....HHHHhho",
        ".....HssssHho",
        ".....gggtggg",
        ".....swwsswwt",
        ".....swestwet",
        ".....sssttsst",
        ".....ssskksst",
        "......sssst",
    ]),
    head_back=pad([
        "......HHHho",
        ".....HHHHhho",
        ".....HHHHhhho",
        ".....HHHHhhho",
        ".....HHHhhhoo",
        ".....sHHhhhot",
        ".....ssshhhst",
        "......sshhst",
    ]),
    torso_front=pad([
        ".....WWWsssWWD",
        "....GGWWwswWWDD",
        "...GGGGGwGwGDDDD",
        "...GG.GGwGwGDD.DD",
        "...GG.GGGGGGDD.DD",
        "...GG.GDDDDDDD.DD",
        "......GDGGGGDD",
        "......GDDDDDDD",
        "......11111111",
    ]),
    torso_back=pad([
        ".....WWWhhhWD",
        "....GGWWWhoWDD",
        "...GGGWWWhoWDDD",
        "...GG.GWWWWDDD.DD",
        "...GG.GGGGGGDD.DD",
        "...GG.GGGGGGDD.DD",
        "......GGGGGGDD",
        "......GDDDDDDD",
        "......11111111",
    ]),
    hand_inset=1,
)

# --- Kalastajaliivimies --------------------------------------------------------------------
KALASTAJA = Look(
    palette={**SKIN,
             "K": hex_color("c0cbdc"), "k": hex_color("8b9bb4"),  # bucket hat
             "a": hex_color("b86f50"), "b": hex_color("733e39"),  # hair, moustache
             "S": hex_color("0099db"), "Q": hex_color("124e89"),  # shirt
             "V": hex_color("3e8948"), "v": hex_color("265c42"), "x": hex_color("193c3e"),  # vest, pockets
             "1": hex_color("c28569"), "4": hex_color("c28569"), "2": hex_color("733e39"), "3": hex_color("3e2731")},
    head_front=pad([
        "......KKKKk",
        ".....KKKKKkk",
        "....KKKKKKKkkk",
        ".....ssssssst",
        ".....swwsswwt",
        ".....swestwet",
        ".....sssttsst",
        ".....sbbbbbst",
        ".....sssssstt",
        "......sssst",
    ]),
    head_back=pad([
        "......KKKKk",
        ".....KKKKKkk",
        "....KKKKKKKkkk",
        ".....aaaaaaab",
        ".....aaaaaaab",
        ".....saaaaabt",
        ".....ssssssst",
        "......sssst",
    ]),
    torso_front=pad([
        "....SVVVSssSVvvQ",
        "...SSVVVVSSVVvvQQ",
        "..SSSVxVVSSVxVvvQQ",
        "..SS.VxVVSSVxVv.QQ",
        "..SS.VVVVSSVVVv.QQ",
        "..SS.VxxVSSVxxv.QQ",
        ".....VVVVSSVVvv",
        ".....vvvvSSvvvv",
        "......11111111",
    ]),
    torso_back=pad([
        "....SVVVVVVVVvvQ",
        "...SSVVVVVVVVvvQQ",
        "..SSSVVVVVVVVvvvQQ",
        "..SS.VVVVVVVVVv.QQ",
        "..SS.VVxxxxxxVv.QQ",
        "..SS.VVxxxxxxVv.QQ",
        ".....VVVVVVVVvv",
        ".....vvvvvvvvvv",
        "......11111111",
    ]),
)

# --- Lenkkeilijä ---------------------------------------------------------------------------
LENKKEILIJA = Look(
    palette={**SKIN,
             "H": hex_color("3e2731"), "h": hex_color("181425"),  # short dark hair
             "r": hex_color("e43b44"), "R": hex_color("a22633"),  # headband
             "Y": hex_color("fee761"), "y": hex_color("feae34"), "z": hex_color("8b9bb4"),  # jacket, zip
             "1": hex_color("262b44"), "4": hex_color("262b44"), "2": hex_color("e43b44"), "3": hex_color("ffffff")},
    head_front=pad([
        ".....HHHHHHh",
        ".....rrrrrrrR",
        ".....ssssssst",
        ".....swwsswwt",
        ".....swestwet",
        ".....sssttsst",
        ".....ssskksst",
        "......sssst",
    ]),
    head_back=pad([
        ".....HHHHHHh",
        ".....rrrrrrrR",
        ".....HHHHHHHH",
        ".....HHHHHHHH",
        ".....sHHHHHHt",
        ".....ssssssst",
        "......sssst",
    ]),
    torso_front=pad([
        ".....YYYsssYyy",
        "....YYYYYzYYyyy",
        "...YYYYYYzYYyyyy",
        "...ww.wwwzwwww.ww",
        "...YY.YYYzYYyy.yy",
        "...YY.YYYzYYyy.yy",
        "......YYYzYYyy",
        "......YYYzYyyy",
        "......11111111",
    ]),
    torso_back=pad([
        ".....YYYYYYyy",
        "....YYYYYYYYyyy",
        "...YYYYYYYYYyyyy",
        "...ww.wwwwwwww.ww",
        "...YY.YYYYYYyy.yy",
        "...YY.YYYYYYyy.yy",
        "......YYYYYYyy",
        "......YYYYYyyy",
        "......11111111",
    ]),
    lift=1,
    hand_inset=1,
)

# --- Nahkatakkinainen ----------------------------------------------------------------------
NAHKATAKKI = Look(
    palette={**SKIN,
             "P": hex_color("b55088"), "p": hex_color("68386c"),  # purple bob
             "r": hex_color("e43b44"),  # lips
             "L": hex_color("3a4466"), "l": hex_color("262b44"), "h": hex_color("8b9bb4"),  # leather, sheen
             "1": hex_color("262b44"), "4": hex_color("262b44"), "2": hex_color("3e2731"), "3": hex_color("181425")},
    head_front=pad([
        "......PPPPp",
        ".....PPPPPPpp",
        "....PPPPPPPPpp",
        "....Pswwsswwtp",
        "....Pswestwetp",
        "....Psssttsstp",
        "....Psssrrsstp",
        "....PP.ssss.pp",
    ]),
    head_back=pad([
        "......PPPPp",
        ".....PPPPPPpp",
        "....PPPPPPPPpp",
        "....PPPPPPPPpp",
        "....PPPPPPPppp",
        "....PPPPPPPppp",
        "....PPPPPPPppp",
        "....PP.ssss.pp",
    ]),
    torso_front=pad([
        "....hLLswwsLLlll",
        "...hLLLwwwwLLllll",
        "..hLLLLwwwwLLlllll",
        "..hL.LLLwwwwLLl.ll",
        "..hL.LLLwwwwLLl.ll",
        "..hL.LLLwwwwLLl.ll",
        ".....LLLwwwwLll",
        ".....LLLLLLLlll",
        "......11111111",
    ]),
    torso_back=pad([
        "....hLLLLLLLLlll",
        "...hLLLLLLLLLllll",
        "..hLLLLLLLLLLlllll",
        "..hL.LLLLLLLLLl.ll",
        "..hL.LLLLLLLLLl.ll",
        "..hL.LLLLLLLLLl.ll",
        ".....LLLLLLLLll",
        ".....LLLLLLLlll",
        "......11111111",
    ]),
)

# --- Villapaitanainen ----------------------------------------------------------------------
VILLAPAITA = Look(
    palette={**SKIN,
             "H": hex_color("733e39"), "h": hex_color("3e2731"),  # hair in a bun
             "N": hex_color("3a4466"), "n": hex_color("262b44"),  # sweater
             "r": hex_color("e43b44"),  # pattern red (w is the pattern white)
             "1": hex_color("b86f50"), "4": hex_color("b86f50"), "2": hex_color("3e2731"), "3": hex_color("181425")},
    head_front=pad([
        ".......HHh",
        ".......Hhh",
        ".....HHHHHHh",
        ".....Hssssssh",
        ".....swwsswwt",
        ".....swestwet",
        ".....sssttsst",
        ".....ssskksst",
        "......sssst",
    ]),
    head_back=pad([
        ".......HHh",
        ".......Hhh",
        ".....HHHHHHh",
        ".....HHHHHHhh",
        ".....HHHHHHhh",
        ".....HHHHHhhh",
        ".....ssssssst",
        "......sssst",
    ]),
    torso_front=pad([
        "....NNwrwsswrwnn",
        "...NNrwrwrwrwrwnn",
        "..NNNwrwrwrwrwrnnn",
        "..NN.NNNNNNNNnn.nn",
        "..NN.NNNNNNNNnn.nn",
        "..wr.NNNNNNNNnn.rw",
        ".....NNNNNNNNnn",
        ".....wrwrwrwrwn",
        "......11111111",
    ]),
    torso_back=pad([
        "....NNwrwrwrwrnn",
        "...NNrwrwrwrwrwnn",
        "..NNNwrwrwrwrwrnnn",
        "..NN.NNNNNNNNnn.nn",
        "..NN.NNNNNNNNnn.nn",
        "..wr.NNNNNNNNnn.rw",
        ".....NNNNNNNNnn",
        ".....wrwrwrwrwn",
        "......11111111",
    ]),
)

LOOKS = {
    "normaali_tuulipuku_32": TUULIPUKU,
    "normaali_flanelli_32": FLANELLI,
    "normaali_toppatakki_32": TOPPATAKKI,
    "normaali_huppari_32": HUPPARI,
    "normaali_kalastaja_32": KALASTAJA,
    "normaali_lenkkeilija_32": LENKKEILIJA,
    "normaali_nahkatakki_32": NAHKATAKKI,
    "normaali_villapaita_32": VILLAPAITA,
}


# The grids above draw each head a pixel left of the legs; the user's originals centre it.
HEAD_SHIFT = 1
for _look in LOOKS.values():
    _look.head_front = ["." * HEAD_SHIFT + row[:-HEAD_SHIFT] for row in _look.head_front]
    _look.head_back = ["." * HEAD_SHIFT + row[:-HEAD_SHIFT] for row in _look.head_back]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="also write a 4x preview of all four sheets")
    parser.add_argument("--force-aseprite", action="store_true")
    args = parser.parse_args()
    sheets = {name: draw_sheet(look) for name, look in LOOKS.items()}
    save(sheets, args.preview)
    for name in sheets:
        write_aseprite_source(TEXTURE_DIR / f"{name}.png", args.force_aseprite)


if __name__ == "__main__":
    main()
