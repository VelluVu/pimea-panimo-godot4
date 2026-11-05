@tool
extends McpTestSuite

const WindowPopScript := preload("res://src/systems/toolkit/window_pop.gd")


func suite_name() -> String:
	return "window_pop"


func test_first_step_is_visible() -> void:
	assert_true(WindowPopScript.alpha_at(0) > 0.0, "The window shows from the first frame")


func test_last_step_is_opaque() -> void:
	assert_eq(WindowPopScript.alpha_at(WindowPopScript.STEPS), 1.0)


func test_steps_rise() -> void:
	for step : int in range(1, WindowPopScript.STEPS + 1):
		assert_true(WindowPopScript.alpha_at(step) > WindowPopScript.alpha_at(step - 1))
