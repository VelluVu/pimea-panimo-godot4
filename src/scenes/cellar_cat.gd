class_name CellarCat
extends Node2D

## The adopted cellar cat (Tikru) lives in the cellar: he sits, naps, grooms, stretches,
## wanders the Routes between the Spots, peeks into the brewery and the warehouse, and goes
## after the pests the ImmersionEventSpawner lets loose. CellarCatRules decides what comes next.

const BASE_SCALE : float = 3.0
const FADE_SECONDS : float = 0.6
## Chance of a meow when he wakes with a stretch or arrives for the first time.
const MEOW_CHANCE : float = 0.5
## Re-pick the chase walk (back or side view) this often, not every frame, so it doesn't flicker.
const CHASE_TURN_SECONDS : float = 0.25

@export var meows : Array[AudioStream] = []

@onready var _sprite : AnimatedSprite2D = %Sprite
@onready var _routes : Node2D = %Routes
@onready var _rest_spots : Node2D = %Spots
@onready var _peek_spots : Node2D = %PeekSpots
@onready var _entry : Marker2D = %Entry
@onready var _act_timer : Timer = %ActTimer
@onready var _meow_player : AudioStreamPlayer2D = %MeowPlayer

var _graph : CatRouteGraph
var _act : CellarCatRules.Act = CellarCatRules.Act.SIT
var _destination : CellarCatRules.Destination = CellarCatRules.Destination.REST
var _spot : int = -1

# The walk under way: route points, the leg being walked and the unsnapped position.
var _path : PackedVector2Array = PackedVector2Array()
var _leg : int = 0
var _leg_from : Vector2 = Vector2.ZERO
var _exact : Vector2 = Vector2.ZERO
var _speed_factor : float = 1.0
var _on_arrival : Callable = Callable()

# A pest reaction: the critter chased, where he left from, and the time left.
var _reacting : bool = false
## Bumped by every reaction, so a watch timer left from an older one ends nothing.
var _reaction_id : int = 0
var _pest : AnimatedSprite2D = null
var _home : Vector2 = Vector2.ZERO
var _chase_left : float = 0.0
var _react_wait : float = 0.0
var _turn_wait : float = 0.0


func _ready() -> void:
	hide()
	_routes.hide()
	_graph = CatRouteGraph.new(_route_polylines())
	_act_timer.timeout.connect(_on_act_done)
	_sprite.animation_finished.connect(_on_act_done)
	BrewerySignals.cellar_cat_adopted.connect(_on_adopted)
	BrewEngine.brewery_changed.connect(_on_brewery_changed)
	_connect_pests.call_deferred()
	_on_brewery_changed(BrewEngine.current_brewery)


func _process(delta : float) -> void:
	if not visible:
		return
	_sprite.scale = Vector2.ONE * VignettePath.pixel_scale(BASE_SCALE, _sprite.global_position.y)
	_sprite.z_index = CellarCatRules.z_index_at(_sprite.global_position.y)
	if _pest != null:
		_chase(delta)
	elif not _path.is_empty():
		_walk(delta)


# --- the season -----------------------------------------------------------------------------

## A loaded season with the cat finds him at one of his spots; a new season has no cat.
func _on_brewery_changed(brewery : Brewery) -> void:
	_cancel_reaction()
	_stop()
	if brewery == null or not brewery.cellar_cat_adopted:
		hide()
		return
	_spot = CellarCatRules.next_spot(_rest_spots.get_child_count(), -1, randf())
	_place(_marker_position(_rest_spots, _spot))
	_sprite.modulate.a = 1.0
	show()
	_begin(CellarCatRules.Act.SIT)


## Just adopted: he comes in from the entry and picks a spot.
func _on_adopted() -> void:
	_cancel_reaction()
	_stop()
	_spot = -1
	_place(_entry.global_position)
	_sprite.modulate.a = 0.0
	show()
	create_tween().tween_property(_sprite, "modulate:a", 1.0, FADE_SECONDS)
	_maybe_meow(1.0)
	_walk_to_destination(CellarCatRules.Destination.REST)


# --- acts -------------------------------------------------------------------------------------

func _begin(act : CellarCatRules.Act) -> void:
	_stop()
	_act = act
	if act == CellarCatRules.Act.WALK:
		var kind : CellarCatRules.Destination = CellarCatRules.destination(randf())
		# After a peek inside he comes back out to a resting spot.
		_walk_to_destination(CellarCatRules.Destination.REST if _destination == CellarCatRules.Destination.PEEK else kind)
		return
	_sprite.play(CellarCatRules.animation(act))
	if act == CellarCatRules.Act.STRETCH:
		_maybe_meow(MEOW_CHANCE)
	if CellarCatRules.loops(act):
		_act_timer.start(CellarCatRules.act_seconds(act, randf()))


## The act timer or a one-shot animation ended.
func _on_act_done() -> void:
	if not visible or _reacting:
		return
	_begin(CellarCatRules.next_act(_act, randf()))


func _walk_to_destination(kind : CellarCatRules.Destination) -> void:
	_act = CellarCatRules.Act.WALK
	_destination = kind
	var target : Vector2
	match kind:
		CellarCatRules.Destination.PEEK:
			target = _marker_position(_peek_spots, randi() % _peek_spots.get_child_count())
		CellarCatRules.Destination.ROAM:
			target = _graph.point(randi() % _graph.point_count())
		_:
			_spot = CellarCatRules.next_spot(_rest_spots.get_child_count(), _spot, randf())
			target = _marker_position(_rest_spots, _spot)
	_follow(_graph.path(_sprite.global_position, target), 1.0, _on_destination_reached)


