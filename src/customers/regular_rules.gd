class_name RegularRules
extends RefCounted

## Customer types remember how they were treated this run. Delighted visits build
## standing, bad ones cost twice as much; enough standing makes the type a regular
## (kanta-asiakas) who buys more and tips better.

const STANDING_PER_DELIGHTED_VISIT: int = 1
const STANDING_PER_BAD_VISIT: int = -2
const MAX_STANDING: int = 6
const REGULAR_THRESHOLD: int = 3
const EXTRA_BOTTLES: int = 1
const TIP_MULTIPLIER: float = 1.25


static func next_standing(standing: int, delighted: bool, reputation_gain: int) -> int:
	var change: int = 0
	if delighted:
		change = STANDING_PER_DELIGHTED_VISIT
	elif reputation_gain < 0:
		change = STANDING_PER_BAD_VISIT
	return clampi(standing + change, 0, MAX_STANDING)


static func is_regular(standing: int) -> bool:
	return standing >= REGULAR_THRESHOLD
