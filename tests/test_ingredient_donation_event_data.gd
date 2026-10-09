@tool
extends McpTestSuite

## Which ingredients the neighbour brewer can ask for.


func suite_name() -> String:
	return "ingredient_donation_event_data"


func _make_ingredient(id : int, type : IngredientData.IngredientType, min_reputation : int = 0) -> IngredientData:
	var ingredient := IngredientData.new()
	ingredient.id = id
	ingredient.type = type
	ingredient.min_reputation = min_reputation
	return ingredient


func test_only_ingredients_of_the_type_are_rolled() -> void:
	var ingredients : Array = [
		_make_ingredient(100, IngredientData.IngredientType.MALT),
		_make_ingredient(201, IngredientData.IngredientType.HOP),
		_make_ingredient(105, IngredientData.IngredientType.MALT),
	]
	assert_eq(IngredientDonationEventData.ids_of_type(ingredients, IngredientData.IngredientType.MALT, 0), [100, 105])


func test_ingredients_not_yet_for_sale_are_skipped() -> void:
	var ingredients : Array = [
		_make_ingredient(100, IngredientData.IngredientType.MALT),
		_make_ingredient(108, IngredientData.IngredientType.MALT, 50),
	]
	assert_eq(IngredientDonationEventData.ids_of_type(ingredients, IngredientData.IngredientType.MALT, 20), [100])
