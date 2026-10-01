@tool
extends McpTestSuite

## Unit tests for SpecialEventPacing.interval().

const PacingScript := preload("res://src/events/special_event_pacing.gd")


func suite_name() -> String:
	return "special_event_pacing"


func test_no_risk_keeps_the_base_interval() -> void:
	assert_eq(PacingScript.interval(0.0), PacingScript.BASE_INTERVAL_SECONDS)


func test_risk_at_the_threshold_shortens_the_wait() -> void:
	assert_eq(PacingScript.interval(1.0), PacingScript.BASE_INTERVAL_SECONDS * (1.0 - PacingScript.MAX_RISK_SPEEDUP))


func test_risk_past_the_threshold_is_capped() -> void:
	assert_eq(PacingScript.interval(3.0), PacingScript.interval(1.0))
