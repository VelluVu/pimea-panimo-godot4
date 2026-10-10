class_name BubbleLayout
extends RefCounted

## Where a speech bubble goes. Bubbles that would overlap side by side stack one step up,
## at most MAX_STACK_STEPS; past that the older bubble collapses into a small badge instead
## (DialogView), so a busy counter never grows a tall pile.

const OFFSET_Y : float = -180.0
const STAIR_STEP : float = 34.0
const MIN_VISIBLE_Y : float = 38.0
## Room kept between bubbles side by side.
const SIDE_GAP : float = 4.0
const MAX_STACK_STEPS : int = 1
## A collapsed bubble's badge sits this much lower than a bubble, closer to the speaker.
const BADGE_DROP : float = 40.0


## Whether bubbles `width` and `other_width` wide, centred on `x` and `other_x`, would
## touch side by side.
static func overlaps_x(x : float, width : float, other_x : float, other_width : float) -> bool:
	return absf(x - other_x) < (width + other_width) * 0.5 + SIDE_GAP


## The lowest height not taken by an open bubble it would overlap, capped by
## MAX_STACK_STEPS and by the top of the screen.
static func choose_step(speaker_pos : Vector2, width : float, others : Array[BubbleEntry]) -> int:
	var base_y : float = speaker_pos.y + OFFSET_Y
	var max_steps : int = mini(MAX_STACK_STEPS, maxi(0, floori((base_y - MIN_VISIBLE_Y) / STAIR_STEP)))
	var taken : Dictionary = {}
	for other : BubbleEntry in others:
		if overlaps_x(speaker_pos.x, width, other.x, other.width):
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


## Top edge for a bubble `height` tall stacked over open bubbles whose top edges are
## `tops`, so it covers none of them. Below MIN_VISIBLE_Y it does not fit.
static func stacked_y(tops : Array[float], height : float) -> float:
	var highest : float = INF
	for top : float in tops:
		highest = minf(highest, top)
	return highest - height - SIDE_GAP


## Where a collapsed bubble's badge goes: centred over the speaker, below the bubbles.
static func badge_position_for(speaker_pos : Vector2, badge_size : Vector2, viewport_size : Vector2) -> Vector2:
	return position_for(speaker_pos, 0, badge_size, viewport_size) + Vector2(0.0, BADGE_DROP)
