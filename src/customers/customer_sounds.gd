class_name CustomerSounds
extends RefCounted

## A customer's own sounds: footsteps while a walk animation plays, and the ambient loop
## some customers carry with them (a drone's hum).

## Seconds between footsteps while a walk animation plays.
const FOOTSTEP_INTERVAL_SECONDS : float = 0.32
const AMBIENT_LOOP_VOLUME_DB : float = -12.0

var _footstep_clock : float = 0.0
var _ambient_player : AudioStreamPlayer2D


## Call every frame; steps only while one of `walk_animations` plays.
func tick(delta : float, owner : Node2D, sprite : AnimatedSprite2D, data : CustomerData, walk_animations : Array[StringName]) -> void:
	if data == null or not data.makes_footsteps:
		return
	if not (sprite.is_playing() and MirroredAnimation.base_name(sprite.animation) in walk_animations):
		_footstep_clock = 0.0
		return
	_footstep_clock += delta
	if _footstep_clock >= FOOTSTEP_INTERVAL_SECONDS:
		_footstep_clock -= FOOTSTEP_INTERVAL_SECONDS
		BrewerySignals.customer_stepped.emit(owner.global_position)


## The loop follows the customer, so it is a child player rather than AudioManager's.
## Restarted on finish: the WAV files are not imported as loops.
func start_ambient_loop(owner : Node2D, data : CustomerData) -> void:
	if data.ambient_loop == null or _ambient_player != null:
		return
	_ambient_player = AudioStreamPlayer2D.new()
	_ambient_player.stream = data.ambient_loop
	_ambient_player.bus = &"SFX"
	_ambient_player.volume_db = AMBIENT_LOOP_VOLUME_DB
	_ambient_player.finished.connect(_ambient_player.play)
	owner.add_child(_ambient_player)
	_ambient_player.play()
