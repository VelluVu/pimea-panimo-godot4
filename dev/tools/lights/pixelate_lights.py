"""Remakes the cellar's older lights pixel exact: each source texture resampled smoothly to
the size it is drawn at (its old texture_scale and node scale), then its alpha stepped and
dithered per world pixel (pixel_dither.py). The PointLight2Ds then use scale 1 and
texture_scale 1, so one texel is one game pixel. Colours inside the texture are kept.

    python dev/tools/lights/pixelate_lights.py
"""

import os

from PIL import Image

from pixel_dither import stepped

TEXTURES = os.path.join(os.path.dirname(__file__), "..", "..", "..", "assets", "textures")

# name -> (source texture, drawn size, light's global position). Global, because the
# Lights node in main.tscn sits at (0, -1) and the dither follows world pixels.
LIGHTS = {
    "light_glow_stairs.png": ("light_glow_32.png", (340, 340), (27, 80)),
    "light_glow_wall.png": ("light_glow_32.png", (114, 114), (305, 138)),
    "light_glow_wall2.png": ("light_glow_32.png", (118, 118), (495, 133)),
    "light_cone_bar.png": ("light_cone_64x120.png", (422, 564), (394, 340)),
}


def main() -> None:
    for name, (source, size, centre) in LIGHTS.items():
        smooth = Image.open(os.path.join(TEXTURES, source)).convert("RGBA").resize(size, Image.BICUBIC)
        origin = (centre[0] - size[0] // 2, centre[1] - size[1] // 2)
        image = Image.new("RGBA", size)
        for y in range(size[1]):
            for x in range(size[0]):
                r, g, b, a = smooth.getpixel((x, y))
                alpha = stepped(a / 255.0, origin[0] + x, origin[1] + y)
                image.putpixel((x, y), (r, g, b, round(alpha * 255)))
        out = os.path.normpath(os.path.join(TEXTURES, name))
        image.save(out)
        print("wrote", out, size, "top-left at", origin)


if __name__ == "__main__":
    main()
