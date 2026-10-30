@tool
extends McpTestSuite

## Unit tests for GuideParts.is_on_for(): which part of Aatu's tutorial runs when.

const PartsScript := preload("res://src/ui/guide/guide_parts.gd")

const CELLAR : int = PartsScript.Part.CELLAR
const BREW_DAY : int = PartsScript.Part.BREW_DAY
const TALK : int = PartsScript.Part.TALK
const NONE_DONE : Array[int] = []


func suite_name() -> String:
	return "guide_parts"


func test_a_new_run_starts_with_the_cellar_and_the_brew_day() -> void:
	assert_true(PartsScript.is_on_for(CELLAR, false, NONE_DONE, false))
	assert_true(PartsScript.is_on_for(BREW_DAY, false, NONE_DONE, false))
	assert_false(PartsScript.is_on_for(TALK, false, NONE_DONE, false), "the talk waits for the first brew")


func test_after_the_first_brew_only_the_talk_is_left() -> void:
	assert_false(PartsScript.is_on_for(CELLAR, false, NONE_DONE, true))
	assert_false(PartsScript.is_on_for(BREW_DAY, false, NONE_DONE, true))
	assert_true(PartsScript.is_on_for(TALK, false, NONE_DONE, true))


func test_a_skipped_part_stays_done_and_the_others_carry_on() -> void:
	var done : Array[int] = [CELLAR]
	assert_false(PartsScript.is_on_for(CELLAR, false, done, false))
	assert_true(PartsScript.is_on_for(BREW_DAY, false, done, false))


func test_skip_tutorial_turns_every_part_off() -> void:
	for part : int in [CELLAR, BREW_DAY, TALK]:
		assert_false(PartsScript.is_on_for(part, true, NONE_DONE, part == TALK))
