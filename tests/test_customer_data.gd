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


func test_meets_strict_requirements_uses_the_batch_abv() -> void:
	var customer := CustomerData.new()
	customer.min_required_abv = 1.0
	var kotikalja := BeerStyle.new()
	kotikalja.abv = 2.8
	assert_true(customer.meets_strict_requirements(kotikalja))
	assert_false(customer.meets_strict_requirements(kotikalja, 0.2), "alcohol-free kotikalja is refused")


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
	assert_false(result[CustomerManager.KEY_DELIGHTED], "delighted")


func test_a_connoisseur_buys_below_the_bar_for_minus_one_and_no_tip() -> void:
	var customer := CustomerData.new()
	customer.buys_below_bar = true
	customer.min_quality = 1.1
	var result := customer.evaluate_brew_batch(_make_batch(customer.primary_style, 0.9), 3.0, 0.0)
	assert_eq(result[CustomerManager.KEY_INCOME], 3.0, "income")
	assert_eq(result[CustomerManager.KEY_TIP], 0.0, "tip")
	assert_eq(result[CustomerManager.KEY_REPUTATION], SaleEvaluation.BELOW_BAR_REPUTATION, "the favourite earns nothing below the bar")
	assert_false(result[CustomerManager.KEY_DELIGHTED], "delighted")
	assert_eq(result[CustomerManager.KEY_RESPONSE], SaleEvaluation.BELOW_BAR_LINE + QualityWishText.reject_suffix(0.9, 1.1), "response")


func test_a_connoisseur_below_the_bar_keeps_a_worse_wrong_style_penalty() -> void:
	var customer := CustomerData.new()
	customer.buys_below_bar = true
	customer.min_quality = 1.1
	customer.rep_wrong_style = -2
	var result := customer.evaluate_brew_batch(_make_batch(BeerStyle.Style.IMPERIAL_STOUT, 0.9), 3.0, 0.0)
	assert_eq(result[CustomerManager.KEY_REPUTATION], -2)


func test_evaluate_brew_batch_rewards_primary_style_match() -> void:
	var customer := CustomerData.new()
	var batch := _make_batch(BeerStyle.Style.BULKKILAGER, 1.0)
	var result := customer.evaluate_brew_batch(batch, 3.0, 0.0)
	assert_eq(result[CustomerManager.KEY_INCOME], 3, "income") # fixed price, style match doesn't change it
	assert_eq(result[CustomerManager.KEY_TIP], 0.9, "tip") # 3 * (0.5 base + 0.5 margin) * 0.3
	assert_eq(result[CustomerManager.KEY_REPUTATION], 7, "reputation") # 5 flat, margin 0.5 * 4.0 -> +2
	assert_eq(result[CustomerManager.KEY_RISK], 2, "risk") # 3 flat, margin 0.5 * 2.0 -> -1
	assert_eq(result[CustomerManager.KEY_RESPONSE], customer.dialogue_success, "response")
	assert_true(result[CustomerManager.KEY_DELIGHTED], "delighted")


func test_evaluate_brew_batch_gives_smaller_reward_for_secondary_style() -> void:
	var customer := CustomerData.new()
	var batch := _make_batch(BeerStyle.Style.KOTIKALJA, 1.0)
	var result := customer.evaluate_brew_batch(batch, 3.0, 0.0)
	assert_eq(result[CustomerManager.KEY_INCOME], 3, "income") # same fixed price as any other style
	assert_eq(result[CustomerManager.KEY_TIP], 0.9, "tip") # a second choice tips less often, not less
	assert_eq(result[CustomerManager.KEY_REPUTATION], 2, "reputation") # 0 flat, margin 0.5 * 4.0 -> +2
	assert_eq(result[CustomerManager.KEY_RISK], 0, "risk") # 1 flat, margin 0.5 * 2.0 -> -1
	assert_eq(result[CustomerManager.KEY_RESPONSE], customer.dialogue_fallback, "response")
	assert_false(result[CustomerManager.KEY_DELIGHTED], "delighted")


