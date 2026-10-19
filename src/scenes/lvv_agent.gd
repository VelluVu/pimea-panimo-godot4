class_name LvvAgent
extends Node2D

## One LVV raider: walks the spawner's waypoints to the warehouse, seizes a keg and walks
## back. Each leg's animation follows its direction, so markers move freely.

signal raid_sequence_finished

const ANIM_IDLE_UP : StringName = &"idle_up"
const ANIM_WALK_TOWARDS : StringName = &"walk_towards"
const ANIM_WALK_RIGHT : StringName = &"walk_right"
const ANIM_WALK_AWAY : StringName = &"walk_away"

## Same pace as CustomerData's defaults, so the squad matches ordinary foot traffic.
const STAIR_STEP_DURATION : float = 0.3
const FLOOR_WALK_SPEED : float = 120.0
const STAIR_STEPS : int = 15

## How long the agent stands at the pickup spot before turning back.
const PICKUP_PAUSE_SECONDS : float = 1.0

const KEG_SCENE : PackedScene = preload("res://src/scenes/keg.tscn")
## A carried keg is the same prop as one on the ground, so it renders at the same size.
const CARRIED_KEG_SCALE : float = 1.0

@onready var animated_sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var carry_marker : Marker2D = $CarryMarker

var _carried_keg : Node2D = null
var _route_tween : Tween


func _play_animation(anim_name : StringName, flip_horizontally : bool = false) -> void:
	if animated_sprite.sprite_frames == null or not animated_sprite.sprite_frames.has_animation(anim_name):
		return
	animated_sprite.flip_h = flip_horizontally
	animated_sprite.play(anim_name)
	_update_carried_keg_z_index(anim_name)


## The keg is in front of the agent unless they face away (climbing back up); z_index beats
## y-sort here.
func _update_carried_keg_z_index(anim_name : StringName) -> void:
	if not is_instance_valid(_carried_keg) or not _carried_keg.visible:
		return
	if anim_name == ANIM_WALK_AWAY or anim_name == ANIM_IDLE_UP:
		_carried_keg.z_index = -1
	else:
		_carried_keg.z_index = 1


## Walks `waypoints` (global, [0] is the stairs bottom), seizes a keg at the last and walks
## back out with it. A loaded raid skips `elapsed_seconds`.
func walk_in_and_seize(waypoints : Array[Vector2], elapsed_seconds : float = 0.0) -> void:
	var tween := create_tween()
	_route_tween = tween
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

	# The return climb uses walk_away, which has no Customer equivalent.
	tween.tween_callback(_play_animation.bind(ANIM_WALK_AWAY, false))
	_tween_stairs(tween, waypoints[0], spawn_pos)

	tween.tween_callback(raid_sequence_finished.emit)
	tween.tween_callback(queue_free)
	if elapsed_seconds > 0.0:
		tween.custom_step(elapsed_seconds)


## Seconds walked of the route so far, for the save.
func elapsed_seconds() -> float:
	return _route_tween.get_total_elapsed_time() if _route_tween != null else 0.0


## walk_towards or walk_away for a mostly vertical leg, walk_right (flipped) for a
## horizontal one; from the two positions only, so any waypoint works both ways.
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
	PixelStepTween.move(tween, self, from_pos, to_pos, from_pos.distance_to(to_pos) / FLOOR_WALK_SPEED, animated_sprite.scale.x)


func _tween_stairs(tween : Tween, from_pos : Vector2, to_pos : Vector2) -> void:
	var step_from := from_pos
	for i in range(1, STAIR_STEPS + 1):
		var step_pos := from_pos.lerp(to_pos, float(i) / STAIR_STEPS)
		PixelStepTween.move(tween, self, step_from, step_pos, STAIR_STEP_DURATION, animated_sprite.scale.x)
		tween.tween_interval(0.05)
		step_from = step_pos


## Parented under carry_marker but hidden until the agent turns to walk it out.
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
		# y-sort puts CarryMarker behind the sprite, so z_index sets the keg's side instead.
		_update_carried_keg_z_index(animated_sprite.animation)
