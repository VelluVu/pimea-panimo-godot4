@tool
extends McpTestSuite

## Unit tests for CustomerRecolor: which shader regions are switched on.

const RecolorScript := preload("res://src/customers/customer_recolor.gd")


func suite_name() -> String:
	return "customer_recolor"


func _make_data(randomize_all: bool) -> CustomerData:
	var data := CustomerData.new()
	data.randomize_skin = randomize_all
	data.randomize_hair = randomize_all
	data.randomize_clothes = randomize_all
	data.randomize_shoes = randomize_all
	return data


func test_fixed_regions_are_switched_off_but_keep_their_base() -> void:
	var data : CustomerData = _make_data(false)
	data.clothes_base_color = Color("#3e345c")
	var material : ShaderMaterial = RecolorScript.build_material(data)
	for region : String in ["skin", "hair", "clothes", "shoes"]:
		assert_false(material.get_shader_parameter(region + "_recolor"), region)
	assert_eq(material.get_shader_parameter("clothes_base_color"), Color("#3e345c"))


func test_randomized_region_is_switched_on() -> void:
	var data : CustomerData = _make_data(false)
	data.randomize_hair = true
	var material : ShaderMaterial = RecolorScript.build_material(data)
	assert_true(material.get_shader_parameter("hair_recolor"))
	assert_false(material.get_shader_parameter("clothes_recolor"))


func test_random_skin_tone_stays_in_its_hue_band() -> void:
	for i : int in 20:
		var hue : float = RecolorScript._random_skin_tone().h
		assert_true(hue >= RecolorScript.SKIN_HUE_RANGE.x - 0.001 and hue <= RecolorScript.SKIN_HUE_RANGE.y + 0.001, str(hue))
