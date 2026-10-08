@tool
extends McpTestSuite

## Unit tests for OptionStepper: steps skip disabled items, wrap around and emit item_selected.

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


func test_step_selects_and_emits_like_a_pick() -> void:
	var option := OptionButton.new()
	for item : String in ["a", "b", "c"]:
		option.add_item(item)
	option.set_item_disabled(1, true)
	option.select(0)
	var picked : Array[int] = []
	option.item_selected.connect(func(index : int) -> void: picked.append(index))
	OptionStepperScript.step(option, 1)
	assert_eq(option.selected, 2)
	assert_eq(picked, [2] as Array[int])
	option.free()
