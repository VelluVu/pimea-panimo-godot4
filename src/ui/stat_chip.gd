class_name StatChip
extends PanelContainer

## One stat in the top bar: a 9 px icon and its value on a sunken plate, with an optional
## thin meter under the value. The whole plate carries the tooltip, so hovering the icon
## explains it too. Built in code; the scene sets only the exports.

## Frames of assets/textures/ui/top_bar_icons.png, in make_top_bar_icons.py's order.
enum TopBarIcon { COIN, STAR, SIREN_OFF, SIREN_ON, MUG, CALENDAR }

const ICON_SHEET : Texture2D = preload("res://assets/textures/ui/top_bar_icons.png")
const ICON_SIZE : int = 9
const ICON_GAP : int = 3
const METER_HEIGHT : int = 2
## Plates sit inside the 34 px bar's frame (y 6 to 27) with a pixel to spare.
const PLATE_HEIGHT : int = 20
const THEME_VARIATION : StringName = &"StatChip"

enum Meter { NONE, BEER, RISK }

@export var icon : TopBarIcon = TopBarIcon.COIN
@export var meter : Meter = Meter.NONE
## Room for the widest value it shows, so the plate keeps its width while a number
## changes; 0 lets it follow the text.
@export var value_min_width : int = 0
@export var value_color : Color = Color(0, 0, 0, 0)

## Called on hover; while set it wins over tooltip_text and updates live.
var tooltip_source : Callable

var _icon_rect : TextureRect
var _icon_atlas : AtlasTexture
var _value_label : Label
var _meter_bar : ProgressBar


func _init() -> void:
	theme_type_variation = THEME_VARIATION
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	custom_minimum_size.y = PLATE_HEIGHT
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", ICON_GAP)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)

	_icon_atlas = AtlasTexture.new()
	_icon_atlas.atlas = ICON_SHEET
	_icon_rect = TextureRect.new()
	_icon_rect.texture = _icon_atlas
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	_icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_icon_rect)
	set_icon(icon)

	var column := VBoxContainer.new()
	# A pixel between the value and its meter, so the meter never reads as an underline.
	column.add_theme_constant_override(&"separation", 1)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(column)

	_value_label = Label.new()
	_value_label.custom_minimum_size.x = value_min_width
	_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Values arrive translated and formatted.
	_value_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	column.add_child(_value_label)
	set_value_color(value_color)

	if meter != Meter.NONE:
		_meter_bar = ProgressBar.new()
		_meter_bar.theme_type_variation = &"RiskMeter" if meter == Meter.RISK else &"ChipMeter"
		_meter_bar.custom_minimum_size.y = METER_HEIGHT
		_meter_bar.max_value = 1.0
		_meter_bar.show_percentage = false
		_meter_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(_meter_bar)


## The label that shows the value, for popups floating off it.
func value_label() -> Label:
	return _value_label


func set_value(text : String) -> void:
	_value_label.text = text


## A transparent colour returns to the theme's text colour.
func set_value_color(color : Color) -> void:
	if color.a == 0.0:
		_value_label.remove_theme_color_override(&"font_color")
	else:
		_value_label.add_theme_color_override(&"font_color", color)


func set_icon(which : TopBarIcon) -> void:
	icon = which
	if _icon_atlas != null:
		_icon_atlas.region = Rect2(0, ICON_SIZE * which, ICON_SIZE, ICON_SIZE)


## 0 to 1 of the meter; ignored on a chip without one.
func set_meter(fraction : float) -> void:
	if _meter_bar != null:
		_meter_bar.value = clampf(fraction, 0.0, 1.0)


func meter_value() -> float:
	return _meter_bar.value if _meter_bar != null else 0.0


func _get_tooltip(_at_position : Vector2) -> String:
	return LiveTooltipLabel.LIVE_TOOLTIP_KEY if tooltip_source.is_valid() else tooltip_text


func _make_custom_tooltip(for_text : String) -> Object:
	if tooltip_source.is_valid():
		return TooltipFactory.make_live_tooltip(tooltip_source)
	return TooltipFactory.make_wrapped_tooltip(for_text)
