class_name SpecialEventPresenter
extends RefCounted

## Opens a special event window in `container` whenever SpecialEventManager triggers one,
## and keeps open windows across a save (Brewery.open_special_events).
## Game-side: this used to live in DialogView, which is now project-independent.

const SPECIAL_EVENT_WINDOW_SCENE : PackedScene = preload("res://src/scenes/ui/special_event_window.tscn")

var _container : Control


func _init(container : Control) -> void:
	_container = container
	SpecialEventManager.special_event_triggered.connect(_on_special_event_triggered)
	BrewEngine.brewery_about_to_save.connect(_record_open_events)
	_resume_open_events.call_deferred()


func _on_special_event_triggered(event_data : SpecialEventData) -> void:
	_open_window().initialize_window(event_data)


func _open_window() -> SpecialEventWindow:
	var window : SpecialEventWindow = SPECIAL_EVENT_WINDOW_SCENE.instantiate()
	_container.add_child(window)
	return window


func _record_open_events(brewery : Brewery) -> void:
	brewery.open_special_events.clear()
	if not is_instance_valid(_container):
		return
	for node : Node in _container.get_children():
		var window := node as SpecialEventWindow
		if window != null and not window.is_queued_for_deletion():
			brewery.open_special_events.append(window.snapshot())


func _resume_open_events() -> void:
	var brewery : Brewery = BrewEngine.current_brewery
	if brewery == null or not is_instance_valid(_container):
		return
	for snap : SpecialEventSnapshot in brewery.open_special_events:
		if snap.event_data != null:
			_open_window().resume(snap)
	brewery.open_special_events.clear()
