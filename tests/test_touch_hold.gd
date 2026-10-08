@tool
extends McpTestSuite

## Unit tests for TouchHold: a finger held still fires once, a tap or a drag never does.

const TouchHoldScript := preload("res://src/systems/tooltip/touch_hold.gd")


func suite_name() -> String:
	return "touch_hold"


func test_holding_still_fires_once() -> void:
	var hold := TouchHoldScript.new()
	hold.press(Vector2(100, 100))
	assert_false(hold.tick(0.3))
	assert_true(hold.tick(0.3))
	assert_false(hold.tick(0.3), "fires only once per press")
	assert_true(hold.has_fired())


func test_a_quick_tap_never_fires() -> void:
	var hold := TouchHoldScript.new()
	hold.press(Vector2(100, 100))
	hold.tick(0.1)
	hold.release()
	assert_false(hold.tick(1.0))
	assert_false(hold.has_fired())


func test_dragging_cancels_the_hold() -> void:
	var hold := TouchHoldScript.new()
	hold.press(Vector2(100, 100))
	hold.move(Vector2(100, 130))
	assert_false(hold.tick(1.0))


func test_a_small_wobble_still_holds() -> void:
	var hold := TouchHoldScript.new()
	hold.press(Vector2(100, 100))
	hold.move(Vector2(104, 103))
	assert_true(hold.tick(1.0))


func test_a_new_press_starts_over() -> void:
	var hold := TouchHoldScript.new()
	hold.press(Vector2(100, 100))
	hold.tick(1.0)
	hold.press(Vector2(50, 50))
	assert_false(hold.has_fired())
	assert_true(hold.tick(1.0))
