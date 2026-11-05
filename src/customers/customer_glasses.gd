class_name CustomerGlasses
extends RefCounted

## A customer's two glasses: the one the bartender slides along the counter and the one
## carried out in hand, both filled with the colour of the beer bought.

const SLIDE_DURATION_SECONDS : float = 0.4

## The EBC of the beer bought; -1 while nothing was.
var beer_ebc : int = -1

var _owner : Node2D
var _hand : Sprite2D
var _counter : Sprite2D
## The counter glass's spot on its customer, where it rests while not served.
var _counter_home : Vector2
## The glass as drawn, before fill() colours its beer.
var _empty_texture : Texture2D
var _serve_timer : SceneTreeTimer
## True once carry_instead() put the customer's own item in hand: fill() leaves it as drawn.
var _carries_item : bool = false


func _init(owner : Node2D, hand : Sprite2D, counter : Sprite2D) -> void:
	_owner = owner
	_hand = hand
	_counter = counter
	_counter_home = counter.position
	_empty_texture = hand.texture


## Colours both glasses' beer. A negative `ebc` (nothing sold) leaves them as drawn.
func fill(ebc : int) -> void:
	beer_ebc = ebc
	if ebc < 0 or _empty_texture == null:
		return
	var filled : Texture2D = BeerColor.glass_texture(_empty_texture, ebc)
	if not _carries_item:
		_hand.texture = filled
	_counter.texture = filled


## Carries `item` out instead of the glass (a bucket of bottles), at `pixel_scale` so its
## pixels match the customer's sprite.
func carry_instead(item : Texture2D, pixel_scale : Vector2) -> void:
	_carries_item = true
	_hand.texture = item
	_hand.scale = pixel_scale


func hand_texture() -> Texture2D:
	return _hand.texture


func show_in_hand() -> void:
	_hand.show()


## The counter glass comes after `seconds`, by default when the bartender's pours end.
func serve_after(seconds : float = -1.0) -> void:
	if seconds < 0.0:
		var bartender := _owner.get_tree().get_first_node_in_group(Bartender.BARTENDER_GROUP) as Bartender
		seconds = bartender.pours_left_seconds() if bartender != null else 0.0
	# Pauses with the bartender's pour.
	_serve_timer = _owner.get_tree().create_timer(seconds, false)
	_serve_timer.timeout.connect(slide_to_counter)


## Seconds until the counter glass comes, or -1 when it is not on its way.
func serve_time_left() -> float:
	return _serve_timer.time_left if _serve_timer != null and _serve_timer.time_left > 0.0 else -1.0


func is_on_counter() -> bool:
	return _counter.visible


## Global, as slide_to_counter() takes it back on a resume.
func counter_position() -> Vector2:
	return _counter.global_position


## Slides the glass from the bartender to the counter (or pops it in with no Bartender). A
## rest_position_override (global) puts it in a group's stack.
func slide_to_counter(slide_duration_seconds : float = SLIDE_DURATION_SECONDS, rest_position_override : Vector2 = Vector2.INF) -> void:
	var rest_position : Vector2 = rest_position_override if rest_position_override != Vector2.INF else _owner.to_global(_counter_home)
	var bartender := _owner.get_tree().get_first_node_in_group(Bartender.BARTENDER_GROUP) as Bartender

	_move_to_stage()

	if bartender == null:
		_counter.global_position = rest_position
		_counter.show()
		return

	_counter.global_position = bartender.serve_marker.global_position
	_counter.show()

	var tween := _owner.create_tween()
	PixelStepTween.move_property(tween, _counter, &"global_position", _counter.global_position, rest_position, slide_duration_seconds, _counter.scale.x).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func hide_counter() -> void:
	_counter.hide()
	if _counter.get_parent() != _owner:
		_counter.reparent(_owner)
	_counter.position = _counter_home


## On the counter the glass leaves its customer for the customers' parent (the spawner),
## which y-sorts them: there it sorts behind everyone standing in front of the counter, and
## the spawner's z keeps it above the counter decor. As a child of its customer it drew
## over them. It goes when its customer does.
func _move_to_stage() -> void:
	var stage : Node = _owner.get_parent()
	if stage == null or _counter.get_parent() == stage:
		return
	_counter.reparent(stage)
	if not _owner.tree_exiting.is_connected(_drop_counter):
		_owner.tree_exiting.connect(_drop_counter)


func _drop_counter() -> void:
	if is_instance_valid(_counter) and _counter.get_parent() != _owner:
		_counter.queue_free()
