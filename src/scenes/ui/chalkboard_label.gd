class_name ChalkboardLabel
extends Label

## Hover label for ChalkboardHoverArea; shows and hides itself on its area's signal.

const LABEL_TEXT : String = "Tilastot"


func _ready() -> void:
	text = LABEL_TEXT
	hide()
	GUISignals.mouse_entered_chalkboard_hover_area.connect(_on_mouse_entered_chalkboard_hover_area)
	GUISignals.touch_hints_shown.connect(_on_mouse_entered_chalkboard_hover_area)


func _on_mouse_entered_chalkboard_hover_area(is_entered : bool) -> void:
	visible = is_entered
