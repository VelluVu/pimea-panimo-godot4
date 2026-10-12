@tool
extends McpTestSuite

## Unit tests for NicknameRules: the names allowed on the shared leaderboard.

const NicknameRulesScript := preload("res://src/systems/online_leaderboard/nickname_rules.gd")


func suite_name() -> String:
	return "nickname_rules"


func test_spaces_are_trimmed_and_collapsed() -> void:
	assert_eq(NicknameRulesScript.clean("  Kellari   Kalle  "), "Kellari Kalle")


func test_control_characters_become_spaces() -> void:
	assert_eq(NicknameRulesScript.clean("Olut\nMies\t"), "Olut Mies")


func test_long_names_are_cut() -> void:
	var cleaned : String = NicknameRulesScript.clean("Pimeän Panimon Mestaripanimo")
	assert_eq(cleaned.length(), NicknameRulesScript.MAX_LENGTH)


func test_a_cut_name_does_not_end_in_a_space() -> void:
	assert_eq(NicknameRulesScript.clean("Aaaaaaaaaaaaaaa Bbbb"), "Aaaaaaaaaaaaaaa")


func test_blank_names_are_not_valid() -> void:
	assert_false(NicknameRulesScript.is_valid("   "))
	assert_false(NicknameRulesScript.is_valid("\n\t"))
	assert_true(NicknameRulesScript.is_valid("Ä"))
