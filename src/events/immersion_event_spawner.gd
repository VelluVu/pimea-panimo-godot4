class_name ImmersionEventSpawner
extends Node2D

## Decorative vignettes (a mouse chased by a cat) every few minutes, no gameplay. The
## adopted cellar cat lives in the cellar on its own (CellarCat) and hears of every pest.

## A pest actor came out; the cellar cat chases it or, when it flies, watches it.
signal pest_appeared(sprite : AnimatedSprite2D, flying : bool)

const MIN_INTERVAL_SECONDS : float = 240.0 * DayPace.SCALE
const MAX_INTERVAL_SECONDS : float = 480.0 * DayPace.SCALE

const VIGNETTE_DIR : String = "res://src/resources/immersion_vignettes/"

## Feet-anchored like customer.tscn, so y-sorting against kegs and customers works.
const SPRITE_OFFSET : Vector2 = Vector2(-16, -32)
## Fades at a route's ends, so one that starts or ends on screen does not pop.
const FADE_SECONDS : float = 0.5
## Above customers (z 1); same as the wall overlays in main.tscn.
const FLYING_Z_INDEX : int = 2

const SOUND_BUS : StringName = &"SFX"
const SOUND_VOLUME_DB : float = -4.0
## Where in the crossing the sound may land: not while fading.
const SOUND_WINDOW : Vector2 = Vector2(0.2, 0.7)

## Lets the console's "cat" command find this node without an autoload.
const IMMERSION_EVENT_SPAWNER_GROUP : String = "immersion_event_spawner"

var vignettes : Array[ImmersionVignetteData] = []

var _timer : Timer
## Live actor sprite -> its base scale, rescaled for depth every frame.
var _active_sprites : Dictionary = {}


func _ready() -> void:
	add_to_group(IMMERSION_EVENT_SPAWNER_GROUP)
	_load_vignettes()
	_setup_timer()


func _process(_delta: float) -> void:
	for sprite : AnimatedSprite2D in _active_sprites:
		_apply_depth_scale(sprite, _active_sprites[sprite])


func _load_vignettes() -> void:
	vignettes.assign(ResourceFolder.load_all(VIGNETTE_DIR, ImmersionVignetteData))


func _apply_depth_scale(sprite : AnimatedSprite2D, base_scale : Vector2) -> void:
	sprite.scale = Vector2.ONE * VignettePath.pixel_scale(base_scale.x, sprite.global_position.y)


## The console's "cat" and "vignette": plays `vignette` (random when null) and re-rolls
## the timer so another does not follow at once.
func force_trigger(vignette : ImmersionVignetteData = null) -> void:
	_run_vignette(vignette if vignette != null else _pick_vignette())
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
	_run_vignette(_pick_vignette())
	_start_next_timer()


func _run_vignette(vignette : ImmersionVignetteData) -> void:
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

	var has_cellar_cat : bool = BrewEngine.current_brewery != null and BrewEngine.current_brewery.cellar_cat_adopted
	for actor : ImmersionActorData in vignette.actors:
		if actor.cellar_cat_takes_over and has_cellar_cat:
			continue
		var sprite : AnimatedSprite2D = _cross(actor, points)
		if actor.pest:
			pest_appeared.emit(sprite, actor.flying)


## Null when nothing is loaded.
func _pick_vignette() -> ImmersionVignetteData:
	var weights : Array[float] = []
	var season : SeasonRules.Season = SeasonRules.now()
	var is_halloween : bool = season == SeasonRules.Season.HALLOWEEN
	for vignette : ImmersionVignetteData in vignettes:
		weights.append(vignette.pick_weight(is_halloween, season))
	return WeightedPicker.pick(vignettes, weights) as ImmersionVignetteData


func _get_waypoints(path_root : Node2D) -> PackedVector2Array:
	var points := PackedVector2Array()
	for child : Node in path_root.get_children():
		if child is Marker2D:
			points.append((child as Marker2D).global_position)
	return points


func _cross(actor : ImmersionActorData, points : PackedVector2Array) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = actor.sprite_frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	sprite.offset = SPRITE_OFFSET
	sprite.global_position = points[0]
	add_child(sprite)
	sprite.play(actor.animation)
	if actor.flying:
		sprite.scale = actor.base_scale
		sprite.z_index = FLYING_Z_INDEX
	else:
		_active_sprites[sprite] = actor.base_scale
		# Set the depth scale before the first frame draws, not one frame later.
		_apply_depth_scale(sprite, actor.base_scale)

	var durations : PackedFloat32Array = VignettePath.segment_durations(points, actor.crossing_seconds)
	var tween := sprite.create_tween()
	# The delay lives in the sprite's tween, so a scene change frees it instead of resuming a
	# coroutine on a freed spawner.
	if actor.start_delay_seconds > 0.0:
		sprite.hide()
		tween.tween_interval(actor.start_delay_seconds)
		tween.tween_callback(sprite.show)
	for i : int in range(1, points.size()):
		# Mirror the art on legs heading away from the way it was drawn; vertical legs keep facing.
		var dx : float = points[i].x - points[i - 1].x
		if not is_zero_approx(dx):
			var mirrored : bool = (dx > 0.0) != actor.art_faces_right
			tween.tween_callback(func() -> void: sprite.flip_h = mirrored)
		PixelStepTween.move(tween, sprite, points[i - 1], points[i], durations[i - 1])
	tween.tween_callback(_finish_actor.bind(sprite))
	_fade_in_and_out(sprite, actor.start_delay_seconds, actor.crossing_seconds)
	_maybe_make_sound(actor, sprite)
	return sprite


## A child player, so the sound comes from the critter and leaves with it.
func _maybe_make_sound(actor : ImmersionActorData, sprite : AnimatedSprite2D) -> void:
	if actor.sounds.is_empty() or randf() >= actor.sound_chance:
		return
	var player := AudioStreamPlayer2D.new()
	player.stream = actor.sounds.pick_random()
	player.bus = SOUND_BUS
	player.volume_db = SOUND_VOLUME_DB
	sprite.add_child(player)
	var at_seconds : float = actor.start_delay_seconds + randf_range(SOUND_WINDOW.x, SOUND_WINDOW.y) * actor.crossing_seconds
	sprite.create_tween().tween_callback(player.play).set_delay(at_seconds)


func _fade_in_and_out(sprite : AnimatedSprite2D, delay : float, crossing : float) -> void:
	var fade : float = minf(FADE_SECONDS, crossing * 0.5)
	sprite.modulate.a = 0.0
	var tween := sprite.create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(sprite, "modulate:a", 1.0, fade)
	tween.tween_interval(crossing - 2.0 * fade)
	tween.tween_property(sprite, "modulate:a", 0.0, fade)


func _finish_actor(sprite : AnimatedSprite2D) -> void:
	_active_sprites.erase(sprite)
	sprite.queue_free()
