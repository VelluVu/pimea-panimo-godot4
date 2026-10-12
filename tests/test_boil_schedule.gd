@tool
extends McpTestSuite

const BoilScheduleScript := preload("res://src/brewing/brew_day/boil_schedule.gd")


func suite_name() -> String:
	return "boil_schedule"


func test_the_marks_come_in_order() -> void:
	assert_eq(BoilScheduleScript.time_for(HopAddition.Kind.BITTERING), 0.0)
	assert_true(BoilScheduleScript.time_for(HopAddition.Kind.FLAVOR) < BoilScheduleScript.time_for(HopAddition.Kind.SPICE))
	assert_eq(BoilScheduleScript.time_for(HopAddition.Kind.AROMA), BoilScheduleScript.BOIL_SECONDS)


func test_bittering_opens_with_the_boil() -> void:
	assert_true(BoilScheduleScript.in_window(HopAddition.Kind.BITTERING, 0.0))
	assert_true(BoilScheduleScript.in_window(HopAddition.Kind.BITTERING, 1.5))
	assert_false(BoilScheduleScript.in_window(HopAddition.Kind.BITTERING, 1.6))


func test_other_windows_are_tight_and_can_widen() -> void:
	assert_true(BoilScheduleScript.in_window(HopAddition.Kind.FLAVOR, 5.7))
	assert_false(BoilScheduleScript.in_window(HopAddition.Kind.FLAVOR, 5.8))
	assert_true(BoilScheduleScript.in_window(HopAddition.Kind.FLAVOR, 5.8, 0.1))


func test_the_dry_hop_is_not_in_the_boil() -> void:
	assert_false(BoilScheduleScript.is_in_boil(HopAddition.Kind.DRY_HOP))


func test_the_aroma_window_lasts_the_hop_stand() -> void:
	assert_eq(BoilScheduleScript.end_time(), BoilScheduleScript.BOIL_SECONDS + BoilScheduleScript.HOP_STAND_SECONDS)
	assert_eq(BoilScheduleScript.window_end(HopAddition.Kind.AROMA), BoilScheduleScript.end_time())
	assert_true(BoilScheduleScript.in_window(HopAddition.Kind.AROMA, BoilScheduleScript.BOIL_SECONDS + 2.5))
