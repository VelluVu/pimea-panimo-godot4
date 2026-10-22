@tool
extends McpTestSuite

## Unit tests for SpeechTiming: how long a speech bubble stays.

const SpeechTimingScript := preload("res://src/customers/speech_timing.gd")


func suite_name() -> String:
	return "speech_timing"


func test_an_empty_line_stays_the_base_time() -> void:
	assert_eq(SpeechTimingScript.seconds_for(""), SpeechTimingScript.BASE_SECONDS)


func test_each_character_adds_time() -> void:
	var expected : float = SpeechTimingScript.BASE_SECONDS + 5 * SpeechTimingScript.PER_CHARACTER_SECONDS
	assert_true(is_equal_approx(SpeechTimingScript.seconds_for("12345"), expected))


func test_a_long_line_is_capped() -> void:
	assert_eq(SpeechTimingScript.seconds_for("x".repeat(1000)), SpeechTimingScript.MAX_SECONDS)


func test_the_preview_starts_from_a_shorter_base() -> void:
	assert_eq(SpeechTimingScript.seconds_for("", SpeechTimingScript.PREVIEW_BASE_SECONDS), SpeechTimingScript.PREVIEW_BASE_SECONDS)
