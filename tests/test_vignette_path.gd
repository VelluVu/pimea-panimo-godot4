@tool
extends McpTestSuite


func suite_name() -> String:
	return "vignette_path"


func test_depth_scale_is_one_at_the_reference_line() -> void:
	assert_eq(VignettePath.depth_scale_factor(VignettePath.DEPTH_REFERENCE_Y), 1.0)


func test_depth_scale_shrinks_above_and_grows_below() -> void:
	var one_step: float = VignettePath.DEPTH_Y_STEP
	assert_true(is_equal_approx(VignettePath.depth_scale_factor(VignettePath.DEPTH_REFERENCE_Y - one_step), 1.0 - VignettePath.DEPTH_SCALE_PER_STEP))
	assert_true(is_equal_approx(VignettePath.depth_scale_factor(VignettePath.DEPTH_REFERENCE_Y + one_step), 1.0 + VignettePath.DEPTH_SCALE_PER_STEP))


func test_depth_scale_is_clamped() -> void:
	assert_eq(VignettePath.depth_scale_factor(-100000.0), VignettePath.DEPTH_SCALE_MIN_FACTOR)
	assert_eq(VignettePath.depth_scale_factor(100000.0), VignettePath.DEPTH_SCALE_MAX_FACTOR)


func test_segment_durations_follow_leg_lengths() -> void:
	var points := PackedVector2Array([Vector2(0, 0), Vector2(30, 0), Vector2(30, 10)])
	var durations := VignettePath.segment_durations(points, 4.0)
	assert_eq(durations.size(), 2)
	assert_true(is_equal_approx(durations[0], 3.0))
	assert_true(is_equal_approx(durations[1], 1.0))


func test_segment_durations_survive_a_zero_length_path() -> void:
	var points := PackedVector2Array([Vector2(5, 5), Vector2(5, 5)])
	var durations := VignettePath.segment_durations(points, 2.0)
	assert_eq(durations.size(), 1)
	assert_eq(durations[0], 0.0)
