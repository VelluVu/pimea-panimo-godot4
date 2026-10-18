@tool
extends McpTestSuite

## Unit tests for SaleEvaluation's helpers; the full evaluation is covered through
## CustomerData.evaluate_brew_batch() in test_customer_data.gd.

const SaleEvaluationScript := preload("res://src/customers/sale_evaluation.gd")


func suite_name() -> String:
	return "sale_evaluation"


func test_quality_reputation_is_capped_but_penalties_are_not() -> void:
	assert_eq(SaleEvaluationScript.quality_reputation(2.0, 4.0), SaleEvaluationScript.QUALITY_REPUTATION_BONUS_MAX)
	assert_eq(SaleEvaluationScript.quality_reputation(-2.0, 4.0), -8)


func test_refusal_costs_more_the_further_below_the_bar() -> void:
	var customer := CustomerData.new()
	customer.min_quality = 1.0
	customer.rep_bad_quality = -3
	customer.risk_bad_quality = 1
	customer.quality_reputation_sensitivity = 4.0
	customer.quality_risk_sensitivity = 2.0
	assert_eq(SaleEvaluationScript.refusal(customer, 0.95), Vector2i(-3, 1), "a near miss costs the flat penalty")
	assert_eq(SaleEvaluationScript.refusal(customer, 0.2), Vector2i(-6, 3))


func test_quality_cannot_turn_risk_into_a_reward() -> void:
	assert_eq(SaleEvaluationScript.risk_after_quality(2, 5), 0)
	assert_eq(SaleEvaluationScript.risk_after_quality(2, 1), 1)


func test_negative_flat_risk_keeps_going_past_zero() -> void:
	assert_eq(SaleEvaluationScript.risk_after_quality(-2, 1), -3)


func test_income_snaps_to_ten_cents_and_is_never_free() -> void:
	assert_eq(SaleEvaluationScript.income_for(3.14), 3.1)
	assert_eq(SaleEvaluationScript.income_for(0.0), 0.1)


func test_no_tip_at_or_below_the_bar_or_without_sensitivity() -> void:
	assert_eq(SaleEvaluationScript.tip_for(3.0, 0.0, 0.3, 1.0), 0.0)
	assert_eq(SaleEvaluationScript.tip_for(3.0, -0.2, 0.3, 1.0), 0.0)
	assert_eq(SaleEvaluationScript.tip_for(3.0, 0.5, 0.0, 1.0), 0.0)


func test_tip_is_a_share_of_the_price_with_a_capped_margin() -> void:
	# 4.0 * (0.5 + 0.5) * 0.5
	assert_eq(SaleEvaluationScript.tip_for(4.0, 0.5, 0.5, 1.0), 2.0)
	assert_eq(SaleEvaluationScript.tip_for(4.0, 1.8, 0.5, 1.0), 3.0, "a margin over TIP_MARGIN_MAX adds nothing")


func test_tip_scales_with_budget() -> void:
	assert_true(is_equal_approx(SaleEvaluationScript.tip_for(1.0, 0.5, 0.3, 2.0), 0.6))


func test_tip_chance_is_a_crit_roll() -> void:
	# 0.1 base + 0.25 margin * 0.6 + 0.15 favourite
	assert_true(is_equal_approx(SaleEvaluationScript.tip_chance(0.1, 0.25, 1.0), 0.4))
	# The margin counts only up to TIP_MARGIN_MAX, so a very low bar is no sure tip.
	assert_true(is_equal_approx(SaleEvaluationScript.tip_chance(0.1, 1.8, 1.0), 0.85))
	assert_true(is_equal_approx(SaleEvaluationScript.tip_chance(0.25, 0.25, 1.0), 0.55), "a generous customer starts higher")
	assert_true(is_equal_approx(SaleEvaluationScript.tip_chance(0.1, 0.25, 1.0, 0.15), 0.55), "perks add to the chance")
	assert_eq(SaleEvaluationScript.tip_chance(0.5, 0.5, 1.0, 0.5), SaleEvaluationScript.TIP_CHANCE_MAX)


func test_tip_chance_follows_taste() -> void:
	assert_true(is_equal_approx(SaleEvaluationScript.tip_chance(0.1, 0.25, 0.5), 0.3), "second choice: +0.05 instead of +0.15")
	assert_eq(SaleEvaluationScript.tip_chance(0.1, 0.25, 0.0), 0.0, "tried it and left: wrong style or last resort")
	assert_eq(SaleEvaluationScript.tip_chance(0.1, 0.0, 1.0), 0.0, "at the bar")


func test_discreet_risk_keeps_whole_risk_at_full_multiplier() -> void:
	assert_eq(SaleEvaluation.discreet_risk(3, 1.0, 0.99), 3)


func test_discreet_risk_rounds_the_fraction_by_its_odds() -> void:
	assert_eq(SaleEvaluation.discreet_risk(3, 0.5, 0.4), 2, "1.5: a roll under 0.5 rounds up")
	assert_eq(SaleEvaluation.discreet_risk(3, 0.5, 0.6), 1, "a roll over 0.5 rounds down")


func test_discreet_risk_leaves_calming_sales_alone() -> void:
	assert_eq(SaleEvaluation.discreet_risk(-2, 0.5, 0.0), -2)


func test_a_customer_refuses_beer_below_their_bar() -> void:
	var customer := CustomerData.new()
	customer.min_quality = 1.0
	assert_true(SaleEvaluationScript.refuses(customer, 0.9))
	assert_false(SaleEvaluationScript.refuses(customer, 1.0), "exactly at the bar is good enough")
	customer.buys_below_bar = true
	assert_false(SaleEvaluationScript.refuses(customer, 0.5), "a connoisseur buys it anyway")
