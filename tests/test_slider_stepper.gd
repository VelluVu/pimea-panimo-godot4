@tool
extends McpTestSuite

## Unit tests for SliderStepper: steps stay inside the slider's range, and the knob is round.

const SliderStepperScript := preload("res://src/systems/toolkit/slider_stepper.gd")


func suite_name() -> String:
	return "slider_stepper"


func test_plus_and_minus_move_one_step() -> void:
	assert_eq(SliderStepperScript.stepped(3.0, 1.0, 1.0, 0.0, 10.0), 4.0)
	assert_eq(SliderStepperScript.stepped(3.0, -1.0, 1.0, 0.0, 10.0), 2.0)


func test_steps_stop_at_the_ends() -> void:
	assert_eq(SliderStepperScript.stepped(10.0, 1.0, 1.0, 0.0, 10.0), 10.0)
	assert_eq(SliderStepperScript.stepped(0.0, -1.0, 1.0, 0.0, 10.0), 0.0)


func test_a_fractional_step_still_moves_a_whole_unit() -> void:
	assert_eq(SliderStepperScript.stepped(2.0, 1.0, 0.01, 0.0, 10.0), 3.0)


func test_grabber_is_filled_in_the_middle_and_clear_in_the_corners() -> void:
	var fill := Color(1, 0, 0)
	var outline := Color(0, 0, 1)
	var image : Image = SliderStepperScript.make_grabber(18, fill, outline).get_image()
	assert_eq(image.get_pixel(9, 9), fill)
	assert_eq(image.get_pixel(0, 0).a, 0.0)
	assert_eq(image.get_pixel(9, 1), outline)
