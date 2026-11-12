@tool
extends McpTestSuite

## Unit tests for CustomerGiftRules: when a customer leaves an ingredient behind.

const RulesScript := preload("res://src/customers/rules/customer_gift_rules.gd")


func suite_name() -> String:
	return "customer_gift_rules"


func test_a_roll_under_the_chance_leaves_the_gift() -> void:
	assert_true(RulesScript.leaves_gift(100, 3, 0.35, 1, 0.2))


func test_a_roll_over_the_chance_does_not() -> void:
	assert_false(RulesScript.leaves_gift(100, 3, 0.35, 1, 0.5))


func test_no_gift_without_a_sale() -> void:
	assert_false(RulesScript.leaves_gift(100, 3, 1.0, 0, 0.0))


func test_a_customer_without_a_gift_never_leaves_one() -> void:
	assert_false(RulesScript.leaves_gift(-1, 3, 1.0, 1, 0.0))
	assert_false(RulesScript.leaves_gift(100, 0, 1.0, 1, 0.0))
