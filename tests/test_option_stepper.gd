@tool
extends McpTestSuite

## Unit tests for OptionStepper.next_index: steps skip disabled items and wrap around.

const OptionStepperScript := preload("res://src/systems/toolkit/option_stepper.gd")


func suite_name() -> String:
	return "option_stepper"


func test_next_and_previous_move_one_item() -> void:
	var disabled : Array[bool] = [false, false, false]
	assert_eq(OptionStepperScript.next_index(1, 1, disabled), 2)
	assert_eq(OptionStepperScript.next_index(1, -1, disabled), 0)


func test_steps_wrap_around_the_ends() -> void:
	var disabled : Array[bool] = [false, false, false]
	assert_eq(OptionStepperScript.next_index(2, 1, disabled), 0)
	assert_eq(OptionStepperScript.next_index(0, -1, disabled), 2)


func test_disabled_items_are_skipped() -> void:
	var disabled : Array[bool] = [false, true, true, false]
	assert_eq(OptionStepperScript.next_index(0, 1, disabled), 3)
	assert_eq(OptionStepperScript.next_index(3, -1, disabled), 0)


func test_no_other_enabled_item_stays_put() -> void:
	var disabled : Array[bool] = [true, false, true]
	assert_eq(OptionStepperScript.next_index(1, 1, disabled), 1)
