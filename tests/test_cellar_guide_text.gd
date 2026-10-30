@tool
extends McpTestSuite

## Unit tests for CellarGuideText: Aatu has a line for every first-brew step and talk line.

const TextScript := preload("res://src/ui/guide/cellar_guide_text.gd")
const RulesScript := preload("res://src/progression/next_step_rules.gd")

const FIRST_BREW_STEPS : Array[int] = [
	RulesScript.Step.OPEN_RECIPES, RulesScript.Step.PICK_RECIPE, RulesScript.Step.LOAD_RECIPE,
	RulesScript.Step.GO_TO_SHOP, RulesScript.Step.BUY_MISSING, RulesScript.Step.CLOSE_SHOP,
	RulesScript.Step.OPEN_BREWERY, RulesScript.Step.ADD_INGREDIENTS, RulesScript.Step.START_BREW,
]


func suite_name() -> String:
	return "cellar_guide_text"


func test_every_first_brew_step_has_a_line() -> void:
	for step : int in FIRST_BREW_STEPS:
		var text : String = TextScript.of(step)
		assert_false(text.is_empty(), "step %d has no line" % step)
		assert_false(text.contains("—"), "no em dashes in player text")


func test_later_steps_are_left_to_the_goals_panel() -> void:
	assert_eq(TextScript.of(RulesScript.Step.BREW_MORE), "")
	assert_eq(TextScript.of(RulesScript.Step.NONE), "")


func test_every_talk_line_differs() -> void:
	var seen : Dictionary = {}
	for line : int in TextScript.Talk.values():
		var text : String = TextScript.talk(line)
		assert_false(text.is_empty())
		assert_false(seen.has(text), "talk line %d repeats another" % line)
		seen[text] = true
