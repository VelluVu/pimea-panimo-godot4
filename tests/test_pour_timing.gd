@tool
extends McpTestSuite

## PourTiming: how long the bartender's running and queued pours still take.

const PourTimingScript := preload("res://src/customers/pour_timing.gd")

## Seven one-unit frames at 4 fps, like serve_beer: 1.75 s at 1x.
const DURATIONS : PackedFloat32Array = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
const FPS : float = 4.0


func suite_name() -> String:
	return "pour_timing"


func test_a_whole_pour_follows_the_frames_and_speed() -> void:
	assert_eq(PourTimingScript.full_seconds(DURATIONS, FPS, 1.0), 1.75)
	assert_eq(PourTimingScript.full_seconds(DURATIONS, FPS, 3.5), 0.5)


func test_a_pour_half_way_through_a_frame_counts_only_what_is_left() -> void:
	assert_eq(PourTimingScript.seconds_left(DURATIONS, FPS, 1.0, 3, 0.5, []), 0.875)


func test_queued_pours_add_their_own_length() -> void:
	var queued : Array[float] = [1.0, 3.5]
	assert_eq(PourTimingScript.seconds_left(DURATIONS, FPS, 1.0, 6, 0.0, queued), 0.25 + 1.75 + 0.5)


func test_longer_frames_take_longer() -> void:
	var durations : PackedFloat32Array = [2.0, 1.0]
	assert_eq(PourTimingScript.full_seconds(durations, 1.0, 1.0), 3.0)
