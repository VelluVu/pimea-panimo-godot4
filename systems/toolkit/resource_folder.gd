class_name ResourceFolder
extends RefCounted

## Loads every .tres Resource of one script type from a folder, for registries that fill a
## pool from a content folder.

const WARNING_FOLDER_OPEN_FAILED: String = "ResourceFolder: Failed to open path: "
## Exported builds list resources as "<name>.tres.remap".
const REMAP_SUFFIX: String = ".remap"


## Returns the untyped array of loaded resources; callers copy it into their
## typed pool with `pool.assign(...)`. Files of another type are skipped.
static func load_all(folder_path: String, resource_type: Script) -> Array:
	var loaded: Array = []
	var dir := DirAccess.open(folder_path)
	if dir == null:
		push_warning(WARNING_FOLDER_OPEN_FAILED + folder_path)
		return loaded

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and (file_name.ends_with(".tres") or file_name.ends_with(REMAP_SUFFIX)):
			var resource: Resource = load(folder_path + file_name.trim_suffix(REMAP_SUFFIX))
			if resource != null and is_instance_of(resource, resource_type):
				loaded.append(resource)
		file_name = dir.get_next()
	dir.list_dir_end()
	return loaded
