@tool
extends McpTestSuite

## Unit tests for GoalSlot: starting a goal snapshots its tracking state.

const GoalSlotScript := preload("res://src/progression/goal_slot.gd")


func suite_name() -> String:
	return "goal_slot"


func _make_goal() -> DailyGoalData:
	var goal := DailyGoalData.new()
	goal.goal_type = DailyGoalData.GoalType.SELL_BOTTLES
	goal.target_amount = 6
	return goal


func test_new_slot_is_empty() -> void:
	assert_false(GoalSlotScript.new().has_goal())


func test_start_resets_progress_and_snapshots_reputation_and_target() -> void:
	var slot := GoalSlotScript.new()
	slot.progress = 4
	var goal := _make_goal()

	slot.start(goal, 25, 3)

	assert_true(slot.has_goal())
	assert_eq(slot.goal, goal)
	assert_eq(slot.progress, 0)
	assert_eq(slot.reputation_baseline, 25)
	assert_eq(slot.effective_target, goal.get_effective_target(3))


func test_clear_empties_the_slot_but_keeps_its_counters() -> void:
	var slot := GoalSlotScript.new()
	slot.start(_make_goal(), 10, 1)
	slot.progress = 2

	slot.clear()

	assert_false(slot.has_goal())
	assert_eq(slot.progress, 2, "matches the old behaviour: only the goal is nulled")
