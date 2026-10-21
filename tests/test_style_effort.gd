@tool
extends McpTestSuite

## Unit tests for StyleEffort: the effort score and tiers of the recipe book's order.

const StyleEffortScript := preload("res://src/brewing/style_effort.gd")

const MALT_ID : int = 100
const HOP_ID : int = 200
const GATED_HOP_ID : int = 202
const YEAST_ID : int = 301


func suite_name() -> String:
	return "style_effort"


func _table() -> Dictionary:
	var hop := HopData.new()
	hop.id = HOP_ID
	var gated := HopData.new()
	gated.id = GATED_HOP_ID
	gated.min_reputation = 20
	return {HOP_ID: hop, GATED_HOP_ID: gated}


func _simple_style() -> BeerStyle:
	var beer_style := BeerStyle.new()
	beer_style.reference_recipe = {MALT_ID: 4, HOP_ID: 10, YEAST_ID: 1}
	beer_style.mash_steps = [65]
	var additions : Array[HopAddition.Kind] = [HopAddition.Kind.BITTERING]
	beer_style.hop_additions = additions
	return beer_style


func test_a_simple_style_counts_its_ingredients() -> void:
	assert_eq(StyleEffortScript.score(_simple_style(), _table(), false), 3)


func test_mash_steps_and_hop_additions_add_effort() -> void:
	var beer_style := _simple_style()
	beer_style.mash_steps = [45, 63, 72]
	var additions : Array[HopAddition.Kind] = [HopAddition.Kind.BITTERING, HopAddition.Kind.AROMA]
	beer_style.hop_additions = additions
	var expected : int = 3 + 2 * StyleEffortScript.EXTRA_MASH_STEP_POINTS + StyleEffortScript.EXTRA_HOP_ADDITION_POINTS
	assert_eq(StyleEffortScript.score(beer_style, _table(), false), expected)


func test_a_style_without_hops_is_not_negative() -> void:
	var beer_style := _simple_style()
	var none : Array[HopAddition.Kind] = []
	beer_style.hop_additions = none
	assert_eq(StyleEffortScript.score(beer_style, _table(), false), 3)


func test_requirements_gated_ingredients_and_the_mash_tun_add_effort() -> void:
	var beer_style := _simple_style()
	beer_style.required_malt_id = MALT_ID
	beer_style.reference_recipe = {MALT_ID: 4, GATED_HOP_ID: 10, YEAST_ID: 1}
	var expected : int = 3 + StyleEffortScript.REQUIREMENT_POINTS + StyleEffortScript.GATED_INGREDIENT_POINTS + StyleEffortScript.MASH_UPGRADE_POINTS
	assert_eq(StyleEffortScript.score(beer_style, _table(), true), expected)


func test_tiers_split_at_their_limits() -> void:
	assert_eq(StyleEffortScript.tier(StyleEffortScript.MEDIUM_FROM - 1), StyleEffortScript.Tier.EASY)
	assert_eq(StyleEffortScript.tier(StyleEffortScript.MEDIUM_FROM), StyleEffortScript.Tier.MEDIUM)
	assert_eq(StyleEffortScript.tier(StyleEffortScript.HARD_FROM), StyleEffortScript.Tier.HARD)
