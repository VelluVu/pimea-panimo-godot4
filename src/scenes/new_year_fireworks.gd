class_name NewYearFireworks
extends Node2D

## New Year outside the cellar. Now and then a rocket whistles and bangs, muffled by the
## walls; a near one shakes the cellar (ScreenShake through BrewerySignals.cellar_shaken,
## so the screen shake setting holds) and knocks dust off the ceiling. When the door opens
## for a customer, the fireworks outside flash in through it in colour and sound unmuffled.
## Checks the season itself like Storm, and follows the console's seasonal command.

const FIRST_ROCKET_SECONDS : Vector2 = Vector2(4.0, 10.0)
const ROCKET_INTERVAL_SECONDS : Vector2 = Vector2(8.0, 22.0)
const NEAR_CHANCE : float = 0.35
## When the boom lands in each sound (rocket_far / rocket_near in make_sfx.py).
const FAR_BOOM_SECONDS : float = 1.1
const NEAR_BOOM_SECONDS : float = 0.6
const FAR_TRAUMA : float = 0.12
const NEAR_TRAUMA : float = 0.3
const FAR_DUST_CHANCE : float = 0.3
const NEAR_DUST_SPOTS : Vector2i = Vector2i(1, 3)
## The door's fireworks: a few bursts of coloured light, each fading.
const DOOR_BURSTS : Vector2i = Vector2i(2, 3)
const DOOR_BURST_PAUSE_SECONDS : float = 0.08
const DOOR_FLASH_ENERGY : float = 2.4
const DOOR_FLASH_FADE_SECONDS : float = 0.3
const FLASH_COLORS : Array[Color] = [Color("fee761"), Color("e43b44"), Color("2ce8f5"), Color("63c74d"), Color("f6757a")]
const DUST_Z_INDEX : int = 5
const SOUND_BUS : StringName = &"SFX"
const FAR_VOLUME_DB : float = -8.0
const NEAR_VOLUME_DB : float = -4.0
const DOOR_VOLUME_DB : float = -6.0

@export var far_rocket : AudioStream
@export var near_rocket : AudioStream
@export var door_fireworks : AudioStream
## The ceiling line dust falls from, in this node's space.
@export var ceiling_y : float = 58.0
@export var ceiling_left : float = 110.0
@export var ceiling_right : float = 560.0

@onready var door_flash : PointLight2D = $DoorFlash

var _timer : Timer
var _rocket_player : AudioStreamPlayer
var _door_player : AudioStreamPlayer
var _flash_tween : Tween
var _active : bool = false


func _ready() -> void:
	door_flash.energy = 0.0
	_rocket_player = _make_player()
	_door_player = _make_player()
	_door_player.stream = door_fireworks
	_door_player.volume_db = DOOR_VOLUME_DB
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)
	BrewerySignals.customer_entered.connect(_on_customer_entered.unbind(1))
	BrewerySignals.season_forced.connect(_set_season)
	_set_season(SeasonRules.now())


func _set_season(season : SeasonRules.Season) -> void:
	_active = season == SeasonRules.Season.NEW_YEAR
	if _active:
		_timer.start(randf_range(FIRST_ROCKET_SECONDS.x, FIRST_ROCKET_SECONDS.y))
	else:
		_timer.stop()


func _on_timer_timeout() -> void:
	launch(randf() < NEAR_CHANCE)
	_timer.start(randf_range(ROCKET_INTERVAL_SECONDS.x, ROCKET_INTERVAL_SECONDS.y))


## One rocket; the console and tests can fire one at will.
func launch(near : bool) -> void:
	_rocket_player.stream = near_rocket if near else far_rocket
	_rocket_player.volume_db = NEAR_VOLUME_DB if near else FAR_VOLUME_DB
	_rocket_player.play()
	var boom : float = NEAR_BOOM_SECONDS if near else FAR_BOOM_SECONDS
	get_tree().create_timer(boom, false).timeout.connect(_on_boom.bind(near))


func _on_boom(near : bool) -> void:
	BrewerySignals.cellar_shaken.emit(NEAR_TRAUMA if near else FAR_TRAUMA)
	var spots : int = randi_range(NEAR_DUST_SPOTS.x, NEAR_DUST_SPOTS.y) if near else int(randf() < FAR_DUST_CHANCE)
	for i : int in spots:
		var dust := DustFall.new()
		dust.z_index = DUST_Z_INDEX
		dust.position = Vector2(roundf(randf_range(ceiling_left, ceiling_right)), ceiling_y)
		add_child(dust)


func _on_customer_entered() -> void:
	if not _active:
		return
	if _door_player.stream != null:
		_door_player.play()
	if _flash_tween != null:
		_flash_tween.kill()
	_flash_tween = create_tween()
	for i : int in randi_range(DOOR_BURSTS.x, DOOR_BURSTS.y):
		var color : Color = FLASH_COLORS.pick_random()
		_flash_tween.tween_callback(func() -> void:
			door_flash.color = color
			door_flash.energy = DOOR_FLASH_ENERGY)
		_flash_tween.tween_property(door_flash, "energy", 0.0, DOOR_FLASH_FADE_SECONDS)
		_flash_tween.tween_interval(DOOR_BURST_PAUSE_SECONDS)


func _make_player() -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = SOUND_BUS
	add_child(player)
	return player
