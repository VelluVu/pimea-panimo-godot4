extends Node

signal day_changed(new_day : int)

## A sale still under way when the day runs out: recheck after this long.
const DAY_END_CUSTOMER_RETRY_SECONDS : float = 5.0

## Aging ticks on its own timer, so an early close does not skip it; DayPace keeps the
## ticks per day the same.
const AGING_TICK_SECONDS : float = 30.0 * DayPace.SCALE
## Fermentation counts down in steps this long, see Fermenter.
const FERMENT_TICK_SECONDS : float = 1.0

const LOG_DAY_CHANGED : String = "--- DAY CHANGED: Day %s starts ---"

@export var day_duration_seconds : float = DayPace.DAY_SECONDS
var day_timer: Timer
var aging_timer: Timer
var ferment_timer: Timer


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

	ferment_timer = Timer.new()
	add_child(ferment_timer)
	ferment_timer.one_shot = false
	ferment_timer.timeout.connect(_on_ferment_tick)
	ferment_timer.start(FERMENT_TICK_SECONDS)

	GUISignals.close_day_requested.connect(force_advance_day)
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)
	BrewEngine.brewery_about_to_save.connect(sync_remaining_time_to_brewery)
	BrewEngine.brewery_changed.connect(_on_brewery_changed)


## The clock outlives a run: a new game stays stopped (free practice until the first
## brew), a loaded save with a batch resumes.
func _on_brewery_changed(brewery: Brewery) -> void:
	day_timer.stop()
	_on_brewery_state_changed(brewery)


## Starts the day clock once a batch exists, from the saved time left. Idempotent.
func _on_brewery_state_changed(brewery: Brewery) -> void:
	if day_timer.is_stopped() and not brewery.inventory.brew_batches.is_empty():
		day_timer.start(DayRules.clock_start_seconds(brewery.day_time_remaining_seconds, day_duration_seconds))


## Dev mode starts the clock without the first brew. Idempotent.
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


func _on_ferment_tick() -> void:
	var brewery := BrewEngine.current_brewery
	if brewery != null:
		Fermenter.new(brewery).tick(FERMENT_TICK_SECONDS)


## No player to confirm with, so it rechecks shortly instead of ending the day mid-sale.
func _on_day_timeout() -> void:
	if CustomerManager.has_active_customers():
		day_timer.start(DAY_END_CUSTOMER_RETRY_SECONDS)
		return

	day_timer.start(day_duration_seconds)
	_advance_day()


## Passes a day now (console "day", close-day button), charging the early close first.
## Nothing before the clock starts, so a stray click in free practice costs nothing.
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
	print(LOG_DAY_CHANGED % brewery.current_day)

	brewery.today_sale_receipts.clear()

	Fermenter.new(brewery).finish_all()
	_charge_daily_utility_bills(brewery)
	brewery.close_money_day()
	_apply_reputation_decay(brewery)
	_apply_risk_decay(brewery)

	SaveManager.save_game()
	# DailyGoalManager, DayEventManager and the UI react to this themselves.
	day_changed.emit(brewery.current_day)

	_check_survival_ending(brewery)


## The browser demo ends on its own shorter day instead, see DemoRules.
func _check_survival_ending(brewery : Brewery) -> void:
	var ending : String = DemoRules.demo_ending(brewery.current_day, brewery.game_has_ended) if DemoRules.is_demo() \
			else DayRules.season_ending(brewery.current_day, brewery.reputation, brewery.money, brewery.game_has_ended, brewery.has_continued_past_survival)
	if not ending.is_empty():
		brewery.trigger_ending(ending)


## Before day_changed, so the day recap's reputation change includes it.
func _apply_reputation_decay(brewery : Brewery) -> void:
	var tier : ReputationTier = brewery.get_reputation_tier()
	var decay : int = ReputationRules.daily_decay(brewery.reputation, tier)
	if decay <= 0:
		return

	brewery.change_reputation(-decay, ReputationRules.Source.DECAY)
	BrewerySignals.reputation_decayed.emit(decay, tier)
	BrewerySignals.brewery_state_changed.emit(brewery)


## Before day_changed, so the day recap can show the night's relief.
func _apply_risk_decay(brewery : Brewery) -> void:
	var relief : int = brewery.risk - DayRules.risk_after_night(brewery.risk)
	if relief <= 0:
		return

	brewery.risk -= relief
	BrewerySignals.risk_decayed.emit(relief)
	BrewerySignals.brewery_state_changed.emit(brewery)


## Skipped until the tutorial is complete and on the first night, see DayRules.
func _charge_daily_utility_bills(brewery : Brewery) -> void:
	if not brewery.tutorial_complete() or not DayRules.bills_due(brewery.current_day):
		return

	var total : int = DayRules.daily_bill_total()
	brewery.change_money(-total, MoneyLedger.Source.BILLS)
	BrewerySignals.daily_bills_paid.emit(DayRules.DAILY_ELECTRICITY_COST, DayRules.DAILY_WATER_COST, total)
	BrewerySignals.brewery_state_changed.emit(brewery)
	brewery.check_bankruptcy()


## Writes the time left onto the Brewery before a save; a stopped clock keeps -1.0.
func sync_remaining_time_to_brewery(brewery : Brewery) -> void:
	if day_timer.is_stopped():
		return
	brewery.day_time_remaining_seconds = day_timer.time_left


func get_day_progress() -> float:
	if day_timer == null:
		return 0.0
	return DayRules.day_progress(not day_timer.is_stopped(), day_timer.wait_time, day_timer.time_left)


## Seconds left today, or -1.0 while the clock has not started.
func get_seconds_left() -> float:
	if day_timer == null or day_timer.is_stopped():
		return -1.0
	return day_timer.time_left


func pause_time() -> void:
	day_timer.paused = true
	aging_timer.paused = true
	ferment_timer.paused = true


func resume_time() -> void:
	day_timer.paused = false
	aging_timer.paused = false
	ferment_timer.paused = false
