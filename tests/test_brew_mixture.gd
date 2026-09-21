@tool
extends McpTestSuite

## Unit tests for BrewMixture: totals from a prep table and the style-fit rules.

const BrewMixtureScript := preload("res://src/brewing/brew_mixture.gd")

const MALT_ID : int = 101 # EBC 10
const DARK_MALT_ID : int = 102 # EBC 60
const HOP_ID : int = 201 # alpha 100, beta 50
const YEAST_ID : int = 301


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
	return {MALT_ID: malt, DARK_MALT_ID: dark, HOP_ID: hop, YEAST_ID: yeast}


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


func test_totals_average_ebc_by_weight() -> void:
	var mixture := _make_mixture({MALT_ID: 2, DARK_MALT_ID: 1, YEAST_ID: 1})
	assert_eq(mixture.malt_weight, 3)
	assert_eq(mixture.final_ebc, 27) # (10 * 2 + 60) / 3
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
