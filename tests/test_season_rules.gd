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
	assert_eq(_season(2026, 12, 1), SeasonRulesScript.Season.NONE)


## With Black Friday on the 29th, Cyber Monday is 2 December.
func test_cyber_week_can_reach_into_december() -> void:
	assert_eq(_season(2024, 11, 24), SeasonRulesScript.Season.BLACK_MONTH)
	assert_eq(_season(2024, 11, 25), SeasonRulesScript.Season.CYBER_WEEK)
	assert_eq(_season(2024, 12, 2), SeasonRulesScript.Season.CYBER_WEEK)
	assert_eq(_season(2024, 12, 3), SeasonRulesScript.Season.NONE)


func test_black_month_things_stay_in_cyber_week() -> void:
	var season := SeasonRulesScript.Season
	assert_true(SeasonRulesScript.includes(season.CYBER_WEEK, season.BLACK_MONTH))
	assert_true(SeasonRulesScript.includes(season.CYBER_WEEK, season.CYBER_WEEK))
	assert_false(SeasonRulesScript.includes(season.BLACK_MONTH, season.CYBER_WEEK))
	assert_false(SeasonRulesScript.includes(season.HALLOWEEN, season.BLACK_MONTH))
	assert_true(SeasonRulesScript.includes(season.HALLOWEEN, season.HALLOWEEN))


func test_days_outside_the_seasons_are_not() -> void:
	assert_eq(_season(2026, 6, 15), SeasonRulesScript.Season.NONE)
	assert_eq(_season(2026, 12, 24), SeasonRulesScript.Season.NONE)
	assert_eq(SeasonRulesScript.season_of({}), SeasonRulesScript.Season.NONE)


func test_a_forced_season_wins_until_cleared() -> void:
	var calendar : SeasonRulesScript.Season = SeasonRulesScript.now()
	SeasonRulesScript.force(SeasonRulesScript.Season.CYBER_WEEK)
	assert_eq(SeasonRulesScript.now(), SeasonRulesScript.Season.CYBER_WEEK)
	SeasonRulesScript.force(SeasonRulesScript.Season.NONE)
	assert_eq(SeasonRulesScript.now(), SeasonRulesScript.Season.NONE)
	SeasonRulesScript.clear_forced()
	assert_eq(SeasonRulesScript.now(), calendar)
