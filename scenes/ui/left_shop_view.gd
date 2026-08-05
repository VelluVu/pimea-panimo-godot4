class_name ShopView
extends VBoxContainer

@export var malt_selection_header : Label
@export var hop_selection_header : Label
@export var yeast_selection_header : Label
@export var malt_option_button : OptionButton
@export var hop_option_button : OptionButton
@export var yeast_option_button : OptionButton
@export var malt_slider : Slider
@export var hop_slider : Slider
@export var yeast_slider : Slider
@export var buy_button : Button
@export var sell_button : Button

var malt_selection_header_formatted_string = "Valitse mallas: %s kg Hinta: %s €"
var hop_selection_header_formatted_string = "Valitse humala: %s g Hinta: %s €"
var yeast_selection_header_formatted_string = "Valitse hiiva: %s kpl Hinta: %s €"

var last_used_slider_index = -1


func _handle_slider_selection(index : int, value : int) -> void:
	last_used_slider_index = index
	var total_price : int = 0
	
	if index == 0:
		var malt_id = malt_option_button.get_selected_id()
		total_price = IngredientDatabase.database[malt_id].base_price * value
		malt_selection_header.text = malt_selection_header_formatted_string % [value, total_price]
	elif index == 1:
		var hop_id = hop_option_button.get_selected_id()
		total_price = IngredientDatabase.database[hop_id].base_price * value
		hop_selection_header.text = hop_selection_header_formatted_string % [value, total_price]
	elif index == 2:
		var yeast_id = yeast_option_button.get_selected_id()
		total_price = IngredientDatabase.database[yeast_id].base_price * value
		yeast_selection_header.text = yeast_selection_header_formatted_string % [value, total_price]


func _on_malt_slider_value_changed(value: float) -> void:
	_handle_slider_selection(0, roundi(value))


func _on_hop_slider_value_changed(value: float) -> void:
	_handle_slider_selection(1, roundi(value))


func _on_yeast_slider_value_changed(value: float) -> void:
	_handle_slider_selection(2, roundi(value))


func _on_buy_button_pressed() -> void:
	if last_used_slider_index == -1:
		return
	
	var final_id : int = 0
	var final_amount : int = 0
	
	match last_used_slider_index:
		0: # MALTAAT
			final_id = malt_option_button.get_selected_id()
			final_amount = roundi(malt_slider.value)
		1: # HUMALAT
			final_id = hop_option_button.get_selected_id()
			final_amount = roundi(hop_slider.value)
		2: # HIIVAT
			final_id = yeast_option_button.get_selected_id()
			final_amount = roundi(yeast_slider.value)
			
	if final_amount <= 0:
		return
	
	GUISignals.buy_ingredient.emit(final_id, final_amount)


func _on_sell_button_pressed() -> void:
	# 1. Tarkistetaan, onko mitään liukuria käytetty
	if last_used_slider_index == -1:
		return
		
	var final_id : int = 0
	var final_amount : int = 0
	
	# 2. Katsotaan lennosta suoraan oikeat elementit indeksin perusteella
	match last_used_slider_index:
		0: # MALTAAT
			final_id = malt_option_button.get_selected_id()
			final_amount = roundi(malt_slider.value) # Korvataan kuvasi 'last_used_slider_value' suoralla luvulla
		1: # HUMALAT
			final_id = hop_option_button.get_selected_id()
			final_amount = roundi(hop_slider.value)
		2: # HIIVAT
			final_id = yeast_option_button.get_selected_id()
			final_amount = roundi(yeast_slider.value)
			
	# 3. Turvatarkistus nollalle tai negatiiviselle
	if final_amount <= 0:
		return
		
	# 4. Ammutaan universaali signaali täysin virheettömästi!
	GUISignals.sell_ingredient.emit(final_id, final_amount)
