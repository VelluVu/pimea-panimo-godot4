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
	var rng := RandomNumberGenerator.new()
	for i : int in 20:
		var hue : float = RecolorScript._random_skin_tone(rng).h
		assert_true(hue >= RecolorScript.SKIN_HUE_RANGE.x - 0.001 and hue <= RecolorScript.SKIN_HUE_RANGE.y + 0.001, str(hue))


func _regions(recolor_all: bool) -> Dictionary:
	return RecolorScript.regions_for(_make_data(recolor_all), RandomNumberGenerator.new())


func test_shoes_claim_their_colour_only_in_the_feet_rows() -> void:
	var regions : Dictionary = _regions(true)
	var shoe_brown : Color = regions["shoes"]["base"]
	assert_eq(RecolorScript.claiming_region(shoe_brown, regions, true), "shoes")
	assert_eq(RecolorScript.claiming_region(shoe_brown, regions, false), "hair")


func test_skin_is_claimed_before_shoes() -> void:
	var regions : Dictionary = _regions(true)
	assert_eq(RecolorScript.claiming_region(regions["skin"]["base"], regions, true), "skin")


func test_recolor_keeps_the_pixel_value_and_skips_fixed_regions() -> void:
	var regions : Dictionary = _regions(false)
	regions["clothes"]["recolor"] = true
	regions["clothes"]["target"] = Color.from_hsv(0.33, 0.8, 1.0)
	var image : Image = Image.create(1, 32, false, Image.FORMAT_RGBA8)
	var clothes_pixel : Color = regions["clothes"]["base"]
	var skin_pixel : Color = regions["skin"]["base"]
	image.set_pixel(0, 0, clothes_pixel)
	image.set_pixel(0, 1, skin_pixel)
	var stored_skin : Color = image.get_pixel(0, 1)
	RecolorScript.recolor_image(image, regions)
	var recolored : Color = image.get_pixel(0, 0)
	assert_true(absf(recolored.h - 0.33) < 0.01, str(recolored.h))
	assert_true(absf(recolored.v - clothes_pixel.v) < 0.01, str(recolored.v))
	assert_eq(image.get_pixel(0, 1), stored_skin)


func test_portrait_is_the_same_every_time() -> void:
	var data : CustomerData = load("res://src/resources/customers/hipsteri.tres")
	var first : Image = RecolorScript.portrait(data, &"idle").get_image()
	var second : Image = RecolorScript.portrait(data, &"idle").get_image()
	assert_eq(first.get_data(), second.get_data())
