class_name WalkStepper
extends RefCounted

## Turns the distance a walker covers into walk frames, so the legs keep pace with the body
## whatever the speed: the eased walk out, the stairs and their pauses included. A clock
## driven walk skates whenever the body speeds up or stops.

## Art pixels walked per frame on the floor: half the gap between the feet in the contact
## frames (about 10 art pixels on the sheets), as a planted foot sweeps the gap in two frames.
const STRIDE_ART_PIXELS : float = 5.0
## One stair is one step: contact to contact.
const FRAMES_PER_STAIR : int = 2

var active : bool = false

var _stride : float = 0.0
var _travelled : float = 0.0
var _last : Vector2 = Vector2.ZERO


## Screen pixels per frame on the floor for art drawn `art_scale` times bigger.
static func floor_stride(art_scale : float) -> float:
	return STRIDE_ART_PIXELS * art_scale


## Screen pixels per frame down `steps` stairs from `from` to `to`.
static func stair_stride(from : Vector2, to : Vector2, steps : int) -> float:
	return from.distance_to(to) / maxi(1, steps) / FRAMES_PER_STAIR


## Starts counting from `at`; every `stride` pixels moved is one frame.
func start(at : Vector2, stride : float) -> void:
	active = stride > 0.0
	_stride = stride
	_travelled = 0.0
	_last = at


func stop() -> void:
	active = false


## The frames to step after moving to `at`.
func advance(at : Vector2) -> int:
	if not active:
		return 0
	_travelled += at.distance_to(_last)
	_last = at
	var frames : int = floori(_travelled / _stride)
	_travelled -= frames * _stride
	return frames


## Hands `sprite`'s walk animation over to the distance walked from `at`, from a random
## frame so a group setting off together does not march in step. Play the animation first.
func begin(sprite : AnimatedSprite2D, at : Vector2, stride : float) -> void:
	sprite.speed_scale = 0.0
	sprite.frame = randi() % maxi(1, sprite.sprite_frames.get_frame_count(sprite.animation))
	start(at, stride)


## Call every frame: steps `sprite` by the distance moved to `at`.
func tick(sprite : AnimatedSprite2D, at : Vector2) -> void:
	var frames : int = advance(at)
	if frames > 0:
		sprite.frame = next_frame(sprite.frame, frames, sprite.sprite_frames.get_frame_count(sprite.animation))


## Gives `sprite` back its own clock.
func end(sprite : AnimatedSprite2D) -> void:
	stop()
	sprite.speed_scale = 1.0


## The frame `frames` on from `frame` in a looping animation of `count` frames.
static func next_frame(frame : int, frames : int, count : int) -> int:
	if count <= 0:
		return 0
	return (frame + frames) % count
