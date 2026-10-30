class_name CustomerWalker
extends RefCounted

## A customer's walking: the route in down the stairs, which leg of it is under way (for
## the save), and the short walks to a pickup spot and out. The customer picks what happens
## at the end of each walk.

const STAIR_STEPS : int = 15
const STAIR_STEP_PAUSE_SECONDS : float = 0.05
const CENTER_PAUSE_SECONDS : float = 0.8
const MIN_WALK_DISTANCE : float = 1.0

## The legs of the walk in, in order (see start()).
enum Leg { STAIRS, TO_CENTER, CENTER_PAUSE, TO_COUNTER }

## Set by the customer with its data; the walks take their speeds from it.
var data : CustomerData
var route : Array[Vector2] = []  # spawn, stairs bottom, room centre, counter spot
var leg : int = Leg.STAIRS

var _owner : Node2D
var _sprite : AnimatedSprite2D
## (anim_name: StringName, flip_horizontally: bool), the customer's own player.
var _play : Callable
var _pause_seconds : float = CENTER_PAUSE_SECONDS
var _pause_started_msec : int = 0


func _init(owner : Node2D, sprite : AnimatedSprite2D, play : Callable) -> void:
	_owner = owner
	_sprite = sprite
	_play = play


## A fresh walk in from where the customer stands. Add the arrival to the returned tween.
func start(stairs_pos : Vector2, center_pos : Vector2, target_pos : Vector2) -> Tween:
	route = [_owner.global_position, stairs_pos, center_pos, target_pos]
	return walk_route_from(Leg.STAIRS, CENTER_PAUSE_SECONDS)


## Queues the walk from `first_leg` on, from where the customer stands: a fresh visit at the
## top, a loaded one mid-way.
func walk_route_from(first_leg : int, pause_seconds : float) -> Tween:
	var tween := _owner.create_tween()
	var from := _owner.global_position
	if first_leg <= Leg.STAIRS:
		tween.tween_callback(_set_leg.bind(Leg.STAIRS))
		_queue_stair_descent(tween, from, route[1], CustomerRoute.stair_steps_left(route[0], route[1], from, STAIR_STEPS))
		from = route[1]
	if first_leg <= Leg.TO_CENTER:
		tween.tween_callback(_set_leg.bind(Leg.TO_CENTER))
		_queue_floor_walk(tween, from, route[2])
		from = route[2]
	if first_leg <= Leg.CENTER_PAUSE:
		_pause_seconds = pause_seconds
		tween.tween_callback(_set_leg.bind(Leg.CENTER_PAUSE))
		tween.tween_callback(_play.bind(Customer.ANIM_IDLE, false))
		tween.tween_interval(pause_seconds)
	tween.tween_callback(_set_leg.bind(Leg.TO_COUNTER))
	_queue_floor_walk(tween, from, route[3])
	return tween


## What is left of the centre pause, for the save.
func pause_left() -> float:
	if leg != Leg.CENTER_PAUSE:
		return _pause_seconds
	return maxf(0.0, _pause_seconds - (Time.get_ticks_msec() - _pause_started_msec) / 1000.0)


## Short lateral walk, like the walk in's last leg. Returns once there.
func walk_to(target : Vector2) -> void:
	var distance := _owner.global_position.distance_to(target)
	if distance < MIN_WALK_DISTANCE:
		return
	_play.call(Customer.ANIM_WALK_RIGHT, target.x < _owner.global_position.x)
	var tween := _owner.create_tween()
	PixelStepTween.move(tween, _owner, _owner.global_position, target, distance / data.floor_walk_speed, art_pixel())
	await tween.finished


## Walks towards the camera to `exit_position`, speeding up. Add the exit to the returned tween.
func walk_out(exit_position : Vector2) -> Tween:
	var duration := CustomerRoute.seconds_left(_owner.global_position, exit_position, data.floor_walk_speed)
	_play.call(Customer.ANIM_WALK_TOWARDS, true)
	var tween := _owner.create_tween()
	PixelStepTween.move(tween, _owner, _owner.global_position, exit_position, duration, art_pixel()).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	return tween


## One pixel of the scaled-up art: walks step by it, see PixelStepTween.
func art_pixel() -> float:
	return _sprite.scale.x


func _set_leg(new_leg : int) -> void:
	leg = new_leg
	if new_leg == Leg.CENTER_PAUSE:
		_pause_started_msec = Time.get_ticks_msec()


func _queue_stair_descent(tween : Tween, from_pos : Vector2, stairs_pos : Vector2, steps : int) -> void:
	if steps <= 0:
		return
	tween.tween_callback(_play.bind(Customer.ANIM_WALK_TOWARDS, true))
	var step_from := from_pos
	for i in range(1, steps + 1):
		var step_pos := from_pos.lerp(stairs_pos, float(i) / steps)
		PixelStepTween.move(tween, _owner, step_from, step_pos, data.stair_step_duration, art_pixel())
		tween.tween_interval(STAIR_STEP_PAUSE_SECONDS)
		step_from = step_pos


func _queue_floor_walk(tween : Tween, from_pos : Vector2, to_pos : Vector2) -> void:
	tween.tween_callback(_play.bind(Customer.ANIM_WALK_RIGHT, to_pos.x < from_pos.x))
	PixelStepTween.move(tween, _owner, from_pos, to_pos, from_pos.distance_to(to_pos) / data.floor_walk_speed, art_pixel())
