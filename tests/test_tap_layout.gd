@tool
extends McpTestSuite

## Unit tests for TapLayout: the tap tower's crossbar and handles.

const TapLayoutScript := preload("res://src/ui/tap_layout.gd")


func suite_name() -> String:
	return "tap_layout"


func test_an_empty_bar_still_shows_one_tap_and_the_count_is_capped() -> void:
	assert_eq(TapLayoutScript.tap_count(0), 1)
	assert_eq(TapLayoutScript.tap_count(4), 4)
	assert_eq(TapLayoutScript.tap_count(20), TapLayoutScript.MAX_TAPS)


func test_three_taps_match_the_old_sprite() -> void:
	# The old 48 px sprite had a 38 px crossbar with handles 12 px apart.
	assert_eq(TapLayoutScript.bar_width(3), 39)
	assert_eq(TapLayoutScript.handle_left(3, 1) - TapLayoutScript.handle_left(3, 0), 12.0)


func test_the_bar_is_centred_and_the_middle_tap_sits_on_the_centre() -> void:
	for taps : int in [1, 3, 5]:
		assert_eq(TapLayoutScript.spout_x(taps, taps / 2), 0.0)
	assert_eq(TapLayoutScript.bar_left(4), -TapLayoutScript.bar_width(4) / 2.0)


func test_the_tray_overhangs_the_bar() -> void:
	assert_eq(TapLayoutScript.tray_width(6), TapLayoutScript.bar_width(6) + 2 * TapLayoutScript.TRAY_OVERHANG)
