class_name KegRules
extends RefCounted

## A batch is one 20 L keg; every brew needs an empty one, clean 0 (just emptied) to 1
## (spotless). Only a nearly full batch counts for "Vie tynnyri baariin". The bar has a
## tap per keg but SPARE_KEGS; full kegs past the taps wait in the warehouse.

const MIN_SERVINGS : int = 40
## Taps a season starts with; the keg upgrade adds a keg and a tap per level.
const START_TAPS : int = 2
## Kegs that wait in the warehouse, full or empty, on top of the ones on tap.
const SPARE_KEGS : int = 2
const START_KEGS : int = START_TAPS + SPARE_KEGS
const DIRTY : float = 0.0
const CLEAN : float = 1.0


static func is_full_keg(servings : int) -> bool:
	return servings >= MIN_SERVINGS


static func starting_kegs() -> Array[float]:
	var kegs : Array[float] = []
	for i : int in START_KEGS:
		kegs.append(CLEAN)
	return kegs


## Taps on the bar for `total_kegs` kegs owned.
static func tap_count(total_kegs : int) -> int:
	return maxi(1, total_kegs - SPARE_KEGS)


static func is_dirty(cleanliness : float) -> bool:
	return cleanliness < CLEAN


static func dirty_count(kegs : Array[float]) -> int:
	return kegs.filter(is_dirty).size()


## Takes the cleanest keg from `kegs` and returns its cleanliness; with none (developer
## cheats) a clean one appears.
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
