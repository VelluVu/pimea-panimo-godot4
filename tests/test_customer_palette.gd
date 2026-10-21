@tool
extends McpTestSuite

## Unit tests for CustomerPalette: region targets and which region claims a pixel.

const PaletteScript := preload("res://src/customers/customer_palette.gd")


func suite_name() -> String:
	return "customer_palette"


func _regions() -> Dictionary:
	return PaletteScript.regions(CustomerData.new(), RandomNumberGenerator.new())


func test_fixed_region_targets_its_own_base() -> void:
	var data := CustomerData.new()
	data.randomize_clothes = false
	var palette : Dictionary = PaletteScript.random(data)
	assert_false(palette["clothes"]["recolor"])
	assert_eq(palette["clothes"]["target"], data.clothes_base_color)


func test_seeded_palette_is_the_same_every_time() -> void:
	var data := CustomerData.new()
	data.title = "Hipsteri"
	assert_eq(PaletteScript.seeded(data)["hair"]["target"], PaletteScript.seeded(data)["hair"]["target"])


func test_random_skin_tone_stays_in_its_hue_band() -> void:
	var rng := RandomNumberGenerator.new()
	for i : int in 20:
		var hue : float = PaletteScript._random_skin_tone(rng).h
		assert_true(hue >= PaletteScript.SKIN_HUE_RANGE.x - 0.001 and hue <= PaletteScript.SKIN_HUE_RANGE.y + 0.001, str(hue))


func test_feet_rows_are_the_bottom_of_each_frame() -> void:
	assert_false(PaletteScript.is_feet_row(24))
	assert_true(PaletteScript.is_feet_row(25))
	assert_true(PaletteScript.is_feet_row(31))
	assert_false(PaletteScript.is_feet_row(32))


func test_shoes_claim_their_colour_only_in_the_feet_rows() -> void:
	var palette : Dictionary = _regions()
	var shoe_brown : Color = palette["shoes"]["base"]
	assert_eq(PaletteScript.claiming_region(shoe_brown, palette, true), "shoes")
	assert_eq(PaletteScript.claiming_region(shoe_brown, palette, false), "hair")


func test_skin_is_claimed_before_shoes() -> void:
	var palette : Dictionary = _regions()
	assert_eq(PaletteScript.claiming_region(palette["skin"]["base"], palette, true), "skin")
