"""Builds assets/fonts/pimea_icons/pimea_icons.ttf: hand-drawn pixel icons for the emoji
and arrows the m5x7 font lacks.

The theme puts this font first among m5x7's fallbacks, so text like "🍺 Hyvät suhteet"
keeps its emoji and draws our pixel icon in place of Twemoji's. One icon pixel is one m5x7
pixel (64 units at 1024 per em), so icons scale in the same whole steps as the text.
Coloured icons are COLR layers with a CPAL palette; the arrows are plain glyphs and take
the text colour.

    python dev/tools/icons/make_icon_font.py

Edit a grid below and rerun. Each grid is 9 rows of 9 characters ('.' is empty), with
the bottom row one pixel below the baseline. Needs fontTools (pip install fonttools).
"""

import os

from fontTools.colorLib.builder import buildCOLR, buildCPAL
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
OUT = os.path.join(ROOT, "assets", "fonts", "pimea_icons", "pimea_icons.ttf")

UNITS_PER_EM = 1024
PIXEL = 64
## Icon rows run from 8 pixels above the baseline down to 1 below it, like a capital
## with a one-pixel drop.
ICON_TOP = 8
ICON_ADVANCE = 10
ASCENT = 682
DESCENT = -128

PALETTE = {
	"w": "#f2ecd8",  # cream
	"f": "#f5d6b0",  # foam, light skin
	"y": "#f2c94c",  # gold
	"o": "#e8862a",  # orange
	"r": "#c8402e",  # red
	"p": "#e07a8a",  # pink
	"g": "#6aa84f",  # green
	"G": "#3d6b35",  # dark green
	"b": "#5b8fd6",  # blue
	"c": "#9ed6e6",  # ice, glass
	"l": "#d9a066",  # tan
	"n": "#8a5a32",  # brown
	"N": "#5a3a22",  # dark brown
	"s": "#b4b4b4",  # grey
	"S": "#6b6b6b",  # dark grey
	"k": "#2a2420",  # near black
	"v": "#8e5ac8",  # purple
}

## Plain glyphs in the text colour: (rows, top pixel above the baseline).
ARROWS = {
	0x25B2: (["..#..", ".###.", "#####"], 4),  # ▲
	0x25BC: (["#####", ".###.", "..#.."], 4),  # ▼
	0x25B6: (["#..", "##.", "###", "##.", "#.."], 5),  # ▶
}

