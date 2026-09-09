@tool
extends McpTestSuite

## Unit tests for CustomerData's pure logic: price/reputation/risk outcomes
## from evaluate_brew_batch(), the generate_display_name() fallback, and the
## reroll_preference() guard clauses. All cases rely on CustomerData's
## default export values so a regression in the defaults themselves would
## also be caught here.


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
	assert_eq(result[CustomerManager.KEY_REPUTATION], -3, "reputation")
	assert_eq(result[CustomerManager.KEY_RISK], 1, "risk")
	assert_eq(result[CustomerManager.KEY_RESPONSE], customer.dialogue_reject, "response")


func test_evaluate_brew_batch_rewards_primary_style_match() -> void:
	var customer := CustomerData.new()
	var batch := _make_batch(BeerStyle.Style.BULKKILAGER, 1.0)
	var result := customer.evaluate_brew_batch(batch)
	assert_eq(result[CustomerManager.KEY_INCOME], 4, "income")
	assert_eq(result[CustomerManager.KEY_REPUTATION], 10, "reputation")
	assert_eq(result[CustomerManager.KEY_RISK], 3, "risk")
	assert_eq(result[CustomerManager.KEY_RESPONSE], customer.dialogue_success, "response")


func test_evaluate_brew_batch_gives_smaller_reward_for_secondary_style() -> void:
	var customer := CustomerData.new()
	var batch := _make_batch(BeerStyle.Style.KOTIKALJA, 1.0)
	var result := customer.evaluate_brew_batch(batch)
	assert_eq(result[CustomerManager.KEY_INCOME], 3, "income")
	assert_eq(result[CustomerManager.KEY_REPUTATION], 0, "reputation")
	assert_eq(result[CustomerManager.KEY_RISK], 1, "risk")
	assert_eq(result[CustomerManager.KEY_RESPONSE], customer.dialogue_fallback, "response")


func test_evaluate_brew_batch_penalizes_wrong_style() -> void:
	var customer := CustomerData.new()
	var batch := _make_batch(BeerStyle.Style.IPA, 1.0)
	var result := customer.evaluate_brew_batch(batch)
	assert_eq(result[CustomerManager.KEY_INCOME], 2, "income")
	assert_eq(result[CustomerManager.KEY_REPUTATION], -1, "reputation")
	assert_eq(result[CustomerManager.KEY_RISK], 2, "risk")
	assert_eq(result[CustomerManager.KEY_RESPONSE], customer.dialogue_wrong_style, "response")


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
