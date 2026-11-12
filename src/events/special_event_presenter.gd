class_name SpecialEventPresenter
extends RefCounted

## Opens a special event window whenever SpecialEventManager triggers one, at most
## SpecialEventQueue.MAX_OPEN_WINDOWS at a time, and keeps open and waiting events across a save.

const SPECIAL_EVENT_WINDOW_SCENE : PackedScene = preload("res://src/scenes/ui/special_event_window.tscn")

var _container : Control
var _queue := SpecialEventQueue.new()


func _init(container : Control) -> void:
	_container = container
	SpecialEventManager.special_event_triggered.connect(_on_special_event_triggered)
	BrewEngine.brewery_about_to_save.connect(_record_open_events)
	_resume_open_events.call_deferred()


func _on_special_event_triggered(event_data : SpecialEventData) -> void:
	if _queue.offer(event_data, _open_windows().size()):
		_open_window().initialize_window(event_data)


func _open_window() -> SpecialEventWindow:
	var window : SpecialEventWindow = SPECIAL_EVENT_WINDOW_SCENE.instantiate()
	window.tree_exited.connect(_open_next_waiting, CONNECT_DEFERRED)
	_container.add_child(window)
	return window


func _open_next_waiting() -> void:
	if not is_instance_valid(_container) or not _container.is_inside_tree():
		return
	var event_data : SpecialEventData = _queue.next(_open_windows().size())
	if event_data != null:
		_open_window().initialize_window(event_data)


func _open_windows() -> Array[SpecialEventWindow]:
	var windows : Array[SpecialEventWindow] = []
	if not is_instance_valid(_container):
		return windows
	for node : Node in _container.get_children():
		var window := node as SpecialEventWindow
		if window != null and not window.is_queued_for_deletion():
			windows.append(window)
	return windows


func _record_open_events(brewery : Brewery) -> void:
	brewery.open_special_events.clear()
	for window : SpecialEventWindow in _open_windows():
		brewery.open_special_events.append(window.snapshot())
	for event_data : SpecialEventData in _queue.waiting():
		var snap := SpecialEventSnapshot.new()
		snap.event_data = event_data
		snap.time_left = SpecialEventSnapshot.NOT_OPENED
		brewery.open_special_events.append(snap)


func _resume_open_events() -> void:
	var brewery : Brewery = BrewEngine.current_brewery
	if brewery == null or not is_instance_valid(_container):
		return
	_queue.clear()
	for snap : SpecialEventSnapshot in brewery.open_special_events:
		if snap.event_data == null:
			continue
		if snap.time_left < 0.0:
			_on_special_event_triggered(snap.event_data)
		else:
			_open_window().resume(snap)
	brewery.open_special_events.clear()
