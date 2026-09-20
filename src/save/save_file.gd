class_name SaveFile
extends RefCounted

## Crash-safe read/write of one saved Resource. Knows nothing about Brewery
## or any autoload, so it can be unit-tested with any Resource.
##
## write() never touches the live save until the new one is fully on disk:
## it saves to a temp file, copies the current save to a backup, then renames
## the temp file into place. read() falls back to that backup when the main
## file is missing or unreadable, so one bad write can't lose the run.
##
## ResourceSaver picks its format from the extension, so every sibling path
## keeps a .tres ending.

static func temp_path(path : String) -> String:
	return path.get_basename() + ".tmp.tres"


static func backup_path(path : String) -> String:
	return path.get_basename() + ".bak.tres"


## True when there is anything read() could return, including only a backup.
static func exists(path : String) -> bool:
	return FileAccess.file_exists(path) or FileAccess.file_exists(backup_path(path))


static func write(resource : Resource, path : String) -> Error:
	var temp : String = temp_path(path)
	var err : Error = ResourceSaver.save(resource, temp)
	if err != OK:
		_remove_if_exists(temp)
		return err

	if FileAccess.file_exists(path):
		err = DirAccess.copy_absolute(path, backup_path(path))
		if err != OK:
			_remove_if_exists(temp)
			return err

	err = DirAccess.rename_absolute(temp, path)
	if err != OK:
		_remove_if_exists(temp)
	return err


## The main file, else the backup, else null. Never returns a half-loaded
## resource: a file that fails to load counts as missing.
static func read(path : String) -> Resource:
	for candidate : String in [path, backup_path(path)]:
		if not FileAccess.file_exists(candidate):
			continue
		var loaded : Resource = ResourceLoader.load(candidate, "", ResourceLoader.CACHE_MODE_IGNORE)
		if loaded != null:
			if candidate != path:
				push_warning("Save %s was unreadable, loaded backup %s instead" % [path, candidate])
			return loaded
	return null


## Removes the save, its backup and any leftover temp file.
static func delete(path : String) -> void:
	for candidate : String in [path, backup_path(path), temp_path(path)]:
		_remove_if_exists(candidate)


static func _remove_if_exists(path : String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
