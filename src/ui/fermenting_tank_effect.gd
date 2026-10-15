class_name FermentingTankEffect
extends Node2D

## Bubbles on the back room's middle unitank while a brew ferments: they rise from the
## airlock on top and inside the sight glass. Drawn pixel by pixel and stepped at a low
## frame rate, like the rest of the pixel art. Sits under the tank's Sprite2D, in its
## centred coordinates.

## Ten steps a second, like the brew day's shaders.
const STEP_SECONDS : float = 0.1
## The airlock on top of the tank: bubbles rise this far above it.
const AIRLOCK_TOP : Vector2i = Vector2i(-6, -42)
const AIRLOCK_RISE : int = 7
const AIRLOCK_BUBBLES : int = 3
## The sight glass: bubbles rise from its bottom to its top inside these columns.
const GLASS_COLUMNS : Array[int] = [-8, -6, -4]
const GLASS_BOTTOM : int = 10
const GLASS_TOP : int = 3
const FOAM_COLOR : Color = Color("ffffff")
const GLASS_BUBBLE_COLOR : Color = Color("fee761")
## The tank sprite's light mask, so the room's lights brighten the bubbles too.
const TANK_LIGHT_MASK : int = 3

var _step : int = 0
var _elapsed : float = 0.0


func _ready() -> void:
	light_mask = TANK_LIGHT_MASK
	BrewerySignals.fermentation_started.connect(_on_fermentation_changed.unbind(1))
	BrewerySignals.batch_fermented.connect(_on_fermentation_changed.unbind(1))
	BrewerySignals.brewery_state_changed.connect(_on_fermentation_changed.unbind(1))
	_on_fermentation_changed()


func _process(delta : float) -> void:
	_elapsed += delta
	if _elapsed < STEP_SECONDS:
		return
	_elapsed = fmod(_elapsed, STEP_SECONDS)
	_step += 1
	queue_redraw()


func _on_fermentation_changed() -> void:
	var brewery : Brewery = BrewEngine.current_brewery
	visible = brewery != null and not brewery.inventory.fermenting.is_empty()
	set_process(visible)


func _draw() -> void:
	for i : int in AIRLOCK_BUBBLES:
		var rise : int = (_step + i * 3) % (AIRLOCK_RISE + 2)
		if rise <= AIRLOCK_RISE:
			_dot(AIRLOCK_TOP + Vector2i((i % 2), -rise), FOAM_COLOR)
	var glass_height : int = GLASS_BOTTOM - GLASS_TOP
	for i : int in GLASS_COLUMNS.size():
		var rise : int = (_step + i * 4) % (glass_height + 1)
		_dot(Vector2i(GLASS_COLUMNS[i], GLASS_BOTTOM - rise), GLASS_BUBBLE_COLOR)


func _dot(at : Vector2i, color : Color) -> void:
	draw_rect(Rect2(Vector2(at), Vector2.ONE), color)