func test_evaluate_brew_batch_penalizes_wrong_style() -> void:
	var customer := CustomerData.new()
	var batch := _make_batch(BeerStyle.Style.IPA, 1.0)
	var result := customer.evaluate_brew_batch(batch, 3.0, 0.0)
	assert_eq(result[CustomerManager.KEY_INCOME], 3, "income") # fixed price even for a wrong-style sale
	assert_eq(result[CustomerManager.KEY_TIP], 0.0, "tip") # nobody tips for a beer they did not want
	assert_eq(result[CustomerManager.KEY_REPUTATION], -1, "reputation") # -1 flat; a well-made wrong style earns no quality bonus
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
	var result := customer.evaluate_brew_batch(batch, 3.0, 0.0)
	assert_eq(result[CustomerManager.KEY_TIP], 0, "tip")
	assert_eq(result[CustomerManager.KEY_REPUTATION], customer.rep_primary_style, "reputation")
	assert_eq(result[CustomerManager.KEY_RISK], customer.risk_primary_style, "risk")


func test_evaluate_brew_batch_masterful_quality_boosts_reputation_cuts_risk_and_pays_a_tip() -> void:
	# Well above min_quality keeps cutting risk; the reputation bonus stops at
	# QUALITY_REPUTATION_BONUS_MAX and the tip's margin at TIP_MARGIN_MAX.
	var customer := CustomerData.new()
	var batch := _make_batch(BeerStyle.Style.BULKKILAGER, 1.5)
	var result := customer.evaluate_brew_batch(batch, 3.0, 0.0)
	var margin : float = 1.5 - customer.min_quality
	var expected_income : float = maxf(0.1, snappedf(3.0, 0.1))
	var expected_tip : float = snappedf(expected_income * (SaleEvaluation.TIP_BASE_SHARE + minf(margin, SaleEvaluation.TIP_MARGIN_MAX)) * customer.quality_tip_sensitivity * customer.budget_multiplier, 0.1)
	assert_eq(result[CustomerManager.KEY_INCOME], expected_income, "income")
	assert_eq(result[CustomerManager.KEY_TIP], expected_tip, "tip")
	assert_eq(result[CustomerManager.KEY_REPUTATION], customer.rep_primary_style + SaleEvaluation.QUALITY_REPUTATION_BONUS_MAX, "reputation")
	assert_eq(result[CustomerManager.KEY_RISK], maxi(0, customer.risk_primary_style - roundi(margin * customer.quality_risk_sensitivity)), "risk")


## A cheap beer earns a small tip: the tip is a share of the price, so a 1 EUR
## Kotikalja can never tip more than the beer itself.
func test_evaluate_brew_batch_tip_follows_the_price() -> void:
	var customer := CustomerData.new()
	var batch := _make_batch(BeerStyle.Style.BULKKILAGER, 1.0)
	assert_true(is_equal_approx(customer.evaluate_brew_batch(batch, 1.0, 0.0)[CustomerManager.KEY_TIP], 0.3), "1 * (0.5 + 0.5) * 0.3")
	assert_true(is_equal_approx(customer.evaluate_brew_batch(batch, 6.0, 0.0)[CustomerManager.KEY_TIP], 1.8), "6 * (0.5 + 0.5) * 0.3")


func test_evaluate_brew_batch_tips_only_when_the_roll_hits() -> void:
	var customer := CustomerData.new()
	var batch := _make_batch(BeerStyle.Style.BULKKILAGER, 1.0)
	# Chance = 0.1 base + 0.5 margin * 0.6 + 0.15 favourite = 0.55.
	assert_gt(customer.evaluate_brew_batch(batch, 3.0, 0.54)[CustomerManager.KEY_TIP], 0.0)
	assert_eq(customer.evaluate_brew_batch(batch, 3.0, 0.55)[CustomerManager.KEY_TIP], 0.0)


