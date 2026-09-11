@tool
extends McpTestSuite

## Unit tests for CustomerData's pure logic: price/reputation/risk outcomes
## from evaluate_brew_batch(), the generate_display_name() fallback, and the
## reroll_preference() guard clauses. All cases rely on CustomerData's
## default export values so a regression in the defaults themselves would
## also be caught here.
##
## evaluate_brew_batch() adds a continuous quality_margin adjustment (quality
## minus this customer's min_quality, times quality_reputation_sensitivity /
## quality_risk_sensitivity) on top of each branch's flat rep/risk numbers —
## every expected reputation/risk value below already bakes that margin in
## for the given quality (default min_quality = 0.5, sensitivities 4.0/2.0).


func suite_name() -> String:
	return "customer_data"


func _make_batch(style: BeerStyle.Style, quality: float) -> BrewBatch:
	var beer_style := BeerStyle.new()
	beer_style.style = style
	var batch := BrewBatch.new()
	batch.beer_style = beer_style
	batch.current_quality = quality
	return batch


func test_evaluate_brew_batch_rejects_below_min_quality() -> void:
	var customer := CustomerData.new()
	var batch := _make_batch(BeerStyle.Style.BULKKILAGER, 0.3)
	var result := customer.evaluate_brew_batch(batch)
	assert_eq(result[CustomerManager.KEY_INCOME], 0, "income")
	assert_eq(result[CustomerManager.KEY_REPUTATION], -4, "reputation") # -3 flat, margin -0.2 * 4.0 -> -1 extra
	assert_eq(result[CustomerManager.KEY_RISK], 1, "risk") # margin -0.2 * 2.0 rounds to 0 extra
	assert_eq(result[CustomerManager.KEY_RESPONSE], customer.dialogue_reject, "response")


func test_evaluate_brew_batch_rewards_primary_style_match() -> void:
	var customer := CustomerData.new()
	var batch := _make_batch(BeerStyle.Style.BULKKILAGER, 1.0)
	var result := customer.evaluate_brew_batch(batch)
	assert_eq(result[CustomerManager.KEY_INCOME], 4, "income")
	assert_eq(result[CustomerManager.KEY_REPUTATION], 12, "reputation") # 10 flat, margin 0.5 * 4.0 -> +2
	assert_eq(result[CustomerManager.KEY_RISK], 2, "risk") # 3 flat, margin 0.5 * 2.0 -> -1
	assert_eq(result[CustomerManager.KEY_RESPONSE], customer.dialogue_success, "response")


func test_evaluate_brew_batch_gives_smaller_reward_for_secondary_style() -> void:
	var customer := CustomerData.new()
	var batch := _make_batch(BeerStyle.Style.KOTIKALJA, 1.0)
	var result := customer.evaluate_brew_batch(batch)
	assert_eq(result[CustomerManager.KEY_INCOME], 3, "income")
	assert_eq(result[CustomerManager.KEY_REPUTATION], 2, "reputation") # 0 flat, margin 0.5 * 4.0 -> +2
	assert_eq(result[CustomerManager.KEY_RISK], 0, "risk") # 1 flat, margin 0.5 * 2.0 -> -1
	assert_eq(result[CustomerManager.KEY_RESPONSE], customer.dialogue_fallback, "response")


func test_evaluate_brew_batch_penalizes_wrong_style() -> void:
	var customer := CustomerData.new()
	var batch := _make_batch(BeerStyle.Style.IPA, 1.0)
	var result := customer.evaluate_brew_batch(batch)
	assert_eq(result[CustomerManager.KEY_INCOME], 2, "income")
	assert_eq(result[CustomerManager.KEY_REPUTATION], 1, "reputation") # -1 flat, margin 0.5 * 4.0 -> +2
	assert_eq(result[CustomerManager.KEY_RISK], 1, "risk") # 2 flat, margin 0.5 * 2.0 -> -1
	assert_eq(result[CustomerManager.KEY_RESPONSE], customer.dialogue_wrong_style, "response")


func test_evaluate_brew_batch_quality_at_min_quality_matches_flat_baseline() -> void:
	# quality exactly at the min_quality bar -> margin is 0, so the result
	# should equal the old pre-quality-margin flat numbers exactly, proving
	# the new continuous adjustment doesn't shift behavior at the boundary.
	var customer := CustomerData.new()
	var batch := _make_batch(BeerStyle.Style.BULKKILAGER, customer.min_quality)
	var result := customer.evaluate_brew_batch(batch)
	assert_eq(result[CustomerManager.KEY_REPUTATION], customer.rep_primary_style, "reputation")
	assert_eq(result[CustomerManager.KEY_RISK], customer.risk_primary_style, "risk")


func test_evaluate_brew_batch_masterful_quality_boosts_reputation_and_cuts_risk_further() -> void:
	# Well above min_quality should keep compounding the bonus/reduction,
	# not cap out at whatever the first threshold step gave.
	var customer := CustomerData.new()
	var batch := _make_batch(BeerStyle.Style.BULKKILAGER, 1.5)
	var result := customer.evaluate_brew_batch(batch)
	var margin : float = 1.5 - customer.min_quality
	assert_eq(result[CustomerManager.KEY_REPUTATION], customer.rep_primary_style + roundi(margin * customer.quality_reputation_sensitivity), "reputation")
	assert_eq(result[CustomerManager.KEY_RISK], maxi(0, customer.risk_primary_style - roundi(margin * customer.quality_risk_sensitivity)), "risk")


func test_generate_display_name_uses_title_and_first_names_when_set() -> void:
	var customer := CustomerData.new()
	customer.title = "Testi"
	customer.first_names = ["Ada", "Bo"]
	var display_name := customer.generate_display_name()
	assert_true(display_name.begins_with("Testi "), "should start with the configured title")
	assert_true(
		display_name == "Testi Ada" or display_name == "Testi Bo",
		"should use one of the configured first names, got: " + display_name
	)


func test_generate_display_name_falls_back_when_title_missing() -> void:
	var customer := CustomerData.new()
	var display_name := customer.generate_display_name()
	assert_true(
		display_name.begins_with(CustomerData.DEFAULT_TITLE + " "),
		"should fall back to the default title, got: " + display_name
	)


func test_reroll_preference_noop_when_disabled() -> void:
	var customer := CustomerData.new()
	customer.randomizes_preference = false
	customer.primary_style = BeerStyle.Style.IPA
	customer.secondary_style = BeerStyle.Style.HELLES
	customer.reroll_preference()
	assert_eq(customer.primary_style, BeerStyle.Style.IPA, "primary style should be untouched")
	assert_eq(customer.secondary_style, BeerStyle.Style.HELLES, "secondary style should be untouched")
