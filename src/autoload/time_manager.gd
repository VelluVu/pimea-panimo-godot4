#TimeManager (Autoload)
extends Node

signal day_changed(new_day : int)

## How long to wait before rechecking when the day timer runs out while a
## customer is still mid-sale. Long enough to cover a normal sale's sequence.
const DAY_END_CUSTOMER_RETRY_SECONDS : float = 5.0

## Cellar aging ticks on this fixed real-time interval, not once per day close, so
## quality moves while the player is playing (about 10 ticks per 300s day). It is
## independent of day length and early closes on purpose: shortening a day should
## not change how fast beer ages.
const AGING_TICK_SECONDS : float = 30.0

@export var day_duration_seconds : float = 300
var day_timer: Timer
var aging_timer: Timer


func _ready() -> void:
	day_timer = Timer.new()
	add_child(day_timer)
	day_timer.one_shot = false
	day_timer.timeout.connect(_on_day_timeout)
	# Not started here: a new player gets free practice time until the first
	# brewed batch, see _on_brewery_state_changed().

	aging_timer = Timer.new()
	add_child(aging_timer)
	aging_timer.one_shot = false
	aging_timer.timeout.connect(_on_aging_tick)
	aging_timer.start(AGING_TICK_SECONDS)

	GUISignals.close_day_requested.connect(force_advance_day)
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)
	BrewEngine.brewery_about_to_save.connect(sync_remaining_time_to_brewery)
	BrewEngine.brewery_changed.connect(_on_brewery_changed)


## A different run became current. The autoload's clock outlives the run, so stop
## the previous one's and re-derive it: a new game stays stopped (free practice
## time, first-brew hint) while a loaded save with a batch resumes.
func _on_brewery_changed(brewery: Brewery) -> void:
	day_timer.stop()
	_on_brewery_state_changed(brewery)


## Starts the day clock once there is a brewed batch: a fresh run's first brew, or
## a loaded save that already has one. Idempotent, so later state changes never
## restart it. Resumes from the saved time left rather than a full day, see
## Brewery.day_time_remaining_seconds.
func _on_brewery_state_changed(brewery: Brewery) -> void:
	if day_timer.is_stopped() and not brewery.inventory.brew_batches.is_empty():
		day_timer.start(DayRules.clock_start_seconds(brewery.day_time_remaining_seconds, day_duration_seconds))


## Starts the clock without waiting for a brewed batch: dev mode skips the
## tutorial gate. Idempotent, so it never restarts a running clock.
func start_clock_immediately() -> void:
	if day_timer.is_stopped():
		day_timer.start(day_duration_seconds)


## Ages the cellar on its own timer, see AGING_TICK_SECONDS.
func _on_aging_tick() -> void:
	var brewery := BrewEngine.current_brewery
	if brewery == null:
		return

	brewery.inventory.age_batches()
	BrewerySignals.brewery_state_changed.emit(brewery)


## The automatic timer has no player to confirm with, so it waits a short beat and
## rechecks instead of ending the day under a customer who is mid-sale.
func _on_day_timeout() -> void:
	if CustomerManager.has_active_customers():
		day_timer.start(DAY_END_CUSTOMER_RETRY_SECONDS)
		return

	day_timer.start(day_duration_seconds)
	_advance_day()


## Forces a day to pass now: the dev console's "day" command, and the close-day
## confirmation. Charges the early-close cost first, using how much of today's
## timer was spent as the earliness. Does nothing before the clock has started:
## a stray click during free practice must not cost a penalty.
func force_advance_day() -> void:
	if day_timer.is_stopped():
		return

	# Anyone still being served is thrown out; their sale is cancelled.
	CustomerManager.evict_active_customers()

	var earliness : float = 1.0 - get_day_progress()
	day_timer.start(day_duration_seconds)

	var brewery := BrewEngine.current_brewery
	if brewery != null:
		InspectionService.new(brewery).apply_early_close_cost(earliness)

	_advance_day()


func _advance_day() -> void:
	var brewery := BrewEngine.current_brewery
	if brewery == null:
		return

	brewery.current_day += 1
	print(StringContainer.DAY_CHANGED_MESSAGE % brewery.current_day)

	brewery.today_sale_receipts.clear()

	_charge_daily_utility_bills(brewery)

	SaveManager.save_game()
	# DailyGoalManager, DayEventManager and the UI react to this themselves.
	day_changed.emit(brewery.current_day)

	_check_survival_ending(brewery)


func _check_survival_ending(brewery : Brewery) -> void:
	if DayRules.survival_reached(brewery.current_day, brewery.reputation, brewery.money, brewery.game_has_ended, brewery.has_continued_past_survival):
		brewery.trigger_ending("survived")


## Skipped until the tutorial is complete, see DayRules.DAILY_ELECTRICITY_COST.
func _charge_daily_utility_bills(brewery : Brewery) -> void:
	if not brewery.tutorial_complete():
		return

	var total : int = DayRules.daily_bill_total()
	brewery.money -= total
	BrewerySignals.daily_bills_paid.emit(DayRules.DAILY_ELECTRICITY_COST, DayRules.DAILY_WATER_COST, total)
	BrewerySignals.brewery_state_changed.emit(brewery)
	brewery.check_bankruptcy()


## Writes the time left on the day clock onto the Brewery before a save. A stopped
## clock keeps the -1.0 "not started" marker.
func sync_remaining_time_to_brewery(brewery : Brewery) -> void:
	if day_timer.is_stopped():
		return
	brewery.day_time_remaining_seconds = day_timer.time_left


func get_day_progress() -> float:
	if day_timer == null:
		return 0.0
	return DayRules.day_progress(not day_timer.is_stopped(), day_timer.wait_time, day_timer.time_left)


func pause_time() -> void:
	day_timer.paused = true
	aging_timer.paused = true


func resume_time() -> void:
	day_timer.paused = false
	aging_timer.paused = false
