class_name DailyGoalRules
extends RefCounted

## This game's daily goal maths, with no state, signals or autoloads, so it can be
## unit-tested. Outcomes, matching and picking are the goals system's GoalRules.


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