func _on_destination_reached() -> void:
	if _destination == CellarCatRules.Destination.PEEK:
		_begin(CellarCatRules.Act.PEEK)
	else:
		_on_act_done()


# --- walking ----------------------------------------------------------------------------------

func _follow(points : PackedVector2Array, speed_factor : float, on_arrival : Callable) -> void:
	_path = points
	_leg = 0
	_speed_factor = speed_factor
	_on_arrival = on_arrival
	_exact = _sprite.global_position
	_next_leg()


func _next_leg() -> void:
	_leg += 1
	if _leg >= _path.size():
		_path = PackedVector2Array()
		_sprite.speed_scale = 1.0
		_on_arrival.call()
		return
	_leg_from = _exact
	_face(_path[_leg] - _leg_from)


func _walk(delta : float) -> void:
	var target : Vector2 = _path[_leg]
	_exact = _exact.move_toward(target, CellarCatRules.walk_speed(_sprite.scale.x) * _speed_factor * delta)
	_sprite.global_position = PixelStepTween.snapped_on_path(_leg_from, target, _exact, _sprite.scale.x)
	if _exact.is_equal_approx(target):
		_next_leg()


## The walk that shows the way he heads, mirrored when he heads right (the art faces left).
func _face(direction : Vector2) -> void:
	if not is_zero_approx(direction.x):
		_sprite.flip_h = direction.x > 0.0
	_sprite.play(CellarCatRules.walk_animation(direction))
	_sprite.speed_scale = _speed_factor


func _place(at : Vector2) -> void:
	_exact = at
	_sprite.global_position = at.round()


func _stop() -> void:
	_act_timer.stop()
	_path = PackedVector2Array()
	_sprite.speed_scale = 1.0
	_sprite.stop()


# --- pests ------------------------------------------------------------------------------------

func _connect_pests() -> void:
	var spawner := get_tree().get_first_node_in_group(ImmersionEventSpawner.IMMERSION_EVENT_SPAWNER_GROUP) as ImmersionEventSpawner
	if spawner != null:
		spawner.pest_appeared.connect(_on_pest_appeared)


## A critter on the floor gets chased from wherever he is, then he walks back; one in the air
## he sits and watches. One pest at a time.
func _on_pest_appeared(pest : AnimatedSprite2D, flying : bool) -> void:
	if not visible or _reacting:
		return
	_stop()
	_reacting = true
	_reaction_id += 1
	_home = _sprite.global_position
	if flying:
		_sprite.flip_h = pest.global_position.x > _sprite.global_position.x
		_sprite.play(CellarCatRules.animation(CellarCatRules.Act.SIT))
		var watch : float = randf_range(CellarCatRules.WATCH_SECONDS.x, CellarCatRules.WATCH_SECONDS.y)
		get_tree().create_timer(watch).timeout.connect(_end_reaction.bind(_reaction_id))
		return
	_pest = pest
	_chase_left = CellarCatRules.CHASE_MAX_SECONDS
	_react_wait = CellarCatRules.CHASE_REACT_SECONDS
	_turn_wait = 0.0
	_sprite.play(CellarCatRules.animation(CellarCatRules.Act.SIT))


func _chase(delta : float) -> void:
	if not is_instance_valid(_pest) or _chase_left <= 0.0:
		_give_up_chase()
		return
	if not _pest.visible:
		return
	_react_wait -= delta
	if _react_wait > 0.0:
		return
	_chase_left -= delta
	var target : Vector2 = CellarCatRules.chase_target(_pest.global_position)
	_turn_wait -= delta
	if _turn_wait <= 0.0:
		_turn_wait = CHASE_TURN_SECONDS
		_speed_factor = CellarCatRules.CHASE_SPEED_FACTOR
		_face(target - _exact)
	var step : float = CellarCatRules.walk_speed(_sprite.scale.x) * CellarCatRules.CHASE_SPEED_FACTOR * delta
	_exact = _exact.move_toward(target, step)
	_sprite.global_position = (_exact / _sprite.scale.x).round() * _sprite.scale.x


func _give_up_chase() -> void:
	_pest = null
	_follow(_graph.path(_exact, _home), 1.0, _end_reaction.bind(_reaction_id))


func _end_reaction(reaction_id : int) -> void:
	if not _reacting or reaction_id != _reaction_id:
		return
	_reacting = false
	_begin(CellarCatRules.Act.SIT)


func _cancel_reaction() -> void:
	_reacting = false
	_pest = null


# --- helpers ----------------------------------------------------------------------------------

func _route_polylines() -> Array[PackedVector2Array]:
	var polylines : Array[PackedVector2Array] = []
	for child : Node in _routes.get_children():
		var line := child as Line2D
		if line == null:
			continue
		var points := PackedVector2Array()
		for local : Vector2 in line.points:
			points.append(line.to_global(local))
		polylines.append(points)
	return polylines


func _marker_position(parent : Node2D, index : int) -> Vector2:
	return (parent.get_child(index) as Node2D).global_position


func _maybe_meow(chance : float) -> void:
	if meows.is_empty() or randf() >= chance:
		return
	_meow_player.stream = meows.pick_random()
	_meow_player.play()
