@tool
extends McpTestSuite

## Unit tests for KegRules: a batch leaves as a keg only while nearly full.

const KegRulesScript := preload("res://src/brewery/keg_rules.gd")


func suite_name() -> String:
	return "keg_rules"


func test_a_fresh_batch_can_leave_as_a_keg() -> void:
	# A fresh batch is 45 servings after bottling loss.
	assert_true(KegRulesScript.can_leave_as_keg(45))
	assert_true(KegRulesScript.can_leave_as_keg(KegRulesScript.MIN_SERVINGS))


func test_a_batch_drawn_below_the_minimum_stays_for_the_counter() -> void:
	assert_false(KegRulesScript.can_leave_as_keg(KegRulesScript.MIN_SERVINGS - 1))
	assert_false(KegRulesScript.can_leave_as_keg(0))
