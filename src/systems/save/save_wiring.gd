class_name SaveWiring
extends SaveSlot

## This game's run save: the one file to edit after copying the save system.
## Saves BrewEngine.current_brewery. Almost all run state is already a Resource
## with @export fields, so the whole graph serializes as is. Autoloads that keep
## live run state elsewhere (TimeManager's day countdown) write it onto the
## Brewery on BrewEngine.brewery_about_to_save. The game's SaveManager autoload
## extends this.

## Version 0 -> 1 needed no migration step. 1 -> 2 dropped the run modifier, which is
## stripped from the file text before loading (LegacySaveText).
const SAVE_VERSION: int = 2

## Endings that finish the run for good. The season endings ("survived",
## "season_over") are left out on purpose: the player can keep playing.
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
	_clean_legacy_saves()
	var loaded: Brewery = read() as Brewery
	if loaded == null:
		return false

	BrewEngine.set_brewery(loaded)
	BrewEngine.current_brewery.emit_initial_values()
	return true


## Rewrites saves from older builds that Godot could not load at all, see LegacySaveText.
func _clean_legacy_saves() -> void:
	for path: String in [save_path, SaveFile.backup_path(save_path)]:
		if not FileAccess.file_exists(path):
			continue
		var text: String = FileAccess.get_file_as_string(path)
		if not LegacySaveText.needs_cleanup(text):
			continue
		var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		if file != null:
			file.store_string(LegacySaveText.cleaned(text))


func _on_game_ended(ending_type: String) -> void:
	if ending_type in RUN_ENDING_TYPES:
		delete_save()
