class_name ReputationTiers
extends RefCounted

## Looks up which named tier a reputation falls in. The lookups take the tier
## list as a parameter so tests can pass their own.

const FOLDER_PATH: String = "res://src/resources/reputation_tiers/"
## How far below a tier's start reputation must fall before the drop is announced.
const DROP_MARGIN: int = 5

static var _loaded: Array[ReputationTier] = []


## Every tier, lowest first. Loaded once.
static func all() -> Array[ReputationTier]:
	if _loaded.is_empty():
		_loaded.assign(ResourceFolder.load_all(FOLDER_PATH, ReputationTier))
		_loaded.sort_custom(func(a: ReputationTier, b: ReputationTier) -> bool: return a.min_reputation < b.min_reputation)
	return _loaded


## The highest tier `reputation` has reached, or null if none has. `tiers` is lowest first.
static func tier_for(reputation: int, tiers: Array[ReputationTier]) -> ReputationTier:
	var reached: ReputationTier = null
	for tier: ReputationTier in tiers:
		if reputation >= tier.min_reputation:
			reached = tier
	return reached


## The tier to announce after a change, given the one announced last. A rise is
## announced at once; a drop only once reputation is DROP_MARGIN below the announced
## tier's start, so hovering at a boundary does not toast up and down all day.
static func announced_tier(announced: ReputationTier, reputation: int, tiers: Array[ReputationTier]) -> ReputationTier:
	var actual: ReputationTier = tier_for(reputation, tiers)
	if announced == null or actual == null:
		return actual
	if actual.min_reputation >= announced.min_reputation:
		return actual
	if reputation <= announced.min_reputation - DROP_MARGIN:
		return actual
	return announced


## The first tier above `reputation`, or null at the top. `tiers` is lowest first.
static func next_tier(reputation: int, tiers: Array[ReputationTier]) -> ReputationTier:
	for tier: ReputationTier in tiers:
		if reputation < tier.min_reputation:
			return tier
	return null
