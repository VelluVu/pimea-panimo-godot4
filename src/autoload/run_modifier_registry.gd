#RunModifierRegistry (Autoload)
extends Node

## Static var + _static_init() (not a normal _ready()) so the pool is
## guaranteed populated before Brewery._init() runs — mirrors
## IngredientDatabase, which has the exact same constraint (Brewery._init()
## reads it via BrewResolver too). A plain _ready()-based autoload (like
## CustomerRegistry) would race: BrewEngine._init() calls
## Brewery.new() -> Brewery._init() -> RunModifierRegistry.get_random_modifier()
## the moment BrewEngine itself is added to the tree, which can happen
## before this autoload's own _ready() if it were listed later in
## project.godot. _static_init() runs at script parse time, before any
## autoload node processing at all, so there's no ordering dependency.

const RUN_MODIFIER_FOLDER_PATH : String = "res://src/resources/run_modifiers/"
const WARNING_POOL_EMPTY : String = "RunModifierRegistry: Run modifier pool is empty!"
const WARNING_FOLDER_OPEN_FAILED : String = "RunModifierRegistry: Failed to open path: "

static var pool : Array[RunModifier] = []


static func _static_init() -> void:
	var dir := DirAccess.open(RUN_MODIFIER_FOLDER_PATH)
	if dir == null:
		push_warning(WARNING_FOLDER_OPEN_FAILED + RUN_MODIFIER_FOLDER_PATH)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res = load(RUN_MODIFIER_FOLDER_PATH + file_name)
			if res is RunModifier:
				pool.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()

	if pool.is_empty():
		push_warning(WARNING_POOL_EMPTY)


## Instance method (not static) purely so callers can write
## RunModifierRegistry.get_random_modifier() without a static-called-on-
## instance warning — pool itself still has to be a static var (see
## _static_init()'s docstring above for why). Never null while any .tres
## exists under RUN_MODIFIER_FOLDER_PATH — falls back to a fresh
## default-valued RunModifier (all multipliers 1.0) only if the pool
## somehow ended up empty, so Brewery.run_modifier is never null.
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


func _get_default_modifier() -> RunModifier:
	for modifier : RunModifier in pool:
		if modifier.is_default:
			return modifier
	return null
