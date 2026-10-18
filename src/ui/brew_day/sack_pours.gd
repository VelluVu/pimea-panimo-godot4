class_name SackPours
extends RefCounted

## The sacks over the kettle and their pellets. A carried sack lags the pointer; shaking it
## pours faster and throws pellets along its motion.

signal landed(at : Vector2, color : Color, blooms : bool)

## Where a sack lifted by its key hangs over the mouth, one spot per sack at once.
const POUR_SPOTS : Array[Vector2] = [Vector2(78, 4), Vector2(170, 4), Vector2(124, -4)]
## A carried sack follows the pointer this fast.
const CARRY_FOLLOW : float = 16.0
## Faster than this (pixels a second) a sack shakes; fully at SHAKE_FROM + SHAKE_RANGE,
## pouring twice as fast.
const SHAKE_FROM : float = 220.0
const SHAKE_RANGE : float = 400.0
const SHAKE_THROW : float = 0.55
const SHAKE_SCATTER : float = 60.0
## The sack's mouth pours into the kettle within this reach of the mouth's edges.
const POUR_REACH_ABOVE : float = 110.0
const POUR_INSET : float = 8.0
## Where the lifted sack sprite's mouth is (sprite pixels), for the falling pellets.
const LIFTED_SACK_MOUTH : Vector2 = Vector2(13, 16)
const PELLETS_PER_SECOND : float = 30.0
const PELLET_GRAVITY : float = 420.0
const PELLET_SIZE : Vector2 = Vector2(2, 2)
## Pellets land this far into the mouth from its top edge.
const LANDING_DEPTH : Vector2 = Vector2(18, 62)

## Ingredient id -> {at (sprite's top-left), target, velocity, follow, color, blooms}.
var _carried : Dictionary = {}
## Ingredient id -> pellets owed to the next frame, for each pouring sack.
var _pours : Dictionary = {}
## [position, velocity, landing y, colour, blooms] of each falling pellet.
var _pellets : Array = []


static func lifted_size() -> Vector2:
	return KettleView.ART.sack_lifted.get_size() * BrewDayArt.PROP_SCALE


## 0 for a sack held still, up to 1 for one shaken hard.
static func shake(velocity : Vector2) -> float:
	return clampf((velocity.length() - SHAKE_FROM) / SHAKE_RANGE, 0.0, 1.0)


## Lifts a sack: following the pointer, or hung at its own spot when lifted by key.
## Without blooms its pellets only splash.
func carry(id : int, color : Color, follow : bool, blooms : bool, pointer : Vector2) -> void:
	if _carried.has(id):
		return
	var at : Vector2 = POUR_SPOTS[_carried.size() % POUR_SPOTS.size()]
	if follow:
		at = pointer - lifted_size() / 2.0
	_carried[id] = {"at": at, "target": at, "velocity": Vector2.ZERO, "follow": follow, "color": color, "blooms": blooms}


func drop(id : int) -> void:
	_carried.erase(id)
	_pours.erase(id)


func is_carrying(id : int) -> bool:
	return _carried.has(id)


## Where the carried sack should hang: centred on `point`.
func set_target(id : int, point : Vector2) -> void:
	if _carried.has(id):
		_carried[id].target = point - lifted_size() / 2.0


## True while the carried sack's mouth is above the kettle mouth, so it pours in.
func is_over_mouth(id : int) -> bool:
	if not _carried.has(id):
		return false
	var liquid : Rect2 = KettleView.LIQUID_RECT
	var mouth : Vector2 = _carried[id].at + LIFTED_SACK_MOUTH * BrewDayArt.PROP_SCALE
	return mouth.x > liquid.position.x + POUR_INSET and mouth.x < liquid.end.x - POUR_INSET \
		and mouth.y > liquid.position.y - POUR_REACH_ABOVE and mouth.y < liquid.end.y - POUR_INSET


func set_pouring(id : int, pouring : bool) -> void:
	if not pouring or not _carried.has(id):
		_pours.erase(id)
	elif not _pours.has(id):
		_pours[id] = 0.0


## A handful tipped in at once, like spices.
func drop_handful(id : int, count : int) -> void:
	if not _carried.has(id):
		return
	for i : int in count:
		_spawn_pellet(_carried[id])


func clear() -> void:
	_carried.clear()
	_pours.clear()
	_pellets.clear()


func pellet_count() -> int:
	return _pellets.size()


func step(delta : float) -> void:
	for id : int in _carried:
		var sack : Dictionary = _carried[id]
		if sack.follow and delta > 0.0:
			var before : Vector2 = sack.at
			sack.at = (sack.at as Vector2).lerp(sack.target, minf(1.0, CARRY_FOLLOW * delta))
			sack.velocity = (sack.at - before) / delta
	for id : int in _pours:
		var sack : Dictionary = _carried[id]
		_pours[id] += PELLETS_PER_SECOND * (1.0 + shake(sack.velocity)) * delta
		while _pours[id] >= 1.0:
			_pours[id] -= 1.0
			_spawn_pellet(sack)
	for i : int in range(_pellets.size() - 1, -1, -1):
		var pellet : Array = _pellets[i]
		pellet[1].y += PELLET_GRAVITY * delta
		pellet[0] += pellet[1] * delta
		if pellet[0].y >= pellet[2]:
			_pellets.remove_at(i)
			landed.emit(pellet[0], pellet[3], pellet[4])


## The carried sacks, jittering while shaken, and the falling pellets.
func draw(canvas : CanvasItem, clock : float) -> void:
	for id : int in _carried:
		var sack : Dictionary = _carried[id]
		var jitter : float = 0.0
		if shake(sack.velocity) > 0.0:
			jitter = 1.0 if int(clock * KettleView.ANIMATION_FPS * 2.0) % 2 == 0 else -1.0
		var at : Vector2 = ((sack.at as Vector2) + Vector2(jitter, 0)).round()
		canvas.draw_texture_rect(KettleView.ART.sack_lifted, Rect2(at, lifted_size()), false)
	for pellet : Array in _pellets:
		canvas.draw_rect(Rect2((pellet[0] as Vector2).round(), PELLET_SIZE), pellet[3])


## A pellet falls from the sack's mouth into the wort; a shaken sack throws it along its
## motion, so it may miss.
func _spawn_pellet(sack : Dictionary) -> void:
	var start : Vector2 = sack.at + LIFTED_SACK_MOUTH * BrewDayArt.PROP_SCALE + Vector2(randf_range(-3, 3), 0)
	var landing : float = KettleView.LIQUID_RECT.position.y + randf_range(LANDING_DEPTH.x, LANDING_DEPTH.y)
	var shaken : float = shake(sack.velocity)
	var throw : Vector2 = (sack.velocity as Vector2) * SHAKE_THROW * shaken
	throw += Vector2(randf_range(-1, 1), randf_range(-1, 0.5)) * SHAKE_SCATTER * shaken
	var velocity := Vector2(randf_range(-18, 18), randf_range(0, 30)) + throw
	_pellets.append([start, velocity, landing, sack.color, sack.blooms])
