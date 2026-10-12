@tool
extends McpTestSuite

## OnlineLeaderboard without a backend: an unconfigured client never sends and says so.

const OnlineLeaderboardScript := preload("res://src/systems/online_leaderboard/online_leaderboard.gd")


func suite_name() -> String:
	return "online_leaderboard"


func test_configured_needs_url_and_key() -> void:
	var board : OnlineLeaderboard = track(OnlineLeaderboardScript.new())
	assert_false(board.is_configured())
	board.base_url = "https://example.supabase.co"
	assert_false(board.is_configured())
	board.api_key = "key"
	assert_true(board.is_configured())


func test_an_unconfigured_submit_fails_at_once() -> void:
	var board : OnlineLeaderboard = track(OnlineLeaderboardScript.new())
	var failures : Array = []
	board.request_failed.connect(func(action : StringName, _message : String) -> void: failures.append(action))
	board.submit({})
	board.fetch_top(10)
	assert_eq(failures, [OnlineLeaderboardScript.ACTION_SUBMIT, OnlineLeaderboardScript.ACTION_FETCH])
	assert_eq(board.get_child_count(), 0)
