extends McpTestSuite

const LayoutScript := preload("res://src/ui/pennant_layout.gd")


func suite_name() -> String:
	return "pennant_layout"


func test_a_pennant_per_letter_and_a_narrow_gap_for_a_space() -> void:
	assert_eq(LayoutScript.slots("AB C"), [[0, "A"], [8, "B"], [8 + 7 + 1 + 4, "C"]])


func test_the_width_ends_at_the_last_pennant() -> void:
	assert_eq(LayoutScript.width("AB"), 15)
	assert_eq(LayoutScript.width(""), 0)


func test_the_string_sags_in_the_middle_and_not_at_the_ends() -> void:
	assert_eq(LayoutScript.sag(0, 100), 0)
	assert_eq(LayoutScript.sag(99, 100), 0)
	assert_eq(LayoutScript.sag(50, 100), 2)
