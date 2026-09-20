class_name CustomerRecolor
extends RefCounted

## Builds the palette-swap material for a customer's sprite: each body part's
## base color maps to a target color, which is either the archetype's own
## color or a random one when the CustomerData flags that part as randomized.

const SHADER : Shader = preload("res://assets/shaders/customer_recolor.gdshader")
const HAIR_SATURATION_RANGE : Vector2 = Vector2(0.55, 0.9)
const CLOTHES_SATURATION_RANGE : Vector2 = Vector2(0.55, 0.9)
const SHOES_SATURATION_RANGE : Vector2 = Vector2(0.4, 0.75)
const SKIN_HUE_RANGE : Vector2 = Vector2(0.03, 0.09)
const SKIN_SATURATION_RANGE : Vector2 = Vector2(0.35, 0.6)
const SKIN_VALUE_RANGE : Vector2 = Vector2(0.6, 0.95)


static func build_material(data: CustomerData) -> ShaderMaterial:
	var recolor_material : ShaderMaterial = ShaderMaterial.new()
	recolor_material.shader = SHADER
	recolor_material.set_shader_parameter("skin_base_color", data.skin_base_color)
	recolor_material.set_shader_parameter("hair_base_color", data.hair_base_color)
	recolor_material.set_shader_parameter("clothes_base_color", data.clothes_base_color)
	recolor_material.set_shader_parameter("shoes_base_color", data.shoes_base_color)
	recolor_material.set_shader_parameter("skin_target_color", _random_skin_tone() if data.randomize_skin else data.skin_base_color)
	recolor_material.set_shader_parameter("hair_target_color", _random_color_in_range(HAIR_SATURATION_RANGE, 0.9) if data.randomize_hair else data.hair_base_color)
	recolor_material.set_shader_parameter("clothes_target_color", _random_color_in_range(CLOTHES_SATURATION_RANGE, 0.85) if data.randomize_clothes else data.clothes_base_color)
	recolor_material.set_shader_parameter("shoes_target_color", _random_color_in_range(SHOES_SATURATION_RANGE, 0.6) if data.randomize_shoes else data.shoes_base_color)
	return recolor_material


static func _random_color_in_range(saturation_range: Vector2, value: float) -> Color:
	return Color.from_hsv(randf(), randf_range(saturation_range.x, saturation_range.y), value)


static func _random_skin_tone() -> Color:
	var hue : float = randf_range(SKIN_HUE_RANGE.x, SKIN_HUE_RANGE.y)
	var saturation : float = randf_range(SKIN_SATURATION_RANGE.x, SKIN_SATURATION_RANGE.y)
	var value : float = randf_range(SKIN_VALUE_RANGE.x, SKIN_VALUE_RANGE.y)
	return Color.from_hsv(hue, saturation, value)
