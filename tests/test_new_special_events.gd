@tool
extends McpTestSuite

## The rules behind the contest, the sailor's bet, the dance hall order and the old
## master's tip.


func suite_name() -> String:
	return "new_special_events"


func _make_batch(style : BeerStyle.Style, servings : int, held : bool = false) -> BrewBatch:
	var batch := BrewBatch.new()
	batch.beer_style = BeerStyle.new()
	batch.beer_style.style = style
	batch.amount_bottles = servings
	batch.held = held
	return batch


func test_contest_judging() -> void:
	assert_eq(ContestEventData.judge(1.45, 1.4, 1.15), ContestEventData.Outcome.WON)
	assert_eq(ContestEventData.judge(1.2, 1.4, 1.15), ContestEventData.Outcome.PLACED)
	assert_eq(ContestEventData.judge(1.0, 1.4, 1.15), ContestEventData.Outcome.LOST)


func test_better_beer_tips_the_bet_within_limits() -> void:
	assert_true(is_equal_approx(GambleEventData.win_chance(1.0, 0.5, 0.2, 0.35, 0.65), 0.5))
	assert_true(is_equal_approx(GambleEventData.win_chance(1.5, 0.5, 0.2, 0.35, 0.65), 0.6))
	assert_true(is_equal_approx(GambleEventData.win_chance(3.0, 0.5, 0.2, 0.35, 0.65), 0.65))


func test_bulk_order_gathers_from_several_batches() -> void:
	var batches : Array[BrewBatch] = [_make_batch(BeerStyle.Style.BULKKILAGER, 45), _make_batch(BeerStyle.Style.KOTIKALJA, 40), _make_batch(BeerStyle.Style.BULKKILAGER, 30)]
	var taken : Dictionary = BulkOrderEventData.take_from(batches, 100)
	assert_eq(taken.values(), [45, 40, 15])


func test_bulk_order_takes_nothing_until_it_is_all_there() -> void:
	var batches : Array[BrewBatch] = [_make_batch(BeerStyle.Style.BULKKILAGER, 45)]
	assert_eq(BulkOrderEventData.take_from(batches, 100), {})


func test_bulk_order_skips_held_and_other_styles() -> void:
	var inventory := Inventory.new()
	inventory.brew_batches.append(_make_batch(BeerStyle.Style.BULKKILAGER, 20))
	inventory.brew_batches.append(_make_batch(BeerStyle.Style.KOTIKALJA, 45))
	inventory.brew_batches.append(_make_batch(BeerStyle.Style.BULKKILAGER, 40, true))
	inventory.brew_batches.append(_make_batch(BeerStyle.Style.IPA, 40))
	var found : Array[BrewBatch] = BulkOrderEventData.offered_batches(inventory, [BeerStyle.Style.BULKKILAGER, BeerStyle.Style.KOTIKALJA] as Array[BeerStyle.Style])
	assert_eq(found.map(func(b : BrewBatch) -> int: return b.amount_bottles), [45, 20])


func test_the_old_masters_tip_shows_in_the_recipe_library() -> void:
	var style := BeerStyle.new()
	style.min_ebc = 30
	style.max_ebc = 50
	style.min_ibu = 16
	style.max_ibu = 26
	assert_false(RecipeLibraryText.locked_row(style, "Lagerhiiva", "", false).contains("30-50"))
	assert_true(RecipeLibraryText.locked_row(style, "Lagerhiiva", "", false, "", false, true).contains("EBC 30-50, IBU 16-26"))
