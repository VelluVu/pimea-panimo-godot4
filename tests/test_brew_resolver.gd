@tool
extends McpTestSuite

## Unit tests for BrewResolver against hand-built ingredients and styles. The
## IngredientDatabase autoload is out of reach here, so they go through use_ingredients()
## and assign active_styles directly.

## Loaded by path so the suite uses the script on disk, not the editor's cached class.
const BrewResolverScript := preload("res://src/brewing/brew_resolver.gd")


func suite_name() -> String:
	return "brew_resolver"


const MALT_LIGHT_ID : int = 101 # EBC 10, price 2
const MALT_DARK_ID : int = 102 # EBC 60, price 3
const HOP_ID : int = 201 # alpha 100 -> 10 IBU per unit, citrus
const YEAST_ID : int = 301
const ALCOHOL_FREE_YEAST_ID : int = 304


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
	yeast.attentuation_percent = 75

	var alcohol_free_yeast := YeastData.new()
	alcohol_free_yeast.id = ALCOHOL_FREE_YEAST_ID
	alcohol_free_yeast.type = IngredientData.IngredientType.YEAST
	alcohol_free_yeast.attentuation_percent = 8

	return {MALT_LIGHT_ID: light, MALT_DARK_ID: dark, HOP_ID: hop, YEAST_ID: yeast, ALCOHOL_FREE_YEAST_ID: alcohol_free_yeast}


func _make_style(style : BeerStyle.Style, min_ibu : int, max_ibu : int, hop_profile : HopData.FlavorProfile = HopData.FlavorProfile.NONE) -> BeerStyle:
	var beer_style := BeerStyle.new()
	beer_style.style = style
	beer_style.required_yeast_id = YEAST_ID
	beer_style.min_malt_weight = 3
	beer_style.min_ebc = 0
	beer_style.max_ebc = 20
	beer_style.min_ibu = min_ibu
	beer_style.max_ibu = max_ibu
	if hop_profile != HopData.FlavorProfile.NONE:
		beer_style.preferred_hop_profiles = [hop_profile]
	return beer_style


func _make_resolver() -> BrewResolverScript:
	var resolver := BrewResolverScript.new()
	resolver.use_ingredients(_make_ingredients())
	var kotikalja := _make_style(BeerStyle.Style.KOTIKALJA, 0, 0)
	kotikalja.reference_recipe = {MALT_LIGHT_ID: 3, YEAST_ID: 1}
	var ipa := _make_style(BeerStyle.Style.IPA, 20, 100, HopData.FlavorProfile.CITRUS)
	ipa.reference_recipe = {MALT_LIGHT_ID: 3, HOP_ID: 3, YEAST_ID: 1}
	var styles : Array[BeerStyle] = [kotikalja, ipa]
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
	# 3 kg of the EBC 60 malt colours the beer to EBC 30 (Morey), past both styles' 20.
	var result : BrewResult = _make_resolver().resolve_brew_style({MALT_DARK_ID: 3, YEAST_ID: 1})
	assert_false(result.is_matched)
	assert_eq(result.final_ebc, 30)
	assert_eq(result.reputation_change, -1)
	assert_eq(result.beer_style.style, BeerStyle.Style.KOTIKALJA)


func test_a_brew_gets_the_abv_of_its_grist() -> void:
	# 3 kg at extract 0.8: 33.2 gravity points; ale yeast ferments 75 % of them.
	var result : BrewResult = _make_resolver().resolve_brew_style({MALT_LIGHT_ID: 3, YEAST_ID: 1})
	assert_true(is_equal_approx(result.abv, 3.3), str(result.abv))


func test_failed_brew_with_alcohol_free_yeast_stays_alcohol_free() -> void:
	var result : BrewResult = _make_resolver().resolve_brew_style({MALT_LIGHT_ID: 3, ALCOHOL_FREE_YEAST_ID: 1})
	assert_false(result.is_matched)
	assert_eq(result.beer_style.style, BeerStyle.Style.KOTIKALJA)
	assert_true(result.abv <= BeerStyle.ALCOHOL_FREE_MAX_ABV)


