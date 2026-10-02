@tool
extends McpTestSuite

## Unit tests for LeaderboardManager's ranking.
##
## Only get_rank() (a pure read over in-memory ConfigFile state; the score itself is
## RunScore, see test_run_score.gd) is covered here — the
## autoload's _on_game_ended()/_insert_entry() persistence path reaches
## BrewEngine.current_brewery and disk I/O, which this @tool-context test
## harness cannot exercise (same limitation documented in
## test_brew_resolver.gd and test_customer_data.gd). A fresh instance is
## created via preload() rather than the LeaderboardManager autoload
## singleton, so these tests never touch the real user://leaderboard.cfg.

const LeaderboardManagerScript := preload("res://src/autoload/leaderboard_manager.gd")


func suite_name() -> String:
	return "leaderboard_manager"


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
