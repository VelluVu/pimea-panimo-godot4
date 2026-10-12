class_name BrewDayRules
extends RefCounted

## Turns the brew day's 0..1 score into the batch's quality multiplier.

const FAILED_MULTIPLIER : float = 0.8
const NORMAL_MULTIPLIER : float = 1.0
const PERFECT_MULTIPLIER : float = 1.1
## Pikakeitto: skipping the minigame before the automatic kettle is bought.
const SKIP_MULTIPLIER : float = 0.9
const AUTO_KETTLE_MULTIPLIER : float = PERFECT_MULTIPLIER
const NORMAL_FROM : float = 0.5
const PERFECT_FROM : float = 0.8


## Below NORMAL_FROM the multiplier slides from FAILED up to NORMAL.
static func multiplier(score : float) -> float:
	var clamped : float = clampf(score, 0.0, 1.0)
	if clamped >= PERFECT_FROM:
		return PERFECT_MULTIPLIER
	if clamped >= NORMAL_FROM:
		return NORMAL_MULTIPLIER
	return snappedf(lerpf(FAILED_MULTIPLIER, NORMAL_MULTIPLIER, clamped / NORMAL_FROM), 0.01)


static func final_score(mash_score : float, boil_score : float) -> float:
	return (clampf(mash_score, 0.0, 1.0) + clampf(boil_score, 0.0, 1.0)) / 2.0
