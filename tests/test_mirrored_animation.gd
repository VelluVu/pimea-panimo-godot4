@tool
extends McpTestSuite

## MirroredAnimation: hand-fixed "_mirrored" frames are played instead of flipping.


func suite_name() -> String:
	return "mirrored_animation"


func _make_sprite(with_mirrored : bool) -> AnimatedSprite2D:
	# play() ignores an animation without frames.
	var frames := SpriteFrames.new()
	frames.add_animation(&"walk_right")
	frames.add_frame(&"walk_right", PlaceholderTexture2D.new())
	if with_mirrored:
		frames.add_animation(&"walk_right_mirrored")
		frames.add_frame(&"walk_right_mirrored", PlaceholderTexture2D.new())
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	return sprite


func test_a_sheet_with_mirrored_frames_plays_them_unflipped() -> void:
	var sprite := _make_sprite(true)
	MirroredAnimation.play(sprite, &"walk_right", true)
	assert_eq(sprite.animation, &"walk_right_mirrored")
	assert_false(sprite.flip_h, "flipping would write the lettering backwards")
	sprite.free()


func test_other_sheets_are_flipped() -> void:
	var sprite := _make_sprite(false)
	MirroredAnimation.play(sprite, &"walk_right", true)
	assert_eq(sprite.animation, &"walk_right")
	assert_true(sprite.flip_h)
	sprite.free()


func test_facing_the_drawn_way_never_uses_the_mirrored_frames() -> void:
	var sprite := _make_sprite(true)
	MirroredAnimation.play(sprite, &"walk_right", false)
	assert_eq(sprite.animation, &"walk_right")
	assert_false(sprite.flip_h)
	sprite.free()


func test_base_name_drops_the_suffix() -> void:
	assert_eq(MirroredAnimation.base_name(&"walk_towards_mirrored"), &"walk_towards")
	assert_eq(MirroredAnimation.base_name(&"idle"), &"idle")
