@tool
extends McpTestSuite

## Unit tests for CellarUpgradeRules' prices and purchase checks.

const RulesScript := preload("res://src/brewery/cellar_upgrade_rules.gd")


func suite_name() -> String:
	return "cellar_upgrade_rules"


func test_first_level_costs_the_base_price() -> void:
	assert_eq(RulesScript.level_cost(80, 1.9, 0), 80)


func test_each_level_costs_more_than_the_last() -> void:
	var previous : int = 0
	for level : int in 5:
		var cost : int = RulesScript.level_cost(80, 1.9, level)
		assert_gt(cost, previous)
		previous = cost


func test_prices_round_to_the_price_step() -> void:
	for level : int in 5:
		assert_eq(RulesScript.level_cost(43, 1.7, level) % RulesScript.PRICE_STEP, 0)


func test_cannot_buy_past_the_max_level() -> void:
	assert_false(RulesScript.can_buy(5, 5, 10, 1000.0))
	assert_true(RulesScript.is_maxed(5, 5))


func test_cannot_buy_without_the_money() -> void:
	assert_false(RulesScript.can_buy(0, 5, 80, 79.9))
	assert_true(RulesScript.can_buy(0, 5, 80, 80.0))
