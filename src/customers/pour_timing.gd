class_name PourTiming
extends RefCounted

## Seconds left in the bartender's pours, from the serve animation's frame durations.


## One whole pour at `speed_scale`.
static func full_seconds(durations : PackedFloat32Array, fps : float, speed_scale : float) -> float:
	return seconds_left(durations, fps, speed_scale, 0, 0.0, [])


## The running pour from `frame` (`progress` into it) plus each queued pour at its speed.
static func seconds_left(durations : PackedFloat32Array, fps : float, speed_scale : float, frame : int, progress : float, queued_speeds : Array[float]) -> float:
	var frame_units : float = 0.0
	for i : int in range(frame, durations.size()):
		frame_units += durations[i] * (1.0 - progress if i == frame else 1.0)
	var left : float = frame_units / (fps * speed_scale)
	for queued_speed : float in queued_speeds:
		left += full_seconds(durations, fps, queued_speed)
	return left
