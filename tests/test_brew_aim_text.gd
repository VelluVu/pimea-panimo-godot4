@tool
extends McpTestSuite

## Unit tests for BrewAimText: the preview's hint towards the style's centre.

const BrewAimTextScript := preload("res://src/ui/brew_aim_text.gd")


func suite_name() -> String:
	return "brew_aim_text"


## A Bulkkilager-like window: EBC 4-8, IBU 10-25, ABV 3.9-5.5, a noble hop preferred.
func _preview(ebc : int, ibu : int, abv : float, flavor_matched : bool = true) -> BrewResult:
	var beer_style := BeerStyle.new()
	beer_style.min_ebc = 4
	beer_style.max_ebc = 8
	beer_style.min_ibu = 10
	beer_style.max_ibu = 25
	beer_style.min_abv = 3.9
	beer_style.max_abv = 5.5
	beer_style.preferred_hop_profiles.assign([HopData.FlavorProfile.NOBLE])
	var result := BrewResult.new()
	result.beer_style = beer_style
	result.final_ebc = ebc
	result.final_ibu = ibu
	result.abv = abv
	result.flavor_matched = flavor_matched
	return result


func test_a_centred_recipe_gets_no_hint() -> void:
	assert_eq(BrewAimTextScript.lines(_preview(6, 18, 4.7)), "")


func test_only_the_values_far_from_the_centre_are_named() -> void:
	var text : String = BrewAimTextScript.lines(_preview(6, 10, 4.7))
	assert_true(text.contains("Tyylin keskikohta: IBU 18"))
	assert_false(text.contains("EBC"))
	assert_false(text.contains("ABV"))


func test_every_far_value_is_listed() -> void:
	var text : String = BrewAimTextScript.lines(_preview(8, 25, 5.5))
	assert_true(text.contains("EBC 6, IBU 18, 4.7 % ABV"))


func test_a_missing_style_flavour_is_named() -> void:
	assert_true(BrewAimTextScript.lines(_preview(6, 18, 4.7, false)).contains("puuttuu: -10 %"))


func test_a_style_without_a_flavour_never_asks_for_one() -> void:
	var preview : BrewResult = _preview(6, 18, 4.7, false)
	preview.beer_style.preferred_hop_profiles.clear()
	assert_eq(BrewAimTextScript.lines(preview), "")
