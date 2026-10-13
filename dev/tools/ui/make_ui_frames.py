"""Draws the theme's 9-slice UI frames pixel by pixel into assets/textures/ui/.

Every frame is a small PNG: dark outline with cut corners, a light top-left
bevel and a darker bottom-right shade. Buttons get a 2 px lip under them that
disappears when pressed; panels cast a hard 1 px shadow. Colours come from the
existing theme palette. Run: python dev/tools/ui/make_ui_frames.py
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


def with_drop_shadow(img: Image.Image) -> Image.Image:
    """Adds a hard 1 px shadow to the right and bottom, offset by one pixel."""
    w, h = img.size
    out = Image.new("RGBA", (w + 1, h + 1), CLEAR)
    shadow = Image.new("RGBA", (w, h), CLEAR)
    alpha = img.getchannel("A")
    shadow.paste(DROP_SHADOW, (0, 0, w, h), alpha)
    out.paste(shadow, (1, 1))
    out.alpha_composite(img)
    return out


FRAMES = {
    # Raised wooden button: 2 px lip under the face.
    "button_normal": lambda: frame(SIZE, SIZE, INK, WOOD_FACE, WOOD_LIGHT, SHADE, WOOD_HOVER_LIGHT, shade_rows=2),
    "button_hover": lambda: frame(SIZE, SIZE, INK, WOOD_HOVER, WOOD_HOVER_LIGHT, WOOD, GOLD, shade_rows=2),
    # Pushed in: the lip is gone and the top edge falls into shadow.
    "button_pressed": lambda: frame(SIZE, SIZE, INK, SHADE, DARK, WOOD, light_rows=2),
    "button_disabled": lambda: frame(SIZE, SIZE, DARK, PANEL, SHADE, None),
    "button_focus": lambda: frame(SIZE, SIZE, GOLD_LIGHT, CLEAR),
    "panel": lambda: with_drop_shadow(frame(SIZE, SIZE, INK, PANEL, WOOD, DARK, WOOD_HOVER)),
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
