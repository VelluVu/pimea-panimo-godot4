@tool
extends McpTestSuite

## Unit tests for RecipeNameText: stored names and the names rebuilt for display.

const RecipeNameTextScript := preload("res://src/ui/recipe_name_text.gd")


func suite_name() -> String:
	return "recipe_name_text"


func _make_recipe(stored_name : String, is_default : bool = false) -> BrewRecipe:
	var recipe := BrewRecipe.new()
	recipe.beer_style = BeerStyle.Style.SAHTI
	recipe.recipe_name = stored_name
	recipe.is_default = is_default
	return recipe


func test_stored_names_use_the_finnish_formats() -> void:
	assert_eq(RecipeNameTextScript.default_name("Sahti"), "Sahti (perusresepti)")
	assert_eq(RecipeNameTextScript.numbered_name("Sahti", 3), "Sahti #3")


func test_display_rebuilds_a_numbered_name_from_the_style_and_number() -> void:
	var recipe := _make_recipe("Vanha nimi #12")
	assert_eq(RecipeNameTextScript.display(recipe), "%s #12" % StringContainer.SAHTI)


func test_display_rebuilds_a_default_name_from_the_style() -> void:
	var recipe := _make_recipe("Mitä tahansa", true)
	assert_eq(RecipeNameTextScript.display(recipe), "%s (perusresepti)" % StringContainer.SAHTI)


func test_display_keeps_a_name_without_a_number() -> void:
	var recipe := _make_recipe("Oma resepti")
	assert_eq(RecipeNameTextScript.display(recipe), "Oma resepti")
