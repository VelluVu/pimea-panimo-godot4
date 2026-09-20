@tool
extends McpTestSuite

## Unit tests for BrewResolver: the pure _range_precision() math, and
## resolve_brew_style() / the cost search run against hand-built ingredients
## and styles. The resolver normally reads IngredientDatabase (an autoload
## this @tool-context test harness can't reach), so these tests inject their
## own table through BrewResolver.use_ingredients() and assign active_styles
## directly instead of going through _ready()'s load-from-disk step.


## Loaded by path (not through the BrewResolver class_name) like
## test_achievement_manager.gd does, so the suite always instantiates the
## script as it is on disk instead of the editor's cached global class.
const BrewResolverScript := preload("res://src/brewing/brew_resolver.gd")


func suite_name() -> String:
	return "brew_resolver"


const MALT_LIGHT_ID : int = 101 # EBC 10, price 2
const MALT_DARK_ID : int = 102 # EBC 60, price 3
const HOP_ID : int = 201 # alpha 100 -> 10 IBU per unit, citrus
const YEAST_ID : int = 301


func _make_ingredients() -> Dictionary:
	var light := MaltData.new()
	light.id = MALT_LIGHT_ID
	light.type = IngredientData.IngredientType.MALT
	light.ebc = 10
	light.base_price = 2

	var dark := MaltData.new()
	dark.id = MALT_DARK_ID
	dark.type = IngredientData.IngredientType.MALT
	dark.ebc = 60
	dark.base_price = 3

	var hop := HopData.new()
	hop.id = HOP_ID
	hop.type = IngredientData.IngredientType.HOP
	hop.alpha_acids = 100
	hop.beta_acids = 100
	hop.flavor_profile = HopData.FlavorProfile.CITRUS
	hop.base_price = 4

	var yeast := YeastData.new()
	yeast.id = YEAST_ID
	yeast.type = IngredientData.IngredientType.YEAST
	yeast.base_price = 5

	return {MALT_LIGHT_ID: light, MALT_DARK_ID: dark, HOP_ID: hop, YEAST_ID: yeast}


func _make_style(style : BeerStyle.Style, min_ibu : int, max_ibu : int, hop_profile : HopData.FlavorProfile = HopData.FlavorProfile.NONE) -> BeerStyle:
	var beer_style := BeerStyle.new()
	beer_style.style = style
	beer_style.required_yeast_id = YEAST_ID
	beer_style.min_malt_weight = 3
	beer_style.min_ebc = 0
	beer_style.max_ebc = 30
	beer_style.min_ibu = min_ibu
	beer_style.max_ibu = max_ibu
	beer_style.preferred_hop_profile = hop_profile
	return beer_style


func _make_resolver() -> BrewResolverScript:
	var resolver := BrewResolverScript.new()
	resolver.use_ingredients(_make_ingredients())
	var styles : Array[BeerStyle] = [
		_make_style(BeerStyle.Style.KOTIKALJA, 0, 0),
		_make_style(BeerStyle.Style.IPA, 20, 100, HopData.FlavorProfile.CITRUS),
	]
	resolver.active_styles = styles
	return resolver


func test_resolve_matches_a_hopless_style() -> void:
	var result : BrewResult = _make_resolver().resolve_brew_style({MALT_LIGHT_ID: 3, YEAST_ID: 1})
	assert_true(result.is_matched)
	assert_eq(result.beer_style.style, BeerStyle.Style.KOTIKALJA)
	assert_eq(result.final_ibu, 0)


func test_resolve_uses_hops_to_pick_the_hoppy_style() -> void:
	# 3 hop units -> alpha 300 -> IBU 30, inside IPA's window and above Kotikalja's max.
	var result : BrewResult = _make_resolver().resolve_brew_style({MALT_LIGHT_ID: 3, HOP_ID: 3, YEAST_ID: 1})
	assert_true(result.is_matched)
	assert_eq(result.beer_style.style, BeerStyle.Style.IPA)
	assert_eq(result.final_ibu, 30)
	assert_true(result.flavor_matched)


func test_resolve_rejects_too_little_malt() -> void:
	assert_eq(_make_resolver().resolve_brew_style({MALT_LIGHT_ID: 2, YEAST_ID: 1}), null)


func test_resolve_rejects_a_brew_without_yeast() -> void:
	assert_eq(_make_resolver().resolve_brew_style({MALT_LIGHT_ID: 3}), null)


func test_resolve_out_of_range_ebc_returns_the_failed_fallback() -> void:
	# 3 x dark malt -> EBC 60, outside both styles' 0..30 window.
	var result : BrewResult = _make_resolver().resolve_brew_style({MALT_DARK_ID: 3, YEAST_ID: 1})
	assert_false(result.is_matched)
	assert_eq(result.final_ebc, 60)
	assert_eq(result.reputation_change, -1)
	assert_eq(result.beer_style.style, BeerStyle.Style.KOTIKALJA)


func test_style_cost_includes_ingredients_and_flat_consumables() -> void:
	var resolver := _make_resolver()
	var cost : float = resolver.get_style_cost_per_bottle(resolver.get_beer_style(BeerStyle.Style.KOTIKALJA))
	# Malt + yeast are always paid for, so the cost must exceed the flat per-bottle extras alone.
	assert_gt(cost, BrewResolver.LABEL_ART_COST_PER_BOTTLE + BrewResolver.CONSUMABLES_COST_PER_BOTTLE)


func test_hoppy_style_costs_more_than_hopless_style() -> void:
	var resolver := _make_resolver()
	var plain : float = resolver.get_style_cost_per_bottle(resolver.get_beer_style(BeerStyle.Style.KOTIKALJA))
	var hoppy : float = resolver.get_style_cost_per_bottle(resolver.get_beer_style(BeerStyle.Style.IPA))
	assert_gt(hoppy, plain)


func test_style_needs_malt_blend_is_false_when_one_malt_fits() -> void:
	var resolver := _make_resolver()
	assert_false(resolver.style_needs_malt_blend(resolver.get_beer_style(BeerStyle.Style.KOTIKALJA)))


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
