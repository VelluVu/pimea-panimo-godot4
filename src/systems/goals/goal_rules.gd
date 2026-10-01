class_name GoalRules
extends RefCounted

## The pure decisions behind a GoalBoard, with no state or signals, so they can be
## unit-tested.

enum Outcome { PENDING, SUCCEEDED, FAILED }


## Whether `progress` toward `target` settles the goal right now.
static func check_outcome(goal : GoalData, progress : int, target : int) -> Outcome:
	if goal.is_avoid():
		return Outcome.FAILED if progress > target else Outcome.PENDING
	return Outcome.SUCCEEDED if progress >= target else Outcome.PENDING


## The slots a progress event of `kind` with `detail` advances.
static func matching_slots(goals : Array[GoalData], kind : int, detail : int = -1) -> Array[int]:
	var slots : Array[int] = []
	for slot : int in range(goals.size()):
		var goal : GoalData = goals[slot]
		if goal != null and goal.matches(kind, detail):
			slots.append(slot)
	return slots


## A random pool goal whose kind no active slot already has, so concurrent goals
## differ in kind and tiers of one goal never show together. `active_goals`
## includes the slot being replaced, so its replacement is a different kind too.
## Null when the pool has nothing left.
static func pick_new_goal(pool : Array[GoalData], active_goals : Array[GoalData]) -> GoalData:
	var active_kinds : Dictionary = {}
	for goal : GoalData in active_goals:
		if goal != null:
			active_kinds[goal.get_kind()] = true

	var candidates : Array[GoalData] = []
	for goal : GoalData in pool:
		if not active_kinds.has(goal.get_kind()):
			candidates.append(goal)
	if candidates.is_empty():
		return null
	return candidates.pick_random()
