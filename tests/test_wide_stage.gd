@tool
extends McpTestSuite

## WideStage's centring maths and ScreenBleed's edge offsets for wide and tall screens.

const WideStageScript := preload("res://src/systems/toolkit/wide_stage.gd")
const ScreenBleedScript := preload("res://src/systems/toolkit/screen_bleed.gd")

const BASE : Vector2 = Vector2(640, 360)


func suite_name() -> String:
	return "wide_stage"


func test_stage_fills_a_16_by_9_screen() -> void:
	assert_eq(WideStageScript.origin_for(BASE, BASE), Vector2i.ZERO)
	assert_eq(WideStageScript.far_extra_for(BASE, BASE), Vector2i.ZERO)


func test_wide_phone_centres_the_stage() -> void:
	assert_eq(WideStageScript.origin_for(Vector2(800, 360), BASE), Vector2i(80, 0))
	assert_eq(WideStageScript.far_extra_for(Vector2(800, 360), BASE), Vector2i(80, 0))


func test_odd_extra_pixel_goes_right() -> void:
	assert_eq(WideStageScript.origin_for(Vector2(801, 360), BASE), Vector2i(80, 0))
	assert_eq(WideStageScript.far_extra_for(Vector2(801, 360), BASE), Vector2i(81, 0))


func test_tall_screen_centres_vertically() -> void:
	assert_eq(WideStageScript.origin_for(Vector2(640, 400), BASE), Vector2i(0, 20))


func test_mask_covers_both_sides_of_a_wide_screen() -> void:
	var rects : Array[Rect2] = WideStageScript.mask_rects_for(Rect2(Vector2(80, 0), BASE), Vector2(800, 360))
	assert_eq(rects[0], Rect2(0, 0, 80, 360))
	assert_eq(rects[1], Rect2(720, 0, 80, 360))
	assert_false(rects[2].has_area())
	assert_false(rects[3].has_area())


func test_bleed_moves_edge_anchors_out() -> void:
	# A full-width bar: left edge out by the left extra, right edge by the right extra.
	var bar : Vector4 = ScreenBleedScript.offsets_for(Vector4(0, 0, 1, 0.1), Vector2i(80, 0), Vector2i(81, 0))
	assert_eq(bar, Vector4(-80, 0, 81, 0))


func test_bleed_keeps_fractional_anchors() -> void:
	var middle : Vector4 = ScreenBleedScript.offsets_for(Vector4(0.3, 0.5, 0.7, 0.5), Vector2i(80, 20), Vector2i(80, 20))
	assert_eq(middle, Vector4.ZERO)


func test_a_top_bar_moves_up_whole_on_a_tall_screen() -> void:
	# Spans the width, pinned to the top with a fractional bottom anchor: it must stay a bar.
	var bar : Vector4 = ScreenBleedScript.offsets_for(Vector4(0, 0, 1, 0.1), Vector2i(0, 60), Vector2i(0, 60))
	assert_eq(bar, Vector4(0, -60, 0, -60))


func test_a_bottom_corner_button_goes_to_the_screen_corner() -> void:
	var cog : Vector4 = ScreenBleedScript.offsets_for(Vector4(0, 1, 0, 1), Vector2i(80, 20), Vector2i(81, 21))
	assert_eq(cog, Vector4(-80, 21, -80, 21))


func test_a_dimmer_covers_the_whole_screen() -> void:
	var dimmer : Vector4 = ScreenBleedScript.offsets_for(Vector4(0, 0, 1, 1), Vector2i(80, 20), Vector2i(81, 21))
	assert_eq(dimmer, Vector4(-80, -20, 81, 21))


func test_bleed_moves_a_right_pinned_panel_whole() -> void:
	var panel : Vector4 = ScreenBleedScript.offsets_for(Vector4(1, 0, 1, 0), Vector2i(80, 0), Vector2i(80, 0))
	assert_eq(panel, Vector4(80, 0, 80, 0))
