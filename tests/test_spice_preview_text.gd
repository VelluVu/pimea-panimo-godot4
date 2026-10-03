@tool
extends McpTestSuite

## Unit tests for SpicePreviewText: the brewing preview's spice line.

const SpicePreviewTextScript := preload("res://src/ui/spice_preview_text.gd")


func suite_name() -> String:
	return "spice_preview_text"


func test_no_bonus_gives_no_line() -> void:
	assert_eq(SpicePreviewTextScript.line(0.0), "")


func test_bonus_shows_as_plus_percent() -> void:
	var text : String = SpicePreviewTextScript.line(0.1)
	assert_true(text.contains("+10 %"))
	assert_false(text.contains("Reinheitsgebot"))


func test_penalty_names_the_purity_law() -> void:
	var text : String = SpicePreviewTextScript.line(-0.1)
	assert_true(text.contains("Reinheitsgebot"))
	assert_true(text.contains("-10 %"))
