extends Node

## Drives the ACTIVE_GOAL_COUNT concurrent daily goals. The pool is every DailyGoalData
## .tres under DAILY_GOAL_FOLDER_PATH, so a new goal is just a new file. The decisions
## themselves (outcomes, rewards, picking) live in DailyGoalRules.
##
## Goals never carry progress across a day: _on_day_changed() resolves whatever is
## still active, and resolving always rolls the slot's replacement.

signal daily_goal_resolved(goal_name: String, succeeded: bool, money: int, reputation: int, xp: int, risk: int)
## Fired whenever a goal or its progress changes, so DailyGoalsPanel needs only this.
signal goal_progress_changed()

const DAILY_GOAL_FOLDER_PATH : String = "res://src/resources/daily_goals/"
const ACTIVE_GOAL_COUNT : int = 3
const NO_EFFECTS : Dictionary = {"money": 0, "reputation": 0, "xp": 0, "risk": 0}

var goal_pool : Array[DailyGoalData] = []

## The goal in each slot, index-aligned with get_progress() and get_effective_target().
var active_goals : Array[DailyGoalData]:
	get:
		var goals : Array[DailyGoalData] = []
		for slot : GoalSlot in _slots:
			goals.append(slot.goal)
		return goals

var _slots : Array[GoalSlot] = []


func _init() -> void:
	for i : int in ACTIVE_GOAL_COUNT:
		_slots.append(GoalSlot.new())


func _ready() -> void:
	goal_pool.assign(ResourceFolder.load_all(DAILY_GOAL_FOLDER_PATH, DailyGoalData))
	_connect_signals()
	# The boot-time Brewery was created before this autoload existed.
	if BrewEngine.current_brewery != null:
		_load_from_brewery(BrewEngine.current_brewery)


func get_progress(slot : int) -> int:
	return _slots[slot].progress


func get_effective_target(slot : int) -> int:
	return _slots[slot].effective_target


func _connect_signals() -> void:
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)
	BrewerySignals.beer_brewed.connect(_on_beer_brewed)
	BrewerySignals.bottles_sold.connect(_on_bottles_sold)
	BrewerySignals.beer_sale_breakdown.connect(_on_beer_sale_breakdown)
	BrewerySignals.customer_unhappy.connect(_on_customer_unhappy)
	BrewerySignals.special_event_resolved.connect(_on_special_event_resolved)
	BrewerySignals.keg_shipped_to_bar.connect(_on_keg_shipped_to_bar)
	BrewEngine.brewery_changed.connect(_load_from_brewery)
	BrewEngine.brewery_about_to_save.connect(_flush_to_brewery)
	TimeManager.day_changed.connect(_on_day_changed)


func _on_brewery_state_changed(brewery : Brewery) -> void:
	if not brewery.tutorial_complete():
		return

	for i : int in _slots.size():
		var slot : GoalSlot = _slots[i]
		if not slot.has_goal():
			_assign_new_goal(i)
		elif slot.goal.goal_type == DailyGoalData.GoalType.REPUTATION_GAIN:
			slot.progress = DailyGoalRules.reputation_progress(brewery.reputation, slot.reputation_baseline)
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


func _on_keg_shipped_to_bar(_style_name : String, _bar_name : String, bottles : int, _payout : float, _risk_added : int) -> void:
	_add_progress(DailyGoalData.GoalType.SHIP_TO_BAR, bottles)


## A failed special event fails an active SPECIAL_EVENT goal outright, without a penalty:
## the brewery tried, it just lacked what was asked for.
func _on_special_event_resolved(succeeded : bool) -> void:
	if succeeded:
		_add_progress(DailyGoalData.GoalType.SPECIAL_EVENT, 1)
	else:
		_fail_goal_type_no_penalty(DailyGoalData.GoalType.SPECIAL_EVENT)


## A surviving avoid-goal succeeds; an unfinished achieve-goal ran out of time.
func _on_day_changed(_new_day : int) -> void:
	for i : int in _slots.size():
		var goal : DailyGoalData = _slots[i].goal
		if goal != null:
			_resolve_goal(i, DailyGoalRules.is_avoid_type(goal))


func _add_progress(goal_type : DailyGoalData.GoalType, amount : int, required_style : int = -1) -> void:
	for i : int in DailyGoalRules.matching_slots(active_goals, goal_type, required_style):
		_slots[i].progress += amount
		goal_progress_changed.emit()
		_check_goal_outcome(i)


