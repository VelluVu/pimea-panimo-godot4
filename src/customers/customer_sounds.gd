class_name CustomerSounds
extends RefCounted

## A customer's own sounds: footsteps while a walk animation plays, and the ambient loop
## some customers carry with them (a drone's hum).

const AMBIENT_LOOP_VOLUME_DB : float = -12.0

var _ambient_player : AudioStreamPlayer2D


## Call on every frame change; a step lands on each contact frame of `walk_animations`.
func on_frame(owner : Node2D, sprite : AnimatedSprite2D, data : CustomerData, walk_animations : Array[StringName]) -> void:
	if data == null or not data.makes_footsteps:
		return
	if MirroredAnimation.base_name(sprite.animation) in walk_animations and is_contact_frame(sprite.frame):
		BrewerySignals.customer_stepped.emit(owner.global_position)


## Frames 1 and 3 of the 4-frame walks (0 and 2 counted from zero) put a foot down.
static func is_contact_frame(frame : int) -> bool:
	return frame % 2 == 0


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
