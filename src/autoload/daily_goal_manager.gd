#DailyGoalManager (Autoload)
extends Node

## Drives the ACTIVE_GOAL_COUNT concurrent daily goals. The pool is every
## DailyGoalData .tres under DAILY_GOAL_FOLDER_PATH, so a new goal is just a new
## file. The decisions themselves (outcomes, rewards, picking) live in
## DailyGoalRules.
##
## Goals never carry progress across a day. _on_day_changed() resolves whatever
## is still active, and resolving always rolls the slot's replacement, which is
## what gives the new day a fresh set.

signal daily_goal_resolved(goal_name: String, succeeded: bool, money: int, reputation: int, xp: int, risk: int)
## Fired whenever active_goals or a slot's progress changes, so DailyGoalsPanel
## needs only this one signal.
signal goal_progress_changed()

const DAILY_GOAL_FOLDER_PATH : String = "res://src/resources/daily_goals/"
const WARNING_FOLDER_OPEN_FAILED : String = "DailyGoalManager: Failed to open path: "

const ACTIVE_GOAL_COUNT : int = 3

var goal_pool : Array[DailyGoalData] = []

## Index-aligned with the arrays below. null means the slot has no goal: nothing
## rolled yet (pre-tutorial), or the pool ran out of distinct candidates.
var active_goals : Array[DailyGoalData] = [null, null, null]
var _progress : Array[int] = [0, 0, 0]
## REPUTATION_GAIN progress is measured from this snapshot of reputation.
var _reputation_baseline : Array[int] = [0, 0, 0]
## The target captured when the goal was rolled, so a day change cannot move it
## mid-day. See DailyGoalData.get_effective_target().
var _effective_target : Array[int] = [0, 0, 0]


func _ready() -> void:
	_load_goal_pool()

	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)
	BrewEngine.brewery_changed.connect(_on_brewery_changed)
	BrewEngine.brewery_about_to_save.connect(_flush_to_brewery)
	# The boot-time Brewery was created before this autoload existed.
	if BrewEngine.current_brewery != null:
		_on_brewery_changed(BrewEngine.current_brewery)
	BrewerySignals.beer_brewed.connect(_on_beer_brewed)
	BrewerySignals.bottles_sold.connect(_on_bottles_sold)
	BrewerySignals.beer_sale_breakdown.connect(_on_beer_sale_breakdown)
	BrewerySignals.customer_unhappy.connect(_on_customer_unhappy)
	BrewerySignals.special_event_resolved.connect(_on_special_event_resolved)
	BrewerySignals.keg_shipped_to_bar.connect(_on_keg_shipped_to_bar)
	TimeManager.day_changed.connect(_on_day_changed)


func _load_goal_pool() -> void:
	var dir := DirAccess.open(DAILY_GOAL_FOLDER_PATH)
	if dir == null:
		push_warning(WARNING_FOLDER_OPEN_FAILED + DAILY_GOAL_FOLDER_PATH)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res = load(DAILY_GOAL_FOLDER_PATH + file_name)
			if res is DailyGoalData:
				goal_pool.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()


func get_progress(slot : int) -> int:
	return _progress[slot]


func get_effective_target(slot : int) -> int:
	return _effective_target[slot]


## Every active goal belongs to the run that was current when it was rolled,
## so a different Brewery (new game or load) means restoring from that
## Brewery's own saved fields instead.
func _on_brewery_changed(brewery : Brewery) -> void:
	_load_from_brewery(brewery)


func _on_brewery_state_changed(brewery : Brewery) -> void:
	if not brewery.tutorial_complete():
		return

	for i in range(ACTIVE_GOAL_COUNT):
		if active_goals[i] == null:
			_assign_new_goal(i)
			continue
		if active_goals[i].goal_type == DailyGoalData.GoalType.REPUTATION_GAIN:
			_progress[i] = DailyGoalRules.reputation_progress(brewery.reputation, _reputation_baseline[i])
			goal_progress_changed.emit()
			_check_goal_outcome(i)


func _on_beer_brewed(style : int) -> void:
	_add_progress(DailyGoalData.GoalType.BREW_STYLE, 1, style)


func _on_bottles_sold(amount : int) -> void:
	_add_progress(DailyGoalData.GoalType.SELL_BOTTLES, amount)


func _on_beer_sale_breakdown(entry : SaleReceiptEntry) -> void:
	_add_progress(DailyGoalData.GoalType.EARN_MONEY, roundi(entry.net_income))


func _on_customer_unhappy() -> void:
	_add_progress(DailyGoalData.GoalType.UNHAPPY_CUSTOMERS_MAX, 1)


func _on_keg_shipped_to_bar(_style_name: String, _bar_name: String, bottles: int, _payout: float, _risk_added: int) -> void:
	_add_progress(DailyGoalData.GoalType.SHIP_TO_BAR, bottles)


