@tool
extends McpTestSuite

const RopeScript := preload("res://src/ui/keg_wash/hose_rope.gd")

const TAP : Vector2 = Vector2(600, 90)


func suite_name() -> String:
	return "hose_rope"


func test_the_nozzle_reaches_only_as_far_as_the_hose() -> void:
	var rope : HoseRope = RopeScript.new(TAP, TAP + Vector2(0, 100))
	var far : Vector2 = TAP + Vector2(-2000, 0)
	for i : int in 30:
		rope.step(1.0 / 60.0, far)
	assert_true(absf(rope.nozzle().distance_to(TAP) - RopeScript.length()) < 0.01)


func test_the_hose_stays_on_the_tap_and_above_the_floor() -> void:
	var rope : HoseRope = RopeScript.new(TAP, TAP + Vector2(-100, 120))
	for i : int in 120:
		rope.step(1.0 / 60.0, TAP + Vector2(-100, 120))
	assert_eq(rope.points[0], TAP)
	for point : Vector2 in rope.points:
		assert_true(point.y <= RopeScript.FLOOR_Y + 0.01)


func test_no_segment_stretches_far_past_its_length() -> void:
	var rope : HoseRope = RopeScript.new(TAP, TAP + Vector2(0, 100))
	for i : int in 60:
		rope.step(1.0 / 60.0, TAP + Vector2(-300, 150) + Vector2(sin(i * 0.3), 0) * 50.0)
	for i : int in range(1, rope.points.size()):
		assert_true(rope.points[i - 1].distance_to(rope.points[i]) <= RopeScript.SEGMENT * 1.25)
