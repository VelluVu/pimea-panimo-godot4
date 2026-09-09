#SpecialEventManager (Autoload)
extends Node

signal special_event_triggered(event_data: SpecialEventData)

const SPECIAL_EVENT_INTERVAL_SECONDS = 300.0

const WARNING_SPECIAL_INVALID_STATE = "SpecialEventManager: Cannot accept special request, invalid state!"


func _ready() -> void:
	_setup_timers()


func _setup_timers() -> void:
	var special_event_timer = Timer.new()
	special_event_timer.process_callback = Timer.TIMER_PROCESS_IDLE
	special_event_timer.wait_time = SPECIAL_EVENT_INTERVAL_SECONDS
	special_event_timer.autostart = true
	special_event_timer.one_shot = false
	special_event_timer.timeout.connect(_on_special_event_timer_timeout)
	add_child(special_event_timer)


func _on_special_event_timer_timeout() -> void:
	if BrewEngine.current_brewery == null:
		return
		
	var event_data = CustomerRegistry.get_random_special_event()
	if event_data == null:
		return
		
	special_event_triggered.emit(event_data)


func process_accept(event_data: SpecialEventData) -> String:
	if BrewEngine.current_brewery == null: return ""
	var brewery = BrewEngine.current_brewery

	if event_data.try_fulfill(brewery):
		BrewerySignals.brewery_state_changed.emit(brewery)
		return event_data.success_dialogue
	else:
		return event_data.fail_dialogue


func process_reject(event_data: SpecialEventData) -> String:
	return event_data.reject_dialogue


func spawn_special_customer() -> void:
	_on_special_event_timer_timeout()