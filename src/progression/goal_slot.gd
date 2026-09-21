class_name GoalSlot
extends RefCounted

## One of DailyGoalManager's concurrent goal slots: the goal and its tracking state.
## A null goal means the slot is empty: nothing rolled yet (pre-tutorial), or the pool
## ran out of distinct candidates.

var goal : DailyGoalData = null
var progress : int = 0
## REPUTATION_GAIN progress is measured from this snapshot of reputation.
var reputation_baseline : int = 0
## Captured when the goal is rolled, so a day change cannot move it mid-day.
## See DailyGoalData.get_effective_target().
var effective_target : int = 0


func has_goal() -> bool:
	return goal != null


func start(new_goal : DailyGoalData, reputation : int, day : int) -> void:
	goal = new_goal
	progress = 0
	reputation_baseline = reputation
	effective_target = new_goal.get_effective_target(day)


func clear() -> void:
	goal = null
