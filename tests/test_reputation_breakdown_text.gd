@tool
extends McpTestSuite

## Unit tests for ReputationBreakdownText.format().

const TextScript := preload("res://src/ui/reputation_breakdown_text.gd")


func suite_name() -> String:
	return "reputation_breakdown_text"


func test_nothing_moved_gives_no_suffix() -> void:
	assert_eq(TextScript.format({}), "")
	assert_eq(TextScript.format({ReputationRules.Source.CUSTOMERS: 0}), "")


func test_sources_are_listed_in_a_fixed_order_with_signs() -> void:
	var totals: Dictionary = {ReputationRules.Source.DECAY: -4, ReputationRules.Source.CUSTOMERS: 12}
	assert_eq(TextScript.format(totals), " (asiakkaat +12, hiipuminen -4)")
