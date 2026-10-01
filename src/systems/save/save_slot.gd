class_name SaveSlot
extends Node

## One saved Resource in one file: writes it crash-safely through SaveFile,
## stamps it with a version, refuses saves from a newer version and gives
## older ones a migrate step. Saves on window close when save_on_quit is set.
## The project says what to save and where the loaded one goes by overriding
## save_game() and load_game() in its wiring subclass.

var save_path: String = "user://savegame.tres"
## Bump whenever a saved field is renamed, removed or changes meaning, and add
## the matching step to _migrate().
var version: int = 1
## The int property on the saved resource that holds its version. A resource
## without it reads as version 0.
var version_property: StringName = &"save_version"
var save_on_quit: bool = true


func _ready() -> void:
	if save_on_quit:
		get_tree().root.close_requested.connect(_on_close_requested)


## Override: write the project's state with write(). False when nothing was saved.
func save_game() -> bool:
	return false


## Override: take read()'s resource into the game. False when nothing was loaded.
func load_game() -> bool:
	return false


func has_save() -> bool:
	return SaveFile.exists(save_path)


## Removes the save, its backup and any leftover temp file.
func delete_save() -> void:
	SaveFile.delete(save_path)


## Stamps the version and writes. False, with the old save untouched, when
## there is nothing to save or the write failed.
func write(resource: Resource) -> bool:
	if resource == null:
		return false
	resource.set(version_property, version)
	var err: Error = SaveFile.write(resource, save_path)
	if err != OK:
		push_error("Saving failed: %s" % error_string(err))
		return false
	return true


## The saved resource, migrated to the current version. Null when there is no
## readable save (even from its backup) or it comes from a newer version.
func read() -> Resource:
	var loaded: Resource = SaveFile.read(save_path)
	if loaded == null:
		push_warning("No readable save to load")
		return null

	var saved_version: int = version_of(loaded)
	if saved_version > version:
		push_warning("Save is from a newer version (%d > %d), not loading" % [saved_version, version])
		return null

	_migrate(loaded, saved_version)
	loaded.set(version_property, version)
	return loaded


func version_of(resource: Resource) -> int:
	var value: Variant = resource.get(version_property)
	return value if value is int else 0


## Override: upgrade a save one version at a time, e.g.
## `if from_version < 2: <rename/convert fields>`.
func _migrate(_resource: Resource, _from_version: int) -> void:
	pass


func _on_close_requested() -> void:
	save_game()
	get_tree().quit()
