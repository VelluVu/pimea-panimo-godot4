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

## The season's last day: reaching it scores the run, as "survived" with enough
## reputation and money, otherwise "season_over". The player may play on after it.
const SURVIVAL_DAY_TARGET : int = 15
const ENDING_SURVIVED : String = "survived"
const ENDING_SEASON_OVER : String = "season_over"

## LVV risk the cellar sheds each night. Without it risk only ever climbed between
## raids, so about half of all runs were busted no matter how carefully they sold.
const NIGHTLY_RISK_DECAY : int = 15


static func daily_bill_total() -> int:
	return DAILY_ELECTRICITY_COST + DAILY_WATER_COST


static func risk_after_night(risk : int) -> int:
	return maxi(0, risk - NIGHTLY_RISK_DECAY)


## The ending the season reaches today, or "" while it runs on. Never fires again
## once the run has ended, or once the player chose to keep playing past it.
static func season_ending(day : int, reputation : int, money : float, run_has_ended : bool, has_continued : bool) -> String:
	if run_has_ended or has_continued or day < SURVIVAL_DAY_TARGET:
		return ""
	if reputation >= Brewery.SURVIVAL_MIN_REPUTATION and money > 0.0:
		return ENDING_SURVIVED
	return ENDING_SEASON_OVER


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
