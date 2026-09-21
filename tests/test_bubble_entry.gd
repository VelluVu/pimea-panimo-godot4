@tool
extends McpTestSuite

## Unit tests for BubbleEntry: token validity and safety around a freed bubble.

const BubbleEntryScript := preload("res://systems/dialog/bubble_entry.gd")


func suite_name() -> String:
	return "bubble_entry"


func _make_entry() -> BubbleEntryScript:
	return BubbleEntryScript.new(track(SpeechBubble.new()) as SpeechBubble)


func test_latest_token_is_current_and_older_ones_are_not() -> void:
	var entry := _make_entry()
	var first : int = entry.next_token()
	var second : int = entry.next_token()
	assert_false(entry.is_current(first))
	assert_true(entry.is_current(second))


func test_freed_bubble_is_not_alive_or_current() -> void:
	var bubble := SpeechBubble.new()
	var entry := BubbleEntryScript.new(bubble)
	var token : int = entry.next_token()
	bubble.free()
	assert_false(entry.is_alive())
	assert_false(entry.is_current(token), "must answer false, not throw, once the bubble is freed")


func test_dispose_queues_free_and_voids_the_token() -> void:
	var entry := _make_entry()
	var token : int = entry.next_token()
	var bubble : SpeechBubble = entry.bubble
	entry.dispose()
	assert_true(bubble.is_queued_for_deletion())
	assert_false(entry.is_current(token))


func test_dispose_on_a_freed_bubble_is_safe() -> void:
	var bubble := SpeechBubble.new()
	var entry := BubbleEntryScript.new(bubble)
	bubble.free()
	entry.dispose()
	assert_false(entry.is_alive())
