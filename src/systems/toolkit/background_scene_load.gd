class_name BackgroundSceneLoad
extends RefCounted

## Reads a scene on a thread ahead of time, so switching to it later does not freeze the
## game while it loads (the cellar took over a second). Start it when the scene is likely
## next, then change_to() when it is wanted; that waits only for what is still unread.


## Starts reading `path` in the background; harmless when it is already loading or loaded.
static func start(path : String) -> void:
	if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		ResourceLoader.load_threaded_request(path)


## Switches `tree` to `path`, using the background read when there is one.
static func change_to(tree : SceneTree, path : String) -> void:
	var scene : PackedScene = null
	if ResourceLoader.load_threaded_get_status(path) != ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		scene = ResourceLoader.load_threaded_get(path) as PackedScene
	if scene == null:
		tree.change_scene_to_file(path)
		return
	tree.change_scene_to_packed(scene)
