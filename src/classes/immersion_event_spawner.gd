class_name ImmersionEventSpawner
extends Node2D

## Purely decorative background flavor: every so often a vignette (e.g. a
## mouse scurrying across the floor with a cat in chase) plays. Zero gameplay
## effect: nothing here reads or writes Brewery state, reputation, risk, or
## any BrewerySignals.
##
## Vignettes are data: every ImmersionVignetteData .tres in VIGNETTE_DIR is
## loaded at startup (same auto-load-from-folder pattern as the project's other
## registries), naming its actors and which PathMarkers-style child node
## supplies the route. Actor sprites are created per run and freed when they
## reach the end of the path.

const MIN_INTERVAL_SECONDS : float = 240.0
const MAX_INTERVAL_SECONDS : float = 480.0

const VIGNETTE_DIR : String = "res://src/resources/immersion_vignettes/"

## Same foot-anchored setup as customer.tscn's AnimatedSprite2D: position is
## the sprite's feet, so y-sorting against kegs and customers reads correctly.
const SPRITE_OFFSET : Vector2 = Vector2(-16, -32)

## Fake depth: every DEPTH_Y_STEP pixels a sprite is above DEPTH_REFERENCE_Y
## (further from the camera) it shrinks by DEPTH_SCALE_PER_STEP of its base
## scale, and grows by the same amount when below it. Clamped so a stray
## marker can't make it vanish or balloon.
const DEPTH_REFERENCE_Y : float = 330.0
const DEPTH_Y_STEP : float = 20.0
const DEPTH_SCALE_PER_STEP : float = 0.05
const DEPTH_SCALE_MIN_FACTOR : float = 0.4
const DEPTH_SCALE_MAX_FACTOR : float = 1.5

## Lets DevConsole's "cat" command reach this instance via
## get_tree().get_first_node_in_group() — same lightweight lookup
## Bartender.BARTENDER_GROUP already uses elsewhere, instead of routing
## through a dedicated autoload that would otherwise exist purely to
## relay one debug command (there's no other gameplay state here for an
## autoload to own).
const IMMERSION_EVENT_SPAWNER_GROUP : String = "immersion_event_spawner"

var vignettes : Array[ImmersionVignetteData] = []

var _timer : Timer
## Live actor sprites -> their base scale, so _process() can apply the depth
## scale without any per-actor bookkeeping node.
var _active_sprites : Dictionary = {}


func _ready() -> void:
	add_to_group(IMMERSION_EVENT_SPAWNER_GROUP)
	_load_vignettes()
	_setup_timer()


func _process(_delta: float) -> void:
	for sprite : AnimatedSprite2D in _active_sprites:
		_apply_depth_scale(sprite, _active_sprites[sprite])


func _load_vignettes() -> void:
	vignettes.clear()
	for file_name : String in ResourceLoader.list_directory(VIGNETTE_DIR):
		if not file_name.ends_with(".tres"):
			continue
		var vignette : ImmersionVignetteData = load(VIGNETTE_DIR + file_name) as ImmersionVignetteData
		if vignette != null:
			vignettes.append(vignette)


func _apply_depth_scale(sprite : AnimatedSprite2D, base_scale : Vector2) -> void:
	var steps : float = (sprite.global_position.y - DEPTH_REFERENCE_Y) / DEPTH_Y_STEP
	var factor : float = clampf(1.0 + steps * DEPTH_SCALE_PER_STEP, DEPTH_SCALE_MIN_FACTOR, DEPTH_SCALE_MAX_FACTOR)
	sprite.scale = base_scale * factor


## DevConsole's "cat" command — fires a vignette immediately instead of
## waiting for the timer, and re-rolls that timer so it doesn't also fire
## again moments later on top of this forced one.
func force_trigger() -> void:
	_run_vignette()
	_start_next_timer()


func _setup_timer() -> void:
	_timer = Timer.new()
	_timer.process_callback = Timer.TIMER_PROCESS_IDLE
	_timer.one_shot = true
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)
	_start_next_timer()


func _start_next_timer() -> void:
	_timer.start(randf_range(MIN_INTERVAL_SECONDS, MAX_INTERVAL_SECONDS))


func _on_timer_timeout() -> void:
	_run_vignette()
	_start_next_timer()


func _run_vignette() -> void:
	var vignette : ImmersionVignetteData = _pick_vignette()
	if vignette == null:
		return

	var path_root : Node2D = get_node_or_null(NodePath(vignette.path_node_name)) as Node2D
	if path_root == null:
		push_warning("ImmersionEventSpawner: no path node '%s' for vignette '%s'" % [vignette.path_node_name, vignette.vignette_name])
		return

	var points : PackedVector2Array = _get_waypoints(path_root)
	if points.size() < 2:
		push_warning("ImmersionEventSpawner: '%s' needs at least 2 Marker2D children" % path_root.name)
		return

	for actor : ImmersionActorData in vignette.actors:
		_run_actor(actor, points)


## Weighted random pick; null when nothing is loaded.
func _pick_vignette() -> ImmersionVignetteData:
	var total_weight : float = 0.0
	for vignette : ImmersionVignetteData in vignettes:
		total_weight += maxf(vignette.weight, 0.0)
	if total_weight <= 0.0:
		return null

	var roll : float = randf() * total_weight
	for vignette : ImmersionVignetteData in vignettes:
		roll -= maxf(vignette.weight, 0.0)
		if roll <= 0.0:
			return vignette
	return vignettes.back()


func _get_waypoints(path_root : Node2D) -> PackedVector2Array:
	var points := PackedVector2Array()
	for child : Node in path_root.get_children():
		if child is Marker2D:
			points.append((child as Marker2D).global_position)
	return points


func _run_actor(actor : ImmersionActorData, points : PackedVector2Array) -> void:
	if actor.start_delay_seconds > 0.0:
		await get_tree().create_timer(actor.start_delay_seconds).timeout
	if not is_inside_tree():
		return
	_cross(actor, points)


func _cross(actor : ImmersionActorData, points : PackedVector2Array) -> void:
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = actor.sprite_frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	sprite.offset = SPRITE_OFFSET
	sprite.global_position = points[0]
	add_child(sprite)
	sprite.play(actor.animation)
	_active_sprites[sprite] = actor.base_scale
	# Set the depth scale before the first frame draws, not one frame later.
	_apply_depth_scale(sprite, actor.base_scale)

	var total_length : float = 0.0
	for i : int in range(1, points.size()):
		total_length += points[i - 1].distance_to(points[i])

	# Segment durations are proportional to length so speed stays constant
	# and the total stays actor.crossing_seconds (keeps a chaser's gap steady).
	var tween := sprite.create_tween()
	for i : int in range(1, points.size()):
		var seg_duration : float = actor.crossing_seconds * points[i - 1].distance_to(points[i]) / maxf(total_length, 0.001)
		# Art is drawn facing left, so mirror it on legs heading right.
		# Purely vertical legs keep the previous facing.
		var dx : float = points[i].x - points[i - 1].x
		if not is_zero_approx(dx):
			var facing_right : bool = dx > 0.0
			tween.tween_callback(func() -> void: sprite.flip_h = facing_right)
		tween.tween_property(sprite, "global_position", points[i], seg_duration)
	tween.tween_callback(_finish_actor.bind(sprite))


func _finish_actor(sprite : AnimatedSprite2D) -> void:
	_active_sprites.erase(sprite)
	sprite.queue_free()