ICONS = {
	0x1F37A: [  # 🍺 beer
		".wwwww...",
		"wwwwwww..",
		"syyyyys..",
		"syoyyysss",
		"syoyyys.s",
		"syoyyys.s",
		"syyyyysss",
		"syyyyys..",
		".sssss...",
	],
	0x1F37B: [  # 🍻 two beers
		".ww...ww.",
		"wwww.wwww",
		"syys.syys",
		"syysssyys",
		"syys.syys",
		"syysssyys",
		"syys.syys",
		"ssss.ssss",
		".........",
	],
	0x1F9FD: [  # 🧽 sponge
		".........",
		".GGGGGGG.",
		".ggggggg.",
		".yyyyyyy.",
		".yoyyyoy.",
		".yyyoyyy.",
		".yoyyyyy.",
		".yyyyoyy.",
		".........",
	],
	0x1F4E6: [  # 📦 box
		"..lllll..",
		".lllnlll.",
		"nnnnnnnnn",
		"nllllllln",
		"nlnnnnnln",
		"nllllllln",
		"nllllllln",
		"nllllllln",
		"nnnnnnnnn",
	],
	0x2B50: [  # ⭐ star
		"....y....",
		"....y....",
		"...yyy...",
		"yyyyyyyyy",
		".yyyyyyy.",
		"..yyyyy..",
		"..yy.yy..",
		".yy...yy.",
		".y.....y.",
	],
	0x1F31F: [  # 🌟 glowing star
		"....w....",
		"....y....",
		"...yyy...",
		"wyyywyyyw",
		".yyywyyy.",
		"..yyyyy..",
		"..yo.oy..",
		".yo...oy.",
		".o.....o.",
	],
	0x23F3: [  # ⏳ hourglass
		"nnnnnnnnn",
		".c.....c.",
		".cyyyyyc.",
		"..cyyyc..",
		"...cyc...",
		"..c.y.c..",
		".c..y..c.",
		".cyyyyyc.",
		"nnnnnnnnn",
	],
	0x23F1: [  # ⏱ stopwatch
		"...sss...",
		"....s....",
		"..sssss..",
		".swwwwws.",
		"swwwswwws",
		"swwwsswws",
		"swwwwwwws",
		".swwwwws.",
		"..sssss..",
	],
	0x1F512: [  # 🔒 locked
		"..sssss..",
		".ss...ss.",
		".s.....s.",
		".yyyyyyy.",
		".yyyNyyy.",
		".yyyNyyy.",
		".yyyyyyy.",
		".ooooooo.",
		".........",
	],
	0x1F513: [  # 🔓 open lock
		"....sssss",
		"...ss...s",
		"...s.....",
		".yyyyyyy.",
		".yyyNyyy.",
		".yyyNyyy.",
		".yyyyyyy.",
		".ooooooo.",
		".........",
	],
	0x1F6E2: [  # 🛢 drum
		".SSSSSSS.",
		".bbbbbbb.",
		".bcbbbbb.",
		".SSSSSSS.",
		".bcbbbbb.",
		".bbbbbbb.",
		".SSSSSSS.",
		".bcbbbbb.",
		".SSSSSSS.",
	],
	0x2744: [  # ❄ snowflake
		"....c....",
		".c..c..c.",
		"..c.c.c..",
		"...ccc...",
		"ccccwcccc",
		"...ccc...",
		"..c.c.c..",
		".c..c..c.",
		"....c....",
	],
	0x1F5C4: [  # 🗄 cabinet
		".SSSSSSS.",
		".SsssssS.",
		".SssSssS.",
		".SSSSSSS.",
		".SsssssS.",
		".SssSssS.",
		".SSSSSSS.",
		".SsssssS.",
		".SSSSSSS.",
	],
	0x1F377: [  # 🍷 wine
		"..ccccc..",
		"..c...c..",
		"..crrrc..",
		"..crrrc..",
		"...crc...",
		"....c....",
		"....c....",
		"....c....",
		"..ccccc..",
	],
	0x1F4B0: [  # 💰 money bag
		"...N.N...",
		"....N....",
		"...yyy...",
		"..yoooy..",
		".yyoyyyy.",
		".yyoooyy.",
		".yyyyoyy.",
		".yyoooyy.",
		"..yyyyy..",
	],
	0x1F4B6: [  # 💶 euro note
		".........",
		"ggggggggg",
		"gGgggggGg",
		"gggwwwggg",
		"ggwwgggGg",
		"gggwwwggg",
		"gGgggggGg",
		"ggggggggg",
		".........",
	],
	0x1FA99: [  # 🪙 coin
		"..ooooo..",
		".oyyyyyo.",
		"oywyyyyyo",
		"oywyyyyyo",
		"oyyyyyyyo",
		"oyyyyyyyo",
		"oyyyyyyyo",
		".oyyyyyo.",
		"..ooooo..",
	],
	0x1F3A9: [  # 🎩 top hat
		".........",
		"..SSSSS..",
		"..SSSSs..",
		"..SSSSs..",
		"..SSSSs..",
		"..rrrrr..",
		"..SSSSS..",
		"SSSSSSSSS",
		".........",
	],
	0x1F33E: [  # 🌾 wheat
		"....y....",
		"...y.y...",
		"....y....",
		"...y.y...",
		"....y....",
		"...y.y...",
		"....y....",
		"....l....",
		"....l....",
	],
	0x1F527: [  # 🔧 wrench
		"......s.s",
		"......sss",
		".....ss..",
		"....ss...",
		"...ss....",
		"..ss.....",
		"sss......",
		"s.s......",
		".........",
	],
	0x1F3AF: [  # 🎯 target
		"..rrrrr..",
		".rwwwwwr.",
		"rwrrrrrwr",
		"rwrwwwrwr",
		"rwrwrwrwr",
		"rwrwwwrwr",
		"rwrrrrrwr",
		".rwwwwwr.",
		"..rrrrr..",
	],
	0x1F91D: [  # 🤝 handshake
		".........",
		".........",
		"bb.....rr",
		"bbfff.lrr",
		"bffflllrr",
		".fflflll.",
		"..flflf..",
		"...fff...",
		".........",
	],
	0x1F3C5: [  # 🏅 medal
		".r.....b.",
		".rr...bb.",
		"..rr.bb..",
		"...rbb...",
		"...yyy...",
		"..yyyyy..",
		"..yyoyy..",
		"..yyyyy..",
		"...yyy...",
	],
	0x1F56F: [  # 🕯 candle
		"....o....",
		"...oyo...",
		"....y....",
		"....S....",
		"...www...",
		"...www...",
		"...www...",
		"...www...",
		"..sssss..",
	],
	0x1F3C6: [  # 🏆 trophy
		"yyyyyyyyy",
		"y.yyyyy.y",
		"y.yyyyy.y",
		".yyyyyyy.",
		"..yyyyy..",
		"...yyy...",
		"....y....",
		"...yyy...",
		"..nnnnn..",
	],
	0x1F9F1: [  # 🧱 bricks
		"sssssssss",
		"rrrrsrrrr",
		"rrrrsrrrr",
		"sssssssss",
		"rrsrrrrsr",
		"rrsrrrrsr",
		"sssssssss",
		"rrrrsrrrr",
		"rrrrsrrrr",
	],
	0x1F372: [  # 🍲 stew pot
		"..w...w..",
		"...w.w...",
		".........",
		"SoooooooS",
		".SSSSSSS.",
		"SSSSSSSSS",
		".SSSSSSS.",
		".SSSSSSS.",
		"..SSSSS..",
	],
	0x1FAE7: [  # 🫧 bubbles
		".ccc.....",
		"c..wc....",
		"c...c.cc.",
		".ccc.c.wc",
		".....c..c",
		"..cc..cc.",
		".c.wc....",
		".c..c....",
		"..cc.....",
	],
	0x2699: [  # ⚙ gear
		"...s.s...",
		".s.sss.s.",
		"..sssss..",
		"sss...sss",
		".ss...ss.",
		"sss...sss",
		"..sssss..",
		".s.sss.s.",
		"...s.s...",
	],
	0x1F4CC: [  # 📌 pin
		"..rrrrr..",
		"...rrr...",
		"...rrr...",
		".rrrrrrr.",
		"....s....",
		"....s....",
		"....s....",
		"....s....",
		".........",
	],
	0x1F6B2: [  # 🚲 bicycle
		".........",
		".........",
		"......nn.",
		"..rrrrr..",
		".r..r..r.",
		"SSS.r.SSS",
		"S.S.r.S.S",
		"SSS...SSS",
		".........",
	],
	0x1F48D: [  # 💍 ring
		"...ccc...",
		"....c....",
		"..yyyyy..",
		".y.....y.",
		"y.......y",
		"y.......y",
		".y.....y.",
		"..yyyyy..",
		".........",
	],
	0x1F408: [  # 🐈 cat
		".o...o...",
		".oo.oo...",
		".ooooo...",
		".okoko...",
		".ooooo..o",
		"..ooooo.o",
		"..ooooooo",
		"..o.o.o..",
		".........",
	],
	0x1F642: [  # 🙂 smile
		"..yyyyy..",
		".yyyyyyy.",
		"yyNyyyNyy",
		"yyNyyyNyy",
		"yyyyyyyyy",
		"yNyyyyyNy",
		"yyNNNNNyy",
		".yyyyyyy.",
		"..yyyyy..",
	],
	0x1F60F: [  # 😏 smirk
		"..yyyyy..",
		".yyyyyyy.",
		"yyNNyNNyy",
		"yyyyyyyyy",
		"yyyyyyyyy",
		"yyyyyyNyy",
		"yyyNNNyyy",
		".yyyyyyy.",
		"..yyyyy..",
	],
	0x1F92B: [  # 🤫 shush
		"..yyyyy..",
		".yyyyyyy.",
		"yyNyyyNyy",
		"yyyyyyyyy",
		"yyyylyyyy",
		"yyyNlNyyy",
		"yyyylyyyy",
		".yyylyyy.",
		"..yylyy..",
	],
	0x1F321: [  # 🌡 thermometer
		"....s....",
		"...sws...",
		"...sws...",
		"...srs...",
		"...srs...",
		"...srs...",
		"..srrrs..",
		"..srrrs..",
		"...sss...",
	],
	0x1F6AA: [  # 🚪 door
		".NNNNNNN.",
		".NnnnnnN.",
		".NnnnnnN.",
		".NnnnnnN.",
		".NnnnnyN.",
		".NnnnnnN.",
		".NnnnnnN.",
		".NnnnnnN.",
		".NNNNNNN.",
	],
	0x1F465: [  # 👥 people
		".........",
		".ss...bb.",
		".ss...bb.",
		".........",
		"ssss.bbbb",
		"ssss.bbbb",
		"ssss.bbbb",
		".........",
		".........",
	],
	0x1F46B: [  # 👫 couple
		".bb...pp.",
		".bb...pp.",
		".........",
		"bbbb.pppp",
		"bbbb.pppp",
		".bb...pp.",
		".bb..pppp",
		".b.b..pp.",
		".........",
	],
	0x267B: [  # ♻ recycle
		"....G....",
		"...g.g...",
		"..g...g..",
		"..g...g..",
		".g.....g.",
		".g.....g.",
		"G.......G",
		"ggggggggg",
		".........",
	],
	0x1F4E3: [  # 📣 megaphone
		".......r.",
		".....rrr.",
		"...rrrrr.",
		"wwrrrrrr.",
		"wwrrrrrr.",
		"...rrrrr.",
		"....s.rr.",
		"....s..r.",
		".........",
	],
	0x1F525: [  # 🔥 fire
		"....r....",
		"...rr....",
		"...ror.r.",
		"..rroorr.",
		".rrooorr.",
		".rooyoor.",
		".rooyyor.",
		"..oyyyo..",
		"...yyy...",
	],
	0x1F4D6: [  # 📖 open book
		".........",
		".www.www.",
		"wwwwnwwww",
		"wSSwnwSSw",
		"wwwwnwwww",
		"wSSwnwSSw",
		"wwwwnwwww",
		"nnnnnnnnn",
		".........",
	],
	0x1F4DC: [  # 📜 scroll
		".lllllll.",
		"lnlllllln",
		".lSSSSSl.",
		".lllllll.",
		".lSSSSl..",
		".lllllll.",
		".lSSSSSl.",
		"nlllllll.",
		".lllllll.",
	],
	0x1F573: [  # 🕳 hole
		".........",
		".........",
		".........",
		"..SSSSS..",
		".SkkkkkS.",
		"SkkkkkkkS",
		".SkkkkkS.",
		"..SSSSS..",
		".........",
	],
	0x1F441: [  # 👁 eye
		".........",
		".........",
		"..wwwww..",
		".wwbbbww.",
		"wwbbkbbww",
		".wwbbbww.",
		"..wwwww..",
		".........",
		".........",
	],
	0x1F3F7: [  # 🏷 tag
		".........",
		"...yyyyyy",
		"..yyyyyyy",
		".yyNyyyyy",
		"yyyyyyyyy",
		".yyyyyyyy",
		"..yyyyyyy",
		"...yyyyyy",
		".........",
	],
	0x1F39F: [  # 🎟 ticket
		".........",
		"ooooooooo",
		"oyyyyoyyo",
		".yyyy.yy.",
		".yyyyoyy.",
		"oyyyy.yyo",
		"oyyyyoyyo",
		"ooooooooo",
		".........",
	],
	0x1F451: [  # 👑 crown
		".........",
		"y...y...y",
		"yy.yry.yy",
		"yyyyyyyyy",
		"yryyryyry",
		"yyyyyyyyy",
		"ooooooooo",
		".........",
		".........",
	],
	0x1F49D: [  # 💝 heart with ribbon
		".pp.y.pp.",
		"ppppypppp",
		"ppppypppp",
		"yyyyyyyyy",
		".pppyppp.",
		"..ppypp..",
		"...pyp...",
		"....p....",
		".........",
	],
	0x1F3FA: [  # 🏺 amphora
		"..nnnnn..",
		"...nnn...",
		"n.nnnnn.n",
		"nnooooonn",
		".nnnnnnn.",
		".nooooon.",
		"..nnnnn..",
		"...nnn...",
		"....n....",
	],
	0x1F4FF: [  # 📿 beads
		"..r.r.r..",
		".r.....r.",
		"r.......r",
		".........",
		"r.......r",
		".r.....r.",
		"..r.r.r..",
		"....y....",
		"...yyy...",
	],
	0x1F3B6: [  # 🎶 notes
		"....yyyyy",
		"....yyyyy",
		"....y...y",
		"....y...y",
		"....y...y",
		"..yyy.yyy",
		".yyyyyyyy",
		".yyy.yyy.",
		".........",
	],
	0x1F3B3: [  # 🎳 bowling
		"..w......",
		".www.....",
		".www.....",
		"..r......",
		".www..SS.",
		".www.SSSS",
		"wwwwwSSSS",
		"wwwww.SS.",
		".www.....",
	],
	0x1F47B: [  # 👻 ghost
		"..wwwww..",
		".wwwwwww.",
		"wwSwwwSww",
		"wwSwwwSww",
		"wwwwwwwww",
		"wwwwwwwww",
		"wwwwwwwww",
		"ww.www.ww",
		"w...w...w",
	],
	0x1F319: [  # 🌙 crescent moon
		"..yyyy...",
		".yyy.....",
		"yyy......",
		"yyy......",
		"yyy......",
		"yyy......",
		"yyy......",
		".yyy.....",
		"..yyyy...",
	],
	0x1F6A2: [  # 🚢 ship
		"....s....",
		"...ws....",
		"..wws....",
		".wwws....",
		"....s....",
		"nnnnnnnnn",
		".nnnnnnn.",
		"..nnnnn..",
		"bbbbbbbbb",
	],
	0x1FAA3: [  # 🪣 bucket
		"..s...s..",
		".s.....s.",
		"SSSSSSSSS",
		".SsssssS.",
		".SsssssS.",
		"..SsssS..",
		"..SsssS..",
		"..SSSSS..",
		".........",
	],
	0x1F9EE: [  # 🧮 abacus
		"nnnnnnnnn",
		"nrrSSSSSn",
		"n.......n",
		"nSSbbSSSn",
		"n.......n",
		"nSSSSyyyn",
		"n.......n",
		"nnnnnnnnn",
		"n.......n",
	],
	0x1F6E1: [  # 🛡 shield
		"bbbbbbbbb",
		"bbbbybbbb",
		"bbbbybbbb",
		"byyyyyyyb",
		"bbbbybbbb",
		".bbbybbb.",
		"..bbybb..",
		"...bbb...",
		"....b....",
	],
	0x1F4C7: [  # 📇 card index
		"..wwwww..",
		".wwwwwww.",
		".wSSSSSw.",
		".wwwwwww.",
		".wSSSSw..",
		"nnnnnnnnn",
		"nnnnnnnnn",
		"n.......n",
		"nnnnnnnnn",
	],
	0x1F5FA: [  # 🗺 map
		"lllllllll",
		"llgglllbb",
		"lggggllbb",
		"lggglllbb",
		"llggllbbb",
		"llllllbbb",
		"llrlllbbb",
		"lllllllbb",
		"lllllllll",
	],
}

