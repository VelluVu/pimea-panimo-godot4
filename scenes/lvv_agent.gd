class_name LvvAgent
extends Node2D

## One member of an LVV raid squad (see LvvRaidSpawner) — walks in down the
## stairs, then through however many waypoints LvvRaidSpawner hands it (its
## own Marker2D chain — see route_waypoints there) to line up with and walk
## into the warehouse doorway, grabs a keg, then reverses the exact same
## waypoints back out and climbs the stairs back up and off-screen. Each
## leg's animation/flip is derived from its own direction (see
## _leg_animation_and_flip()) rather than being hardcoded per leg, so
## LvvRaidSpawner's markers can be added, removed, or dragged around in the
## editor without this script needing to change. Mirrors Customer.gd's
## walk_complex_route()/leave_counter() shape (same stairs-leg tween-chain
## style) but simpler: no dialogue, no CustomerData, and the outbound stairs
## leg uses walk_away instead of walk_towards — the one new animation row
## this whole feature exists for.

signal raid_sequence_finished

const ANIM_IDLE_UP : StringName = &"idle_up"
const ANIM_WALK_TOWARDS : StringName = &"walk_towards"
const ANIM_WALK_RIGHT : StringName = &"walk_right"
const ANIM_WALK_AWAY : StringName = &"walk_away"

## Same defaults as CustomerData.stair_step_duration/floor_walk_speed
## (customer_data.gd) — keeps the raid squad's pace visually consistent
## with ordinary customer foot traffic instead of reading as oddly fast
## or sluggish next to them.
const STAIR_STEP_DURATION : float = 0.3
const FLOOR_WALK_SPEED : float = 120.0
const STAIR_STEPS : int = 15

## How long the agent stands at the pickup spot before turning back —
## long enough to read as "picking something up", short enough not to
## drag out a squad of 2-3 doing this one after another.
const PICKUP_PAUSE_SECONDS : float = 1.0

const KEG_SCENE : PackedScene = preload("res://scenes/keg.tscn")
## A carried keg is still the same physical prop as one sitting on the
## ground (keg.tscn's own baked-in Sprite2D scale), so it should render at
## the same absolute size — 1.0 here means "don't shrink it further".
## Previously guessed at 0.6 to avoid looking oversized, but that was never
## actually confirmed visually and just made the carried keg read as a
## noticeably smaller toy-sized can next to the same prop on the ground.
const CARRIED_KEG_SCALE : float = 1.0

@onready var animated_sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var carry_marker : Marker2D = $CarryMarker

var _carried_keg : Node2D = null


func _play_animation(anim_name : StringName, flip_horizontally : bool = false) -> void:
	if animated_sprite.sprite_frames == null or not animated_sprite.sprite_frames.has_animation(anim_name):
		return
	animated_sprite.flip_h = flip_horizontally
	animated_sprite.play(anim_name)
	_update_carried_keg_z_index(anim_name)


## A keg held against the chest is only actually in front of the agent from
## the CAMERA's point of view while the agent is facing the camera
## (walk_towards/idle) or side-on (walk_right) — turned away (walk_away/
## idle_up, e.g. climbing back up the stairs through the warehouse doorway)
## their own body is between the camera and the keg, so it needs to sort
## behind them instead. z_index (not y-sort — see _show_carried_keg()'s own
## comment) still wins here, just flipped negative for the away-facing case.
func _update_carried_keg_z_index(anim_name : StringName) -> void:
	if not is_instance_valid(_carried_keg) or not _carried_keg.visible:
		return
	if anim_name == ANIM_WALK_AWAY or anim_name == ANIM_IDLE_UP:
		_carried_keg.z_index = -1
	else:
		_carried_keg.z_index = 1


