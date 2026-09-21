@tool
extends McpTestSuite

const StylePricingScript := preload("res://src/brewing/style_pricing.gd")


func suite_name() -> String:
	return "style_pricing"


## Unit tests for StylePricing.calculate_price_breakdown(): the pure cost-plus-margin math.
## No tax: price is raw cost plus profit.
func test_calculate_price_breakdown_computes_profit_and_price() -> void:
	var breakdown := StylePricingScript.calculate_price_breakdown("Testiolut", 4.0, 2.0)
	assert_eq(breakdown.style_name, "Testiolut", "style_name")
	assert_eq(breakdown.abv, 4.0, "abv") # carried through for display only, doesn't affect price
	assert_true(is_equal_approx(breakdown.raw_cost_per_bottle, 2.0), "raw_cost_per_bottle")
	# profit = raw_cost * PROFIT_MARKUP_RATE(0.5) * multiplier(1.0 default) = 1.0
	assert_true(is_equal_approx(breakdown.profit_per_bottle, 1.0), "profit_per_bottle")
	# price = raw_cost + profit
	assert_true(is_equal_approx(breakdown.price_per_bottle, 3.0), "price_per_bottle")


func test_calculate_price_breakdown_abv_does_not_affect_price() -> void:
	var weak := StylePricingScript.calculate_price_breakdown("Weak", 0.0, 2.0)
	var strong := StylePricingScript.calculate_price_breakdown("Strong", 10.0, 2.0)
	assert_true(is_equal_approx(weak.price_per_bottle, strong.price_per_bottle), "same raw cost should give the same price regardless of ABV")


func test_calculate_price_breakdown_applies_profit_margin_multiplier() -> void:
	var breakdown := StylePricingScript.calculate_price_breakdown("IPA", 6.5, 2.0, 1.3)
	# profit = raw_cost(2.0) * PROFIT_MARKUP_RATE(0.5) * multiplier(1.3) = 1.3
	assert_true(is_equal_approx(breakdown.profit_per_bottle, 1.3), "profit_per_bottle")
	assert_true(is_equal_approx(breakdown.price_per_bottle, 3.3), "price_per_bottle")


func test_calculate_price_breakdown_zero_cost_still_clears_the_profit_floor() -> void:
	var breakdown := StylePricingScript.calculate_price_breakdown("Free", 5.0, 0.0)
	# proportional profit is 0, but MIN_PROFIT_PER_BOTTLE still applies —
	# no style should ever carry a near-nothing "kate".
	assert_eq(breakdown.profit_per_bottle, StylePricingScript.MIN_PROFIT_PER_BOTTLE, "profit_per_bottle")
	assert_eq(breakdown.price_per_bottle, StylePricingScript.MIN_PROFIT_PER_BOTTLE, "price_per_bottle")


func test_calculate_price_breakdown_cheap_style_clears_the_profit_floor() -> void:
	# Demonstrates the actual motivating case: Kotikalja's real raw cost
	# (~0.36 EUR) makes for a proportional profit of a few cents — the flat
	# floor should win instead.
	var breakdown := StylePricingScript.calculate_price_breakdown("Kotikalja", 2.8, 0.36)
	assert_true(is_equal_approx(breakdown.profit_per_bottle, StylePricingScript.MIN_PROFIT_PER_BOTTLE), "profit_per_bottle")
