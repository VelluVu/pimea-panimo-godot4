class_name DailyGoalRules
extends RefCounted

## This game's daily goal maths, stateless for tests; outcomes and picking are GoalRules.


## Gain since the goal was rolled, re-derived each time since reputation can also fall.
static func reputation_progress(reputation : int, baseline : int) -> int:
	return maxi(0, reputation - baseline)


## A goal's outcome on `day` is {money, reputation, xp, risk}: success pays, a failure costs
## reputation and risk. `apply_penalty` false (stock missing for an event) fails without
## cost. Day 1 is for learning: its failures cost nothing.
const PENALTY_FREE_DAYS : int = 1


static func resolution_effects(goal : DailyGoalData, succeeded : bool, apply_penalty : bool, day : int) -> Dictionary:
	var effects : Dictionary = {"money": 0, "reputation": 0, "xp": 0, "risk": 0}
	if succeeded:
		effects.money = goal.get_effective_reward_money(day)
		effects.reputation = goal.get_effective_reward_reputation(day)
		effects.xp = goal.get_effective_reward_xp(day)
	elif apply_penalty and day > PENALTY_FREE_DAYS:
		effects.reputation = -goal.penalty_reputation
		effects.risk = goal.penalty_risk
	return effects


## Whether `goal` may roll on `day`; no wash goal while the Tynnyrinpesukone runs.
static func can_offer(goal : DailyGoalData, day : int, washer_running : bool) -> bool:
	if day < goal.min_day:
		return false
	return not (washer_running and goal.goal_type == DailyGoalData.GoalType.WASH_KEGS)
