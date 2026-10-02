class_name GoalBoard
extends Node

## A few concurrent goals rolled from a pool, each in its own slot. Progress
## events advance matching slots; a goal settles the moment it succeeds (achieve)
## or fails (avoid), and end_period() settles the rest. Settling always rolls the
## slot's replacement. The project feeds progress and pays rewards in its wiring
## subclass, through the hooks at the bottom.

## A slot's goal settled. Fired after the replacement was rolled.
signal goal_resolved(goal : GoalData, succeeded : bool)
## Any goal or its progress changed, so a view needs only this.
signal goal_progress_changed()

var goal_pool : Array[GoalData] = []

## The goal in each slot, index-aligned with get_progress() and get_effective_target().
var active_goals : Array[GoalData]:
	get:
		var goals : Array[GoalData] = []
		for slot : GoalSlot in _slots:
			goals.append(slot.goal)
		return goals

var _slots : Array[GoalSlot] = []
## Goals rolled since the period began; _roll_limit() caps it.
var rolls_used : int = 0
## Goals that may be rolled per period, -1 for no limit. Read through _roll_limit().
var roll_limit : int = -1


func _init() -> void:
	set_slot_count(3)


func set_slot_count(count : int) -> void:
	_slots.clear()
	for i : int in count:
		_slots.append(GoalSlot.new())


func get_slot_count() -> int:
	return _slots.size()


func get_progress(slot : int) -> int:
	return _slots[slot].progress


func get_effective_target(slot : int) -> int:
	return _slots[slot].effective_target


func get_baseline(slot : int) -> int:
	return _slots[slot].baseline


## Adds `amount` to every slot whose goal matches the event.
func add_progress(kind : int, amount : int, detail : int = -1) -> void:
	for i : int in GoalRules.matching_slots(active_goals, kind, detail):
		_slots[i].progress += amount
		goal_progress_changed.emit()
		_check_outcome(i)


## For progress derived from live state rather than counted.
func set_progress(slot : int, value : int) -> void:
	if not _slots[slot].has_goal():
		return
	_slots[slot].progress = value
	goal_progress_changed.emit()
	_check_outcome(slot)


## Fails the first goal of `kind` without its penalty.
func fail_kind_without_penalty(kind : int) -> void:
	for i : int in _slots.size():
		var goal : GoalData = _slots[i].goal
		if goal != null and goal.get_kind() == kind:
			_resolve_goal(i, false, false)
			return


## Goals that can still be rolled this period, or -1 when there is no limit.
func get_rolls_left() -> int:
	var limit : int = _roll_limit()
	return -1 if limit < 0 else maxi(0, limit - rolls_used)


## Settles every active goal: a surviving avoid goal succeeds, an unfinished
## achieve goal ran out of time. Starts a new period, so the replacements count
## towards the next period's roll limit.
func end_period() -> void:
	rolls_used = 0
	for i : int in _slots.size():
		var goal : GoalData = _slots[i].goal
		if goal != null:
			_resolve_goal(i, goal.is_avoid())


## Rolls a goal into every empty slot.
func fill_empty_slots() -> void:
	for i : int in _slots.size():
		if not _slots[i].has_goal():
			_assign_new_goal(i)


## Restores one slot, e.g. from a save. Emits nothing; call notify_changed() after.
## An avoid goal takes its own target, since older saves stored a limit of 0 as 1.
func load_slot(slot : int, goal : GoalData, progress : int, baseline : int, effective_target : int) -> void:
	var goal_slot : GoalSlot = _slots[slot]
	goal_slot.goal = goal
	goal_slot.progress = progress
	goal_slot.baseline = baseline
	goal_slot.effective_target = goal.target_amount if goal != null and goal.is_avoid() else effective_target


func notify_changed() -> void:
	goal_progress_changed.emit()


func _check_outcome(slot_index : int) -> void:
	var slot : GoalSlot = _slots[slot_index]
	if not slot.has_goal():
		return

	match GoalRules.check_outcome(slot.goal, slot.progress, slot.effective_target):
		GoalRules.Outcome.SUCCEEDED:
			_resolve_goal(slot_index, true)
		GoalRules.Outcome.FAILED:
			_resolve_goal(slot_index, false)


## The replacement is rolled between the two hooks: a reward that changes the
## state a new goal snapshots goes in _before_replace(), anything that can feed
## progress back into the board goes in _after_replace(), or a goal could see its
## own reward and settle again.
func _resolve_goal(slot_index : int, succeeded : bool, apply_penalty : bool = true) -> void:
	var goal : GoalData = _slots[slot_index].goal
	if goal == null:
		return

	var context : Variant = _before_replace(goal, succeeded, apply_penalty)
	_assign_new_goal(slot_index)
	_after_replace(goal, succeeded, apply_penalty, context)
	goal_resolved.emit(goal, succeeded)


func _assign_new_goal(slot_index : int) -> void:
	var new_goal : GoalData = null
	if _can_roll_goals() and get_rolls_left() != 0:
		new_goal = GoalRules.pick_new_goal(goal_pool, active_goals)

	if new_goal != null:
		rolls_used += 1
		_slots[slot_index].start(new_goal, _baseline_for(new_goal), _current_day())
	else:
		_slots[slot_index].clear()
	goal_progress_changed.emit()


## Override: whether goals may be rolled right now (false leaves slots empty).
func _can_roll_goals() -> bool:
	return true


## Override: how many goals may be rolled per period, or -1 for no limit. An
## empty slot stays empty once the limit is used up.
func _roll_limit() -> int:
	return roll_limit


## Override: the day a new goal's target is scaled for.
func _current_day() -> int:
	return 1


## Override: the baseline a new goal snapshots.
func _baseline_for(_goal : GoalData) -> int:
	return 0


## Override: pay or charge before the replacement is rolled. The return value is
## handed to _after_replace().
func _before_replace(_goal : GoalData, _succeeded : bool, _apply_penalty : bool) -> Variant:
	return null


## Override: the rest of the settlement, after the replacement is rolled.
func _after_replace(_goal : GoalData, _succeeded : bool, _apply_penalty : bool, _context : Variant) -> void:
	pass
