@tool
extends McpTestSuite

## Unit tests for BrewMixture: totals from a prep table and the style-fit rules.

const BrewMixtureScript := preload("res://src/brewing/brew_mixture.gd")

const MALT_ID : int = 101 # EBC 10
const DARK_MALT_ID : int = 102 # EBC 60
const HOP_ID : int = 201 # alpha 100, beta 50
const YEAST_ID : int = 301
const SPICE_ID : int = 212
const SECOND_SPICE_ID : int = 401
const BITTERING_HOP_ID : int = 200 # alpha 100, no aroma
const PACK_MALT_ID : int = 111 # EBC 1000, sold in 100 g packs


func suite_name() -> String:
	return "brew_mixture"


func _make_ingredients() -> Dictionary:
	var malt := MaltData.new()
	malt.type = IngredientData.IngredientType.MALT
	malt.ebc = 10
	var dark := MaltData.new()
	dark.type = IngredientData.IngredientType.MALT
	dark.ebc = 60
	var hop := HopData.new()
	hop.type = IngredientData.IngredientType.HOP
	hop.alpha_acids = 100
	hop.beta_acids = 50
	hop.flavor_profile = HopData.FlavorProfile.CITRUS
	var yeast := YeastData.new()
	yeast.type = IngredientData.IngredientType.YEAST
	yeast.attentuation_percent = 75
	var pack_malt := MaltData.new()
	pack_malt.type = IngredientData.IngredientType.MALT
	pack_malt.ebc = 1000
	pack_malt.pack_grams = 100
	var spice := IngredientData.new()
	spice.type = IngredientData.IngredientType.SPICE
	var second_spice := IngredientData.new()
	second_spice.type = IngredientData.IngredientType.SPICE
	var bittering := HopData.new()
	bittering.type = IngredientData.IngredientType.HOP
	bittering.alpha_acids = 100
	return {MALT_ID: malt, DARK_MALT_ID: dark, HOP_ID: hop, YEAST_ID: yeast, SPICE_ID: spice, BITTERING_HOP_ID: bittering, PACK_MALT_ID: pack_malt, SECOND_SPICE_ID: second_spice}


func _make_mixture(contents : Dictionary) -> BrewMixtureScript:
	return BrewMixtureScript.from_contents(contents, _make_ingredients())


func _make_style(min_ebc : int, max_ebc : int, min_ibu : int, max_ibu : int) -> BeerStyle:
	var beer_style := BeerStyle.new()
	beer_style.required_yeast_id = YEAST_ID
	beer_style.min_malt_weight = 3
	beer_style.min_ebc = min_ebc
	beer_style.max_ebc = max_ebc
	beer_style.min_ibu = min_ibu
	beer_style.max_ibu = max_ibu
	return beer_style


func test_colour_follows_morey_not_a_plain_average() -> void:
	var mixture := _make_mixture({MALT_ID: 2, DARK_MALT_ID: 1, YEAST_ID: 1})
	assert_eq(mixture.malt_weight, 3.0)
	assert_eq(mixture.final_ebc, 17, "a plain average would say 27")
	assert_eq(mixture.yeast_id, YEAST_ID)


func test_totals_derive_ibu_from_alpha_acids() -> void:
	var mixture := _make_mixture({MALT_ID: 3, HOP_ID: 2, YEAST_ID: 1})
	assert_eq(mixture.final_ibu, 20)
	assert_eq(mixture.alpha_acids, 200.0)
	assert_eq(mixture.beta_acids, 100.0)
	assert_true(mixture.hop_ids.has(HOP_ID))
	assert_true(mixture.hop_profiles.has(HopData.FlavorProfile.CITRUS))


func test_zero_amounts_are_not_recorded_as_present() -> void:
	var mixture := _make_mixture({MALT_ID: 3, HOP_ID: 0, YEAST_ID: 1})
	assert_false(mixture.hop_ids.has(HOP_ID))


func test_is_brewable_needs_malt_and_yeast() -> void:
	assert_true(_make_mixture({MALT_ID: 3, YEAST_ID: 1}).is_brewable())
	assert_false(_make_mixture({MALT_ID: 2, YEAST_ID: 1}).is_brewable())
	assert_false(_make_mixture({MALT_ID: 3}).is_brewable())


func test_fits_checks_ebc_and_ibu_windows() -> void:
	var mixture := _make_mixture({MALT_ID: 3, HOP_ID: 2, YEAST_ID: 1})
	assert_true(mixture.fits(_make_style(0, 30, 10, 30)))
	assert_false(mixture.fits(_make_style(20, 30, 10, 30)), "EBC below window")
	assert_false(mixture.fits(_make_style(0, 30, 30, 60)), "IBU below window")


