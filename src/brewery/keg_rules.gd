class_name KegRules
extends RefCounted

## A batch is one 20 L keg (BrewResult.bottle_yield, 45 servings fresh). Any batch can be
## shipped, but only a nearly full one counts as a keg for the "Vie tynnyri baariin" goal.

const MIN_SERVINGS : int = 40


static func is_full_keg(servings : int) -> bool:
	return servings >= MIN_SERVINGS
