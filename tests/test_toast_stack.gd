@tool
extends McpTestSuite


func suite_name() -> String:
	return "toast_stack"


func test_hold_grows_with_text_length() -> void:
	assert_true(is_equal_approx(ToastStack.hold_seconds_for(40, 2.0, 0.05, 3.0, 7.0), 4.0))


func test_short_text_gets_the_minimum_hold() -> void:
	assert_eq(ToastStack.hold_seconds_for(5, 2.0, 0.05, 3.0, 7.0), 3.0)


func test_long_text_is_capped_at_the_maximum() -> void:
	assert_eq(ToastStack.hold_seconds_for(500, 2.0, 0.05, 3.0, 7.0), 7.0)


func test_zero_per_character_keeps_the_base_hold() -> void:
	assert_eq(ToastStack.hold_seconds_for(120, 2.0, 0.0, 0.0, INF), 2.0)
