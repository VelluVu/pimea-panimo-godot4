class_name RecipeLibraryWindow
extends Panel


const NO_RECIPES_FOR_STYLE_STRING : String = "Ei tallennettuja reseptejä tälle tyylille."
const RECIPE_ROW_LOAD_BUTTON_TEXT : String = "Lataa"
const BACK_BUTTON_TEXT : String = "< Takaisin"
const RECIPE_BREWABLE_BORDER_COLOR : Color = Color(0.3, 0.85, 0.35)
const RECIPE_MISSING_BORDER_COLOR : Color = Color(0.5, 0.5, 0.5)

@onready var title_label : Label = $MarginContainer/MainVBox/HeaderHBox/TitleLabel
@onready var close_button : Button = $MarginContainer/MainVBox/HeaderHBox/CloseButton
@onready var back_button : Button = $MarginContainer/MainVBox/HeaderHBox/BackButton
@onready var rows_vbox : VBoxContainer = $MarginContainer/MainVBox/ScrollContainer/RowsVBox

var selected_style : int = -1


func _ready() -> void:
	title_label.text = StringContainer.RECIPE_LIBRARY_TITLE
	close_button.text = StringContainer.RECIPE_LIBRARY_CLOSE_TEXT
	back_button.text = BACK_BUTTON_TEXT

	close_button.pressed.connect(_on_close_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	GUISignals.recipe_library_requested.connect(_on_recipe_library_requested)
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)
	BrewerySignals.style_discovered.connect(_on_style_discovered)


func _on_recipe_library_requested() -> void:
	selected_style = -1
	_refresh_rows()
	show()


func _on_close_button_pressed() -> void:
	hide()


func _on_back_button_pressed() -> void:
	selected_style = -1
	_refresh_rows()


func _on_brewery_state_changed(_brewery : Brewery) -> void:
	if visible:
		_refresh_rows()


func _on_style_discovered(_style : int) -> void:
	if visible:
		_refresh_rows()


func _refresh_rows() -> void:
	for child in rows_vbox.get_children():
		child.queue_free()

	if BrewEngine.current_brewery == null:
		return

	back_button.visible = selected_style != -1

	if selected_style == -1:
		_build_style_list_rows()
	else:
		_build_recipe_detail_rows()


func _build_style_list_rows() -> void:
	var brewery : Brewery = BrewEngine.current_brewery

	for beer_style : BeerStyle in brewery.resolver.active_styles:
		if brewery.is_style_known(beer_style.style):
			var row_button := Button.new()
			row_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			row_button.add_theme_font_size_override("font_size", 14)
			row_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			row_button.text = StringContainer.RECIPE_LIBRARY_ROW_STRING % [
				beer_style.style_name,
				beer_style.min_ebc,
				beer_style.max_ebc,
				beer_style.min_ibu,
				beer_style.max_ibu,
				_get_yeast_name(beer_style.required_yeast_id)
			]

			if beer_style.preferred_hop_profile != HopData.FlavorProfile.NONE:
				row_button.text += StringContainer.RECIPE_LIBRARY_HOP_HINT_STRING % HopData.get_flavor_profile_display_name(beer_style.preferred_hop_profile)

			row_button.pressed.connect(_on_style_row_pressed.bind(beer_style.style))
			rows_vbox.add_child(row_button)
		else:
			var row_label := Label.new()
			row_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			row_label.add_theme_font_size_override("font_size", 14)
			row_label.text = StringContainer.RECIPE_LIBRARY_LOCKED_STRING % _get_yeast_name(beer_style.required_yeast_id)
			row_label.modulate = Color.DIM_GRAY
			rows_vbox.add_child(row_label)


func _on_style_row_pressed(style : BeerStyle.Style) -> void:
	selected_style = style
	_refresh_rows()


func _build_recipe_detail_rows() -> void:
	var brewery : Brewery = BrewEngine.current_brewery

	var recipes_for_style : Array[BrewRecipe] = []
	for recipe : BrewRecipe in brewery.saved_recipes:
		if recipe.beer_style == selected_style:
			recipes_for_style.append(recipe)

	if recipes_for_style.is_empty():
		var empty_label := Label.new()
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.text = NO_RECIPES_FOR_STYLE_STRING
		rows_vbox.add_child(empty_label)
		return

	for recipe : BrewRecipe in recipes_for_style:
		rows_vbox.add_child(_build_recipe_row(recipe))


func _build_recipe_row(recipe : BrewRecipe) -> Control:
	var row := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0, 0, 0, 0)
	box.set_border_width_all(2)
	box.border_color = RECIPE_BREWABLE_BORDER_COLOR if _recipe_is_brewable(recipe) else RECIPE_MISSING_BORDER_COLOR
	box.set_corner_radius_all(4)
	row.add_theme_stylebox_override("panel", box)

	var row_hbox := HBoxContainer.new()
	row.add_child(row_hbox)

	var name_label := Label.new()
	name_label.text = recipe.recipe_name
	name_label.size_flags_horizontal = SIZE_EXPAND_FILL
	row_hbox.add_child(name_label)

	var load_button := Button.new()
	load_button.text = RECIPE_ROW_LOAD_BUTTON_TEXT
	load_button.pressed.connect(_on_recipe_load_button_pressed.bind(recipe))
	row_hbox.add_child(load_button)

	return row


func _on_recipe_load_button_pressed(recipe : BrewRecipe) -> void:
	GUISignals.load_recipe_requested.emit(recipe)
	selected_style = -1
	hide()


func _recipe_is_brewable(recipe : BrewRecipe) -> bool:
	var brewery : Brewery = BrewEngine.current_brewery
	if brewery == null:
		return false

	for ingredient_id : int in recipe.ingredient_amounts:
		var needed : int = recipe.ingredient_amounts[ingredient_id]
		var item : InventoryItem = brewery.inventory.get_item_by_id(ingredient_id)
		var owned : int = item.amount if item else 0

		if owned < needed:
			return false

	return true


func _get_yeast_name(yeast_id : int) -> String:
	var yeast : IngredientData = IngredientDatabase.get_item_by_id(yeast_id)

	if yeast == null:
		return StringContainer.TUNTEMATON

	return yeast.name