## A customer with quality_tip_sensitivity == 0.0 (see Opiskelija) never
## tips at all, even well above their own min_quality bar — proves the
## floor from the test above doesn't bypass a customer who was
## deliberately given zero tipping sensitivity.
func test_evaluate_brew_batch_zero_tip_sensitivity_never_tips_even_at_masterful_quality() -> void:
	var customer := CustomerData.new()
	customer.quality_tip_sensitivity = 0.0
	var batch := _make_batch(BeerStyle.Style.BULKKILAGER, 1.5)
	var result := customer.evaluate_brew_batch(batch, 3.0, 0.0)
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


func test_also_likes_scores_like_the_secondary_without_limiting_the_menu() -> void:
	var customer := CustomerData.new()
	customer.primary_style = BeerStyle.Style.IMPERIAL_STOUT
	customer.secondary_style = BeerStyle.Style.SAHTI
	customer.also_likes = [BeerStyle.Style.BALTIC_PORTTERI]
	assert_eq(customer.get_preference_score(BeerStyle.Style.BALTIC_PORTTERI), 0.5)
	assert_eq(customer.get_preference_score(BeerStyle.Style.IPA), 0.0)
	var ipa := BeerStyle.new()
	ipa.style = BeerStyle.Style.IPA
	assert_true(customer.meets_strict_requirements(ipa), "other styles stay on the menu")


## customer.gd formats the preview line with one style name, so a missing or extra %s
## would break the counter dialogue of that customer.
func test_shipped_preview_lines_take_exactly_one_style_name() -> void:
	var customers : Array = ResourceFolder.load_all("res://src/resources/customers/", CustomerData)
	assert_true(customers.size() > 0, "no customers loaded")
	for customer : CustomerData in customers:
		assert_eq(customer.dialogue_preview_format.count("%s"), 1, "%s: dialogue_preview_format needs one %%s" % customer.customer_name)
		assert_false(customer.dialogue_nothing_available.is_empty(), "%s: dialogue_nothing_available is empty" % customer.customer_name)


func test_accepted_non_favourite_style_scores_like_the_secondary() -> void:
	var customer := CustomerData.new()
	customer.primary_style = BeerStyle.Style.MARZEN
	customer.secondary_style = BeerStyle.Style.HELLES
	customer.accepted_styles = [BeerStyle.Style.MARZEN, BeerStyle.Style.HELLES, BeerStyle.Style.HEFEWEIZEN]
	assert_eq(customer.get_preference_score(BeerStyle.Style.HEFEWEIZEN), 0.5)
	assert_eq(customer.get_preference_score(BeerStyle.Style.IPA), 0.0, "not accepted")


func test_accepted_non_favourite_style_gets_the_fallback_reaction() -> void:
	var customer := CustomerData.new()
	customer.primary_style = BeerStyle.Style.MARZEN
	customer.secondary_style = BeerStyle.Style.HELLES
	customer.accepted_styles = [BeerStyle.Style.MARZEN, BeerStyle.Style.HELLES, BeerStyle.Style.HEFEWEIZEN]
	var batch := _make_batch(BeerStyle.Style.HEFEWEIZEN, customer.min_quality)
	var results : Dictionary = customer.evaluate_brew_batch(batch)
	assert_eq(results[CustomerManager.KEY_RESPONSE], customer.dialogue_fallback)


func test_purity_law_customer_is_offended_by_a_spiced_german_beer() -> void:
	var customer := CustomerData.new()
	customer.dialogue_purity_law_broken = "Verboten!"
	var batch := _make_batch(BeerStyle.Style.BULKKILAGER, 1.5)
	batch.spice_bonus = -0.1
	var result := customer.evaluate_brew_batch(batch)
	assert_eq(result[CustomerManager.KEY_REPUTATION], customer.rep_purity_law_broken, "reputation")
	assert_eq(result[CustomerManager.KEY_TIP], 0.0, "tip")
	assert_eq(result[CustomerManager.KEY_RESPONSE], "Verboten!", "response")
	assert_false(result[CustomerManager.KEY_DELIGHTED], "delighted")


