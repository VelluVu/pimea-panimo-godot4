@tool
extends McpTestSuite

## Unit tests for LeaderboardManager's pure scoring/ranking logic.
##
## Only calculate_score() (static) and get_rank()/get_rank_for_stats()
## (pure reads over in-memory ConfigFile state) are covered here — the
## autoload's _on_game_ended()/_insert_entry() persistence path reaches
## BrewEngine.current_brewery and disk I/O, which this @tool-context test
## harness cannot exercise (same limitation documented in
## test_brew_resolver.gd and test_customer_data.gd). A fresh instance is
## created via preload() rather than the LeaderboardManager autoload
## singleton, so these tests never touch the real user://leaderboard.cfg.

const LeaderboardManagerScript := preload("res://src/autoload/leaderboard_manager.gd")


func suite_name() -> String:
	return "leaderboard_manager"


func test_calculate_score_weights_days_reputation_and_bottles() -> void:
	# days_survived*100 + reputation*10 + lifetime_bottles_sold
	assert_eq(LeaderboardManagerScript.calculate_score(10, 20, 30), 1230)


func test_calculate_score_zero_stats_is_zero() -> void:
	assert_eq(LeaderboardManagerScript.calculate_score(0, 0, 0), 0)


func test_get_rank_is_one_when_no_entries_exist() -> void:
	var leaderboard := LeaderboardManagerScript.new()
	assert_eq(leaderboard.get_rank(500), 1)


func test_get_rank_counts_only_strictly_higher_scores() -> void:
	var leaderboard := LeaderboardManagerScript.new()
	leaderboard._config.set_value(
		LeaderboardManagerScript.SECTION,
		LeaderboardManagerScript.KEY_ENTRIES,
		[{"score": 900}, {"score": 500}, {"score": 500}, {"score": 100}]
	)
	assert_eq(leaderboard.get_rank(500), 2, "a tie should not push rank past the higher scores")
	assert_eq(leaderboard.get_rank(1000), 1, "beating every saved entry should be rank 1")
	assert_eq(leaderboard.get_rank(0), 5, "losing to every saved entry should land last")


func test_get_rank_for_stats_matches_calculate_score_then_get_rank() -> void:
	var leaderboard := LeaderboardManagerScript.new()
	leaderboard._config.set_value(
		LeaderboardManagerScript.SECTION,
		LeaderboardManagerScript.KEY_ENTRIES,
		[{"score": LeaderboardManagerScript.calculate_score(5, 10, 15)}]
	)
	# Same stats as the saved entry -> tied, not beaten -> still rank 1.
	assert_eq(leaderboard.get_rank_for_stats(5, 10, 15), 1)
	# Clearly worse stats -> beaten by the saved entry -> rank 2.
	assert_eq(leaderboard.get_rank_for_stats(1, 1, 1), 2)
