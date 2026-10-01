class_name ReputationTiers
extends RefCounted

## Looks up which named tier a reputation falls in. The lookups take the tier
## list as a parameter so tests can pass their own.

const FOLDER_PATH: String = "res://src/resources/reputation_tiers/"

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


## The first tier above `reputation`, or null at the top. `tiers` is lowest first.
static func next_tier(reputation: int, tiers: Array[ReputationTier]) -> ReputationTier:
	for tier: ReputationTier in tiers:
		if reputation < tier.min_reputation:
			return tier
	return null
