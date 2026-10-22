class_name BrewPreparationPanel
extends PanelContainer


const INGREDIENT_LABEL_WITH_TARGET_STRING : String = "%s: %s/%s %s"
const MASH_TUN_FULL_FORMAT : String = "Mäskipataan mahtuu enintään %d kg mallasta. Isompi pata löytyy parannuksista."
const RECIPE_SAVED_TOAST_FORMAT : String = "Resepti \"%s\" tallennettu!"
const REJECT_TOAST_STRING : String = "Tuntematon oluttyyli. Keitä se ensin selvittääksesi reseptin!"
const NO_STYLE_TOAST_STRING : String = "Raaka-aineet eivät sovi mihinkään oluttyyliin."
const DUPLICATE_TOAST_FORMAT : String = "Sama resepti on jo tallennettu: %s"
const REJECT_TOAST_FLASH_COLOR : Color = Color(1.4, 0.6, 0.6, 1.0)
const SAVE_TOAST_FLASH_SECONDS : float = 0.15
const SAVE_TOAST_HOLD_SECONDS : float = 1.2
const SAVE_TOAST_FADE_SECONDS : float = 0.4
const NO_ACTIVE_RECIPE_TEXT : String = "Uusi resepti"
const NO_FREE_KEG_TEXT : String = "Kaikissa tynnyreissä on olutta. Myy tai vie erä baariin, niin tynnyri vapautuu."

## Light blue on both XP popups (here and DialogWiring), apart from the gold money.
const XP_POPUP_COLOR : Color = Color(0.4, 0.75, 1.0, 1)
const XP_POPUP_FORMAT : String = "+%d XP"
const XP_POPUP_DURATION_SECONDS : float = 1.8
const XP_POPUP_OFFSET : Vector2 = Vector2(6, 0)
const XP_POPUP_FLOAT_DISTANCE : float = 35.0
const REPUTATION_POPUP_FORMAT : String = "%+d mainetta"
## Below the XP popup, so the two do not overlap.
const REPUTATION_POPUP_STEP : Vector2 = Vector2(0, 20)

@onready var table_list_vbox : VBoxContainer = %IngredientListVBox
@onready var preview_label : Label = $VBoxContainer/PreviewLabel
@onready var save_recipe_toast : Label = %SaveRecipeToast
@onready var current_recipe_label : Label = %CurrentRecipeLabel
@onready var erase_button : Button = %EraseButton
@onready var start_brew_button : Button = %StartBrewButton

var table_labels: Dictionary = {} # ingredient id -> Label
var _toast : BannerPresenter


func _ready() -> void:
	_toast = BannerPresenter.new(save_recipe_toast, SAVE_TOAST_FLASH_SECONDS, SAVE_TOAST_HOLD_SECONDS, SAVE_TOAST_FADE_SECONDS, true, false)
	# A scene-defined plain Label: the script swap makes its tooltip wrap.
	current_recipe_label.set_script(TooltipLabel)
	_initialize_table_nodes()
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)
	BrewerySignals.recipe_saved.connect(_on_recipe_saved)
	BrewerySignals.recipe_save_rejected.connect(_on_recipe_save_rejected)
	BrewerySignals.brew_xp_gained.connect(_on_brew_xp_gained)
	BrewerySignals.brew_reputation_gained.connect(_on_brew_reputation_gained)
	erase_button.pressed.connect(_on_erase_button_pressed)
	_update_table_list_ui()


## Floats off the "Pane" button; a sale's XP popup appears on the customer instead.
func _on_brew_xp_gained(amount : int) -> void:
	_float_popup(tr(XP_POPUP_FORMAT) % amount, XP_POPUP_COLOR, XP_POPUP_OFFSET)


func _on_brew_reputation_gained(amount : int) -> void:
	var color : Color = Color.GREEN if amount > 0 else Color.RED
	_float_popup(tr(REPUTATION_POPUP_FORMAT) % amount, color, XP_POPUP_OFFSET + REPUTATION_POPUP_STEP)


