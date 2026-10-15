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


## Every shipped style earns at least what its reference recipe costs (price >= 2 x cost)
## at base ingredient prices, so no fixed price undercuts the work of brewing it.
func test_shipped_fixed_prices_earn_at_least_their_cost() -> void:
	var table : Dictionary = {}
	for folder : String in ["hops", "malts", "spices", "yeasts"]:
		for data : IngredientData in ResourceFolder.load_all("res://src/resources/ingredients/%s/" % folder, IngredientData):
			table[data.id] = data
	var source := IngredientSource.new()
	source.inject(table)
	var pricing := StylePricingScript.new(source)
	for style : BeerStyle in ResourceFolder.load_all("res://src/resources/beer_styles/", BeerStyle):
		var cost : float = pricing.cost_per_bottle(style)
		assert_true(style.fixed_price_per_bottle - cost >= cost, "%s: price %.2f, cost %.2f" % [style.style_name, style.fixed_price_per_bottle, cost])
