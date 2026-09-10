class_name BrewPreparationPanel
extends PanelContainer


const INGREDIENT_LABEL_WITH_TARGET_STRING : String = "%s: %d/%d %s"
const SAVE_TOAST_STRING : String = "Resepti \"%s\" tallennettu!"
const REJECT_TOAST_STRING : String = "Tuntematon oluttyyli — keitä se ensin selvittääksesi reseptin!"
const SAVE_TOAST_FLASH_SECONDS : float = 0.15
const SAVE_TOAST_HOLD_SECONDS : float = 1.2
const SAVE_TOAST_FADE_SECONDS : float = 0.4
const NO_ACTIVE_RECIPE_TEXT : String = "resepti:"

@onready var table_list_vbox : VBoxContainer = $VBoxContainer/TableScrollContainer/IngredientListVBox
@onready var save_recipe_toast : Label = $VBoxContainer/ButtonPanel/SaveRecipeToast
@onready var current_recipe_label : Label = $VBoxContainer/CurrentRecipeBar/HBoxContainer/CurrentRecipeLabel
@onready var erase_button : Button = $VBoxContainer/CurrentRecipeBar/HBoxContainer/EraseButton

var table_labels: Dictionary = {} # Key: int (ID) -> Value: Label
var _toast_tween : Tween


func _ready() -> void:
	_initialize_table_nodes()
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)
	BrewerySignals.recipe_saved.connect(_on_recipe_saved)
	BrewerySignals.recipe_save_rejected.connect(_on_recipe_save_rejected)
	erase_button.pressed.connect(_on_erase_button_pressed)
	_update_table_list_ui()


func _on_erase_button_pressed() -> void:
	GUISignals.clear_brew_preparation_requested.emit()


func _on_recipe_saved(recipe_name : String) -> void:
	save_recipe_toast.text = SAVE_TOAST_STRING % recipe_name

	if _toast_tween:
		_toast_tween.kill()

	save_recipe_toast.modulate = Color(1.4, 1.4, 1.0, 0.0)

	_toast_tween = create_tween()
	_toast_tween.tween_property(save_recipe_toast, "modulate", Color(1.4, 1.4, 1.0, 1.0), SAVE_TOAST_FLASH_SECONDS)
	_toast_tween.tween_property(save_recipe_toast, "modulate", Color(1.0, 1.0, 1.0, 1.0), SAVE_TOAST_FLASH_SECONDS)
	_toast_tween.tween_interval(SAVE_TOAST_HOLD_SECONDS)
	_toast_tween.tween_property(save_recipe_toast, "modulate:a", 0.0, SAVE_TOAST_FADE_SECONDS)


func _on_recipe_save_rejected() -> void:
	save_recipe_toast.text = REJECT_TOAST_STRING

	if _toast_tween:
		_toast_tween.kill()

	save_recipe_toast.modulate = Color(1.4, 0.6, 0.6, 0.0)

	_toast_tween = create_tween()
	_toast_tween.tween_property(save_recipe_toast, "modulate", Color(1.4, 0.6, 0.6, 1.0), SAVE_TOAST_FLASH_SECONDS)
	_toast_tween.tween_property(save_recipe_toast, "modulate", Color(1.0, 1.0, 1.0, 1.0), SAVE_TOAST_FLASH_SECONDS)
	_toast_tween.tween_interval(SAVE_TOAST_HOLD_SECONDS)
	_toast_tween.tween_property(save_recipe_toast, "modulate:a", 0.0, SAVE_TOAST_FADE_SECONDS)


func _initialize_table_nodes() -> void:
	for id in IngredientDatabase.sorted_ids:
		var new_label := Label.new()
		new_label.visible = false
		new_label.mouse_filter = Control.MOUSE_FILTER_STOP
		new_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		new_label.add_theme_font_size_override("font_size", 16)
		table_list_vbox.add_child(new_label)
		table_labels[id] = new_label


func _on_brewery_state_changed(_brewery : Brewery) -> void:
	_update_table_list_ui()


func _on_recipe_library_button_pressed() -> void:
	GUISignals.recipe_library_requested.emit()


func _on_save_recipe_button_pressed() -> void:
	GUISignals.save_recipe_requested.emit()


func _update_table_list_ui() -> void:
	if BrewEngine.current_brewery == null:
		return

	var active_recipe_style_name : String = BrewEngine.current_brewery.brew_preparation.active_recipe_style_name
	current_recipe_label.text = active_recipe_style_name if not active_recipe_style_name.is_empty() else NO_ACTIVE_RECIPE_TEXT
	current_recipe_label.tooltip_text = current_recipe_label.text

	var prep_contents : Dictionary = BrewEngine.current_brewery.brew_preparation.selected_contents
	var recipe_target : Dictionary = BrewEngine.current_brewery.brew_preparation.active_recipe_target

	for id in IngredientDatabase.sorted_ids:

		var ingredient: IngredientData = IngredientDatabase.database[id]
		var label: Label = table_labels[id]
		var on_table : int = prep_contents.get(id, 0)
		var required : int = recipe_target.get(id, 0)

		if required > 0:
			label.text = INGREDIENT_LABEL_WITH_TARGET_STRING % [ingredient.name, on_table, required, ingredient.get_unit_string()]
			label.tooltip_text = ingredient.description
			label.modulate = Color.LIME_GREEN if on_table >= required else Color.ORANGE
			label.visible = true
		elif on_table > 0:
			label.text = StringContainer.INGREDIENT_LABEL_WITH_STAT_STRING % [ingredient.name, on_table, ingredient.get_unit_string(), ingredient.get_stat_string()]
			label.tooltip_text = ingredient.description
			label.modulate = ingredient.get_color()
			label.visible = true
		else:
			label.visible = false
