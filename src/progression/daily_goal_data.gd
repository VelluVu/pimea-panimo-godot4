class_name DailyGoalData
extends Resource

## One entry in DailyGoalManager's pool, auto-loaded from
## res://src/resources/daily_goals/ the same way CustomerData/SpecialEventData
## are — adding a new daily goal is just dropping in another .tres, no code
## change needed.
##
## Every type here is an "achieve" goal (progress climbs toward
## target_amount, success on reaching it, failure if the day ends first)
## except UNHAPPY_CUSTOMERS_MAX, which DailyGoalManager treats as an "avoid"
## goal instead: progress climbing PAST target_amount is an immediate
## failure, and never breaching it by day's end is the success case. See
## DailyGoalRules.is_avoid_type().
enum GoalType {
	BREW_STYLE,
	SELL_BOTTLES,
	SPECIAL_EVENT,
	REPUTATION_GAIN,
	EARN_MONEY,
	UNHAPPY_CUSTOMERS_MAX,
	## Progress is bottles shipped to any BarContact today (Brewery.
	## ship_batch_to_bar(), see BrewerySignals.keg_shipped_to_bar) — an
	## "achieve" type like every other one here except UNHAPPY_CUSTOMERS_MAX.
	SHIP_TO_BAR,
}

@export var goal_name : String = ""
@export var goal_type : GoalType = GoalType.EARN_MONEY
@export var target_amount : int = 1
## Only read when goal_type == BREW_STYLE.
@export var target_style : BeerStyle.Style = BeerStyle.Style.BULKKILAGER
## Always takes exactly (progress, target_amount) as %d %d — even a
## one-shot goal (SPECIAL_EVENT/BREW_STYLE, target_amount 1) just reads as
## "0/1" then "1/1", so every goal shows the same kind of progress instead
## of some having numbers and others not.
@export var progress_format : String = "%d/%d"

@export_group("Palkkio (onnistuminen)")
@export var reward_money : int = 20
@export var reward_reputation : int = 5
@export var reward_xp : int = 20

@export_group("Rangaistus (epäonnistuminen)")
@export var penalty_reputation : int = 3
@export var penalty_risk : int = 5

@export_group("Päiväskaalaus")
## Growth applied to target_amount (and, proportionally, the success
## rewards) per day beyond day 1 — e.g. "sell 8 bottles" stops meaning
## anything by day 15 with a fixed target, so quantity-based goals can opt
## into scaling instead. Leave scales_with_day false for one-shot goals
## (BREW_STYLE/SPECIAL_EVENT, where "brew 1 IPA" doesn't get harder) and
## for UNHAPPY_CUSTOMERS_MAX (an avoid-type goal — a RISING target there
## would make it easier, not harder). See DailyGoalManager._assign_new_goal(),
## which snapshots get_effective_target()/get_effective_reward_*() once
## per assignment rather than re-deriving them live, so a goal's numbers
## can't shift mid-day if current_day changes under it.
@export var scales_with_day : bool = false
@export var target_scale_per_day : float = 0.08


func _day_scale_multiplier(day : int) -> float:
	if not scales_with_day:
		return 1.0
	return 1.0 + target_scale_per_day * float(maxi(0, day - 1))


func get_effective_target(day : int) -> int:
	return maxi(1, roundi(target_amount * _day_scale_multiplier(day)))


func get_effective_reward_money(day : int) -> int:
	return roundi(reward_money * _day_scale_multiplier(day))


func get_effective_reward_reputation(day : int) -> int:
	return roundi(reward_reputation * _day_scale_multiplier(day))


func get_effective_reward_xp(day : int) -> int:
	return roundi(reward_xp * _day_scale_multiplier(day))


## target defaults to target_amount (the unscaled base) so callers that
## don't care about day-scaling (e.g. a preview outside a live run) still
## get a sensible number — DailyGoalsPanel always passes DailyGoalManager.
## get_effective_target() explicitly instead of relying on this default.
func get_progress_text(progress : int, target : int = -1) -> String:
	var effective_target := target_amount if target < 0 else target
	return progress_format % [progress, effective_target]
