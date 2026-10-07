@tool
extends McpTestSuite

const DayClockTextScript := preload("res://src/ui/day_clock_text.gd")


func suite_name() -> String:
	return "day_clock_text"


func test_the_day_runs_from_opening_to_closing_time() -> void:
	assert_eq(DayClockTextScript.clock_time(0.0), "18.00")
	assert_eq(DayClockTextScript.clock_time(0.5), "22.00")
	assert_eq(DayClockTextScript.closing_time(), "02.00")


func test_the_clock_moves_in_five_minute_steps() -> void:
	# 0.2 of 480 minutes is 96 minutes: 19.36 shows as 19.35.
	assert_eq(DayClockTextScript.clock_time(0.2), "19.35")


func test_the_time_past_midnight_wraps() -> void:
	assert_eq(DayClockTextScript.clock_time(0.9), "01.10")


func test_the_tooltip_shows_the_day_time_and_time_left() -> void:
	var text : String = DayClockTextScript.tooltip(3, 15, 0.5, 200.4)
	assert_contains(text, "Päivä 3/15")
	assert_contains(text, "Kello 22.00, valot sammuvat klo 02.00")
	assert_contains(text, "Päivää jäljellä 3 min 21 s")


func test_a_stopped_clock_says_when_it_starts() -> void:
	var text : String = DayClockTextScript.tooltip(1, 15, 0.0, -1.0)
	assert_contains(text, DayClockTextScript.CLOCK_STOPPED_TEXT)
	assert_false(text.contains("Kello 18"))


func test_a_day_past_the_season_is_not_shown_as_a_fraction() -> void:
	assert_contains(DayClockTextScript.tooltip(17, 15, 0.1, 100.0), "Päivä 17, kausi on jo pelattu")
