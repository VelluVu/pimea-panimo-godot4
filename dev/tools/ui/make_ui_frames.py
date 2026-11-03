"""Draws the theme's 9-slice UI frames pixel by pixel into assets/textures/ui/.

Every frame is a small PNG: dark outline with cut corners, a light top-left
bevel and a darker bottom-right shade. Buttons are raised planks with a 2 px lip
that disappears when pressed; red ones end something (the X on hover, closing
the doors). Windows get a wooden rim with
brass studs in the corners and a 2 px dithered shadow; title bars are recessed
plaques. Sliders are a glass tube that fills with beer, foam at the front, with a
tap handle to drag. Run: python dev/tools/ui/make_ui_frames.py
"""
from pathlib import Path

from PIL import Image

OUT_DIR = Path(__file__).resolve().parents[3] / "assets" / "textures" / "ui"
SIZE = 16


def rgb(hex_str: str, alpha: int = 255) -> tuple:
    h = hex_str.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), alpha)


CLEAR = (0, 0, 0, 0)
INK = rgb("0d0805")
DARK = rgb("170f09")
SHADE = rgb("2a1c12")
PANEL = rgb("241811")
WOOD = rgb("3f2a1a")
WOOD_FACE = rgb("4a3220")
WOOD_LIGHT = rgb("5e4026")
WOOD_HOVER = rgb("6b4726")
WOOD_HOVER_LIGHT = rgb("8a5e33")
GOLD_DARK = rgb("a87a35")
GOLD = rgb("d3a24f")
GOLD_LIGHT = rgb("f2c96b")
DROP_SHADOW = rgb("000000", 110)
PLANK = rgb("5a3f2e")
PLANK_LIGHT = rgb("7d5a40")
PLANK_SIDE = rgb("6a4a34")
PLANK_LIP = rgb("2e1d16")
PLANK_HOVER = rgb("6c4c36")
PLANK_PRESSED = rgb("4a3426")
RIM_LIGHT = rgb("9a7650")
RIM = rgb("6e4c32")
RIM_DARK = rgb("3a2516")
INSET = rgb("170f0b")
BRASS = rgb("d9ad55")
BRASS_LIGHT = rgb("fff0b0")
BRASS_DARK = rgb("8a6428")
DANGER = (rgb("7a2a20"), rgb("b84a34"), rgb("3a120e"))
DANGER_HOVER = (rgb("8e3326"), rgb("d05a40"), rgb("3a120e"))
DANGER_PRESSED = rgb("6a241c")
GLASS = rgb("1c2026")
GLASS_LIGHT = rgb("3a4450")
BEER = rgb("d08a1c")
BEER_HOVER = rgb("e09a2a")
BEER_LIGHT = rgb("f0b040")
BEER_DARK = rgb("8a5410")
BUBBLE = rgb("f8d070")
FOAM = rgb("f4ecd8")
FOAM_LIGHT = rgb("ffffff")
TAP = rgb("b04a2a")
TAP_HOVER = rgb("d06040")
TAP_LIGHT = rgb("f08a60")
TAP_DARK = rgb("6a2010")
TAP_DISABLED = rgb("5a4a40")
STEEL = rgb("c8c8d4")
STEEL_DARK = rgb("9a9aa8")


def frame(w: int, h: int, outline, body, light=None, shade=None, top=None,
          light_rows: int = 1, shade_rows: int = 1, cut_corners: bool = True) -> Image.Image:
    """Outline ring, filled body, then bevel rows inside the outline.

    Light falls from above, so the top edge (top) can be brighter than the left (light).
    """
    img = Image.new("RGBA", (w, h), CLEAR)
    px = img.load()
    for y in range(h):
        for x in range(w):
            edge = x == 0 or y == 0 or x == w - 1 or y == h - 1
            px[x, y] = outline if edge else body
    if light is not None:
        for i in range(1, 1 + light_rows):
            for y in range(1, h - 1 - shade_rows):
                px[i, y] = light
            for x in range(1, w - 1):
                px[x, i] = top or light
    if shade is not None:
        for i in range(1, 1 + shade_rows):
            for x in range(1, w - 1):
                px[x, h - 1 - i] = shade
            for y in range(1 + light_rows, h - 1):
                px[w - 1 - i, y] = shade
    if cut_corners:
        for x, y in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)):
            px[x, y] = CLEAR
    return img


