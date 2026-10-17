class_name RecipeLibraryWindow
extends Panel

## The recipe book: an index of every style (locked ones as "???") and a page per style,
## with its recipe and saved recipes, or hints if locked; text from RecipeLibraryText.
## Pauses the game, so it runs while paused and handles its own Esc.

const BACK_BUTTON_TEXT : String = "< Takaisin"
const LOAD_BUTTON_TEXT : String = "Lataa resepti"
const MISSING_INGREDIENTS_FORMAT : String = "%s (raaka-aineita puuttuu)"

const NO_STYLE_SELECTED : int = -1
## m5x7 is pixel-crisp only at multiples of 16; any other size smears on a phone.
const TEXT_FONT_SIZE : int = 16
const SECTION_COLOR : Color = Color(0.949, 0.788, 0.42)
## Muted against the known styles but still readable on the dark panel.
const LOCKED_COLOR : Color = Color(0.72, 0.66, 0.55)
const INDEX_COLUMNS : int = 2
const SWATCH_SIZE : int = 8

@onready var title_label : Label = %TitleLabel
@onready var close_button : Button = %CloseButton
@onready var back_button : Button = %BackButton
@onready var load_button : Button = %LoadButton
@onready var bottom_bar : HBoxContainer = %BottomHBox
@onready var rows_vbox : VBoxContainer = %RowsVBox

var selected_style : int = NO_STYLE_SELECTED
var _selected_recipe : BrewRecipe = null
## Swatch textures by colour, so reopening the book reuses them.
static var _swatches : Dictionary = {}


func _ready() -> void:
	close_button.text = StringContainer.RECIPE_LIBRARY_CLOSE_TEXT
	back_button.text = BACK_BUTTON_TEXT
	load_button.text = LOAD_BUTTON_TEXT

	close_button.pressed.connect(_on_close_button_pressed)
	back_button.pressed.connect(_select_style.bind(NO_STYLE_SELECTED))
	load_button.pressed.connect(_on_load_button_pressed)
	GUISignals.recipe_library_requested.connect(_on_recipe_library_requested)
	BrewerySignals.brewery_state_changed.connect(_on_state_changed)
	BrewerySignals.style_discovered.connect(_on_state_changed)
	process_mode = Node.PROCESS_MODE_ALWAYS
	PauseLock.hold_while_visible(self)


## The paused tree no longer reaches gui.gd's key handlers, so this closes itself.
func _input(event : InputEvent) -> void:
	if visible and event.is_action_pressed(InputManager.ACTION_TOGGLE_RECIPE_LIBRARY):
		_on_close_button_pressed()
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed(InputManager.ACTION_CANCEL):
		if selected_style != NO_STYLE_SELECTED:
			_select_style(NO_STYLE_SELECTED)
		else:
			_on_close_button_pressed()
		get_viewport().set_input_as_handled()


func _on_recipe_library_requested() -> void:
	# Tapping the spot that opened it closes it again.
	if visible:
		_on_close_button_pressed()
		return
	_select_style(NO_STYLE_SELECTED)
	show()


## Bound to two signals with different arguments, so it takes none of them.
func _on_state_changed(_ignored : Variant = null) -> void:
	if visible:
		_refresh()


func _select_style(style : int) -> void:
	selected_style = style
	_selected_recipe = null
	_refresh()


func _on_close_button_pressed() -> void:
	GUISignals.window_closed.emit()
	hide()


func _on_load_button_pressed() -> void:
	if _selected_recipe == null:
		return
	GUISignals.load_recipe_requested.emit(_selected_recipe)
	selected_style = NO_STYLE_SELECTED
	hide()


func _refresh() -> void:
	for child : Node in rows_vbox.get_children():
		child.queue_free()

	var brewery : Brewery = BrewEngine.current_brewery
	if brewery == null:
		return

	var on_page : bool = selected_style != NO_STYLE_SELECTED
	bottom_bar.visible = on_page
	if on_page:
		_build_page(brewery, brewery.resolver.get_beer_style(selected_style as BeerStyle.Style))
	else:
		title_label.text = StringContainer.RECIPE_LIBRARY_TITLE
		_build_index(brewery)


## Known styles first by name, then the locked ones from mild to strong.
func _build_index(brewery : Brewery) -> void:
	var known : Array[BeerStyle] = []
	var locked : Array[BeerStyle] = []
	for beer_style : BeerStyle in brewery.resolver.active_styles:
		if brewery.is_style_known(beer_style.style):
			known.append(beer_style)
		else:
			locked.append(beer_style)
	known.sort_custom(func(a : BeerStyle, b : BeerStyle) -> bool: return UiText.of(a.style_name) < UiText.of(b.style_name))
	locked.sort_custom(func(a : BeerStyle, b : BeerStyle) -> bool: return a.abv < b.abv)

	rows_vbox.add_child(_section_label(RecipeLibraryText.known_section_title(known.size(), known.size() + locked.size())))
	rows_vbox.add_child(_index_grid(brewery, known))
	if locked.is_empty():
		return
	rows_vbox.add_child(_section_label(RecipeLibraryText.locked_section_title(locked.size())))
	rows_vbox.add_child(_index_grid(brewery, locked))


