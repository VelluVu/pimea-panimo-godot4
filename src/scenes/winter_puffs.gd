class_name WinterPuffs
extends Node2D

## Draws the winter arrival bits (see WinterArrival): snow shaken off a customer's head and
## shoulders and stamped off their boots, which falls or hops out, lands around the feet and
## melts, and a puff of breath that drifts up and fades. Each bit is a square snapped to the customers' art pixel grid (their sprites are
## drawn at 4x). Unshaded, so the cellar's darkness does not turn the breath grey.

const SNOW_COLOR : Color = Color(0.78, 0.84, 0.9)
const BREATH_COLOR : Color = Color(0.85, 0.9, 0.95, 0.6)
const BIT_PX : float = 4.0
const SNOW_BITS_PER_STOMP : int = 3
## Snow shaken off the shoulders tumbles a little sideways as it drops.
const SHAKEN_DRIFT : Vector2 = Vector2(18.0, 15.0)
const SNOW_SPREAD_PX : float = 20.0
const SNOW_HOP_SPEED : Vector2 = Vector2(30.0, 45.0)
const SNOW_GRAVITY : float = 260.0
## How far in front of the feet a bit can land, so they scatter over the floor.
const SNOW_LAND_DEPTH_PX : float = 8.0
const SNOW_SECONDS : float = 1.8
const BREATH_BITS : int = 8
const BREATH_SPEED : Vector2 = Vector2(30.0, 16.0)
const BREATH_SECONDS : float = 1.1
## Breath bits grow to this many times BIT_PX as they spread.
const BREATH_GROWTH : float = 2.0

var _positions : PackedVector2Array = []
var _velocities : PackedVector2Array = []
var _ages : PackedFloat32Array = []
## A snow bit's landing row; INF for breath, which floats.
var _floors : PackedFloat32Array = []


func _ready() -> void:
	BrewerySignals.snow_stamped_off.connect(_on_snow_stamped_off)
	BrewerySignals.breath_puffed.connect(_on_breath_puffed)
	BrewerySignals.snow_shaken_off.connect(_on_snow_shaken_off)
	set_process(false)


func _process(delta : float) -> void:
	for i in range(_ages.size() - 1, -1, -1):
		_ages[i] += delta
		var is_snow : bool = _floors[i] != INF
		if _ages[i] >= (SNOW_SECONDS if is_snow else BREATH_SECONDS):
			_remove(i)
			continue
		var velocity : Vector2 = _velocities[i]
		if is_snow:
			velocity.y += SNOW_GRAVITY * delta
		var at : Vector2 = _positions[i] + velocity * delta
		if is_snow and at.y >= _floors[i]:
			at.y = _floors[i]
			velocity = Vector2.ZERO
		_positions[i] = at
		_velocities[i] = velocity
	queue_redraw()
	set_process(not _ages.is_empty())


func _draw() -> void:
	for i in _ages.size():
		var is_snow : bool = _floors[i] != INF
		var life : float = _ages[i] / (SNOW_SECONDS if is_snow else BREATH_SECONDS)
		var color : Color = SNOW_COLOR if is_snow else BREATH_COLOR
		# Snow melts away at the end; breath thins out the whole time.
		color.a *= 1.0 - (maxf(0.0, life - 0.5) * 2.0 if is_snow else life)
		var size : float = BIT_PX if is_snow else BIT_PX * round(lerpf(1.0, BREATH_GROWTH, life))
		var corner : Vector2 = (to_local(_positions[i]) / BIT_PX).floor() * BIT_PX
		draw_rect(Rect2(corner, Vector2(size, size)), color)


func _on_snow_stamped_off(feet : Vector2) -> void:
	for i in SNOW_BITS_PER_STOMP:
		var start : Vector2 = feet + Vector2(randf_range(-SNOW_SPREAD_PX, SNOW_SPREAD_PX), -BIT_PX)
		var hop : Vector2 = Vector2(randf_range(-SNOW_HOP_SPEED.x, SNOW_HOP_SPEED.x), -randf_range(0.5, 1.0) * SNOW_HOP_SPEED.y)
		_add(start, hop, feet.y + randf_range(0.0, SNOW_LAND_DEPTH_PX))


func _on_snow_shaken_off(spots : PackedVector2Array, floor_y : float) -> void:
	for spot in spots:
		var drift : Vector2 = Vector2(randf_range(-SHAKEN_DRIFT.x, SHAKEN_DRIFT.x), -randf_range(0.0, SHAKEN_DRIFT.y))
		_add(spot, drift, floor_y + randf_range(0.0, SNOW_LAND_DEPTH_PX))


func _on_breath_puffed(mouth : Vector2) -> void:
	var side : float = 1.0 if randf() < 0.5 else -1.0
	for i in BREATH_BITS:
		var drift : Vector2 = Vector2(side * randf_range(0.3, 1.0) * BREATH_SPEED.x, -randf_range(0.4, 1.0) * BREATH_SPEED.y)
		_add(mouth + Vector2(randf_range(-BIT_PX, BIT_PX), randf_range(-BIT_PX, BIT_PX)), drift, INF)


func _add(at : Vector2, velocity : Vector2, floor_y : float) -> void:
	_positions.append(at)
	_velocities.append(velocity)
	_ages.append(0.0)
	_floors.append(floor_y)
	set_process(true)


func _remove(index : int) -> void:
	_positions.remove_at(index)
	_velocities.remove_at(index)
	_ages.remove_at(index)
	_floors.remove_at(index)
