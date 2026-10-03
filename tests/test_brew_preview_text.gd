@tool
extends McpTestSuite

## Unit tests for BrewPreviewText: the brewing table's live preview line.

const BrewPreviewTextScript := preload("res://src/ui/brew_preview_text.gd")


func suite_name() -> String:
	return "brew_preview_text"


func _result(matched : bool) -> BrewResult:
	var result := BrewResult.new()
	result.is_matched = matched
	result.final_ebc = 12
	result.final_ibu = 15
	result.original_quality = 1.2
	var beer_style := BeerStyle.new()
	beer_style.style_name = "Witbier"
	result.beer_style = beer_style
	return result


func test_empty_table_asks_for_ingredients() -> void:
	assert_eq(BrewPreviewTextScript.text(true, null, false), BrewPreviewTextScript.EMPTY_TEXT)


func test_unbrewable_table_names_the_minimum() -> void:
	assert_eq(BrewPreviewTextScript.text(false, null, false), BrewPreviewTextScript.NOT_ENOUGH_TEXT)


func test_no_match_shows_the_numbers() -> void:
	var text : String = BrewPreviewTextScript.text(false, _result(false), false)
	assert_true(text.contains("Ei täsmää") and text.contains("EBC 12") and text.contains("IBU 15"))


func test_unknown_style_keeps_its_name_secret() -> void:
	var text : String = BrewPreviewTextScript.text(false, _result(true), false)
	assert_true(text.contains("tuntematon"))
	assert_false(text.contains("Witbier"))


func test_known_style_shows_name_quality_and_spices() -> void:
	var result := _result(true)
	result.spice_bonus = 0.1
	var text : String = BrewPreviewTextScript.text(false, result, true)
	assert_true(text.contains("Witbier") and text.contains("laatu 120%"))
	assert_true(text.contains("Mausteet: +10 %"))
