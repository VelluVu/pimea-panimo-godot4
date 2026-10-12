@tool
extends McpTestSuite

const BrewDayRulesScript := preload("res://src/brewing/brew_day/brew_day_rules.gd")


func suite_name() -> String:
	return "brew_day_rules"


func test_a_failed_day_gives_the_floor() -> void:
	assert_eq(BrewDayRulesScript.multiplier(0.0), BrewDayRulesScript.FAILED_MULTIPLIER)


func test_a_low_score_slides_up_to_normal() -> void:
	assert_true(is_equal_approx(BrewDayRulesScript.multiplier(0.25), 0.9))
	assert_eq(BrewDayRulesScript.multiplier(0.5), BrewDayRulesScript.NORMAL_MULTIPLIER)


func test_the_middle_is_normal_and_the_top_is_perfect() -> void:
	assert_eq(BrewDayRulesScript.multiplier(0.79), BrewDayRulesScript.NORMAL_MULTIPLIER)
	assert_eq(BrewDayRulesScript.multiplier(0.8), BrewDayRulesScript.PERFECT_MULTIPLIER)
	assert_eq(BrewDayRulesScript.multiplier(1.5), BrewDayRulesScript.PERFECT_MULTIPLIER)


func test_the_final_score_averages_mash_and_boil() -> void:
	assert_eq(BrewDayRulesScript.final_score(1.0, 0.5), 0.75)
	assert_eq(BrewDayRulesScript.final_score(-1.0, 2.0), 0.5)


func test_skipping_is_worse_than_a_normal_day_and_the_kettle_is_perfect() -> void:
	assert_true(BrewDayRulesScript.SKIP_MULTIPLIER < BrewDayRulesScript.NORMAL_MULTIPLIER)
	assert_eq(BrewDayRulesScript.AUTO_KETTLE_MULTIPLIER, BrewDayRulesScript.PERFECT_MULTIPLIER)
