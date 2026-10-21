@tool
extends McpTestSuite

## Unit tests for TipsyRules: how far a customer sways on the way out.

const TipsyRulesScript := preload("res://src/customers/tipsy_rules.gd")


func suite_name() -> String:
	return "tipsy_rules"


func test_one_normal_beer_does_not_sway() -> void:
	assert_eq(TipsyRulesScript.sway_steps(1, 5.0), 0)


func test_alcohol_free_never_sways() -> void:
	assert_eq(TipsyRulesScript.sway_steps(8, 0.0), 0)


func test_two_normal_beers_sway_one_pixel() -> void:
	assert_eq(TipsyRulesScript.sway_steps(2, 5.0), 1)


func test_one_strong_beer_sways_one_pixel() -> void:
	assert_eq(TipsyRulesScript.sway_steps(1, 11.0), 1)


func test_sway_is_capped() -> void:
	assert_eq(TipsyRulesScript.sway_steps(10, 12.0), TipsyRulesScript.MAX_STEPS)


func test_offset_stays_whole_and_within_the_steps() -> void:
	for i : int in 50:
		var offset : int = TipsyRulesScript.sway_offset(i * 0.07, 2)
		assert_true(absi(offset) <= 2, str(offset))


func test_no_steps_no_offset() -> void:
	assert_eq(TipsyRulesScript.sway_offset(0.3, 0), 0)
