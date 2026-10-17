class_name BrewingView
extends Control

const AMOUNT_FORMAT : String = "%s %s"
const FILL_FROM_INVENTORY_BUTTON_TEXT : String = "Täytä resepti"
## Same height as the scene's other buttons, a comfortable finger target.
const FILL_BUTTON_HEIGHT : float = 26.0
const FILL_FROM_INVENTORY_BUTTON_TOOLTIP : String = "Täytä puuttuvat raaka-aineet pöydälle varastosta ladatun reseptin mukaan. Pois käytöstä, jos varastossa ei ole tarpeeksi jotain raaka-ainetta."

@onready var current_item_label : Label = %BrewingItemLabel
@onready var ingredient_type_selector : IngredientTypeSelector = %BrewingTypeSelector
@onready var main_vbox : VBoxContainer = %VBoxContainer
@export var main_slider : Slider
@export var add_button : Button
@export var remove_button : Button

var current_id : int = -1
## Built at runtime below MaltAndHopVBoxContainer, where this view has room for it.
var _fill_from_inventory_button : Button = null


func _ready() -> void:
	SliderStepper.wrap(main_slider)
	ingredient_type_selector.add_step_buttons(current_item_label)
	main_slider.value_changed.connect(_on_slider_changed)
	GUISignals.active_ingredient_changed.connect(_set_active_ingredient)
	# Buying, selling or moving to the table changes what is available; without this the
	# slider kept its old max, stuck at 0 if nothing was owned when picked.
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)
	# ShopView's selector fires the same global signal, so reset to malt each time this
	# view opens.
	visibility_changed.connect(_on_visibility_changed)

	_fill_from_inventory_button = TooltipButton.new()
	_fill_from_inventory_button.text = FILL_FROM_INVENTORY_BUTTON_TEXT
	_fill_from_inventory_button.tooltip_text = FILL_FROM_INVENTORY_BUTTON_TOOLTIP
	_fill_from_inventory_button.disabled = true
	_fill_from_inventory_button.custom_minimum_size.y = FILL_BUTTON_HEIGHT
	_fill_from_inventory_button.pressed.connect(_on_fill_from_inventory_button_pressed)
	main_vbox.add_child(_fill_from_inventory_button)

	_update_label()
	_update_fill_from_inventory_button()


func _input(event : InputEvent) -> void:
	if IngredientViewKeys.handle(event, self, ingredient_type_selector, main_slider, _on_add_button_pressed):
		get_viewport().set_input_as_handled()


func _on_fill_from_inventory_button_pressed() -> void:
	GUISignals.fill_recipe_from_inventory_requested.emit()


## Mirrors Brewery._on_fill_recipe_from_inventory_requested()'s all-or-nothing check:
## a recipe loaded, something missing, and the inventory covering every missing piece.
func _update_fill_from_inventory_button() -> void:
	var brewery := BrewEngine.current_brewery
	if brewery == null:
		_fill_from_inventory_button.disabled = true
		return

	var recipe_target : Dictionary = brewery.brew_preparation.active_recipe_target
	var prep_contents : Dictionary = brewery.brew_preparation.selected_contents

	var has_shortfall : bool = false
	var can_fill_recipe : bool = not recipe_target.is_empty()

	for ingredient_id : int in recipe_target:
		var required : int = recipe_target[ingredient_id]
		var on_table : int = prep_contents.get(ingredient_id, 0)
		if on_table >= required:
			continue

		has_shortfall = true
		var item : InventoryItem = brewery.inventory.get_item_by_id(ingredient_id)
		var available : int = item.amount if item else 0
		if available < required - on_table:
			can_fill_recipe = false

	_fill_from_inventory_button.disabled = not (can_fill_recipe and has_shortfall)


func _on_visibility_changed() -> void:
	if visible:
		ingredient_type_selector.reset_to_first_tab()


func _set_active_ingredient(id: int) -> void:
	current_id = id
	# The last amount means nothing for another ingredient (25 g of hops is not 25 kg of malt).
	main_slider.value = 0
	_update_slider()
	_update_label()


func _on_brewery_state_changed(_brewery : Brewery) -> void:
	_update_slider()
	_update_label()
	_update_fill_from_inventory_button()


func _on_slider_changed(_value: float) -> void:
	if current_id == -1:
		return
	
	_update_label()


func _update_slider() -> void:
	if current_id == -1:
		return

	# An ingredient never bought has no item yet; that is 0 available, so the slider
	# still has to zero.
	var item: InventoryItem = BrewEngine.current_brewery.inventory.get_item_by_id(current_id)
	var inventory_amount : int = item.amount if item != null else 0

	# One slider drives Add (bounded by inventory) and Remove (bounded by the table), so
	# take the larger, or a fully moved ingredient could never come back off.
	var prep_amount : int = BrewEngine.current_brewery.brew_preparation.selected_contents.get(current_id, 0)
	var max_available : int = max(inventory_amount, prep_amount)

	main_slider.max_value = max_available
	main_slider.value = min(main_slider.value, max_available)


func _update_label() -> void:
	if current_id == -1:
		current_item_label.text = ""
		return

	var ingredient: IngredientData = IngredientDatabase.get_item_by_id(current_id)
	if ingredient == null:
		return

	current_item_label.text = AMOUNT_FORMAT % [ingredient.amount_text(int(main_slider.value)), ingredient.get_unit_string()]


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
	GUISignals.brew_day_requested.emit()