## A failed special event fails an active SPECIAL_EVENT goal outright, without a
## penalty: the brewery tried, it just lacked what was asked for.
func _on_special_event_resolved(succeeded : bool) -> void:
	if succeeded:
		_add_progress(DailyGoalData.GoalType.SPECIAL_EVENT, 1)
	else:
		_fail_goal_type_no_penalty(DailyGoalData.GoalType.SPECIAL_EVENT)


func _fail_goal_type_no_penalty(goal_type : DailyGoalData.GoalType) -> void:
	for i in range(ACTIVE_GOAL_COUNT):
		var goal := active_goals[i]
		if goal != null and goal.goal_type == goal_type:
			_resolve_goal(i, false, false)
			return


func _add_progress(goal_type : DailyGoalData.GoalType, amount : int, required_style : int = -1) -> void:
	for slot : int in DailyGoalRules.matching_slots(active_goals, goal_type, required_style):
		_progress[slot] += amount
		goal_progress_changed.emit()
		_check_goal_outcome(slot)


func _check_goal_outcome(slot : int) -> void:
	var goal := active_goals[slot]
	if goal == null:
		return

	match DailyGoalRules.check_outcome(goal, _progress[slot], _effective_target[slot]):
		DailyGoalRules.Outcome.SUCCEEDED:
			_resolve_goal(slot, true)
		DailyGoalRules.Outcome.FAILED:
			_resolve_goal(slot, false)


## Settles a goal, applies its reward or penalty (see
## DailyGoalRules.resolution_effects()) and always rolls the slot's replacement.
## Called when a goal completes, an avoid-goal is breached, a special event fails,
## and from _on_day_changed() for whatever is still pending.
func _resolve_goal(slot : int, succeeded : bool, apply_penalty : bool = true) -> void:
	var goal := active_goals[slot]
	if goal == null:
		return

	var brewery := BrewEngine.current_brewery
	var effects : Dictionary = {"money": 0, "reputation": 0, "xp": 0, "risk": 0}
	if brewery != null:
		effects = DailyGoalRules.resolution_effects(goal, succeeded, apply_penalty, brewery.current_day)
		# Plain field changes emit nothing, so they are safe before the slot is
		# replaced. xp and risk go after, since they emit brewery_state_changed.
		if effects.reputation != 0:
			brewery.reputation = max(0, brewery.reputation + effects.reputation)
		if succeeded:
			brewery.money += effects.money

	# Replace the slot BEFORE anything that emits brewery_state_changed. This
	# script re-checks every slot on that signal, and REPUTATION_GAIN progress is
	# derived from live reputation, so a resolved goal left in place would see
	# its own reward re-cross its target and resolve again, recursing forever.
	_assign_new_goal(slot)

	if brewery != null:
		if succeeded:
			brewery.add_xp(effects.xp)
		elif apply_penalty:
			brewery.add_risk(effects.risk)
		BrewerySignals.brewery_state_changed.emit(brewery)

	daily_goal_resolved.emit(goal.goal_name, succeeded, effects.money, effects.reputation, effects.xp, effects.risk)


func _assign_new_goal(slot : int) -> void:
	var brewery := BrewEngine.current_brewery
	var new_goal : DailyGoalData = null
	if brewery != null and brewery.tutorial_complete():
		new_goal = DailyGoalRules.pick_new_goal(goal_pool, active_goals)

	active_goals[slot] = new_goal
	if new_goal != null:
		_progress[slot] = 0
		_reputation_baseline[slot] = brewery.reputation
		_effective_target[slot] = new_goal.get_effective_target(brewery.current_day)
	goal_progress_changed.emit()


## Restores the tracking arrays from the Brewery's saved fields. A new run and a
## save from before goals were persisted both hold the defaults (null and 0), so
## one path covers a new run and a loaded one.
func _load_from_brewery(brewery : Brewery) -> void:
	for i in range(ACTIVE_GOAL_COUNT):
		active_goals[i] = brewery.active_daily_goals[i]
		_progress[i] = brewery.daily_goal_progress[i]
		_reputation_baseline[i] = brewery.daily_goal_reputation_baseline[i]
		_effective_target[i] = brewery.daily_goal_effective_target[i]
	goal_progress_changed.emit()


## The mirror of _load_from_brewery(), run before a save (see
## BrewEngine.brewery_about_to_save) so it is saved with the Brewery.
func _flush_to_brewery(brewery : Brewery) -> void:
	brewery.active_daily_goals = active_goals.duplicate()
	brewery.daily_goal_progress = _progress.duplicate()
	brewery.daily_goal_reputation_baseline = _reputation_baseline.duplicate()
	brewery.daily_goal_effective_target = _effective_target.duplicate()


## A surviving avoid-goal succeeds; an unfinished achieve-goal ran out of time.
func _on_day_changed(_new_day : int) -> void:
	for i in range(ACTIVE_GOAL_COUNT):
		var goal := active_goals[i]
		if goal == null:
			continue
		_resolve_goal(i, DailyGoalRules.is_avoid_type(goal))
