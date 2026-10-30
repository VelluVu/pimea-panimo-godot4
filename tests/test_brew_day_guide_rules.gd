@tool
extends McpTestSuite

## Unit tests for BrewDayGuideRules: the guided brew day's order of steps.

const RulesScript := preload("res://src/ui/brew_day/brew_day_guide_rules.gd")

const MASH : RulesScript.Phase = RulesScript.Phase.MASH


func suite_name() -> String:
	return "brew_day_guide_rules"


func test_mash_heats_then_pours_at_the_band() -> void:
	assert_eq(RulesScript.mash_step(MASH, false, false, false, false), RulesScript.Step.HEAT_WATER)
	assert_eq(RulesScript.mash_step(MASH, false, true, false, false), RulesScript.Step.POUR_MALTS)


func test_overheated_water_says_let_go() -> void:
	assert_eq(RulesScript.mash_step(MASH, false, false, true, false), RulesScript.Step.COOL_WATER)


func test_clumps_come_before_holding_the_band() -> void:
	assert_eq(RulesScript.mash_step(MASH, true, true, false, true), RulesScript.Step.BREAK_CLUMPS)
	assert_eq(RulesScript.mash_step(MASH, true, false, true, false), RulesScript.Step.HOLD_MASH)


func test_mash_done_and_result_point_at_the_next_button() -> void:
	assert_eq(RulesScript.mash_step(RulesScript.Phase.MASH_DONE, true, true, false, false), RulesScript.Step.TO_BOIL)
	assert_eq(RulesScript.mash_step(RulesScript.Phase.RESULT, true, true, false, false), RulesScript.Step.FINISH)


func test_boil_heats_then_keeps_boiling() -> void:
	assert_eq(RulesScript.boil_step(false, false, false), RulesScript.Step.HEAT_BOIL)
	assert_eq(RulesScript.boil_step(true, false, false), RulesScript.Step.KEEP_BOILING)


func test_foam_outranks_a_hop_sack() -> void:
	assert_eq(RulesScript.boil_step(true, false, true), RulesScript.Step.ADD_HOPS)
	assert_eq(RulesScript.boil_step(true, true, true), RulesScript.Step.WATCH_FOAM)
