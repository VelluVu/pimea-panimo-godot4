class_name BubbleLayout
extends RefCounted

## Where a speech bubble goes. Speakers who stand far apart share the lowest height;
## only speakers close enough to collide get stacked, and a height frees up the moment
## the nearby bubble goes away.

const OFFSET_Y : float = -180.0
const STAIR_STEP : float = 34.0
const MIN_VISIBLE_Y : float = 38.0
const X_PROXIMITY_PX : float = 60.0


## The lowest height not taken by another bubble close enough on the x axis, capped so
## the bubble stays on screen.
static func choose_step(speaker_pos : Vector2, others : Array[BubbleEntry]) -> int:
	var base_y : float = speaker_pos.y + OFFSET_Y
	var max_steps : int = maxi(0, floori((base_y - MIN_VISIBLE_Y) / STAIR_STEP))

	var taken : Dictionary = {}
	for other : BubbleEntry in others:
		if absf(other.x - speaker_pos.x) < X_PROXIMITY_PX:
			taken[other.height_step] = true

	var step : int = 0
	while taken.has(step) and step < max_steps:
		step += 1
	return step


## Centered over the speaker, then clamped fully inside the viewport: a wide bubble or a
## speaker at a screen edge must not push it off screen.
static func position_for(speaker_pos : Vector2, step : int, bubble_size : Vector2, viewport_size : Vector2) -> Vector2:
	var target_x : float = speaker_pos.x - bubble_size.x * 0.5
	var target_y : float = speaker_pos.y + OFFSET_Y - step * STAIR_STEP
	return Vector2(
		clampf(target_x, 0.0, maxf(0.0, viewport_size.x - bubble_size.x)),
		clampf(target_y, 0.0, maxf(0.0, viewport_size.y - bubble_size.y)))
