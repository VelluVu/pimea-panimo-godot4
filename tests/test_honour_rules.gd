@tool
extends McpTestSuite

## Unit tests for HonourRules: when a customer honours the cellar.

const RulesScript := preload("res://src/customers/rules/honour_rules.gd")


func suite_name() -> String:
	return "honour_rules"


func test_a_good_enough_favourite_honours() -> void:
	assert_true(RulesScript.earns(1.1, 1.1, false))
	assert_true(RulesScript.earns(1.1, 1.3, false))


func test_a_weaker_favourite_does_not() -> void:
	assert_false(RulesScript.earns(1.1, 1.05, false))


func test_no_favourite_sold_does_not() -> void:
	assert_false(RulesScript.earns(1.1, -1.0, false))


func test_only_once_a_run() -> void:
	assert_false(RulesScript.earns(1.1, 1.5, true))


func test_a_customer_without_an_honour_never_gives_one() -> void:
	assert_false(RulesScript.earns(-1.0, 2.0, false))
