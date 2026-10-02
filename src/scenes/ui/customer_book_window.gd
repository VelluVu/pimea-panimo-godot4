class_name CustomerBookWindow
extends Panel

## The Asiakaskirja: every customer type unlocked in any run, with the tastes of the
## ones served at least once. Opened from the notebook on the counter
## (GUISignals.customer_book_requested).

const TITLE_TEXT : String = "Asiakaskirja"
const CLOSE_TEXT : String = "Sulje"
const REGULAR_TAG : String = "  (kanta-asiakas)"
const NAME_FONT_SIZE : int = 15
const DETAIL_FONT_SIZE : int = 12
const PORTRAIT_SIZE : Vector2 = Vector2(64, 64)
const PORTRAIT_ANIMATION : StringName = &"idle"
## Not-met customers show as a dark silhouette.
const UNMET_PORTRAIT_COLOR : Color = Color(0.05, 0.05, 0.08, 0.85)
const REGULAR_COLOR : Color = Color(0.949, 0.788, 0.42, 1)
const MUTED_COLOR : Color = Color(0.75, 0.73, 0.67, 1)

@onready var title_label : Label = %TitleLabel
@onready var close_button : Button = %CloseButton
@onready var rows_vbox : VBoxContainer = %RowsVBox


func _ready() -> void:
	title_label.text = TITLE_TEXT
	close_button.text = CLOSE_TEXT
	close_button.pressed.connect(_on_close_button_pressed)
	GUISignals.customer_book_requested.connect(_on_customer_book_requested)


func _on_customer_book_requested() -> void:
	_refresh_rows()
	show()


func _on_close_button_pressed() -> void:
	GUISignals.window_closed.emit()
	hide()


func _refresh_rows() -> void:
	for child : Node in rows_vbox.get_children():
		child.queue_free()

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
	var title : Label = _make_label(tr(customer.title) + (tr(REGULAR_TAG) if _is_regular(customer) else ""), NAME_FONT_SIZE)
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
		names[beer_style.style] = beer_style.style_name
	return names


func _make_label(text : String, font_size : int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	return label
