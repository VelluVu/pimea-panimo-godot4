@tool
extends McpTestSuite

## The wedding's two-style request and its reward between export and pub price.


func suite_name() -> String:
	return "wedding_order_event_data"


func _make_style(style : BeerStyle.Style, abv : float) -> BeerStyle:
	var beer_style := BeerStyle.new()
	beer_style.style = style
	beer_style.abv = abv
	return beer_style


func _make_batch(style : BeerStyle.Style, bottles : int) -> BrewBatch:
	var batch := BrewBatch.new()
	batch.beer_style = _make_style(style, 4.0)
	batch.amount_bottles = bottles
	return batch


func _make_bar(price_multiplier : float, required_reputation : int) -> BarContact:
	var bar := BarContact.new()
	bar.price_multiplier = price_multiplier
	bar.required_reputation = required_reputation
	return bar


func test_reward_is_between_export_and_pub() -> void:
	assert_eq(WeddingOrderEventData.reward_between(20.0, 40.0, 0.5, 1.1), 30.0)


func test_reward_beats_an_export_already_above_pub_price() -> void:
	assert_true(is_equal_approx(WeddingOrderEventData.reward_between(50.0, 40.0, 0.5, 1.1), 55.0))


func test_best_export_skips_bars_not_unlocked() -> void:
	var bars : Array[BarContact] = [_make_bar(0.8, 0), _make_bar(1.1, 30), _make_bar(1.35, 60)]
	assert_eq(WeddingOrderEventData.best_export_multiplier(bars, 40), 1.1)


func test_best_export_without_bars_is_one() -> void:
	assert_eq(WeddingOrderEventData.best_export_multiplier([], 100), 1.0)


func test_styles_split_into_light_and_alcohol_free() -> void:
	var styles : Array[BeerStyle] = [
		_make_style(BeerStyle.Style.ALKOHOLITON_LAGER, 0.3),
		_make_style(BeerStyle.Style.SESSION_ALE, 3.8),
		_make_style(BeerStyle.Style.PALE_ALE, 5.0),
		_make_style(BeerStyle.Style.IPA, 6.5),
	]
	assert_eq(WeddingOrderEventData.styles_between(styles, 0.5, 5.0), [BeerStyle.Style.SESSION_ALE, BeerStyle.Style.PALE_ALE])
	assert_eq(WeddingOrderEventData.styles_between(styles, -1.0, 0.5), [BeerStyle.Style.ALKOHOLITON_LAGER])


func test_each_style_counts_only_up_to_its_own_amount() -> void:
	var event := WeddingOrderEventData.new()
	event.required_style = BeerStyle.Style.HELLES
	event.required_bottles = 15
	event.alcohol_free_style = BeerStyle.Style.ALKOHOLITON_IPA
	event.alcohol_free_bottles = 10
	var inventory := Inventory.new()
	inventory.brew_batches.append(_make_batch(BeerStyle.Style.HELLES, 40))
	inventory.brew_batches.append(_make_batch(BeerStyle.Style.ALKOHOLITON_IPA, 4))
	assert_eq(event.delivery_progress(inventory), Vector2i(19, 25))
