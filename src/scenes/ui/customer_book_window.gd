class_name CustomerBookWindow
extends Panel

## The Panimokirja, opened from the notebook on the counter
## (GUISignals.customer_book_requested). Three tabs: every customer type unlocked in any
## run with the tastes of the ones served; every ingredient with price and stats; and the
## Ohjeet, a short guide to the game (GuideSection resources). The reference that touch
## screens, without hover tooltips, need most.

const TITLE_TEXT : String = "Panimokirja"
const CLOSE_TEXT : String = "Sulje"
const CUSTOMERS_TAB_TEXT : String = "Asiakkaat"
const INGREDIENTS_TAB_TEXT : String = "Ainekset"
const GUIDE_TAB_TEXT : String = "Ohjeet"
const GUIDE_FOLDER_PATH : String = "res://src/resources/guide/"
const REGULAR_TAG : String = "(kanta-asiakas)"
const NAME_FONT_SIZE : int = 16
const DETAIL_FONT_SIZE : int = 14
const TAB_HEIGHT : float = 26.0
const HEADER_COLOR : Color = Color(0.949, 0.788, 0.42, 1)

enum Tab { CUSTOMERS, INGREDIENTS, GUIDE }
const PORTRAIT_SIZE : Vector2 = Vector2(64, 64)
const PORTRAIT_ANIMATION : StringName = &"idle"
## Not-met customers show as a dark silhouette.
const UNMET_PORTRAIT_COLOR : Color = Color(0.05, 0.05, 0.08, 0.85)
const REGULAR_COLOR : Color = Color(0.949, 0.788, 0.42, 1)
const MUTED_COLOR : Color = Color(0.75, 0.73, 0.67, 1)

@onready var title_label : Label = %TitleLabel
@onready var close_button : Button = %CloseButton
@onready var rows_vbox : VBoxContainer = %RowsVBox
@onready var scroll_container : ScrollContainer = $MarginContainer/MainVBox/ScrollContainer

var _tab_bar : TabBar
var _guide_sections : Array[GuideSection] = []


func _ready() -> void:
	title_label.text = TITLE_TEXT
	close_button.text = CLOSE_TEXT
	close_button.pressed.connect(_on_close_button_pressed)
	GUISignals.customer_book_requested.connect(_on_customer_book_requested)
	process_mode = Node.PROCESS_MODE_ALWAYS
	PauseLock.hold_while_visible(self)

	_guide_sections.assign(ResourceFolder.load_all(GUIDE_FOLDER_PATH, GuideSection))
	_guide_sections.sort_custom(func(a : GuideSection, b : GuideSection) -> bool: return a.order < b.order)

	_tab_bar = TabBar.new()
	_tab_bar.custom_minimum_size.y = TAB_HEIGHT
	for tab_text : String in [CUSTOMERS_TAB_TEXT, INGREDIENTS_TAB_TEXT, GUIDE_TAB_TEXT]:
		_tab_bar.add_tab(tab_text)
	var main_vbox : Node = scroll_container.get_parent()
	main_vbox.add_child(_tab_bar)
	main_vbox.move_child(_tab_bar, scroll_container.get_index())
	_tab_bar.tab_changed.connect(func(_tab : int) -> void:
		GUISignals.tab_switched.emit()
		_refresh_rows())


## The paused tree no longer reaches gui.gd's Esc handler, so this closes itself.
func _input(event : InputEvent) -> void:
	if visible and event.is_action_pressed(InputManager.ACTION_CANCEL):
		_on_close_button_pressed()
		get_viewport().set_input_as_handled()


func _on_customer_book_requested() -> void:
	# Tapping the spot that opened it closes it again.
	if visible:
		_on_close_button_pressed()
		return
	_refresh_rows()
	show()


func _on_close_button_pressed() -> void:
	GUISignals.window_closed.emit()
	hide()


func _refresh_rows() -> void:
	for child : Node in rows_vbox.get_children():
		child.queue_free()
	scroll_container.scroll_vertical = 0

	match _tab_bar.current_tab:
		Tab.INGREDIENTS:
			_build_ingredient_rows()
		Tab.GUIDE:
			_build_guide_rows()
		_:
			_build_customer_rows()


