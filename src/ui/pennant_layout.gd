class_name PennantLayout
extends RefCounted

## Where the pennants of a party banner hang: one pennant per letter, a narrower gap for
## a space, and the string sagging a few whole pixels toward the middle along a hand-set
## profile (no computed curve, so it stays clean pixel art).

const PENNANT_WIDTH : int = 7
const GAP : int = 1
const SPACE_WIDTH : int = 4
## The string's drop in pixels across the banner, left to right.
const SAG_PROFILE : Array[int] = [0, 1, 1, 2, 2, 2, 1, 1, 0]


## [x, character] for each pennant of `text`, x from the banner's left end.
static func slots(text : String) -> Array:
	var result : Array = []
	var x : int = 0
	for character : String in text:
		if character == " ":
			x += SPACE_WIDTH
			continue
		result.append([x, character])
		x += PENNANT_WIDTH + GAP
	return result


## The banner's width: the last pennant's right edge.
static func width(text : String) -> int:
	var all : Array = slots(text)
	return 0 if all.is_empty() else all[-1][0] + PENNANT_WIDTH


## How far the string has dropped at `x` of a banner `total` wide.
static func sag(x : int, total : int) -> int:
	if total <= 0:
		return 0
	@warning_ignore("integer_division")
	var index : int = clampi(x * SAG_PROFILE.size() / total, 0, SAG_PROFILE.size() - 1)
	return SAG_PROFILE[index]
