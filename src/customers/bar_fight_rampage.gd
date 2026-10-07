class_name BarFightRampage
extends RefCounted

## The visible side of a bar fight: the customer flashes red, stomps back and forth in
## front of the counter and hurls one glass per broken bottle, each shattering on the
## floor. Purely visual; SaleProcessor already applied the fight's costs.

const RAGE_COLOR: Color = Color(1.0, 0.3, 0.25)
const FLASH_SECONDS: float = 0.24
const STOMPS: int = 6
const STOMP_SECONDS: float = 0.48
const STOMP_DISTANCE: float = 26.0
const STOMP_HOP: float = 8.0
const RETURN_SECONDS: float = 0.15
## How long play() runs, for callers that start it without awaiting.
const DURATION_SECONDS: float = STOMPS * STOMP_SECONDS + RETURN_SECONDS

## Where the glass leaves the customer's hand, relative to their feet. Low and flat on
## purpose: the customer's speech bubble sits above their head and would hide a high arc.
const THROW_HAND_OFFSET: Vector2 = Vector2(0.0, -40.0)
const THROW_MIN_DISTANCE: float = 80.0
const THROW_MAX_DISTANCE: float = 170.0
## Landing spots scatter in depth too, on the floor in front of the counter.
const THROW_DEPTH_SCATTER: Vector2 = Vector2(5.0, 40.0)
const THROW_ARC_HEIGHT: float = 28.0
const THROW_SECONDS: float = 0.75
const THROW_SPIN: float = TAU * 2.0
const GLASS_SCALE: Vector2 = Vector2(3.0, 3.0)
## Above the y-sorted world: a glass in the air sorts by its height and would slip
## behind the counter.
const FLYING_Z_INDEX: int = 10

const SHARD_COUNT: int = 7
const SHARD_SIZE: Vector2 = Vector2(6.0, 6.0)
const SHARD_COLOR: Color = Color(1.0, 0.92, 0.6)
const SHARD_SPREAD: float = 36.0
const SHARD_SECONDS: float = 0.5


## Plays the rampage; await it to know when it is over. The sprite gets the red flash,
## facing and walk animation, the actor is the node that moves. A loaded rampage starts
## at `first_stomp`; `on_stomp` hears the index of each stomp still to come once the
## previous one is under way, so the caller can save its progress.
static func play(actor: Node2D, sprite: AnimatedSprite2D, glass_texture: Texture2D, glass_count: int, first_stomp: int = 0, on_stomp: Callable = Callable()) -> void:
	if first_stomp >= STOMPS:
		return
	var home: Vector2 = actor.position
	var flash := actor.create_tween().set_loops(STOMPS - first_stomp)
	flash.tween_property(sprite, "modulate", RAGE_COLOR, FLASH_SECONDS)
	flash.tween_property(sprite, "modulate", Color.WHITE, FLASH_SECONDS)

	for i in range(first_stomp, STOMPS):
		if on_stomp.is_valid():
			on_stomp.call(i + 1)
		var direction: float = 1.0 if i % 2 == 0 else -1.0
		sprite.flip_h = direction < 0.0
		if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(Customer.ANIM_WALK_RIGHT):
			sprite.play(Customer.ANIM_WALK_RIGHT)
		var stomp := actor.create_tween()
		stomp.tween_property(actor, "position", home + Vector2(STOMP_DISTANCE * direction, -STOMP_HOP), STOMP_SECONDS * 0.5)
		stomp.tween_property(actor, "position", home + Vector2(STOMP_DISTANCE * direction, 0.0), STOMP_SECONDS * 0.5)
		for throw in share_of(i, glass_count, STOMPS):
			_throw_glass(actor, glass_texture, direction)
		await stomp.finished

	var settle := actor.create_tween()
	settle.tween_property(actor, "position", home, RETURN_SECONDS)
	await settle.finished
	sprite.modulate = Color.WHITE
	sprite.flip_h = false
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(Customer.ANIM_IDLE_UP):
		sprite.play(Customer.ANIM_IDLE_UP)


## Part `index` of `total` split into `parts` near-equal shares, earlier parts first:
## glasses over the stomps, and over the members of a fighting group.
static func share_of(index: int, total: int, parts: int) -> int:
	@warning_ignore("integer_division")
	return total / parts + (1 if index < total % parts else 0)


## A point on a parabola from `from` to `to` peaking `height` above the straight line.
static func arc_point(from: Vector2, to: Vector2, height: float, t: float) -> Vector2:
	return from.lerp(to, t) + Vector2(0.0, -height * 4.0 * t * (1.0 - t))


static func _throw_glass(actor: Node2D, texture: Texture2D, direction: float) -> void:
	var glass := Sprite2D.new()
	glass.texture = texture
	glass.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	glass.scale = GLASS_SCALE
	glass.z_index = FLYING_Z_INDEX
	var from: Vector2 = actor.position + THROW_HAND_OFFSET
	var to: Vector2 = actor.position + Vector2(direction * randf_range(THROW_MIN_DISTANCE, THROW_MAX_DISTANCE), randf_range(THROW_DEPTH_SCATTER.x, THROW_DEPTH_SCATTER.y))
	glass.position = from
	# In the actor's parent, so a glass keeps flying after the customer walks away.
	actor.get_parent().add_child(glass)

	var flight := glass.create_tween().set_parallel()
	flight.tween_method(func(t: float) -> void: glass.position = arc_point(from, to, THROW_ARC_HEIGHT, t), 0.0, 1.0, THROW_SECONDS)
	flight.tween_property(glass, "rotation", THROW_SPIN * direction, THROW_SECONDS)
	flight.chain().tween_callback(_shatter.bind(glass))


static func _shatter(glass: Sprite2D) -> void:
	var parent: Node = glass.get_parent()
	var at: Vector2 = glass.position
	glass.queue_free()
	BrewerySignals.glass_shattered.emit()
	for i in SHARD_COUNT:
		var shard := ColorRect.new()
		shard.size = SHARD_SIZE
		shard.color = SHARD_COLOR
		shard.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shard.z_index = FLYING_Z_INDEX
		shard.position = at
		parent.add_child(shard)
		# Angles between PI and TAU point upward, so shards burst up off the floor.
		var target: Vector2 = at + Vector2.from_angle(randf_range(PI, TAU)) * randf_range(SHARD_SPREAD * 0.5, SHARD_SPREAD)
		var burst := shard.create_tween().set_parallel()
		burst.tween_property(shard, "position", target, SHARD_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		burst.tween_property(shard, "modulate:a", 0.0, SHARD_SECONDS)
		burst.chain().tween_callback(shard.queue_free)
