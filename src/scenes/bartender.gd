class_name Bartender
extends Node2D

## Stands behind the bar playing idle and serve animations; never walks. World sounds pan
## and fade by their distance to him.

const ANIM_IDLE : StringName = &"idle"
const ANIM_IDLE_SHOULDERS : StringName = &"idle_shoulders"
const ANIM_IDLE_WIPE : StringName = &"idle_wipe"
const ANIM_SERVE_BEER : StringName = &"serve_beer"
## Each idle is a one-shot; the next is picked by weight, so standing still stays common.
const IDLE_ANIMS : Array[StringName] = [ANIM_IDLE, ANIM_IDLE_SHOULDERS, ANIM_IDLE_WIPE]
const IDLE_WEIGHTS : Array[float] = [3.0, 2.0, 1.0]

## There is only one Bartender, so Customer finds him by group instead of a reference
## threaded through main.gd.
const BARTENDER_GROUP : StringName = &"bartender"

@onready var animated_sprite : AnimatedSprite2D = $AnimatedSprite2D
## Where the counter glass starts its slide: his hands. A marker, movable on its own.
@onready var serve_marker : Marker2D = $ServeMarker

## A group's round piles up left of serve_marker, wrapping every STACK_ROW_SIZE glasses.
const STACK_ROW_SIZE : int = 4
const STACK_BASE_OFFSET_PX : Vector2 = Vector2(-20, 5)
const STACK_COLUMN_OFFSET_PX : Vector2 = Vector2(-7, 0)
const STACK_ROW_OFFSET_PX : Vector2 = Vector2(0, -6)

## Short, so the pour keeps its timing with the customer's glass.
const TAP_SLIDE_SECONDS : float = 0.25
## Where the hand that pulls the tap is in the serve_beer frames (x in the 48 px frame);
## this point goes to the spout. Tuned by eye in the game.
const POUR_STREAM_FRAME_X : float = 32.75

## The frames as drawn, kept for pours with no known beer.
var _drawn_frames : SpriteFrames
## Where he stands when not pouring.
var _home_x : float = 0.0
var _slide : Tween


func _ready() -> void:
	add_to_group(BARTENDER_GROUP)
	var listener := AudioListener2D.new()
	add_child(listener)
	listener.make_current()
	_drawn_frames = animated_sprite.sprite_frames
	_home_x = position.x
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.play(ANIM_IDLE)


func _play_random_idle() -> void:
	animated_sprite.play(WeightedPicker.pick(IDLE_ANIMS, IDLE_WEIGHTS) as StringName)


## How far from home he must slide for his pour to fall at `global_x` (a tap's spout).
func offset_to_pour_at(global_x : float) -> float:
	var stream_from_origin : float = animated_sprite.position.x + (POUR_STREAM_FRAME_X + animated_sprite.offset.x) * animated_sprite.scale.x
	return global_x - (get_parent().to_global(Vector2(_home_x, 0.0)).x + stream_from_origin * global_scale.x)


## Plays the serve animation, then idles. speed_scale speeds up a group's pours; a negative
## `ebc` pours as drawn; `tap_offset` slides him to the tap.
func play_serve_beer(speed_scale: float = 1.0, ebc: int = -1, tap_offset: float = 0.0) -> void:
	_slide_to(_home_x + tap_offset)
	animated_sprite.sprite_frames = _drawn_frames if ebc < 0 else BeerColor.pour_sprite_frames(_drawn_frames, ebc)
	animated_sprite.speed_scale = speed_scale
	animated_sprite.play(ANIM_SERVE_BEER)
	BrewerySignals.beer_poured.emit(serve_marker.global_position, speed_scale)


func _on_animation_finished() -> void:
	if animated_sprite.animation == ANIM_SERVE_BEER:
		animated_sprite.speed_scale = 1.0
		_slide_to(_home_x)
	_play_random_idle()


func _slide_to(x : float) -> void:
	if is_equal_approx(position.x, x):
		return
	if _slide != null:
		_slide.kill()
	_slide = create_tween()
	_slide.tween_property(self, "position:x", x, TAP_SLIDE_SECONDS).set_trans(Tween.TRANS_SINE)


## Global position of the Nth glass in a group order's counter stack.
func get_stack_position(index: int) -> Vector2:
	var column := index % STACK_ROW_SIZE
	@warning_ignore("integer_division")
	var row := index / STACK_ROW_SIZE
	return serve_marker.global_position + STACK_BASE_OFFSET_PX + STACK_COLUMN_OFFSET_PX * column + STACK_ROW_OFFSET_PX * row
