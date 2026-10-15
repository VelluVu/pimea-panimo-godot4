class_name FermentationRules
extends RefCounted

## A brew ferments for a while before it goes into a keg. The keg is picked when
## fermentation ends, so a keg washed meanwhile still helps. A dirty keg can sour the
## batch: the chance grows with the dirt, and cleaning perks cut it.

## About a minute at normal game speed (the timer follows Engine.time_scale).
const SECONDS : float = 60.0
## Chance of souring in a keg that was never washed (cleanliness 0).
const MAX_INFECTION_CHANCE : float = 0.25
## Quality an infected batch keeps.
const INFECTED_QUALITY_MULTIPLIER : float = 0.7


## The very first brew of a run skips fermentation, so the tutorial's first customer
## does not wait for it.
static func duration(is_first_brew : bool) -> float:
	return 0.0 if is_first_brew else SECONDS


## `reduction` is PerkStats.INFECTION_REDUCTION, 0 (none) to 1 (never sours).
static func infection_chance(keg_cleanliness : float, reduction : float) -> float:
	var dirt : float = 1.0 - clampf(keg_cleanliness, KegRules.DIRTY, KegRules.CLEAN)
	return MAX_INFECTION_CHANCE * dirt * (1.0 - clampf(reduction, 0.0, 1.0))


## Seconds left after `elapsed` more seconds, never below zero.
static func remaining(seconds_left : float, elapsed : float) -> float:
	return maxf(0.0, seconds_left - elapsed)


static func is_done(seconds_left : float) -> bool:
	return seconds_left <= 0.0


## 0 at the start, 1 when done; the warehouse shows it.
static func progress(seconds_left : float) -> float:
	return clampf(1.0 - seconds_left / SECONDS, 0.0, 1.0)
