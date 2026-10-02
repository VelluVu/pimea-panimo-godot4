class_name RunScore
extends RefCounted

## The run's leaderboard score and the Olutoppi renown paid for it. A run is scored
## once, at its first ending (the latest is day DayRules.SURVIVAL_DAY_TARGET), so
## playing on afterwards can never raise it; continued days only pay reduced renown.

const DAY_POINTS : int = 100
const REPUTATION_POINTS : int = 10
const BOTTLE_POINTS : int = 1
## Reaching the target day as a legend must always beat any run that did not.
const SURVIVAL_BONUS : int = 1500
## Harder modifiers multiply the score by 1 + difficulty * weight, easier ones lower it.
const DIFFICULTY_WEIGHT : float = 0.5
const MIN_MULTIPLIER : float = 0.5

const RENOWN_DIVISOR : float = 20.0
## A bust already costs the run, so it still pays a little.
const RENOWN_FLOOR : int = 5
## A night of continued play pays this share of what the same day would have scored.
const CONTINUED_RENOWN_RATE : float = 0.5


static func difficulty_multiplier(run_modifier : RunModifier) -> float:
	if run_modifier == null:
		return 1.0
	return maxf(MIN_MULTIPLIER, 1.0 + run_modifier.get_difficulty_score() * DIFFICULTY_WEIGHT)


static func scored_days(day : int) -> int:
	return mini(day, DayRules.SURVIVAL_DAY_TARGET)


static func bonus(ending_type : String) -> int:
	return SURVIVAL_BONUS if ending_type == DayRules.ENDING_SURVIVED else 0


static func base_points(day : int, reputation : int, bottles : int, ending_type : String) -> int:
	return scored_days(day) * DAY_POINTS + maxi(0, reputation) * REPUTATION_POINTS + bottles * BOTTLE_POINTS + bonus(ending_type)


static func score(day : int, reputation : int, bottles : int, ending_type : String, run_modifier : RunModifier = null) -> int:
	return roundi(base_points(day, reputation, bottles, ending_type) * difficulty_multiplier(run_modifier))


static func renown(run_score : int) -> int:
	return maxi(RENOWN_FLOOR, roundi(run_score / RENOWN_DIVISOR))


## Renown for one night after the run was scored: that day's points and bottles, at a reduced rate.
static func continued_day_renown(bottles_sold_that_day : int, run_modifier : RunModifier = null) -> int:
	var points : float = (DAY_POINTS + bottles_sold_that_day * BOTTLE_POINTS) * difficulty_multiplier(run_modifier)
	return roundi(points / RENOWN_DIVISOR * CONTINUED_RENOWN_RATE)


## The run's score with its parts, as stored on the leaderboard (LeaderboardText shows
## it). An empty `ending_type` is the run in progress, without the survival bonus.
static func entry(day : int, reputation : int, bottles : int, ending_type : String, run_modifier : RunModifier = null) -> Dictionary:
	return {
		"ending_type": ending_type,
		"days_survived": scored_days(day),
		"reputation": reputation,
		"lifetime_bottles_sold": bottles,
		"bonus": bonus(ending_type),
		"multiplier": difficulty_multiplier(run_modifier),
		"modifier_name": run_modifier.modifier_name if run_modifier != null else "",
		"score": score(day, reputation, bottles, ending_type, run_modifier),
	}


static func entry_for(brewery : Brewery, ending_type : String) -> Dictionary:
	return entry(brewery.current_day, brewery.reputation, brewery.lifetime_bottles_sold, ending_type, brewery.run_modifier)
