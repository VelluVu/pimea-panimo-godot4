@tool
extends McpTestSuite

## Unit tests for BubbleLayout: stacking of nearby speakers and viewport clamping.

const BubbleLayoutScript := preload("res://src/systems/dialog/bubble_layout.gd")
const BubbleEntryScript := preload("res://src/systems/dialog/bubble_entry.gd")

const SPEAKER : Vector2 = Vector2(300.0, 300.0)
const VIEWPORT : Vector2 = Vector2(640.0, 360.0)


func suite_name() -> String:
	return "bubble_layout"


const WIDTH : float = 100.0


func _entry_at(x : float, step : int) -> BubbleEntryScript:
	var entry := BubbleEntryScript.new(track(SpeechBubble.new()) as SpeechBubble)
	entry.x = x
	entry.width = WIDTH
	entry.height_step = step
	return entry


func test_step_is_zero_with_no_neighbors() -> void:
	assert_eq(BubbleLayoutScript.choose_step(SPEAKER, WIDTH, []), 0)


func test_nearby_speaker_pushes_the_bubble_up_a_step() -> void:
	var others : Array[BubbleEntry] = [_entry_at(SPEAKER.x + 20.0, 0)]
	assert_eq(BubbleLayoutScript.choose_step(SPEAKER, WIDTH, others), 1)


func test_far_speaker_does_not_take_a_step() -> void:
	var others : Array[BubbleEntry] = [_entry_at(SPEAKER.x + 200.0, 0)]
	assert_eq(BubbleLayoutScript.choose_step(SPEAKER, WIDTH, others), 0)


func test_neighbours_closer_than_the_bubbles_are_wide_overlap() -> void:
	assert_true(BubbleLayoutScript.overlaps_x(300.0, 220.0, 380.0, 220.0), "80 px apart, 220 px wide")
	assert_false(BubbleLayoutScript.overlaps_x(300.0, 60.0, 380.0, 60.0), "short bubbles fit side by side")


func test_stacking_stops_at_the_cap() -> void:
	var others : Array[BubbleEntry] = []
	for step in 5:
		others.append(_entry_at(SPEAKER.x, step))
	assert_eq(BubbleLayoutScript.choose_step(SPEAKER, WIDTH, others), BubbleLayoutScript.MAX_STACK_STEPS)


func test_step_is_capped_so_the_bubble_stays_on_screen() -> void:
	var low_speaker := Vector2(300.0, 200.0) # room for no step above it
	var others : Array[BubbleEntry] = [_entry_at(low_speaker.x, 0)]
	assert_eq(BubbleLayoutScript.choose_step(low_speaker, WIDTH, others), 0)


func test_position_is_centered_above_the_speaker() -> void:
	var pos : Vector2 = BubbleLayoutScript.position_for(SPEAKER, 0, Vector2(100.0, 40.0), VIEWPORT)
	assert_eq(pos, Vector2(250.0, 300.0 + BubbleLayoutScript.OFFSET_Y))


func test_a_stacked_bubble_rests_its_tail_on_the_highest_one_below() -> void:
	var tops : Array[float] = [120.0, 100.0]
	assert_eq(BubbleLayoutScript.stacked_y(tops, 50.0), 100.0 - 50.0 + BubbleLayoutScript.STACK_OVERLAP)


func test_only_more_than_a_tail_of_overlap_covers_a_bubble() -> void:
	var lower := Rect2(100.0, 100.0, 80.0, 50.0)
	var tail_over := Rect2(100.0, 100.0 - 50.0 + BubbleLayoutScript.STACK_OVERLAP, 80.0, 50.0)
	assert_false(BubbleLayoutScript.covers(tail_over, lower), "a stacked bubble's tail may lie over the one below")
	assert_true(BubbleLayoutScript.covers(Rect2(110.0, 110.0, 80.0, 50.0), lower))
	assert_false(BubbleLayoutScript.covers(Rect2(300.0, 100.0, 80.0, 50.0), lower), "side by side")


func test_each_step_raises_the_bubble() -> void:
	var base : Vector2 = BubbleLayoutScript.position_for(SPEAKER, 0, Vector2(100.0, 40.0), VIEWPORT)
	var raised : Vector2 = BubbleLayoutScript.position_for(SPEAKER, 1, Vector2(100.0, 40.0), VIEWPORT)
	assert_eq(base.y - raised.y, BubbleLayoutScript.STAIR_STEP)


func test_position_is_clamped_inside_the_viewport() -> void:
	var size := Vector2(100.0, 40.0)
	assert_eq(BubbleLayoutScript.position_for(Vector2(0.0, 300.0), 0, size, VIEWPORT).x, 0.0, "left edge")
	assert_eq(BubbleLayoutScript.position_for(Vector2(640.0, 300.0), 0, size, VIEWPORT).x, 540.0, "right edge")
	assert_eq(BubbleLayoutScript.position_for(Vector2(300.0, 50.0), 3, size, VIEWPORT).y, 0.0, "top edge")
