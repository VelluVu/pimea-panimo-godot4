class_name WinterArrival
extends RefCounted

## In winter a customer comes in with snow on their head and shoulders (SnowCover), stamps it
## off during the walk in's pause in the room centre, then blows out a puff of cold breath.
## Queued into the walk in's tween; WinterPuffs draws the falling snow and the breath. A
## customer without feet (CustomerData.makes_footsteps) only shakes, and a machine does not
## breathe.

## Of the snow still on, the share each stomp knocks off; the last takes the rest.
const STOMP_SHARES : Array[float] = [0.5, 1.0]
const STOMP_LIFT_SECONDS : float = 0.1
const STOMP_REST_SECONDS : float = 0.15
## The idle frame's mouth, in art pixels from the feet.
const MOUTH_ART_PIXELS : Vector2 = Vector2(0.0, -21.0)


static func seconds() -> float:
	return STOMP_SHARES.size() * (STOMP_LIFT_SECONDS + STOMP_REST_SECONDS)


## Snow on the customer for the walk in, until queue()'s stomps knock it off.
static func cover(sprite : AnimatedSprite2D) -> SnowCover:
	var snow := SnowCover.new()
	sprite.add_child(snow)
	return snow


## Takes seconds() of the tween.
static func queue(tween : Tween, owner : Node2D, sprite : AnimatedSprite2D, snow : SnowCover, data : CustomerData) -> void:
	var rest_offset : Vector2 = sprite.offset
	for share in STOMP_SHARES:
		tween.tween_callback(func() -> void: sprite.offset = rest_offset + Vector2.UP)
		tween.tween_interval(STOMP_LIFT_SECONDS)
		tween.tween_callback(_stomp.bind(owner, sprite, rest_offset, snow, share, data.makes_footsteps))
		tween.tween_interval(STOMP_REST_SECONDS)
	if data.breathes:
		tween.tween_callback(func() -> void: BrewerySignals.breath_puffed.emit(owner.global_position + MOUTH_ART_PIXELS * sprite.scale.x))


static func _stomp(owner : Node2D, sprite : AnimatedSprite2D, rest_offset : Vector2, snow : SnowCover, share : float, has_feet : bool) -> void:
	sprite.offset = rest_offset
	if has_feet:
		BrewerySignals.customer_stepped.emit(owner.global_position)
		BrewerySignals.snow_stamped_off.emit(owner.global_position)
	if is_instance_valid(snow):
		snow.shake(share, owner.global_position.y)
