class_name SpawnPacing
extends RefCounted

## How long the cellar waits for the next walk-in or group visit. Reputation and
## spawn perks shorten both waits, never below each kind's floor.

const WALK_IN_INTERVAL_MIN_SECONDS: float = 30.0
const WALK_IN_INTERVAL_MAX_SECONDS: float = 90.0
const WALK_IN_INTERVAL_FLOOR_SECONDS: float = 10.0
## Reputation at which waits are halved; they keep shrinking past it, ever slower.
const REPUTATION_SPAWN_SOFT_CAP: float = 100.0

## Group visits are rarer than walk-ins and have a higher floor.
const GROUP_EVENT_INTERVAL_MIN_SECONDS: float = 150.0
const GROUP_EVENT_INTERVAL_MAX_SECONDS: float = 300.0
const GROUP_EVENT_FLOOR_SECONDS: float = 120.0


## The (min, max) wait: the base range scaled by `factor`, never below `floor_seconds`.
static func interval_bounds(base_min: float, base_max: float, floor_seconds: float, factor: float) -> Vector2:
	var min_time := maxf(floor_seconds, base_min * factor)
	return Vector2(min_time, maxf(min_time, base_max * factor))


static func reputation_factor(reputation: float) -> float:
	return REPUTATION_SPAWN_SOFT_CAP / (REPUTATION_SPAWN_SOFT_CAP + reputation)


## `spawn_multiplier` is the perk multiplier shared by walk-ins and groups.
static func walk_in_bounds(reputation: float, spawn_multiplier: float) -> Vector2:
	var factor := reputation_factor(reputation) * spawn_multiplier
	return interval_bounds(WALK_IN_INTERVAL_MIN_SECONDS, WALK_IN_INTERVAL_MAX_SECONDS, WALK_IN_INTERVAL_FLOOR_SECONDS, factor)


## `group_multiplier` is the perk multiplier on group waits only.
static func group_bounds(reputation: float, spawn_multiplier: float, group_multiplier: float) -> Vector2:
	var factor := reputation_factor(reputation) * spawn_multiplier * group_multiplier
	return interval_bounds(GROUP_EVENT_INTERVAL_MIN_SECONDS, GROUP_EVENT_INTERVAL_MAX_SECONDS, GROUP_EVENT_FLOOR_SECONDS, factor)
