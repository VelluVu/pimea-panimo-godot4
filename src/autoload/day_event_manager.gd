#DayEventManager (Autoload)
extends Node

## Rolls a DayEventData in secret whenever TimeManager.day_changed fires,
## announces it immediately (BrewerySignals.day_event_announced — see
## GUI._on_day_event_announced()), then activates its bias for a randomized
## window that's only PART of the day (see DayEventData's own docstring for
## why), read via is_event_active()/get_active_event() by
## CustomerSpawner._on_group_event_timer_timeout() and
## CustomerRegistry.get_random_customer_data().
##
## Deliberately keyed on day_changed (fired only from TimeManager._advance_day(),
## itself only reached via the day timer or force_advance_day()) rather than
## on brewery_state_changed/a swapped Brewery instance — that's exactly the
## detection DailyGoalManager historically got bitten by (a loaded/continued
## save's Brewery instance read as "a fresh run", silently re-rolling
## progress that should have carried over — see notes/playtest_notes_11.txt).
## A day event has no persisted state to protect the same way, so the
## simplest correct behavior falls out for free: continuing a save mid-day
## just has no active event until the next genuine day change, rather than
## trying to reconstruct or persist one.
##
## No event roll on day 1: day_changed never fires for it (nothing "changes
## into" the first day — see TimeManager._advance_day()'s own call sites),
## which conveniently also keeps this from competing with
## GUI._show_first_brew_hint()'s own banner on a brand new run.

@export var day_event_folder_path : String = "res://src/resources/day_events/"

const WARNING_FOLDER_OPEN_FAILED : String = "DayEventManager: Failed to open path: "
const WARNING_POOL_EMPTY : String = "DayEventManager: Day event pool is empty!"

var day_event_pool : Array[DayEventData] = []

var _active_event : DayEventData = null
var _window_active : bool = false
var _start_delay_timer : Timer
var _window_timer : Timer


func _ready() -> void:
	_load_resources()
	_setup_timers()
	TimeManager.day_changed.connect(_on_day_changed)


func _setup_timers() -> void:
	_start_delay_timer = Timer.new()
	_start_delay_timer.one_shot = true
	_start_delay_timer.process_callback = Timer.TIMER_PROCESS_IDLE
	_start_delay_timer.timeout.connect(_on_window_start)
	add_child(_start_delay_timer)

	_window_timer = Timer.new()
	_window_timer.one_shot = true
	_window_timer.process_callback = Timer.TIMER_PROCESS_IDLE
	_window_timer.timeout.connect(_on_window_end)
	add_child(_window_timer)


func is_event_active() -> bool:
	return _window_active and _active_event != null


func get_active_event() -> DayEventData:
	return _active_event if _window_active else null


func _on_day_changed(_new_day : int) -> void:
	_start_delay_timer.stop()
	_window_timer.stop()
	_window_active = false

	_active_event = _pick_weighted_event()
	if _active_event == null:
		return

	BrewerySignals.day_event_announced.emit(_active_event)
	_apply_direct_effect(_active_event)

	var day_duration : float = TimeManager.day_duration_seconds
	var start_delay : float = _active_event.get_start_delay_fraction() * day_duration
	if start_delay <= 0.0:
		_on_window_start()
	else:
		_start_delay_timer.start(start_delay)


func _on_window_start() -> void:
	if _active_event == null:
		return
	_window_active = true
	var window_seconds : float = _active_event.get_window_fraction() * TimeManager.day_duration_seconds
	_window_timer.start(maxf(1.0, window_seconds))


func _on_window_end() -> void:
	_window_active = false


## Applies event.effect_type's one-off stock/batch hit, if any — separate
## from the featured_group_event/featured_customer_titles bias, which stays
## on its own delayed window timing (_on_window_start()/_on_window_end()).
## No-ops silently (no signal) if there's nothing to actually take the hit,
## same as BrewEngine.current_brewery being null on a menu/no-run state.
func _apply_direct_effect(event : DayEventData) -> void:
	var brewery : Brewery = BrewEngine.current_brewery
	if brewery == null:
		return

	match event.effect_type:
		DayEventData.EffectType.INGREDIENT_LOSS:
			_apply_ingredient_loss(brewery, event)
		DayEventData.EffectType.BOTTLE_SPOILAGE:
			_apply_bottle_spoilage(brewery, event)


func _apply_ingredient_loss(brewery : Brewery, event : DayEventData) -> void:
	var bucket : Dictionary = brewery.inventory.items.get(event.effect_ingredient_type, {})
	var requested : int = event.get_effect_amount()
	var removed : int = 0

	for id : int in bucket.keys():
		if removed >= requested:
			break
		var item : InventoryItem = bucket[id]
		removed += brewery.inventory.withdraw_item_by_id(id, min(item.amount, requested - removed))

	if removed <= 0:
		return

	BrewerySignals.day_event_effect_triggered.emit(event.effect_toast_format % removed)
	BrewerySignals.brewery_state_changed.emit(brewery)


func _apply_bottle_spoilage(brewery : Brewery, event : DayEventData) -> void:
	if brewery.inventory.brew_batches.is_empty():
		return

	var batch : BrewBatch = brewery.inventory.brew_batches.pick_random()
	var removed : int = min(batch.amount_bottles, event.get_effect_amount())
	batch.amount_bottles -= removed

	if batch.amount_bottles <= 0:
		brewery.inventory.brew_batches.erase(batch)

	if removed <= 0:
		return

	BrewerySignals.day_event_effect_triggered.emit(event.effect_toast_format % removed)
	BrewerySignals.brewery_state_changed.emit(brewery)


## Same weighted-roll shape as CustomerRegistry.get_random_special_event()
## — every entry at the default weight (1.0) keeps flat odds against each
## other; day_event_none.tres's much higher weight is what actually makes
## "nothing special" the common case.
func _pick_weighted_event() -> DayEventData:
	if day_event_pool.is_empty():
		return null

	var total_weight : float = 0.0
	for event : DayEventData in day_event_pool:
		total_weight += event.weight

	var roll : float = randf() * total_weight
	var cumulative : float = 0.0
	for event : DayEventData in day_event_pool:
		cumulative += event.weight
		if roll < cumulative:
			return event

	return day_event_pool.back()


func _load_resources() -> void:
	var dir := DirAccess.open(day_event_folder_path)
	if dir == null:
		push_warning(WARNING_FOLDER_OPEN_FAILED + day_event_folder_path)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res := load(day_event_folder_path + file_name)
			if res is DayEventData:
				day_event_pool.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()

	if day_event_pool.is_empty():
		push_warning(WARNING_POOL_EMPTY)
