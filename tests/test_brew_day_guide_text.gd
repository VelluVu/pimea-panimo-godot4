@tool
extends McpTestSuite

## Unit tests for BrewDayGuideText: every step but NONE has a line.

const TextScript := preload("res://src/ui/brew_day/brew_day_guide_text.gd")
const RulesScript := preload("res://src/ui/brew_day/brew_day_guide_rules.gd")


func suite_name() -> String:
	return "brew_day_guide_text"


func test_every_step_but_none_has_text() -> void:
	for step : int in RulesScript.Step.values():
		var text : String = TextScript.of(step)
		if step == RulesScript.Step.NONE:
			assert_eq(text, "")
		else:
			assert_false(text.is_empty(), "step %d has no text" % step)
			assert_false(text.contains("—"), "no em dashes in player text")
