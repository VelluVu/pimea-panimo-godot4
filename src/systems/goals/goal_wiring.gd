class_name GoalWiring
extends GoalBoard

## This game's daily goals: the one file to edit after copying the goals system.
## Feeds progress from BrewerySignals, ends the period on TimeManager.day_changed,
## pays rewards to the Brewery and keeps the slots on the Brewery so they are saved
## with the run. The game's DailyGoalManager autoload extends this.

## With the paid amounts, for the toast and the day recap.
signal daily_goal_resolved(goal_name: String, succeeded: bool, money: int, reputation: int, xp: int, risk: int)

const DAILY_GOAL_FOLDER_PATH : String = "res://src/resources/daily_goals/"
const ACTIVE_GOAL_COUNT : int = 3
## Goals rolled per day, the morning's three included. Without a limit a finished goal
## was replaced at once, so cheap goals could be chained all day for reputation and XP.
const DAILY_GOAL_ROLLS : int = 5
const NO_EFFECTS : Dictionary = {"money": 0, "reputation": 0, "xp": 0, "risk": 0}


func _init() -> void:
	set_slot_count(ACTIVE_GOAL_COUNT)


func _ready() -> void:
	goal_pool.assign(ResourceFolder.load_all(DAILY_GOAL_FOLDER_PATH, DailyGoalData).filter(func(goal : DailyGoalData) -> bool: return not goal.retired))
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)
	BrewerySignals.beer_brewed.connect(func(style : int) -> void: add_progress(DailyGoalData.GoalType.BREW_STYLE, 1, style))
	BrewerySignals.bottles_sold.connect(func(amount : int) -> void: add_progress(DailyGoalData.GoalType.SELL_BOTTLES, amount))
	BrewerySignals.beer_sale_breakdown.connect(func(entry : SaleReceiptEntry) -> void: add_progress(DailyGoalData.GoalType.EARN_MONEY, roundi(entry.net_income)))
	BrewerySignals.customer_unhappy.connect(add_progress.bind(DailyGoalData.GoalType.UNHAPPY_CUSTOMERS_MAX, 1))
	BrewerySignals.special_event_resolved.connect(_on_special_event_resolved)
	BrewerySignals.keg_shipped_to_bar.connect(_on_keg_shipped_to_bar)
	BrewEngine.brewery_changed.connect(_load_from_brewery)
	BrewEngine.brewery_about_to_save.connect(_flush_to_brewery)
	# A slot left empty by yesterday's limit gets its goal in the morning.
	TimeManager.day_changed.connect(func(_day : int) -> void: end_period(); fill_empty_slots())
	# The boot-time Brewery was created before this autoload existed.
	if BrewEngine.current_brewery != null:
		_load_from_brewery(BrewEngine.current_brewery)


## Rolls the first goals once the tutorial is done, and re-derives REPUTATION_GAIN
## progress from live reputation.
func _on_brewery_state_changed(brewery : Brewery) -> void:
	if not brewery.tutorial_complete():
		return

	for i : int in get_slot_count():
		var goal : DailyGoalData = active_goals[i] as DailyGoalData
		if goal == null:
			_assign_new_goal(i)
		elif goal.goal_type == DailyGoalData.GoalType.REPUTATION_GAIN:
			set_progress(i, DailyGoalRules.reputation_progress(brewery.reputation, get_baseline(i)))


## Counts full kegs only: the goal reads "Vie tynnyri baariin", and a drawn batch is no keg.
func _on_keg_shipped_to_bar(_style_name : String, _bar_name : String, bottles : int, _payout : float, _risk_added : int) -> void:
	if KegRules.is_full_keg(bottles):
		add_progress(DailyGoalData.GoalType.SHIP_TO_BAR, 1)


## A failed special event fails an active SPECIAL_EVENT goal outright, without a
## penalty: the brewery tried, it just lacked what was asked for.
func _on_special_event_resolved(succeeded : bool, _event_data : SpecialEventData) -> void:
	if succeeded:
		add_progress(DailyGoalData.GoalType.SPECIAL_EVENT, 1)
	else:
		fail_kind_without_penalty(DailyGoalData.GoalType.SPECIAL_EVENT)


func _can_roll_goals() -> bool:
	var brewery : Brewery = BrewEngine.current_brewery
	return brewery != null and brewery.tutorial_complete()


func _roll_limit() -> int:
	var brewery : Brewery = BrewEngine.current_brewery
	var extra : int = int(brewery.stats.total(PerkStats.EXTRA_DAILY_GOAL_ROLLS)) if brewery != null else 0
	return DAILY_GOAL_ROLLS + extra


func _current_day() -> int:
	return BrewEngine.current_brewery.current_day


## REPUTATION_GAIN goals measure from the reputation at the moment they are rolled.
func _baseline_for(_goal : GoalData) -> int:
	return BrewEngine.current_brewery.reputation


## Plain field changes emit nothing, so they are safe before the replacement is
## rolled, and the new goal's reputation baseline already includes the reward.
func _before_replace(goal : GoalData, succeeded : bool, apply_penalty : bool) -> Variant:
	var brewery : Brewery = BrewEngine.current_brewery
	if brewery == null:
		return NO_EFFECTS
	var effects : Dictionary = DailyGoalRules.resolution_effects(goal as DailyGoalData, succeeded, apply_penalty, brewery.current_day)
	if effects.reputation != 0:
		brewery.change_reputation(effects.reputation, ReputationRules.Source.GOALS)
	if succeeded:
		brewery.change_money(effects.money, MoneyLedger.Source.GOALS)
	return effects


## xp and risk emit brewery_state_changed, which re-checks REPUTATION_GAIN progress,
## so they wait until the resolved goal has left its slot.
func _after_replace(goal : GoalData, succeeded : bool, apply_penalty : bool, context : Variant) -> void:
	var effects : Dictionary = context
	var brewery : Brewery = BrewEngine.current_brewery
	if brewery != null:
		if succeeded:
			brewery.add_xp(effects.xp)
		elif apply_penalty:
			brewery.add_risk(effects.risk)
		BrewerySignals.brewery_state_changed.emit(brewery)
	daily_goal_resolved.emit(goal.goal_name, succeeded, effects.money, effects.reputation, effects.xp, effects.risk)


## A new run and a save from before goals were persisted both hold the defaults
## (null and 0), so one path covers a new run and a loaded one.
func _load_from_brewery(brewery : Brewery) -> void:
	for i : int in get_slot_count():
		load_slot(i, brewery.active_daily_goals[i], brewery.daily_goal_progress[i],
			brewery.daily_goal_reputation_baseline[i], brewery.daily_goal_effective_target[i])
	rolls_used = brewery.daily_goal_rolls_used
	notify_changed()


## Run before a save (BrewEngine.brewery_about_to_save) so the slots are saved with the Brewery.
func _flush_to_brewery(brewery : Brewery) -> void:
	for i : int in get_slot_count():
		brewery.active_daily_goals[i] = active_goals[i] as DailyGoalData
		brewery.daily_goal_progress[i] = get_progress(i)
		brewery.daily_goal_reputation_baseline[i] = get_baseline(i)
		brewery.daily_goal_effective_target[i] = get_effective_target(i)
	brewery.daily_goal_rolls_used = rolls_used
