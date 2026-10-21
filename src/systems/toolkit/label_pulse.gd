class_name LabelPulse
extends RefCounted

## A looping brighten-and-dim pulse on one label, switched on and off by set_active().
## Brightness, not scale: a pixel font scaled off whole sizes blurs.

const PULSE_COLOR : Color = Color(1.7, 1.7, 1.7)
const PULSE_SECONDS : float = 0.6

var _label : Label
var _tween : Tween = null


func _init(label : Label) -> void:
	_label = label


func set_active(active : bool) -> void:
	if active:
		_start()
	else:
		_stop()


func _start() -> void:
	if _tween != null:
		return
	_tween = _label.create_tween().set_loops()
	_tween.tween_property(_label, "modulate", PULSE_COLOR, PULSE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(_label, "modulate", Color.WHITE, PULSE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _stop() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null
	_label.modulate = Color.WHITE
