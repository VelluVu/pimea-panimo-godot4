"""Gives the theme's fallback fonts the game font's line metrics.

Godot sizes a line by the tallest font in a fallback chain, so a fallback with a big
ascent and descent (Noto Sans Symbols 2) stretches every label in the game. This rewrites
each fallback's ascent, descent and line gap to the same share of its em as the game
font's (m5x7), so the chain is exactly as tall as m5x7 alone. The glyphs are untouched.

    pip install fonttools
    python dev/tools/fonts/fit_fallback_metrics.py

Run it again after replacing a fallback font with a fresh download.
"""

from pathlib import Path

from fontTools.ttLib import TTFont

ROOT = Path(__file__).resolve().parents[3]
GAME_FONT = ROOT / "assets/fonts/m5x7.ttf"
FALLBACKS = [
    ROOT / "assets/fonts/noto_sans_symbols2/NotoSansSymbols2-Regular.ttf",
    ROOT / "assets/fonts/twemoji/Twemoji.Mozilla.ttf",
]


def line_shares(font):
    """Ascent and descent as shares of the em, as Godot reads them (hhea)."""
    em = font["head"].unitsPerEm
    return font["hhea"].ascent / em, -font["hhea"].descent / em


def fit(path, ascent_share, descent_share):
    font = TTFont(path)
    em = font["head"].unitsPerEm
    ascent = round(ascent_share * em)
    descent = round(descent_share * em)
    hhea = font["hhea"]
    hhea.ascent, hhea.descent, hhea.lineGap = ascent, -descent, 0
    os2 = font["OS/2"]
    os2.sTypoAscender, os2.sTypoDescender, os2.sTypoLineGap = ascent, -descent, 0
    os2.usWinAscent, os2.usWinDescent = ascent, descent
    font.save(path)
    print(f"{path.name}: ascent {ascent}, descent {descent} (em {em})")


def main():
    ascent_share, descent_share = line_shares(TTFont(GAME_FONT))
    for path in FALLBACKS:
        fit(path, ascent_share, descent_share)


if __name__ == "__main__":
    main()
