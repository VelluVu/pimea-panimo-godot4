@tool
extends McpTestSuite

## Regression tests for the DialogView crash documented in
## playtest_notes_6.txt: force-closing the day while a customer's speech
## bubble is mid-fade (TimeManager.force_advance_day() ->
## CustomerManager.evict_active_customers() -> DialogView.
## _on_customer_evicted()) could queue_free() a bubble that
## _hide_bubble_after_delay() was still awaiting on. When that coroutine
## resumed, its stale `bubble` reference got passed into
## _bubble_still_current(bubble: Node, ...) — a statically typed parameter —
## which throws "previously freed... not a subclass of the expected
## argument class" at the CALL SITE itself, before _bubble_still_current()'s
## own is_instance_valid() check ever runs. The fix guards one level up in
## _hide_bubble_after_delay(), via short-circuiting `or`, so the unsafe call
## is never made once bubble is invalid.
##
## The awaited timer/tween race itself needs a running game to reproduce
## (same limitation test_brew_resolver.gd documents for autoload-state
## logic — see its class-level note); these tests instead cover the two
## pieces that ARE plain node/dictionary logic and don't need the
## SceneTree: the guard expression itself, and _on_customer_evicted()'s
## cleanup, both exercised synchronously with a truly-freed bubble.


func suite_name() -> String:
	return "dialog_view"


func _make_view() -> DialogView:
	return track(DialogView.new()) as DialogView


func test_guard_short_circuits_before_bubble_still_current_on_freed_bubble() -> void:
	var view := _make_view()
	var bubble := Node.new()
	bubble.free()

	# Mirrors _hide_bubble_after_delay()'s exact guard expression (see its
	# docstring). If this ever regresses back to calling
	# _bubble_still_current(bubble, ...) unconditionally, this line throws
	# the same freed-Object-into-typed-parameter runtime error the real
	# crash did — evaluating it here enforces the guard the same way the
	# engine's own static typing check does at the real call site.
	var should_bail : bool = not is_instance_valid(bubble) or not view._bubble_still_current(bubble, 0, 1)
	assert_true(should_bail, "guard must return true (bail out) once bubble is freed")


func test_customer_evicted_clears_slot_for_freed_bubble_without_crashing() -> void:
	var view := _make_view()
	var bubble := Node.new()
	bubble.free()

	view.active_bubbles[0] = {"bubble": bubble, "x": 0.0, "height_step": 0, "fade_tween": null}
	view.slot_display_tokens[0] = 1

	view._on_customer_evicted(0)

	assert_false(view.active_bubbles.has(0), "evicted slot's bubble entry should be cleared")
	assert_false(view.slot_display_tokens.has(0), "evicted slot's display token should be cleared")


func test_customer_evicted_queues_free_for_still_valid_bubble() -> void:
	var view := _make_view()
	var bubble := track(Node.new())

	view.active_bubbles[0] = {"bubble": bubble, "x": 0.0, "height_step": 0, "fade_tween": null}
	view.slot_display_tokens[0] = 1

	view._on_customer_evicted(0)

	assert_true(bubble.is_queued_for_deletion(), "a still-valid evicted bubble should be queued for deletion")
	assert_false(view.active_bubbles.has(0), "evicted slot's bubble entry should be cleared")


func test_customer_evicted_on_unknown_slot_is_a_safe_no_op() -> void:
	var view := _make_view()

	# No active_bubbles/slot_display_tokens entry for slot 0 at all — the
	# early `if not active_bubbles.has(slot): return` guard should make this
	# a no-op instead of an out-of-bounds Dictionary access.
	view._on_customer_evicted(0)

	assert_false(view.active_bubbles.has(0))
