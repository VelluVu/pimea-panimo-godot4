class_name Bartender
extends Node2D

## Plays idle and serve animations behind the bar; world sounds pan by distance to him.

const ANIM_IDLE : StringName = &"idle"
const ANIM_IDLE_SHOULDERS : StringName = &"idle_shoulders"
const ANIM_IDLE_WIPE : StringName = &"idle_wipe"
const ANIM_SERVE_BEER : StringName = &"serve_beer"
const SOLO_POUR_SPEED_SCALE : float = 1.4
## One-shot idles picked by weight, so standing still stays common.
const IDLE_ANIMS : Array[StringName] = [ANIM_IDLE, ANIM_IDLE_SHOULDERS, ANIM_IDLE_WIPE]
const IDLE_WEIGHTS : Array[float] = [3.0, 2.0, 1.0]

## Found by group: there is only one.
const BARTENDER_GROUP : StringName = &"bartender"

@onready var animated_sprite : AnimatedSprite2D = $AnimatedSprite2D
## His hands, where the counter glass starts its slide.
@onready var serve_marker : Marker2D = $ServeMarker

## A group's round piles up left of serve_marker in rows of STACK_ROW_SIZE.
const STACK_ROW_SIZE : int = 4
const STACK_BASE_OFFSET_PX : Vector2 = Vector2(-20, 5)
const STACK_COLUMN_OFFSET_PX : Vector2 = Vector2(-7, 0)
const STACK_ROW_OFFSET_PX : Vector2 = Vector2(0, -6)

const TAP_SLIDE_SECONDS : float = 0.25
## The tap hand's x in the 48 px serve_beer frame, lined up with the spout. Tuned by eye.
const POUR_STREAM_FRAME_X : float = 32.75

## As drawn, for pours with no known beer.
var _drawn_frames : SpriteFrames
var _serve_durations : PackedFloat32Array = []
var _home_x : float = 0.0
var _slide : Tween
## Pours waiting for the running one, each [speed_scale, ebc, tap_offset].
var _pour_queue : Array[Array] = []


func _ready() -> void:
	add_to_group(BARTENDER_GROUP)
	var listener := AudioListener2D.new()
	add_child(listener)
	listener.make_current()
	_drawn_frames = animated_sprite.sprite_frames
	for i : int in _drawn_frames.get_frame_count(ANIM_SERVE_BEER):
		_serve_durations.append(_drawn_frames.get_frame_duration(ANIM_SERVE_BEER, i))
	_home_x = position.x
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.play(ANIM_IDLE)


func _play_random_idle() -> void:
	animated_sprite.play(WeightedPicker.pick(IDLE_ANIMS, IDLE_WEIGHTS) as StringName)


## How far from home he slides for his pour to fall at `global_x`.
func offset_to_pour_at(global_x : float) -> float:
	var stream_from_origin : float = animated_sprite.position.x + (POUR_STREAM_FRAME_X + animated_sprite.offset.x) * animated_sprite.scale.x
	return global_x - (get_parent().to_global(Vector2(_home_x, 0.0)).x + stream_from_origin * global_scale.x)


## Pours after the queued ones and returns the seconds until this pour ends. A negative
## `ebc` pours as drawn; `tap_offset` slides him to the tap.
func play_serve_beer(speed_scale: float = 1.0, ebc: int = -1, tap_offset: float = 0.0) -> float:
	if _is_pouring():
		# A group's burst hurries the pour its own sale started.
		animated_sprite.speed_scale = maxf(animated_sprite.speed_scale, speed_scale)
		_pour_queue.append([speed_scale, ebc, tap_offset])
	else:
		_start_pour(speed_scale, ebc, tap_offset)
	return pours_left_seconds()


## Seconds until the running and queued pours are done.
func pours_left_seconds() -> float:
	if not _is_pouring():
		return 0.0
	var queued_speeds : Array[float] = []
	for pour : Array in _pour_queue:
		queued_speeds.append(pour[0])
	return PourTiming.seconds_left(_serve_durations, _serve_fps(), animated_sprite.speed_scale, animated_sprite.frame, animated_sprite.frame_progress, queued_speeds)


func _is_pouring() -> bool:
	return animated_sprite.animation == ANIM_SERVE_BEER and animated_sprite.is_playing()


func _start_pour(speed_scale: float, ebc: int, tap_offset: float) -> void:
	_slide_to(_home_x + tap_offset)
	animated_sprite.sprite_frames = _drawn_frames if ebc < 0 else BeerColor.pour_sprite_frames(_drawn_frames, ebc)
	animated_sprite.speed_scale = speed_scale
	animated_sprite.stop()
	animated_sprite.play(ANIM_SERVE_BEER)
	BrewerySignals.beer_poured.emit(serve_marker.global_position, speed_scale)


func serve_seconds(speed_scale : float) -> float:
	return PourTiming.full_seconds(_serve_durations, _serve_fps(), speed_scale)


func _serve_fps() -> float:
	return _drawn_frames.get_animation_speed(ANIM_SERVE_BEER)


func _on_animation_finished() -> void:
	if animated_sprite.animation == ANIM_SERVE_BEER:
		if not _pour_queue.is_empty():
			var pour : Array = _pour_queue.pop_front()
			_start_pour(pour[0], pour[1], pour[2])
			return
		animated_sprite.speed_scale = 1.0
		_slide_to(_home_x)
	_play_random_idle()


func _slide_to(x : float) -> void:
	if is_equal_approx(position.x, x):
		return
	if _slide != null:
		_slide.kill()
	_slide = create_tween()
	var target : Vector2 = get_parent().to_global(Vector2(x, position.y))
	PixelStepTween.move(_slide, self, global_position, target, TAP_SLIDE_SECONDS, animated_sprite.scale.x).set_trans(Tween.TRANS_SINE)


## Global position of the Nth glass in a group order's counter stack.
func get_stack_position(index: int) -> Vector2:
	var column := index % STACK_ROW_SIZE
	@warning_ignore("integer_division")
	var row := index / STACK_ROW_SIZE
	return serve_marker.global_position + STACK_BASE_OFFSET_PX + STACK_COLUMN_OFFSET_PX * column + STACK_ROW_OFFSET_PX * row
