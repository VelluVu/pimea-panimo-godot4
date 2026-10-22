class_name PixelStepTween
extends RefCounted

## Tweens a Node2D's global position in whole steps instead of gliding through fractions.
## Pixel art drawn N times bigger moves cleanest with step N: the sprite shifts by one of
## its own pixels at a time, and never sits between screen pixels where its columns bend.
##   PixelStepTween.move(tween, self, global_position, target, 2.0, sprite.scale.x)


## Queues the move on `tween`; returns the tweener so trans and ease can still be set.
static func move(tween : Tween, node : Node2D, from : Vector2, to : Vector2, seconds : float, step : float = 1.0) -> MethodTweener:
	var set_position := func(at : Vector2) -> void: node.global_position = snapped_on_path(from, to, at, step)
	return tween.tween_method(set_position, from, to, seconds)


## move() for any Vector2 property, such as a Control's `position` or a local position.
static func move_property(tween : Tween, object : Object, property : StringName, from : Vector2, to : Vector2, seconds : float, step : float = 1.0) -> MethodTweener:
	var set_value := func(at : Vector2) -> void: object.set(property, snapped_on_path(from, to, at, step))
	return tween.tween_method(set_value, from, to, seconds)


## `at` on the grid of `step` that starts from `from`, rounded to whole pixels; the end
## lands on `to` itself.
static func snapped_on_path(from : Vector2, to : Vector2, at : Vector2, step : float) -> Vector2:
	if at.is_equal_approx(to):
		return to.round()
	var start : Vector2 = from.round()
	return start + (at - start).snapped(Vector2(step, step)).round()
