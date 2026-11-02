@tool
extends McpTestSuite

## WalkStepper: walk frames follow the distance moved, not the clock.

const WalkStepperScript := preload("res://src/customers/walk_stepper.gd")
const CustomerSoundsScript := preload("res://src/customers/customer_sounds.gd")


func suite_name() -> String:
	return "walk_stepper"


func test_one_frame_per_stride() -> void:
	var stepper : WalkStepper = WalkStepperScript.new()
	stepper.start(Vector2.ZERO, 20.0)
	assert_eq(stepper.advance(Vector2(12.0, 0.0)), 0)
	assert_eq(stepper.advance(Vector2(20.0, 0.0)), 1)
	assert_eq(stepper.advance(Vector2(60.0, 0.0)), 2)


func test_leftover_distance_carries_over() -> void:
	var stepper : WalkStepper = WalkStepperScript.new()
	stepper.start(Vector2.ZERO, 20.0)
	stepper.advance(Vector2(16.0, 0.0))
	assert_eq(stepper.advance(Vector2(24.0, 0.0)), 1)


func test_standing_still_holds_the_frame() -> void:
	var stepper : WalkStepper = WalkStepperScript.new()
	stepper.start(Vector2(5.0, 5.0), 20.0)
	assert_eq(stepper.advance(Vector2(5.0, 5.0)), 0)


func test_stopped_or_strideless_never_steps() -> void:
	var stepper : WalkStepper = WalkStepperScript.new()
	stepper.start(Vector2.ZERO, 20.0)
	stepper.stop()
	assert_eq(stepper.advance(Vector2(100.0, 0.0)), 0)
	stepper.start(Vector2.ZERO, 0.0)
	assert_eq(stepper.advance(Vector2(100.0, 0.0)), 0)


func test_next_frame_loops() -> void:
	assert_eq(WalkStepperScript.next_frame(3, 1, 4), 0)
	assert_eq(WalkStepperScript.next_frame(1, 2, 4), 3)
	assert_eq(WalkStepperScript.next_frame(2, 1, 0), 0)


func test_footsteps_land_on_contact_frames() -> void:
	assert_true(CustomerSoundsScript.is_contact_frame(0))
	assert_false(CustomerSoundsScript.is_contact_frame(1))
	assert_true(CustomerSoundsScript.is_contact_frame(2))
	assert_false(CustomerSoundsScript.is_contact_frame(3))
