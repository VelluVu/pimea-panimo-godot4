class_name WordOfMouthRules
extends RefCounted

## What customers tell others after a visit: a delighted one may send a friend,
## an unhappy one may spread a bad review that keeps the next walk-in away longer.

enum Outcome { NONE, FRIEND, BAD_REVIEW }

const FRIEND_CHANCE: float = 0.25
const BAD_REVIEW_CHANCE: float = 0.3
## Seconds before a recommended friend walks in.
const FRIEND_DELAY_MIN_SECONDS: float = 8.0
const FRIEND_DELAY_MAX_SECONDS: float = 16.0
## Added to the wait for the next walk-in.
const BAD_REVIEW_DELAY_SECONDS: float = 25.0


## `roll` is randf(). A delighted customer never spreads a bad review.
static func outcome(delighted: bool, reputation_gain: int, roll: float) -> Outcome:
	if delighted:
		return Outcome.FRIEND if roll < FRIEND_CHANCE else Outcome.NONE
	if reputation_gain < 0 and roll < BAD_REVIEW_CHANCE:
		return Outcome.BAD_REVIEW
	return Outcome.NONE
