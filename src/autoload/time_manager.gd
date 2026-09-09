#TimeManager (Autoload)
extends Node

signal day_changed(new_day : int)

const BREW_BATCHES_PROPERTY_NAME = "brew_batches"

@export var day_duration_seconds : float = 300
var current_day : int = 1
var time_accumulator : float = 0.0
var day_timer: Timer


func _ready() -> void:
	day_timer = Timer.new()
	add_child(day_timer)
	day_timer.wait_time = day_duration_seconds
	day_timer.one_shot = false 
	day_timer.timeout.connect(_on_day_timeout)
	day_timer.start()


func _on_day_timeout() -> void:
	_advance_day()


## Public entry point for forcing a day to pass on demand (used by the dev
## console's "day" command) instead of waiting for day_timer.
func force_advance_day() -> void:
	day_timer.start()
	_advance_day()


func _advance_day() -> void:
	current_day += 1
	print(StringContainer.DAY_CHANGED_MESSAGE % current_day)
	
	if BrewEngine.current_brewery and BrewEngine.current_brewery.inventory:
		_process_cellar_aging(BrewEngine.current_brewery.inventory)
	
	day_changed.emit(current_day)


func get_day_progress() -> float:
	if day_timer == null or day_timer.is_stopped():
		return 0.0
	
	return (day_timer.wait_time - day_timer.time_left) / day_timer.wait_time


func _process_cellar_aging(inventory) -> void:
	if BREW_BATCHES_PROPERTY_NAME in inventory and inventory.brew_batches != null:
		for batch in inventory.brew_batches:
			batch.age_one_day() 
			
		BrewerySignals.brewery_state_changed.emit(BrewEngine.current_brewery)


func pause_time() -> void:
	day_timer.paused = true

func resume_time() -> void:
	day_timer.paused = false
