@tool
extends McpTestSuite

## Unit tests for TapLayout: the tap tower's crossbar and handles.

const TapLayoutScript := preload("res://src/ui/tap_layout.gd")


func suite_name() -> String:
	return "tap_layout"


func test_a_tap_per_keg_with_at_least_one_and_at_most_the_cap() -> void:
	assert_eq(TapLayoutScript.tap_count(0), 1)
	assert_eq(TapLayoutScript.tap_count(4), 4)
	assert_eq(TapLayoutScript.tap_count(20), TapLayoutScript.MAX_TAPS)


func test_many_taps_tighten_instead_of_overflowing_the_counter() -> void:
	assert_eq(TapLayoutScript.pitch(6), TapLayoutScript.HANDLE_PITCH)
	assert_true(TapLayoutScript.pitch(12) < TapLayoutScript.HANDLE_PITCH)
	assert_true(TapLayoutScript.bar_width(12) <= TapLayoutScript.MAX_BAR_WIDTH)
	assert_eq(TapLayoutScript.pitch(12), 8, "twelve taps keep a 3 px gap")


func test_three_taps_match_the_old_sprite() -> void:
	# The old 48 px sprite had a 38 px crossbar with handles 12 px apart.
	assert_eq(TapLayoutScript.bar_width(3), 39)
	assert_eq(TapLayoutScript.handle_left(3, 1) - TapLayoutScript.handle_left(3, 0), 12.0)
	assert_eq(TapLayoutScript.bar_width(6), 75)


func test_the_bar_is_centred_and_the_middle_tap_sits_on_the_centre() -> void:
	for taps : int in [1, 3, 5]:
		assert_eq(TapLayoutScript.spout_x(taps, taps / 2), 0.0)
	assert_eq(TapLayoutScript.bar_left(4), -TapLayoutScript.bar_width(4) / 2.0)


func test_the_tray_overhangs_the_bar_and_its_studs_end_in_step() -> void:
	for taps : int in range(1, TapLayoutScript.MAX_TAPS + 1):
		var width : int = TapLayoutScript.tray_width(taps)
		assert_true(width >= TapLayoutScript.bar_width(taps) + 2 * TapLayoutScript.TRAY_OVERHANG)
		assert_eq(width % TapLayoutScript.TRAY_STUD_PITCH, 1, "%d taps" % taps)
