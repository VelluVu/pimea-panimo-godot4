@tool
extends McpTestSuite

const IngredientMenuTextScript := preload("res://src/ui/ingredient_menu_text.gd")


func suite_name() -> String:
	return "ingredient_menu_text"


func test_an_ingredient_out_of_stock_shows_only_its_name() -> void:
	assert_eq(IngredientMenuTextScript.item("Pilsner-mallas", "", false), "Pilsner-mallas")


func test_the_stock_follows_the_name() -> void:
	assert_eq(IngredientMenuTextScript.item("Pilsner-mallas", "3 kg", false), "Pilsner-mallas  (3 kg)")


func test_a_needed_ingredient_gets_the_target_mark() -> void:
	assert_eq(IngredientMenuTextScript.item("Leivinhiiva", "", true), "🎯 Leivinhiiva")
	assert_eq(IngredientMenuTextScript.item("Leivinhiiva", "1 kpl", true), "🎯 Leivinhiiva  (1 kpl)")
