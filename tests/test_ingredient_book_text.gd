@tool
extends McpTestSuite

## Unit tests for IngredientBookText: the Ainekset tab's price, unlock and description lines.

const IngredientBookTextScript := preload("res://src/ui/ingredient_book_text.gd")
const IngredientDataScript := preload("res://src/brewing/ingredient_data.gd")


func suite_name() -> String:
	return "ingredient_book_text"


func _make_malt(min_reputation : int = 0) -> IngredientData:
	var malt : IngredientData = IngredientDataScript.new()
	malt.name = "Testimallas"
	malt.description = "Vaalea ja makea."
	malt.type = IngredientData.IngredientType.MALT
	malt.min_reputation = min_reputation
	return malt


func test_price_line_comes_first_with_the_unit() -> void:
	var lines : PackedStringArray = IngredientBookTextScript.lines(_make_malt(), 1.5, 0)
	assert_eq(lines[0], "Hinta: 1.50 € / kg")


func test_unlock_line_only_while_reputation_is_short() -> void:
	assert_true(IngredientBookTextScript.lines(_make_malt(20), 1.0, 5).has("Avautuu maineella 20"))
	assert_false(IngredientBookTextScript.lines(_make_malt(20), 1.0, 20).has("Avautuu maineella 20"))


func test_description_is_included() -> void:
	assert_true(IngredientBookTextScript.lines(_make_malt(), 1.0, 0).has("Vaalea ja makea."))


func test_each_type_has_its_own_header() -> void:
	assert_eq(IngredientBookTextScript.type_header(IngredientData.IngredientType.MALT), "Maltaat")
	assert_eq(IngredientBookTextScript.type_header(IngredientData.IngredientType.SPICE), "Mausteet")
