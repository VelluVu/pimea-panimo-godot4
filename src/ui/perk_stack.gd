class_name PerkStack
extends RefCounted

## Groups perks for RunEffectsWindow: one row per perk name with how many times it was
## taken, in first-taken order, keeping Olutoppi perks and level-up picks apart.

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
		if index_by_name.has(perk.perk_name):
			result[index_by_name[perk.perk_name]][KEY_COUNT] += 1
		else:
			index_by_name[perk.perk_name] = result.size()
			result.append({KEY_PERK: perk, KEY_COUNT: 1})
	return result