func test_customer_without_the_line_ignores_the_purity_law() -> void:
	var customer := CustomerData.new()
	var batch := _make_batch(BeerStyle.Style.BULKKILAGER, 1.0)
	batch.spice_bonus = -0.1
	assert_eq(customer.evaluate_brew_batch(batch)[CustomerManager.KEY_RESPONSE], customer.dialogue_success)


func _tier_batch(style : BeerStyle.Style, abv : float = 5.0) -> BrewBatch:
	var beer_style := BeerStyle.new()
	beer_style.style = style
	beer_style.abv = abv
	var batch := BrewBatch.new()
	batch.beer_style = beer_style
	batch.abv = abv
	return batch


func _styles_rule(styles : Array[BeerStyle.Style]) -> TasteRule:
	var rule := TasteRule.new()
	rule.styles = styles
	return rule


func _sailor() -> CustomerData:
	var customer := CustomerData.new()
	customer.favourite_rules = [_styles_rule([BeerStyle.Style.BALTIC_PORTTERI])]
	customer.second_rules = [_styles_rule([BeerStyle.Style.BALTIC_PORTTERI, BeerStyle.Style.IMPERIAL_STOUT])]
	customer.last_resort_rules = [_styles_rule([BeerStyle.Style.BULKKILAGER])]
	return customer


func test_taste_tiers_score_favourite_second_and_last_resort() -> void:
	var customer := _sailor()
	assert_eq(customer.get_batch_preference(_tier_batch(BeerStyle.Style.BALTIC_PORTTERI)), 1.0)
	assert_eq(customer.get_batch_preference(_tier_batch(BeerStyle.Style.IMPERIAL_STOUT)), 0.5)
	assert_eq(customer.get_batch_preference(_tier_batch(BeerStyle.Style.BULKKILAGER)), 0.0)
	assert_eq(customer.get_batch_preference(_tier_batch(BeerStyle.Style.IPA)), CustomerData.NOT_TO_TASTE)


func test_a_batch_outside_every_tier_is_not_accepted() -> void:
	var customer := _sailor()
	assert_true(customer.accepts_batch(_tier_batch(BeerStyle.Style.BULKKILAGER)))
	assert_false(customer.accepts_batch(_tier_batch(BeerStyle.Style.IPA)))


func test_without_tiers_the_batch_preference_follows_the_styles() -> void:
	var customer := CustomerData.new()
	customer.primary_style = BeerStyle.Style.IPA
	assert_eq(customer.get_batch_preference(_tier_batch(BeerStyle.Style.IPA)), 1.0)
	assert_true(customer.accepts_batch(_tier_batch(BeerStyle.Style.SAHTI)))


func test_a_rolled_favourite_leaves_the_rest_of_its_group_second() -> void:
	var customer := CustomerData.new()
	customer.favourite_rules = [_styles_rule([BeerStyle.Style.HELLES, BeerStyle.Style.MARZEN])]
	customer.rolls_favourite = true
	customer.roll_favourite([BeerStyle.Style.MARZEN])
	assert_eq(customer.primary_style, BeerStyle.Style.MARZEN, "only Märzen has been found")
	assert_eq(customer.get_batch_preference(_tier_batch(BeerStyle.Style.MARZEN)), 1.0)
	assert_eq(customer.get_batch_preference(_tier_batch(BeerStyle.Style.HELLES)), 0.5)


func test_roll_favourite_uses_the_whole_group_before_any_is_found() -> void:
	var customer := CustomerData.new()
	customer.favourite_rules = [_styles_rule([BeerStyle.Style.HELLES])]
	customer.rolls_favourite = true
	customer.primary_style = BeerStyle.Style.IPA
	customer.roll_favourite([])
	assert_eq(customer.primary_style, BeerStyle.Style.HELLES)