func test_fits_requires_matching_yeast_and_malt() -> void:
	var mixture := _make_mixture({MALT_ID: 3, YEAST_ID: 1})
	var wrong_yeast := _make_style(0, 30, 0, 0)
	wrong_yeast.required_yeast_id = 302
	assert_false(mixture.fits(wrong_yeast))
	var wants_dark := _make_style(0, 30, 0, 0)
	wants_dark.required_malt_id = DARK_MALT_ID
	assert_false(mixture.fits(wants_dark))
	var wants_light := _make_style(0, 30, 0, 0)
	wants_light.required_malt_id = MALT_ID
	assert_true(mixture.fits(wants_light))


func test_fits_requires_the_required_spice() -> void:
	var wants_spice := _make_style(0, 30, 0, 999)
	wants_spice.required_spice_ids = [SPICE_ID]
	assert_false(_make_mixture({MALT_ID: 3, YEAST_ID: 1}).fits(wants_spice), "no spice on the table")
	assert_true(_make_mixture({MALT_ID: 3, SPICE_ID: 1, YEAST_ID: 1}).fits(wants_spice))


func test_fits_requires_every_required_spice() -> void:
	var wants_two := _make_style(0, 30, 0, 999)
	wants_two.required_spice_ids = [SPICE_ID, SECOND_SPICE_ID]
	assert_false(_make_mixture({MALT_ID: 3, SPICE_ID: 1, YEAST_ID: 1}).fits(wants_two), "one of the two is missing")
	assert_true(_make_mixture({MALT_ID: 3, SPICE_ID: 1, SECOND_SPICE_ID: 1, YEAST_ID: 1}).fits(wants_two))


func test_a_hop_forward_style_needs_an_aroma_hop() -> void:
	var hop_forward := _make_style(0, 30, 0, 999)
	hop_forward.requires_aroma_hop = true
	assert_false(_make_mixture({MALT_ID: 3, BITTERING_HOP_ID: 3, YEAST_ID: 1}).fits(hop_forward), "bittering hops only")
	assert_true(_make_mixture({MALT_ID: 3, BITTERING_HOP_ID: 3, HOP_ID: 1, YEAST_ID: 1}).fits(hop_forward))
	assert_true(_make_mixture({MALT_ID: 3, BITTERING_HOP_ID: 3, YEAST_ID: 1}).fits(_make_style(0, 30, 0, 999)), "other styles do not care")


func test_spice_adds_no_bitterness() -> void:
	var mixture := _make_mixture({MALT_ID: 3, SPICE_ID: 5, YEAST_ID: 1})
	assert_eq(mixture.final_ibu, 0)
	assert_eq(mixture.hop_amount, 0)
	assert_true(mixture.spice_ids.has(SPICE_ID))


func test_packs_count_as_tenths_of_a_kilo() -> void:
	var mixture := _make_mixture({MALT_ID: 3, PACK_MALT_ID: 2, YEAST_ID: 1})
	assert_true(is_equal_approx(mixture.malt_weight, 3.2))
	assert_gt(mixture.final_ebc, 30, "200 g of roast malt darkens 3 kg a lot")


func test_abv_comes_from_the_grist_and_the_yeast() -> void:
	var mixture := _make_mixture({MALT_ID: 3, YEAST_ID: 1})
	assert_true(is_equal_approx(mixture.abv, 3.3), str(mixture.abv))
	assert_true(is_equal_approx(_make_mixture({MALT_ID: 6, YEAST_ID: 1}).abv, 6.5), "twice the malt, twice the alcohol")


func test_fits_checks_the_abv_range() -> void:
	var mixture := _make_mixture({MALT_ID: 3, YEAST_ID: 1})
	var style := _make_style(0, 30, 0, 0)
	style.min_abv = 3.3
	assert_true(mixture.fits(style), "the edge counts")
	style.min_abv = 4.0
	assert_false(mixture.fits(style))


func test_base_share_is_the_part_of_the_malt_weight() -> void:
	var mixture := _make_mixture({MALT_ID: 3, DARK_MALT_ID: 1, YEAST_ID: 1})
	assert_eq(mixture.base_share([MALT_ID]), 0.75)
	var style := _make_style(0, 999, 0, 0)
	style.base_malt_ids = [MALT_ID]
	style.min_base_share = 0.75
	assert_true(mixture.fits(style))
	style.min_base_share = 0.8
	assert_false(mixture.fits(style), "too little of the base malt")
