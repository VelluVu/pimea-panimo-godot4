class_name ScreenBleed
extends Node

## Lets a Control inside a WideStage stage reach the real screen edges (offsets_for()): a
## top bar spans the screen's width at its top, a corner button sits in the screen's corner,
## a dimmer covers it all.

var _target : Control
var _base_offsets : Vector4


## Adds the watcher as a child of `control`, so it goes when the control does.
static func attach(control : Control) -> void:
	var bleed := ScreenBleed.new()
	bleed.name = &"ScreenBleed"
	control.add_child(bleed)


func _ready() -> void:
	_target = get_parent() as Control
	_base_offsets = Vector4(_target.offset_left, _target.offset_top, _target.offset_right, _target.offset_bottom)
	get_viewport().size_changed.connect(_apply)
	_apply()


func _apply() -> void:
	var visible : Vector2 = get_viewport().get_visible_rect().size
	var shift : Vector4 = offsets_for(Vector4(_target.anchor_left, _target.anchor_top, _target.anchor_right, _target.anchor_bottom),
			WideStage.origin_for(visible, WideStage.base_size()), WideStage.far_extra_for(visible, WideStage.base_size()))
	_target.offset_left = _base_offsets.x + shift.x
	_target.offset_top = _base_offsets.y + shift.y
	_target.offset_right = _base_offsets.z + shift.z
	_target.offset_bottom = _base_offsets.w + shift.w


## What to add to each offset (left, top, right, bottom) for anchors (left, top, right,
## bottom), given how far the screen reaches past the stage on each side. Per axis: a
## control spanning the stage stretches to both screen edges; one pinned to the start or the
## end (its near anchor at 0, or its far anchor at 1) moves whole with that edge, keeping
## its size (a top bar stays a bar); one in between stays.
static func offsets_for(anchors : Vector4, near : Vector2i, far : Vector2i) -> Vector4:
	var horizontal : Vector2 = _axis_shift(anchors.x, anchors.z, near.x, far.x)
	var vertical : Vector2 = _axis_shift(anchors.y, anchors.w, near.y, far.y)
	return Vector4(horizontal.x, vertical.x, horizontal.y, vertical.y)


static func _axis_shift(start_anchor : float, end_anchor : float, near : int, far : int) -> Vector2:
	var at_start : bool = is_zero_approx(start_anchor)
	var at_end : bool = is_equal_approx(end_anchor, 1.0)
	if at_start and at_end:
		return Vector2(-near, far)
	if at_start:
		return Vector2(-near, -near)
	if at_end:
		return Vector2(far, far)
	return Vector2.ZERO
