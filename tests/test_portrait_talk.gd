@tool
extends McpTestSuite

## Unit tests for PortraitTalk: typing pace and the mouth's frames.

const PortraitTalkScript := preload("res://src/events/portrait_talk.gd")


func suite_name() -> String:
	return "portrait_talk"


func test_text_appears_at_the_typing_pace_and_stops_at_the_end() -> void:
	assert_eq(PortraitTalkScript.characters_shown(0.0, 90), 0)
	assert_eq(PortraitTalkScript.characters_shown(1.0, 90), int(PortraitTalkScript.CHARACTERS_PER_SECOND))
	assert_eq(PortraitTalkScript.characters_shown(60.0, 90), 90)


func test_the_mouth_opens_and_shuts_while_typing() -> void:
	var step : int = PortraitTalkScript.CHARACTERS_PER_MOUTH_MOVE
	assert_false(PortraitTalkScript.is_mouth_open(0, 90))
	assert_true(PortraitTalkScript.is_mouth_open(step, 90))
	assert_false(PortraitTalkScript.is_mouth_open(step * 2, 90))


func test_the_mouth_rests_shut_when_the_text_is_out() -> void:
	var step : int = PortraitTalkScript.CHARACTERS_PER_MOUTH_MOVE
	assert_false(PortraitTalkScript.is_mouth_open(step, step))


func test_the_frames_sit_side_by_side() -> void:
	assert_eq(PortraitTalkScript.frame_region(false), Rect2(0, 0, 48, 48))
	assert_eq(PortraitTalkScript.frame_region(true), Rect2(48, 0, 48, 48))
