class_name RomanCandleStar
extends Node2D

## One roman candle star: a 2x2 art-pixel ball as wide as the candle's mouth. It leaves
## white hot, cools to its colour with a white glint on its lit corner as it climbs and
## slows, drags a tapering trail and bursts into a pinwheel of eight sparks at the top.
## Everything sits on whole art pixels from the launch point, and the colours step down a
## ramp instead of fading, so it stays crisp pixel art. A light of its colour goes with it.
## top_level: once fired it stays in the cellar while the customer walks on.

const WHITE_HOT_SECONDS : float = 0.1
const FLIGHT_SECONDS : float = 0.75
const BURST_SECONDS : float = 0.36
const BALL : int = 2
## Earlier positions drawn behind the ball, newest first: [size in art pixels, ramp step].
## A full-width shade, then single pixels, so the trail tapers.
const TRAIL : Array[Vector2i] = [Vector2i(2, 1), Vector2i(1, 1), Vector2i(1, 2)]
const LIGHT_ENERGY : float = 1.1
const BURST_LIGHT_ENERGY : float = 1.8
const LIGHT_SCALE : float = 2.2
const HOT : Color = Color("ffffff")
## The burst grows a pixel each third of its time, up to this reach.
const BURST_REACH : int = 3

## head, shade, darkest.
var _ramp : Array[Color] = []
var _art : float = 4.0
var _rise : int = 20
var _drift : int = 0
var _seconds : float = 0.0
var _trail : Array[Vector2i] = []
var _head : Vector2i = Vector2i.ZERO
var _light : PointLight2D


const GLOW : Texture2D = preload("res://assets/textures/light_glow_32.png")


func launch(at : Vector2, ramp : Array[Color], rise : int, drift : int, art : float, glow : Texture2D = GLOW) -> void:
	top_level = true
	global_position = at
	# A burning star is its own light, not lit by the lamps (like the winter breath puffs).
	var unshaded := CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = unshaded
	_ramp = ramp
	_rise = rise
	_drift = drift
	_art = art
	_light = PointLight2D.new()
	_light.texture = glow
	_light.texture_scale = LIGHT_SCALE
	_light.color = ramp[0]
	_light.energy = LIGHT_ENERGY
	add_child(_light)
	_place_light()


func _process(delta : float) -> void:
	_seconds += delta
	if _seconds >= FLIGHT_SECONDS + BURST_SECONDS:
		queue_free()
		return
	if _seconds < FLIGHT_SECONDS:
		var head : Vector2i = flight_pixel(_seconds / FLIGHT_SECONDS, _rise, _drift)
		if head != _head:
			_trail.push_front(_head)
			_trail.resize(mini(_trail.size(), TRAIL.size()))
			_head = head
	else:
		_trail.clear()
		var burst : float = (_seconds - FLIGHT_SECONDS) / BURST_SECONDS
		_light.energy = lerpf(BURST_LIGHT_ENERGY, 0.0, burst)
	_place_light()
	queue_redraw()


func _draw() -> void:
	if _seconds >= FLIGHT_SECONDS:
		_draw_burst((_seconds - FLIGHT_SECONDS) / BURST_SECONDS)
		return
	# Oldest first, so the newer, brighter steps cover it.
	for index : int in range(_trail.size() - 1, -1, -1):
		var step : Vector2i = TRAIL[index]
		# A single pixel sits under the ball's left column.
		_block(_trail[index] + Vector2i(0, BALL - step.x), step.x, _ramp[step.y])
	if _seconds < WHITE_HOT_SECONDS:
		_block(_head, BALL, HOT)
		return
	_block(_head, BALL, _ramp[0])
	# The glint on the corner facing the cellar lamps (top left).
	_block(_head, 1, HOT)


## The sparks fly out a pixel per third of the burst, stepping down the ramp.
func _draw_burst(progress : float) -> void:
	var reach : int = mini(1 + floori(progress * BURST_REACH), BURST_REACH)
	var color : Color = _ramp[mini(floori(progress * _ramp.size()), _ramp.size() - 1)]
	for spark : Vector2i in burst_sparks(reach):
		_block(_head + spark, 1, color)


func _block(at : Vector2i, size : int, color : Color) -> void:
	draw_rect(Rect2(Vector2(at) * _art, Vector2(size, size) * _art), color)


func _place_light() -> void:
	_light.position = (Vector2(_head) + Vector2(BALL, BALL) * 0.5) * _art


## The burst's sparks `reach` pixels out from the 2x2 ball (its top left at 0,0): four on
## the diagonals, and four straight out a pixel further, each off its own side's column or
## row, so they make an eight-point pinwheel instead of a hollow square.
static func burst_sparks(reach : int) -> Array[Vector2i]:
	var far : int = reach + 1
	return [
		Vector2i(-reach, -reach), Vector2i(BALL - 1 + reach, -reach),
		Vector2i(-reach, BALL - 1 + reach), Vector2i(BALL - 1 + reach, BALL - 1 + reach),
		Vector2i(0, -far), Vector2i(BALL - 1, BALL - 1 + far),
		Vector2i(-far, BALL - 1), Vector2i(BALL - 1 + far, 0),
	]


## The head's art pixel at `t` (0 to 1) of the flight: fast off the candle, slowing near
## the top, drifting a little sideways.
static func flight_pixel(t : float, rise : int, drift : int) -> Vector2i:
	var eased : float = 1.0 - pow(1.0 - clampf(t, 0.0, 1.0), 2.0)
	return Vector2i(roundi(drift * t), -roundi(rise * eased))
