class_name WideStage
extends Node

## Keeps a fixed-size stage (the project's viewport size) centred when the window is wider
## or taller than it (stretch aspect "expand"). The world canvas and `layers` move to the
## centre; `stage_roots` stay exactly the stage's size, so everything laid out for it holds.
## Controls that should reach the real screen edges take ScreenBleed.

@export var move_world : bool = true
@export var layers : Array[CanvasLayer] = []
@export var stage_roots : Array[Control] = []
## Covers the screen outside the stage, so whatever waits or walks off the stage's edges
## stays hidden. Drawn on mask_layer, after any layer of that number earlier in the tree.
@export var mask_color : Color = Color.BLACK
@export var mask_layer : int = 1

var _mask : CanvasLayer
var _mask_rects : Array[ColorRect] = []


func _ready() -> void:
	_build_mask()
	get_viewport().size_changed.connect(_apply)
	_apply()


func _build_mask() -> void:
	_mask = CanvasLayer.new()
	_mask.name = &"StageMask"
	_mask.layer = mask_layer
	add_child(_mask)
	for side : int in 4:
		var rect := ColorRect.new()
		rect.color = mask_color
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_mask.add_child(rect)
		_mask_rects.append(rect)


func _apply() -> void:
	var viewport : Viewport = get_viewport()
	var origin : Vector2 = Vector2(origin_in(viewport))
	_place_mask(origin, viewport.get_visible_rect().size)
	if move_world:
		var canvas : Transform2D = viewport.canvas_transform
		canvas.origin = origin
		viewport.canvas_transform = canvas
	for layer : CanvasLayer in layers:
		layer.offset = origin
	var shrink : Vector2 = base_size() - viewport.get_visible_rect().size
	for root : Control in stage_roots:
		# A root on one of the moved layers is centred already; any other is moved itself.
		var at : Vector2 = Vector2.ZERO if layers.has(root.get_canvas_layer_node()) else origin
		root.set_anchors_preset(Control.PRESET_FULL_RECT)
		root.offset_left = at.x
		root.offset_top = at.y
		root.offset_right = at.x + shrink.x
		root.offset_bottom = at.y + shrink.y


func _place_mask(origin : Vector2, visible : Vector2) -> void:
	var stage : Rect2 = Rect2(origin, base_size())
	var sides : Array[Rect2] = mask_rects_for(stage, visible)
	for i : int in _mask_rects.size():
		_mask_rects[i].position = sides[i].position
		_mask_rects[i].size = sides[i].size
		_mask_rects[i].visible = sides[i].has_area()


## Left, right, top and bottom of the screen outside `stage`; the side strips run the full
## height, the top and bottom ones only the stage's width.
static func mask_rects_for(stage : Rect2, visible : Vector2) -> Array[Rect2]:
	return [Rect2(0.0, 0.0, stage.position.x, visible.y),
			Rect2(stage.end.x, 0.0, maxf(0.0, visible.x - stage.end.x), visible.y),
			Rect2(stage.position.x, 0.0, stage.size.x, stage.position.y),
			Rect2(stage.position.x, stage.end.y, stage.size.x, maxf(0.0, visible.y - stage.end.y))]


## The stage size the game is laid out for.
static func base_size() -> Vector2:
	return Vector2(ProjectSettings.get_setting("display/window/size/viewport_width", 640),
			ProjectSettings.get_setting("display/window/size/viewport_height", 360))


## Where the stage's top left corner sits on screen.
static func origin_in(viewport : Viewport) -> Vector2i:
	return origin_for(viewport.get_visible_rect().size, base_size())


## Whole pixels, so pixel art never lands between pixels; an odd extra pixel goes right.
static func origin_for(visible : Vector2, base : Vector2) -> Vector2i:
	return Vector2i(maxi(0, floori((visible.x - base.x) / 2.0)), maxi(0, floori((visible.y - base.y) / 2.0)))


## How far the screen reaches past the stage on the right and bottom.
static func far_extra_for(visible : Vector2, base : Vector2) -> Vector2i:
	var origin : Vector2i = origin_for(visible, base)
	return Vector2i(maxi(0, int(visible.x - base.x) - origin.x), maxi(0, int(visible.y - base.y) - origin.y))
