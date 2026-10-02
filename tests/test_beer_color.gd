@tool
extends McpTestSuite

## Unit tests for BeerColor: EBC bands and repainting a glass's liquid.

const ColorScript := preload("res://src/brewing/beer_color.gd")


func suite_name() -> String:
	return "beer_color"


func test_pale_beer_is_straw() -> void:
	assert_eq(ColorScript.from_ebc(4), Color("#fee761"))


func test_band_edges_belong_to_the_lighter_band() -> void:
	assert_eq(ColorScript.from_ebc(8), Color("#fee761"))
	assert_eq(ColorScript.from_ebc(9), Color("#feae34"))


func test_stout_is_darkest() -> void:
	assert_eq(ColorScript.from_ebc(120), ColorScript.DARKEST_COLOR)


func test_darker_ebc_never_gets_lighter() -> void:
	var previous : float = 2.0
	for ebc : int in range(0, 150, 5):
		var luminance : float = ColorScript.from_ebc(ebc).get_luminance()
		assert_true(luminance <= previous, "EBC %d got lighter" % ebc)
		previous = luminance


func test_repaint_changes_only_liquid_pixels() -> void:
	var glass := Image.create(2, 1, false, Image.FORMAT_RGBA8)
	glass.set_pixel(0, 0, ColorScript.GLASS_LIQUID_COLOR)
	glass.set_pixel(1, 0, Color.WHITE)
	var painted : Image = ColorScript.repaint_liquid(glass, Color("#3e2731"))
	assert_true(painted.get_pixel(0, 0).is_equal_approx(Color("#3e2731")))
	assert_eq(painted.get_pixel(1, 0), Color.WHITE)
	assert_true(glass.get_pixel(0, 0).is_equal_approx(ColorScript.GLASS_LIQUID_COLOR), "source image untouched")
