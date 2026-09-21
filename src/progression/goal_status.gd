class_name GoalStatus
extends RefCounted

## How a goal line reads at a glance: each stat judges itself. Pure rules, so
## DailyGoalsPanel only maps a State to a colour.

enum State { PENDING, MET, FAILING }

## "Just one more sale" nudge: an achieve goal that crossed this share of its target
## without meeting it yet. Never applies to avoid goals, where pulsing "getting
## closer to failing" would send the wrong signal.
const NEAR_MISS_PROGRESS_RATIO : float = 0.8


static func from_met(met : bool) -> State:
	return State.MET if met else State.PENDING


static func run_day(current_day : int, target_day : int, money_in_danger : bool) -> State:
	if current_day >= target_day:
		return State.MET
	return State.FAILING if money_in_danger else State.PENDING


static func run_reputation(reputation : int, min_reputation : int, money_in_danger : bool) -> State:
	if money_in_danger:
		return State.FAILING
	return from_met(reputation >= min_reputation)


## Avoid goals read as a danger meter (at the limit = failing), achieve goals as progress.
static func daily_goal(goal_type : DailyGoalData.GoalType, progress : int, target : int) -> State:
	var reached : bool = progress_ratio(progress, target) >= 1.0
	if goal_type == DailyGoalData.GoalType.UNHAPPY_CUSTOMERS_MAX:
		return State.FAILING if reached else State.PENDING
	return from_met(reached)


static func is_near_miss(goal_type : DailyGoalData.GoalType, progress : int, target : int) -> bool:
	if goal_type == DailyGoalData.GoalType.UNHAPPY_CUSTOMERS_MAX:
		return false
	var ratio : float = progress_ratio(progress, target)
	return ratio < 1.0 and ratio >= NEAR_MISS_PROGRESS_RATIO


static func progress_ratio(progress : int, target : int) -> float:
	return float(progress) / float(maxi(1, target))
