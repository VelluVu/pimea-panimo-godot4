class_name GUI
extends Control


@onready var shop_view : ShopView = $Left_ShopView
@onready var brewery_view : BrewingView = $Left_BrewingView
@onready var brew_preparation_panel : BrewPreparationPanel = $BrewPreparationPanel
@onready var warehouse_view : VBoxContainer = $Right_WarehouseView
@onready var brewery_entrance_panel : Control = $BreweryEntrancePanel
@onready var shop_entrance_panel : ShopEntrancePanel = $ShopEntrancePanel
@onready var recipe_library_window : Control = $RecipeLibraryWindow
@onready var AVI_raid_window : Control = $AviRaidWindow
@onready var back_button : Control = $BackButton


func _ready() -> void:
	await get_tree().process_frame
	_move_to_bar()
	GUISignals.brewery_view_requested.connect(_on_brewery_button_pressed)
	AVI_raid_window.hide()
	recipe_library_window.hide()


func _move_to_shop() -> void:
	back_button.show()
	brewery_view.hide()
	brew_preparation_panel.hide()
	shop_entrance_panel.deactivate_shop_panel()
	brewery_entrance_panel.hide()
	shop_view.show()
	warehouse_view.show_warehouse_view()
	GUISignals.warehouse_view_opened.emit()
	GUISignals.bar_view_exited.emit()


func _move_to_brewery() -> void:
	back_button.show()
	shop_view.hide()
	shop_entrance_panel.deactivate_shop_panel()
	brewery_entrance_panel.hide()
	brewery_view.show()
	brew_preparation_panel.show()
	warehouse_view.show_warehouse_view()
	GUISignals.warehouse_view_opened.emit()
	GUISignals.bar_view_exited.emit()


func _move_to_bar() -> void:
	back_button.hide()
	shop_view.hide()
	brewery_view.hide()
	brew_preparation_panel.hide()
	warehouse_view.hide_warehouse_view()
	shop_entrance_panel.activate_shop_panel()
	brewery_entrance_panel.show()
	GUISignals.warehouse_view_closed.emit()
	GUISignals.bar_view_entered.emit()


func _on_shop_button_pressed() -> void:
	_move_to_shop()


func _on_back_button_pressed() -> void:
	_move_to_bar()


func _on_brewery_button_pressed() -> void:
	if brewery_view.visible or shop_view.visible:
		return
	_move_to_brewery()


func _on_options_button_pressed() -> void:
	GUISignals.options_requested.emit()
