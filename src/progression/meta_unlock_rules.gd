class_name MetaUnlockRules
extends RefCounted

## Prerequisite and purchase rules of the Olutoppi tree. Pure: `levels` maps unlock_id to
## the invested level, as MetaProgressManager stores it.


static func is_maxed(unlock : MetaUnlockData, level : int) -> bool:
	return level >= unlock.max_level


## Every prerequisite needs at least 1 invested level, or just one of them for an
## any-mode capstone. A root node (no prerequisites) is always met.
static func meets_prerequisites(unlock : MetaUnlockData, levels : Dictionary) -> bool:
	var invested : Callable = func(prerequisite_id : String) -> bool: return levels.get(prerequisite_id, 0) > 0
	if unlock.requires_any_prerequisite:
		return unlock.prerequisite_ids.is_empty() or unlock.prerequisite_ids.any(invested)
	return unlock.prerequisite_ids.all(invested)


## Not maxed, prerequisites met and enough renown for the next level.
static func can_purchase(unlock : MetaUnlockData, levels : Dictionary, renown : int) -> bool:
	var level : int = levels.get(unlock.unlock_id, 0)
	return not is_maxed(unlock, level) and meets_prerequisites(unlock, levels) and renown >= unlock.renown_cost_per_level
