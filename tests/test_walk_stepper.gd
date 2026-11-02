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


func test_floor_stride_is_half_the_foot_gap_in_screen_pixels() -> void:
	assert_eq(WalkStepperScript.floor_stride(4.0), WalkStepperScript.STRIDE_ART_PIXELS * 4.0)


func test_each_stair_takes_one_step_of_two_frames() -> void:
	var stride : float = WalkStepperScript.stair_stride(Vector2.ZERO, Vector2(0.0, 150.0), 15)
	assert_true(is_equal_approx(stride * WalkStepperScript.FRAMES_PER_STAIR * 15.0, 150.0), str(stride))
	assert_true(WalkStepperScript.stair_stride(Vector2.ZERO, Vector2(0.0, 150.0), 0) > 0.0)


func test_begin_and_end_hand_the_sprite_between_distance_and_clock() -> void:
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = SpriteFrames.new()
	sprite.sprite_frames.add_animation(&"walk_right")
	for i : int in 4:
		sprite.sprite_frames.add_frame(&"walk_right", PlaceholderTexture2D.new())
	sprite.animation = &"walk_right"
	var stepper : WalkStepper = WalkStepperScript.new()
	stepper.begin(sprite, Vector2.ZERO, 20.0)
	assert_eq(sprite.speed_scale, 0.0)
	var first : int = sprite.frame
	stepper.tick(sprite, Vector2(40.0, 0.0))
	assert_eq(sprite.frame, (first + 2) % 4)
	stepper.end(sprite)
	assert_eq(sprite.speed_scale, 1.0)
	stepper.tick(sprite, Vector2(400.0, 0.0))
	assert_eq(sprite.frame, (first + 2) % 4)
	sprite.free()
