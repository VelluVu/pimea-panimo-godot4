class_name PerkStack
extends RefCounted

## Groups perks for RunEffectsWindow: one row per perk (name and effect) with how many
## times it was taken, in first-taken order, keeping Olutoppi perks and level-up picks
## apart. Copies of one perk at different strengths (the critic's) get their own rows.

const KEY_PERK : StringName = &"perk"
const KEY_COUNT : StringName = &"count"


## Rows of {KEY_PERK: the first perk with that name, KEY_COUNT: int} for the perks whose
## is_permanent equals `permanent`.
static func rows(perks : Array[RunPerk], permanent : bool) -> Array[Dictionary]:
	var result : Array[Dictionary] = []
	var index_by_name : Dictionary = {}
	for perk : RunPerk in perks:
		if perk.is_permanent != permanent:
			continue
		var key : String = perk.perk_name + "|" + perk.get_stat_summary()
		if index_by_name.has(key):
			result[index_by_name[key]][KEY_COUNT] += 1
		else:
			index_by_name[key] = result.size()
			result.append({KEY_PERK: perk, KEY_COUNT: 1})
	return result
