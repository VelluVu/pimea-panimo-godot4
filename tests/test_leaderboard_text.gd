@tool
extends McpTestSuite

## Unit tests for LeaderboardText: ending names and the score breakdown.

const LeaderboardTextScript := preload("res://src/ui/leaderboard_text.gd")


func suite_name() -> String:
	return "leaderboard_text"


func _entry() -> Dictionary:
	return {"ending_type": "survived", "days_survived": 15, "reputation": 110, "lifetime_bottles_sold": 400,
		"bonus": 1500, "multiplier": 1.35, "modifier_name": "Ainepula", "score": 6075}


func test_every_ending_has_a_finnish_name() -> void:
	for ending : String in ["survived", "season_over", "busted", "bankrupt", ""]:
		assert_ne(LeaderboardTextScript.ending_label(ending), ending)


func test_the_breakdown_lists_every_part_and_the_total() -> void:
	var text : String = LeaderboardTextScript.breakdown(_entry())
	assert_contains(text, "15 × 100")
	assert_contains(text, "110 × 10")
	assert_contains(text, "400")
	assert_contains(text, "+1500")
	assert_contains(text, "Ainepula × 1,35")
	assert_contains(text, "6075")


func test_the_breakdown_skips_a_missing_bonus_and_a_neutral_multiplier() -> void:
	var entry : Dictionary = _entry()
	entry["bonus"] = 0
	entry["multiplier"] = 1.0
	assert_eq(LeaderboardTextScript.breakdown_lines(entry).size(), 3)


func test_multipliers_use_a_decimal_comma() -> void:
	assert_eq(LeaderboardTextScript.format_multiplier(1.35), "1,35")
	assert_eq(LeaderboardTextScript.format_multiplier(0.95), "0,95")


func test_dates_are_finnish() -> void:
	assert_eq(LeaderboardTextScript.format_date("2026-09-13T10:27:33"), "13.09.2026")
	assert_eq(LeaderboardTextScript.format_date(""), "")


func test_the_podium_has_its_own_colors_and_the_rest_share_one() -> void:
	assert_ne(LeaderboardTextScript.rank_color(1), LeaderboardTextScript.rank_color(2))
	assert_ne(LeaderboardTextScript.rank_color(3), LeaderboardTextScript.rank_color(4))
	assert_eq(LeaderboardTextScript.rank_color(4), LeaderboardTextScript.rank_color(20))


func test_every_ending_has_a_color() -> void:
	for ending : String in ["survived", "season_over", "busted", "bankrupt", ""]:
		assert_ne(LeaderboardTextScript.ending_color(ending), LeaderboardTextScript.DEFAULT_COLOR)
