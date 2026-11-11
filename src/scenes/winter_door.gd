class_name WinterDoor
extends Node2D

## The door at the top of the stairs in winter (SeasonRules.is_winter_now()). It stays shut
## between visitors; when someone comes in it swings open, lets in a cold light and a gust
## of snow (winter_snow.gdshader), then falls shut again. Hidden outside winter.

const FRAME_SECONDS : float = 0.07
const HOLD_OPEN_SECONDS : float = 1.0
const COLD_LIGHT_ENERGY : float = 0.6
const COLD_LIGHT_FADE_SECONDS : float = 0.4
## Long enough for the last flake to fall from the door to the bottom tread and melt.
const SNOW_SECONDS : float = 11.0
## Snow layers taking turns, so a new gust does not wipe the flakes still melting.
const SNOW_LAYERS : int = 2
const SOUND_BUS : StringName = &"SFX"
const SOUND_VOLUME_DB : float = -6.0

@export var creak : AudioStream
@export var gust : AudioStream

@onready var door : Sprite2D = $Door
@onready var snow : ColorRect = $Snow
@onready var cold_light : PointLight2D = $ColdLight

var _layers : Array[ColorRect] = []
## Per layer, since its gust started: the snow shader's `elapsed`.
var _layer_seconds : Array[float] = []
var _tween : Tween
var _creak_player : AudioStreamPlayer
var _gust_player : AudioStreamPlayer


func _ready() -> void:
	_layers.append(snow)
	for i : int in range(1, SNOW_LAYERS):
		var layer := snow.duplicate() as ColorRect
		layer.material = snow.material.duplicate()
		add_child(layer)
		_layers.append(layer)
	_layer_seconds.resize(SNOW_LAYERS)
	_layer_seconds.fill(SNOW_SECONDS)
	_creak_player = _make_player(creak)
	_gust_player = _make_player(gust)
	BrewerySignals.customer_entered.connect(_on_customer_entered)
	BrewerySignals.winter_forced.connect(_show_for)
	_show_for(SeasonRules.is_winter_now())


func _process(delta : float) -> void:
	var any_falling : bool = false
	for i : int in _layers.size():
		if not _layers[i].visible:
			continue
		_layer_seconds[i] += delta
		(_layers[i].material as ShaderMaterial).set_shader_parameter("elapsed", _layer_seconds[i])
		if _layer_seconds[i] >= SNOW_SECONDS:
			_layers[i].hide()
		else:
			any_falling = true
	set_process(any_falling)


func open() -> void:
	if not visible:
		return
	var open_frames : int = door.hframes - 1
	if door.frame == 0:
		_play(_creak_player)
	_play(_gust_player)
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	for frame : int in range(door.frame + 1, open_frames + 1):
		_tween.tween_property(door, "frame", frame, FRAME_SECONDS)
	_tween.parallel().tween_property(cold_light, "energy", COLD_LIGHT_ENERGY, COLD_LIGHT_FADE_SECONDS)
	_tween.tween_interval(HOLD_OPEN_SECONDS)
	for frame : int in range(open_frames - 1, -1, -1):
		_tween.tween_property(door, "frame", frame, FRAME_SECONDS)
	_tween.parallel().tween_property(cold_light, "energy", 0.0, COLD_LIGHT_FADE_SECONDS)
	_let_snow_in(open_frames * FRAME_SECONDS + HOLD_OPEN_SECONDS)


## Into the layer whose snow is oldest (an idle one is oldest of all).
func _let_snow_in(open_seconds : float) -> void:
	var oldest : int = _layer_seconds.find(_layer_seconds.max())
	var layer_material := _layers[oldest].material as ShaderMaterial
	layer_material.set_shader_parameter("open_seconds", open_seconds)
	layer_material.set_shader_parameter("elapsed", 0.0)
	_layer_seconds[oldest] = 0.0
	_layers[oldest].show()
	set_process(true)


func _on_customer_entered(_position : Vector2) -> void:
	open()


func _show_for(is_winter : bool) -> void:
	visible = is_winter
	if _tween != null:
		_tween.kill()
	door.frame = 0
	cold_light.energy = 0.0
	for layer : ColorRect in _layers:
		layer.hide()
	_layer_seconds.fill(SNOW_SECONDS)
	set_process(false)


func _make_player(stream : AudioStream) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = SOUND_BUS
	player.volume_db = SOUND_VOLUME_DB
	add_child(player)
	return player


func _play(player : AudioStreamPlayer) -> void:
	if player.stream != null:
		player.play()
