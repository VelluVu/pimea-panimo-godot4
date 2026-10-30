class_name BrewPreparationPanel
extends PanelContainer

## The X of the brewery or shop window this panel completes; it sits on the right edge.
signal close_requested


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
const START_BREW_TOOLTIP : String = "Pane pöydän raaka-aineista olut tynnyriin"

@onready var table_list_vbox : VBoxContainer = %IngredientListVBox
@onready var preview_label : Label = $VBoxContainer/PreviewLabel
@onready var save_recipe_toast : Label = %SaveRecipeToast
@onready var current_recipe_label : Label = %CurrentRecipeLabel
@onready var header_row : HBoxContainer = $VBoxContainer/HeaderRow
@onready var erase_button : Button = %EraseButton
@onready var start_brew_button : Button = %StartBrewButton

var table_labels: Dictionary = {} # ingredient id -> Label
var close_button : Button
var _toast : BannerPresenter


func _ready() -> void:
	_toast = BannerPresenter.new(save_recipe_toast, SAVE_TOAST_FLASH_SECONDS, SAVE_TOAST_HOLD_SECONDS, SAVE_TOAST_FADE_SECONDS, true, false)
	# A scene-defined plain Label: the script swap makes its tooltip wrap.
	current_recipe_label.set_script(TooltipLabel)
	# Hovering the preview shows the beer's numbers (colour, bitterness, alcohol).
	preview_label.mouse_filter = Control.MOUSE_FILTER_PASS
	_initialize_table_nodes()
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)
	BrewerySignals.recipe_saved.connect(_on_recipe_saved)
	BrewerySignals.recipe_save_rejected.connect(_on_recipe_save_rejected)
	erase_button.pressed.connect(_on_erase_button_pressed)
	# At the end of the header row and as tall as the header bars, so it lines up with
	# both halves' titles instead of hanging off the frame's corner above them.
	close_button = WindowCloseButton.create(close_requested.emit, PanelHeader.HEIGHT)
	header_row.add_child(close_button)
	_update_table_list_ui()


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
	preview_label.tooltip_text = BrewPreviewText.details(preview)
	# Nothing would come out yet; the preview says what is missing.
	start_brew_button.disabled = preview == null
	# Every batch needs a keg of its own.
	if not brewery.inventory.has_free_keg():
		preview_label.text = NO_FREE_KEG_TEXT
		start_brew_button.disabled = true
	elif preview != null and not MashTun.holds(preview.malt_weight, brewery.mash_capacity_kg()):
		preview_label.text = tr(MASH_TUN_FULL_FORMAT) % roundi(brewery.mash_capacity_kg())
		start_brew_button.disabled = true
	# A disabled "Pane" says why, the same words as the preview.
	start_brew_button.tooltip_text = preview_label.text if start_brew_button.disabled else START_BREW_TOOLTIP
