class_name RightWarehouseView
extends VBoxContainer

## A click-to-pin panel, since a hover preview vanished before its rows' tooltips could be
## reached. Ingredients and kegs are toggle-button tabs, as a TabBar cannot stretch.

const STORAGE_TAB_TEXT : String = "Varasto"
const BOTTLES_TAB_TEXT : String = "Tynnyrit"

@onready var tab_row : HBoxContainer = %TabRow
@onready var ingredient_inventory_panel : Control = %IngredientInventoryPanel
@onready var beer_batch_panel : Control = %BeerBatchPanel


func _ready() -> void:
	GUISignals.warehouse_door_clicked.connect(_on_door_clicked)

	var group := ButtonGroup.new()
	for text : String in [STORAGE_TAB_TEXT, BOTTLES_TAB_TEXT]:
		var tab := Button.new()
		tab.text = text
		tab.toggle_mode = true
		tab.button_group = group
		tab.focus_mode = Control.FOCUS_NONE
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.pressed.connect(_on_tab_changed.bind(tab_row.get_child_count()))
		tab_row.add_child(tab)
	(tab_row.get_child(0) as Button).button_pressed = true
	_on_tab_changed(0)


func _on_tab_changed(tab_index : int) -> void:
	ingredient_inventory_panel.visible = tab_index == 0
	beer_batch_panel.visible = tab_index == 1


func _on_door_clicked() -> void:
	if visible:
		hide_warehouse_view()
	else:
		show_warehouse_view()


func show_warehouse_view() -> void:
	show()
	GUISignals.warehouse_view_opened.emit()


func hide_warehouse_view() -> void:
	hide()
	GUISignals.warehouse_view_closed.emit()
