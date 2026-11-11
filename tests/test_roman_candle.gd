extends McpTestSuite

const ShotsScript := preload("res://src/customers/effects/roman_candle_shots.gd")
const StarScript := preload("res://src/customers/effects/roman_candle_star.gd")


func suite_name() -> String:
	return "roman_candle"


func test_the_mouth_rises_with_the_bob_and_the_pumped_fist() -> void:
	assert_eq(ShotsScript.mouth_raise(&"idle", 1, 0, false), 1)
	assert_eq(ShotsScript.mouth_raise(&"walk_towards", 1, 0, false), 2, "left fist pumped on a lifted step")
	assert_eq(ShotsScript.mouth_raise(&"walk_towards", 1, 1, false), 1)


func test_a_mirrored_walk_swaps_the_fists() -> void:
	assert_eq(ShotsScript.mouth_raise(&"walk_right", 1, 1, true), 2)
	assert_eq(ShotsScript.mouth_raise(&"walk_right", 3, 0, true), 2)


func test_an_unknown_frame_stays_at_rest() -> void:
	assert_eq(ShotsScript.mouth_raise(&"burst_out", 0, 0, false), 0)
	assert_eq(ShotsScript.mouth_raise(&"idle", 9, 0, false), 0)


func test_the_star_climbs_whole_pixels_and_slows_at_the_top() -> void:
	assert_eq(StarScript.flight_pixel(0.0, 20, 3), Vector2i.ZERO)
	assert_eq(StarScript.flight_pixel(1.0, 20, 3), Vector2i(3, -20))
	var first_half : int = -StarScript.flight_pixel(0.5, 20, 0).y
	assert_true(first_half > 10, "more than half the climb in the first half: %d" % first_half)


func test_the_burst_is_eight_sparks_clear_of_the_ball() -> void:
	for reach : int in range(1, 4):
		var sparks : Array[Vector2i] = StarScript.burst_sparks(reach)
		assert_eq(sparks.size(), 8)
		for spark : Vector2i in sparks:
			assert_false(Rect2i(0, 0, 2, 2).has_point(spark), "spark %s outside the ball" % spark)
