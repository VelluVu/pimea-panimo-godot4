@tool
extends McpTestSuite

const QueueScript := preload("res://src/events/special_event_queue.gd")


func suite_name() -> String:
	return "special_event_queue"


func _event() -> SpecialEventData:
	return SpecialEventData.new()


func test_opens_at_once_while_there_is_room() -> void:
	var queue := QueueScript.new()
	assert_true(queue.offer(_event(), 0))
	assert_true(queue.offer(_event(), QueueScript.MAX_OPEN_WINDOWS - 1))
	assert_true(queue.waiting().is_empty())


func test_waits_when_the_screen_is_full() -> void:
	var queue := QueueScript.new()
	var held := _event()
	assert_false(queue.offer(held, QueueScript.MAX_OPEN_WINDOWS))
	assert_eq(queue.waiting(), [held])


func test_next_waits_for_a_free_spot() -> void:
	var queue := QueueScript.new()
	var held := _event()
	queue.offer(held, QueueScript.MAX_OPEN_WINDOWS)
	assert_eq(queue.next(QueueScript.MAX_OPEN_WINDOWS), null)
	assert_eq(queue.next(QueueScript.MAX_OPEN_WINDOWS - 1), held)
	assert_true(queue.waiting().is_empty())


func test_keeps_the_order_and_never_jumps_the_line() -> void:
	var queue := QueueScript.new()
	var first := _event()
	var second := _event()
	queue.offer(first, QueueScript.MAX_OPEN_WINDOWS)
	# A spot frees up, but an event already waits: the new one goes behind it.
	assert_false(queue.offer(second, 0))
	assert_eq(queue.next(0), first)
	assert_eq(queue.next(0), second)
	assert_eq(queue.next(0), null)


func test_clear_drops_the_waiting_events() -> void:
	var queue := QueueScript.new()
	queue.offer(_event(), QueueScript.MAX_OPEN_WINDOWS)
	queue.clear()
	assert_true(queue.waiting().is_empty())
