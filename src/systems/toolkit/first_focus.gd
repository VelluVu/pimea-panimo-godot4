class_name FirstFocus
extends RefCounted

## Gives a window's first usable control the keyboard focus each time it opens, so Enter,
## Space and the arrow keys work at once, and keeps the arrow keys inside the top open
## window. The focus starts hidden: a mouse player would see a button highlighted that they
## never chose. FocusReveal shows the frame on the first keyboard press and fades it later.
##   FirstFocus.attach(self)
## A button marked with prefer() wins over the first one, e.g. the safe answer of a
## confirmation.

const PREFERRED_META : StringName = &"first_focus_preferred"
## The last control focused inside a window, to return to when the window above it closes.
const LAST_FOCUS_META : StringName = &"first_focus_last"

## Open windows, the most recent last; the top one holds the keyboard.
static var _open : Array[Control] = []
static var _top_window : Control = null
## Controls beside the top window whose focus is switched off, -> their own setting.
## Godot picks an arrow key's target from the whole screen, often a menu button behind
## the window, so everything beside it is taken out of the search while it is on top.
static var _shut : Dictionary = {}


static func attach(window : Control) -> void:
	window.visibility_changed.connect(func() -> void:
		_open.erase(window)
		# The stack first: a window opening may still be shut by the one it covers.
		_update_top.call_deferred()
		if window.is_visible_in_tree():
			_open.append(window)
			_watch(window.get_viewport())
			focus_now.call_deferred(window))
	window.tree_exiting.connect(func() -> void:
		_open.erase(window)
		_update_top.call_deferred())
	# A window already open when attached, such as a main menu, opens no more.
	if window.is_inside_tree() and window.is_visible_in_tree():
		_open.append(window)
		_watch(window.get_viewport())
		_update_top.call_deferred()


static func prefer(button : Control) -> void:
	button.set_meta(PREFERRED_META, true)


## Deferred by attach(), so controls the window builds as it opens are there. Leaves a focus
## already inside the window alone, and drops one left behind it when the window has
## nothing to focus, so Enter cannot press a hidden button.
static func focus_now(window : Control, hidden : bool = true) -> void:
	if not is_instance_valid(window) or not window.is_visible_in_tree():
		return
	_follow_focus(window)
	var focused : Control = window.get_viewport().gui_get_focus_owner()
	if focused != null and window.is_ancestor_of(focused):
		return
	var target : Control = _find(window, true)
	if target == null:
		target = _find(window, false)
	if target != null:
		target.grab_focus(hidden)
	elif focused != null:
		focused.release_focus()


## A scroll list scrolls to the focused row; without it the arrow keys stop at the last
## row in sight and jump to the button under the list.
static func _follow_focus(node : Node) -> void:
	for child : Node in node.get_children():
		if child is ScrollContainer:
			(child as ScrollContainer).follow_focus = true
		_follow_focus(child)


static func _watch(viewport : Viewport) -> void:
	if viewport.gui_focus_changed.is_connected(_remember):
		return
	viewport.gui_focus_changed.connect(_remember)
	var reveal := FocusReveal.new()
	reveal.name = &"FocusReveal"
	reveal.top_window = func() -> Control: return _top_window if is_instance_valid(_top_window) else null
	# Deferred: the first window attaches while the tree is still building.
	viewport.add_child.call_deferred(reveal)


static func _remember(node : Control) -> void:
	if is_instance_valid(_top_window) and _top_window.is_ancestor_of(node):
		_top_window.set_meta(LAST_FOCUS_META, node)


static func _update_top() -> void:
	_open = _open.filter(func(window : Control) -> bool: return is_instance_valid(window) and window.is_visible_in_tree())
	var top : Control = _open.back() if not _open.is_empty() else null
	if top == _top_window:
		return
	_reopen_shut()
	_top_window = top
	if top == null:
		return
	_shut_beside(top)
	_give_back_focus(top)


## Up from the window to the last Control above it, every sibling on the way.
static func _shut_beside(window : Control) -> void:
	var node : Control = window
	while node.get_parent() is Control:
		for sibling : Node in node.get_parent().get_children():
			var control : Control = sibling as Control
			if control == null or control == node or control.focus_behavior_recursive == Control.FOCUS_BEHAVIOR_DISABLED:
				continue
			_shut[control] = control.focus_behavior_recursive
			control.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
		node = node.get_parent()


static func _reopen_shut() -> void:
	for control : Variant in _shut:
		if is_instance_valid(control):
			(control as Control).focus_behavior_recursive = _shut[control]
	_shut.clear()


## When the window above closes, the keyboard returns where it was in this one.
static func _give_back_focus(window : Control) -> void:
	var focused : Control = window.get_viewport().gui_get_focus_owner()
	if focused != null and window.is_ancestor_of(focused):
		return
	# get_meta() with a null default still errors on a missing key.
	var last : Control = window.get_meta(LAST_FOCUS_META) if window.has_meta(LAST_FOCUS_META) else null
	if is_instance_valid(last) and last.is_visible_in_tree() and window.is_ancestor_of(last):
		last.grab_focus(true)
	else:
		focus_now(window)


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


## Any control the keyboard can land on, sliders and lists too, or a settings page would
## start on its first toggle below the sliders. Containers are skipped: one with a focus
## mode would land the focus on an invisible box.
static func _can_focus(control : Control) -> bool:
	if control.focus_mode != Control.FOCUS_ALL or control is Container:
		return false
	var button : BaseButton = control as BaseButton
	return button == null or not button.disabled
