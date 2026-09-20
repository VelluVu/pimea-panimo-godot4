@tool
extends McpTestSuite

## Unit tests for SaleProcessor's static parts: which batch a customer picks,
## and the income, tip and reputation maths of a sale. The full process() flow
## touches BrewerySignals and a live Brewery, so it is checked in a running
## game instead. Loaded by path so the suite always runs the script as it is on
## disk.

const SaleProcessorScript := preload("res://src/customers/sale_processor.gd")


func suite_name() -> String:
	return "sale_processor"


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
	assert_eq(SaleProcessorScript.find_best_batch(_batches([]), customer), null)


func test_the_primary_style_beats_the_secondary() -> void:
	var customer := _customer(BeerStyle.Style.IPA, BeerStyle.Style.HELLES)
	var helles := _batch(BeerStyle.Style.HELLES, 10)
	var ipa := _batch(BeerStyle.Style.IPA, 10)
	assert_eq(SaleProcessorScript.find_best_batch(_batches([helles, ipa]), customer), ipa)


func test_an_empty_batch_is_never_picked() -> void:
	var customer := _customer(BeerStyle.Style.IPA, BeerStyle.Style.HELLES)
	var empty_ipa := _batch(BeerStyle.Style.IPA, 0)
	var helles := _batch(BeerStyle.Style.HELLES, 5)
	assert_eq(SaleProcessorScript.find_best_batch(_batches([empty_ipa, helles]), customer), helles)


func test_a_batch_failing_a_strict_requirement_is_invisible() -> void:
	var customer := _customer(BeerStyle.Style.IPA, BeerStyle.Style.HELLES)
	customer.min_required_abv = 6.0
	var weak_ipa := _batch(BeerStyle.Style.IPA, 10, 1.0, 4.0)
	assert_eq(SaleProcessorScript.find_best_batch(_batches([weak_ipa]), customer), null)


func test_a_matching_style_beats_an_unmatched_one_despite_better_quality() -> void:
	# The secondary style scores 0.5; an unmatched style scores 0 plus the 0.2
	# quality bonus, so it still loses.
	var customer := _customer(BeerStyle.Style.IPA, BeerStyle.Style.HELLES)
	customer.min_quality = 0.5
	var poor_helles := _batch(BeerStyle.Style.HELLES, 10, 0.1)
	var good_lager := _batch(BeerStyle.Style.BULKKILAGER, 10, 1.0)
	assert_eq(SaleProcessorScript.find_best_batch(_batches([good_lager, poor_helles]), customer), poor_helles)


func test_quality_bonus_breaks_a_tie_between_equal_styles() -> void:
	var customer := _customer(BeerStyle.Style.IPA, BeerStyle.Style.HELLES)
	customer.min_quality = 0.5
	var poor := _batch(BeerStyle.Style.IPA, 10, 0.1)
	var good := _batch(BeerStyle.Style.IPA, 10, 0.9)
	assert_eq(SaleProcessorScript.find_best_batch(_batches([poor, good]), customer), good)


func _results(income : float, tip : float, reputation : int) -> Dictionary:
	return {
		CustomerManager.KEY_INCOME: income,
		CustomerManager.KEY_TIP: tip,
		CustomerManager.KEY_REPUTATION: reputation,
	}


func test_sale_income_scales_with_bottles() -> void:
	var outcome = SaleProcessorScript.calculate_sale(_results(2.0, 0.0, 0), 3, 1.0, 0.0, 1.0)
	assert_eq(outcome.gross_income, 6.0)
	assert_eq(outcome.tip_income, 0.0)
	assert_eq(outcome.net_income, 6.0)


func test_sale_tip_applies_its_multiplier() -> void:
	var outcome = SaleProcessorScript.calculate_sale(_results(2.0, 0.5, 0), 2, 1.5, 0.0, 1.0)
	assert_eq(outcome.tip_income, 1.5)
	assert_eq(outcome.net_income, 5.5)


func test_a_guaranteed_double_tip_doubles_after_the_multiplier() -> void:
	var outcome = SaleProcessorScript.calculate_sale(_results(2.0, 0.5, 0), 2, 1.5, 1.0, 1.0)
	assert_eq(outcome.tip_income, 3.0)
	assert_eq(outcome.net_income, 7.0)


func test_no_tip_is_never_doubled_into_existence() -> void:
	var outcome = SaleProcessorScript.calculate_sale(_results(2.0, 0.0, 0), 2, 1.0, 1.0, 1.0)
	assert_eq(outcome.tip_income, 0.0)


func test_reputation_gain_applies_its_multiplier_and_rounds() -> void:
	var outcome = SaleProcessorScript.calculate_sale(_results(1.0, 0.0, 4), 1, 1.0, 0.0, 1.5)
	assert_eq(outcome.reputation_gain, 6)
	outcome = SaleProcessorScript.calculate_sale(_results(1.0, 0.0, -3), 1, 1.0, 0.0, 1.5)
	assert_eq(outcome.reputation_gain, -5)


func test_amounts_are_snapped_to_the_tenth_grid() -> void:
	# 0.15 * 3 = 0.45 would otherwise carry a hundredths digit.
	var outcome = SaleProcessorScript.calculate_sale(_results(0.15, 0.0, 0), 3, 1.0, 0.0, 1.0)
	assert_true(is_equal_approx(outcome.gross_income, 0.5) or is_equal_approx(outcome.gross_income, 0.4), "gross %s is not on the 0.1 grid" % outcome.gross_income)
