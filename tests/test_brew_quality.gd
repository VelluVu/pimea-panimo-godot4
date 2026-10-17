@tool
extends McpTestSuite

## Unit tests for BrewQuality: range precision, hop layers and the spice bonuses.

const BrewQualityScript := preload("res://src/brewing/brew_quality.gd")
const BrewMixtureScript := preload("res://src/brewing/brew_mixture.gd")


func suite_name() -> String:
	return "brew_quality"


func _make_mixture(alpha : float, beta : float, hop_count : int) -> BrewMixtureScript:
	var mixture := BrewMixtureScript.new()
	mixture.alpha_acids = alpha
	mixture.beta_acids = beta
	for id in hop_count:
		mixture.hop_ids[id] = true
	return mixture


func test_range_precision_is_perfect_at_center() -> void:
	assert_eq(BrewQualityScript.range_precision(20, 10, 30), 1.0)


func test_range_precision_is_zero_at_edges() -> void:
	assert_eq(BrewQualityScript.range_precision(10, 10, 30), 0.0)
	assert_eq(BrewQualityScript.range_precision(30, 10, 30), 0.0)


func test_range_precision_is_clamped_outside_range() -> void:
	assert_eq(BrewQualityScript.range_precision(5, 10, 30), 0.0)


func test_ibu_from_zero_needs_no_hops() -> void:
	assert_eq(BrewQualityScript.ibu_precision(0, 0, 10), 1.0, "no hops is as good as the middle")
	assert_eq(BrewQualityScript.ibu_precision(10, 0, 10), 0.0, "too bitter still costs")
	assert_eq(BrewQualityScript.ibu_precision(10, 10, 30), 0.0, "other styles keep the plain window")


func test_range_precision_handles_degenerate_range() -> void:
	assert_eq(BrewQualityScript.range_precision(999, 10, 10), 1.0)


## A real mixture of hops: Magnum (alpha 16, no aroma), a citrus hop and a noble hop.
func _hop_mixture(contents : Dictionary) -> BrewMixtureScript:
	var table : Dictionary = {}
	for spec : Array in [[200, 16, HopData.FlavorProfile.NONE], [203, 6, HopData.FlavorProfile.CITRUS], [201, 5, HopData.FlavorProfile.NOBLE]]:
		var hop := HopData.new()
		hop.id = spec[0]
		hop.type = IngredientData.IngredientType.HOP
		hop.alpha_acids = spec[1]
		hop.flavor_profile = spec[2]
		table[hop.id] = hop
	return BrewMixtureScript.from_contents(contents, table)


func _style(kinds : Array, profiles : Array) -> BeerStyle:
	var style := BeerStyle.new()
	style.hop_additions.assign(kinds)
	style.preferred_hop_profiles.assign(profiles)
	return style


func test_every_well_filled_layer_counts() -> void:
	var ipa : BeerStyle = _style([HopAddition.Kind.BITTERING, HopAddition.Kind.FLAVOR, HopAddition.Kind.AROMA], [HopData.FlavorProfile.CITRUS])
	assert_eq(BrewQualityScript.good_hop_layers(_hop_mixture({200: 20, 203: 40}), ipa), 3, "Magnum bitters, the citrus hop fills both late layers")
	assert_eq(BrewQualityScript.good_hop_layers(_hop_mixture({200: 20, 201: 40}), ipa), 1, "a noble hop does not suit a citrus style")
	assert_eq(BrewQualityScript.good_hop_layers(_hop_mixture({201: 60}), ipa), 0, "a noble hop neither bitters nor flavours a citrus style")


func test_a_style_can_bitter_with_its_own_aroma_hop() -> void:
	var pils : BeerStyle = _style([HopAddition.Kind.BITTERING, HopAddition.Kind.FLAVOR, HopAddition.Kind.AROMA], [HopData.FlavorProfile.NOBLE])
	var ipa : BeerStyle = _style([HopAddition.Kind.BITTERING, HopAddition.Kind.FLAVOR, HopAddition.Kind.AROMA], [HopData.FlavorProfile.CITRUS])
	assert_eq(BrewQualityScript.good_hop_layers(_hop_mixture({201: 120}), pils), 3, "an all-noble pils fills every layer")
	assert_eq(BrewQualityScript.good_hop_layers(_hop_mixture({203: 60}), ipa), 3, "an all-Cascade citrus beer bitters with Cascade")
	assert_eq(BrewQualityScript.good_hop_layers(_hop_mixture({201: 120}), ipa), 0, "but not with a hop of another flavour")


