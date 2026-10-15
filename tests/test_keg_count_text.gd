@tool
extends McpTestSuite

const KegCountTextScript := preload("res://src/ui/keg_count_text.gd")


func suite_name() -> String:
	return "keg_count_text"


func test_the_line_counts_kegs_in_use() -> void:
	assert_eq(KegCountTextScript.line(2, 3, 4, 0), "Hanat 2, tynnyrit käytössä 3/4")


func test_unwashed_kegs_are_added_only_when_there_are_some() -> void:
	assert_eq(KegCountTextScript.line(3, 2, 5, 2), "Hanat 3, tynnyrit käytössä 2/5, likaisia 2")
