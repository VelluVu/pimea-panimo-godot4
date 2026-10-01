@tool
extends McpTestSuite

## Unit tests for WordOfMouthRules.outcome().

const RulesScript := preload("res://src/customers/word_of_mouth_rules.gd")


func suite_name() -> String:
	return "word_of_mouth_rules"


func test_delighted_customer_sends_a_friend_on_a_low_roll() -> void:
	assert_eq(RulesScript.outcome(true, 5, 0.0), RulesScript.Outcome.FRIEND)


func test_delighted_customer_sends_nobody_on_a_high_roll() -> void:
	assert_eq(RulesScript.outcome(true, 5, 0.99), RulesScript.Outcome.NONE)


func test_delighted_customer_never_spreads_a_bad_review() -> void:
	assert_eq(RulesScript.outcome(true, -3, 0.0), RulesScript.Outcome.FRIEND)


func test_unhappy_customer_spreads_a_bad_review_on_a_low_roll() -> void:
	assert_eq(RulesScript.outcome(false, -2, 0.0), RulesScript.Outcome.BAD_REVIEW)
	assert_eq(RulesScript.outcome(false, -2, 0.99), RulesScript.Outcome.NONE)


func test_a_plain_sale_spreads_nothing() -> void:
	assert_eq(RulesScript.outcome(false, 2, 0.0), RulesScript.Outcome.NONE)
	assert_eq(RulesScript.outcome(false, 0, 0.0), RulesScript.Outcome.NONE)
