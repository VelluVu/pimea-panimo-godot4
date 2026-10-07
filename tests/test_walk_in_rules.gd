@tool
extends McpTestSuite

const WalkInRulesScript := preload("res://src/customers/walk_in_rules.gd")


func suite_name() -> String:
	return "walk_in_rules"


func test_everyone_has_the_base_chance() -> void:
	assert_true(is_equal_approx(WalkInRulesScript.company_chance(0.0), 0.02))


func test_perks_add_to_the_chance_and_it_never_passes_one() -> void:
	assert_true(is_equal_approx(WalkInRulesScript.company_chance(0.08), 0.10))
	assert_eq(WalkInRulesScript.company_chance(5.0), 1.0)


func test_a_roll_under_the_chance_brings_company() -> void:
	assert_eq(WalkInRulesScript.customer_count(0.01, 0.02, 0), 2)
	assert_eq(WalkInRulesScript.customer_count(0.02, 0.02, 0), 1)
	assert_eq(WalkInRulesScript.customer_count(0.5, 0.02, 0), 1)


func test_the_legendary_bonus_grows_the_company() -> void:
	assert_eq(WalkInRulesScript.customer_count(0.01, 0.02, 1), 3)
	assert_eq(WalkInRulesScript.customer_count(0.9, 0.02, 1), 1)
