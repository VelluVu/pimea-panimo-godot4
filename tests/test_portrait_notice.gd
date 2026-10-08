@tool
extends McpTestSuite

## Unit tests for PortraitNotice: which window sizes count as a phone held upright.

const PortraitNoticeScript := preload("res://src/ui/portrait_notice.gd")


func suite_name() -> String:
	return "portrait_notice"


func test_a_tall_window_is_portrait() -> void:
	assert_true(PortraitNoticeScript.is_portrait(Vector2i(412, 915)))


func test_a_wide_or_square_window_is_not() -> void:
	assert_false(PortraitNoticeScript.is_portrait(Vector2i(915, 412)))
	assert_false(PortraitNoticeScript.is_portrait(Vector2i(500, 500)))