func test_the_styles_own_malts_add_quality_up_to_a_cap() -> void:
	var dunkel := BeerStyle.new()
	dunkel.preferred_malt_ids.assign([104, 113, 102])
	var mixture := BrewMixtureScript.new()
	assert_eq(BrewQualityScript.malt_bonus(mixture, dunkel), 0.0, "no character malt, no bonus")
	mixture.malt_ids[104] = true
	assert_true(is_equal_approx(BrewQualityScript.malt_bonus(mixture, dunkel), BrewQualityScript.MALT_MATCH_STEP))
	mixture.malt_ids[113] = true
	mixture.malt_ids[102] = true
	assert_true(is_equal_approx(BrewQualityScript.malt_bonus(mixture, dunkel), BrewQualityScript.MALT_MATCH_MAX), "three malts stop at the cap")
	assert_true(BrewQualityScript.multiplier(dunkel, 0.5, 0.0, false, 0.0, BrewQualityScript.MALT_MATCH_MAX) > BrewQualityScript.multiplier(dunkel, 0.5, 0.0, false), "the bonus raises the quality")


func test_a_pinch_is_not_a_layer() -> void:
	var ipa : BeerStyle = _style([HopAddition.Kind.BITTERING, HopAddition.Kind.AROMA], [HopData.FlavorProfile.CITRUS])
	assert_eq(BrewQualityScript.good_hop_layers(_hop_mixture({200: 20, 203: 2}), ipa), 1)


func test_hop_forward_styles_reward_layers_more_and_classic_ones_the_malt() -> void:
	var hoppy : BeerStyle = _style([HopAddition.Kind.BITTERING, HopAddition.Kind.FLAVOR, HopAddition.Kind.AROMA], [HopData.FlavorProfile.NOBLE])
	var classic : BeerStyle = _style([HopAddition.Kind.BITTERING, HopAddition.Kind.AROMA], [HopData.FlavorProfile.NOBLE])
	assert_true(BrewQualityScript.is_hop_forward(hoppy))
	assert_false(BrewQualityScript.is_hop_forward(classic))
	var mixture := _hop_mixture({200: 20, 201: 40})
	assert_true(is_equal_approx(BrewQualityScript.hop_layer_bonus(mixture, hoppy), 3 * BrewQualityScript.HOP_LAYER_STEP))
	assert_true(is_equal_approx(BrewQualityScript.hop_layer_bonus(mixture, classic), 2 * BrewQualityScript.CLASSIC_HOP_LAYER_STEP))
	assert_true(BrewQualityScript.multiplier(classic, 1.0, 0.0, false) > BrewQualityScript.multiplier(hoppy, 1.0, 0.0, false), "a spot-on classic grist counts for more")


func test_more_than_three_hop_varieties_fit_no_style() -> void:
	var style : BeerStyle = _style([HopAddition.Kind.BITTERING], [])
	style.required_yeast_id = BrewMixtureScript.NO_YEAST
	style.min_malt_weight = 0
	style.max_ebc = 999
	style.max_abv = 99.0
	var mixture := _hop_mixture({200: 1, 201: 1, 203: 1})
	assert_true(mixture.fits(style))
	mixture.hop_ids[999] = true
	assert_false(mixture.fits(style))


func test_multiplier_is_neutral_at_neutral_precision_without_bonuses() -> void:
	assert_true(is_equal_approx(BrewQualityScript.multiplier(BeerStyle.new(), BrewQualityScript.NEUTRAL_PRECISION, 0.0, false), 1.0))