## Zero-width, so "⚙️" (with the emoji variation selector) stays in our font.
VARIATION_SELECTOR = 0xFE0F


def glyph_name(code : int) -> str:
	return "u%04X" % code


def draw_pixels(pixels, top : int):
	"""A glyph of one square per pixel, merged into runs along each row."""
	pen = TTGlyphPen(None)
	for y, row in enumerate(pixels):
		x = 0
		while x < len(row):
			if not row[x]:
				x += 1
				continue
			start = x
			while x < len(row) and row[x]:
				x += 1
			top_y = (top - y) * PIXEL
			# Clockwise from the top left, as TrueType wants outer contours.
			pen.moveTo((start * PIXEL, top_y))
			pen.lineTo((x * PIXEL, top_y))
			pen.lineTo((x * PIXEL, top_y - PIXEL))
			pen.lineTo((start * PIXEL, top_y - PIXEL))
			pen.closePath()
	return pen.glyph()


def mask(rows, keep) -> list:
	return [[keep(ch) for ch in row] for row in rows]


def check(code : int, rows) -> None:
	if len(rows) != 9 or any(len(row) != 9 for row in rows):
		raise SystemExit("U+%04X: the grid must be 9x9" % code)
	unknown = {ch for row in rows for ch in row if ch != "." and ch not in PALETTE}
	if unknown:
		raise SystemExit("U+%04X: no colour for %s" % (code, sorted(unknown)))


