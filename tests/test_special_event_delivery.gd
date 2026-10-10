@tool
extends McpTestSuite

## What an accepted special request is still missing (delivery_progress) and which
## requests wait for their goods at all (waits_for_delivery).


func suite_name() -> String:
	return "special_event_delivery"


func _make_batch(style : BeerStyle.Style, bottles : int, quality : float = 1.0) -> BrewBatch:
	var batch := BrewBatch.new()
	batch.beer_style = BeerStyle.new()
	batch.beer_style.style = style
	batch.amount_bottles = bottles
	batch.current_quality = quality
	return batch


func test_style_request_counts_the_fullest_batch_of_that_style() -> void:
	var event := SpecialEventData.new()
	event.required_style = BeerStyle.Style.IPA
	event.required_bottles = 15
	var inventory := Inventory.new()
	inventory.brew_batches.append(_make_batch(BeerStyle.Style.IPA, 4))
	inventory.brew_batches.append(_make_batch(BeerStyle.Style.IPA, 9))
	inventory.brew_batches.append(_make_batch(BeerStyle.Style.HELLES, 30))
	assert_eq(event.delivery_progress(inventory), Vector2i(9, 15), "one batch is delivered, other styles do not count")


func test_style_request_with_none_of_that_style_has_nothing() -> void:
	var event := SpecialEventData.new()
	event.required_style = BeerStyle.Style.IPA
	event.required_bottles = 5
	assert_eq(event.delivery_progress(Inventory.new()), Vector2i(0, 5))


func test_quality_request_counts_only_good_enough_batches() -> void:
	var event := QualityChallengeEventData.new()
	event.required_min_quality = 1.2
	event.required_bottles = 3
	var inventory := Inventory.new()
	inventory.brew_batches.append(_make_batch(BeerStyle.Style.IPA, 40, 1.1))
	inventory.brew_batches.append(_make_batch(BeerStyle.Style.HELLES, 2, 1.3))
	assert_eq(event.delivery_progress(inventory), Vector2i(2, 3))


func test_quality_request_line_names_quality_and_caps_storage() -> void:
	var event := QualityChallengeEventData.new()
	event.required_min_quality = 1.2
	event.required_bottles = 3
	var inventory := Inventory.new()
	inventory.brew_batches.append(_make_batch(BeerStyle.Style.IPA, 40, 1.3))
	var text: String = event.delivery_text(inventory)
	assert_true(text.contains("120 %"), text)
	assert_true(text.contains("3 / 3"), "a big batch reads as enough, not 40 / 3: " + text)


func test_ingredient_request_counts_the_owned_amount() -> void:
	var event := IngredientDonationEventData.new()
	event.required_ingredient_id = 100
	event.required_ingredient_amount = 5
	var malt := IngredientData.new()
	malt.id = 100
	var inventory := Inventory.new()
	inventory.add_amount(malt, 3)
	assert_eq(event.delivery_progress(inventory), Vector2i(3, 5))


func test_goods_wait_for_delivery_but_payments_settle_at_once() -> void:
	assert_true(SpecialEventData.new().waits_for_delivery())
	assert_true(QualityChallengeEventData.new().waits_for_delivery())
	assert_true(IngredientDonationEventData.new().waits_for_delivery())
	assert_false(RiskBribeEventData.new().waits_for_delivery())
	assert_false(ReputationFavourEventData.new().waits_for_delivery())
