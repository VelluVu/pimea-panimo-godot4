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


func test_stream_is_one_band_lighter() -> void:
	assert_eq(ColorScript.stream_from_ebc(30), ColorScript.from_ebc(20))
	assert_eq(ColorScript.stream_from_ebc(120), ColorScript.BAND_COLORS[-1])


func test_palest_stream_stays_as_drawn() -> void:
	assert_eq(ColorScript.stream_from_ebc(4), ColorScript.POUR_STREAM_COLOR)


func test_repaint_pour_colours_liquid_and_stream() -> void:
	var sheet := Image.create(3, 1, false, Image.FORMAT_RGBA8)
	sheet.set_pixel(0, 0, ColorScript.GLASS_LIQUID_COLOR)
	sheet.set_pixel(1, 0, ColorScript.POUR_STREAM_COLOR)
	sheet.set_pixel(2, 0, Color.WHITE)
	var painted : Image = ColorScript.repaint_pour(sheet, 120)
	assert_true(painted.get_pixel(0, 0).is_equal_approx(ColorScript.DARKEST_COLOR))
	assert_true(painted.get_pixel(1, 0).is_equal_approx(ColorScript.BAND_COLORS[-1]))
	assert_eq(painted.get_pixel(2, 0), Color.WHITE)


func test_pour_sprite_frames_keep_animations_and_regions() -> void:
	var sheet := Image.create(4, 2, false, Image.FORMAT_RGBA8)
	sheet.fill(ColorScript.GLASS_LIQUID_COLOR)
	var frame := AtlasTexture.new()
	frame.atlas = ImageTexture.create_from_image(sheet)
	frame.region = Rect2(2, 0, 2, 2)
	var frames := SpriteFrames.new()
	frames.add_animation(&"serve_beer")
	frames.set_animation_speed(&"serve_beer", 7.0)
	frames.set_animation_loop(&"serve_beer", false)
	frames.add_frame(&"serve_beer", frame)
	var painted : SpriteFrames = ColorScript.pour_sprite_frames(frames, 120)
	assert_eq(painted.get_animation_names(), frames.get_animation_names())
	assert_eq(painted.get_animation_speed(&"serve_beer"), 7.0)
	assert_false(painted.get_animation_loop(&"serve_beer"))
	var painted_frame : AtlasTexture = painted.get_frame_texture(&"serve_beer", 0)
	assert_eq(painted_frame.region, frame.region)
	assert_true(painted_frame.atlas.get_image().get_pixel(3, 1).is_equal_approx(ColorScript.DARKEST_COLOR))
