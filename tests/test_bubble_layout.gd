@tool
extends McpTestSuite

## Unit tests for BubbleLayout: stacking of nearby speakers and viewport clamping.

const BubbleLayoutScript := preload("res://src/systems/dialog/bubble_layout.gd")
const BubbleEntryScript := preload("res://src/systems/dialog/bubble_entry.gd")

const SPEAKER : Vector2 = Vector2(300.0, 300.0)
const VIEWPORT : Vector2 = Vector2(640.0, 360.0)


func suite_name() -> String:
	return "bubble_layout"


func _entry_at(x : float, step : int) -> BubbleEntryScript:
	var entry := BubbleEntryScript.new(track(SpeechBubble.new()) as SpeechBubble)
	entry.x = x
	entry.height_step = step
	return entry


func test_step_is_zero_with_no_neighbors() -> void:
	assert_eq(BubbleLayoutScript.choose_step(SPEAKER, []), 0)


func test_nearby_speaker_pushes_the_bubble_up_a_step() -> void:
	var others : Array[BubbleEntry] = [_entry_at(SPEAKER.x + 20.0, 0)]
	assert_eq(BubbleLayoutScript.choose_step(SPEAKER, others), 1)


func test_far_speaker_does_not_take_a_step() -> void:
	var others : Array[BubbleEntry] = [_entry_at(SPEAKER.x + 200.0, 0)]
	assert_eq(BubbleLayoutScript.choose_step(SPEAKER, others), 0)


func test_step_skips_only_the_taken_heights() -> void:
	var others : Array[BubbleEntry] = [_entry_at(SPEAKER.x, 0), _entry_at(SPEAKER.x + 10.0, 2)]
	assert_eq(BubbleLayoutScript.choose_step(SPEAKER, others), 1, "height 1 is free even though 2 is taken")


func test_step_is_capped_so_the_bubble_stays_on_screen() -> void:
	var low_speaker := Vector2(300.0, 100.0) # room for only a few steps above it
	var others : Array[BubbleEntry] = []
	for step in 10:
		others.append(_entry_at(low_speaker.x, step))
	var max_steps : int = maxi(0, floori((low_speaker.y + BubbleLayoutScript.OFFSET_Y - BubbleLayoutScript.MIN_VISIBLE_Y) / BubbleLayoutScript.STAIR_STEP))
	assert_eq(BubbleLayoutScript.choose_step(low_speaker, others), max_steps)


func test_position_is_centered_above_the_speaker() -> void:
	var pos : Vector2 = BubbleLayoutScript.position_for(SPEAKER, 0, Vector2(100.0, 40.0), VIEWPORT)
	assert_eq(pos, Vector2(250.0, 300.0 + BubbleLayoutScript.OFFSET_Y))


func test_each_step_raises_the_bubble() -> void:
	var base : Vector2 = BubbleLayoutScript.position_for(SPEAKER, 0, Vector2(100.0, 40.0), VIEWPORT)
	var raised : Vector2 = BubbleLayoutScript.position_for(SPEAKER, 1, Vector2(100.0, 40.0), VIEWPORT)
	assert_eq(base.y - raised.y, BubbleLayoutScript.STAIR_STEP)


func test_position_is_clamped_inside_the_viewport() -> void:
	var size := Vector2(100.0, 40.0)
	assert_eq(BubbleLayoutScript.position_for(Vector2(0.0, 300.0), 0, size, VIEWPORT).x, 0.0, "left edge")
	assert_eq(BubbleLayoutScript.position_for(Vector2(640.0, 300.0), 0, size, VIEWPORT).x, 540.0, "right edge")
	assert_eq(BubbleLayoutScript.position_for(Vector2(300.0, 50.0), 3, size, VIEWPORT).y, 0.0, "top edge")
