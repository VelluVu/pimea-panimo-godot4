class_name RecipeLibraryWindow
extends Panel

## The recipe book: a list of styles (known ones open their saved recipes, locked ones
## only hint) and, per known style, its saved recipes with a button to load each.

const NO_RECIPES_FOR_STYLE_STRING : String = "Ei tallennettuja reseptejä tälle tyylille."
const RECIPE_ROW_LOAD_BUTTON_TEXT : String = "Lataa"
const BACK_BUTTON_TEXT : String = "< Takaisin"

const NO_STYLE_SELECTED : int = -1
const ROW_FONT_SIZE : int = 14
const RECIPE_BORDER_WIDTH : int = 2
const RECIPE_CORNER_RADIUS : int = 4
const RECIPE_BREWABLE_BORDER_COLOR : Color = Color(0.3, 0.85, 0.35)
const RECIPE_MISSING_BORDER_COLOR : Color = Color(0.5, 0.5, 0.5)

@onready var title_label : Label = $MarginContainer/MainVBox/HeaderHBox/TitleLabel
@onready var close_button : Button = $MarginContainer/MainVBox/HeaderHBox/CloseButton
@onready var back_button : Button = $MarginContainer/MainVBox/HeaderHBox/BackButton
@onready var rows_vbox : VBoxContainer = $MarginContainer/MainVBox/ScrollContainer/RowsVBox

var selected_style : int = NO_STYLE_SELECTED


func _ready() -> void:
	title_label.text = StringContainer.RECIPE_LIBRARY_TITLE
	close_button.text = StringContainer.RECIPE_LIBRARY_CLOSE_TEXT
	back_button.text = BACK_BUTTON_TEXT

	close_button.pressed.connect(hide)
	back_button.pressed.connect(_select_style.bind(NO_STYLE_SELECTED))
	GUISignals.recipe_library_requested.connect(_on_recipe_library_requested)
	BrewerySignals.brewery_state_changed.connect(_on_state_changed)
	BrewerySignals.style_discovered.connect(_on_state_changed)


func _on_recipe_library_requested() -> void:
	selected_style = NO_STYLE_SELECTED
	_refresh_rows()
	show()


## Bound to two signals with different arguments, so it takes none of them.
func _on_state_changed(_ignored : Variant = null) -> void:
	if visible:
		_refresh_rows()


func _select_style(style : int) -> void:
	selected_style = style
	_refresh_rows()


func _on_recipe_load_button_pressed(recipe : BrewRecipe) -> void:
	GUISignals.load_recipe_requested.emit(recipe)
	selected_style = NO_STYLE_SELECTED
	hide()


func _refresh_rows() -> void:
	for child : Node in rows_vbox.get_children():
		child.queue_free()

	var brewery : Brewery = BrewEngine.current_brewery
	if brewery == null:
		return

	back_button.visible = selected_style != NO_STYLE_SELECTED
	if selected_style == NO_STYLE_SELECTED:
		_build_style_list_rows(brewery)
	else:
		_build_recipe_detail_rows(brewery)


func _build_style_list_rows(brewery : Brewery) -> void:
	for beer_style : BeerStyle in brewery.resolver.active_styles:
		if brewery.is_style_known(beer_style.style):
			rows_vbox.add_child(_build_known_style_row(beer_style))
		else:
			rows_vbox.add_child(_build_locked_style_row(brewery, beer_style))


func _build_known_style_row(beer_style : BeerStyle) -> Button:
	var row := Button.new()
	row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_theme_font_size_override("font_size", ROW_FONT_SIZE)
	row.alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.text = RecipeLibraryText.known_row(beer_style, _ingredient_name(beer_style.required_yeast_id), _required_malt_name(beer_style))
	row.pressed.connect(_select_style.bind(beer_style.style))
	return row


func _build_locked_style_row(brewery : Brewery, beer_style : BeerStyle) -> Label:
	var needs_malt_blend : bool = beer_style.required_malt_id == BrewMixture.NO_REQUIRED_MALT and brewery.resolver.style_needs_malt_blend(beer_style)
	var row := Label.new()
	row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_theme_font_size_override("font_size", ROW_FONT_SIZE)
	row.text = RecipeLibraryText.locked_row(beer_style, _ingredient_name(beer_style.required_yeast_id), _required_malt_name(beer_style), needs_malt_blend)
	row.modulate = Color.DIM_GRAY
	return row


func _build_recipe_detail_rows(brewery : Brewery) -> void:
	var recipes : Array[BrewRecipe] = []
	for recipe : BrewRecipe in brewery.saved_recipes:
		if recipe.beer_style == selected_style:
			recipes.append(recipe)

	if recipes.is_empty():
		var empty_label := Label.new()
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.text = NO_RECIPES_FOR_STYLE_STRING
		rows_vbox.add_child(empty_label)
		return

	for recipe : BrewRecipe in recipes:
		rows_vbox.add_child(_build_recipe_row(recipe, recipe.is_covered_by(brewery.inventory)))


## The border is green when the inventory covers the recipe, grey when something is missing.
func _build_recipe_row(recipe : BrewRecipe, brewable : bool) -> Control:
	var border := StyleBoxFlat.new()
	border.bg_color = Color(0, 0, 0, 0)
	border.set_border_width_all(RECIPE_BORDER_WIDTH)
	border.set_corner_radius_all(RECIPE_CORNER_RADIUS)
	border.border_color = RECIPE_BREWABLE_BORDER_COLOR if brewable else RECIPE_MISSING_BORDER_COLOR

	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", border)
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


## Empty for a style with no single required malt, which the row text ignores.
func _required_malt_name(beer_style : BeerStyle) -> String:
	if beer_style.required_malt_id == BrewMixture.NO_REQUIRED_MALT:
		return ""
	return _ingredient_name(beer_style.required_malt_id)


func _ingredient_name(ingredient_id : int) -> String:
	var ingredient : IngredientData = IngredientDatabase.get_item_by_id(ingredient_id)
	return ingredient.name if ingredient != null else StringContainer.TUNTEMATON
