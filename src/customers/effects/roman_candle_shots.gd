class_name RomanCandleShots
extends Node2D

## The Örveltäjä's roman candles: volleys of stars (RomanCandleStar), the two candles taking
## turns, each star launched from its candle's mouth as the sheet draws it on that frame
## (make_orveltaja.py), so it leaves the tube on the same art pixel even mid-step.

## Head, shade and darkest of each star colour, from the cast's ENDESGA 32 palette.
const RAMPS : Array = [
	[Color("fee761"), Color("feae34"), Color("f77622")],
	[Color("e43b44"), Color("a22633"), Color("68386c")],
	[Color("2ce8f5"), Color("0099db"), Color("124e89")],
	[Color("63c74d"), Color("3e8948"), Color("265c42")],
	[Color("f6757a"), Color("b55088"), Color("68386c")],
]
## Left and right candle mouths in art pixels from the feet, on an unraised frame: the
## top left of the 2x2 star sitting just above each 2-wide tube. They sit evenly about the
## middle, so a mirrored walk keeps them.
const MOUTHS : Array[Vector2i] = [Vector2i(-8, -28), Vector2i(6, -28)]
## Rows each mouth rises per frame, [left, right]: the breath and step bobs plus the
## pumped fist.
const RAISES : Dictionary[StringName, Array] = {
	&"idle": [[0, 0], [1, 1], [0, 0]],
	&"idle_up": [[0, 0], [1, 1], [0, 0]],
	&"walk_towards": [[0, 0], [2, 1], [0, 0], [1, 2]],
	&"walk_right": [[0, 0], [2, 1], [0, 0], [1, 2]],
}
const MIN_VOLLEY : int = 2
const MAX_VOLLEY : int = 4
const MIN_SHOT_GAP : float = 0.22
const MAX_SHOT_GAP : float = 0.4
const MIN_PAUSE : float = 0.8
const MAX_PAUSE : float = 2.2
const MIN_RISE_ART_PX : int = 18
const MAX_RISE_ART_PX : int = 30
const MAX_DRIFT_ART_PX : int = 3
const STAR_Z_INDEX : int = 2
const SOUND_BUS : StringName = &"SFX"
## Quiet: a volley pops several times a second.
const POP_VOLUME_DB : float = -14.0
const POP_PITCH : Vector2 = Vector2(0.9, 1.15)

## Played as each star leaves the tube (candle_pop in make_sfx.py).
@export var pop_sound : AudioStream

var _sprite : AnimatedSprite2D
var _pop_player : AudioStreamPlayer
var _wait : float = 0.0
var _shots_left : int = 0
var _side : int = 0


func attach(sprite : AnimatedSprite2D) -> void:
	_sprite = sprite
	_side = randi_range(0, 1)
	if pop_sound != null:
		_pop_player = AudioStreamPlayer.new()
		_pop_player.stream = pop_sound
		_pop_player.bus = SOUND_BUS
		_pop_player.volume_db = POP_VOLUME_DB
		add_child(_pop_player)
	_wait = randf_range(0.0, MAX_PAUSE)


func _process(delta : float) -> void:
	if _sprite == null or not _sprite.is_visible_in_tree():
		return
	_wait -= delta
	if _wait > 0.0:
		return
	if _shots_left <= 0:
		_shots_left = randi_range(MIN_VOLLEY, MAX_VOLLEY)
	_fire(_side)
	_side = 1 - _side
	_shots_left -= 1
	_wait = randf_range(MIN_SHOT_GAP, MAX_SHOT_GAP) if _shots_left > 0 else randf_range(MIN_PAUSE, MAX_PAUSE)


func _fire(side : int) -> void:
	var art : float = _sprite.scale.x
	var mouth : Vector2i = MOUTHS[side] - Vector2i(0, mouth_raise(_sprite.animation, _sprite.frame, side, _sprite.flip_h))
	var ramp : Array[Color] = []
	ramp.assign(RAMPS.pick_random())
	if _pop_player != null:
		_pop_player.pitch_scale = randf_range(POP_PITCH.x, POP_PITCH.y)
		_pop_player.play()
	var star := RomanCandleStar.new()
	star.z_index = STAR_Z_INDEX
	add_child(star)
	# The sprite's own position carries the drunk sway.
	star.launch(_sprite.global_position + Vector2(mouth) * art, ramp,
		randi_range(MIN_RISE_ART_PX, MAX_RISE_ART_PX), randi_range(-MAX_DRIFT_ART_PX, MAX_DRIFT_ART_PX), art)


## How many rows the mouth on `side` (0 left, 1 right on screen) sits above its resting row.
## A mirrored walk shows the right fist on the left.
static func mouth_raise(animation : StringName, frame : int, side : int, mirrored : bool) -> int:
	var frames : Array = RAISES.get(animation, [])
	if frame < 0 or frame >= frames.size():
		return 0
	return frames[frame][1 - side if mirrored else side]
