class_name WalkCadence
extends RefCounted

## How fast a walk animation plays so the feet keep up with the body: every frame carries
## the walker STRIDE_ART_PIXELS of its own art. On the sheets' fixed 6 fps a 120 px/s walk
## slid 5 art pixels a frame and the feet skated.

const STRIDE_ART_PIXELS : float = 3.0


## AnimatedSprite2D.speed_scale for walking `walk_speed` px/s on an animation of `fps`,
## drawn `art_scale` times bigger than its sheet.
static func speed_scale(walk_speed : float, fps : float, art_scale : float) -> float:
	if walk_speed <= 0.0 or fps <= 0.0 or art_scale <= 0.0:
		return 1.0
	return walk_speed / (fps * STRIDE_ART_PIXELS * art_scale)


## `speed_scale()` for the animation `sprite` plays now: 1.0 unless it is a walk.
static func for_sprite(sprite : AnimatedSprite2D, walk_speed : float, walk_animations : Array[StringName]) -> float:
	if not MirroredAnimation.base_name(sprite.animation) in walk_animations:
		return 1.0
	return speed_scale(walk_speed, sprite.sprite_frames.get_animation_speed(sprite.animation), sprite.scale.x)
