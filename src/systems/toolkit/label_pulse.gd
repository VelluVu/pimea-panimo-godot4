class_name LabelPulse
extends RefCounted

## A looping grow-and-shrink pulse on one label, switched on and off by set_active().

const PULSE_SCALE : Vector2 = Vector2(1.15, 1.15)
const PULSE_SECONDS : float = 0.6
const PIVOT_CENTER : Vector2 = Vector2(0.5, 0.5)
const PIVOT_RIGHT : Vector2 = Vector2(1.0, 0.5)

var _label : Label
## Where the label grows from, as a fraction of its size. A label flush to a
## screen edge pivots on that edge, so the pulse never leaves the screen.
var _pivot : Vector2
var _tween : Tween = null


func _init(label : Label, pivot : Vector2 = PIVOT_CENTER) -> void:
	_label = label
	_pivot = pivot


func set_active(active : bool) -> void:
	if active:
		_start()
	else:
		_stop()


func _start() -> void:
	if _tween != null:
		return
	_label.pivot_offset = _label.size * _pivot
	_tween = _label.create_tween().set_loops()
	_tween.tween_property(_label, "scale", PULSE_SCALE, PULSE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(_label, "scale", Vector2.ONE, PULSE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _stop() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null
	_label.scale = Vector2.ONE