func _float_popup(text : String, color : Color, offset : Vector2) -> void:
	var popup := Label.new()
	popup.text = text
	popup.modulate = color

	start_brew_button.add_child(popup)
	popup.position = Vector2(start_brew_button.size.x, 0) + offset

	var tween := create_tween().set_parallel(true)
	var target_pos := popup.position + Vector2(0, -XP_POPUP_FLOAT_DISTANCE)
	var target_color := popup.modulate
	target_color.a = 0.0

	tween.tween_property(popup, "position", target_pos, XP_POPUP_DURATION_SECONDS)
	tween.tween_property(popup, "modulate", target_color, XP_POPUP_DURATION_SECONDS)

	tween.chain().tween_callback(popup.queue_free)


func _on_erase_button_pressed() -> void:
	GUISignals.clear_brew_preparation_requested.emit()


func _on_recipe_saved(recipe_name : String) -> void:
	_toast.present(tr(RECIPE_SAVED_TOAST_FORMAT) % recipe_name)


func _on_recipe_save_rejected(reason : int, same_recipe_name : String) -> void:
	var text : String = tr(REJECT_TOAST_STRING)
	match reason:
		RecipeSaveRules.Rejection.NO_STYLE:
			text = tr(NO_STYLE_TOAST_STRING)
		RecipeSaveRules.Rejection.DUPLICATE:
			text = tr(DUPLICATE_TOAST_FORMAT) % same_recipe_name
	_toast.present(text, REJECT_TOAST_FLASH_COLOR)


func _initialize_table_nodes() -> void:
	for id in IngredientDatabase.display_ids():
		var new_label := TooltipLabel.new()
		new_label.visible = false
		new_label.mouse_filter = Control.MOUSE_FILTER_STOP
		new_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		new_label.add_theme_font_size_override("font_size", 16)
		table_list_vbox.add_child(new_label)
		table_labels[id] = new_label


func _on_brewery_state_changed(_brewery : Brewery) -> void:
	_update_table_list_ui()


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

	_update_preview(BrewEngine.current_brewery, prep_contents)

	for id in IngredientDatabase.display_ids():

		var ingredient: IngredientData = IngredientDatabase.database[id]
		var label: Label = table_labels[id]
		var on_table : int = prep_contents.get(id, 0)
		var required : int = recipe_target.get(id, 0)

		if required > 0:
			label.text = INGREDIENT_LABEL_WITH_TARGET_STRING % [tr(ingredient.name), ingredient.amount_text(on_table), ingredient.amount_text(required), ingredient.get_unit_string()]
			label.tooltip_text = ingredient.get_tooltip_text()
			label.modulate = Color.LIME_GREEN if on_table >= required else Color.ORANGE
			label.visible = true
		elif on_table > 0:
			label.text = StringContainer.INGREDIENT_LABEL_WITH_STAT_STRING % [tr(ingredient.name), ingredient.amount_text(on_table), ingredient.get_unit_string(), ingredient.get_short_stat_string()]
			label.tooltip_text = ingredient.get_tooltip_text()
			label.modulate = ingredient.get_color()
			label.visible = true
		else:
			label.visible = false


func _update_preview(brewery : Brewery, prep_contents : Dictionary) -> void:
	var preview : BrewResult = null if prep_contents.is_empty() else brewery.resolver.resolve_brew_style(prep_contents)
	var style_known : bool = preview != null and preview.is_matched and brewery.is_style_known(preview.beer_style.style)
	preview_label.text = BrewPreviewText.text(prep_contents.is_empty(), preview, style_known, brewery.machine_active(CellarMachines.AUTO_KETTLE), brewery.stats.total(PerkStats.QUALITY_BONUS))
	# Nothing would come out yet; the preview says what is missing.
	start_brew_button.disabled = preview == null
	# Every batch needs a keg of its own.
	if not brewery.inventory.has_free_keg():
		preview_label.text = NO_FREE_KEG_TEXT
		start_brew_button.disabled = true
	elif preview != null and not MashTun.holds(preview.malt_weight, brewery.mash_capacity_kg()):
		preview_label.text = tr(MASH_TUN_FULL_FORMAT) % roundi(brewery.mash_capacity_kg())
		start_brew_button.disabled = true
