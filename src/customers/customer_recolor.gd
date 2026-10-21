class_name CustomerRecolor
extends RefCounted

## The palette-swap material for a customer's sprite: each body part's base colour maps to
## the archetype's own colour or, when flagged, a random one.

const SHADER : Shader = preload("res://assets/shaders/customer_recolor.gdshader")
const HAIR_SATURATION_RANGE : Vector2 = Vector2(0.55, 0.9)
const CLOTHES_SATURATION_RANGE : Vector2 = Vector2(0.55, 0.9)
const SHOES_SATURATION_RANGE : Vector2 = Vector2(0.4, 0.75)
const SKIN_HUE_RANGE : Vector2 = Vector2(0.03, 0.09)
const SKIN_SATURATION_RANGE : Vector2 = Vector2(0.35, 0.6)


static func build_material(data: CustomerData) -> ShaderMaterial:
	var recolor_material : ShaderMaterial = ShaderMaterial.new()
	recolor_material.shader = SHADER
	_set_region(recolor_material, "skin", data.skin_base_color, data.randomize_skin, _random_skin_tone)
	_set_region(recolor_material, "hair", data.hair_base_color, data.randomize_hair, _random_color.bind(HAIR_SATURATION_RANGE))
	_set_region(recolor_material, "clothes", data.clothes_base_color, data.randomize_clothes, _random_color.bind(CLOTHES_SATURATION_RANGE))
	_set_region(recolor_material, "shoes", data.shoes_base_color, data.randomize_shoes, _random_color.bind(SHOES_SATURATION_RANGE))
	return recolor_material


## A region left as painted still gets its base colour: the shader uses it to claim
## the region's pixels so a later, randomized region can't take them.
static func _set_region(recolor_material: ShaderMaterial, region: String, base_color: Color, recolor: bool, pick_color: Callable) -> void:
	recolor_material.set_shader_parameter(region + "_base_color", base_color)
	recolor_material.set_shader_parameter(region + "_recolor", recolor)
	recolor_material.set_shader_parameter(region + "_target_color", pick_color.call() if recolor else base_color)


# The shader keeps each pixel's own value, so only hue and saturation are picked.
static func _random_color(saturation_range: Vector2) -> Color:
	return Color.from_hsv(randf(), randf_range(saturation_range.x, saturation_range.y), 1.0)


static func _random_skin_tone() -> Color:
	var hue : float = randf_range(SKIN_HUE_RANGE.x, SKIN_HUE_RANGE.y)
	var saturation : float = randf_range(SKIN_SATURATION_RANGE.x, SKIN_SATURATION_RANGE.y)
	return Color.from_hsv(hue, saturation, 1.0)
