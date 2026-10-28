@tool
extends McpTestSuite

## Unit tests for HalloweenRules: which dates put the decorations up.

const HalloweenRulesScript := preload("res://src/events/halloween_rules.gd")


func suite_name() -> String:
	return "halloween_rules"


func _date(month : int, day : int) -> Dictionary:
	return {"year": 2026, "month": month, "day": day}


func test_halloween_itself_is_in_season() -> void:
	assert_true(HalloweenRulesScript.is_season(_date(10, 31)))


func test_the_season_starts_on_its_first_day() -> void:
	assert_false(HalloweenRulesScript.is_season(_date(10, 19)))
	assert_true(HalloweenRulesScript.is_season(_date(10, 20)))


## No Christmas season yet, so Halloween holds until the year turns.
func test_the_season_lasts_until_the_new_year() -> void:
	assert_true(HalloweenRulesScript.is_season(_date(11, 15)))
	assert_true(HalloweenRulesScript.is_season(_date(12, 31)))
	assert_false(HalloweenRulesScript.is_season(_date(1, 1)))


func test_days_outside_the_season_are_not() -> void:
	assert_false(HalloweenRulesScript.is_season(_date(6, 15)))
	assert_false(HalloweenRulesScript.is_season({}))