def build() -> None:
	colors = list(PALETTE)
	glyphs = {".notdef": TTGlyphPen(None).glyph()}
	advances = {".notdef": (ICON_ADVANCE * PIXEL, 0)}
	cmap = {}
	layers = {}

	for code, (rows, top) in ARROWS.items():
		name = glyph_name(code)
		glyphs[name] = draw_pixels(mask(rows, lambda ch: ch != "."), top - 1)
		advances[name] = ((len(rows[0]) + 1) * PIXEL, 0)
		cmap[code] = name

	for code, rows in ICONS.items():
		check(code, rows)
		name = glyph_name(code)
		# The base glyph is the whole silhouette, for anything that skips the colours.
		glyphs[name] = draw_pixels(mask(rows, lambda ch: ch != "."), ICON_TOP)
		advances[name] = (ICON_ADVANCE * PIXEL, 0)
		cmap[code] = name
		layers[name] = []
		for index, color in enumerate(colors):
			if not any(color in row for row in rows):
				continue
			layer = "%s.%s" % (name, "c%02d" % index)
			glyphs[layer] = draw_pixels(mask(rows, lambda ch, c=color: ch == c), ICON_TOP)
			advances[layer] = (ICON_ADVANCE * PIXEL, 0)
			layers[name].append((layer, index))

	selector = glyph_name(VARIATION_SELECTOR)
	glyphs[selector] = TTGlyphPen(None).glyph()
	advances[selector] = (0, 0)
	cmap[VARIATION_SELECTOR] = selector

	builder = FontBuilder(UNITS_PER_EM, isTTF=True)
	builder.setupGlyphOrder(list(glyphs))
	builder.setupCharacterMap(cmap)
	builder.setupGlyf(glyphs)
	builder.setupHorizontalMetrics(advances)
	builder.setupHorizontalHeader(ascent=ASCENT, descent=DESCENT)
	builder.setupNameTable({"familyName": "Pimea Icons", "styleName": "Regular"})
	builder.setupOS2(sTypoAscender=ASCENT, sTypoDescender=DESCENT, usWinAscent=ASCENT, usWinDescent=-DESCENT)
	builder.setupPost()
	builder.font["COLR"] = buildCOLR(layers)
	builder.font["CPAL"] = buildCPAL([[hex_to_rgba(PALETTE[c]) for c in colors]])

	os.makedirs(os.path.dirname(OUT), exist_ok=True)
	builder.save(OUT)
	print("%d icons and %d arrows -> %s" % (len(ICONS), len(ARROWS), os.path.relpath(OUT, ROOT)))


def hex_to_rgba(value : str) -> tuple:
	value = value.lstrip("#")
	return tuple(int(value[i:i + 2], 16) / 255.0 for i in (0, 2, 4)) + (1.0,)


if __name__ == "__main__":
	build()
