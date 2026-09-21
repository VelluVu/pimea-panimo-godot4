class_name ToastStack
extends RefCounted

## Shows toasts stacked under each other so a burst is never overwritten. Every toast is its
## own copy of the template label, presented by its own BannerPresenter and freed once faded.

const STACK_SEPARATION: int = 2

var _template: Label
var _stack: VBoxContainer
var _flash_seconds: float
var _hold_seconds: float
var _fade_seconds: float


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

	var presenter := BannerPresenter.new(label, _flash_seconds, _hold_seconds, _fade_seconds, true, false, false, label.queue_free)
	presenter.present(text)

