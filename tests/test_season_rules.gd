@tool
extends McpTestSuite

## Unit tests for SeasonRules: which dates put up the Halloween, Black Month and Cyber Week decorations.

const SeasonRulesScript := preload("res://src/events/season_rules.gd")


func suite_name() -> String:
	return "season_rules"


func _season(year : int, month : int, day : int) -> int:
	return SeasonRulesScript.season_of({"year": year, "month": month, "day": day})


func test_halloween_itself_is_in_season() -> void:
	assert_eq(_season(2026, 10, 31), SeasonRulesScript.Season.HALLOWEEN)


func test_halloween_starts_on_its_first_day() -> void:
	assert_eq(_season(2026, 10, 19), SeasonRulesScript.Season.NONE)
	assert_eq(_season(2026, 10, 20), SeasonRulesScript.Season.HALLOWEEN)


func test_halloween_ends_early_in_november() -> void:
	assert_eq(_season(2026, 11, 8), SeasonRulesScript.Season.HALLOWEEN)
	assert_ne(_season(2026, 11, 9), SeasonRulesScript.Season.HALLOWEEN)


## Black Friday is the day after the fourth Thursday of November.
func test_black_friday_moves_with_the_calendar() -> void:
	assert_eq(SeasonRulesScript.black_friday_day(2026), 27)
	assert_eq(SeasonRulesScript.black_friday_day(2027), 26)
	assert_eq(SeasonRulesScript.black_friday_day(2024), 29)
	assert_eq(SeasonRulesScript.black_friday_day(2029), 23)


func test_black_month_starts_the_day_after_halloween() -> void:
	assert_eq(_season(2026, 11, 8), SeasonRulesScript.Season.HALLOWEEN)
	assert_eq(_season(2026, 11, 9), SeasonRulesScript.Season.BLACK_MONTH)
	assert_eq(_season(2026, 11, 22), SeasonRulesScript.Season.BLACK_MONTH)


func test_cyber_week_runs_from_monday_to_cyber_monday() -> void:
	assert_eq(_season(2026, 11, 23), SeasonRulesScript.Season.CYBER_WEEK)
	assert_eq(_season(2026, 11, 30), SeasonRulesScript.Season.CYBER_WEEK)
	assert_eq(_season(2026, 12, 1), SeasonRulesScript.Season.CHRISTMAS)


## With Black Friday on the 29th, Cyber Monday is 2 December.
func test_cyber_week_can_reach_into_december() -> void:
	assert_eq(_season(2024, 11, 24), SeasonRulesScript.Season.BLACK_MONTH)
	assert_eq(_season(2024, 11, 25), SeasonRulesScript.Season.CYBER_WEEK)
	assert_eq(_season(2024, 12, 2), SeasonRulesScript.Season.CYBER_WEEK)
	assert_eq(_season(2024, 12, 3), SeasonRulesScript.Season.CHRISTMAS)


func test_black_month_things_stay_in_cyber_week() -> void:
	var season := SeasonRulesScript.Season
	assert_true(SeasonRulesScript.includes(season.CYBER_WEEK, season.BLACK_MONTH))
	assert_true(SeasonRulesScript.includes(season.CYBER_WEEK, season.CYBER_WEEK))
	assert_false(SeasonRulesScript.includes(season.BLACK_MONTH, season.CYBER_WEEK))
	assert_false(SeasonRulesScript.includes(season.HALLOWEEN, season.BLACK_MONTH))
	assert_true(SeasonRulesScript.includes(season.HALLOWEEN, season.HALLOWEEN))


func test_days_outside_the_seasons_are_not() -> void:
	assert_eq(_season(2026, 6, 15), SeasonRulesScript.Season.NONE)
	assert_eq(_season(2026, 11, 1), SeasonRulesScript.Season.HALLOWEEN)
	assert_eq(_season(2026, 1, 7), SeasonRulesScript.Season.NONE)
	assert_eq(SeasonRulesScript.season_of({}), SeasonRulesScript.Season.NONE)


func test_a_forced_season_wins_until_cleared() -> void:
	var calendar : SeasonRulesScript.Season = SeasonRulesScript.now()
	SeasonRulesScript.force(SeasonRulesScript.Season.CYBER_WEEK)
	assert_eq(SeasonRulesScript.now(), SeasonRulesScript.Season.CYBER_WEEK)
	SeasonRulesScript.force(SeasonRulesScript.Season.NONE)
	assert_eq(SeasonRulesScript.now(), SeasonRulesScript.Season.NONE)
	SeasonRulesScript.clear_forced()
	assert_eq(SeasonRulesScript.now(), calendar)


func _winter(month : int, day : int) -> bool:
	return SeasonRulesScript.is_winter({"year": 2026, "month": month, "day": day})


func test_winter_starts_the_day_after_halloween() -> void:
	assert_false(_winter(11, 8))
	assert_true(_winter(11, 9))


func test_winter_runs_over_new_year() -> void:
	assert_true(_winter(12, 24))
	assert_true(_winter(1, 1))
	assert_true(_winter(2, 15))


func test_winter_ends_with_march() -> void:
	assert_true(_winter(3, 31))
	assert_false(_winter(4, 1))
	assert_false(_winter(7, 1))
	assert_false(_winter(10, 31))


func _days_left(year : int, month : int, day : int) -> int:
	return SeasonRulesScript.days_left({"year": year, "month": month, "day": day})


func test_halloween_counts_down_to_its_last_day() -> void:
	assert_eq(_days_left(2026, 11, 3), 6)
	assert_eq(_days_left(2026, 11, 8), 1)


func test_no_countdown_between_seasons() -> void:
	assert_eq(_days_left(2026, 6, 1), 0)


func test_black_month_counts_down_to_cyber_week() -> void:
	# Black Friday 2026 is 27 November, so Cyber Week starts on Monday the 23rd.
	assert_eq(_days_left(2026, 11, 22), 1)
	assert_eq(_days_left(2026, 11, 23), 8)


func test_winter_counts_down_over_new_year_to_march() -> void:
	assert_eq(SeasonRulesScript.winter_days_left({"year": 2026, "month": 3, "day": 31}), 1)
	assert_eq(SeasonRulesScript.winter_days_left({"year": 2026, "month": 12, "day": 31}), 91)
	assert_eq(SeasonRulesScript.winter_days_left({"year": 2026, "month": 4, "day": 1}), 0)


func test_christmas_starts_the_day_after_cyber_monday() -> void:
	assert_eq(_season(2026, 11, 30), SeasonRulesScript.Season.CYBER_WEEK)
	assert_eq(_season(2026, 12, 1), SeasonRulesScript.Season.CHRISTMAS)
	assert_eq(_season(2026, 12, 24), SeasonRulesScript.Season.CHRISTMAS)
	assert_eq(_season(2026, 12, 31), SeasonRulesScript.Season.CHRISTMAS)


func test_christmas_ends_with_epiphany() -> void:
	assert_eq(_season(2027, 1, 1), SeasonRulesScript.Season.CHRISTMAS)
	assert_eq(_season(2027, 1, 6), SeasonRulesScript.Season.CHRISTMAS)
	assert_eq(_season(2027, 1, 7), SeasonRulesScript.Season.NONE)


func test_christmas_counts_down_over_new_year() -> void:
	assert_eq(_days_left(2026, 12, 1), 37)
	assert_eq(_days_left(2027, 1, 6), 1)
