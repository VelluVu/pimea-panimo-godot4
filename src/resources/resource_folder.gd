class_name ResourceFolder
extends RefCounted

## Loads every .tres Resource of one script type from a folder. The registries
## (customers, events, bar contacts, ...) all populate their pools this way.

const WARNING_FOLDER_OPEN_FAILED: String = "ResourceFolder: Failed to open path: "


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
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var resource: Resource = load(folder_path + file_name)
			if resource != null and is_instance_of(resource, resource_type):
				loaded.append(resource)
		file_name = dir.get_next()
	dir.list_dir_end()
	return loaded
