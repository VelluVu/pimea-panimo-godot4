@tool
extends McpTestSuite

## Unit tests for ShakeRules: whole-pixel screen shake from decaying trauma.

const ShakeRulesScript := preload("res://src/ui/shake_rules.gd")


func suite_name() -> String:
	return "shake_rules"


func test_no_trauma_no_offset() -> void:
	assert_eq(ShakeRulesScript.offset(0.0, 1.0, -1.0), Vector2i.ZERO)


func test_full_trauma_reaches_the_max() -> void:
	var max_px : int = roundi(ShakeRulesScript.MAX_OFFSET_PX)
	assert_eq(ShakeRulesScript.offset(1.0, 1.0, -1.0), Vector2i(max_px, -max_px))


func test_offset_grows_with_the_square() -> void:
	assert_eq(ShakeRulesScript.offset(0.5, 1.0, 1.0), Vector2i(1, 1))


func test_offset_never_passes_the_max() -> void:
	var max_px : int = roundi(ShakeRulesScript.MAX_OFFSET_PX)
	var offset : Vector2i = ShakeRulesScript.offset(3.0, 1.0, 1.0)
	assert_true(offset.x <= max_px and offset.y <= max_px, str(offset))


func test_trauma_decays_to_zero_and_stops() -> void:
	assert_eq(ShakeRulesScript.decayed(0.1, 10.0), 0.0)
	assert_true(ShakeRulesScript.decayed(1.0, 0.1) < 1.0)


func test_added_trauma_is_capped() -> void:
	assert_eq(ShakeRulesScript.added(0.8, 0.6), 1.0)
