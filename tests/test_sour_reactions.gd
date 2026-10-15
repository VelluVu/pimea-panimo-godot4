@tool
extends McpTestSuite

## Unit tests for SourReactions: a line from the list for the batch's sour level.

const SourReactionsScript := preload("res://src/customers/sour_reactions.gd")
const SHIPPED : String = "res://src/resources/sour_reactions/sour_reactions.tres"


func suite_name() -> String:
	return "sour_reactions"


func _reactions() -> SourReactions:
	var reactions : SourReactions = SourReactionsScript.new()
	reactions.light_lines.assign(["kirpeä"])
	reactions.sour_lines.assign(["hapan"])
	reactions.spoiled_lines.assign(["etikkaa"])
	return reactions


func test_each_level_has_its_own_lines() -> void:
	var reactions : SourReactions = _reactions()
	assert_eq(reactions.line_for(FermentationRules.SourLevel.LIGHT), "kirpeä")
	assert_eq(reactions.line_for(FermentationRules.SourLevel.CLEAR), "hapan")
	assert_eq(reactions.line_for(FermentationRules.SourLevel.STRONG), "etikkaa")


func test_a_batch_that_did_not_sour_gets_no_line() -> void:
	assert_eq(_reactions().line_for(FermentationRules.SourLevel.NONE), "")


func test_the_shipped_lines_cover_every_level() -> void:
	var reactions : SourReactions = load(SHIPPED)
	for level : FermentationRules.SourLevel in [FermentationRules.SourLevel.LIGHT, FermentationRules.SourLevel.CLEAR, FermentationRules.SourLevel.STRONG]:
		var line : String = reactions.line_for(level)
		assert_false(line.is_empty(), "no line for level %d" % level)
		assert_false(line.contains("—"), "em dash in %s" % line)
