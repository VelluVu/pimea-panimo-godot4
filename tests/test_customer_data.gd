@tool
extends McpTestSuite

## Unit tests for CustomerData's pure logic: price/tip/reputation/risk
## outcomes from evaluate_brew_batch(), the generate_display_name()
## fallback, and the reroll_preference() guard clauses. All cases rely on
## CustomerData's default export values so a regression in the defaults
## themselves would also be caught here.
##
## Income is now always the fixed style_base_price (floored at 1) — style
## match and quality no longer change what a customer pays, only their
## reputation/risk reaction and, when quality exceeds this customer's own
## min_quality bar (quality_margin > 0), a tip on top. See
## evaluate_brew_batch's own docstring for why.
##
## evaluate_brew_batch() adds a continuous quality_margin adjustment (quality
## minus this customer's min_quality, times quality_reputation_sensitivity /
## quality_risk_sensitivity) on top of each branch's flat rep/risk numbers —
## every expected reputation/risk value below already bakes that margin in
## for the given quality (default min_quality = 0.5, sensitivities 4.0/2.0).


func suite_name() -> String:
	return "customer_data"


func test_meets_strict_requirements_respects_min_abv() -> void:
	var customer := CustomerData.new()
	customer.min_required_abv = 5.0
	var weak_style := BeerStyle.new()
	weak_style.abv = 4.5
	var strong_style := BeerStyle.new()
	strong_style.abv = 5.0
	assert_false(customer.meets_strict_requirements(weak_style), "below min_required_abv should fail")
	assert_true(customer.meets_strict_requirements(strong_style), "exactly at min_required_abv should pass")


func test_meets_strict_requirements_respects_max_abv() -> void:
	var customer := CustomerData.new()
	customer.max_required_abv = 0.5
	var alcohol_free_style := BeerStyle.new()
	alcohol_free_style.abv = 0.3
	var regular_style := BeerStyle.new()
	regular_style.abv = 4.5
	assert_true(customer.meets_strict_requirements(alcohol_free_style), "within max_required_abv should pass")
	assert_false(customer.meets_strict_requirements(regular_style), "above max_required_abv should fail")


func test_meets_strict_requirements_respects_max_price() -> void:
	var customer := CustomerData.new()
	customer.max_required_price = 2.5
	var affordable_style := BeerStyle.new()
	affordable_style.fixed_price_per_bottle = 2.5
	var pricey_style := BeerStyle.new()
	pricey_style.fixed_price_per_bottle = 3.0
	assert_true(customer.meets_strict_requirements(affordable_style), "exactly at max_required_price should pass")
	assert_false(customer.meets_strict_requirements(pricey_style), "above max_required_price should fail")


func test_meets_strict_requirements_no_constraint_by_default() -> void:
	var customer := CustomerData.new()
	var any_style := BeerStyle.new()
	any_style.abv = 50.0
	assert_true(customer.meets_strict_requirements(any_style), "default -1 sentinels mean no constraint")


func test_meets_strict_requirements_respects_preference_match() -> void:
	var customer := CustomerData.new()
	customer.primary_style = BeerStyle.Style.IPA
	customer.secondary_style = BeerStyle.Style.HELLES
	customer.requires_preference_match = true
	var primary_style := BeerStyle.new()
	primary_style.style = BeerStyle.Style.IPA
	var secondary_style := BeerStyle.new()
	secondary_style.style = BeerStyle.Style.HELLES
	var unrelated_style := BeerStyle.new()
	unrelated_style.style = BeerStyle.Style.KOTIKALJA
	assert_true(customer.meets_strict_requirements(primary_style), "primary style match should pass")
	assert_true(customer.meets_strict_requirements(secondary_style), "secondary style match should pass")
	assert_false(customer.meets_strict_requirements(unrelated_style), "unrelated style should fail when requires_preference_match is set")


func test_meets_strict_requirements_respects_accepted_styles() -> void:
	var customer := CustomerData.new()
	customer.accepted_styles = [BeerStyle.Style.HELLES, BeerStyle.Style.BULKKILAGER]
	var listed_style := BeerStyle.new()
	listed_style.style = BeerStyle.Style.BULKKILAGER
	var unlisted_style := BeerStyle.new()
	unlisted_style.style = BeerStyle.Style.KOTIKALJA
	assert_true(customer.meets_strict_requirements(listed_style), "listed style should pass")
	assert_false(customer.meets_strict_requirements(unlisted_style), "unlisted style should fail")


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
	assert_eq(result[CustomerManager.KEY_INCOME], 3, "income") # fixed price, unaffected by bad quality
	assert_eq(result[CustomerManager.KEY_TIP], 0, "tip") # quality below the bar -> no tip
	assert_eq(result[CustomerManager.KEY_REPUTATION], -4, "reputation") # -3 flat, margin -0.2 * 4.0 -> -1 extra
	assert_eq(result[CustomerManager.KEY_RISK], 1, "risk") # margin -0.2 * 2.0 rounds to 0 extra
	assert_eq(result[CustomerManager.KEY_RESPONSE], customer.dialogue_reject, "response")