func _build_ingredient_rows() -> void:
	var brewery : Brewery = BrewEngine.current_brewery
	var reputation : int = brewery.reputation if brewery != null else 0
	var price_multiplier : float = brewery.stats.multiplier(PerkStats.INGREDIENT_PRICE) if brewery != null else 1.0
	var last_type : int = -1
	for id : int in IngredientDatabase.display_ids():
		var ingredient : IngredientData = IngredientDatabase.get_item_by_id(id)
		if ingredient.type != last_type:
			last_type = ingredient.type
			rows_vbox.add_child(_make_header(IngredientBookText.type_header(ingredient.type)))
		var name_label : Label = _make_label(tr(ingredient.name), NAME_FONT_SIZE)
		name_label.add_theme_color_override("font_color", ingredient.get_color())
		rows_vbox.add_child(name_label)
		var lines : PackedStringArray = IngredientBookText.lines(ingredient, ingredient.base_price * price_multiplier, reputation)
		rows_vbox.add_child(_make_label("\n".join(lines), DETAIL_FONT_SIZE))


func _build_guide_rows() -> void:
	for section : GuideSection in _guide_sections:
		rows_vbox.add_child(_make_header(tr(section.title)))
		for line : String in section.lines:
			rows_vbox.add_child(_make_label(tr(line), DETAIL_FONT_SIZE))


func _make_header(text : String) -> Label:
	var header : Label = _make_label(text, NAME_FONT_SIZE)
	header.add_theme_color_override("font_color", HEADER_COLOR)
	return header


func _build_customer_rows() -> void:
	var announced : Array = CustomerRegistry.get_announced_titles()
	var met : Array = CustomerRegistry.get_met_titles()
	var customers : Array[CustomerData] = CustomerBookText.unique_by_title(CustomerRegistry.customer_pool)
	customers.sort_custom(func(a : CustomerData, b : CustomerData) -> bool: return a.min_reputation_to_appear < b.min_reputation_to_appear)

	var style_names : Dictionary = _style_names()
	var locked_count : int = 0
	for customer : CustomerData in customers:
		if not announced.has(customer.title) and not met.has(customer.title):
			locked_count += 1
			continue
		rows_vbox.add_child(_build_row(customer, met.has(customer.title), style_names))

	var locked_text : String = CustomerBookText.locked_line(locked_count)
	if not locked_text.is_empty():
		var locked_label : Label = _make_label(locked_text, DETAIL_FONT_SIZE)
		locked_label.add_theme_color_override("font_color", MUTED_COLOR)
		rows_vbox.add_child(locked_label)


func _build_row(customer : CustomerData, met : bool, style_names : Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_make_portrait(customer, met))

	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_theme_constant_override("separation", 0)
	var title : Label = _make_label(tr(customer.title) + ("  " + tr(REGULAR_TAG) if _is_regular(customer) else ""), NAME_FONT_SIZE)
	if _is_regular(customer):
		title.add_theme_color_override("font_color", REGULAR_COLOR)
	texts.add_child(title)
	var details : Label = _make_label("\n".join(CustomerBookText.lines(customer, met, style_names)), DETAIL_FONT_SIZE)
	if not met:
		details.add_theme_color_override("font_color", MUTED_COLOR)
	texts.add_child(details)
	row.add_child(texts)
	return row


func _make_portrait(customer : CustomerData, met : bool) -> TextureRect:
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = PORTRAIT_SIZE
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if customer.sprite_frames != null and customer.sprite_frames.has_animation(PORTRAIT_ANIMATION):
		portrait.texture = customer.sprite_frames.get_frame_texture(PORTRAIT_ANIMATION, 0)
	if not met:
		portrait.modulate = UNMET_PORTRAIT_COLOR
	return portrait


func _is_regular(customer : CustomerData) -> bool:
	var brewery : Brewery = BrewEngine.current_brewery
	return brewery != null and RegularRules.is_regular(brewery.customer_standing.get(customer.title, 0))


func _style_names() -> Dictionary:
	var names : Dictionary = {}
	var brewery : Brewery = BrewEngine.current_brewery
	if brewery == null:
		return names
	for beer_style : BeerStyle in brewery.resolver.active_styles:
		names[beer_style.style] = tr(beer_style.style_name)
	return names


func _make_label(text : String, font_size : int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	return label
