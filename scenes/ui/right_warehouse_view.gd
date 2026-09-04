class_name RightWarehouseView
extends VBoxContainer


var is_opened_from_button : bool = false


func _ready() -> void:
	GUISignals.warehouse_hovered.connect(_on_warehouse_hovered)


func show_warehouse_view() -> void:
	is_opened_from_button = true
	show()


func hide_warehouse_view() -> void:
	is_opened_from_button = false
	hide()



func _on_warehouse_hovered(is_hovered: bool) -> void:
	if is_opened_from_button:
		return
	
	if is_hovered:
		show()
	else:
		hide()