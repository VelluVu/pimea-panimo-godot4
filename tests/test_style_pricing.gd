@tool
extends McpTestSuite

const StylePricingScript := preload("res://src/brewing/style_pricing.gd")


func suite_name() -> String:
	return "style_pricing"


## calculate_price_breakdown(): the pure cost-plus-margin math. No tax.
func test_calculate_price_breakdown_computes_profit_and_price() -> void:
	var breakdown := StylePricingScript.calculate_price_breakdown("Testiolut", 4.0, 2.0)
	assert_eq(breakdown.style_name, "Testiolut", "style_name")
	assert_eq(breakdown.abv, 4.0, "abv") # display only
	assert_true(is_equal_approx(breakdown.raw_cost_per_bottle, 2.0), "raw_cost_per_bottle")
	# profit = 2.0 * PROFIT_MARKUP_RATE(0.5)
	assert_true(is_equal_approx(breakdown.profit_per_bottle, 1.0), "profit_per_bottle")
	assert_true(is_equal_approx(breakdown.price_per_bottle, 3.0), "price_per_bottle")


func test_calculate_price_breakdown_abv_does_not_affect_price() -> void:
	var weak := StylePricingScript.calculate_price_breakdown("Weak", 0.0, 2.0)
	var strong := StylePricingScript.calculate_price_breakdown("Strong", 10.0, 2.0)
	assert_true(is_equal_approx(weak.price_per_bottle, strong.price_per_bottle), "same raw cost should give the same price regardless of ABV")


func test_calculate_price_breakdown_applies_profit_margin_multiplier() -> void:
	var breakdown := StylePricingScript.calculate_price_breakdown("IPA", 6.5, 2.0, 1.3)
	# profit = 2.0 * 0.5 * 1.3
	assert_true(is_equal_approx(breakdown.profit_per_bottle, 1.3), "profit_per_bottle")
	assert_true(is_equal_approx(breakdown.price_per_bottle, 3.3), "price_per_bottle")


func test_calculate_price_breakdown_zero_cost_still_clears_the_profit_floor() -> void:
	var breakdown := StylePricingScript.calculate_price_breakdown("Free", 5.0, 0.0)
	# The proportional profit is 0, so the flat floor applies.
	assert_eq(breakdown.profit_per_bottle, StylePricingScript.MIN_PROFIT_PER_BOTTLE, "profit_per_bottle")
	assert_eq(breakdown.price_per_bottle, StylePricingScript.MIN_PROFIT_PER_BOTTLE, "price_per_bottle")


func test_calculate_price_breakdown_cheap_style_clears_the_profit_floor() -> void:
	# Kotikalja's real raw cost (~0.36 EUR) gives a proportional profit of a few cents.
	var breakdown := StylePricingScript.calculate_price_breakdown("Kotikalja", 2.8, 0.36)
	assert_true(is_equal_approx(breakdown.profit_per_bottle, StylePricingScript.MIN_PROFIT_PER_BOTTLE), "profit_per_bottle")
