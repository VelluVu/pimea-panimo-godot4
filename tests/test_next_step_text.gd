@tool
extends McpTestSuite

## Unit tests for NextStepText: every step but NONE has a line.

const NextStepTextScript := preload("res://src/ui/next_step_text.gd")
const NextStepRulesScript := preload("res://src/progression/next_step_rules.gd")


func suite_name() -> String:
	return "next_step_text"


func test_every_step_but_none_has_text() -> void:
	for step : int in NextStepRulesScript.Step.values():
		var text : String = NextStepTextScript.of(step)
		if step == NextStepRulesScript.Step.NONE:
			assert_eq(text, "")
		else:
			assert_false(text.is_empty(), "step %d has no text" % step)
			assert_false(text.contains("—"), "no em dashes in player text")
