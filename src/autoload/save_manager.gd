#SaveManager (Autoload)
extends Node

## Persists BrewEngine.current_brewery to a single savegame slot. Almost all
## game state (Inventory, BrewBatch, BrewRecipe, BrewPreparation) is already
## a Resource with @export fields, so ResourceSaver/ResourceLoader serialize
## the whole graph without any manual field mapping. The exception is live
## state that genuinely lives in another autoload (e.g. TimeManager's day
## countdown) — save_game() flushes each of those into a Brewery field first
## so it isn't silently lost/reset on the next load.

const SAVE_PATH: String = "user://savegame.tres"

## Bump whenever a saved field is renamed, removed or changes meaning, and add
## the matching step to _migrate(). Saves written before versioning existed
## load as version 0.
const SAVE_VERSION: int = 1

## Endings that finish the run for good. "survived" is left out on purpose:
## the player can choose to keep playing, so that run must stay saved.
const RUN_ENDING_TYPES: PackedStringArray = ["busted", "bankrupt"]


func _ready() -> void:
	get_tree().root.close_requested.connect(_on_close_requested)
	BrewerySignals.game_ended.connect(_on_game_ended)


func has_save() -> bool:
	return SaveFile.exists(SAVE_PATH)


## Returns false without touching the existing save when there is nothing
## worth saving (a finished run) or the write failed.
func save_game() -> bool:
	var brewery: Brewery = BrewEngine.current_brewery
	# A run that already ended must never overwrite the save, or "Jatka"
	# would resume a dead run with its ended flag lost.
	if brewery == null or brewery.game_has_ended:
		return false

	# Live autoload state that Brewery's own fields don't capture on their
	# own has to be flushed in here before serializing — see each sync
	# method's own docstring for why it can't just be re-derived after load.
	TimeManager.sync_remaining_time_to_brewery(brewery)
	brewery.save_version = SAVE_VERSION

	var err: Error = SaveFile.write(brewery, SAVE_PATH)
	if err != OK:
		push_error("Saving failed: %s" % error_string(err))
		return false
	return true


## False when there is no save, it can't be read (even from its backup), or
## it comes from a newer game version. The current run is left untouched then.
func load_game() -> bool:
	var loaded: Brewery = SaveFile.read(SAVE_PATH) as Brewery
	if loaded == null:
		push_warning("No readable save to load")
		return false

	if loaded.save_version > SAVE_VERSION:
		push_warning("Save is from a newer game version (%d > %d), not loading" % [loaded.save_version, SAVE_VERSION])
		return false

	_migrate(loaded)
	BrewEngine.set_brewery(loaded)
	BrewEngine.current_brewery.emit_initial_values()
	return true


## Upgrades a loaded save one version at a time. Add a step per bump, e.g.
## `if brewery.save_version < 2: <rename/convert fields>`, before the final
## stamp. Version 0 -> 1 needed no changes.
func _migrate(brewery: Brewery) -> void:
	brewery.save_version = SAVE_VERSION


func _on_game_ended(ending_type: String) -> void:
	if ending_type in RUN_ENDING_TYPES:
		SaveFile.delete(SAVE_PATH)


func _on_close_requested() -> void:
	save_game()
	get_tree().quit()
