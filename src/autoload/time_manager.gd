#TimeManager (Autoload)
extends Node

signal day_changed(new_day : int)

const BREW_BATCHES_PROPERTY_NAME = "brew_batches"

## Recurring overhead on top of per-sale/per-brew costs — the cellar's
## lights/coolers and cleaning water keep running whether or not the
## player brewed that day. Gated behind tutorial_complete() in
## _charge_daily_utility_bills(), same as the other daily goal checks
## below, so a brand-new player isn't billed before they've even bought
## their first ingredients.
const DAILY_ELECTRICITY_COST : int = 5
const DAILY_WATER_COST : int = 3

## How long to wait before rechecking, once the day timer runs out while a
## customer is still mid-sale — see _on_day_timeout(). Short enough that a
## delayed day-end isn't very noticeable, long enough to cover a normal
## sale's intro/preview/sale/leave sequence.
const DAY_END_CUSTOMER_RETRY_SECONDS : float = 5.0

## Reach this day (with the run not currently on the ropes — see
## Brewery.SURVIVAL_MIN_REPUTATION) and the run ends in the "survived"
## ending instead of running forever. See _advance_day().
const SURVIVAL_DAY_TARGET : int = 15

## Cellar aging (BrewBatch.age_one_day() / BeerStyle.peak_days &
## shelf_life_days) ticks on this fixed real-time interval instead of once
## per day close — with day_duration_seconds at 300s, that's ~10 ticks per
## in-game day, so quality actually moves while the player is still playing
## a day instead of only jumping at day boundaries. Independent of
## day_duration_seconds and of early closes (TimeManager.force_advance_day())
## on purpose: shortening a day shouldn't also slow down or speed up how
## fast beer ages in the cellar.
const AGING_TICK_SECONDS : float = 30.0

@export var day_duration_seconds : float = 300
var time_accumulator : float = 0.0
var day_timer: Timer
var aging_timer: Timer


func _ready() -> void:
	day_timer = Timer.new()
	add_child(day_timer)
	day_timer.one_shot = false
	day_timer.timeout.connect(_on_day_timeout)
	# Deliberately NOT started here — see _on_brewery_state_changed(). A
	# brand-new player should get unlimited free practice time on the
	# brewing UI before the 15-day survival clock and daily utility bills
	# start counting against them; the clock only starts once there's
	# actually a brewed batch in inventory.

	aging_timer = Timer.new()
	add_child(aging_timer)
	aging_timer.one_shot = false
	aging_timer.timeout.connect(_on_aging_tick)
	aging_timer.start(AGING_TICK_SECONDS)

	GUISignals.close_day_requested.connect(force_advance_day)
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)


## Starts the day clock the first time there's ever a brewed batch in
## inventory — covers both a fresh run's first brew and a loaded save that
## already has one (SaveManager.load_game() re-emits this via
## Brewery.emit_initial_values()). is_stopped() makes this idempotent so
## later brews/state changes never restart or interrupt an already-running
## timer. Mirrors the same "has anything happened yet" check
## CustomerManager already gates customer spawning on.
##
## Resumes from Brewery.day_time_remaining_seconds when a loaded save has an
## actual snapshot (>= 0.0) instead of always starting at the full
## day_duration_seconds — see that field's own doc comment for why a
## continued save otherwise silently refunded whatever time was left on the
## clock the moment it was saved.
func _on_brewery_state_changed(brewery: Brewery) -> void:
	if day_timer.is_stopped() and not brewery.inventory.brew_batches.is_empty():
		var remaining : float = brewery.day_time_remaining_seconds
		day_timer.start(remaining if remaining >= 0.0 else day_duration_seconds)


## Called by BrewEngine when developer mode is switched on — unlike
## _on_brewery_state_changed() above, this doesn't wait for a brewed batch:
## dev mode's whole point is skipping straight past the tutorial gate to
## test the real game. Idempotent (is_stopped() guard), so flipping
## developer mode on again later (e.g. after it was toggled off) never
## restarts an already-running clock.
func start_clock_immediately() -> void:
	if day_timer.is_stopped():
		day_timer.start(day_duration_seconds)


## Runs independently of day close — see AGING_TICK_SECONDS.
func _on_aging_tick() -> void:
	var brewery := BrewEngine.current_brewery
	if brewery == null:
		return

	_process_cellar_aging(brewery.inventory)