func _fail_goal_type_no_penalty(goal_type : DailyGoalData.GoalType) -> void:
	for i : int in _slots.size():
		var goal : DailyGoalData = _slots[i].goal
		if goal != null and goal.goal_type == goal_type:
			_resolve_goal(i, false, false)
			return


func _check_goal_outcome(slot_index : int) -> void:
	var slot : GoalSlot = _slots[slot_index]
	if not slot.has_goal():
		return

	match DailyGoalRules.check_outcome(slot.goal, slot.progress, slot.effective_target):
		DailyGoalRules.Outcome.SUCCEEDED:
			_resolve_goal(slot_index, true)
		DailyGoalRules.Outcome.FAILED:
			_resolve_goal(slot_index, false)


## Settles a goal, applies its reward or penalty (see DailyGoalRules.resolution_effects())
## and always rolls the slot's replacement.
func _resolve_goal(slot_index : int, succeeded : bool, apply_penalty : bool = true) -> void:
	var goal : DailyGoalData = _slots[slot_index].goal
	if goal == null:
		return

	var brewery : Brewery = BrewEngine.current_brewery
	var effects : Dictionary = NO_EFFECTS
	if brewery != null:
		effects = DailyGoalRules.resolution_effects(goal, succeeded, apply_penalty, brewery.current_day)
		_apply_field_effects(brewery, effects, succeeded)

	# Replace the slot BEFORE anything that emits brewery_state_changed. _on_brewery_state_changed()
	# re-checks every slot, and REPUTATION_GAIN progress is derived from live reputation, so a
	# resolved goal left in place would see its own reward re-cross its target and resolve
	# again, recursing forever.
	_assign_new_goal(slot_index)

	if brewery != null:
		_apply_emitting_effects(brewery, effects, succeeded, apply_penalty)
	daily_goal_resolved.emit(goal.goal_name, succeeded, effects.money, effects.reputation, effects.xp, effects.risk)


## Plain field changes emit nothing, so they are safe before the slot is replaced.
func _apply_field_effects(brewery : Brewery, effects : Dictionary, succeeded : bool) -> void:
	if effects.reputation != 0:
		brewery.reputation = maxi(0, brewery.reputation + effects.reputation)
	if succeeded:
		brewery.money += effects.money


## xp and risk emit brewery_state_changed, so they go after the slot was replaced.
func _apply_emitting_effects(brewery : Brewery, effects : Dictionary, succeeded : bool, apply_penalty : bool) -> void:
	if succeeded:
		brewery.add_xp(effects.xp)
	elif apply_penalty:
		brewery.add_risk(effects.risk)
	BrewerySignals.brewery_state_changed.emit(brewery)


func _assign_new_goal(slot_index : int) -> void:
	var brewery : Brewery = BrewEngine.current_brewery
	var new_goal : DailyGoalData = null
	if brewery != null and brewery.tutorial_complete():
		new_goal = DailyGoalRules.pick_new_goal(goal_pool, active_goals)

	if new_goal != null:
		_slots[slot_index].start(new_goal, brewery.reputation, brewery.current_day)
	else:
		_slots[slot_index].clear()
	goal_progress_changed.emit()


## A new run and a save from before goals were persisted both hold the defaults (null and
## 0), so one path covers a new run and a loaded one.
func _load_from_brewery(brewery : Brewery) -> void:
	for i : int in _slots.size():
		var slot : GoalSlot = _slots[i]
		slot.goal = brewery.active_daily_goals[i]
		slot.progress = brewery.daily_goal_progress[i]
		slot.reputation_baseline = brewery.daily_goal_reputation_baseline[i]
		slot.effective_target = brewery.daily_goal_effective_target[i]
	goal_progress_changed.emit()


## Run before a save (BrewEngine.brewery_about_to_save) so the slots are saved with the Brewery.
func _flush_to_brewery(brewery : Brewery) -> void:
	brewery.active_daily_goals = active_goals
	brewery.daily_goal_progress.assign(_slots.map(func(slot : GoalSlot) -> int: return slot.progress))
	brewery.daily_goal_reputation_baseline.assign(_slots.map(func(slot : GoalSlot) -> int: return slot.reputation_baseline))
	brewery.daily_goal_effective_target.assign(_slots.map(func(slot : GoalSlot) -> int: return slot.effective_target))
