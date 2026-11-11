class_name SnowCover
extends Node2D

## Snow on a customer who came in from the winter, lying along the top of whatever frame the
## sprite shows (SnowSilhouette): head or hat and shoulders. shake() knocks some of it off as
## falling bits, which WinterPuffs draws. A child of the customer's AnimatedSprite2D, so it
## draws in art pixels and scales, flips and sways with the sprite.

const SNOW_COLOR : Color = Color(1.0, 1.0, 1.0)
## Gaps and little heaps, so the cover reads as snow and not as an outline.
const BARE_CHANCE : float = 0.15
const HEAP_CHANCE : float = 0.35

enum Cell { BARE, SNOW, HEAP }

var _sprite : AnimatedSprite2D
## Per frame column, a Cell.
var _cells : PackedByteArray = []


func _ready() -> void:
	_sprite = get_parent() as AnimatedSprite2D
	var width : int = _current_edge().size()
	_cells.resize(width)
	for x : int in width:
		var roll : float = randf()
		_cells[x] = Cell.BARE if roll < BARE_CHANCE else (Cell.HEAP if roll < BARE_CHANCE + HEAP_CHANCE else Cell.SNOW)


## The frame changes as the customer walks and the stomps move the offset, so redraw always.
func _process(_delta : float) -> void:
	queue_redraw()


func _draw() -> void:
	var tops : PackedInt32Array = _current_edge()
	for x : int in mini(tops.size(), _cells.size()):
		if _cells[x] == Cell.BARE or tops[x] < 0:
			continue
		var cell : Vector2 = _cell_at(x, tops[x], tops.size())
		draw_rect(Rect2(cell, Vector2.ONE), SNOW_COLOR)
		if _cells[x] == Cell.HEAP:
			draw_rect(Rect2(cell + Vector2.UP, Vector2.ONE), SNOW_COLOR)


## Knocks off about `share` of the snow left, all of it at 1. `floor_y` is the global row
## the bits fall to.
func shake(share : float, floor_y : float) -> void:
	var tops : PackedInt32Array = _current_edge()
	var falling := PackedVector2Array()
	for x : int in mini(tops.size(), _cells.size()):
		if _cells[x] == Cell.BARE or (share < 1.0 and randf() >= share):
			continue
		if tops[x] >= 0:
			var cell : Vector2 = _cell_at(x, tops[x], tops.size())
			falling.append(to_global(cell + Vector2(0.5, 0.5)))
			if _cells[x] == Cell.HEAP:
				falling.append(to_global(cell + Vector2(0.5, -0.5)))
		_cells[x] = Cell.BARE
	BrewerySignals.snow_shaken_off.emit(falling, floor_y)
	if share >= 1.0:
		queue_free()


func _current_edge() -> PackedInt32Array:
	var texture : Texture2D = _sprite.sprite_frames.get_frame_texture(_sprite.animation, _sprite.frame) if _sprite.sprite_frames != null else null
	if texture == null:
		return PackedInt32Array()
	return SnowSilhouette.top_edge_of(texture)


## The sprite draws its frame at `offset`, mirrored in place when flipped.
func _cell_at(x : int, top : int, width : int) -> Vector2:
	var drawn_x : int = width - 1 - x if _sprite.flip_h else x
	return _sprite.offset + Vector2(drawn_x, top)
