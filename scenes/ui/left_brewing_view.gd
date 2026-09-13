class_name BrewingView
extends Control

const AMOUNT_FORMAT : String = "%d %s"

@onready var current_item_label : Label = $Panel/MarginContainer/VBoxContainer/MaltAndHopVBoxContainer/IngredientTypeSelector/IngredientRow/CurrentItemLabel
@onready var ingredient_type_selector : IngredientTypeSelector = $Panel/MarginContainer/VBoxContainer/MaltAndHopVBoxContainer/IngredientTypeSelector
@export var main_slider : Slider
@export var add_button : Button
@export var remove_button : Button

var current_id : int = -1


func _ready() -> void:
	main_slider.value_changed.connect(_on_slider_changed)
	GUISignals.active_ingredient_changed.connect(_set_active_ingredient)
	# Without this, the slider's max_value only ever refreshed at the
	# moment an ingredient was selected — buying more, selling some, or
	# moving some to/from the brew table (all of which change how much is
	# actually available) left it stuck at whatever bound it had when the
	# ingredient was first picked. Once that was 0 (nothing owned yet),
	# the slider could never be dragged to anything else even after
	# buying plenty, since a 0-max slider has no range to drag into.
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)
	# ShopView's own IngredientOptionButton listens to this same global
	# active_ingredient_changed signal, so buying/selling something over
	# there leaves current_id here pointing at whatever was last touched
	# globally, not necessarily malt — reset to a known, predictable
	# starting point (tab 0 = malt, first enabled item = Pilsner malt,
	# since it alone has min_reputation 0 and the lowest id in that type)
	# every time this view is actually opened, rather than only once at
	# scene load.
	visibility_changed.connect(_on_visibility_changed)
	_update_label()


func _on_visibility_changed() -> void:
	if visible:
		ingredient_type_selector.reset_to_first_tab()


func _set_active_ingredient(id: int) -> void:
	current_id = id
	_update_slider()
	_update_label()


func _on_brewery_state_changed(_brewery : Brewery) -> void:
	_update_slider()
	_update_label()


func _on_slider_changed(_value: float) -> void:
	if current_id == -1:
		return
	
	_update_label()


func _update_slider() -> void:
	if current_id == -1:
		return

	# get_item_by_id() returns null for an ingredient the player owns none
	# of yet (Inventory only tracks items once at least one unit is
	# bought) — that's a real 0-available state, not "nothing to update",
	# so it must still zero the slider rather than leave it at whatever
	# the previously-selected ingredient's range was (or the editor's
	# authored default, the first time this runs).
	var item = BrewEngine.current_brewery.inventory.get_item_by_id(current_id)
	var max_available : int = item.amount if item != null else 0

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