func _index_grid(brewery : Brewery, styles : Array[BeerStyle]) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = INDEX_COLUMNS
	for beer_style : BeerStyle in styles:
		var entry : RecipeBookEntry = _entry(brewery, beer_style)
		var button := Button.new()
		button.text = RecipeLibraryText.index_label(entry)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		button.icon = _swatch(BeerColor.from_ebc(roundi((beer_style.min_ebc + mini(beer_style.max_ebc, RecipeLibraryText.NO_UPPER_LIMIT)) / 2.0)))
		button.add_theme_font_size_override("font_size", TEXT_FONT_SIZE)
		if not entry.known:
			button.add_theme_color_override("font_color", LOCKED_COLOR)
		button.pressed.connect(_select_style.bind(beer_style.style))
		grid.add_child(button)
	return grid


func _build_page(brewery : Brewery, beer_style : BeerStyle) -> void:
	var entry : RecipeBookEntry = _entry(brewery, beer_style)
	title_label.text = RecipeLibraryText.page_title(entry)
	var lines : PackedStringArray = RecipeLibraryText.known_lines(entry) if entry.known else RecipeLibraryText.locked_lines(entry)
	for line : String in lines:
		rows_vbox.add_child(_text_label(line, Color.WHITE if entry.known else LOCKED_COLOR))
	load_button.disabled = true
	if entry.known:
		_build_saved_recipes(brewery, beer_style)


## The style's saved recipes as a pick list; "Lataa resepti" loads the picked one.
func _build_saved_recipes(brewery : Brewery, beer_style : BeerStyle) -> void:
	rows_vbox.add_child(_section_label(RecipeLibraryText.SAVED_RECIPES_HEADER))
	var recipes : Array[BrewRecipe] = []
	for recipe : BrewRecipe in brewery.saved_recipes:
		if recipe.beer_style == beer_style.style:
			recipes.append(recipe)
	if recipes.is_empty():
		rows_vbox.add_child(_text_label(RecipeLibraryText.NO_SAVED_RECIPES, LOCKED_COLOR))
		return
	var group := ButtonGroup.new()
	for recipe : BrewRecipe in recipes:
		var button := Button.new()
		button.toggle_mode = true
		button.button_group = group
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", TEXT_FONT_SIZE)
		var recipe_name : String = RecipeNameText.display(recipe)
		button.text = recipe_name if recipe.is_covered_by(brewery.inventory) else tr(MISSING_INGREDIENTS_FORMAT) % recipe_name
		button.toggled.connect(_on_recipe_toggled.bind(recipe))
		rows_vbox.add_child(button)
	# A single recipe is picked already, so loading it is one tap.
	if recipes.size() == 1:
		(rows_vbox.get_child(rows_vbox.get_child_count() - 1) as Button).button_pressed = true


func _on_recipe_toggled(pressed : bool, recipe : BrewRecipe) -> void:
	if pressed:
		_selected_recipe = recipe
	elif _selected_recipe == recipe:
		_selected_recipe = null
	load_button.disabled = _selected_recipe == null


func _entry(brewery : Brewery, beer_style : BeerStyle) -> RecipeBookEntry:
	var entry := RecipeBookEntry.new()
	entry.beer_style = beer_style
	entry.known = brewery.is_style_known(beer_style.style)
	entry.yeast_name = _ingredient_name(beer_style.required_yeast_id)
	for id : int in beer_style.base_malt_ids:
		entry.base_malt_names.append(_ingredient_name(id))
	if beer_style.required_malt_id != BrewMixture.NO_REQUIRED_MALT:
		entry.required_malt_name = _ingredient_name(beer_style.required_malt_id)
	for spice_id : int in beer_style.required_spice_ids:
		entry.required_spice_names.append(_ingredient_name(spice_id))
	for malt_id : int in beer_style.preferred_malt_ids:
		entry.character_malt_names.append(_ingredient_name(malt_id))
	for spice_id : int in beer_style.preferred_spice_ids:
		entry.preferred_spice_names.append(_ingredient_name(spice_id))
	entry.saved_recipe_count = brewery.saved_recipes.filter(func(recipe : BrewRecipe) -> bool: return recipe.beer_style == beer_style.style).size()
	entry.needs_mash_upgrade = not MashTun.holds(brewery.resolver.reference_malt_weight(beer_style), brewery.mash_capacity_kg())
	if not entry.known:
		entry.needs_malt_blend = beer_style.required_malt_id == BrewMixture.NO_REQUIRED_MALT and brewery.resolver.style_needs_malt_blend(beer_style)
		entry.attracts_new_customer = not MetaProgressManager.has_style(beer_style.style) and CustomerRegistry.is_style_customer_gate(beer_style.style)
		entry.hinted = brewery.hinted_styles.has(beer_style.style)
	return entry


func _section_label(text : String) -> Label:
	var label := _text_label(text, SECTION_COLOR)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	return label


func _text_label(text : String, color : Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", TEXT_FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	return label


static func _swatch(color : Color) -> Texture2D:
	if not _swatches.has(color):
		var image := Image.create(SWATCH_SIZE, SWATCH_SIZE, false, Image.FORMAT_RGBA8)
		image.fill(color)
		_swatches[color] = ImageTexture.create_from_image(image)
	return _swatches[color]


func _ingredient_name(ingredient_id : int) -> String:
	var ingredient : IngredientData = IngredientDatabase.get_item_by_id(ingredient_id)
	return tr(ingredient.name if ingredient != null else StringContainer.TUNTEMATON)
