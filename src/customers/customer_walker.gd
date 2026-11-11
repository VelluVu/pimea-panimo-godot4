class_name CustomerWalker
extends RefCounted

## A customer's walking: the route in down the stairs, which leg of it is under way (for
## the save), and the short walks to a pickup spot and out. The customer picks what happens
## at the end of each walk.

const STAIR_STEPS : int = 15
const STAIR_STEP_PAUSE_SECONDS : float = 0.05
const CENTER_PAUSE_SECONDS : float = 0.8
const MIN_WALK_DISTANCE : float = 1.0
## route's index of the room centre, where the walk in pauses.
const ROOM_CENTRE_LEG : int = 2

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
var _stepper : WalkStepper = WalkStepper.new()
## Set for a fresh walk in during winter; a visit loaded mid-way has already stamped.
var _stamps_snow : bool = false
var _snow_cover : SnowCover = null


func _init(owner : Node2D, sprite : AnimatedSprite2D, play : Callable) -> void:
	_owner = owner
	_sprite = sprite
	_play = play


## A fresh walk in from where the customer stands. Add the arrival to the returned tween.
func start(stairs_pos : Vector2, center_pos : Vector2, target_pos : Vector2) -> Tween:
	route = [_owner.global_position, stairs_pos, center_pos, target_pos]
	_stamps_snow = SeasonRules.is_winter_now()
	if _stamps_snow:
		_snow_cover = WinterArrival.cover(_sprite)
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
		tween.tween_callback(_end_steps)
		tween.tween_callback(_play.bind(Customer.ANIM_IDLE, false))
		if _stamps_snow and pause_seconds >= WinterArrival.seconds():
			WinterArrival.queue(tween, _owner, _sprite, _snow_cover, data)
			tween.tween_interval(pause_seconds - WinterArrival.seconds())
		else:
			tween.tween_interval(pause_seconds)
	tween.tween_callback(_set_leg.bind(Leg.TO_COUNTER))
	_queue_floor_walk(tween, from, route[3])
	tween.tween_callback(_end_steps)
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
	_begin_steps(Customer.ANIM_WALK_RIGHT, target.x < _owner.global_position.x, floor_stride())
	var tween := _owner.create_tween()
	PixelStepTween.move(tween, _owner, _owner.global_position, target, distance / data.floor_walk_speed, art_pixel())
	await tween.finished
	_end_steps()


## Walks towards the camera to `exit_position`, speeding up. Add the exit to the returned tween.
func walk_out(exit_position : Vector2, carrying_glass : bool) -> Tween:
	var duration := CustomerRoute.seconds_left(_owner.global_position, exit_position, data.floor_walk_speed)
	var anim_name : StringName = CustomerHandOffsets.walk_out_animation(_sprite.sprite_frames, carrying_glass, Customer.ANIM_WALK_TOWARDS)
	_begin_steps(anim_name, true, floor_stride())
	var tween := _owner.create_tween()
	PixelStepTween.move(tween, _owner, _owner.global_position, exit_position, duration, art_pixel()).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	return tween


## One pixel of the scaled-up art: walks step by it, see PixelStepTween.
func art_pixel() -> float:
	return _sprite.scale.x


## Screen pixels walked per walk frame on the floor.
func floor_stride() -> float:
	return WalkStepper.floor_stride(art_pixel())


## Call every frame: steps the walk frames by the distance moved since the last call.
func tick() -> void:
	_stepper.tick(_sprite, _owner.global_position)


func _begin_steps(anim_name : StringName, flip_horizontally : bool, stride : float) -> void:
	_play.call(anim_name, flip_horizontally)
	_stepper.begin(_sprite, _owner.global_position, stride)


func _end_steps() -> void:
	_stepper.end(_sprite)


func _set_leg(new_leg : int) -> void:
	leg = new_leg
	if new_leg == Leg.CENTER_PAUSE:
		_pause_started_msec = Time.get_ticks_msec()


func _queue_stair_descent(tween : Tween, from_pos : Vector2, stairs_pos : Vector2, steps : int) -> void:
	if steps <= 0:
		return
	tween.tween_callback(_begin_steps.bind(Customer.ANIM_WALK_TOWARDS, true, WalkStepper.stair_stride(from_pos, stairs_pos, steps)))
	var step_from := from_pos
	for i : int in range(1, steps + 1):
		var step_pos := from_pos.lerp(stairs_pos, float(i) / steps)
		PixelStepTween.move(tween, _owner, step_from, step_pos, data.stair_step_duration, art_pixel())
		tween.tween_interval(STAIR_STEP_PAUSE_SECONDS)
		step_from = step_pos


func _queue_floor_walk(tween : Tween, from_pos : Vector2, to_pos : Vector2) -> void:
	tween.tween_callback(_begin_steps.bind(Customer.ANIM_WALK_RIGHT, to_pos.x < from_pos.x, floor_stride()))
	PixelStepTween.move(tween, _owner, from_pos, to_pos, from_pos.distance_to(to_pos) / data.floor_walk_speed, art_pixel())
