@tool
extends McpTestSuite

## Unit tests for Inventory's stock-tracking math (add_amount/withdraw_item/
## has_item/get_item) — real economy logic (every ingredient purchase and
## every brew's consumption goes through it) that had no automated coverage
## at all. Only the *_by_id() variants (withdraw_item_by_id,
## add_amount_by_id, has_item_by_id) reach into IngredientDatabase — an
## autoload whose `database` dict this @tool-context harness can't populate
## (same limitation test_brew_resolver.gd documents) — so those stay
## untested here; the plain (ingredient : IngredientData) overloads below
## take the ingredient object directly and don't touch any autoload.


func suite_name() -> String:
	return "inventory"


func _make_ingredient(id: int, type: IngredientData.IngredientType) -> IngredientData:
	var ingredient := IngredientData.new()
	ingredient.id = id
	ingredient.type = type
	return ingredient


func test_add_amount_creates_a_new_entry() -> void:
	var inventory := Inventory.new()
	var malt := _make_ingredient(100, IngredientData.IngredientType.MALT)

	inventory.add_amount(malt, 3)

	assert_true(inventory.has_item(malt))
	assert_eq(inventory.get_item(malt).amount, 3)


func test_add_amount_accumulates_on_existing_entry() -> void:
	var inventory := Inventory.new()
	var malt := _make_ingredient(100, IngredientData.IngredientType.MALT)

	inventory.add_amount(malt, 3)
	inventory.add_amount(malt, 2)

	assert_eq(inventory.get_item(malt).amount, 5)


func test_add_amount_with_non_positive_amount_is_a_no_op() -> void:
	var inventory := Inventory.new()
	var malt := _make_ingredient(100, IngredientData.IngredientType.MALT)

	inventory.add_amount(malt, 0)
	inventory.add_amount(malt, -5)

	assert_false(inventory.has_item(malt))


func test_has_item_and_get_item_are_false_null_for_unknown_ingredient() -> void:
	var inventory := Inventory.new()
	var hop := _make_ingredient(200, IngredientData.IngredientType.HOP)

	assert_false(inventory.has_item(hop))
	assert_eq(inventory.get_item(hop), null)


func test_withdraw_item_reduces_stock_and_returns_withdrawn_amount() -> void:
	var inventory := Inventory.new()
	var hop := _make_ingredient(200, IngredientData.IngredientType.HOP)
	inventory.add_amount(hop, 10)

	var withdrawn : int = inventory.withdraw_item(hop, 4)

	assert_eq(withdrawn, 4)
	assert_eq(inventory.get_item(hop).amount, 6)


func test_withdraw_item_exact_stock_erases_the_entry() -> void:
	var inventory := Inventory.new()
	var hop := _make_ingredient(200, IngredientData.IngredientType.HOP)
	inventory.add_amount(hop, 5)

	var withdrawn : int = inventory.withdraw_item(hop, 5)

	assert_eq(withdrawn, 5)
	assert_false(inventory.has_item(hop))


func test_withdraw_item_with_insufficient_stock_withdraws_nothing() -> void:
	var inventory := Inventory.new()
	var yeast := _make_ingredient(300, IngredientData.IngredientType.YEAST)
	inventory.add_amount(yeast, 2)

	var withdrawn : int = inventory.withdraw_item(yeast, 5)

	assert_eq(withdrawn, 0)
	assert_eq(inventory.get_item(yeast).amount, 2)


func test_withdraw_item_with_non_positive_amount_withdraws_nothing() -> void:
	var inventory := Inventory.new()
	var yeast := _make_ingredient(300, IngredientData.IngredientType.YEAST)
	inventory.add_amount(yeast, 2)

	assert_eq(inventory.withdraw_item(yeast, 0), 0)
	assert_eq(inventory.withdraw_item(yeast, -1), 0)
	assert_eq(inventory.get_item(yeast).amount, 2)


func test_withdraw_item_on_unknown_ingredient_returns_zero() -> void:
	var inventory := Inventory.new()
	var yeast := _make_ingredient(300, IngredientData.IngredientType.YEAST)

	assert_eq(inventory.withdraw_item(yeast, 1), 0)


func test_count_bottles_is_zero_for_an_empty_cellar() -> void:
	assert_eq(Inventory.new().count_bottles(), 0)


func test_count_bottles_sums_every_batch() -> void:
	var inventory := Inventory.new()
	for amount : int in [10, 5, 7]:
		var batch := BrewBatch.new()
		batch.amount_bottles = amount
		inventory.brew_batches.append(batch)
	assert_eq(inventory.count_bottles(), 22)
