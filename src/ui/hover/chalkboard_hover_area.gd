class_name ChalkboardHoverArea
extends CounterHoverArea

## Hover-and-glow trigger for the run stats ("Tilastot"), a wall chalkboard.


func _hover_changed(is_entered : bool) -> void:
	GUISignals.mouse_entered_chalkboard_hover_area.emit(is_entered)


func _clicked() -> void:
	GUISignals.run_effects_requested.emit()
