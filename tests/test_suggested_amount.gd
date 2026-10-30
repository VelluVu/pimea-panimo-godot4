@tool
extends McpTestSuite

const SuggestedAmountScript := preload("res://src/ui/suggested_amount.gd")


func suite_name() -> String:
	return "suggested_amount"


func test_the_table_starts_at_the_recipe_shortfall() -> void:
	assert_eq(SuggestedAmountScript.for_table(3, 1, 10, 1), 2)


func test_the_table_never_suggests_more_than_the_stock() -> void:
	assert_eq(SuggestedAmountScript.for_table(3, 0, 2, 1), 2)
	assert_eq(SuggestedAmountScript.for_table(3, 0, 0, 1), 0)


func test_without_a_shortfall_the_table_starts_at_one_step() -> void:
	assert_eq(SuggestedAmountScript.for_table(0, 0, 100, 25), 25)
	assert_eq(SuggestedAmountScript.for_table(3, 3, 10, 1), 1)


func test_the_shop_starts_at_what_the_recipe_misses() -> void:
	assert_eq(SuggestedAmountScript.for_shop(3, 10, 1), 3)
	assert_eq(SuggestedAmountScript.for_shop(0, 10, 1), 1)


func test_the_shop_never_suggests_more_than_the_money_buys() -> void:
	assert_eq(SuggestedAmountScript.for_shop(3, 2, 1), 2)
	assert_eq(SuggestedAmountScript.for_shop(3, 0, 1), 0)