func test_multiplier_is_clamped_and_rewards_flavor_match() -> void:
	var style := BeerStyle.new()
	assert_true(BrewQualityScript.multiplier(style, 1.0, 0.0, true) > BrewQualityScript.multiplier(style, 1.0, 0.0, false))
	assert_true(BrewQualityScript.multiplier(style, 1.0, 5.0, true) <= BrewQualityScript.MAX_MULTIPLIER)


func test_required_spice_on_the_table_counts_as_flavor_match() -> void:
	var beer_style := BeerStyle.new()
	beer_style.required_spice_ids = [212]
	var mixture := _make_mixture(0.0, 0.0, 0)
	assert_false(BrewQualityScript.flavor_matched(mixture, beer_style))
	mixture.spice_ids[212] = true
	assert_true(BrewQualityScript.flavor_matched(mixture, beer_style))


func test_spice_bonus_counts_preferred_spices_and_caps() -> void:
	var beer_style := BeerStyle.new()
	beer_style.preferred_spice_ids = [401, 402, 403]
	var mixture := _make_mixture(0.0, 0.0, 0)
	assert_eq(BrewQualityScript.spice_bonus(mixture, beer_style), 0.0)
	mixture.spice_ids[401] = true
	assert_eq(BrewQualityScript.spice_bonus(mixture, beer_style), BrewQualityScript.SPICE_MATCH_STEP)
	mixture.spice_ids[402] = true
	mixture.spice_ids[403] = true
	assert_eq(BrewQualityScript.spice_bonus(mixture, beer_style), BrewQualityScript.SPICE_MATCH_MAX)


func test_unrelated_spice_gives_no_bonus() -> void:
	var beer_style := BeerStyle.new()
	beer_style.preferred_spice_ids = [401]
	var mixture := _make_mixture(0.0, 0.0, 0)
	mixture.spice_ids[407] = true
	assert_eq(BrewQualityScript.spice_bonus(mixture, beer_style), 0.0)


func test_multiplier_adds_the_spice_bonus() -> void:
	var style := BeerStyle.new()
	var without : float = BrewQualityScript.multiplier(style, BrewQualityScript.NEUTRAL_PRECISION, 0.0, false)
	var with_spice : float = BrewQualityScript.multiplier(style, BrewQualityScript.NEUTRAL_PRECISION, 0.0, false, 0.1)
	assert_true(is_equal_approx(with_spice - without, 0.1))


func test_any_spice_breaks_the_purity_law() -> void:
	var beer_style := BeerStyle.new()
	beer_style.forbids_spices = true
	beer_style.preferred_spice_ids = [401]
	var mixture := _make_mixture(0.0, 0.0, 0)
	assert_eq(BrewQualityScript.spice_bonus(mixture, beer_style), 0.0)
	mixture.spice_ids[401] = true
	assert_eq(BrewQualityScript.spice_bonus(mixture, beer_style), -BrewQualityScript.PURITY_LAW_PENALTY)


func test_unsuited_spices_cost_quality_each() -> void:
	var beer_style := BeerStyle.new()
	beer_style.preferred_spice_ids = [401]
	beer_style.required_spice_ids = [212]
	var mixture := _make_mixture(0.0, 0.0, 0)
	mixture.spice_ids[401] = true
	mixture.spice_ids[212] = true
	assert_eq(BrewQualityScript.unsuited_spice_penalty(mixture, beer_style), 0.0, "needed and liked spices cost nothing")
	mixture.spice_ids[406] = true
	mixture.spice_ids[404] = true
	assert_eq(BrewQualityScript.unsuited_spice_penalty(mixture, beer_style), 2 * BrewQualityScript.UNSUITED_SPICE_PENALTY)


func test_a_german_style_pays_only_the_purity_law() -> void:
	var beer_style := BeerStyle.new()
	beer_style.forbids_spices = true
	var mixture := _make_mixture(0.0, 0.0, 0)
	mixture.spice_ids[406] = true
	assert_eq(BrewQualityScript.unsuited_spice_penalty(mixture, beer_style), 0.0)
	assert_eq(BrewQualityScript.spice_bonus(mixture, beer_style), -BrewQualityScript.PURITY_LAW_PENALTY)
