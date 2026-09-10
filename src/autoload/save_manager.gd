#SaveManager (Autoload)
extends Node

## Persists BrewEngine.current_brewery to a single savegame slot. Every
## piece of game state (Inventory, BrewBatch, BrewRecipe, BrewPreparation)
## is already a Resource with @export fields, so ResourceSaver/ResourceLoader
## serialize the whole graph without any manual field mapping.

const SAVE_PATH: String = "user://savegame.tres"


func _ready() -> void:
	get_tree().root.close_requested.connect(_on_close_requested)


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	ResourceSaver.save(BrewEngine.current_brewery, SAVE_PATH)


func load_game() -> bool:
	if not has_save():
		return false

	var loaded: Brewery = ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as Brewery
	if loaded == null:
		return false

	if BrewEngine.current_brewery != null:
		BrewEngine.current_brewery.disconnect_signals()

	BrewEngine.current_brewery = loaded
	BrewEngine.current_brewery._ready()
	BrewEngine.current_brewery.emit_initial_values()
	return true


func _on_close_requested() -> void:
	if BrewEngine.current_brewery != null:
		save_game()
	get_tree().quit()
