@tool
extends McpTestSuite

## Unit tests for SaleProcessor's static parts: the income, tip and reputation maths
## of a sale. The full process() flow
## touches BrewerySignals and a live Brewery, so it is checked in a running
## game instead. Loaded by path so the suite always runs the script as it is on
## disk.

const SaleProcessorScript := preload("res://src/customers/sale_processor.gd")


func suite_name() -> String:
	return "sale_processor"


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
	assert_false(outcome.tip_doubled)


func test_a_guaranteed_double_tip_doubles_after_the_multiplier() -> void:
	var outcome = SaleProcessorScript.calculate_sale(_results(2.0, 0.5, 0), 2, 1.5, 1.0, 1.0)
	assert_eq(outcome.tip_income, 3.0)
	assert_eq(outcome.net_income, 7.0)
	assert_true(outcome.tip_doubled)


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
