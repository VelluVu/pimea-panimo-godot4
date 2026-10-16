class_name WarehouseLabel
extends Label

## Hover label for WarehouseHoverArea, like RecipeShelfLabel: shows and hides itself on
## its hover area's signal.

const LABEL_TEXT : String = "Varasto"


func _ready() -> void:
	text = LABEL_TEXT
	hide()
	GUISignals.mouse_entered_warehouse_hover_area.connect(_on_mouse_entered_warehouse_hover_area)
	GUISignals.touch_hints_shown.connect(_on_mouse_entered_warehouse_hover_area)


func _on_mouse_entered_warehouse_hover_area(is_entered : bool) -> void:
	visible = is_entered
