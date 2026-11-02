class_name CustomerPalette
extends RefCounted

## A customer's recolour regions (skin, hair, clothes, shoes), each a base colour, whether
## it recolours and its target colour, and the rules for which region claims a pixel.
## The shader (customer_recolor.gdshader) and CustomerPortrait both follow these rules.

const HAIR_SATURATION_RANGE : Vector2 = Vector2(0.55, 0.9)
const CLOTHES_SATURATION_RANGE : Vector2 = Vector2(0.55, 0.9)
const SHOES_SATURATION_RANGE : Vector2 = Vector2(0.4, 0.75)
## The recolour keeps the painted brightness, so saturation above ~0.45 turns light skin orange.
const SKIN_HUE_RANGE : Vector2 = Vector2(0.055, 0.085)
const SKIN_SATURATION_RANGE : Vector2 = Vector2(0.2, 0.42)
const HUE_TOLERANCE : float = 0.05
const SATURATION_TOLERANCE : float = 0.35
const FRAME_HEIGHT : int = 32
const FEET_ROWS : int = 7
## Shoes share brown hues with hair, so they only claim within the feet rows, before hair.
const MATCH_ORDER : Array[String] = ["skin", "shoes", "hair", "clothes"]
## A random hue this close to the skin or another part is drawn again, so a jacket never
## melts into the hair beside it or an orange shirt into the skin.
const MIN_HUE_SEPARATION : float = 0.1
## Below this saturation or value a colour reads as grey, white or black, and its hue
## clashes with none.
const GREY_SATURATION : float = 0.2
const BLACK_VALUE : float = 0.25
const HUE_DRAWS : int = 8


## Fresh random targets, for a customer walking in.
static func random(data: CustomerData) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return regions(data, rng)


## Targets seeded by the title, so a customer always looks the same.
static func seeded(data: CustomerData) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(data.title)
	return regions(data, rng)


## Region name -> {base, recolor, target}, the targets picked with `rng`.
static func regions(data: CustomerData, rng: RandomNumberGenerator) -> Dictionary:
	var palette : Dictionary = {
		"skin": _region(data.skin_base_color, data.randomize_skin, _random_skin_tone(rng)),
	}
	var bases : Dictionary = {"hair": data.hair_base_color, "clothes": data.clothes_base_color, "shoes": data.shoes_base_color}
	var randomized : Dictionary = {"hair": data.randomize_hair, "clothes": data.randomize_clothes, "shoes": data.randomize_shoes}
	var saturations : Dictionary = {"hair": HAIR_SATURATION_RANGE, "clothes": CLOTHES_SATURATION_RANGE, "shoes": SHOES_SATURATION_RANGE}
	# The fixed parts are known up front, so every random one keeps clear of them.
	var shown : Array[Color] = [palette["skin"]["target"]]
	for region : String in bases:
		if not randomized[region]:
			shown.append(bases[region])
	for region : String in bases:
		var color : Color = _separated_color(rng, saturations[region], shown)
		palette[region] = _region(bases[region], randomized[region], color)
		if randomized[region]:
			shown.append(color)
	return palette


## Whether `color`'s hue keeps MIN_HUE_SEPARATION from every coloured one in `others`.
static func is_hue_separated(color: Color, others: Array[Color]) -> bool:
	if not _has_hue(color):
		return true
	for other : Color in others:
		if _has_hue(other) and _hue_distance(color.h, other.h) < MIN_HUE_SEPARATION:
			return false
	return true


static func _has_hue(color: Color) -> bool:
	return color.s >= GREY_SATURATION and color.v >= BLACK_VALUE


static func is_feet_row(y: int) -> bool:
	return y % FRAME_HEIGHT >= FRAME_HEIGHT - FEET_ROWS


## The region whose base colour claims `pixel`, or "" when none does.
static func claiming_region(pixel: Color, palette: Dictionary, in_feet: bool) -> String:
	for region : String in MATCH_ORDER:
		if region == "shoes" and not in_feet:
			continue
		var base : Color = palette[region]["base"]
		if _hue_distance(pixel.h, base.h) < HUE_TOLERANCE and absf(pixel.s - base.s) < SATURATION_TOLERANCE:
			return region
	return ""


## `pixel` of a region painted around `base`, moved to `target`. The pixel keeps its own
## brightness and its hue and saturation offsets from the base: a shade that differs from
## the base only in hue or saturation (a warm skin shadow, a blush) would vanish otherwise.
static func recolored(pixel: Color, base: Color, target: Color) -> Color:
	var hue_offset : float = pixel.h - base.h
	hue_offset -= roundf(hue_offset)
	var saturation : float = clampf(target.s + pixel.s - base.s, 0.0, 1.0)
	return Color.from_hsv(fposmod(target.h + hue_offset, 1.0), saturation, pixel.v, pixel.a)


static func _region(base_color: Color, recolor: bool, random_color: Color) -> Dictionary:
	return {"base": base_color, "recolor": recolor, "target": random_color if recolor else base_color}


static func _hue_distance(a: float, b: float) -> float:
	var distance : float = absf(a - b)
	return minf(distance, 1.0 - distance)


# The recolour keeps each pixel's own value, so only hue and saturation are picked.
static func _random_color(rng: RandomNumberGenerator, saturation_range: Vector2) -> Color:
	return Color.from_hsv(rng.randf(), rng.randf_range(saturation_range.x, saturation_range.y), 1.0)


## A random colour clear of `shown` in hue; after HUE_DRAWS tries the last draw stands.
static func _separated_color(rng: RandomNumberGenerator, saturation_range: Vector2, shown: Array[Color]) -> Color:
	var color : Color = _random_color(rng, saturation_range)
	for draw : int in HUE_DRAWS - 1:
		if is_hue_separated(color, shown):
			break
		color = _random_color(rng, saturation_range)
	return color


static func _random_skin_tone(rng: RandomNumberGenerator) -> Color:
	var hue : float = rng.randf_range(SKIN_HUE_RANGE.x, SKIN_HUE_RANGE.y)
	var saturation : float = rng.randf_range(SKIN_SATURATION_RANGE.x, SKIN_SATURATION_RANGE.y)
	return Color.from_hsv(hue, saturation, 1.0)
