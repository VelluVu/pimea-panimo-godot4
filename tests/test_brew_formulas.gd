@tool
extends McpTestSuite

## Unit tests for BrewFormulas: colour, gravity and ABV of one 20 L keg.

const BrewFormulasScript := preload("res://src/brewing/brew_formulas.gd")


func suite_name() -> String:
	return "brew_formulas"


func _ebc(grist : Dictionary) -> int:
	var units : float = 0.0
	for ebc : int in grist:
		units += BrewFormulasScript.malt_color_units(grist[ebc], ebc)
	return roundi(BrewFormulasScript.ebc_from_color_units(units))


func test_four_kilos_of_pilsner_is_a_pale_lager() -> void:
	assert_eq(_ebc({3: 4.0}), 6)


func test_a_little_roast_malt_goes_a_long_way() -> void:
	# 4 kg pale ale malt and 500 g roasted barley: a dry stout's black.
	var ebc : int = _ebc({6: 4.0, 1400: 0.5})
	assert_true(ebc >= 60 and ebc <= 90, "EBC %d" % ebc)


func test_no_malt_has_no_colour() -> void:
	assert_eq(BrewFormulasScript.ebc_from_color_units(0.0), 0.0)


func test_sugar_dissolves_fully_while_malt_is_mashed() -> void:
	var malt : float = BrewFormulasScript.gravity_points(1.0, 0.8, false)
	var sugar : float = BrewFormulasScript.gravity_points(1.0, 0.8, true)
	assert_true(is_equal_approx(sugar * BrewFormulasScript.MASH_EFFICIENCY, malt))


func test_five_kilos_of_ale_malt_make_about_five_percent() -> void:
	var points : float = BrewFormulasScript.gravity_points(5.0, 0.8, false)
	assert_eq(snappedf(BrewFormulasScript.abv(points, 75.0), 0.1), 5.4)


func test_an_alcohol_free_yeast_stays_under_half_a_percent() -> void:
	var points : float = BrewFormulasScript.gravity_points(3.0, 0.8, false)
	assert_true(BrewFormulasScript.abv(points, 8.0) <= 0.5)
