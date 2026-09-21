class_name DailyGoalRules
extends RefCounted

## The pure decisions behind daily goals, with no state, signals or autoloads, so
## they can be unit-tested. DailyGoalManager owns the active goals and applies
## the results to the Brewery.
##
## Every goal type is an "achieve" goal (success on reaching its target, failure
## if the day ends first) except UNHAPPY_CUSTOMERS_MAX, an "avoid" goal: passing
## its target fails it at once, and never passing it by day's end is the success.

enum Outcome { PENDING, SUCCEEDED, FAILED }


static func is_avoid_type(goal : DailyGoalData) -> bool:
	return goal.goal_type == DailyGoalData.GoalType.UNHAPPY_CUSTOMERS_MAX


## Whether `progress` toward `target` settles the goal right now.
static func check_outcome(goal : DailyGoalData, progress : int, target : int) -> Outcome:
	if is_avoid_type(goal):
		return Outcome.FAILED if progress > target else Outcome.PENDING
	return Outcome.SUCCEEDED if progress >= target else Outcome.PENDING


## The slots a progress event of `goal_type` advances. `required_style` only
## matters for BREW_STYLE goals; every other type ignores it.
static func matching_slots(goals : Array[DailyGoalData], goal_type : DailyGoalData.GoalType, required_style : int = -1) -> Array[int]:
	var slots : Array[int] = []
	for slot : int in range(goals.size()):
		var goal : DailyGoalData = goals[slot]
		if goal == null or goal.goal_type != goal_type:
			continue
		if goal_type == DailyGoalData.GoalType.BREW_STYLE and goal.target_style != required_style:
			continue
		slots.append(slot)
	return slots


## REPUTATION_GAIN progress is the gain since the goal was rolled. Reputation can
## also fall (a bad sale, a raid), so it is re-derived from the snapshot each
## time instead of accumulated.
static func reputation_progress(reputation : int, baseline : int) -> int:
	return maxi(0, reputation - baseline)


## What resolving a goal pays or costs on `day`, as {money, reputation, xp, risk}.
## Success pays money, reputation and xp. A genuine failure costs reputation and
## risk. `apply_penalty` false is the "tried in good faith" failure (a special
## event whose stock was missing): the goal still fails, but nothing changes.
static func resolution_effects(goal : DailyGoalData, succeeded : bool, apply_penalty : bool, day : int) -> Dictionary:
	var effects : Dictionary = {"money": 0, "reputation": 0, "xp": 0, "risk": 0}
	if succeeded:
		effects.money = goal.get_effective_reward_money(day)
		effects.reputation = goal.get_effective_reward_reputation(day)
		effects.xp = goal.get_effective_reward_xp(day)
	elif apply_penalty:
		effects.reputation = -goal.penalty_reputation
		effects.risk = goal.penalty_risk
	return effects


## A random pool goal whose type no active slot already has, so concurrent goals differ
## in kind and tiers of one goal never show together. `active_goals` includes the slot
## being replaced, so its replacement is a different type too. Null when the pool has
## nothing left.
static func pick_new_goal(pool : Array[DailyGoalData], active_goals : Array[DailyGoalData]) -> DailyGoalData:
	var active_types : Dictionary = {}
	for goal : DailyGoalData in active_goals:
		if goal != null:
			active_types[goal.goal_type] = true

	var candidates : Array[DailyGoalData] = []
	for goal : DailyGoalData in pool:
		if not active_types.has(goal.goal_type):
			candidates.append(goal)
	if candidates.is_empty():
		return null
	return candidates.pick_random()
