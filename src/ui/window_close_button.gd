class_name WindowCloseButton
extends TooltipButton

## The X every closable window has in its top right corner, so closing works the same
## everywhere. Playtesters missed the old text buttons scattered around the windows.
##   WindowCloseButton.attach(self, _on_close_button_pressed)

const CLOSE_TEXT : String = "X"
const CLOSE_TOOLTIP_FORMAT : String = "Sulje (%s)"
## The smallest side; a bigger font or theme padding grows both sides alike.
const MIN_SIDE : float = 18.0
## None: the button's border lies on the window's frame, so it reads as part of the window.
const CORNER_INSET : int = 0


## The smallest side this button was made with; MIN_SIDE unless a header row asks for its
## own height.
var _side : float = MIN_SIDE


## Square whatever the theme's padding, so it reads as an icon rather than a text button.
func _ready() -> void:
	var content : Vector2 = get_minimum_size()
	var side : float = maxf(_side, maxf(content.x, content.y))
	custom_minimum_size = Vector2(side, side)


## A close button calling `on_pressed`, for windows that place it in a container themselves.
## In a row of framed header bars, pass the bars' height as `side` so it lines up with them.
static func create(on_pressed : Callable, side : float = MIN_SIDE) -> WindowCloseButton:
	var button := WindowCloseButton.new()
	button._side = side
	button.text = CLOSE_TEXT
	button.tooltip_text = UiText.of(CLOSE_TOOLTIP_FORMAT) % InputManager.get_binding_text(InputManager.ACTION_CANCEL)
	button.custom_minimum_size = Vector2(side, side)
	# In a row of taller buttons it would otherwise stretch to their height.
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(on_pressed)
	return button


## Pins a close button to the top right corner of `window`, above its other children.
## `clear_row` is a header row with something at its right end (a counter, a button):
## it gets a gap there, so that never sits under the X.
static func attach(window : Control, on_pressed : Callable, clear_row : HBoxContainer = null) -> WindowCloseButton:
	var button : WindowCloseButton = create(on_pressed)
	# Grows left and down from the corner, so a theme that widens it keeps it inside.
	button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	var host : Control = window
	var corner_offset : Vector2 = Vector2.ZERO
	# A PanelContainer would lay the button out like content. A bare overlay keeps it
	# pinned, pushed back out over the panel's content margin into the frame's corner.
	if window is PanelContainer:
		host = Control.new()
		host.mouse_filter = Control.MOUSE_FILTER_IGNORE
		window.add_child(host)
		var style : StyleBox = window.get_theme_stylebox(&"panel")
		corner_offset = Vector2(style.get_margin(SIDE_RIGHT), -style.get_margin(SIDE_TOP))
	host.add_child(button)
	button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, CORNER_INSET)
	button.position += corner_offset
	if clear_row != null:
		var gap := Control.new()
		gap.custom_minimum_size.x = button.custom_minimum_size.x
		gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		clear_row.add_child(gap)
	# Every closable window is one the keyboard should land in when it opens.
	FirstFocus.attach(window)
	return button