func test_a_brew_outside_the_abv_range_does_not_match() -> void:
	var resolver := _make_resolver()
	resolver.get_beer_style(BeerStyle.Style.KOTIKALJA).max_abv = 3.0
	assert_false(resolver.resolve_brew_style({MALT_LIGHT_ID: 3, YEAST_ID: 1}).is_matched, "3.3 % is too strong")


func test_minimum_ingredients_are_the_reference_recipe() -> void:
	var resolver := _make_resolver()
	assert_eq(resolver.compute_minimum_ingredients(resolver.get_beer_style(BeerStyle.Style.IPA)), {MALT_LIGHT_ID: 3, HOP_ID: 3, YEAST_ID: 1})


func test_a_reference_recipe_that_brews_another_style_gives_nothing() -> void:
	var resolver := _make_resolver()
	var ipa : BeerStyle = resolver.get_beer_style(BeerStyle.Style.IPA)
	ipa.reference_recipe = {MALT_LIGHT_ID: 3, YEAST_ID: 1}
	assert_eq(resolver.compute_minimum_ingredients(ipa), {})


func test_styles_with_a_required_ingredient_are_checked_first() -> void:
	var resolver := _make_resolver()
	var wants_dark := _make_style(BeerStyle.Style.SAHTI, 0, 0)
	wants_dark.required_malt_id = MALT_DARK_ID
	var has_base := _make_style(BeerStyle.Style.HELLES, 0, 0)
	has_base.base_malt_ids = [MALT_LIGHT_ID]
	var styles : Array[BeerStyle] = [resolver.get_beer_style(BeerStyle.Style.KOTIKALJA), has_base, wants_dark]
	resolver.active_styles = styles
	resolver.prioritize_styles()
	assert_eq(resolver.active_styles.map(func(s : BeerStyle) -> BeerStyle.Style: return s.style), [BeerStyle.Style.SAHTI, BeerStyle.Style.HELLES, BeerStyle.Style.KOTIKALJA])


func test_style_cost_includes_ingredients_and_flat_consumables() -> void:
	var resolver := _make_resolver()
	var cost : float = resolver.get_style_cost_per_bottle(resolver.get_beer_style(BeerStyle.Style.KOTIKALJA))
	# Malt + yeast are always paid for, so the cost must exceed the flat per-bottle extras alone.
	assert_gt(cost, StylePricing.LABEL_ART_COST_PER_BOTTLE + StylePricing.CONSUMABLES_COST_PER_BOTTLE)


func test_hoppy_style_costs_more_than_hopless_style() -> void:
	var resolver := _make_resolver()
	var plain : float = resolver.get_style_cost_per_bottle(resolver.get_beer_style(BeerStyle.Style.KOTIKALJA))
	var hoppy : float = resolver.get_style_cost_per_bottle(resolver.get_beer_style(BeerStyle.Style.IPA))
	assert_gt(hoppy, plain)


func test_style_needs_malt_blend_is_false_when_one_malt_fits() -> void:
	var resolver := _make_resolver()
	assert_false(resolver.style_needs_malt_blend(resolver.get_beer_style(BeerStyle.Style.KOTIKALJA)))


func test_a_new_price_multiplier_drops_cached_costs() -> void:
	var resolver := _make_resolver()
	var style : BeerStyle = resolver.get_beer_style(BeerStyle.Style.KOTIKALJA)
	var full : float = resolver.get_style_cost_per_bottle(style)
	resolver.ingredient_price_multiplier = 0.5
	assert_true(resolver.get_style_cost_per_bottle(style) < full, "a cheaper shop lowers the cached cost")


func test_bars_pay_a_share_of_the_list_price_whatever_the_discount() -> void:
	var resolver := _make_resolver()
	var style : BeerStyle = resolver.get_beer_style(BeerStyle.Style.KOTIKALJA)
	style.fixed_price_per_bottle = 2.0
	var wholesale : float = resolver.get_wholesale_price_per_bottle(style)
	assert_true(is_equal_approx(wholesale, 2.0 * StylePricing.WHOLESALE_SHARE))
	resolver.ingredient_price_multiplier = 0.5
	assert_true(is_equal_approx(resolver.get_wholesale_price_per_bottle(style), wholesale), "bars pay by the beer, not the player's discount")
