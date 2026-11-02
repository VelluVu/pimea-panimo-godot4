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


func test_the_base_colour_becomes_the_target_at_its_own_brightness() -> void:
	var base := Color("#ead4aa")
	var target := Color.from_hsv(0.07, 0.3, 1.0)
	var result : Color = PaletteScript.recolored(base, base, target)
	assert_true(is_equal_approx(result.h, target.h), str(result.h))
	assert_true(is_equal_approx(result.s, target.s), str(result.s))
	assert_true(is_equal_approx(result.v, base.v), str(result.v))


func test_a_shadow_painted_by_saturation_stays_apart_from_the_base() -> void:
	var base := Color("#ead4aa")
	var shadow := Color("#e4a672")
	var target := Color.from_hsv(0.07, 0.3, 1.0)
	var lit : Color = PaletteScript.recolored(base, base, target)
	var shaded : Color = PaletteScript.recolored(shadow, base, target)
	assert_true(shaded.s - lit.s > 0.2, "%f vs %f" % [shaded.s, lit.s])
	assert_true(shaded.h < lit.h, "the warmer shadow keeps its hue shift")


func test_hue_offset_wraps_around_red() -> void:
	var base := Color.from_hsv(0.98, 0.5, 0.5)
	var pixel := Color.from_hsv(0.02, 0.5, 0.5)
	var result : Color = PaletteScript.recolored(pixel, base, Color.from_hsv(0.5, 0.5, 1.0))
	assert_true(absf(result.h - 0.54) < 0.001, str(result.h))


func test_saturation_stays_in_range() -> void:
	var base := Color.from_hsv(0.6, 0.3, 0.8)
	var vivid := Color.from_hsv(0.6, 0.6, 0.8)
	assert_true(PaletteScript.recolored(vivid, base, Color.from_hsv(0.1, 0.9, 1.0)).s <= 1.0)
	var pale := Color.from_hsv(0.6, 0.05, 0.8)
	assert_true(PaletteScript.recolored(pale, base, Color.from_hsv(0.1, 0.1, 1.0)).s >= 0.0)
