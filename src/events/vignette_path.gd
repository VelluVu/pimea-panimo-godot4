class_name VignettePath
extends RefCounted

## Movement maths for immersion vignette actors: fake depth scaling and constant-speed
## timing along a waypoint path.

## Every DEPTH_Y_STEP pixels above DEPTH_REFERENCE_Y a sprite shrinks by
## DEPTH_SCALE_PER_STEP, and grows below it; clamped against stray markers.
const DEPTH_REFERENCE_Y: float = 330.0
const DEPTH_Y_STEP: float = 20.0
const DEPTH_SCALE_PER_STEP: float = 0.05
const DEPTH_SCALE_MIN_FACTOR: float = 0.4
const DEPTH_SCALE_MAX_FACTOR: float = 1.5


static func depth_scale_factor(y: float) -> float:
	var steps: float = (y - DEPTH_REFERENCE_Y) / DEPTH_Y_STEP
	return clampf(1.0 + steps * DEPTH_SCALE_PER_STEP, DEPTH_SCALE_MIN_FACTOR, DEPTH_SCALE_MAX_FACTOR)


## `base_scale` at depth `y`, rounded to a whole scale: a fractional one draws some art
## pixels a screen pixel wider than others.
static func pixel_scale(base_scale: float, y: float) -> float:
	return maxf(1.0, roundf(base_scale * depth_scale_factor(y)))


## Leg durations by length, so speed is constant and a chaser's gap steady.
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
