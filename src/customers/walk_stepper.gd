class_name WalkStepper
extends RefCounted

## Turns the distance a walker covers into walk frames, so the legs keep pace with the body
## whatever the speed: the eased walk out, the stairs and their pauses included. A clock
## driven walk skates whenever the body speeds up or stops.

var active : bool = false

var _stride : float = 0.0
var _travelled : float = 0.0
var _last : Vector2 = Vector2.ZERO


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


## The frame `frames` on from `frame` in a looping animation of `count` frames.
static func next_frame(frame : int, frames : int, count : int) -> int:
	if count <= 0:
		return 0
	return (frame + frames) % count
