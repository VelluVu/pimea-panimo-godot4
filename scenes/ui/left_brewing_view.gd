class_name BrewingView
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
@export var add_button : Button
@export var remove_button : Button
@export var selected_ingredients_list : VBoxContainer

var malt_selection_header_formatted_string : String = "Valitse mallas: %s kg"
var hop_selection_header_formatted_string : String = "Valitse humala: %s g"
var yeast_selection_header_formatted_string : String = "Valitse hiiva: %s kpl"
var last_used_slider_index : int = -1


func _on_malt_slider_value_changed(value: float) -> void:
	_edit_header(0,value)


func _on_hop_slider_value_changed(value: float) -> void:
	_edit_header(1,value)


func _on_yeast_slider_value_changed(value: float) -> void:
	_edit_header(2,value)


func _edit_header(index : int, value : int) -> void:
	last_used_slider_index = index
	
	if index == 0:
		malt_selection_header.text = malt_selection_header_formatted_string % value
	elif index == 1:
		hop_selection_header.text = hop_selection_header_formatted_string % value
	elif index == 2:
		yeast_selection_header.text = yeast_selection_header_formatted_string % value
	else:
		last_used_slider_index = -1


func _on_add_button_pressed() -> void:
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
		
	GUISignals.add_ingredient_to_brew_preparation.emit(final_id, final_amount)


func _on_remove_button_pressed() -> void:
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
	
	GUISignals.remove_ingredients_from_brew_preparation.emit(final_id, final_amount)


func _on_start_brew_button_pressed() -> void:
	GUISignals.start_brewing.emit()
