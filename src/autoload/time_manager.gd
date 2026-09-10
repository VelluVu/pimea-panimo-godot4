#TimeManager (Autoload)
extends Node

signal day_changed(new_day : int)

const BREW_BATCHES_PROPERTY_NAME = "brew_batches"

@export var day_duration_seconds : float = 300
var time_accumulator : float = 0.0
var day_timer: Timer


func _ready() -> void:
	day_timer = Timer.new()
	add_child(day_timer)
	day_timer.wait_time = day_duration_seconds
	day_timer.one_shot = false 
	day_timer.timeout.connect(_on_day_timeout)
	day_timer.start()
	GUISignals.close_day_requested.connect(force_advance_day)


func _on_day_timeout() -> void:
	_advance_day()


## Public entry point for forcing a day to pass on demand (used by the dev
## console's "day" command) instead of waiting for day_timer.
func force_advance_day() -> void:
	day_timer.start()
	_advance_day()


func _advance_day() -> void:
	var brewery := BrewEngine.current_brewery
	if brewery == null:
		return

	brewery.current_day += 1
	print(StringContainer.DAY_CHANGED_MESSAGE % brewery.current_day)

	_process_cellar_aging(brewery.inventory)
	_check_risk_goal_reward(brewery)

	# bottles_sold_toward_goal deliberately does NOT reset here — a slow
	# day's progress carries into the next one instead of being wiped; it
	# only resets (with overflow preserved) when the goal is actually
	# reached, in CustomerManager._check_bottles_goal_reward().

	SaveManager.save_game()
	day_changed.emit(brewery.current_day)


const RISK_GOAL_REWARD_NAME : String = "Riskitavoite"

## The risk goal is a "stay under X" goal, unlike bottles' "reach X" — it can
## only be confirmed met once the day is actually over (risk could still have
## climbed past the limit later), so it pays out here instead of instantly.
func _check_risk_goal_reward(brewery : Brewery) -> void:
	if not brewery.tutorial_complete() or brewery.risk >= DailyGoalsPanel.RISK_LIMIT:
		return

	brewery.money += DailyGoalsPanel.RISK_GOAL_REWARD_MONEY
	brewery.reputation += DailyGoalsPanel.RISK_GOAL_REWARD_REPUTATION
	BrewerySignals.daily_goal_reward_granted.emit(RISK_GOAL_REWARD_NAME, DailyGoalsPanel.RISK_GOAL_REWARD_MONEY, DailyGoalsPanel.RISK_GOAL_REWARD_REPUTATION)


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
