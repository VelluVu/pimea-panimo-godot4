class_name DemoRules
extends RefCounted

## The browser demo (feature tag "demo", see dev/docs/browser_demo_plan.md): a shorter
## season, a "full game coming" ending, and Olutoppi talents shown but not for sale.

const DEMO_FEATURE : String = "demo"
const DEMO_LAST_DAY : int = 5
## The demo's season end: scored like any run, but it is not a survived season.
const ENDING_DEMO_OVER : String = "demo_over"


static func is_demo() -> bool:
	return OS.has_feature(DEMO_FEATURE)


## The season's last day, the day it is scored.
static func last_day(demo : bool = is_demo()) -> int:
	return DEMO_LAST_DAY if demo else DayRules.SURVIVAL_DAY_TARGET


## The demo's ending on its last day, or "" while the run goes on (or has ended).
static func demo_ending(day : int, run_has_ended : bool) -> String:
	if run_has_ended or day < DEMO_LAST_DAY:
		return ""
	return ENDING_DEMO_OVER
