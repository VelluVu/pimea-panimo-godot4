@tool
extends McpTestSuite

## Unit tests for RecipeLibraryText: what a known and a locked style row reveal.

const RecipeLibraryTextScript := preload("res://src/ui/recipe_library_text.gd")


func suite_name() -> String:
	return "recipe_library_text"


func _make_style() -> BeerStyle:
	var beer_style := BeerStyle.new()
	beer_style.style_name = "Testiolut"
	beer_style.abv = 4.5
	beer_style.min_ebc = 11
	beer_style.max_ebc = 14
	beer_style.min_ibu = 14
	beer_style.max_ibu = 20
	beer_style.min_malt_weight = 3
	return beer_style


func test_known_row_shows_the_name_abv_and_exact_ranges() -> void:
	var text : String = RecipeLibraryTextScript.known_row(_make_style(), "Lagerhiiva", "")
	assert_true(text.begins_with("Testiolut (4.5% ABV), EBC 11-14, IBU 14-20"))
	assert_true(text.contains("Lagerhiiva"))


func test_known_row_adds_hop_and_malt_hints_only_when_the_style_has_them() -> void:
	var plain : String = RecipeLibraryTextScript.known_row(_make_style(), "Y", "Vehnämallas")
	assert_false(plain.contains("Suosikkihumala"))
	assert_false(plain.contains("Vaadittu mallas"), "no required malt id, so the name is ignored")

	var beer_style := _make_style()
	beer_style.preferred_hop_profile = HopData.FlavorProfile.CITRUS
	beer_style.required_malt_id = 103
	var hinted : String = RecipeLibraryTextScript.known_row(beer_style, "Y", "Vehnämallas")
	assert_true(hinted.contains("Suosikkihumala"))
	assert_true(hinted.contains("Vaadittu mallas: Vehnämallas"))


func test_locked_row_withholds_the_exact_ranges() -> void:
	var text : String = RecipeLibraryTextScript.locked_row(_make_style(), "Lagerhiiva", "", false)
	assert_true(text.begins_with("??? (4.5% ABV)"))
	assert_true(text.contains("vähintään 3 kg mallasta"))
	assert_false(text.contains("EBC"), "the exact EBC range must stay hidden")
	assert_false(text.contains("14-20"), "the exact IBU range must stay hidden")


func test_locked_row_gives_color_and_bitterness_buckets() -> void:
	var text : String = RecipeLibraryTextScript.locked_row(_make_style(), "Y", "", false)
	assert_true(text.contains("Väri: %s" % BeerStyle.get_color_hint(11, 14)))
	assert_true(text.contains("Katkeruus: %s" % BeerStyle.get_bitterness_hint(14, 20)))


func test_locked_row_mentions_a_malt_blend_only_without_a_required_malt() -> void:
	var beer_style := _make_style()
	assert_true(RecipeLibraryTextScript.locked_row(beer_style, "Y", "", true).contains("Vaatii mallasseoksen"))
	assert_false(RecipeLibraryTextScript.locked_row(beer_style, "Y", "", false).contains("Vaatii mallasseoksen"))

	beer_style.required_malt_id = 103
	var text : String = RecipeLibraryTextScript.locked_row(beer_style, "Y", "Vehnämallas", true)
	assert_false(text.contains("Vaatii mallasseoksen"), "a single required malt replaces the blend hint")
	assert_true(text.contains("Vaadittu mallas: Vehnämallas"))
