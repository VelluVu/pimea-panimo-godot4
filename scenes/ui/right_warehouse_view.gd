class_name RightWarehouseView
extends VBoxContainer

## Independent click-to-pin panel, decoupled from Shop/Brewing view
## navigation — a hover-only preview made it impossible to reach into the
## panel and hover an ingredient row for its stat tooltip before the panel
## itself disappeared. Ingredient storage and bottle storage are tabbed
## instead of shown side by side, so the panel can stay narrow.

const STORAGE_TAB_TEXT : String = "Varasto"
const BOTTLES_TAB_TEXT : String = "Pullot"

@onready var tab_bar : TabBar = $Panel/MarginContainer/MainVBox/TabBar
@onready var ingredient_inventory_panel : Control = $Panel/MarginContainer/MainVBox/ContentVBox/IngredientInventoryPanel
@onready var beer_batch_panel : Control = $Panel/MarginContainer/MainVBox/ContentVBox/BeerBatchPanel


func _ready() -> void:
	GUISignals.warehouse_door_clicked.connect(_on_door_clicked)

	tab_bar.clear_tabs()
	tab_bar.add_tab(STORAGE_TAB_TEXT)
	tab_bar.add_tab(BOTTLES_TAB_TEXT)
	tab_bar.current_tab = 0
	tab_bar.tab_changed.connect(_on_tab_changed)
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
