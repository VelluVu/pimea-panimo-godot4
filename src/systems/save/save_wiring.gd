class_name SaveWiring
extends SaveSlot

## This game's run save: the one file to edit after copying the save system.
## Saves BrewEngine.current_brewery. Almost all run state is already a Resource
## with @export fields, so the whole graph serializes as is. Autoloads that keep
## live run state elsewhere (TimeManager's day countdown) write it onto the
## Brewery on BrewEngine.brewery_about_to_save. The game's SaveManager autoload
## extends this.

## Version 0 -> 1 needed no migration step.
const SAVE_VERSION: int = 1

## Endings that finish the run for good. "survived" is left out on purpose:
## the player can choose to keep playing, so that run must stay saved.
const RUN_ENDING_TYPES: PackedStringArray = ["busted", "bankrupt"]


func _init() -> void:
	save_path = "user://savegame.tres"
	version = SAVE_VERSION
	version_property = &"save_version"


func _ready() -> void:
	super._ready()
	BrewerySignals.game_ended.connect(_on_game_ended)


func save_game() -> bool:
	var brewery: Brewery = BrewEngine.current_brewery
	# A run that already ended must never overwrite the save, or "Jatka"
	# would resume a dead run with its ended flag lost.
	if brewery == null or brewery.game_has_ended:
		return false

	BrewEngine.brewery_about_to_save.emit(brewery)
	return write(brewery)


## The current run is left untouched when nothing could be loaded.
func load_game() -> bool:
	var loaded: Brewery = read() as Brewery
	if loaded == null:
		return false

	BrewEngine.set_brewery(loaded)
	BrewEngine.current_brewery.emit_initial_values()
	return true


func _on_game_ended(ending_type: String) -> void:
	if ending_type in RUN_ENDING_TYPES:
		delete_save()
