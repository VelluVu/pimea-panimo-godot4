class_name VignettePath
extends RefCounted

## Movement maths for immersion vignette actors: fake depth scaling and constant-speed
## timing along a waypoint path.

## Every DEPTH_Y_STEP pixels above DEPTH_REFERENCE_Y (further from the camera) a sprite
## shrinks by DEPTH_SCALE_PER_STEP, and grows the same below it. Clamped so a stray
## marker can't make it vanish or balloon.
const DEPTH_REFERENCE_Y: float = 330.0
const DEPTH_Y_STEP: float = 20.0
const DEPTH_SCALE_PER_STEP: float = 0.05
const DEPTH_SCALE_MIN_FACTOR: float = 0.4
const DEPTH_SCALE_MAX_FACTOR: float = 1.5


static func depth_scale_factor(y: float) -> float:
	var steps: float = (y - DEPTH_REFERENCE_Y) / DEPTH_Y_STEP
	return clampf(1.0 + steps * DEPTH_SCALE_PER_STEP, DEPTH_SCALE_MIN_FACTOR, DEPTH_SCALE_MAX_FACTOR)


## One duration per leg, proportional to its length, so speed stays constant and the
## legs add up to `total_seconds` (keeps a chaser's gap steady).
static func segment_durations(points: PackedVector2Array, total_seconds: float) -> PackedFloat32Array:
	var lengths := PackedFloat32Array()
	var total_length: float = 0.0
	for i: int in range(1, points.size()):
		var length: float = points[i - 1].distance_to(points[i])
		lengths.append(length)
		total_length += length
	var durations := PackedFloat32Array()
	for length: float in lengths:
		durations.append(total_seconds * length / maxf(total_length, 0.001))
	return durations
