class_name BrewingView
extends Control

## The chosen amount under the slider, with the stock it comes from.
const AMOUNT_FORMAT : String = "%s %s (varastossa %s %s)"
const SLIDER_TOOLTIP_FORMAT : String = "Määrä (%s / %s)"
const ADD_TOOLTIP_FORMAT : String = "Lisää valittu määrä pöydälle (%s)"
const REMOVE_TOOLTIP : String = "Palauta valittu määrä pöydältä varastoon"
## Why a press did nothing, floated off the button.
const NOT_IN_STOCK_TEXT : String = "Ei varastossa"
const NOT_ON_TABLE_TEXT : String = "Ei pöydällä"
const NO_AMOUNT_TEXT : String = "Valitse määrä"
const FILL_FROM_INVENTORY_BUTTON_TEXT : String = "Täytä resepti"
## Same height as the scene's other buttons, a comfortable finger target.
const FILL_BUTTON_HEIGHT : float = 26.0
const FILL_FROM_INVENTORY_BUTTON_TOOLTIP : String = "Täytä puuttuvat raaka-aineet pöydälle varastosta ladatun reseptin mukaan. Pois käytöstä, jos varastossa ei ole tarpeeksi jotain raaka-ainetta."

@onready var current_item_label : Label = %BrewingItemLabel
@onready var ingredient_type_selector : IngredientTypeSelector = %BrewingTypeSelector
@onready var main_vbox : VBoxContainer = %VBoxContainer
@onready var header_label : Label = $Panel/MarginContainer/VBoxContainer/HeaderLabel
@export var main_slider : Slider
@export var add_button : Button
@export var remove_button : Button

var current_id : int = -1
## Built at runtime below MaltAndHopVBoxContainer, where this view has room for it.
var fill_from_inventory_button : Button = null
var buy_missing_button : BuyMissingButton = null
var _brewery : Brewery = null


func _ready() -> void:
	PanelHeader.wrap(header_label)
	var slider_row : HBoxContainer = SliderStepper.wrap(main_slider)
	_put_amount_first(slider_row)
	ingredient_type_selector.add_step_buttons()
	main_slider.tooltip_text = tr(SLIDER_TOOLTIP_FORMAT) % [InputManager.get_binding_text(InputManager.ACTION_AMOUNT_UP), InputManager.get_binding_text(InputManager.ACTION_AMOUNT_DOWN)]
	add_button.tooltip_text = tr(ADD_TOOLTIP_FORMAT) % InputManager.get_binding_text(InputManager.ACTION_INGREDIENT_CONFIRM)
	remove_button.tooltip_text = REMOVE_TOOLTIP
	main_slider.value_changed.connect(_on_slider_changed)
	GUISignals.active_ingredient_changed.connect(_set_active_ingredient)
	# Buying, selling or moving to the table changes what is available, so the slider's max
	# follows.
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)
	# ShopView's selector fires the same signal, so reset to malt on each open.
	visibility_changed.connect(_on_visibility_changed)

	fill_from_inventory_button = TooltipButton.new()
	fill_from_inventory_button.text = FILL_FROM_INVENTORY_BUTTON_TEXT
	fill_from_inventory_button.tooltip_text = FILL_FROM_INVENTORY_BUTTON_TOOLTIP
	fill_from_inventory_button.disabled = true
	fill_from_inventory_button.custom_minimum_size.y = FILL_BUTTON_HEIGHT
	fill_from_inventory_button.pressed.connect(_on_fill_from_inventory_button_pressed)
	main_vbox.add_child(fill_from_inventory_button)
	buy_missing_button = BuyMissingButton.new(FILL_BUTTON_HEIGHT)
	main_vbox.add_child(buy_missing_button)

	_update_label()


## Pick the amount, read it, then act: the slider row first, the amount line under it, the
## Lisää / Poista buttons below.
func _put_amount_first(slider_row : HBoxContainer) -> void:
	var box : Node = slider_row.get_parent()
	box.move_child(slider_row, 0)
	current_item_label.reparent(box)
	box.move_child(current_item_label, 1)
	current_item_label.size_flags_horizontal = Control.SIZE_FILL
	current_item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _input(event : InputEvent) -> void:
	if IngredientViewKeys.handle(event, self, ingredient_type_selector, main_slider, _on_add_button_pressed):
		get_viewport().set_input_as_handled()


func _on_fill_from_inventory_button_pressed() -> void:
	GUISignals.fill_recipe_from_inventory_requested.emit()


## Enabled exactly when RecipeBook's fill would move something, see RecipeFill.
func _update_fill_from_inventory_button() -> void:
	if _brewery == null:
		fill_from_inventory_button.disabled = true
		return

	var preparation : BrewPreparation = _brewery.brew_preparation
	fill_from_inventory_button.disabled = RecipeFill.from_stock(preparation.active_recipe_target, preparation.selected_contents, _brewery.owned_ingredient_amounts()).is_empty()


