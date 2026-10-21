class_name CustomerRecolor
extends RefCounted

## The palette-swap for a customer's sprite: each body part's base colour maps to the
## archetype's own colour or, when flagged, a random one. Live sprites use the shader;
## portraits are baked on the CPU by `portrait()`, which follows the same rules.

const SHADER : Shader = preload("res://assets/shaders/customer_recolor.gdshader")
const HAIR_SATURATION_RANGE : Vector2 = Vector2(0.55, 0.9)
const CLOTHES_SATURATION_RANGE : Vector2 = Vector2(0.55, 0.9)
const SHOES_SATURATION_RANGE : Vector2 = Vector2(0.4, 0.75)
const SKIN_HUE_RANGE : Vector2 = Vector2(0.03, 0.09)
const SKIN_SATURATION_RANGE : Vector2 = Vector2(0.35, 0.6)
const HUE_TOLERANCE : float = 0.05
const SATURATION_TOLERANCE : float = 0.35
const FRAME_HEIGHT : int = 32
const FEET_ROWS : int = 7
## The order the shader claims pixels in; shoes only within the feet rows.
const MATCH_ORDER : Array[String] = ["skin", "shoes", "hair", "clothes"]


static func build_material(data: CustomerData) -> ShaderMaterial:
	var recolor_material : ShaderMaterial = ShaderMaterial.new()
	recolor_material.shader = SHADER
	recolor_material.set_shader_parameter("hue_tolerance", HUE_TOLERANCE)
	recolor_material.set_shader_parameter("saturation_tolerance", SATURATION_TOLERANCE)
	recolor_material.set_shader_parameter("frame_height", float(FRAME_HEIGHT))
	recolor_material.set_shader_parameter("feet_rows", float(FEET_ROWS))
	var regions : Dictionary = regions_for(data, _randomized_rng())
	for region : String in regions:
		# A region left as painted still gets its base colour: the shader uses it to claim
		# the region's pixels so a later, randomized region can't take them.
		recolor_material.set_shader_parameter(region + "_base_color", regions[region]["base"])
		recolor_material.set_shader_parameter(region + "_recolor", regions[region]["recolor"])
		recolor_material.set_shader_parameter(region + "_target_color", regions[region]["target"])
	return recolor_material


## The first frame of `animation`, recoloured with colours seeded by the title, so the
## customer book and unlock cards always show a customer the same way.
static func portrait(data: CustomerData, animation: StringName) -> Texture2D:
	if data.sprite_frames == null or not data.sprite_frames.has_animation(animation):
		return null
	var image : Image = data.sprite_frames.get_frame_texture(animation, 0).get_image()
	if image == null:
		return null
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(data.title)
	recolor_image(image, regions_for(data, rng))
	return ImageTexture.create_from_image(image)


## Region name -> {base, recolor, target}, the targets picked with `rng`.
static func regions_for(data: CustomerData, rng: RandomNumberGenerator) -> Dictionary:
	return {
		"skin": _region(data.skin_base_color, data.randomize_skin, _random_skin_tone(rng)),
		"hair": _region(data.hair_base_color, data.randomize_hair, _random_color(rng, HAIR_SATURATION_RANGE)),
		"clothes": _region(data.clothes_base_color, data.randomize_clothes, _random_color(rng, CLOTHES_SATURATION_RANGE)),
		"shoes": _region(data.shoes_base_color, data.randomize_shoes, _random_color(rng, SHOES_SATURATION_RANGE)),
	}


## The shader's fragment() on an image whose frames are FRAME_HEIGHT tall.
static func recolor_image(image: Image, regions: Dictionary) -> void:
	if image.is_compressed():
		image.decompress()
	for y : int in image.get_height():
		var in_feet : bool = y % FRAME_HEIGHT >= FRAME_HEIGHT - FEET_ROWS
		for x : int in image.get_width():
			var pixel : Color = image.get_pixel(x, y)
			if pixel.a == 0.0:
				continue
			var region : String = claiming_region(pixel, regions, in_feet)
			if region != "" and regions[region]["recolor"]:
				var target : Color = regions[region]["target"]
				image.set_pixel(x, y, Color.from_hsv(target.h, target.s, pixel.v, pixel.a))


## The region whose base colour claims `pixel`, or "" when none does.
static func claiming_region(pixel: Color, regions: Dictionary, in_feet: bool) -> String:
	for region : String in MATCH_ORDER:
		if region == "shoes" and not in_feet:
			continue
		var base : Color = regions[region]["base"]
		if _hue_distance(pixel.h, base.h) < HUE_TOLERANCE and absf(pixel.s - base.s) < SATURATION_TOLERANCE:
			return region
	return ""


static func _region(base_color: Color, recolor: bool, random_color: Color) -> Dictionary:
	return {"base": base_color, "recolor": recolor, "target": random_color if recolor else base_color}


static func _hue_distance(a: float, b: float) -> float:
	var distance : float = absf(a - b)
	return minf(distance, 1.0 - distance)


static func _randomized_rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return rng


# The shader keeps each pixel's own value, so only hue and saturation are picked.
static func _random_color(rng: RandomNumberGenerator, saturation_range: Vector2) -> Color:
	return Color.from_hsv(rng.randf(), rng.randf_range(saturation_range.x, saturation_range.y), 1.0)


static func _random_skin_tone(rng: RandomNumberGenerator) -> Color:
	var hue : float = rng.randf_range(SKIN_HUE_RANGE.x, SKIN_HUE_RANGE.y)
	var saturation : float = rng.randf_range(SKIN_SATURATION_RANGE.x, SKIN_SATURATION_RANGE.y)
	return Color.from_hsv(hue, saturation, 1.0)
