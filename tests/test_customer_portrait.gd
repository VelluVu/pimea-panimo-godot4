@tool
extends McpTestSuite

## Unit tests for CustomerPortrait: the CPU recolour of a customer's still.

const PortraitScript := preload("res://src/customers/customer_portrait.gd")
const PaletteScript := preload("res://src/customers/customer_palette.gd")


func suite_name() -> String:
	return "customer_portrait"


func _fixed_palette() -> Dictionary:
	var data := CustomerData.new()
	data.randomize_skin = false
	data.randomize_hair = false
	data.randomize_clothes = false
	data.randomize_shoes = false
	return PaletteScript.regions(data, RandomNumberGenerator.new())


func test_recolor_keeps_the_pixel_value_and_skips_fixed_regions() -> void:
	var palette : Dictionary = _fixed_palette()
	palette["clothes"]["recolor"] = true
	palette["clothes"]["target"] = Color.from_hsv(0.33, 0.8, 1.0)
	var image : Image = Image.create(1, 32, false, Image.FORMAT_RGBA8)
	var clothes_pixel : Color = palette["clothes"]["base"]
	image.set_pixel(0, 0, clothes_pixel)
	image.set_pixel(0, 1, palette["skin"]["base"])
	var stored_skin : Color = image.get_pixel(0, 1)
	PortraitScript.recolor_image(image, palette)
	var recolored : Color = image.get_pixel(0, 0)
	assert_true(absf(recolored.h - 0.33) < 0.01, str(recolored.h))
	assert_true(absf(recolored.v - clothes_pixel.v) < 0.01, str(recolored.v))
	assert_eq(image.get_pixel(0, 1), stored_skin)


func test_portrait_is_the_same_every_time() -> void:
	var data : CustomerData = load("res://src/resources/customers/hipsteri.tres")
	var first : Image = PortraitScript.of(data, &"idle").get_image()
	var second : Image = PortraitScript.of(data, &"idle").get_image()
	assert_eq(first.get_data(), second.get_data())


func test_customer_without_the_animation_has_no_portrait() -> void:
	assert_eq(PortraitScript.of(CustomerData.new(), &"idle"), null)
