@tool
extends McpTestSuite


func suite_name() -> String:
	return "day_event_effects"


func _make_ingredient(id: int, type: IngredientData.IngredientType) -> IngredientData:
	var ingredient := IngredientData.new()
	ingredient.id = id
	ingredient.type = type
	return ingredient


func _make_batch(bottles: int) -> BrewBatch:
	var batch := BrewBatch.new()
	batch.amount_bottles = bottles
	return batch


func test_remove_ingredients_spans_several_items() -> void:
	var inventory := Inventory.new()
	var pale := _make_ingredient(100, IngredientData.IngredientType.MALT)
	var dark := _make_ingredient(101, IngredientData.IngredientType.MALT)
	inventory.add_amount(pale, 2)
	inventory.add_amount(dark, 5)

	var removed := DayEventEffects.remove_ingredients(inventory, IngredientData.IngredientType.MALT, 4)

	assert_eq(removed, 4)
	var left: int = 0
	for item: InventoryItem in inventory.items[IngredientData.IngredientType.MALT].values():
		left += item.amount
	assert_eq(left, 3)


func test_remove_ingredients_stops_at_available_stock() -> void:
	var inventory := Inventory.new()
	var malt := _make_ingredient(100, IngredientData.IngredientType.MALT)
	inventory.add_amount(malt, 2)

	assert_eq(DayEventEffects.remove_ingredients(inventory, IngredientData.IngredientType.MALT, 10), 2)
	assert_false(inventory.has_item(malt))


func test_remove_ingredients_ignores_other_types() -> void:
	var inventory := Inventory.new()
	var hop := _make_ingredient(200, IngredientData.IngredientType.HOP)
	inventory.add_amount(hop, 3)

	assert_eq(DayEventEffects.remove_ingredients(inventory, IngredientData.IngredientType.MALT, 2), 0)
	assert_eq(inventory.get_item(hop).amount, 3)


func test_spoil_bottles_takes_from_a_batch() -> void:
	var inventory := Inventory.new()
	inventory.brew_batches.append(_make_batch(10))

	assert_eq(DayEventEffects.spoil_bottles(inventory, 4), 4)
	assert_eq(inventory.brew_batches[0].amount_bottles, 6)


func test_spoil_bottles_drops_an_emptied_batch() -> void:
	var inventory := Inventory.new()
	inventory.brew_batches.append(_make_batch(3))

	assert_eq(DayEventEffects.spoil_bottles(inventory, 5), 3)
	assert_true(inventory.brew_batches.is_empty())


func test_spoil_bottles_with_no_batches_does_nothing() -> void:
	assert_eq(DayEventEffects.spoil_bottles(Inventory.new(), 5), 0)


func test_apply_with_no_effect_removes_nothing() -> void:
	var inventory := Inventory.new()
	inventory.brew_batches.append(_make_batch(10))

	assert_eq(DayEventEffects.apply(inventory, DayEventData.new()), 0)
	assert_eq(inventory.brew_batches[0].amount_bottles, 10)


func test_apply_routes_bottle_spoilage() -> void:
	var inventory := Inventory.new()
	inventory.brew_batches.append(_make_batch(10))
	var event := DayEventData.new()
	event.effect_type = DayEventData.EffectType.BOTTLE_SPOILAGE
	event.effect_amount_min = 2
	event.effect_amount_max = 2

	assert_eq(DayEventEffects.apply(inventory, event), 2)
	assert_eq(inventory.brew_batches[0].amount_bottles, 8)
