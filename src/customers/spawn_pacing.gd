class_name SpawnPacing
extends RefCounted

## How long the cellar waits for the next walk-in or group. Reputation and perks shorten
## both, never below each floor; more styles on tap shorten the walk-in wait a little.

const WALK_IN_INTERVAL_MIN_SECONDS: float = 30.0 * DayPace.SCALE
const WALK_IN_INTERVAL_MAX_SECONDS: float = 90.0 * DayPace.SCALE
const WALK_IN_INTERVAL_FLOOR_SECONDS: float = 10.0 * DayPace.SCALE
## Reputation at which waits are halved; they keep shrinking past it, ever slower.
const REPUTATION_SPAWN_SOFT_CAP: float = 100.0
## Each style on tap beyond the first draws this much more walk-in flow, up to
## TAP_FLOW_MAX_EXTRA_STYLES extra styles (+25 % at six styles).
const TAP_FLOW_PER_STYLE: float = 0.05
const TAP_FLOW_MAX_EXTRA_STYLES: int = 5

## Group visits are rarer than walk-ins and have a higher floor.
const GROUP_EVENT_INTERVAL_MIN_SECONDS: float = 150.0 * DayPace.SCALE
const GROUP_EVENT_INTERVAL_MAX_SECONDS: float = 300.0 * DayPace.SCALE
const GROUP_EVENT_FLOOR_SECONDS: float = 120.0 * DayPace.SCALE


## The (min, max) wait: the base range scaled by `factor`, never below `floor_seconds`.
static func interval_bounds(base_min: float, base_max: float, floor_seconds: float, factor: float) -> Vector2:
	var min_time := maxf(floor_seconds, base_min * factor)
	return Vector2(min_time, maxf(min_time, base_max * factor))


## The walk-in wait's factor for `styles_on_tap` different styles for sale.
static func tap_factor(styles_on_tap: int) -> float:
	var extra: int = clampi(styles_on_tap - 1, 0, TAP_FLOW_MAX_EXTRA_STYLES)
	return 1.0 / (1.0 + TAP_FLOW_PER_STYLE * extra)


static func reputation_factor(reputation: float) -> float:
	return REPUTATION_SPAWN_SOFT_CAP / (REPUTATION_SPAWN_SOFT_CAP + reputation)


## `spawn_multiplier` is the perk multiplier shared by walk-ins and groups.
static func walk_in_bounds(reputation: float, spawn_multiplier: float, styles_on_tap: int = 1) -> Vector2:
	var factor := reputation_factor(reputation) * spawn_multiplier * tap_factor(styles_on_tap)
	return interval_bounds(WALK_IN_INTERVAL_MIN_SECONDS, WALK_IN_INTERVAL_MAX_SECONDS, WALK_IN_INTERVAL_FLOOR_SECONDS, factor)


## `group_multiplier` is the perk multiplier on group waits only.
static func group_bounds(reputation: float, spawn_multiplier: float, group_multiplier: float) -> Vector2:
	var factor := reputation_factor(reputation) * spawn_multiplier * group_multiplier
	return interval_bounds(GROUP_EVENT_INTERVAL_MIN_SECONDS, GROUP_EVENT_INTERVAL_MAX_SECONDS, GROUP_EVENT_FLOOR_SECONDS, factor)
