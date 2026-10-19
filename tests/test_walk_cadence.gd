@tool
extends McpTestSuite

## WalkCadence: the walk animation's pace follows the walk speed, one stride per frame.

const WalkCadenceScript := preload("res://src/customers/walk_cadence.gd")


func suite_name() -> String:
	return "walk_cadence"


func test_each_frame_moves_one_stride_of_art_pixels() -> void:
	var scale : float = WalkCadenceScript.speed_scale(120.0, 6.0, 4.0)
	var pixels_per_frame : float = 120.0 / (6.0 * scale)
	assert_true(is_equal_approx(pixels_per_frame / 4.0, WalkCadenceScript.STRIDE_ART_PIXELS))


func test_faster_walkers_step_faster() -> void:
	assert_true(WalkCadenceScript.speed_scale(160.0, 6.0, 4.0) > WalkCadenceScript.speed_scale(120.0, 6.0, 4.0))


func test_missing_data_keeps_the_sheet_pace() -> void:
	assert_eq(WalkCadenceScript.speed_scale(120.0, 0.0, 4.0), 1.0)
	assert_eq(WalkCadenceScript.speed_scale(0.0, 6.0, 4.0), 1.0)


func test_non_walk_animations_keep_the_sheet_pace() -> void:
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = SpriteFrames.new()
	sprite.sprite_frames.add_animation(&"walk_right")
	sprite.sprite_frames.set_animation_speed(&"walk_right", 6.0)
	sprite.scale = Vector2(4, 4)
	var walks : Array[StringName] = [&"walk_right"]
	assert_eq(WalkCadenceScript.for_sprite(sprite, 120.0, walks), 1.0)
	sprite.animation = &"walk_right"
	assert_true(is_equal_approx(WalkCadenceScript.for_sprite(sprite, 120.0, walks), 120.0 / 72.0))
	sprite.free()
