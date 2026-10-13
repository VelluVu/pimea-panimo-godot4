class_name KegRules
extends RefCounted

## A batch is one 20 L keg (BrewResult.bottle_yield, 45 servings fresh). Any batch can be
## shipped, but only a nearly full one counts as a keg for the "Vie tynnyri baariin" goal.
##
## Every batch sits in a keg of its own, so a brew needs an empty one. Empty kegs are kept
## as their cleanliness, 0 (just emptied) to 1 (washed spotless). Dirt never grows while a
## keg waits.

const MIN_SERVINGS : int = 40
## Kegs a season starts with; the cellar upgrade buys more.
const START_KEGS : int = 4
const DIRTY : float = 0.0
const CLEAN : float = 1.0


static func is_full_keg(servings : int) -> bool:
	return servings >= MIN_SERVINGS


static func starting_kegs() -> Array[float]:
	var kegs : Array[float] = []
	for i : int in START_KEGS:
		kegs.append(CLEAN)
	return kegs


static func is_dirty(cleanliness : float) -> bool:
	return cleanliness < CLEAN


static func dirty_count(kegs : Array[float]) -> int:
	return kegs.filter(is_dirty).size()


## Removes the cleanest keg from `kegs` and returns its cleanliness. A batch made with no
## keg free (only the developer cheats do that) gets a clean one out of thin air.
static func take_cleanest(kegs : Array[float]) -> float:
	if kegs.is_empty():
		return CLEAN
	var cleanliness : float = kegs.max()
	kegs.erase(cleanliness)
	return cleanliness


## Washes the dirtiest keg in `kegs` to `cleanliness`; a worse wash never makes it dirtier.
## Returns false when there was nothing dirty to wash.
static func wash_dirtiest(kegs : Array[float], cleanliness : float) -> bool:
	if kegs.is_empty() or not is_dirty(kegs.min()):
		return false
	var index : int = kegs.find(kegs.min())
	kegs[index] = maxf(kegs[index], clampf(cleanliness, DIRTY, CLEAN))
	return true
