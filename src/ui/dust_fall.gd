class_name DustFall
extends Node2D

## A puff of dust shaken loose from the cellar ceiling: single-pixel grains trickle down
## from one spot, each at its own pace with a pixel or two of drift, and a few 2x2 plaster
## chips drop faster. They step darker as they settle out of sight. Whole pixels at the
## room art's scale (1 world px), so it sits on the background's grid. Unshaded with light
## plaster colours: in the cellar's darkness, grey grains sank among the back wall's specks.
## Frees itself when the last grain is gone.

## Light plaster to stone, ENDESGA 32.
const RAMP : Array[Color] = [Color("ead4aa"), Color("c0cbdc"), Color("8b9bb4")]
const MIN_GRAINS : int = 14
const MAX_GRAINS : int = 24
const CHIP_CHANCE : float = 0.15
const CHIP_SIZE : int = 2
const CHIP_SPEED_MULTIPLIER : float = 1.8
const SPREAD_PX : int = 6
const MIN_SPEED : float = 22.0
const MAX_SPEED : float = 55.0
const MIN_FALL_PX : float = 40.0
const MAX_FALL_PX : float = 130.0
const MAX_DRIFT_PX : int = 2
## The grains leave one after another over this long, so it trickles.
const MAX_DELAY_SECONDS : float = 0.8

## Per grain: x offset, delay, speed, fall distance, drift and size.
var _x : Array[int] = []
var _delay : Array[float] = []
var _speed : Array[float] = []
var _fall : Array[float] = []
var _drift : Array[int] = []
var _size : Array[int] = []
var _seconds : float = 0.0


func _ready() -> void:
	var unshaded := CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = unshaded
	for i : int in randi_range(MIN_GRAINS, MAX_GRAINS):
		var chip : bool = randf() < CHIP_CHANCE
		_x.append(randi_range(-SPREAD_PX, SPREAD_PX))
		_delay.append(randf_range(0.0, MAX_DELAY_SECONDS))
		_speed.append(randf_range(MIN_SPEED, MAX_SPEED) * (CHIP_SPEED_MULTIPLIER if chip else 1.0))
		_fall.append(randf_range(MIN_FALL_PX, MAX_FALL_PX))
		_drift.append(randi_range(-MAX_DRIFT_PX, MAX_DRIFT_PX))
		_size.append(CHIP_SIZE if chip else 1)


func _process(delta : float) -> void:
	_seconds += delta
	queue_redraw()
	for i : int in _x.size():
		if _seconds < _delay[i] + _fall[i] / _speed[i]:
			return
	queue_free()


func _draw() -> void:
	for i : int in _x.size():
		var fallen : float = (_seconds - _delay[i]) * _speed[i]
		if fallen < 0.0 or fallen >= _fall[i]:
			continue
		var share : float = fallen / _fall[i]
		var at := Vector2(_x[i] + roundi(_drift[i] * share), roundi(fallen))
		draw_rect(Rect2(at, Vector2(_size[i], _size[i])), RAMP[mini(floori(share * RAMP.size()), RAMP.size() - 1)])
