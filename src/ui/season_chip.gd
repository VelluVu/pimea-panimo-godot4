class_name SeasonChip
extends TooltipLabel

## The season's icon in the top bar; its tooltip says what the season brings and how long
## it lasts. Hidden between seasons. The main menu shows the long form under its title.

## A click target, though the glyph is 9 px.
const MIN_SIZE : Vector2 = Vector2(18, 18)

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
		text = SeasonText.line(_data, SeasonRules.days_left_now(_data.winter))
	else:
		text = _data.icon


## Built on hover, so the countdown is today's.
func _get_tooltip(_at_position : Vector2) -> String:
	if _data == null:
		return ""
	return SeasonText.tooltip(_data, SeasonRules.days_left_now(_data.winter))
