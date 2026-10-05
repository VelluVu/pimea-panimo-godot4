@tool
extends McpTestSuite

## Unit tests for BankruptcyRules: a run ends only when no known recipe can be
## brewed with owned ingredients, cash and what selling the rest back raises.

const BankruptcyRulesScript := preload("res://src/brewery/bankruptcy_rules.gd")

const MALT : int = 1
const YEAST : int = 2
const LOCKED_HOP : int = 3
const RECIPE : Dictionary = {MALT: 4, YEAST: 1}
const BUY_PRICES : Dictionary = {MALT: 1.0, YEAST: 2.0}
const SELL_PRICES : Dictionary = {MALT: 0.75, YEAST: 1.5, LOCKED_HOP: 3.0}


func suite_name() -> String:
	return "bankruptcy_rules"


func _is_bankrupt(money : float, bottles : int, owned : Dictionary, recipe : Dictionary = RECIPE) -> bool:
	var recipes : Array[Dictionary] = [recipe]
	return BankruptcyRulesScript.is_bankrupt(money, bottles, owned, recipes, BUY_PRICES, SELL_PRICES)


func test_bottles_keep_the_run_alive() -> void:
	assert_false(_is_bankrupt(0.0, 5, {}))


func test_money_above_zero_keeps_the_run_alive() -> void:
	assert_false(_is_bankrupt(0.5, 0, {}))


func test_no_money_no_bottles_no_ingredients_is_bankrupt() -> void:
	assert_true(_is_bankrupt(0.0, 0, {}))


func test_spending_the_last_euro_on_a_full_recipe_is_not_bankrupt() -> void:
	assert_false(_is_bankrupt(0.0, 0, {MALT: 4, YEAST: 1}))


func test_owning_a_full_recipe_survives_negative_money() -> void:
	assert_false(_is_bankrupt(-12.0, 0, {MALT: 4, YEAST: 1}))


func test_selling_spare_ingredients_can_pay_for_the_missing_ones() -> void:
	# Missing yeast costs 2.0; the spare hop sells for 3.0.
	assert_false(_is_bankrupt(0.0, 0, {MALT: 4, LOCKED_HOP: 1}))


func test_selling_back_is_not_enough_when_debt_eats_it() -> void:
	assert_true(_is_bankrupt(-2.0, 0, {MALT: 4, LOCKED_HOP: 1}))


func test_ingredients_the_recipe_needs_are_not_counted_as_sellable() -> void:
	# All four malts are needed, so nothing is left to sell for the yeast.
	assert_true(_is_bankrupt(0.0, 0, {MALT: 4}))


func test_a_missing_ingredient_that_cannot_be_bought_blocks_the_recipe() -> void:
	var recipe : Dictionary = {MALT: 1, LOCKED_HOP: 1}
	assert_true(_is_bankrupt(0.0, 0, {MALT: 1, YEAST: 10}, recipe))


func test_any_one_brewable_recipe_is_enough() -> void:
	var recipes : Array[Dictionary] = [{LOCKED_HOP: 1}, RECIPE]
	assert_false(BankruptcyRulesScript.is_bankrupt(0.0, 0, {MALT: 4, YEAST: 1}, recipes, BUY_PRICES, SELL_PRICES))
