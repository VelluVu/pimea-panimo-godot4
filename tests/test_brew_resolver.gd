@tool
extends McpTestSuite

## Unit tests for BrewResolver's pure _range_precision() math.
##
## resolve_brew_style() itself is NOT covered here: it reaches directly into
## IngredientDatabase.database (a static var populated by the autoload's own
## lifecycle), which this @tool-context test harness cannot access — the
## same limitation as BrewEngine.current_brewery in test_customer_data.gd.
## Only autoload constants and plain Resource/RefCounted logic are testable
## this way. Covering resolve_brew_style() would need either refactoring it
## to accept ingredient data as a parameter instead of reaching into the
## autoload directly, or testing it via game_eval against a running game
## instead of this suite.


func suite_name() -> String:
	return "brew_resolver"


func test_range_precision_is_perfect_at_center() -> void:
	var resolver := BrewResolver.new()
	assert_eq(resolver._range_precision(20, 10, 30), 1.0)


func test_range_precision_is_zero_at_edges() -> void:
	var resolver := BrewResolver.new()
	assert_eq(resolver._range_precision(10, 10, 30), 0.0)
	assert_eq(resolver._range_precision(30, 10, 30), 0.0)


func test_range_precision_is_clamped_outside_range() -> void:
	var resolver := BrewResolver.new()
	assert_eq(resolver._range_precision(5, 10, 30), 0.0)


func test_range_precision_handles_degenerate_range() -> void:
	var resolver := BrewResolver.new()
	assert_eq(resolver._range_precision(999, 10, 10), 1.0)


## Unit tests for BrewResolver.calculate_price_breakdown() — the pure
## cost-plus-margin math, deliberately kept independent of
## IngredientDatabase (see its docstring) so it's testable here. No
## excise/VAT: this cellar operation doesn't remit anything to the state,
## so price is just raw_cost + profit — see the function's own docstring.
func test_calculate_price_breakdown_computes_profit_and_price() -> void:
	var breakdown := BrewResolver.calculate_price_breakdown("Testiolut", 4.0, 2.0)
	assert_eq(breakdown.style_name, "Testiolut", "style_name")
	assert_eq(breakdown.abv, 4.0, "abv") # carried through for display only, doesn't affect price
	assert_true(is_equal_approx(breakdown.raw_cost_per_bottle, 2.0), "raw_cost_per_bottle")
	# profit = raw_cost * PROFIT_MARKUP_RATE(0.5) * multiplier(1.0 default) = 1.0
	assert_true(is_equal_approx(breakdown.profit_per_bottle, 1.0), "profit_per_bottle")
	# price = raw_cost + profit
	assert_true(is_equal_approx(breakdown.price_per_bottle, 3.0), "price_per_bottle")


func test_calculate_price_breakdown_abv_does_not_affect_price() -> void:
	var weak := BrewResolver.calculate_price_breakdown("Weak", 0.0, 2.0)
	var strong := BrewResolver.calculate_price_breakdown("Strong", 10.0, 2.0)
	assert_true(is_equal_approx(weak.price_per_bottle, strong.price_per_bottle), "same raw cost should give the same price regardless of ABV")


func test_calculate_price_breakdown_applies_profit_margin_multiplier() -> void:
	var breakdown := BrewResolver.calculate_price_breakdown("IPA", 6.5, 2.0, 1.3)
	# profit = raw_cost(2.0) * PROFIT_MARKUP_RATE(0.5) * multiplier(1.3) = 1.3
	assert_true(is_equal_approx(breakdown.profit_per_bottle, 1.3), "profit_per_bottle")
	assert_true(is_equal_approx(breakdown.price_per_bottle, 3.3), "price_per_bottle")


func test_calculate_price_breakdown_zero_cost_still_clears_the_profit_floor() -> void:
	var breakdown := BrewResolver.calculate_price_breakdown("Free", 5.0, 0.0)
	# proportional profit is 0, but MIN_PROFIT_PER_BOTTLE still applies —
	# no style should ever carry a near-nothing "kate".
	assert_eq(breakdown.profit_per_bottle, BrewResolver.MIN_PROFIT_PER_BOTTLE, "profit_per_bottle")
	assert_eq(breakdown.price_per_bottle, BrewResolver.MIN_PROFIT_PER_BOTTLE, "price_per_bottle")


func test_calculate_price_breakdown_cheap_style_clears_the_profit_floor() -> void:
	# Demonstrates the actual motivating case: Kotikalja's real raw cost
	# (~0.36 EUR) makes for a proportional profit of a few cents — the flat
	# floor should win instead.
	var breakdown := BrewResolver.calculate_price_breakdown("Kotikalja", 2.8, 0.36)
	assert_true(is_equal_approx(breakdown.profit_per_bottle, BrewResolver.MIN_PROFIT_PER_BOTTLE), "profit_per_bottle")
