class_name BeerColor
extends RefCounted

## A beer's colour from its EBC, in flat Endesga 32 steps rather than a blend so the
## pixel art keeps its palette. Also repaints the liquid of a glass texture and of the
## bartender's pour.

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
## The falling stream in the bartender's pour frames, drawn a shade lighter than the liquid.
const POUR_STREAM_COLOR : Color = Color("#ffd485")

## Repainted glass textures by source texture and colour, so each sale reuses one.
static var _glass_cache : Dictionary = {}
## Repainted SpriteFrames by source frames and colour.
static var _frames_cache : Dictionary = {}


static func from_ebc(ebc : int) -> Color:
	for i : int in BAND_MAX_EBC.size():
		if ebc <= BAND_MAX_EBC[i]:
			return BAND_COLORS[i]
	return DARKEST_COLOR


## One band lighter than the liquid, so the stream stays visible against it.
static func stream_from_ebc(ebc : int) -> Color:
	for i : int in BAND_MAX_EBC.size():
		if ebc <= BAND_MAX_EBC[i]:
			return POUR_STREAM_COLOR if i == 0 else BAND_COLORS[i - 1]
	return BAND_COLORS[-1]


## `glass` with every GLASS_LIQUID_COLOR pixel painted `color`.
static func repaint_liquid(glass : Image, color : Color) -> Image:
	return _repaint(glass, {GLASS_LIQUID_COLOR: color})


## `sheet` with the liquid and the pour stream coloured for `ebc`.
static func repaint_pour(sheet : Image, ebc : int) -> Image:
	return _repaint(sheet, {GLASS_LIQUID_COLOR: from_ebc(ebc), POUR_STREAM_COLOR: stream_from_ebc(ebc)})


static func glass_texture(glass : Texture2D, ebc : int) -> Texture2D:
	var color : Color = from_ebc(ebc)
	var key : String = "%s|%s" % [glass.resource_path, color.to_html()]
	if not _glass_cache.has(key):
		_glass_cache[key] = ImageTexture.create_from_image(repaint_liquid(glass.get_image(), color))
	return _glass_cache[key]


## A copy of `frames` whose atlas frames show the pour in the colour of `ebc`.
static func pour_sprite_frames(frames : SpriteFrames, ebc : int) -> SpriteFrames:
	var key : String = "%s|%s" % [frames.resource_path, from_ebc(ebc).to_html()]
	if _frames_cache.has(key):
		return _frames_cache[key]
	var painted_sheets : Dictionary = {}
	var painted := SpriteFrames.new()
	painted.remove_animation(&"default")
	for animation : StringName in frames.get_animation_names():
		painted.add_animation(animation)
		painted.set_animation_speed(animation, frames.get_animation_speed(animation))
		painted.set_animation_loop(animation, frames.get_animation_loop(animation))
		for i : int in frames.get_frame_count(animation):
			var texture : Texture2D = frames.get_frame_texture(animation, i)
			if texture is AtlasTexture:
				var sheet : Texture2D = texture.atlas
				if not painted_sheets.has(sheet):
					painted_sheets[sheet] = ImageTexture.create_from_image(repaint_pour(sheet.get_image(), ebc))
				var frame := AtlasTexture.new()
				frame.atlas = painted_sheets[sheet]
				frame.region = texture.region
				texture = frame
			painted.add_frame(animation, texture, frames.get_frame_duration(animation, i))
	_frames_cache[key] = painted
	return painted


static func _repaint(source : Image, colors : Dictionary) -> Image:
	var painted : Image = source.duplicate()
	for y : int in painted.get_height():
		for x : int in painted.get_width():
			var pixel : Color = painted.get_pixel(x, y)
			for from : Color in colors:
				if pixel.is_equal_approx(from):
					painted.set_pixel(x, y, colors[from])
					break
	return painted
