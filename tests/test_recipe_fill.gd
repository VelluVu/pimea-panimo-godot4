@tool
extends McpTestSuite

## Unit tests for RecipeFill: the all-or-nothing "Täytä resepti" from the warehouse.

const RecipeFillScript := preload("res://src/brewing/recipe_fill.gd")

const MALT_ID : int = 100
const HOP_ID : int = 202
const YEAST_ID : int = 302


func suite_name() -> String:
	return "recipe_fill"


func test_moves_only_what_the_table_lacks() -> void:
	var target : Dictionary = {MALT_ID: 3, HOP_ID: 25}
	var on_table : Dictionary = {MALT_ID: 1}
	var owned : Dictionary = {MALT_ID: 5, HOP_ID: 30}
	assert_eq(RecipeFillScript.from_stock(target, on_table, owned), {MALT_ID: 2, HOP_ID: 25})


func test_one_short_ingredient_moves_nothing() -> void:
	var target : Dictionary = {MALT_ID: 3, YEAST_ID: 1}
	var owned : Dictionary = {MALT_ID: 5}
	assert_eq(RecipeFillScript.from_stock(target, {}, owned), {})


func test_a_full_table_needs_nothing() -> void:
	var target : Dictionary = {MALT_ID: 3}
	assert_eq(RecipeFillScript.from_stock(target, {MALT_ID: 3}, {MALT_ID: 3}), {})


func test_what_is_already_on_the_table_counts_as_owned() -> void:
	# 2 on the table and 1 on the shelf: owned is 3, enough for the 3 the recipe wants.
	var target : Dictionary = {MALT_ID: 3}
	assert_eq(RecipeFillScript.from_stock(target, {MALT_ID: 2}, {MALT_ID: 3}), {MALT_ID: 1})


func test_no_recipe_loaded_fills_nothing() -> void:
	assert_eq(RecipeFillScript.from_stock({}, {MALT_ID: 1}, {MALT_ID: 9}), {})
