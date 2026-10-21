class_name LightFlicker
extends PointLight2D

## A lamp that breathes a little, like a bulb on an old cellar wire.
## Smooth noise keeps the wobble organic; rare dips read as a loose contact.

## A fluorescent tube blinks this many times before it stays on.
const STARTER_BLINKS : int = 2
const STARTER_ON_SECONDS : float = 0.05
const STARTER_OFF_SECONDS : float = 0.08

@export_range(0.0, 0.5) var flicker_amount: float = 0.06
@export_range(0.1, 10.0) var flicker_speed: float = 1.5
@export_range(0.0, 1.0) var dip_chance_per_second: float = 0.0
@export_range(0.0, 1.0) var dip_depth: float = 0.45

## 0 switches the lamp off, see DayLights.
var dimmer: float = 1.0

var _base_energy: float
var _noise: FastNoiseLite = FastNoiseLite.new()
var _time: float = 0.0
var _dip: float = 1.0
## The lamp's own switch (set_switched_on), apart from the night's dimmer.
var _switched_on: bool = true
var _switch_level: float = 1.0
var _switch_tween: Tween


func _ready() -> void:
	# Pausing windows (level-up) open over the cellar; its lamps keep living and switching.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_base_energy = energy
	_noise.seed = randi()
	_noise.frequency = 1.0
	_noise.fractal_octaves = 2


func _process(delta: float) -> void:
	_time += delta * flicker_speed
	if randf() < dip_chance_per_second * delta:
		_dip_once()
	energy = _base_energy * dimmer * _switch_level * _dip * (1.0 + _noise.get_noise_1d(_time) * flicker_amount)


## Off at once; on with `starter` blinks first, like a fluorescent tube's starter.
func set_switched_on(on: bool, starter: bool = false) -> void:
	if on == _switched_on:
		return
	_switched_on = on
	if _switch_tween != null:
		_switch_tween.kill()
	if not on or not starter:
		_switch_level = 1.0 if on else 0.0
		return
	_switch_tween = create_tween()
	for i: int in STARTER_BLINKS:
		_switch_tween.tween_callback(func() -> void: _switch_level = 1.0)
		_switch_tween.tween_interval(STARTER_ON_SECONDS)
		_switch_tween.tween_callback(func() -> void: _switch_level = 0.0)
		_switch_tween.tween_interval(STARTER_OFF_SECONDS)
	_switch_tween.tween_callback(func() -> void: _switch_level = 1.0)


func _dip_once() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "_dip", 1.0 - dip_depth, 0.04)
	tween.tween_property(self, "_dip", 1.0, 0.04)
	tween.tween_property(self, "_dip", 1.0 - dip_depth * 0.6, 0.05)
	tween.tween_property(self, "_dip", 1.0, 0.15)
