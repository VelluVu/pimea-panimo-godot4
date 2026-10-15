class_name FermentationRules
extends RefCounted

## A brew ferments for a while before it goes into a keg. The keg is picked when
## fermentation ends, so a keg washed meanwhile still helps. A dirty keg can sour the
## batch: the chance grows with the dirt, and cleaning perks cut it. How badly it sours is
## rolled too, and dirt makes it worse.

enum SourLevel { NONE, LIGHT, CLEAR, STRONG }

## About a minute at normal game speed (the timer follows Engine.time_scale).
const SECONDS : float = 60.0
## Chance of souring in a keg that was never washed (cleanliness 0).
const MAX_INFECTION_CHANCE : float = 0.6
## Share of quality a never-washed keg can take at worst; the roll takes 30 to 100 % of it.
const MAX_SOUR_LOSS : float = 0.4
const MIN_SOUR_ROLL : float = 0.3
## Quality losses below these are a light sour, up to the second a clear one, above strong.
const LIGHT_SOUR_BELOW : float = 0.1
const CLEAR_SOUR_UP_TO : float = 0.25


## The very first brew of a run skips fermentation, so the tutorial's first customer
## does not wait for it.
static func duration(is_first_brew : bool) -> float:
	return 0.0 if is_first_brew else SECONDS


## `reduction` is PerkStats.INFECTION_REDUCTION, 0 (none) to 1 (never sours).
static func infection_chance(keg_cleanliness : float, reduction : float) -> float:
	var dirt : float = 1.0 - clampf(keg_cleanliness, KegRules.DIRTY, KegRules.CLEAN)
	return MAX_INFECTION_CHANCE * dirt * (1.0 - clampf(reduction, 0.0, 1.0))


## Share of quality a souring takes: dirt times a `roll` (0 to 1) between MIN_SOUR_ROLL
## and all of MAX_SOUR_LOSS.
static func sour_loss(keg_cleanliness : float, roll : float) -> float:
	var dirt : float = 1.0 - clampf(keg_cleanliness, KegRules.DIRTY, KegRules.CLEAN)
	return dirt * lerpf(MIN_SOUR_ROLL, 1.0, clampf(roll, 0.0, 1.0)) * MAX_SOUR_LOSS


static func sour_level(loss : float) -> SourLevel:
	if loss < LIGHT_SOUR_BELOW:
		return SourLevel.LIGHT
	if loss <= CLEAR_SOUR_UP_TO:
		return SourLevel.CLEAR
	return SourLevel.STRONG


## Seconds left after `elapsed` more seconds, never below zero.
static func remaining(seconds_left : float, elapsed : float) -> float:
	return maxf(0.0, seconds_left - elapsed)


static func is_done(seconds_left : float) -> bool:
	return seconds_left <= 0.0


## 0 at the start, 1 when done; the warehouse shows it.
static func progress(seconds_left : float) -> float:
	return clampf(1.0 - seconds_left / SECONDS, 0.0, 1.0)
