#SpecialEventManager (Autoload)
extends Node

signal special_event_triggered(event_data: SpecialEventData)

const WARNING_SPECIAL_INVALID_STATE = "SpecialEventManager: Cannot accept special request, invalid state!"


var _special_event_timer: Timer


func _ready() -> void:
	_setup_timers()
	BrewEngine.brewery_about_to_save.connect(_record_timer)
	BrewEngine.brewery_changed.connect(_restore_timer)


## The next special event comes when it would have in the saved run.
func _record_timer(brewery: Brewery) -> void:
	brewery.special_event_time_left = -1.0 if _special_event_timer.is_stopped() else _special_event_timer.time_left


func _restore_timer(brewery: Brewery) -> void:
	if brewery.special_event_time_left > 0.0:
		_special_event_timer.start(brewery.special_event_time_left)


func _setup_timers() -> void:
	_special_event_timer = Timer.new()
	_special_event_timer.process_callback = Timer.TIMER_PROCESS_IDLE
	_special_event_timer.wait_time = SpecialEventPacing.BASE_INTERVAL_SECONDS
	_special_event_timer.autostart = true
	_special_event_timer.one_shot = true
	_special_event_timer.timeout.connect(_on_special_event_timer_timeout)
	add_child(_special_event_timer)


## Re-armed each time with SpecialEventPacing's wait (flat for now, see MAX_RISK_SPEEDUP).
func _on_special_event_timer_timeout() -> void:
	var brewery: Brewery = BrewEngine.current_brewery
	var risk_fraction: float = SpecialEventData.risk_fraction(brewery) if brewery != null else 0.0
	_special_event_timer.start(SpecialEventPacing.interval(risk_fraction))
	if brewery == null:
		return

	var event_data: SpecialEventData = CustomerRegistry.get_random_special_event(BrewEngine.current_brewery)
	if event_data == null:
		return

	special_event_triggered.emit(event_data.prepared(brewery, CustomerRegistry.bar_contact_pool))


func process_accept(event_data: SpecialEventData) -> String:
	if BrewEngine.current_brewery == null: return ""
	var brewery: Brewery = BrewEngine.current_brewery

	var succeeded := event_data.try_fulfill(brewery)
	BrewerySignals.special_event_resolved.emit(succeeded, event_data)

	if succeeded:
		BrewerySignals.brewery_state_changed.emit(brewery)
		return event_data.success_dialogue
	else:
		return event_data.fail_dialogue


## Only reachable via SpecialEventWindow's timeout, not a player choice —
## the window no longer offers a decline button (the brewery always says
## "Joo"; see try_fulfill/fail_dialogue for how a genuine lack of stock
## already gets handled instead).
func process_reject(event_data: SpecialEventData) -> String:
	if BrewEngine.current_brewery != null:
		event_data.on_rejected(BrewEngine.current_brewery)
	return event_data.reject_dialogue


## An accepted request whose goods never came in time: it failed, at no further cost.
func process_expired(event_data: SpecialEventData) -> String:
	BrewerySignals.special_event_resolved.emit(false, event_data)
	return event_data.fail_dialogue


func spawn_special_customer() -> void:
	_on_special_event_timer_timeout()