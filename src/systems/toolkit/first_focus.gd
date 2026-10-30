class_name FirstFocus
extends RefCounted

## Gives a window's first usable button the keyboard focus each time it opens, so Enter,
## Space and the arrow keys work at once. The focus starts hidden: a mouse player would
## see a button highlighted that they never chose. The theme's frame appears with the
## first keyboard move.
##   FirstFocus.attach(self)
## A button marked with prefer() wins over the first one, e.g. the safe answer of a
## confirmation.

const PREFERRED_META : StringName = &"first_focus_preferred"


static func attach(window : Control) -> void:
	window.visibility_changed.connect(func() -> void:
		if window.visible:
			focus_now.call_deferred(window))


static func prefer(button : Control) -> void:
	button.set_meta(PREFERRED_META, true)


## Deferred by attach(), so buttons the window builds as it opens are there. Leaves a focus
## already inside the window alone.
static func focus_now(window : Control) -> void:
	if not is_instance_valid(window) or not window.is_visible_in_tree():
		return
	var focused : Control = window.get_viewport().gui_get_focus_owner()
	if focused != null and window.is_ancestor_of(focused):
		return
	var target : Control = _find(window, true)
	if target == null:
		target = _find(window, false)
	if target != null:
		target.grab_focus(true)


## Depth first in tree order, which is reading order for the containers windows use.
static func _find(node : Node, preferred_only : bool) -> Control:
	for child : Node in node.get_children():
		var control : Control = child as Control
		if control == null or not control.visible or control.is_queued_for_deletion():
			continue
		if _can_focus(control) and (not preferred_only or control.has_meta(PREFERRED_META)):
			return control
		var found : Control = _find(control, preferred_only)
		if found != null:
			return found
	return null


static func _can_focus(control : Control) -> bool:
	var button : BaseButton = control as BaseButton
	return button != null and not button.disabled and control.focus_mode != Control.FOCUS_NONE
