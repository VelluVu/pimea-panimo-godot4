"""Draws Vanha mestari Aatu's 48x48 portrait for the brew day guide.

Two frames side by side (mouth shut, mouth open) in the characters' palette. Shapes are
whole-pixel ellipses and boxes, then a 1 px dark outline is added around the silhouette.
Rerun after editing: python dev/tools/portraits/make_old_master.py
"""

from pathlib import Path

from PIL import Image

SIZE = 48
OUT = Path(__file__).resolve().parents[3] / "assets/textures/characters/vanha_mestari_portrait_48.png"

# The palette the 32 px customers use.
OUTLINE = (38, 43, 68)
SKIN = (232, 183, 150)
SKIN_MID = (228, 166, 114)
SKIN_DARK = (184, 111, 80)
GREY = (139, 155, 180)
GREY_DARK = (116, 132, 157)
WHITE = (255, 255, 255)
SHIRT = (38, 92, 66)
SHIRT_DARK = (25, 60, 62)
APRON = (115, 62, 57)
APRON_DARK = (62, 39, 49)


def in_ellipse(x, y, cx, cy, rx, ry):
    return ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0


def draw(mouth_open):
    px = {}

    def put(x, y, c):
        if 0 <= x < SIZE and 0 <= y < SIZE:
            px[(x, y)] = c

    # Shoulders: shirt, the leather apron's bib and straps.
    for y in range(36, SIZE):
        inset = max(0, 39 - y) * 2
        for x in range(5 + inset, 43 - inset):
            put(x, y, SHIRT_DARK if x >= 36 - inset else SHIRT)
    for y in range(39, SIZE):
        for x in range(16, 32):
            put(x, y, APRON_DARK if x >= 29 or y == 39 else APRON)
    for y in range(36, 39):
        for x in (16, 17, 30, 31):
            put(x, y, APRON_DARK if x >= 30 else APRON)
    put(23, 43, APRON_DARK)
    put(24, 43, APRON_DARK)

    # Head with the light from the upper left.
    cx, cy = 23.5, 18.5
    for y in range(5, 33):
        for x in range(12, 36):
            if in_ellipse(x, y, cx, cy, 10.2, 12.2):
                c = SKIN
                if x >= 30:
                    c = SKIN_MID
                if x >= 32 or (x >= 30 and y >= 24):
                    c = SKIN_DARK
                put(x, y, c)
    # Ears.
    for y in range(17, 22):
        put(12, y, SKIN_MID)
        put(35, y, SKIN_DARK)
    put(13, 19, SKIN_DARK)
    # A shine on the bald top.
    for x, y in ((18, 9), (19, 8), (20, 8), (18, 10)):
        put(x, y, WHITE)

    # Grey tufts over the ears.
    for y in range(11, 19):
        for x in range(11, 15 if y < 16 else 14):
            if (x + y) % 5 != 0:
                put(x, y, GREY)
        for x in range(33 if y < 16 else 34, 37):
            if (x + y) % 5 != 0:
                put(x, y, GREY_DARK)
    put(10, 12, GREY)
    put(37, 12, GREY_DARK)

    # Bushy brows, the outer ends dropping.
    for x in range(16, 23):
        put(x, 15, GREY)
    for x in range(25, 32):
        put(x, 15, GREY_DARK if x >= 30 else GREY)
    for x in (16, 17, 30, 31):
        put(x, 16, GREY_DARK)
    put(15, 16, GREY)
    put(32, 16, GREY_DARK)

    # Eyes: a dark pupil with a white glint, a wrinkle under.
    for ex in (18, 27):
        put(ex, 18, WHITE)
        put(ex + 1, 18, OUTLINE)
        put(ex + 2, 18, OUTLINE)
        put(ex + 1, 17, OUTLINE)
        put(ex + 2, 17, OUTLINE)
        put(ex + 1, 20, SKIN_MID)
        put(ex + 2, 20, SKIN_MID)

    # A big ruddy nose.
    for y in range(19, 24):
        for x in range(22, 26):
            put(x, y, SKIN_MID if x < 25 else SKIN_DARK)
    for x in range(21, 27):
        put(x, 23, SKIN_DARK)
    put(22, 21, SKIN)
    put(22, 22, SKIN)

    # The beard: a wide ellipse below the cheeks, darker to the right and bottom.
    bx, by = 23.5, 31.0
    for y in range(24, 43):
        for x in range(10, 38):
            if in_ellipse(x, y, bx, by, 12.3, 10.5) and y >= 25:
                c = GREY
                if x >= 30 or y >= 39:
                    c = GREY_DARK
                put(x, y, c)
    # A few broken strands down the beard.
    for sx, top, bottom in ((16, 31, 36), (20, 30, 39), (24, 32, 40), (28, 30, 37), (32, 30, 35)):
        for y in range(top, bottom):
            if y % 4 != 3:
                put(sx, y, GREY_DARK if sx < 30 else OUTLINE)
    # Moustache sweeping out over the beard, tips curling up, a shadow line under it.
    for x in range(16, 32):
        put(x, 24, GREY)
        put(x, 25, GREY if x < 30 else GREY_DARK)
        put(x, 26, GREY_DARK)
    for x, y in ((15, 23), (14, 22), (32, 23), (33, 22), (15, 24), (32, 24), (15, 25), (32, 25)):
        put(x, y, GREY if x < 30 else GREY_DARK)

    # The mouth shows only when he talks.
    if mouth_open:
        for x in range(21, 27):
            put(x, 27, APRON_DARK)
            put(x, 28, APRON_DARK)
        put(22, 28, APRON)
        put(23, 28, APRON)
        for x in range(21, 27):
            put(x, 29, GREY_DARK)

    # A 1 px outline around the whole silhouette.
    filled = set(px)
    for (x, y) in list(filled):
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (x + dx, y + dy)
            if n not in filled and 0 <= n[0] < SIZE and 0 <= n[1] < SIZE:
                px[n] = OUTLINE
    return px


def main():
    sheet = Image.new("RGBA", (SIZE * 2, SIZE), (0, 0, 0, 0))
    for frame, mouth_open in enumerate((False, True)):
        for (x, y), c in draw(mouth_open).items():
            sheet.putpixel((frame * SIZE + x, y), c + (255,))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(OUT)
    print(OUT)


if __name__ == "__main__":
    main()