func test_evaluate_brew_batch_rewards_primary_style_match() -> void:
	var customer := CustomerData.new()
	var batch := _make_batch(BeerStyle.Style.BULKKILAGER, 1.0)
	var result := customer.evaluate_brew_batch(batch)
	assert_eq(result[CustomerManager.KEY_INCOME], 3, "income") # fixed price, style match doesn't change it
	assert_eq(result[CustomerManager.KEY_TIP], 0.5, "tip") # proportional 3*0.5*0.3=0.45 loses to the MIN_TIP_PER_QUALITY_POINT floor (0.5*1.0=0.5)
	assert_eq(result[CustomerManager.KEY_REPUTATION], 12, "reputation") # 10 flat, margin 0.5 * 4.0 -> +2
	assert_eq(result[CustomerManager.KEY_RISK], 2, "risk") # 3 flat, margin 0.5 * 2.0 -> -1
	assert_eq(result[CustomerManager.KEY_RESPONSE], customer.dialogue_success, "response")


func test_evaluate_brew_batch_gives_smaller_reward_for_secondary_style() -> void:
	var customer := CustomerData.new()
	var batch := _make_batch(BeerStyle.Style.KOTIKALJA, 1.0)
	var result := customer.evaluate_brew_batch(batch)
	assert_eq(result[CustomerManager.KEY_INCOME], 3, "income") # same fixed price as any other style
	assert_eq(result[CustomerManager.KEY_TIP], 0.5, "tip") # same tip floor as above (tip is quality-driven, not style-driven)
	assert_eq(result[CustomerManager.KEY_REPUTATION], 2, "reputation") # 0 flat, margin 0.5 * 4.0 -> +2
	assert_eq(result[CustomerManager.KEY_RISK], 0, "risk") # 1 flat, margin 0.5 * 2.0 -> -1
	assert_eq(result[CustomerManager.KEY_RESPONSE], customer.dialogue_fallback, "response")


func test_evaluate_brew_batch_penalizes_wrong_style() -> void:
	var customer := CustomerData.new()
	var batch := _make_batch(BeerStyle.Style.IPA, 1.0)
	var result := customer.evaluate_brew_batch(batch)
	assert_eq(result[CustomerManager.KEY_INCOME], 3, "income") # fixed price even for a wrong-style sale
	assert_eq(result[CustomerManager.KEY_TIP], 0.5, "tip") # same tip floor as above (tip is quality-driven, not style-driven)
	assert_eq(result[CustomerManager.KEY_REPUTATION], 1, "reputation") # -1 flat, margin 0.5 * 4.0 -> +2
	assert_eq(result[CustomerManager.KEY_RISK], 1, "risk") # 2 flat, margin 0.5 * 2.0 -> -1
	assert_eq(result[CustomerManager.KEY_RESPONSE], customer.dialogue_wrong_style, "response")


func test_evaluate_brew_batch_quality_at_min_quality_matches_flat_baseline() -> void:
	# quality exactly at the min_quality bar -> margin is 0, so the result
	# should equal the old pre-quality-margin flat numbers exactly, proving
	# the new continuous adjustment doesn't shift behavior at the boundary.
	# Also proves no tip at exactly the bar — the customer got what they
	# expected, nothing more.
	var customer := CustomerData.new()
	var batch := _make_batch(BeerStyle.Style.BULKKILAGER, customer.min_quality)
	var result := customer.evaluate_brew_batch(batch)
	assert_eq(result[CustomerManager.KEY_TIP], 0, "tip")
	assert_eq(result[CustomerManager.KEY_REPUTATION], customer.rep_primary_style, "reputation")
	assert_eq(result[CustomerManager.KEY_RISK], customer.risk_primary_style, "risk")


