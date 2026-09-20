@tool
extends McpTestSuite

## Unit tests for RecipeSearch: the malt and hop searches, run on hand-built
## ingredients with no autoload involved. Loaded by path so the suite always
## runs the script as it is on disk.

const RecipeSearchScript := preload("res://src/brewing/recipe_search.gd")


func suite_name() -> String:
	return "recipe_search"


func _malt(id : int, ebc : int) -> MaltData:
	var malt := MaltData.new()
	malt.id = id
	malt.type = IngredientData.IngredientType.MALT
	malt.ebc = ebc
	return malt


func _hop(id : int, alpha : int, price : int, profile : HopData.FlavorProfile = HopData.FlavorProfile.NONE) -> HopData:
	var hop := HopData.new()
	hop.id = id
	hop.type = IngredientData.IngredientType.HOP
	hop.alpha_acids = alpha
	hop.base_price = price
	hop.flavor_profile = profile
	return hop


func test_single_malt_is_used_when_its_ebc_fits() -> void:
	var malts : Array[MaltData] = [_malt(1, 10), _malt(2, 60)]
	assert_eq(RecipeSearchScript.find_malt_combo(malts, 5, 20, 3), {1: 3})


func test_first_fitting_malt_wins() -> void:
	var malts : Array[MaltData] = [_malt(1, 10), _malt(2, 12)]
	assert_eq(RecipeSearchScript.find_malt_combo(malts, 5, 20, 3), {1: 3})


func test_blend_is_found_when_no_single_malt_fits() -> void:
	# Window 30..40 sits strictly between the two malts (10 and 60).
	var malts : Array[MaltData] = [_malt(1, 10), _malt(2, 60)]
	var combo : Dictionary = RecipeSearchScript.find_malt_combo(malts, 30, 40, 3)
	assert_eq(combo.size(), 2)
	var total : int = 0
	var ebc_sum : int = 0
	for id : int in combo:
		total += combo[id]
		ebc_sum += malts[id - 1].ebc * combo[id]
	assert_true(total >= 3, "blend must reach the minimum weight")
	var average : float = float(ebc_sum) / total
	assert_true(average >= 30.0 and average <= 40.0, "blend EBC %.1f is outside 30..40" % average)


func test_blend_prefers_the_middle_of_the_window() -> void:
	# 10 and 60 in a 2:1 ratio averages 26.7; 1:1 gives exactly 35, the centre.
	var malts : Array[MaltData] = [_malt(1, 10), _malt(2, 60)]
	assert_eq(RecipeSearchScript.find_malt_combo(malts, 30, 40, 3), {1: 2, 2: 2})


func test_no_combo_when_nothing_can_reach_the_window() -> void:
	var malts : Array[MaltData] = [_malt(1, 10), _malt(2, 20)]
	assert_eq(RecipeSearchScript.find_malt_combo(malts, 90, 100, 3), {})


func test_required_malt_is_used_alone_when_it_fits() -> void:
	var malts : Array[MaltData] = [_malt(1, 10), _malt(2, 12)]
	assert_eq(RecipeSearchScript.find_malt_combo(malts, 5, 20, 3, 2), {2: 3})


func test_required_malt_is_always_part_of_a_blend() -> void:
	var malts : Array[MaltData] = [_malt(1, 10), _malt(2, 60), _malt(3, 30)]
	var combo : Dictionary = RecipeSearchScript.find_malt_combo(malts, 40, 45, 3, 2)
	assert_true(combo.has(2), "required malt 2 must be in the blend")
	assert_eq(combo.size(), 2)


func test_unknown_required_malt_gives_no_combo() -> void:
	var malts : Array[MaltData] = [_malt(1, 10)]
	assert_eq(RecipeSearchScript.find_malt_combo(malts, 5, 20, 3, 99), {})


func test_hop_dose_lands_inside_the_ibu_window() -> void:
	# alpha 100 gives 10 IBU per unit; the window centre is 30, so 3 units.
	var hops : Array[HopData] = [_hop(1, 100, 4)]
	assert_eq(RecipeSearchScript.find_hop_dose(hops, 20, 40, HopData.FlavorProfile.NONE), {1: 3})


func test_hop_dose_prefers_the_styles_flavour_profile() -> void:
	var hops : Array[HopData] = [_hop(1, 100, 4, HopData.FlavorProfile.PINE), _hop(2, 100, 4, HopData.FlavorProfile.CITRUS)]
	var dose : Dictionary = RecipeSearchScript.find_hop_dose(hops, 20, 40, HopData.FlavorProfile.CITRUS)
	assert_true(dose.has(2), "the citrus hop should be picked")


func test_hop_dose_falls_back_to_any_hop_without_a_profile_match() -> void:
	var hops : Array[HopData] = [_hop(1, 100, 4, HopData.FlavorProfile.PINE)]
	var dose : Dictionary = RecipeSearchScript.find_hop_dose(hops, 20, 40, HopData.FlavorProfile.CITRUS)
	assert_true(dose.has(1))


func test_hop_dose_is_empty_without_hops() -> void:
	var hops : Array[HopData] = []
	assert_eq(RecipeSearchScript.find_hop_dose(hops, 20, 40, HopData.FlavorProfile.NONE), {})


func test_cheapest_hop_dose_ignores_flavour_and_picks_the_lowest_cost() -> void:
	var hops : Array[HopData] = [_hop(1, 100, 10), _hop(2, 100, 3)]
	var dose : Dictionary = RecipeSearchScript.find_cheapest_hop_dose(hops, 20, 40)
	assert_true(dose.has(2), "the cheaper hop should win")
	assert_eq(dose[2], 2)


func test_cheapest_hop_dose_is_empty_when_no_whole_dose_lands_in_the_window() -> void:
	# These hops only give IBU in steps of 10, so a 25..26 window cannot be hit.
	var hops : Array[HopData] = [_hop(1, 100, 4)]
	assert_eq(RecipeSearchScript.find_cheapest_hop_dose(hops, 25, 26), {})
