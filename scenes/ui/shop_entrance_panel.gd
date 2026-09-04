class_name ShopEntrancePanel
extends Panel


@onready var shop_button : Button = $ShopButton
@onready var shop_label : Label = $ShopLabel


func _ready() -> void:
	shop_button.mouse_entered.connect(_on_shop_button_mouse_entered)
	shop_button.mouse_exited.connect(_on_shop_button_mouse_exited)


func deactivate_shop_panel() -> void:
	shop_label.hide()
	shop_button.disabled = true
	shop_button.mouse_filter = Control.MOUSE_FILTER_IGNORE


func activate_shop_panel() -> void:
	shop_label.show()
	shop_button.disabled = false
	shop_button.mouse_filter = Control.MOUSE_FILTER_STOP


func _on_shop_button_mouse_entered() -> void:
	shop_button.modulate = Color.GOLD


func _on_shop_button_mouse_exited() -> void:
	shop_button.modulate = Color.WHITE