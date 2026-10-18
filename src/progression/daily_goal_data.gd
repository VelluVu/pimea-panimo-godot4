class_name DailyGoalData
extends GoalData

## One daily goal, loaded from its folder: a new goal is another .tres. Every GoalType is an
## "achieve" goal except UNHAPPY_CUSTOMERS_MAX, an "avoid" one (GoalData).
enum GoalType {
	BREW_STYLE,
	SELL_BOTTLES,
	SPECIAL_EVENT,
	REPUTATION_GAIN,
	EARN_MONEY,
	UNHAPPY_CUSTOMERS_MAX,
	## Full kegs (KegRules.is_full_keg) shipped to any BarContact today (BrewerySignals.keg_shipped_to_bar).
	SHIP_TO_BAR,
	## The season's first batch of any style (BrewerySignals.season_first_brew).
	NEW_STYLE_BREW,
	## Dirty kegs washed today (BrewerySignals.keg_washed).
	WASH_KEGS,
}

@export var goal_type : GoalType = GoalType.EARN_MONEY
## Only read when goal_type == BREW_STYLE.
@export var target_style : BeerStyle.Style = BeerStyle.Style.BULKKILAGER
## Never rolled again, but kept so a save holding this goal still loads.
@export var retired : bool = false
## Not rolled before this day of the season, see DailyGoalRules.can_offer().
@export var min_day : int = 1

@export_group("Palkkio (onnistuminen)")
@export var reward_money : int = 20
@export var reward_reputation : int = 5
@export var reward_xp : int = 20

@export_group("Rangaistus (epäonnistuminen)")
@export var penalty_reputation : int = 3
@export var penalty_risk : int = 5


func get_kind() -> int:
	return goal_type


func is_avoid() -> bool:
	return goal_type == GoalType.UNHAPPY_CUSTOMERS_MAX


## A BREW_STYLE goal counts only its own style; `detail` is the brewed style.
func matches(kind : int, detail : int) -> bool:
	if kind != goal_type:
		return false
	return goal_type != GoalType.BREW_STYLE or target_style == detail


## Success rewards scale with the day like the target (see GoalData.scales_with_day).
func get_effective_reward_money(day : int) -> int:
	return roundi(reward_money * scale_multiplier(day))


func get_effective_reward_reputation(day : int) -> int:
	return roundi(reward_reputation * scale_multiplier(day))


func get_effective_reward_xp(day : int) -> int:
	return roundi(reward_xp * scale_multiplier(day))
