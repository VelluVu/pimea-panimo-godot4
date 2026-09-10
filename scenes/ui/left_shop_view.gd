class_name ShopView
extends VBoxContainer

const AMOUNT_PRICE_FORMAT : String = "%d %s - %d €"

@onready var current_item_label : Label = $Panel/MarginContainer/IngredientSelectionElementList/IngredientTypeSelector/IngredientRow/CurrentItemLabel
@export var main_slider : Slider
@export var buy_button : Button
@export var sell_button : Button


var current_id: int = -1


func _ready() -> void:
	main_slider.value_changed.connect(_on_slider_changed)
	GUISignals.active_ingredient_changed.connect(_on_ingredient_selected_globally)
	_update_label()


func _on_ingredient_selected_globally(id: int) -> void:
	current_id = id
	_update_slider()
	_update_label()


func _on_slider_changed(_value : float) -> void:
	if current_id == -1:
		return
	
	_update_label()


func _update_slider() -> void:
	if current_id == -1:
		return
	
	var ingredient = IngredientDatabase.get_item_by_id(current_id)
	if ingredient == null:
		return
	
	var player_money : int = BrewEngine.current_brewery.money
	
	var max_affordable : int = 0
	if ingredient.base_price > 0:
		max_affordable = int(player_money / ingredient.base_price)
		
	var max_limit = min(max_affordable, 99)
	
	main_slider.max_value = max_limit
	main_slider.value = min(main_slider.value, max_limit)


func _update_label() -> void:
	if current_id == -1:
		current_item_label.text = ""
		return

	var ingredient = IngredientDatabase.get_item_by_id(current_id)
	if ingredient == null:
		return

	var total_price : int = ingredient.base_price * main_slider.value
	current_item_label.text = AMOUNT_PRICE_FORMAT % [int(main_slider.value), ingredient.get_unit_string(), total_price]


func _on_buy_button_pressed() -> void:
	if current_id == -1:
		return
	
	var final_id : int = current_id
	var final_amount : int = roundi(main_slider.value)
	
	if final_amount <= 0:
		return
	
	GUISignals.buy_ingredient.emit(final_id, final_amount)


func _on_sell_button_pressed() -> void:
	if current_id == -1:
		return
		
	var final_id : int = current_id
	var final_amount : int = roundi(main_slider.value)
	
	if final_amount <= 0:
		return
	
	GUISignals.sell_ingredient.emit(final_id, final_amount)
