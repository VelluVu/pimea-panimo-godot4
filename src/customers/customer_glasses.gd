class_name CustomerGlasses
extends RefCounted

## A customer's two glasses: the one the bartender slides along the counter and the one
## carried out in hand, both filled with the colour of the beer bought.

## How long a just-served glass waits before it appears; matches Bartender's serve_beer
## animation (2.0s) so the glass comes once the pour has finished.
const SERVE_WAIT_SECONDS : float = 2.0
const SLIDE_DURATION_SECONDS : float = 0.6

## The EBC of the beer bought; -1 while nothing was.
var beer_ebc : int = -1

var _owner : Node2D
var _hand : Sprite2D
var _counter : Sprite2D
## The glass as drawn, before fill() colours its beer.
var _empty_texture : Texture2D
var _serve_timer : SceneTreeTimer


func _init(owner : Node2D, hand : Sprite2D, counter : Sprite2D) -> void:
	_owner = owner
	_hand = hand
	_counter = counter
	_empty_texture = hand.texture


## Colours both glasses' beer. A negative `ebc` (nothing sold) leaves them as drawn.
func fill(ebc : int) -> void:
	beer_ebc = ebc
	if ebc < 0 or _empty_texture == null:
		return
	var filled : Texture2D = BeerColor.glass_texture(_empty_texture, ebc)
	_hand.texture = filled
	_counter.texture = filled


func hand_texture() -> Texture2D:
	return _hand.texture


func show_in_hand() -> void:
	_hand.show()


## The counter glass comes after `seconds`, once the bartender has poured.
func serve_after(seconds : float = SERVE_WAIT_SECONDS) -> void:
	_serve_timer = _owner.get_tree().create_timer(seconds)
	_serve_timer.timeout.connect(slide_to_counter)


## Seconds until the counter glass comes, or -1 when it is not on its way.
func serve_time_left() -> float:
	return _serve_timer.time_left if _serve_timer != null and _serve_timer.time_left > 0.0 else -1.0


func is_on_counter() -> bool:
	return _counter.visible


func counter_position() -> Vector2:
	return _counter.position


## Slides the glass from the bartender to its spot on the counter (or pops it in with no
## Bartender). top_level keeps it put if the customer walks. A rest_position_override
## (global, Vector2.INF for none) puts it in the bartender's stack for group orders.
func slide_to_counter(slide_duration_seconds : float = SLIDE_DURATION_SECONDS, rest_position_override : Vector2 = Vector2.INF) -> void:
	var rest_position : Vector2 = rest_position_override if rest_position_override != Vector2.INF else _owner.to_global(_counter.position)
	var bartender := _owner.get_tree().get_first_node_in_group(Bartender.BARTENDER_GROUP) as Bartender

	_counter.top_level = true

	if bartender == null:
		_counter.position = rest_position
		_counter.show()
		return

	_counter.position = bartender.serve_marker.global_position
	_counter.show()

	var tween := _owner.create_tween()
	tween.tween_property(_counter, "position", rest_position, slide_duration_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func hide_counter() -> void:
	_counter.hide()
	_counter.top_level = false
