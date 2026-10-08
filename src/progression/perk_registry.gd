class_name PerkRegistry
extends RefCounted

## Static pool of every RunPerk, filled in _static_init().
## A plain class rather than an autoload: perks are only rolled on a level-up.

const PERK_FOLDER_PATH : String = "res://src/resources/perks/"
const WARNING_POOL_EMPTY : String = "PerkRegistry: Perk pool is empty!"

static var pool : Array[RunPerk] = []


static func _static_init() -> void:
	pool.assign(ResourceFolder.load_all(PERK_FOLDER_PATH, RunPerk))
	if pool.is_empty():
		push_warning(WARNING_POOL_EMPTY)


## Per-perk draw weights. With the current pool a card is legendary about 2.5 %
## of the time, so roughly one level-up in 14 offers one (was one in 5).
const TIER_WEIGHTS : Dictionary = {
	RunPerk.Tier.COMMON: 30,
	RunPerk.Tier.RARE: 10,
	RunPerk.Tier.LEGENDARY: 1,
}


## Rolls up to `count` distinct perks (no repeats within this one offer —
## repeats across separate level-ups, stacking the same perk twice over a
## run, are fine and expected), weighted by TIER_WEIGHTS instead of a flat
## shuffle — legendary perks are rare draws, not evenly-odds ones. Clamped
## to pool size.
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
