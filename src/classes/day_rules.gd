class_name DayRules
extends RefCounted

## The pure day rules behind TimeManager: what a day costs, when a run is won,
## and how far through a day the clock is. No state, timers or autoloads, so they
## can be unit-tested.

## Recurring overhead: the cellar's lights, coolers and cleaning water run whether
## or not the player brewed. Charged only once the tutorial is complete, so a new
## player is not billed before buying their first ingredients.
const DAILY_ELECTRICITY_COST : int = 5
const DAILY_WATER_COST : int = 3

## Reaching this day, with the run not on the ropes, ends it in the "survived"
## ending instead of running forever.
const SURVIVAL_DAY_TARGET : int = 15


static func daily_bill_total() -> int:
	return DAILY_ELECTRICITY_COST + DAILY_WATER_COST


## The one win condition: outlast both failure states to the day target with
## enough reputation and money to not just be circling the drain. Never fires
## again once the run has ended, or once the player chose to keep playing past it.
static func survival_reached(day : int, reputation : int, money : float, run_has_ended : bool, has_continued : bool) -> bool:
	if run_has_ended or has_continued:
		return false
	if day < SURVIVAL_DAY_TARGET:
		return false
	return reputation >= Brewery.SURVIVAL_MIN_REPUTATION and money > 0.0


## How far through the day the timer is, 0 to 1. A stopped or empty timer counts
## as the start of the day.
static func day_progress(is_running : bool, wait_time : float, time_left : float) -> float:
	if not is_running or wait_time <= 0.0:
		return 0.0
	return (wait_time - time_left) / wait_time


## How long the day clock runs after (re)starting. A save stores the time left
## (0 or more); -1 means the clock had not started, so a full day applies.
static func clock_start_seconds(saved_remaining : float, day_duration : float) -> float:
	return saved_remaining if saved_remaining >= 0.0 else day_duration
