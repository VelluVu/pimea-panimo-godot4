class_name TouchHints
extends Node

## Touch screens have no hover, so the cellar's clickable spots never show their names.
## On a touch screen the names show for a moment when a run starts and at the start of
## each day, once the cellar is in view (after the day recap closes). Names only: the
## hover glow would read as the finger touching something. A ? button beside the game
## menu button shows them again on demand.

const SHOW_SECONDS : float = 2.5
## Lets a view switch or a closing window settle first.
const DELAY_SECONDS : float = 0.4
const BUTTON_TEXT : String = "?"
const BUTTON_TOOLTIP : String = "Näytä paikkojen nimet"
const BUTTON_FONT_SIZE : int = 32
const BUTTON_GAP : float = 6.0

## Set at run start and each new day; the next time the bar is in view, the hints show.
var _pending : bool = true
var _run_id : int = 0
var _shown : bool = false


func _ready() -> void:
	if not DisplayServer.is_touchscreen_available():
		return
	TimeManager.day_changed.connect(func(_day : int) -> void: _pending = true)
	GUISignals.bar_view_entered.connect(_show_if_pending)
	GUISignals.window_closed.connect(_show_if_pending)


func _show_if_pending() -> void:
	if not _pending:
		return
	_pending = false
	_flash(DELAY_SECONDS)


## Shows the names for a while; a second call while they show hides them.
func toggle() -> void:
	if _shown:
		_run_id += 1
		_set_shown(false)
	else:
		_flash(0.0)


## A ? button the size of `beside`, placed just right of it with the same anchors.
## Added as its sibling so the windows above it still cover it.
static func make_button(beside : Control) -> Button:
	var button := Button.new()
	button.tooltip_text = BUTTON_TOOLTIP
	# A child label, not the button's text: big text would make the button taller than `beside`.
	var mark := Label.new()
	mark.text = BUTTON_TEXT
	mark.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.add_child(mark)
	button.anchor_left = beside.anchor_left
	button.anchor_right = beside.anchor_right
	button.anchor_top = beside.anchor_top
	button.anchor_bottom = beside.anchor_bottom
	button.grow_vertical = beside.grow_vertical
	var width : float = beside.offset_right - beside.offset_left
	button.offset_left = beside.offset_right + BUTTON_GAP
	button.offset_right = button.offset_left + width
	button.offset_top = beside.offset_top
	button.offset_bottom = beside.offset_bottom
	beside.add_sibling(button)
	return button


func _flash(delay : float) -> void:
	_run_id += 1
	var my_run : int = _run_id
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
		if my_run != _run_id:
			return
	_set_shown(true)
	await get_tree().create_timer(SHOW_SECONDS).timeout
	if my_run == _run_id:
		_set_shown(false)


func _set_shown(is_shown : bool) -> void:
	_shown = is_shown
	GUISignals.touch_hints_shown.emit(is_shown)
