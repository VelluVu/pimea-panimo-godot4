class_name SeasonChip
extends TooltipLabel

## The season's icon in the top bar; its tooltip says what the season brings and how long
## it lasts. Hidden between seasons. The main menu shows the long form under its title.

## A click target, though the glyph is 9 px.
const MIN_SIZE : Vector2 = Vector2(18, 18)
const SPACE : String = " "

## The name and the countdown beside the icon, where there is room for them.
@export var long_form : bool = false

var _data : SeasonData = null


func _ready() -> void:
	custom_minimum_size = MIN_SIZE
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mouse_filter = Control.MOUSE_FILTER_PASS
	# The icon is no word to translate.
	auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	BrewerySignals.season_forced.connect(_refresh.unbind(1))
	BrewerySignals.winter_forced.connect(_refresh.unbind(1))
	TimeManager.day_changed.connect(_refresh.unbind(1))
	_refresh()


## The long form is built from translated parts, so a language switch rebuilds it.
func _notification(what : int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_refresh()


func _refresh() -> void:
	_data = SeasonCatalog.current()
	visible = _data != null
	if _data == null:
		text = ""
	elif long_form:
		var line : String = SeasonText.line(_data, SeasonRules.days_left_now(_data.winter))
		text = line.replace(_data.icon, _icon_gap())
	else:
		text = _icon_gap()
	queue_redraw()


## The theme's text outline fills the gaps of a sparse colour icon with dark patches, so
## the text holds spaces where the icon goes and _draw paints it without an outline.
func _icon_gap() -> String:
	var font : Font = get_theme_font(&"font")
	var font_size : int = get_theme_font_size(&"font_size")
	var icon_width : float = font.get_string_size(_data.icon, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var space_width : float = font.get_string_size(SPACE, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	return SPACE.repeat(maxi(1, ceili(icon_width / space_width)))


func _draw() -> void:
	if _data == null or text.is_empty():
		return
	var gap_start : int = text.find(SPACE)
	var gap : String = _icon_gap()
	var first : Rect2 = get_character_bounds(gap_start)
	var last : Rect2 = get_character_bounds(gap_start + gap.length() - 1)
	var font : Font = get_theme_font(&"font")
	var font_size : int = get_theme_font_size(&"font_size")
	var icon_width : float = font.get_string_size(_data.icon, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var span : float = last.end.x - first.position.x
	var x : float = floorf(first.position.x + (span - icon_width) / 2.0)
	var baseline : float = first.position.y + font.get_ascent(font_size)
	draw_string(font, Vector2(x, baseline), _data.icon, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)


## Built on hover, so the countdown is today's.
func _get_tooltip(_at_position : Vector2) -> String:
	if _data == null:
		return ""
	return SeasonText.tooltip(_data, SeasonRules.days_left_now(_data.winter))
