@tool
extends McpTestSuite

## Unit tests for CustomerLines: which of a moment's lines is said.

const CustomerLinesScript := preload("res://src/customers/customer_lines.gd")


func suite_name() -> String:
	return "customer_lines"


func test_no_alternatives_always_gives_the_main_line() -> void:
	var none : Array[String] = []
	assert_eq(CustomerLinesScript.pick("a", none, 0.99), "a")


func test_every_line_can_come_up() -> void:
	var more : Array[String] = ["b", "c"]
	assert_eq(CustomerLinesScript.pick("a", more, 0.0), "a")
	assert_eq(CustomerLinesScript.pick("a", more, 0.5), "b")
	assert_eq(CustomerLinesScript.pick("a", more, 0.9), "c")


func test_a_roll_of_one_stays_in_the_list() -> void:
	var more : Array[String] = ["b"]
	assert_eq(CustomerLinesScript.pick("a", more, 1.0), "b")
