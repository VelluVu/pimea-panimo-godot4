class_name PauseLock
extends RefCounted

## Shares the SceneTree pause between windows: the tree stays paused while any
## holder still holds it, so closing one window no longer unpauses another
## (the level-up cards, the game menu and Options used to fight over it).

static var _holder_ids: Array[int] = []


static func hold(holder: Node) -> void:
	add_holder(holder.get_instance_id())
	holder.get_tree().paused = true


static func release(holder: Node) -> void:
	holder.get_tree().paused = remove_holder(holder.get_instance_id())


## Holds the pause exactly while the node is visible, whatever hides it.
static func hold_while_visible(holder: CanvasItem) -> void:
	holder.visibility_changed.connect(func() -> void:
		if holder.visible:
			hold(holder)
		else:
			release(holder))


## For scene changes: the old scene's holders go away with it.
static func release_all(tree: SceneTree) -> void:
	_holder_ids.clear()
	tree.paused = false


static func add_holder(id: int) -> void:
	if not _holder_ids.has(id):
		_holder_ids.append(id)


## Returns whether the tree should stay paused. Freed holders count as released.
static func remove_holder(id: int) -> bool:
	_holder_ids.erase(id)
	for i: int in range(_holder_ids.size() - 1, -1, -1):
		if not is_instance_id_valid(_holder_ids[i]):
			_holder_ids.remove_at(i)
	return not _holder_ids.is_empty()


static func clear() -> void:
	_holder_ids.clear()
