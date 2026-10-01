class_name ToastStack
extends RefCounted

## Shows toasts stacked, newest on top, so a burst is never overwritten. Every toast is its
## own copy of the template label, presented by its own BannerPresenter and freed once faded.

const STACK_SEPARATION: int = 2

var _template: Label
var _stack: VBoxContainer
var _flash_seconds: float
var _hold_seconds: float
var _fade_seconds: float

## Longer text stays up longer: hold = hold_seconds + this per character, clamped to
## min/max_hold_seconds. Zero keeps every toast at the same hold_seconds.
var hold_per_character: float = 0.0
var min_hold_seconds: float = 0.0
var max_hold_seconds: float = INF
## At most this many toasts on screen; a new one makes the oldest fade out early. 0 = no cap.
var max_visible: int = 0

var _showing: Array[BannerPresenter] = []


## The template label supplies the look and the stack's screen rect; it is hidden and stays
## as the prototype. Must be in the tree.
func _init(template: Label, flash_seconds: float, hold_seconds: float, fade_seconds: float) -> void:
	_template = template
	_flash_seconds = flash_seconds
	_hold_seconds = hold_seconds
	_fade_seconds = fade_seconds

	var parent: Node = template.get_parent()
	_stack = VBoxContainer.new()
	_stack.name = "ToastStack"
	_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stack.anchor_left = template.anchor_left
	_stack.anchor_right = template.anchor_right
	_stack.offset_top = template.offset_top
	_stack.add_theme_constant_override("separation", STACK_SEPARATION)
	parent.add_child(_stack)
	parent.move_child(_stack, template.get_index())
	template.hide()


func show_toast(text: String) -> void:
	var label: Label = _template.duplicate() as Label
	label.show()
	label.custom_minimum_size.y = _template.offset_bottom - _template.offset_top
	_stack.add_child(label)
	# Newest on top: toasts dismissed early keep their slot while they fade, so a burst
	# appended at the bottom would creep down the screen over other UI.
	_stack.move_child(label, 0)

	_make_room()
	var hold: float = hold_seconds_for(text.length(), _hold_seconds, hold_per_character, min_hold_seconds, max_hold_seconds)
	var presenter := BannerPresenter.new(label, _flash_seconds, hold, _fade_seconds, true, false, false, label.queue_free)
	presenter.present(text)
	_showing.append(presenter)


func _make_room() -> void:
	_showing = _showing.filter(func(presenter: BannerPresenter) -> bool: return presenter.is_running())
	while max_visible > 0 and _showing.size() >= max_visible:
		_showing.pop_front().dismiss_early()


static func hold_seconds_for(text_length: int, base_seconds: float, per_character: float, min_seconds: float, max_seconds: float) -> float:
	return clampf(base_seconds + text_length * per_character, min_seconds, max_seconds)

