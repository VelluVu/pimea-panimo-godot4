#DailyGoalManager (Autoload)
extends Node

## Drives the ACTIVE_GOAL_COUNT concurrently-active daily goals. Fully
## data-driven — the pool is every DailyGoalData .tres under
## DAILY_GOAL_FOLDER_PATH, auto-loaded the same way RunModifierRegistry/
## CustomerRegistry already load their own folders, so adding a new goal
## type to the game is just dropping in another .tres.
##
## Every goal type is "achieve" (progress climbs toward target_amount,
## success on reaching it, failure if the day ends first) except
## UNHAPPY_CUSTOMERS_MAX, which is "avoid": progress climbing PAST
## target_amount fails it immediately (mid-day), and never breaching it by
## day's end is the success case — see _is_avoid_type()/_check_goal_outcome().
##
## Goals never carry progress across a day boundary — _on_day_changed()
## resolves whatever's still active (success for a surviving avoid-goal,
## failure for an unfinished achieve-goal) and that resolution's own
## _assign_new_goal() call is what hands the new day a fresh set, so there's
## no separate "reset all 3" step needed on top of resolving each slot.

signal daily_goal_resolved(goal_name: String, succeeded: bool, money: int, reputation: int, xp: int, risk: int)
## Fired whenever active_goals or any slot's progress changes — none of the
## signals that actually drive progress (beer_brewed, bottles_sold, ...) are
## ones DailyGoalsPanel would otherwise have any reason to listen for
## itself, so it just listens for this one instead of duplicating this
## script's whole signal list.
signal goal_progress_changed()

const DAILY_GOAL_FOLDER_PATH : String = "res://src/resources/daily_goals/"
const WARNING_FOLDER_OPEN_FAILED : String = "DailyGoalManager: Failed to open path: "

const ACTIVE_GOAL_COUNT : int = 3

var goal_pool : Array[DailyGoalData] = []

## Index-aligned with _progress/_reputation_baseline. null means that slot
## has no goal yet — either nothing has been rolled at all (pre-tutorial),
## or the pool ran dry of distinct candidates (pool smaller than
## ACTIVE_GOAL_COUNT).
var active_goals : Array[DailyGoalData] = [null, null, null]
var _progress : Array[int] = [0, 0, 0]
## REPUTATION_GAIN's progress is a delta against brewery.reputation as it
## stood when the goal was rolled, not an incrementing counter like every
## other type — reputation is a live stat that can also fall (a bad sale,
## an LVV raid), so it has to be re-derived from this snapshot every time
## rather than accumulated in place. See _on_brewery_state_changed().
var _reputation_baseline : Array[int] = [0, 0, 0]
## Snapshotted once per slot by _assign_new_goal() via DailyGoalData.
## get_effective_target() — see that method's docstring for why this is
## captured once instead of re-derived live from brewery.current_day.
var _effective_target : Array[int] = [0, 0, 0]

var _tracked_brewery : Brewery = null


func _ready() -> void:
	_load_goal_pool()

	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)
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


func _is_avoid_type(goal : DailyGoalData) -> bool:
	return goal.goal_type == DailyGoalData.GoalType.UNHAPPY_CUSTOMERS_MAX


## Also doubles as "a fresh run just started" detection: a Brewery instance
## only ever changes when BrewEngine.start_new_game() constructs a new one,
## so comparing against the last-seen instance is enough to know every
## active goal belongs to a run that no longer exists.
func _on_brewery_state_changed(brewery : Brewery) -> void:
	if brewery != _tracked_brewery:
		_tracked_brewery = brewery
		_reset_all_goals()
		return

	if not brewery.tutorial_complete():
		return

	for i in range(ACTIVE_GOAL_COUNT):
		if active_goals[i] == null:
			_assign_new_goal(i)
			continue
		if active_goals[i].goal_type == DailyGoalData.GoalType.REPUTATION_GAIN:
			_progress[i] = maxi(0, brewery.reputation - _reputation_baseline[i])
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


## A failed special event (the customer's demand couldn't actually be
## filled, see SpecialEventManager.process_accept()) fails an active
## SPECIAL_EVENT goal outright rather than leaving it pending for another
## event to try again later — but penalty-free, since the brewery did try;
## it just didn't have what was asked for. See _resolve_goal()'s
## apply_penalty param.
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


## required_style is only meaningful for BREW_STYLE (a customer_unhappy or
## bottles_sold event never passes one) — every other type ignores it.
func _add_progress(goal_type : DailyGoalData.GoalType, amount : int, required_style : int = -1) -> void:
	for i in range(ACTIVE_GOAL_COUNT):
		var goal := active_goals[i]
		if goal == null or goal.goal_type != goal_type:
			continue
		if goal_type == DailyGoalData.GoalType.BREW_STYLE and goal.target_style != required_style:
			continue

		_progress[i] += amount
		goal_progress_changed.emit()
		_check_goal_outcome(i)


