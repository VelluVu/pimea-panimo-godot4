class_name Storm
extends Node2D

## A Halloween storm outside the top of the stairs: the door's daylight turns to cold
## moonlight, and now and then lightning flashes through the door and thunder follows,
## at once when it is near, after a pause when it is far. Checks the season itself,
## since HalloweenDecor only hides its children and a hidden node still plays sounds.

const NIGHT_COLOR : Color = Color(0.55, 0.62, 0.9)
## Dims the door lamp to moonlight through LightFlicker.boost.
const NIGHT_BOOST : float = 0.45
const FLASH_ENERGY : float = 3.0
## Two bright strokes with a dim gap, the way lightning flickers.
const FLASH_STROKE_SECONDS : float = 0.05
const FLASH_GAP_SECONDS : float = 0.07
const FLASH_GAP_ENERGY : float = 0.4
const FLASH_SECOND_ENERGY : float = 2.2
const FLASH_FADE_SECONDS : float = 0.35
const MIN_INTERVAL_SECONDS : float = 20.0
const MAX_INTERVAL_SECONDS : float = 50.0
const FIRST_STRIKE_SECONDS : Vector2 = Vector2(5.0, 12.0)
const NEAR_CHANCE : float = 0.4
const NEAR_THUNDER_DELAY : Vector2 = Vector2(0.1, 0.4)
const FAR_THUNDER_DELAY : Vector2 = Vector2(0.8, 1.8)
const SOUND_BUS : StringName = &"SFX"
const SOUND_VOLUME_DB : float = -3.0

@export_node_path("LightFlicker") var door_lamp_path : NodePath
@export var near_thunder : AudioStream
@export var far_thunder : AudioStream

@onready var flash : PointLight2D = $Flash

var _timer : Timer
var _player : AudioStreamPlayer
var _flash_tween : Tween


func _ready() -> void:
	flash.energy = 0.0
	if not HalloweenRules.is_season(Time.get_date_dict_from_system()):
		return
	var door_lamp := get_node(door_lamp_path) as LightFlicker
	door_lamp.color = NIGHT_COLOR
	door_lamp.boost = NIGHT_BOOST
	_player = AudioStreamPlayer.new()
	_player.bus = SOUND_BUS
	_player.volume_db = SOUND_VOLUME_DB
	add_child(_player)
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)
	_timer.start(randf_range(FIRST_STRIKE_SECONDS.x, FIRST_STRIKE_SECONDS.y))


func strike() -> void:
	var near : bool = randf() < NEAR_CHANCE
	_flash()
	var delay : Vector2 = NEAR_THUNDER_DELAY if near else FAR_THUNDER_DELAY
	get_tree().create_timer(randf_range(delay.x, delay.y)).timeout.connect(_rumble.bind(near))


func _on_timer_timeout() -> void:
	strike()
	_timer.start(randf_range(MIN_INTERVAL_SECONDS, MAX_INTERVAL_SECONDS))


func _flash() -> void:
	if _flash_tween != null:
		_flash_tween.kill()
	flash.energy = FLASH_ENERGY
	_flash_tween = create_tween()
	_flash_tween.tween_interval(FLASH_STROKE_SECONDS)
	_flash_tween.tween_callback(func() -> void: flash.energy = FLASH_GAP_ENERGY)
	_flash_tween.tween_interval(FLASH_GAP_SECONDS)
	_flash_tween.tween_callback(func() -> void: flash.energy = FLASH_SECOND_ENERGY)
	_flash_tween.tween_property(flash, "energy", 0.0, FLASH_FADE_SECONDS)


func _rumble(near : bool) -> void:
	if _player == null:
		return
	_player.stream = near_thunder if near else far_thunder
	_player.play()
