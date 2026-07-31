class_name GUI
extends Control

@export var shop_view : ShopView
@export var brewery_view : BrewingView
@export var warehouse_view : WarehouseView
@export var brewery_entrance_panel : Control
@export var shop_entrance_panel : Control
@export var back_button : Control


func _ready() -> void:
	_move_to_bar()


func _move_to_shop() -> void:
	back_button.show()
	brewery_view.hide()
	shop_entrance_panel.hide()
	brewery_entrance_panel.hide()
	shop_view.show()
	warehouse_view.show()


func _move_to_brewery() -> void:
	back_button.show()
	shop_view.hide()
	shop_entrance_panel.hide()
	brewery_entrance_panel.hide()
	brewery_view.show()
	warehouse_view.show()


func _move_to_bar() -> void:
	back_button.hide()
	shop_view.hide()
	brewery_view.hide()
	warehouse_view.hide()
	shop_entrance_panel.show()
	brewery_entrance_panel.show()


func _on_shop_button_pressed() -> void:
	_move_to_shop()


func _on_brewery_button_pressed() -> void:
	_move_to_brewery()


func _on_back_button_pressed() -> void:
	_move_to_bar()
