@tool
extends McpTestSuite

const SaveSummaryTextScript := preload("res://src/ui/text/save_summary_text.gd")


func suite_name() -> String:
	return "save_summary_text"


func test_the_line_has_the_day_and_the_money() -> void:
	assert_eq(SaveSummaryTextScript.line(4, 120.0), "Päivä 4 · 120,00 €")
