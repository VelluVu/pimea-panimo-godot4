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


func test_place_moves_the_stack_and_template_brings_it_back() -> void:
	var parent := Control.new()
	var template := Label.new()
	template.anchor_left = 0.15
	template.anchor_right = 0.85
	template.offset_top = 42.0
	parent.add_child(template)
	var toasts := ToastStack.new(template, 0.1, 1.0, 0.1)
	var stack : Control = parent.get_node("ToastStack")

	toasts.place(0.6, 0.98, 240.0)
	assert_true(is_equal_approx(stack.anchor_left, 0.6))
	assert_true(is_equal_approx(stack.anchor_right, 0.98))
	assert_eq(stack.offset_top, 240.0)

	toasts.place_at_template()
	assert_true(is_equal_approx(stack.anchor_left, 0.15))
	assert_true(is_equal_approx(stack.anchor_right, 0.85))
	assert_eq(stack.offset_top, 42.0)
	parent.free()
