class_name SaveWiring
extends SaveSlot

## This game's run save, the file to edit after copying the system. Saves
## BrewEngine.current_brewery, which serializes as is; autoloads keeping run state
## elsewhere (TimeManager's countdown) write it onto the Brewery on
## BrewEngine.brewery_about_to_save. SaveManager extends this.

## Version 0 -> 1 needed no migration step. 1 -> 2 dropped the run modifier, which is
## stripped from the file text before loading (LegacySaveText). 2 -> 3 adds the spare kegs.
## 3 -> 4 counts four specialty malts in 100 g packs, 4 -> 5 wheat, Münchenin, Vienna
## and rye in 500 g packs (MaltPackMigration).
const SAVE_VERSION: int = 5

## Endings that finish the run for good. The season endings ("survived",
## "season_over") are left out on purpose: the player can keep playing.
## The browser demo's end ("demo_over", DemoRules) is final too.
const RUN_ENDING_TYPES: PackedStringArray = ["busted", "bankrupt", "demo_over"]


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
	StyleDiscovery.new(BrewEngine.current_brewery).refresh_default_recipes()
	BrewEngine.current_brewery.emit_initial_values()
	return true


func _migrate(resource: Resource, from_version: int) -> void:
	var brewery := resource as Brewery
	if brewery == null:
		return
	# Every keg used to have its own tap. The bar keeps those taps, so the warehouse's
	# spare kegs come on top.
	if from_version < 3:
		brewery.inventory.add_clean_kegs(KegRules.SPARE_KEGS)
	if from_version < 4:
		MaltPackMigration.migrate(brewery)
	if from_version < 5:
		MaltPackMigration.migrate(brewery, MaltPackMigration.HALF_KILO_IDS, MaltPackMigration.HALF_KILO_PACKS)


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
