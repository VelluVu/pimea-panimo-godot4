@tool
extends McpTestSuite

## Which batch a customer picks. Loaded by path so the suite always runs the script as
## it is on disk.

const BatchChoiceScript := preload("res://src/customers/batch_choice.gd")


func suite_name() -> String:
	return "batch_choice"


func _batch(style : BeerStyle.Style, bottles : int, quality : float = 1.0, abv : float = 5.0) -> BrewBatch:
	var beer_style := BeerStyle.new()
	beer_style.style = style
	beer_style.abv = abv
	var batch := BrewBatch.new()
	batch.beer_style = beer_style
	batch.amount_bottles = bottles
	batch.current_quality = quality
	return batch


func _customer(primary : BeerStyle.Style, secondary : BeerStyle.Style) -> CustomerData:
	var customer := CustomerData.new()
	customer.primary_style = primary
	customer.secondary_style = secondary
	return customer


func _batches(list : Array) -> Array[BrewBatch]:
	var typed : Array[BrewBatch] = []
	for batch : BrewBatch in list:
		typed.append(batch)
	return typed


func test_no_batches_means_no_pick() -> void:
	var customer := _customer(BeerStyle.Style.IPA, BeerStyle.Style.HELLES)
	assert_eq(BatchChoiceScript.find_best_batch(_batches([]), customer), null)


func test_the_primary_style_beats_the_secondary() -> void:
	var customer := _customer(BeerStyle.Style.IPA, BeerStyle.Style.HELLES)
	var helles := _batch(BeerStyle.Style.HELLES, 10)
	var ipa := _batch(BeerStyle.Style.IPA, 10)
	assert_eq(BatchChoiceScript.find_best_batch(_batches([helles, ipa]), customer), ipa)


func test_a_held_batch_is_never_picked() -> void:
	var customer := _customer(BeerStyle.Style.IPA, BeerStyle.Style.HELLES)
	var held_ipa := _batch(BeerStyle.Style.IPA, 10)
	held_ipa.held = true
	var helles := _batch(BeerStyle.Style.HELLES, 5)
	assert_eq(BatchChoiceScript.find_best_batch(_batches([held_ipa, helles]), customer), helles)


func test_an_empty_batch_is_never_picked() -> void:
	var customer := _customer(BeerStyle.Style.IPA, BeerStyle.Style.HELLES)
	var empty_ipa := _batch(BeerStyle.Style.IPA, 0)
	var helles := _batch(BeerStyle.Style.HELLES, 5)
	assert_eq(BatchChoiceScript.find_best_batch(_batches([empty_ipa, helles]), customer), helles)


func test_a_batch_failing_a_strict_requirement_is_invisible() -> void:
	var customer := _customer(BeerStyle.Style.IPA, BeerStyle.Style.HELLES)
	customer.min_required_abv = 6.0
	var weak_ipa := _batch(BeerStyle.Style.IPA, 10, 1.0, 4.0)
	assert_eq(BatchChoiceScript.find_best_batch(_batches([weak_ipa]), customer), null)


func test_a_good_enough_beer_beats_a_preferred_one_below_the_bar() -> void:
	# Below the bar the customer would refuse, so anything good enough wins.
	var customer := _customer(BeerStyle.Style.IPA, BeerStyle.Style.HELLES)
	customer.min_quality = 0.5
	var poor_helles := _batch(BeerStyle.Style.HELLES, 10, 0.1)
	var good_lager := _batch(BeerStyle.Style.BULKKILAGER, 10, 1.0)
	assert_eq(BatchChoiceScript.find_best_batch(_batches([good_lager, poor_helles]), customer), good_lager)


func test_among_good_enough_beers_the_preferred_style_wins() -> void:
	var customer := _customer(BeerStyle.Style.IPA, BeerStyle.Style.HELLES)
	customer.min_quality = 0.5
	var good_helles := _batch(BeerStyle.Style.HELLES, 10, 0.8)
	var good_lager := _batch(BeerStyle.Style.BULKKILAGER, 10, 1.0)
	assert_eq(BatchChoiceScript.find_best_batch(_batches([good_lager, good_helles]), customer), good_helles)


func test_quality_bonus_breaks_a_tie_between_equal_styles() -> void:
	var customer := _customer(BeerStyle.Style.IPA, BeerStyle.Style.HELLES)
	customer.min_quality = 0.5
	var poor := _batch(BeerStyle.Style.IPA, 10, 0.1)
	var good := _batch(BeerStyle.Style.IPA, 10, 0.9)
	assert_eq(BatchChoiceScript.find_best_batch(_batches([poor, good]), customer), good)


func _random_picker(min_quality : float = 0.3) -> CustomerData:
	var customer := CustomerData.new()
	customer.picks_at_random = true
	customer.min_quality = min_quality
	return customer


func test_a_regular_customer_picks_only_the_best_batch() -> void:
	var customer := _customer(BeerStyle.Style.IPA, BeerStyle.Style.HELLES)
	var ipa := _batch(BeerStyle.Style.IPA, 10)
	var helles := _batch(BeerStyle.Style.HELLES, 10)
	assert_eq(BatchChoiceScript.pick_batches(_batches([helles, ipa]), customer, 2), _batches([ipa]))


func test_a_random_picker_takes_different_styles() -> void:
	var lager := _batch(BeerStyle.Style.BULKKILAGER, 10)
	var second_lager := _batch(BeerStyle.Style.BULKKILAGER, 10)
	var ipa := _batch(BeerStyle.Style.IPA, 10)
	for i : int in 20:
		var picks : Array[BrewBatch] = BatchChoiceScript.pick_batches(_batches([lager, second_lager, ipa]), _random_picker(), 2)
		assert_eq(picks.size(), 2)
		assert_true(picks.has(ipa), "two picks of different styles must include the only IPA")


func test_a_random_picker_stops_at_the_count() -> void:
	var lager := _batch(BeerStyle.Style.BULKKILAGER, 10)
	var ipa := _batch(BeerStyle.Style.IPA, 10)
	assert_eq(BatchChoiceScript.pick_batches(_batches([lager, ipa]), _random_picker(), 1).size(), 1)


func test_a_random_picker_skips_batches_below_the_bar() -> void:
	var poor := _batch(BeerStyle.Style.BULKKILAGER, 10, 0.1)
	var good := _batch(BeerStyle.Style.IPA, 10, 0.9)
	for i : int in 20:
		assert_eq(BatchChoiceScript.pick_batches(_batches([poor, good]), _random_picker(), 2), _batches([good]))


func test_a_random_picker_falls_back_to_the_best_batch_to_refuse() -> void:
	var poor := _batch(BeerStyle.Style.BULKKILAGER, 10, 0.1)
	assert_eq(BatchChoiceScript.pick_batches(_batches([poor]), _random_picker(), 2), _batches([poor]))
	assert_true(BatchChoiceScript.pick_batches(_batches([]), _random_picker(), 2).is_empty())


func test_a_random_picker_likes_every_style() -> void:
	assert_eq(_random_picker().get_preference_score(BeerStyle.Style.SAHTI), 1.0)
