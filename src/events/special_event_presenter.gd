class_name SpecialEventPresenter
extends RefCounted

## Opens a special event window in `container` whenever SpecialEventManager triggers one.
## Game-side: this used to live in DialogView, which is now project-independent.

const SPECIAL_EVENT_WINDOW_SCENE : PackedScene = preload("res://src/scenes/ui/special_event_window.tscn")

var _container : Control


func _init(container : Control) -> void:
	_container = container
	SpecialEventManager.special_event_triggered.connect(_on_special_event_triggered)


func _on_special_event_triggered(event_data : SpecialEventData) -> void:
	var window : Node = SPECIAL_EVENT_WINDOW_SCENE.instantiate()
	_container.add_child(window)
	window.initialize_window(event_data)
