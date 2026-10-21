@tool
extends McpTestSuite

## Unit tests for SliderStepper: steps stay inside the slider's range, and the knob scales
## up in whole steps.

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


func test_knob_scales_in_whole_steps_to_reach_the_size() -> void:
	assert_eq(SliderStepperScript.grabber_scale(9, 18), 2)
	assert_eq(SliderStepperScript.grabber_scale(7, 18), 3)
	assert_eq(SliderStepperScript.grabber_scale(18, 18), 1)
	assert_eq(SliderStepperScript.grabber_scale(24, 18), 1, "a big knob is never shrunk")


func test_scaled_knob_keeps_hard_pixels() -> void:
	var image := Image.create(2, 1, false, Image.FORMAT_RGBA8)
	image.set_pixel(0, 0, Color(1, 0, 0))
	image.set_pixel(1, 0, Color(0, 0, 1))
	var big : Image = SliderStepperScript.scaled(ImageTexture.create_from_image(image), 3).get_image()
	assert_eq(big.get_size(), Vector2i(6, 3))
	assert_eq(big.get_pixel(2, 2), Color(1, 0, 0))
	assert_eq(big.get_pixel(3, 0), Color(0, 0, 1))
