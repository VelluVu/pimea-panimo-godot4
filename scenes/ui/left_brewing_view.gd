class_name BrewingView
extends Control

const AMOUNT_FORMAT : String = "%d %s"

@onready var current_item_label : Label = $Panel/MarginContainer/VBoxContainer/MaltAndHopVBoxContainer/IngredientTypeSelector/IngredientRow/CurrentItemLabel
@export var main_slider : Slider
@export var add_button : Button
@export var remove_button : Button

var current_id : int = -1


func _ready() -> void:
	main_slider.value_changed.connect(_on_slider_changed)
	GUISignals.active_ingredient_changed.connect(_set_active_ingredient)
	_update_label()


func _set_active_ingredient(id: int) -> void:
	current_id = id
	_update_slider()
	_update_label()


func _on_slider_changed(_value: float) -> void:
	if current_id == -1:
		return
	
	_update_label()


func _update_slider() -> void:
	if current_id == -1:
		return
	
	var item = BrewEngine.current_brewery.inventory.get_item_by_id(current_id)

	if item == null:
		return
	
	var max_available = item.amount

	main_slider.max_value = max_available
	main_slider.value = min(main_slider.value, max_available)


func _update_label() -> void:
	if current_id == -1:
		current_item_label.text = ""
		return

	var ingredient = IngredientDatabase.get_item_by_id(current_id)
	if ingredient == null:
		return

	current_item_label.text = AMOUNT_FORMAT % [int(main_slider.value), ingredient.get_unit_string()]


func _on_add_button_pressed() -> void:
	if current_id == -1:
		return
	
	var final_id : int = current_id
	var final_amount : int = roundi(main_slider.value)
	
	if final_amount <= 0:
		return
		
	GUISignals.add_ingredient_to_brew_preparation.emit(final_id, final_amount)


func _on_remove_button_pressed() -> void:
	if current_id == -1:
		return
		
	var final_id : int = current_id
	var final_amount : int = roundi(main_slider.value)
	
	if final_amount <= 0:
		return
	
	GUISignals.remove_ingredients_from_brew_preparation.emit(final_id, final_amount)


func _on_start_brew_button_pressed() -> void:
	GUISignals.start_brewing.emit()
