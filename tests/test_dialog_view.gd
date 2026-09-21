@tool
extends McpTestSuite

## DialogView eviction: force-closing the day while a bubble is mid-fade must not
## crash or double-free (playtest_notes_6.txt). The awaited timer and tween race needs
## a running game; these cover the synchronous cleanup, including a truly freed bubble.


func suite_name() -> String:
	return "dialog_view"


func _make_view() -> DialogView:
	return track(DialogView.new()) as DialogView


func test_evicted_clears_the_slot_for_a_freed_bubble_without_crashing() -> void:
	var view := _make_view()
	var bubble := SpeechBubble.new()
	view._bubbles[0] = BubbleEntry.new(bubble)
	bubble.free()

	view._on_customer_evicted(0)

	assert_false(view._bubbles.has(0), "evicted slot should be cleared")


func test_evicted_queues_free_for_a_still_valid_bubble() -> void:
	var view := _make_view()
	var bubble := track(SpeechBubble.new()) as SpeechBubble
	view._bubbles[0] = BubbleEntry.new(bubble)

	view._on_customer_evicted(0)

	assert_true(bubble.is_queued_for_deletion(), "a valid evicted bubble should be queued for deletion")
	assert_false(view._bubbles.has(0), "evicted slot should be cleared")


func test_evicted_on_an_unknown_slot_is_a_safe_no_op() -> void:
	var view := _make_view()
	view._on_customer_evicted(0)
	assert_false(view._bubbles.has(0))


func test_evicted_voids_a_pending_hide_for_that_bubble() -> void:
	var view := _make_view()
	var entry := BubbleEntry.new(track(SpeechBubble.new()) as SpeechBubble)
	var token : int = entry.next_token()
	view._bubbles[0] = entry

	view._on_customer_evicted(0)

	assert_false(entry.is_current(token), "the in-flight hide must bail out after eviction")