def plank(colors: tuple, side=None) -> Image.Image:
    """A raised button face: (face, top edge, lip), with a 2 px lip under it."""
    face, top, lip = colors
    return frame(SIZE, SIZE, INK, face, side or top, lip, top, shade_rows=2)


def pushed(face, top_shadow) -> Image.Image:
    """Pushed in: the lip is gone and the top edge falls into shadow."""
    return frame(SIZE, SIZE, INK, face, top_shadow, None, light_rows=2)


def window() -> Image.Image:
    """Wooden rim lit from above left, an inner dark line, and brass studs at the corners."""
    img = frame(SIZE, SIZE, INK, PANEL, RIM_LIGHT, RIM_DARK, RIM_LIGHT)
    px = img.load()
    for i in range(2, SIZE - 2):
        for x, y in ((i, 2), (i, SIZE - 3), (2, i), (SIZE - 3, i)):
            px[x, y] = RIM
    for i in range(3, SIZE - 3):
        for x, y in ((i, 3), (i, SIZE - 4), (3, i), (SIZE - 4, i)):
            px[x, y] = INK
    for cx, cy in ((1, 1), (SIZE - 3, 1), (1, SIZE - 3), (SIZE - 3, SIZE - 3)):
        px[cx, cy] = BRASS_LIGHT
        px[cx + 1, cy] = BRASS
        px[cx, cy + 1] = BRASS
        px[cx + 1, cy + 1] = BRASS_DARK
    return img


def plaque() -> Image.Image:
    """A title bar sunk into the window: dark inside, a light lip below, nails in the corners."""
    img = frame(SIZE, SIZE, INK, INSET, INK, RIM, cut_corners=False)
    px = img.load()
    for x, y in ((2, 2), (SIZE - 3, 2), (2, SIZE - 3), (SIZE - 3, SIZE - 3)):
        px[x, y] = BRASS
    return img


def tab_selected() -> Image.Image:
    """The open tab: sunk in, with a brass line along its bottom."""
    img = frame(SIZE, SIZE, INK, INSET, INK, None, cut_corners=False)
    px = img.load()
    for x in range(1, SIZE - 1):
        px[x, SIZE - 2] = BRASS
    return img


def tube() -> Image.Image:
    """The slider's empty glass tube, 8 px tall."""
    img = Image.new("RGBA", (8, 8), CLEAR)
    px = img.load()
    for y in range(8):
        for x in range(8):
            edge = x in (0, 7) or y in (0, 7)
            px[x, y] = INK if edge else (GLASS_LIGHT if y == 1 else GLASS)
    for x, y in ((0, 0), (7, 0), (0, 7), (7, 7)):
        px[x, y] = CLEAR
    return img


def beer(body) -> Image.Image:
    """The filled part: beer with bubbles in the tiled middle, a foam head at the front (in
    the right margin, so it stays at the handle)."""
    w = 12
    img = Image.new("RGBA", (w, 8), CLEAR)
    px = img.load()
    for x in range(1, w - 1):
        for y in range(1, 7):
            px[x, y] = BEER_LIGHT if y == 1 else (BEER_DARK if y == 6 else body)
    for x, y in ((3, 4), (6, 2), (8, 5)):
        px[x, y] = BUBBLE
    for x in (w - 3, w - 2):
        for y in range(1, 7):
            px[x, y] = FOAM
    px[w - 2, 1] = FOAM_LIGHT
    return img


def tap(grip) -> Image.Image:
    """The grabber: a tap handle whose neck dips into the tube. The lower half is empty, so
    the icon, which the slider centres on the tube, puts the handle above it."""
    w, h = 9, 25
    img = Image.new("RGBA", (w, h), CLEAR)
    px = img.load()
    for y in range(6):
        for x in range(w):
            edge = x in (0, w - 1) or y in (0, 5)
            px[x, y] = INK if edge else grip
    if grip != TAP_DISABLED:
        for x in range(1, w - 1):
            px[x, 1] = TAP_LIGHT
            px[x, 4] = TAP_DARK
    for y in range(6, 9):
        px[3, y] = INK
        px[5, y] = INK
        px[4, y] = STEEL if y == 6 else STEEL_DARK
    return img


