class_name CustomerPalette
extends RefCounted

## A customer's recolour regions (skin, hair, clothes, shoes), each a base colour, whether
## it recolours and its target colour, and the rules for which region claims a pixel.
## The shader (customer_recolor.gdshader) and CustomerPortrait both follow these rules.

const HAIR_SATURATION_RANGE : Vector2 = Vector2(0.55, 0.9)
const CLOTHES_SATURATION_RANGE : Vector2 = Vector2(0.55, 0.9)
const SHOES_SATURATION_RANGE : Vector2 = Vector2(0.4, 0.75)
const SKIN_HUE_RANGE : Vector2 = Vector2(0.03, 0.09)
const SKIN_SATURATION_RANGE : Vector2 = Vector2(0.35, 0.6)
const HUE_TOLERANCE : float = 0.05
const SATURATION_TOLERANCE : float = 0.35
const FRAME_HEIGHT : int = 32
const FEET_ROWS : int = 7
## Shoes share brown hues with hair, so they only claim within the feet rows, before hair.
const MATCH_ORDER : Array[String] = ["skin", "shoes", "hair", "clothes"]


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
	return {
		"skin": _region(data.skin_base_color, data.randomize_skin, _random_skin_tone(rng)),
		"hair": _region(data.hair_base_color, data.randomize_hair, _random_color(rng, HAIR_SATURATION_RANGE)),
		"clothes": _region(data.clothes_base_color, data.randomize_clothes, _random_color(rng, CLOTHES_SATURATION_RANGE)),
		"shoes": _region(data.shoes_base_color, data.randomize_shoes, _random_color(rng, SHOES_SATURATION_RANGE)),
	}


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


static func _region(base_color: Color, recolor: bool, random_color: Color) -> Dictionary:
	return {"base": base_color, "recolor": recolor, "target": random_color if recolor else base_color}


static func _hue_distance(a: float, b: float) -> float:
	var distance : float = absf(a - b)
	return minf(distance, 1.0 - distance)


# The recolour keeps each pixel's own value, so only hue and saturation are picked.
static func _random_color(rng: RandomNumberGenerator, saturation_range: Vector2) -> Color:
	return Color.from_hsv(rng.randf(), rng.randf_range(saturation_range.x, saturation_range.y), 1.0)


static func _random_skin_tone(rng: RandomNumberGenerator) -> Color:
	var hue : float = rng.randf_range(SKIN_HUE_RANGE.x, SKIN_HUE_RANGE.y)
	var saturation : float = rng.randf_range(SKIN_SATURATION_RANGE.x, SKIN_SATURATION_RANGE.y)
	return Color.from_hsv(hue, saturation, 1.0)
