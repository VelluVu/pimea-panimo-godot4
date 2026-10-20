class_name DayRules
extends RefCounted

## The pure day rules behind TimeManager: a day's costs, the season's end and the clock's
## progress. Stateless, for tests.

## The cellar's lights, coolers and water, billed each night once the tutorial is done.
const DAILY_ELECTRICITY_COST : int = 5
const DAILY_WATER_COST : int = 3

## The season's last day: the run is scored, as "survived" with enough reputation and
## money, else "season_over". Play may go on after it.
const SURVIVAL_DAY_TARGET : int = 15
const ENDING_SURVIVED : String = "survived"
const ENDING_SEASON_OVER : String = "season_over"

## LVV risk shed each night. Without it about half of all runs were busted however
## carefully they sold.
const NIGHTLY_RISK_DECAY : int = 15


## Nights that cost nothing, so a newcomer's first experiment never ends in debt.
const FREE_NIGHTS : int = 1


## Whether the night before `new_day` is billed: the first FREE_NIGHTS are not.
static func bills_due(new_day : int) -> bool:
	return new_day > FREE_NIGHTS + 1


static func daily_bill_total() -> int:
	return DAILY_ELECTRICITY_COST + DAILY_WATER_COST


static func risk_after_night(risk : int) -> int:
	return maxi(0, risk - NIGHTLY_RISK_DECAY)


## Today's season ending, or "" while it runs on, or once the run has ended or continued.
static func season_ending(day : int, reputation : int, money : float, run_has_ended : bool, has_continued : bool) -> String:
	if run_has_ended or has_continued or day < SURVIVAL_DAY_TARGET:
		return ""
	if reputation >= Brewery.SURVIVAL_MIN_REPUTATION and money > 0.0:
		return ENDING_SURVIVED
	return ENDING_SEASON_OVER


## How far through the day the timer is, 0 to 1; a stopped timer counts as the start.
static func day_progress(is_running : bool, wait_time : float, time_left : float) -> float:
	if not is_running or wait_time <= 0.0:
		return 0.0
	return (wait_time - time_left) / wait_time


## How long the clock runs after (re)starting: the saved time left, or a full day for -1.
static func clock_start_seconds(saved_remaining : float, day_duration : float) -> float:
	# A save from when days were longer must not leave more than a day on the clock.
	return minf(saved_remaining, day_duration) if saved_remaining >= 0.0 else day_duration
