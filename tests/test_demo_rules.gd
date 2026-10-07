@tool
extends McpTestSuite

const DemoRulesScript := preload("res://src/brewery/demo_rules.gd")
const DayRulesScript := preload("res://src/brewery/day_rules.gd")


func suite_name() -> String:
	return "demo_rules"


func test_the_demo_season_is_shorter() -> void:
	assert_eq(DemoRulesScript.last_day(true), DemoRulesScript.DEMO_LAST_DAY)
	assert_eq(DemoRulesScript.last_day(false), DayRulesScript.SURVIVAL_DAY_TARGET)
	assert_gt(DayRulesScript.SURVIVAL_DAY_TARGET, DemoRulesScript.DEMO_LAST_DAY)


func test_the_demo_ends_on_its_last_day() -> void:
	assert_eq(DemoRulesScript.demo_ending(DemoRulesScript.DEMO_LAST_DAY - 1, false), "")
	assert_eq(DemoRulesScript.demo_ending(DemoRulesScript.DEMO_LAST_DAY, false), DemoRulesScript.ENDING_DEMO_OVER)


func test_an_ended_run_does_not_end_again() -> void:
	assert_eq(DemoRulesScript.demo_ending(DemoRulesScript.DEMO_LAST_DAY, true), "")


func test_the_editor_and_tests_are_not_the_demo() -> void:
	assert_false(DemoRulesScript.is_demo())