## GUI calls this on every new run or loaded save.
func bind_brewery(brewery : Brewery) -> void:
	_brewery = brewery
	_on_brewery_state_changed(brewery)


## Opens on the first ingredient the recipe still needs on the table.
func _on_visibility_changed() -> void:
	if visible:
		ingredient_type_selector.select_ingredient(_first_needed_id())


func _first_needed_id() -> int:
	var preparation : BrewPreparation = _brewery.brew_preparation
	for ingredient_id : int in preparation.active_recipe_target:
		if preparation.active_recipe_target[ingredient_id] > preparation.selected_contents.get(ingredient_id, 0):
			return ingredient_id
	return -1


func _set_active_ingredient(id: int) -> void:
	current_id = id
	_update_slider()
	# The last amount means nothing for another ingredient (25 g of hops is not 25 kg of
	# malt), so start from what the recipe still needs.
	_suggest_amount()
	_update_label()


func _suggest_amount() -> void:
	var ingredient : IngredientData = IngredientDatabase.get_item_by_id(current_id)
	if ingredient == null:
		return
	var preparation : BrewPreparation = _brewery.brew_preparation
	main_slider.value = SuggestedAmount.for_table(preparation.active_recipe_target.get(current_id, 0), _on_table(), _in_stock(), ingredient.amount_step())


func _in_stock() -> int:
	var item : InventoryItem = _brewery.inventory.get_item_by_id(current_id)
	return item.amount if item != null else 0


func _on_table() -> int:
	return _brewery.brew_preparation.selected_contents.get(current_id, 0)


func _on_brewery_state_changed(_changed : Brewery) -> void:
	_update_slider()
	# Bought from here with "Osta puuttuvat": the new stock fills the empty slider.
	if current_id != -1 and is_zero_approx(main_slider.value):
		_suggest_amount()
	_update_label()
	_update_fill_from_inventory_button()


func _on_slider_changed(_value: float) -> void:
	if current_id == -1:
		return
	
	_update_label()


func _update_slider() -> void:
	if current_id == -1:
		return

	# One slider drives Add (bounded by inventory) and Remove (by the table), so take the
	# larger, or a fully moved ingredient could never come back.
	var max_available : int = maxi(_in_stock(), _on_table())
	var step : int = IngredientDatabase.get_item_by_id(current_id).amount_step()

	main_slider.step = step
	# An empty range draws the knob at the far end, which reads as "full": keep a range
	# and lock the slider at 0 instead.
	main_slider.editable = max_available > 0
	main_slider.max_value = maxi(max_available, step)
	main_slider.value = mini(int(main_slider.value), max_available)


func _update_label() -> void:
	if current_id == -1:
		current_item_label.text = ""
		return

	var ingredient: IngredientData = IngredientDatabase.get_item_by_id(current_id)
	if ingredient == null:
		return

	var unit : String = ingredient.get_unit_string()
	current_item_label.text = tr(AMOUNT_FORMAT) % [ingredient.amount_text(int(main_slider.value)), unit, ingredient.amount_text(_in_stock()), unit]


## A press that cannot move anything says why, instead of doing nothing.
func _on_add_button_pressed() -> void:
	if current_id == -1:
		return
	if _in_stock() <= 0:
		FloatingText.reason(add_button, tr(NOT_IN_STOCK_TEXT))
		return
	var final_amount : int = roundi(main_slider.value)
	if final_amount <= 0:
		FloatingText.reason(add_button, tr(NO_AMOUNT_TEXT))
		return
	GUISignals.add_ingredient_to_brew_preparation.emit(current_id, final_amount)
	_advance_to_next_needed()


## Once the selected ingredient is on the table in full, the recipe's next one comes up,
## so a loaded recipe goes on the table with Lisää alone.
func _advance_to_next_needed() -> void:
	var preparation : BrewPreparation = _brewery.brew_preparation
	if preparation.active_recipe_target.get(current_id, 0) > _on_table():
		return
	var next_id : int = _first_needed_id()
	if next_id != -1:
		ingredient_type_selector.select_ingredient(next_id)


func _on_remove_button_pressed() -> void:
	if current_id == -1:
		return
	if _on_table() <= 0:
		FloatingText.reason(remove_button, tr(NOT_ON_TABLE_TEXT))
		return
	var final_amount : int = roundi(main_slider.value)
	if final_amount <= 0:
		FloatingText.reason(remove_button, tr(NO_AMOUNT_TEXT))
		return
	GUISignals.remove_ingredients_from_brew_preparation.emit(current_id, final_amount)


func _on_start_brew_button_pressed() -> void:
	GUISignals.brew_day_requested.emit()
