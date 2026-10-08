@tool
extends McpTestSuite

## Unit tests for IngredientViewKeys: the amount step a key press makes.

const IngredientViewKeysScript := preload("res://src/ui/ingredient_view_keys.gd")
const SliderStepperScript := preload("res://src/systems/toolkit/slider_stepper.gd")


func suite_name() -> String:
	return "ingredient_view_keys"


func test_shift_steps_ten_at_a_time() -> void:
	assert_eq(IngredientViewKeysScript.amount_step(false), 1.0)
	assert_eq(IngredientViewKeysScript.amount_step(true), 10.0)


func test_a_shift_step_stops_at_the_slider_ends() -> void:
	var up : float = SliderStepperScript.stepped(95.0, IngredientViewKeysScript.amount_step(true), 1.0, 0.0, 99.0)
	var down : float = SliderStepperScript.stepped(4.0, -IngredientViewKeysScript.amount_step(true), 1.0, 0.0, 99.0)
	assert_eq(up, 99.0)
	assert_eq(down, 0.0)
