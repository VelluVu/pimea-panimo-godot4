class_name KegRules
extends RefCounted

## A batch is one 20 L keg (BrewResult.bottle_yield). It leaves the cellar as a keg, to a
## bar or sold off in bulk, only while nearly full: once the counter has drawn it below
## MIN_SERVINGS, what is left is sold by the glass.

const MIN_SERVINGS : int = 40


static func can_leave_as_keg(servings : int) -> bool:
	return servings >= MIN_SERVINGS
