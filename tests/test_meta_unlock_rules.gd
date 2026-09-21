@tool
extends McpTestSuite

## Unit tests for MetaUnlockRules: prerequisites, maxing and purchasing over a levels dictionary.

const MetaUnlockRulesScript := preload("res://src/progression/meta_unlock_rules.gd")


func suite_name() -> String:
	return "meta_unlock_rules"


func _unlock(id : String, prerequisites : Array[String] = [], any_mode : bool = false) -> MetaUnlockData:
	var unlock := MetaUnlockData.new()
	unlock.unlock_id = id
	unlock.max_level = 2
	unlock.renown_cost_per_level = 25
	unlock.prerequisite_ids = prerequisites
	unlock.requires_any_prerequisite = any_mode
	return unlock


func test_a_root_node_always_meets_its_prerequisites() -> void:
	assert_true(MetaUnlockRulesScript.meets_prerequisites(_unlock("root"), {}))
	assert_true(MetaUnlockRulesScript.meets_prerequisites(_unlock("root", [], true), {}), "also in any-mode")


func test_all_mode_needs_every_prerequisite_invested() -> void:
	var unlock := _unlock("capstone", ["a", "b"])
	assert_false(MetaUnlockRulesScript.meets_prerequisites(unlock, {"a": 1}))
	assert_false(MetaUnlockRulesScript.meets_prerequisites(unlock, {"a": 1, "b": 0}), "level 0 is not invested")
	assert_true(MetaUnlockRulesScript.meets_prerequisites(unlock, {"a": 1, "b": 3}))


func test_any_mode_needs_just_one_prerequisite_invested() -> void:
	var unlock := _unlock("capstone", ["a", "b"], true)
	assert_false(MetaUnlockRulesScript.meets_prerequisites(unlock, {}))
	assert_true(MetaUnlockRulesScript.meets_prerequisites(unlock, {"b": 1}))


func test_is_maxed_at_the_max_level() -> void:
	var unlock := _unlock("n")
	assert_false(MetaUnlockRulesScript.is_maxed(unlock, 1))
	assert_true(MetaUnlockRulesScript.is_maxed(unlock, 2))


func test_can_purchase_needs_renown_a_free_level_and_prerequisites() -> void:
	var unlock := _unlock("child", ["parent"])
	assert_true(MetaUnlockRulesScript.can_purchase(unlock, {"parent": 1}, 25))
	assert_false(MetaUnlockRulesScript.can_purchase(unlock, {"parent": 1}, 24), "not enough renown")
	assert_false(MetaUnlockRulesScript.can_purchase(unlock, {}, 100), "prerequisite missing")
	assert_false(MetaUnlockRulesScript.can_purchase(unlock, {"parent": 1, "child": 2}, 100), "already maxed")
