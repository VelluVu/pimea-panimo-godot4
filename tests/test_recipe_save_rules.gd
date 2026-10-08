@tool
extends McpTestSuite

## Unit tests for RecipeSaveRules: which tables may be saved as a recipe.

const RecipeSaveRulesScript := preload("res://src/brewing/recipe_save_rules.gd")


func suite_name() -> String:
	return "recipe_save_rules"


func _matched(is_matched : bool = true) -> BrewResult:
	var result := BrewResult.new()
	result.is_matched = is_matched
	return result


func _recipe(amounts : Dictionary) -> BrewRecipe:
	var recipe := BrewRecipe.new()
	recipe.ingredient_amounts = amounts
	return recipe


func test_a_new_known_recipe_saves() -> void:
	var saved : Array[BrewRecipe] = [_recipe({1: 5, 100: 2})]
	assert_eq(RecipeSaveRulesScript.rejection(_matched(), true, {1: 6, 100: 2}, saved), RecipeSaveRulesScript.Rejection.NONE)


func test_a_mix_that_fits_no_style_is_rejected() -> void:
	var saved : Array[BrewRecipe] = []
	assert_eq(RecipeSaveRulesScript.rejection(_matched(false), true, {1: 1}, saved), RecipeSaveRulesScript.Rejection.NO_STYLE)
	assert_eq(RecipeSaveRulesScript.rejection(null, true, {1: 1}, saved), RecipeSaveRulesScript.Rejection.NO_STYLE)


func test_an_undiscovered_style_is_rejected() -> void:
	var saved : Array[BrewRecipe] = []
	assert_eq(RecipeSaveRulesScript.rejection(_matched(), false, {1: 5}, saved), RecipeSaveRulesScript.Rejection.UNKNOWN_STYLE)


func test_the_same_ingredients_are_rejected_in_any_order() -> void:
	var saved : Array[BrewRecipe] = [_recipe({100: 2, 1: 5})]
	assert_eq(RecipeSaveRulesScript.rejection(_matched(), true, {1: 5, 100: 2}, saved), RecipeSaveRulesScript.Rejection.DUPLICATE)


func test_float_amounts_from_a_save_still_match() -> void:
	var saved : Array[BrewRecipe] = [_recipe({1: 5.0, 100: 2.0})]
	assert_true(RecipeSaveRulesScript.find_same({1: 5, 100: 2}, saved) == saved[0])


func test_an_extra_ingredient_is_a_different_recipe() -> void:
	var saved : Array[BrewRecipe] = [_recipe({1: 5})]
	assert_true(RecipeSaveRulesScript.find_same({1: 5, 400: 1}, saved) == null)