func test_roll_favourite_is_a_noop_when_disabled() -> void:
	var customer := CustomerData.new()
	customer.favourite_rules = [_styles_rule([BeerStyle.Style.HELLES])]
	customer.primary_style = BeerStyle.Style.IPA
	customer.roll_favourite([BeerStyle.Style.HELLES])
	assert_eq(customer.primary_style, BeerStyle.Style.IPA)


func test_shipped_tier_customers_load_their_rules() -> void:
	for file : String in DirAccess.get_files_at("res://src/resources/customers/"):
		if not file.ends_with(".tres"):
			continue
		var data : CustomerData = load("res://src/resources/customers/" + file)
		for rule : TasteRule in data.favourite_rules + data.second_rules + data.last_resort_rules:
			assert_true(rule != null and not rule.label.is_empty(), "%s has a broken taste rule" % file)
		if data.rolls_favourite:
			assert_false(data.favourite_rules.is_empty(), "%s rolls a favourite from no rules" % file)


func test_appearance_weight_rises_only_in_busy_season() -> void:
	var customer := CustomerData.new()
	customer.appearance_weight = 0.5
	customer.busy_season = SeasonRules.Season.BLACK_MONTH
	customer.busy_season_weight = 3.0
	assert_eq(customer.get_appearance_weight(SeasonRules.Season.NONE), 0.5)
	assert_eq(customer.get_appearance_weight(SeasonRules.Season.HALLOWEEN), 0.5)
	assert_eq(customer.get_appearance_weight(SeasonRules.Season.BLACK_MONTH), 3.0)
	assert_eq(customer.get_appearance_weight(SeasonRules.Season.CYBER_WEEK), 3.0)


func test_appearance_weight_defaults_to_one() -> void:
	assert_eq(CustomerData.new().get_appearance_weight(SeasonRules.Season.BLACK_MONTH), 1.0)


## Kyborgi: never out of season, so it is not announced or walked in then either.
func test_a_season_only_customer_comes_only_in_its_season() -> void:
	var customer := CustomerData.new()
	customer.appearance_weight = 0.0
	customer.busy_season = SeasonRules.Season.CYBER_WEEK
	customer.busy_season_weight = 3.0
	assert_false(customer.comes_in(SeasonRules.Season.NONE))
	assert_false(customer.comes_in(SeasonRules.Season.BLACK_MONTH))
	assert_true(customer.comes_in(SeasonRules.Season.CYBER_WEEK))
	assert_true(CustomerData.new().comes_in(SeasonRules.Season.HALLOWEEN))


## Met in their season once, they drop by rarely all year in later runs.
func test_a_met_season_customer_returns_rarely_after_its_season() -> void:
	var customer := CustomerData.new()
	customer.appearance_weight = 0.0
	customer.busy_season = SeasonRules.Season.BLACK_MONTH
	customer.busy_season_weight = 3.0
	customer.after_season_weight = 0.2
	assert_eq(customer.get_appearance_weight(SeasonRules.Season.NONE, false), 0.0)
	assert_eq(customer.get_appearance_weight(SeasonRules.Season.NONE, true), 0.2)
	assert_eq(customer.get_appearance_weight(SeasonRules.Season.HALLOWEEN, true), 0.2)
	assert_eq(customer.get_appearance_weight(SeasonRules.Season.BLACK_MONTH, true), 3.0)
	assert_false(customer.comes_in(SeasonRules.Season.HALLOWEEN))
	assert_true(customer.comes_in(SeasonRules.Season.HALLOWEEN, true))


## customer.gd plays outburst_animation by name, so the customer's sheet must have it.
func test_an_outburst_animation_is_in_the_customers_sprite_frames() -> void:
	for customer : CustomerData in ResourceFolder.load_all("res://src/resources/customers/", CustomerData):
		if customer.outburst_animation == &"":
			continue
		assert_true(customer.sprite_frames.has_animation(customer.outburst_animation), "%s has no %s animation" % [customer.title, customer.outburst_animation])
		assert_false(customer.sprite_frames.get_animation_loop(customer.outburst_animation), "%s's outburst must play once" % customer.title)
