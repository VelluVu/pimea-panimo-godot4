class_name WarehouseLabel
extends Label

## Hover label for WarehouseHoverArea (opens Right_WarehouseView, the
## owned-ingredients panel — see GUISignals.warehouse_door_clicked). Same
## self-contained pattern as RecipeShelfLabel/ReceiptMachineLabel/
## ChalkboardLabel: listens to its own world-hover-area signal, shows/hides
## itself.

const LABEL_TEXT : String = "Varasto"


func _ready() -> void:
	text = LABEL_TEXT
	hide()
	GUISignals.mouse_entered_warehouse_hover_area.connect(_on_mouse_entered_warehouse_hover_area)


func _on_mouse_entered_warehouse_hover_area(is_entered : bool) -> void:
	visible = is_entered