## waypoints are global positions walked through IN ORDER after the stairs
## descent (waypoints[0] is where the stairs bottom out) — as many as
## LvvRaidSpawner hands over, e.g. [stairs, lateral-align, doorway, pickup].
## Pauses at the last one to seize a keg (kept hidden — see _seize_keg()),
## then walks every leg back in reverse and climbs the stairs back out,
## revealing the keg the moment the return trip starts (see
## _show_carried_keg()).
func walk_in_and_seize(waypoints : Array[Vector2]) -> void:
	var tween := create_tween()
	var spawn_pos := global_position

	tween.tween_callback(_play_animation.bind(ANIM_WALK_TOWARDS, true))
	_tween_stairs(tween, spawn_pos, waypoints[0])

	for i in range(1, waypoints.size()):
		_tween_leg(tween, waypoints[i - 1], waypoints[i])

	tween.tween_callback(_seize_keg)
	tween.tween_interval(PICKUP_PAUSE_SECONDS)
	tween.tween_callback(_show_carried_keg)

	for i in range(waypoints.size() - 1, 0, -1):
		_tween_leg(tween, waypoints[i], waypoints[i - 1])

	# Back up the stairs and off-screen — walk_away, not walk_towards: this
	# is the one leg that has no equivalent in Customer.gd at all.
	tween.tween_callback(_play_animation.bind(ANIM_WALK_AWAY, false))
	_tween_stairs(tween, waypoints[0], spawn_pos)

	tween.tween_callback(raid_sequence_finished.emit)
	tween.tween_callback(queue_free)


## Picks walk_towards/walk_away for a mostly-vertical leg (matching the
## direction of travel — towards camera on increasing Y, away on
## decreasing Y, same convention Customer.gd's stairs legs use) or
## walk_right for a mostly-horizontal one, flipped to face the direction
## actually being walked. Driven purely by the two positions, so it keeps
## working correctly no matter how LvvRaidSpawner's route_waypoints get
## reordered, added to, or dragged around — including the reverse trip,
## which just calls this with from/to swapped.
func _tween_leg(tween : Tween, from_pos : Vector2, to_pos : Vector2) -> void:
	var delta := to_pos - from_pos
	var anim_name : StringName
	var flip_h : bool

	if absf(delta.y) > absf(delta.x):
		if delta.y > 0.0:
			anim_name = ANIM_WALK_TOWARDS
			flip_h = true
		else:
			anim_name = ANIM_WALK_AWAY
			flip_h = false
	else:
		anim_name = ANIM_WALK_RIGHT
		flip_h = delta.x < 0.0

	tween.tween_callback(_play_animation.bind(anim_name, flip_h))
	tween.tween_property(self, "global_position", to_pos, from_pos.distance_to(to_pos) / FLOOR_WALK_SPEED).set_trans(Tween.TRANS_LINEAR)


func _tween_stairs(tween : Tween, from_pos : Vector2, to_pos : Vector2) -> void:
	for i in range(1, STAIR_STEPS + 1):
		var step_pos := from_pos.lerp(to_pos, float(i) / STAIR_STEPS)
		tween.tween_property(self, "global_position", step_pos, STAIR_STEP_DURATION).set_trans(Tween.TRANS_LINEAR)
		tween.tween_interval(0.05)


## Instanced (and parented under carry_marker) here so it's already riding
## along on this agent for the rest of the sequence, but hidden until
## _show_carried_keg() — the keg shouldn't be visibly in-hand until the
## agent actually turns around to walk it back out.
func _seize_keg() -> void:
	_play_animation(ANIM_IDLE_UP)
	_carried_keg = KEG_SCENE.instantiate()
	carry_marker.add_child(_carried_keg)
	_carried_keg.position = Vector2.ZERO
	_carried_keg.scale = Vector2(CARRIED_KEG_SCALE, CARRIED_KEG_SCALE)
	_carried_keg.visible = false


func _show_carried_keg() -> void:
	if is_instance_valid(_carried_keg):
		_carried_keg.visible = true
		# LvvAgent has y_sort_enabled on, which sorts AnimatedSprite2D and
		# CarryMarker (its two direct children) by node position — since
		# CarryMarker sits well above the agent's feet (chest height), it
		# sorts as "further back" than AnimatedSprite2D and gets drawn
		# behind the character's own body, hiding the keg entirely despite
		# visible being true. z_index takes priority over y-sort, so
		# _update_carried_keg_z_index() forces it in front (or behind, while
		# facing away) instead of leaving it to that ordering. Still facing
		# idle_up (from _seize_keg()) at this exact moment, so this picks up
		# the correct starting side before the first return leg's own
		# _play_animation() call takes over.
		_update_carried_keg_z_index(animated_sprite.animation)
