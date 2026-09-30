#RunModifierRegistry (Autoload)
extends Node

## Static pool filled in _static_init(), which runs before any autoload is added:
## BrewEngine._init() creates a Brewery that already rolls a run modifier, so a
## _ready()-based pool could still be empty then (same reason as IngredientDatabase).

const RUN_MODIFIER_FOLDER_PATH : String = "res://src/resources/run_modifiers/"
const WARNING_POOL_EMPTY : String = "RunModifierRegistry: Run modifier pool is empty!"

static var pool : Array[RunModifier] = []


static func _static_init() -> void:
	pool.assign(ResourceFolder.load_all(RUN_MODIFIER_FOLDER_PATH, RunModifier))
	if pool.is_empty():
		push_warning(WARNING_POOL_EMPTY)


## An instance method so autoload callers get no static-call warning. Never null: an
## empty pool gives a neutral RunModifier, so Brewery.run_modifier always exists.
func get_random_modifier() -> RunModifier:
	if pool.is_empty():
		return RunModifier.new()
	return pool.pick_random()


## Rolls up to `count` distinct modifiers (no repeats) for the player to
## choose from at run start — see ModifierSelectWindow. Clamped to pool
## size rather than padding with duplicates or nulls: offering fewer
## choices than asked for is a smaller surprise than offering the same
## modifier twice.
##
## The pool's one RunModifier.is_default entry (Tavallinen keikka) is
## guaranteed a slot rather than being left to the same shuffle as every
## other modifier — a player who just wants a plain run without any
## condition attached should always have that option on the table, not
## have it come and go at 3-of-5 odds like everything else. Its position
## among the offered cards is still randomized (the final shuffle below),
## just not whether it's offered at all.
func get_random_modifiers(count : int) -> Array[RunModifier]:
	if pool.is_empty():
		return [RunModifier.new()]

	var default_modifier : RunModifier = _get_default_modifier()
	var rest : Array[RunModifier] = pool.duplicate()
	if default_modifier != null:
		rest.erase(default_modifier)
	rest.shuffle()

	var result : Array[RunModifier] = []
	if default_modifier != null:
		result.append(default_modifier)
	result.append_array(rest.slice(0, maxi(0, count - result.size())))
	result.shuffle()
	return result


## Always [default, medium pick, hard pick] in that fixed order — see
## ModifierSelectWindow, which presents "normal, then a medium modifier,
## then a hard one" instead of a fully random spread. Non-default modifiers
## are ranked by RunModifier.get_difficulty_score() and split at the median
## into a medium (lower) half and a hard (upper) half, so the split stays
## balanced automatically as modifiers are added/removed instead of a
## hand-tuned difficulty cutoff going stale. Falls back to the same
## clamped-to-pool-size spirit as get_random_modifiers() when the pool is
## too small for three distinct roles.
func get_run_start_modifiers() -> Array[RunModifier]:
	if pool.is_empty():
		return [RunModifier.new()]

	var default_modifier : RunModifier = _get_default_modifier()
	var rest : Array[RunModifier] = pool.duplicate()
	if default_modifier != null:
		rest.erase(default_modifier)

	var result : Array[RunModifier] = []
	if default_modifier != null:
		result.append(default_modifier)
	if rest.is_empty():
		return result

	rest.sort_custom(func(a : RunModifier, b : RunModifier) -> bool: return a.get_difficulty_score() < b.get_difficulty_score())
	var split : int = ceili(rest.size() / 2.0)
	var medium_pool : Array[RunModifier] = rest.slice(0, split)
	var hard_pool : Array[RunModifier] = rest.slice(split)
	if hard_pool.is_empty():
		hard_pool = medium_pool

	var medium_choice : RunModifier = medium_pool.pick_random()
	result.append(medium_choice)

	var hard_candidates : Array[RunModifier] = hard_pool.duplicate()
	if hard_candidates.size() > 1:
		hard_candidates.erase(medium_choice)
	result.append(hard_candidates.pick_random())

	return result


func _get_default_modifier() -> RunModifier:
	for modifier : RunModifier in pool:
		if modifier.is_default:
			return modifier
	return null