## Manually closing the day (GUISignals.close_day_requested) warns the
## player first if a customer is mid-sale (see CustomerManager.has_active_customers(),
## used by gui.gd's close-day confirmation) — this is the same protection
## for the automatic timer, which has no player to show a confirmation to:
## instead of silently cancelling an in-progress sale, it waits a short
## beat and rechecks rather than advancing out from under the customer.
func _on_day_timeout() -> void:
	if CustomerManager.has_active_customers():
		day_timer.start(DAY_END_CUSTOMER_RETRY_SECONDS)
		return

	day_timer.start(day_duration_seconds)
	_advance_day()


## Public entry point for forcing a day to pass on demand (used by the dev
## console's "day" command, and by the manual close-day confirmation once
## the player has accepted the CloseDayConfirmWindow warning about an
## active sale) instead of waiting for day_timer. Applies
## Brewery.apply_early_close_cost() first — see its docstring — using how
## much of today's timer was actually spent as the earliness measure,
## captured before the timer resets for the next day. A no-op before the
## clock has actually started (see _on_brewery_state_changed()) — there's
## no day in progress yet to close early, and starting the clock here
## would undercut the whole point of gating it on the first brew: a stray
## click during free practice time shouldn't cost the player an
## early-close penalty.
func force_advance_day() -> void:
	if day_timer.is_stopped():
		return

	# Anyone still being served when the doors are force-closed gets thrown
	# out instead of finishing their purchase — see its own docstring for
	# why this actually cancels the sale rather than just hiding it.
	CustomerManager.evict_active_customers()

	var earliness : float = 1.0 - get_day_progress()
	day_timer.start(day_duration_seconds)

	var brewery := BrewEngine.current_brewery
	if brewery != null:
		brewery.apply_early_close_cost(earliness)

	_advance_day()


func _advance_day() -> void:
	var brewery := BrewEngine.current_brewery
	if brewery == null:
		return

	brewery.current_day += 1
	print(StringContainer.DAY_CHANGED_MESSAGE % brewery.current_day)

	brewery.today_sale_receipts.clear()

	# Cellar aging no longer runs here — it ticks continuously on its own
	# timer (see AGING_TICK_SECONDS / _on_aging_tick()) instead of jumping
	# once per day close.
	_charge_daily_utility_bills(brewery)

	SaveManager.save_game()
	# DailyGoalManager listens for this directly rather than being driven
	# from here — it resolves whatever's still active (success/failure) and
	# rolls each slot's replacement in response, same as it does reactively
	# mid-day when a goal completes or an avoid-type one is breached.
	day_changed.emit(brewery.current_day)

	_check_survival_ending(brewery)


## The one "win" condition: outlast both failure states to the day target.
## Requires more than just still being alive — see
## Brewery.SURVIVAL_MIN_REPUTATION's docstring — so a run that's
## technically alive but circling the drain doesn't read as a triumphant
## ending. Skipped entirely if a bankruptcy check earlier this same
## _advance_day() already ended the run, or if the player already chose to
## keep playing past this ending once (Brewery.has_continued_past_survival)
## — otherwise it would fire again on every single day close from here on.
func _check_survival_ending(brewery : Brewery) -> void:
	if brewery.game_has_ended or brewery.has_continued_past_survival:
		return
	if brewery.current_day < SURVIVAL_DAY_TARGET:
		return
	if brewery.reputation < Brewery.SURVIVAL_MIN_REPUTATION or brewery.money <= 0.0:
		return

	brewery.trigger_ending("survived")


## Gated behind tutorial_complete() (same bar as DailyGoalManager's goals) so
## a brand-new player isn't billed for electricity/water before they've
## even bought their first ingredients.
func _charge_daily_utility_bills(brewery : Brewery) -> void:
	if not brewery.tutorial_complete():
		return

	var total : int = DAILY_ELECTRICITY_COST + DAILY_WATER_COST
	brewery.money -= total
	BrewerySignals.daily_bills_paid.emit(DAILY_ELECTRICITY_COST, DAILY_WATER_COST, total)
	BrewerySignals.brewery_state_changed.emit(brewery)
	brewery.check_bankruptcy()


## Called by SaveManager.save_game() right before it serializes the Brewery
## resource, so whatever's actually left on the live day_timer travels with
## the save instead of Brewery.day_time_remaining_seconds sitting stale at
## whatever a previous save last wrote there. A stopped clock (the day
## hasn't started yet — see _on_brewery_state_changed()'s gating) leaves the
## -1.0 sentinel in place rather than writing a meaningless "0 seconds left".
func sync_remaining_time_to_brewery(brewery : Brewery) -> void:
	if day_timer.is_stopped():
		return
	brewery.day_time_remaining_seconds = day_timer.time_left


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
	aging_timer.paused = true

func resume_time() -> void:
	day_timer.paused = false
	aging_timer.paused = false
