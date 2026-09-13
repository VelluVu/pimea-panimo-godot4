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
