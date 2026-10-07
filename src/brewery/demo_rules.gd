class_name DemoRules
extends RefCounted

## The browser demo's limits. A web export with the custom feature tag "demo" (see
## dev/docs/browser_demo_plan.md) is the same game with a shorter season, ending in a
## "full game coming" screen, and with Olutoppi talents shown but not for sale.

const DEMO_FEATURE : String = "demo"
const DEMO_LAST_DAY : int = 5
## The demo's season end: scored like any run, but it is not a survived season.
const ENDING_DEMO_OVER : String = "demo_over"


static func is_demo() -> bool:
	return OS.has_feature(DEMO_FEATURE)


## The season's last day, the day it is scored.
static func last_day(demo : bool = is_demo()) -> int:
	return DEMO_LAST_DAY if demo else DayRules.SURVIVAL_DAY_TARGET


## The demo's own ending once its last day comes, or "" when the run goes on (also
## after it has ended).
static func demo_ending(day : int, run_has_ended : bool) -> String:
	if run_has_ended or day < DEMO_LAST_DAY:
		return ""
	return ENDING_DEMO_OVER
