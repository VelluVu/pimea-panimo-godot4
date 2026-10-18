class_name PerkRegistry
extends RefCounted

## Every RunPerk, loaded once. A plain class: perks are only rolled on a level-up.

const PERK_FOLDER_PATH : String = "res://src/resources/perks/"
const WARNING_POOL_EMPTY : String = "PerkRegistry: Perk pool is empty!"

static var pool : Array[RunPerk] = []


static func _static_init() -> void:
	pool.assign(ResourceFolder.load_all(PERK_FOLDER_PATH, RunPerk))
	if pool.is_empty():
		push_warning(WARNING_POOL_EMPTY)


## Per-perk draw weights: about one level-up in 14 offers a legendary.
const TIER_WEIGHTS : Dictionary = {
	RunPerk.Tier.COMMON: 30,
	RunPerk.Tier.RARE: 10,
	RunPerk.Tier.LEGENDARY: 1,
}


## Up to `count` different perks, weighted by tier.
static func get_random_perks(count : int) -> Array[RunPerk]:
	if pool.is_empty():
		return [RunPerk.new()]

	var remaining : Array[RunPerk] = pool.duplicate()
	var result : Array[RunPerk] = []
	var take : int = mini(count, remaining.size())

	for i in range(take):
		var total_weight : int = 0
		for perk : RunPerk in remaining:
			total_weight += TIER_WEIGHTS.get(perk.tier, 1)

		var roll : int = randi() % total_weight
		var cumulative : int = 0
		for perk : RunPerk in remaining:
			cumulative += TIER_WEIGHTS.get(perk.tier, 1)
			if roll < cumulative:
				result.append(perk)
				remaining.erase(perk)
				break

	return result


## Chance that a single card is of this tier, from the whole pool.
static func tier_chance(tier : RunPerk.Tier) -> float:
	var total : int = 0
	var of_tier : int = 0
	for perk : RunPerk in pool:
		var weight : int = TIER_WEIGHTS.get(perk.tier, 1)
		total += weight
		if perk.tier == tier:
			of_tier += weight
	return float(of_tier) / float(total) if total > 0 else 0.0