def wrench() -> Image.Image:
    """The upgrades button's 12 px wrench: a 2 px handle from the bottom left to an open jaw
    at the top right, steel lit from above left, outlined."""
    size = 12
    steel = set()
    for t in range(6):
        steel.add((2 + t, 9 - t))
        steel.add((3 + t, 9 - t))
    steel.update({(1, 9), (1, 10), (2, 10)})
    for y in range(size):
        for x in range(size):
            dx, dy = x - 8, y - 3
            ring = 2.2 <= (dx * dx + dy * dy) ** 0.5 <= 3.3
            mouth = dx >= 1 and dy <= -1
            if ring and not mouth:
                steel.add((x, y))
    img = Image.new("RGBA", (size, size), CLEAR)
    px = img.load()
    for x, y in steel:
        lit = (x - 1, y) not in steel or (x, y - 1) not in steel
        px[x, y] = STEEL if lit else STEEL_DARK
    for y in range(size):
        for x in range(size):
            if (x, y) in steel:
                continue
            if any((x + ox, y + oy) in steel for ox, oy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                px[x, y] = INK
    return img


def with_drop_shadow(img: Image.Image, depth: int = 1) -> Image.Image:
    """Adds a shadow `depth` px to the right and bottom: solid next to the frame, dithered
    further out, so it fades on the pixel grid."""
    w, h = img.size
    out = Image.new("RGBA", (w + depth, h + depth), CLEAR)
    alpha = img.getchannel("A")
    for step in range(depth, 0, -1):
        shadow = Image.new("RGBA", (w, h), CLEAR)
        shadow.paste(DROP_SHADOW, (0, 0, w, h), alpha)
        if step > 1:
            px = shadow.load()
            for y in range(h):
                for x in range(w):
                    if (x + y) % 2:
                        px[x, y] = CLEAR
        out.alpha_composite(shadow, (step, step))
    out.alpha_composite(img)
    return out


FRAMES = {
    # Raised wooden button: 2 px lip under the face.
    "button_normal": lambda: plank((PLANK, PLANK_LIGHT, PLANK_LIP), PLANK_SIDE),
    "button_hover": lambda: plank((PLANK_HOVER, GOLD, PLANK_LIP), PLANK_LIGHT),
    "button_pressed": lambda: pushed(PLANK_PRESSED, PLANK_LIP),
    "button_disabled": lambda: frame(SIZE, SIZE, DARK, PANEL, SHADE, None),
    "button_focus": lambda: frame(SIZE, SIZE, GOLD_LIGHT, CLEAR),
    # Ends something: closing the doors, and the X while hovered.
    "button_danger_normal": lambda: plank(DANGER),
    "button_danger_hover": lambda: plank(DANGER_HOVER),
    "button_danger_pressed": lambda: pushed(DANGER_PRESSED, DANGER[2]),
    "tab_selected": tab_selected,
    "panel": lambda: with_drop_shadow(window(), 2),
    "header": plaque,
    # The beer tube slider; the scrollbar keeps the plain track and fill below.
    "slider_tube": tube,
    "slider_beer": lambda: beer(BEER),
    "slider_beer_hover": lambda: beer(BEER_HOVER),
    "slider_tap": lambda: tap(TAP),
    "slider_tap_hover": lambda: tap(TAP_HOVER),
    "slider_tap_disabled": lambda: tap(TAP_DISABLED),
    # The top bar's upgrades button, sized to its 22 px buttons.
    "icon_wrench": wrench,
    # Slider: a sunken track and a gold fill.
    "slider_track": lambda: frame(6, 6, INK, DARK, INK, WOOD, cut_corners=False),
    "slider_fill": lambda: frame(6, 6, INK, GOLD, GOLD_LIGHT, GOLD_DARK, cut_corners=False),
    "slider_fill_hover": lambda: frame(6, 6, INK, GOLD_LIGHT, GOLD_LIGHT, GOLD, cut_corners=False),
}


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for name, make in FRAMES.items():
        path = OUT_DIR / f"{name}.png"
        make().save(path)
        print(f"wrote {path.relative_to(OUT_DIR.parents[2])}")


if __name__ == "__main__":
    main()
