class_name GoalSlot
extends RefCounted

## One of a GoalBoard's concurrent slots: the goal and its tracking state. A null
## goal means the slot is empty: rolling is not allowed yet, or the pool ran out
## of distinct kinds.

var goal : GoalData = null
var progress : int = 0
## A snapshot taken when the goal was rolled, for goals whose progress is measured
## from a starting value (in this game, reputation).
var baseline : int = 0
## Captured when the goal is rolled, so a day change cannot move it mid-day.
var effective_target : int = 0


func has_goal() -> bool:
	return goal != null


func start(new_goal : GoalData, start_baseline : int, day : int) -> void:
	goal = new_goal
	progress = 0
	baseline = start_baseline
	effective_target = new_goal.get_effective_target(day)


func clear() -> void:
	goal = null