func _check_goal_outcome(slot : int) -> void:
	var goal := active_goals[slot]
	if goal == null:
		return

	if _is_avoid_type(goal):
		if _progress[slot] > _effective_target[slot]:
			_resolve_goal(slot, false)
	elif _progress[slot] >= _effective_target[slot]:
		_resolve_goal(slot, true)


## Called reactively (a goal completed, an avoid-type just breached its
## limit, or a SPECIAL_EVENT goal's event just failed outright — see
## _fail_goal_type_no_penalty()) and from _on_day_changed() for whatever's
## still pending at day's end. Always ends by rolling the slot's
## replacement — see the class docstring for why that alone is enough to
## give every new day a fresh set of ACTIVE_GOAL_COUNT goals.
##
## apply_penalty=false is the "tried in good faith, just couldn't" failure
## — a triggered special event whose required stock wasn't on hand — as
## opposed to a genuine miss (an avoid-goal actively breached, or an
## achieve-goal that simply ran out of time): still fails and rerolls the
## goal, but money/reputation/xp/risk all stay exactly 0.
func _resolve_goal(slot : int, succeeded : bool, apply_penalty : bool = true) -> void:
	var goal := active_goals[slot]
	if goal == null:
		return

	var money := 0
	var reputation := 0
	var xp := 0
	var risk := 0

	var brewery := BrewEngine.current_brewery
	if brewery != null:
		if succeeded:
			money = goal.get_effective_reward_money(brewery.current_day)
			reputation = goal.get_effective_reward_reputation(brewery.current_day)
			xp = goal.get_effective_reward_xp(brewery.current_day)
		elif apply_penalty:
			reputation = -goal.penalty_reputation
			risk = goal.penalty_risk
		# Plain field mutation only, no signal — safe to apply before the
		# slot is replaced below. money/xp/risk are applied further down,
		# after the reassignment, since add_xp()/add_risk() (a risk penalty
		# can itself trigger an LVV raid) both emit brewery_state_changed.
		if reputation != 0:
			brewery.reputation = max(0, brewery.reputation + reputation)
		if succeeded:
			brewery.money += money

	# Replace the slot BEFORE anything below that can emit
	# brewery_state_changed (add_xp(), add_risk() via a raid, and the
	# explicit emit further down) — this script reacts to that signal by
	# re-checking every active slot's progress, and a REPUTATION_GAIN
	# goal's progress is derived live from brewery.reputation itself
	# (see _on_brewery_state_changed()), not an incrementing counter. Left
	# in place through an emit, the goal that just resolved would see its
	# own reward immediately re-cross its own target and resolve again —
	# infinite recursion, discovered via an actual stack overflow while
	# stress-testing this function directly.
	_assign_new_goal(slot)

	if brewery != null:
		if succeeded:
			brewery.add_xp(xp)
		elif apply_penalty:
			brewery.add_risk(risk)
		BrewerySignals.brewery_state_changed.emit(brewery)

	daily_goal_resolved.emit(goal.goal_name, succeeded, money, reputation, xp, risk)


## Excludes every goal currently sitting in ANY active slot (not just this
## one) so the 3 concurrent goals are always distinct from each other — the
## pool can still hand back a goal this same slot held earlier today,
## "distinct" only ever means "not one of the other two right now".
func _assign_new_goal(slot : int) -> void:
	var brewery := BrewEngine.current_brewery
	if brewery == null or not brewery.tutorial_complete():
		active_goals[slot] = null
		goal_progress_changed.emit()
		return

	var candidates := goal_pool.filter(func(g : DailyGoalData) -> bool: return not active_goals.has(g))
	if candidates.is_empty():
		active_goals[slot] = null
		goal_progress_changed.emit()
		return

	var new_goal : DailyGoalData = candidates.pick_random()
	active_goals[slot] = new_goal
	_progress[slot] = 0
	_reputation_baseline[slot] = brewery.reputation
	_effective_target[slot] = new_goal.get_effective_target(brewery.current_day)
	goal_progress_changed.emit()


func _reset_all_goals() -> void:
	for i in range(ACTIVE_GOAL_COUNT):
		active_goals[i] = null
		_progress[i] = 0
		_reputation_baseline[i] = 0
		_effective_target[i] = 0
	goal_progress_changed.emit()


## A surviving avoid-goal (never breached its limit) succeeds; any
## still-unfinished achieve-goal ran out of time and fails. Both branches
## go through _resolve_goal(), whose own _assign_new_goal() call is what
## actually gives the new day its fresh set — see the class docstring.
func _on_day_changed(_new_day : int) -> void:
	for i in range(ACTIVE_GOAL_COUNT):
		var goal := active_goals[i]
		if goal == null:
			continue
		_resolve_goal(i, _is_avoid_type(goal))
