@tool
extends McpTestSuite

## GameSpeed's cycle and the 1x it falls back to under a pause.

const GameSpeedScript := preload("res://src/brewery/game_speed.gd")


func suite_name() -> String:
	return "game_speed"


func test_speeds_cycle_back_to_normal() -> void:
	var index : int = 0
	var seen : Array[float] = []
	for i : int in GameSpeedScript.SPEEDS.size():
		seen.append(GameSpeedScript.time_scale(index, false))
		index = GameSpeedScript.next_index(index)
	assert_eq(index, 0)
	assert_eq(seen[0], 1.0)
	assert_true(seen[seen.size() - 1] > 1.0)


func test_paused_tree_runs_at_normal_speed() -> void:
	assert_eq(GameSpeedScript.time_scale(GameSpeedScript.SPEEDS.size() - 1, true), 1.0)
