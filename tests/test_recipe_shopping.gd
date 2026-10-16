@tool
extends McpTestSuite

## Unit tests for RecipeShopping: what a loaded recipe still needs from the shop.

const ShoppingScript := preload("res://src/brewing/recipe_shopping.gd")

const MALT_ID : int = 100
const HOP_ID : int = 202
const YEAST_ID : int = 302


func suite_name() -> String:
	return "recipe_shopping"


func _table() -> Dictionary:
	var malt := MaltData.new()
	malt.base_price = 2.0
	var hop := HopData.new()
	hop.base_price = 0.09
	hop.min_reputation = 20
	var yeast := YeastData.new()
	yeast.base_price = 5.0
	return {MALT_ID: malt, HOP_ID: hop, YEAST_ID: yeast}


func test_only_what_the_table_and_warehouse_lack_is_bought() -> void:
	var target : Dictionary = {MALT_ID: 5, HOP_ID: 90, YEAST_ID: 1}
	var owned : Dictionary = {MALT_ID: 2, YEAST_ID: 3}
	assert_eq(ShoppingScript.missing(target, owned), {MALT_ID: 3, HOP_ID: 90})


func test_nothing_is_missing_when_everything_is_owned() -> void:
	assert_true(ShoppingScript.missing({MALT_ID: 5}, {MALT_ID: 6}).is_empty())
	assert_true(ShoppingScript.missing({}, {}).is_empty(), "no recipe loaded")


func test_the_price_is_to_the_cent_with_the_shop_perk() -> void:
	assert_eq(ShoppingScript.cost({MALT_ID: 3, HOP_ID: 90}, _table(), 1.0), 14.1)
	assert_eq(ShoppingScript.cost({MALT_ID: 3, HOP_ID: 90}, _table(), 0.9), 12.69)


func test_a_locked_ingredient_is_named() -> void:
	var table : Dictionary = _table()
	assert_eq(ShoppingScript.first_locked({MALT_ID: 3, HOP_ID: 90}, table, 10), table[HOP_ID])
	assert_eq(ShoppingScript.first_locked({MALT_ID: 3, HOP_ID: 90}, table, 20), null)
