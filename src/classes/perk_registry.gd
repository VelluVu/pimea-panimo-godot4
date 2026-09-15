class_name PerkRegistry
extends RefCounted

## Loads every RunPerk .tres from PERK_FOLDER_PATH into a shared static
## pool — same _static_init() approach as RunModifierRegistry (see that
## file's docstring for why _static_init specifically), but this one is a
## plain class_name utility rather than an autoload: nothing needs perks
## ready before any other autoload's _init() runs (perks are only ever
## rolled on a mid-run level-up, long after Brewery already exists), so
## there's no ordering constraint to design around and no need to touch
## project.godot's autoload list at all. Called directly as
## PerkRegistry.get_random_perks(...), a real static call on a real
## class — no instance-vs-static workaround needed here.

const PERK_FOLDER_PATH : String = "res://src/resources/perks/"
const WARNING_POOL_EMPTY : String = "PerkRegistry: Perk pool is empty!"
const WARNING_FOLDER_OPEN_FAILED : String = "PerkRegistry: Failed to open path: "

static var pool : Array[RunPerk] = []


static func _static_init() -> void:
	var dir := DirAccess.open(PERK_FOLDER_PATH)
	if dir == null:
		push_warning(WARNING_FOLDER_OPEN_FAILED + PERK_FOLDER_PATH)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res = load(PERK_FOLDER_PATH + file_name)
			if res is RunPerk:
				pool.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()

	if pool.is_empty():
		push_warning(WARNING_POOL_EMPTY)


## Weight a common perk is TIER_WEIGHTS[COMMON] times as likely to be drawn
## as a legendary one on any single pick — see RunPerk.Tier/get_tier_label().
const TIER_WEIGHTS : Dictionary = {
	RunPerk.Tier.COMMON: 10,
	RunPerk.Tier.RARE: 4,
	RunPerk.Tier.LEGENDARY: 1,
}


## Rolls up to `count` distinct perks (no repeats within this one offer —
## repeats across separate level-ups, stacking the same perk twice over a
## run, are fine and expected), weighted by TIER_WEIGHTS instead of a flat
## shuffle — legendary perks are rare draws, not evenly-odds ones. Clamped
## to pool size, same reasoning as RunModifierRegistry.get_random_modifiers().
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
