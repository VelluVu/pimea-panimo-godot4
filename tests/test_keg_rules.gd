@tool
extends McpTestSuite

## Unit tests for KegRules: only a nearly full batch counts as a keg for the bar goal.

const KegRulesScript := preload("res://src/brewery/keg_rules.gd")


func suite_name() -> String:
	return "keg_rules"


func test_a_fresh_batch_is_a_full_keg() -> void:
	# A fresh batch is 45 servings after bottling loss.
	assert_true(KegRulesScript.is_full_keg(45))
	assert_true(KegRulesScript.is_full_keg(KegRulesScript.MIN_SERVINGS))


func test_a_drawn_batch_is_not_a_full_keg() -> void:
	assert_false(KegRulesScript.is_full_keg(KegRulesScript.MIN_SERVINGS - 1))
	assert_false(KegRulesScript.is_full_keg(0))
