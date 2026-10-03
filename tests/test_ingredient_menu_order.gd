@tool
extends McpTestSuite

## Unit tests for IngredientMenuOrder: unlocked first, locked nearest to unlocking next.

const IngredientMenuOrderScript := preload("res://src/ui/ingredient_menu_order.gd")


func suite_name() -> String:
	return "ingredient_menu_order"


func _make(id : int, min_reputation : int) -> IngredientData:
	var ingredient := IngredientData.new()
	ingredient.id = id
	ingredient.min_reputation = min_reputation
	return ingredient


func _ids(ingredients : Array[IngredientData]) -> Array[int]:
	var ids : Array[int] = []
	for ingredient : IngredientData in ingredients:
		ids.append(ingredient.id)
	return ids


func test_unlocked_keep_their_order_and_come_first() -> void:
	var list : Array[IngredientData] = [_make(1, 0), _make(2, 50), _make(3, 0)]
	assert_eq(_ids(IngredientMenuOrderScript.order(list, 10)), [1, 3, 2] as Array[int])


func test_locked_are_sorted_by_reputation_then_id() -> void:
	var list : Array[IngredientData] = [_make(4, 50), _make(5, 20), _make(6, 15), _make(7, 20)]
	assert_eq(_ids(IngredientMenuOrderScript.order(list, 0)), [6, 5, 7, 4] as Array[int])


func test_reaching_the_bar_unlocks() -> void:
	assert_false(IngredientMenuOrderScript.is_locked(_make(1, 20), 20))
	assert_true(IngredientMenuOrderScript.is_locked(_make(1, 20), 19))
