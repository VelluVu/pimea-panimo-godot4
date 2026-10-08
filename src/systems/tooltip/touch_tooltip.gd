class_name TouchTooltip
extends CanvasLayer

## Tooltips for touch screens, which have no hover: pressing and holding a Control shows its
## tooltip above the finger, and the next tap closes it. Add one to each scene's UI root.
## Only reacts to mouse events emulated from touch, so mouse players see no change.

## Above every window and the level-up cards.
const LAYER: int = 120
## Gap between the finger and the tooltip's bottom edge.
const FINGER_GAP: float = 14.0
const SCREEN_MARGIN: float = 4.0

var _hold := TouchHold.new()
var _shown: Control = null


func _ready() -> void:
	layer = LAYER
	# Tooltips also open over paused windows.
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	if event.device != InputEvent.DEVICE_ID_EMULATION:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_close()
			_hold.press(event.position)
		else:
			_hold.release()
	elif event is InputEventMouseMotion:
		_hold.move(event.position)


func _process(delta: float) -> void:
	if _hold.tick(delta):
		_open_at(get_viewport().get_mouse_position())


func _open_at(finger: Vector2) -> void:
	var control: Control = get_viewport().gui_get_hovered_control()
	while control != null:
		var text: String = control.get_tooltip(control.get_local_mouse_position())
		if not text.is_empty():
			_show(_make_content(control, text), _theme_of(control), finger)
			_drag_finger_off_the_button()
			return
		control = control.get_parent() as Control


func _make_content(control: Control, text: String) -> Control:
	var content: Control = null
	if control.has_method("_make_custom_tooltip"):
		content = control.call("_make_custom_tooltip", text) as Control
	return content if content != null else TooltipFactory.make_wrapped_tooltip(text)


## A held button would fire on release. Buttons judge that from the last mouse motion,
## so a motion far outside tells it the finger slid off.
func _drag_finger_off_the_button() -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(-10000.0, -10000.0)
	motion.global_position = motion.position
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	get_viewport().push_input(motion, true)


## This layer sits outside the UI's own theme, so the tooltip borrows it.
func _theme_of(control: Control) -> Theme:
	var node: Node = control
	while node != null:
		if node is Control and (node as Control).theme != null:
			return (node as Control).theme
		node = node.get_parent()
	return null


func _show(content: Control, theme: Theme, finger: Vector2) -> void:
	_shown = content
	content.theme = theme
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)
	content.reset_size()
	var screen: Vector2 = get_viewport().get_visible_rect().size
	var size: Vector2 = content.get_combined_minimum_size()
	var position := Vector2(finger.x - size.x / 2.0, finger.y - FINGER_GAP - size.y)
	if position.y < SCREEN_MARGIN:
		position.y = finger.y + FINGER_GAP
	position.x = clampf(position.x, SCREEN_MARGIN, screen.x - size.x - SCREEN_MARGIN)
	position.y = clampf(position.y, SCREEN_MARGIN, screen.y - size.y - SCREEN_MARGIN)
	content.position = position


func _close() -> void:
	if is_instance_valid(_shown):
		_shown.queue_free()
	_shown = null
