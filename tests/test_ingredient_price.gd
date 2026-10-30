@tool
extends McpTestSuite

## Unit tests for IngredientPrice: shop prices after the price perk, and the sell-back rate.

const IngredientPriceScript := preload("res://src/brewing/ingredient_price.gd")


func suite_name() -> String:
	return "ingredient_price"


func _malt(base_price : float) -> MaltData:
	var malt := MaltData.new()
	malt.base_price = base_price
	return malt


func test_unit_price_follows_the_perk() -> void:
	assert_true(is_equal_approx(IngredientPriceScript.unit(_malt(2.0), 0.9), 1.8))


func test_buying_rounds_to_the_cent() -> void:
	assert_eq(IngredientPriceScript.buy(_malt(0.333), 3, 1.0), 1.0)


func test_selling_back_pays_less_than_buying() -> void:
	var malt := _malt(2.0)
	assert_true(is_equal_approx(IngredientPriceScript.sell(malt, 4, 1.0), 6.0))
	assert_true(IngredientPriceScript.sell(malt, 4, 1.0) < IngredientPriceScript.buy(malt, 4, 1.0))


func test_unit_sell_price_is_the_sell_back_share() -> void:
	assert_true(is_equal_approx(IngredientPriceScript.unit_sell(_malt(2.0), 1.0), 2.0 * IngredientPriceScript.SELL_BACK_RATE))
