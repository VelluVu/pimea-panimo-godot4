extends Node

## Rolls a day event on every TimeManager.day_changed (so a loaded save is not a new day)
## and turns its customer bias on for part of the day. None on day 1.

@export var day_event_folder_path : String = "res://src/resources/day_events/"

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
	# The autoload outlives a run: an event still running must not follow into the next one.
	BrewEngine.brewery_changed.connect(_clear_event.unbind(1))


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


func _clear_event() -> void:
	_start_delay_timer.stop()
	_window_timer.stop()
	_window_active = false
	_active_event = null


func _on_day_changed(_new_day : int) -> void:
	_clear_event()
	_active_event = _pick_weighted_event()
	_set_day_perk(_active_event.day_perk if _active_event != null else null)
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


func _set_day_perk(perk : RunPerk) -> void:
	var brewery : Brewery = BrewEngine.current_brewery
	if brewery != null:
		brewery.set_day_perk(perk)


## The one-off stock hit; silent when nothing was lost.
func _apply_direct_effect(event : DayEventData) -> void:
	var brewery : Brewery = BrewEngine.current_brewery
	if brewery == null:
		return
	var removed : int = DayEventEffects.apply(brewery.inventory, event)
	if removed <= 0:
		return
	BrewerySignals.day_event_effect_triggered.emit(tr(event.effect_toast_format) % removed)
	BrewerySignals.brewery_state_changed.emit(brewery)


## day_event_none.tres weighs most, so most days are plain. An event whose customers are
## all locked never comes, nor one out of its season.
func _pick_weighted_event() -> DayEventData:
	var season : SeasonRules.Season = SeasonRules.now()
	var available_titles : Array = []
	for customer : CustomerData in CustomerRegistry.get_eligible_customers():
		available_titles.append(customer.title)
	var weights : Array[float] = []
	for event : DayEventData in day_event_pool:
		weights.append(event.weight if event.has_audience(available_titles) and event.can_come_in(season) else 0.0)
	return WeightedPicker.pick(day_event_pool, weights) as DayEventData


func _load_resources() -> void:
	day_event_pool.assign(ResourceFolder.load_all(day_event_folder_path, DayEventData))
	if day_event_pool.is_empty():
		push_warning(WARNING_POOL_EMPTY)
