@tool
extends McpTestSuite


func suite_name() -> String:
	return "popup_card_stack"


func test_newest_card_sits_at_the_bottom() -> void:
	var bottoms : Array[float] = PopupCardStack.stacked_bottoms([40.0, 30.0, 50.0] as Array[float], 4.0)
	assert_eq(bottoms, [0.0, 44.0, 78.0] as Array[float])


func test_fresh_oldest_card_holds_the_queue() -> void:
	assert_true(is_equal_approx(PopupCardStack.seconds_left_to_read(1000, 1500, 2.0), 1.5))


func test_read_card_frees_its_slot_at_once() -> void:
	assert_eq(PopupCardStack.seconds_left_to_read(1000, 4000, 2.0), 0.0)


func test_no_cards_no_slots() -> void:
	assert_true(PopupCardStack.stacked_bottoms([] as Array[float], 4.0).is_empty())
