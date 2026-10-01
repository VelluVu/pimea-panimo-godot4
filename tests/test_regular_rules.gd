@tool
extends McpTestSuite

## Unit tests for RegularRules: standing changes and the regular threshold.

const RulesScript := preload("res://src/customers/regular_rules.gd")


func suite_name() -> String:
	return "regular_rules"


func test_delighted_visit_builds_standing() -> void:
	assert_eq(RulesScript.next_standing(0, true, 5), 1)


func test_bad_visit_costs_double() -> void:
	assert_eq(RulesScript.next_standing(4, false, -2), 2)


func test_plain_visit_keeps_standing() -> void:
	assert_eq(RulesScript.next_standing(2, false, 1), 2)


func test_standing_stays_within_bounds() -> void:
	assert_eq(RulesScript.next_standing(0, false, -3), 0)
	assert_eq(RulesScript.next_standing(RulesScript.MAX_STANDING, true, 5), RulesScript.MAX_STANDING)


func test_three_delighted_visits_make_a_regular() -> void:
	var standing: int = 0
	for i: int in 3:
		standing = RulesScript.next_standing(standing, true, 5)
	assert_true(RulesScript.is_regular(standing))
	assert_false(RulesScript.is_regular(RulesScript.next_standing(standing, false, -1)))