func test_evaluate_brew_batch_masterful_quality_boosts_reputation_cuts_risk_and_pays_a_tip() -> void:
	# Well above min_quality should keep compounding the bonus/reduction,
	# not cap out at whatever the first threshold step gave.
	var customer := CustomerData.new()
	var batch := _make_batch(BeerStyle.Style.BULKKILAGER, 1.5)
	var result := customer.evaluate_brew_batch(batch)
	var margin : float = 1.5 - customer.min_quality
	var expected_income : float = maxf(0.1, snappedf(3.0, 0.1))
	var expected_proportional_tip : float = expected_income * margin * customer.quality_tip_sensitivity
	var expected_floor_tip : float = margin * CustomerData.MIN_TIP_PER_QUALITY_POINT
	var expected_tip : float = maxf(0.0, snappedf(max(expected_proportional_tip, expected_floor_tip) * customer.budget_multiplier, 0.1))
	assert_eq(result[CustomerManager.KEY_INCOME], expected_income, "income")
	assert_eq(result[CustomerManager.KEY_TIP], expected_tip, "tip")
	assert_eq(result[CustomerManager.KEY_REPUTATION], customer.rep_primary_style + roundi(margin * customer.quality_reputation_sensitivity), "reputation")
	assert_eq(result[CustomerManager.KEY_RISK], maxi(0, customer.risk_primary_style - roundi(margin * customer.quality_risk_sensitivity)), "risk")


## Demonstrates the fix for playtest_notes_2.txt's "tips round to 0 on
## cheap styles" finding: a modest margin (0.5) that the pure proportional
## formula alone would round down to 0 on a 1 EUR style now clears
## MIN_TIP_PER_QUALITY_POINT's flat floor instead.
func test_evaluate_brew_batch_tip_has_a_minimum_floor_on_cheap_styles() -> void:
	var customer := CustomerData.new()
	var batch := _make_batch(BeerStyle.Style.BULKKILAGER, 1.0)
	var result := customer.evaluate_brew_batch(batch, 1.0)
	# proportional tip = 1 * 0.5 * 0.3 = 0.15 -> would round to 0.1 (barely
	# felt) alone; floor = 0.5 * MIN_TIP_PER_QUALITY_POINT(1.0) = 0.5 wins
	assert_eq(result[CustomerManager.KEY_TIP], 0.5, "tip")


## A customer with quality_tip_sensitivity == 0.0 (see Opiskelija) never
## tips at all, even well above their own min_quality bar — proves the
## floor from the test above doesn't bypass a customer who was
## deliberately given zero tipping sensitivity.
func test_evaluate_brew_batch_zero_tip_sensitivity_never_tips_even_at_masterful_quality() -> void:
	var customer := CustomerData.new()
	customer.quality_tip_sensitivity = 0.0
	var batch := _make_batch(BeerStyle.Style.BULKKILAGER, 1.5)
	var result := customer.evaluate_brew_batch(batch)
	assert_eq(result[CustomerManager.KEY_TIP], 0.0, "tip")


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
	customer.reroll_preference([])
	assert_eq(customer.primary_style, BeerStyle.Style.IPA, "primary style should be untouched")
	assert_eq(customer.secondary_style, BeerStyle.Style.HELLES, "secondary style should be untouched")


func _make_style(style : BeerStyle.Style) -> BeerStyle:
	var beer_style := BeerStyle.new()
	beer_style.style = style
	return beer_style


func test_reroll_preference_picks_two_different_styles_from_the_pool() -> void:
	var customer := CustomerData.new()
	customer.randomizes_preference = true
	customer.primary_style = BeerStyle.Style.KOTIKALJA
	customer.secondary_style = BeerStyle.Style.KOTIKALJA
	var pool : Array[BeerStyle] = [_make_style(BeerStyle.Style.IPA), _make_style(BeerStyle.Style.HELLES)]
	customer.reroll_preference(pool)
	assert_ne(customer.primary_style, customer.secondary_style)
	assert_true(customer.primary_style in [BeerStyle.Style.IPA, BeerStyle.Style.HELLES])
	assert_true(customer.secondary_style in [BeerStyle.Style.IPA, BeerStyle.Style.HELLES])


func test_reroll_preference_keeps_styles_when_pool_is_too_small() -> void:
	var customer := CustomerData.new()
	customer.randomizes_preference = true
	customer.primary_style = BeerStyle.Style.IPA
	customer.secondary_style = BeerStyle.Style.HELLES
	var pool : Array[BeerStyle] = [_make_style(BeerStyle.Style.KOTIKALJA)]
	customer.reroll_preference(pool)
	assert_eq(customer.primary_style, BeerStyle.Style.IPA)
	assert_eq(customer.secondary_style, BeerStyle.Style.HELLES)


func test_get_preference_score_matches_primary_secondary_and_mismatch() -> void:
	var customer := CustomerData.new()
	customer.primary_style = BeerStyle.Style.IPA
	customer.secondary_style = BeerStyle.Style.HELLES
	assert_eq(customer.get_preference_score(BeerStyle.Style.IPA), 1.0, "primary style")
	assert_eq(customer.get_preference_score(BeerStyle.Style.HELLES), 0.5, "secondary style")
	assert_eq(customer.get_preference_score(BeerStyle.Style.KOTIKALJA), 0.0, "unrelated style")
