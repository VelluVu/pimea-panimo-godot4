class_name BeerColor
extends RefCounted

## A beer's colour from its EBC, in flat Endesga 32 steps rather than a blend so the
## pixel art keeps its palette. Also repaints the liquid of a glass texture.

## Upper EBC bound of each band, paired with BAND_COLORS; darker past the last one.
const BAND_MAX_EBC : Array[int] = [8, 16, 26, 40, 60, 90]
const BAND_COLORS : Array[Color] = [
	Color("#fee761"), # pale straw
	Color("#feae34"), # gold
	Color("#f77622"), # amber
	Color("#be4a2f"), # copper
	Color("#733e39"), # brown
	Color("#3e2731"), # dark brown
]
const DARKEST_COLOR : Color = Color("#181425")
## The liquid colour drawn into beer_glass_8.png.
const GLASS_LIQUID_COLOR : Color = Color("#e7c17c")

## Repainted glass textures by source texture and colour, so each sale reuses one.
static var _glass_cache : Dictionary = {}


static func from_ebc(ebc : int) -> Color:
	for i : int in BAND_MAX_EBC.size():
		if ebc <= BAND_MAX_EBC[i]:
			return BAND_COLORS[i]
	return DARKEST_COLOR


## `glass` with every GLASS_LIQUID_COLOR pixel painted `color`.
static func repaint_liquid(glass : Image, color : Color) -> Image:
	var painted : Image = glass.duplicate()
	for y : int in painted.get_height():
		for x : int in painted.get_width():
			if painted.get_pixel(x, y).is_equal_approx(GLASS_LIQUID_COLOR):
				painted.set_pixel(x, y, color)
	return painted


static func glass_texture(glass : Texture2D, ebc : int) -> Texture2D:
	var color : Color = from_ebc(ebc)
	var key : String = "%s|%s" % [glass.resource_path, color.to_html()]
	if not _glass_cache.has(key):
		_glass_cache[key] = ImageTexture.create_from_image(repaint_liquid(glass.get_image(), color))
	return _glass_cache[key]
