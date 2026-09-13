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

@export var day_duration_seconds : float = 300
var time_accumulator : float = 0.0
var day_timer: Timer


func _ready() -> void:
	day_timer = Timer.new()
	add_child(day_timer)
	day_timer.one_shot = false
	day_timer.timeout.connect(_on_day_timeout)
	day_timer.start(day_duration_seconds)
	GUISignals.close_day_requested.connect(force_advance_day)


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
## the player has already accepted cancelling any active sale) instead of
## waiting for day_timer.
func force_advance_day() -> void:
	day_timer.start(day_duration_seconds)
	_advance_day()


func _advance_day() -> void:
	var brewery := BrewEngine.current_brewery
	if brewery == null:
		return

	brewery.current_day += 1
	print(StringContainer.DAY_CHANGED_MESSAGE % brewery.current_day)

	brewery.today_sale_receipts.clear()

	_process_cellar_aging(brewery.inventory)
	_check_risk_goal_reward(brewery)
	_charge_daily_utility_bills(brewery)

	# bottles_sold_toward_goal deliberately does NOT reset here — a slow
	# day's progress carries into the next one instead of being wiped; it
	# only resets (with overflow preserved) when the goal is actually
	# reached, in CustomerManager._check_bottles_goal_reward().

	SaveManager.save_game()
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


## Gated behind tutorial_complete() (same bar as the goal rewards above) so
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
