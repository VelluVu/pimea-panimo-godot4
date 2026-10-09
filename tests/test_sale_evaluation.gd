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


func test_tip_floor_wins_on_cheap_styles() -> void:
	# proportional 1.0 * 0.5 * 0.3 = 0.15, floor 0.5 * 1.0 = 0.5
	assert_eq(SaleEvaluationScript.tip_for(1.0, 0.5, 0.3, 1.0), 0.5)


func test_tip_scales_with_budget() -> void:
	assert_eq(SaleEvaluationScript.tip_for(1.0, 0.5, 0.3, 2.0), 1.0)


func test_discreet_risk_keeps_whole_risk_at_full_multiplier() -> void:
	assert_eq(SaleEvaluation.discreet_risk(3, 1.0, 0.99), 3)


func test_discreet_risk_rounds_the_fraction_by_its_odds() -> void:
	assert_eq(SaleEvaluation.discreet_risk(3, 0.5, 0.4), 2, "1.5: a roll under 0.5 rounds up")
	assert_eq(SaleEvaluation.discreet_risk(3, 0.5, 0.6), 1, "a roll over 0.5 rounds down")


func test_discreet_risk_leaves_calming_sales_alone() -> void:
	assert_eq(SaleEvaluation.discreet_risk(-2, 0.5, 0.0), -2)
