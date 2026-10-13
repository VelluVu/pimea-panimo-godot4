class_name KegWashView
extends Control

## The keg wash table: the opened keg, the dirt in it and the three tools in their places.
## Press a tool to pick it up; it follows the pointer, and while the button is held it is
## in use (also straight after grabbing it): the brush scrubs, the hose rinses, the bottle
## sprays. Pressing its place again (or the right button) puts it back. The work goes to `session`.

signal tool_changed(tool : Tool)

enum Tool { NONE, BRUSH, HOSE, SPRAY }

const ART : KegWashArt = preload("res://src/resources/keg_wash/keg_wash_art.tres")
const TUNNEL_POSITION : Vector2 = KegTunnel.OPENING_CENTER - Vector2(46, 31) * KegWashArt.TUNNEL_SCALE
const SPOT_FRAME : int = 14
const LOOSE_FRAME : int = 7

const HOOK_POSITION : Vector2 = Vector2(44, 92)
## The brush hangs from the hook with its bristles down.
const BRUSH_REST : Vector2 = Vector2(51, 158)
const BRUSH_REST_RECT : Rect2 = Rect2(30, 96, 42, 72)
const BRUSH_SPRING : float = 260.0
const BRUSH_DAMPING : float = 18.0
const TAP_POSITION : Vector2 = Vector2(586, 66)
const TAP_SPOUT : Vector2 = TAP_POSITION + Vector2(11, 20)
## The nozzle hangs by the tap; the hose joins the bottom of its grip.
const HOSE_REST : Vector2 = Vector2(604, 186)
const NOZZLE_GRIP : Vector2 = Vector2(0, 28)
const HOSE_REST_RECT : Rect2 = Rect2(586, 176, 36, 48)
const BENCH_POSITION : Vector2 = Vector2(536, 300)
## The bottle stands on the bench; the mist leaves from its top left.
const SPRAY_REST : Vector2 = Vector2(576, 268)
const SPRAY_NOZZLE : Vector2 = Vector2(0, 6)
const SPRAY_REST_RECT : Rect2 = Rect2(566, 258, 44, 44)
const TOOL_LABELS : Dictionary = {Tool.BRUSH: "Harja", Tool.HOSE: "Letku", Tool.SPRAY: "Suihke"}
const LABEL_COLOR : Color = Color(0.95, 0.88, 0.7)
const READY_GLOW : Color = Color(1.35, 1.25, 0.9)

const HOSE_COLOR : Color = Color(0.2, 0.42, 0.22)
const HOSE_SHINE : Color = Color(0.36, 0.62, 0.34)
const WATER_COLOR : Color = Color(0.62, 0.8, 1.0, 0.85)
const MIST_COLOR : Color = Color(0.85, 0.95, 1.0, 0.5)
const SHEEN_COLOR : Color = Color(0.75, 0.9, 1.0, 0.12)
const SPARKLE_COLOR : Color = Color(1.0, 1.0, 0.95)
const FLASH_SECONDS : float = 0.15
## The rim's lowest point, where rinse water runs out onto the floor.
const RIM_BOTTOM : Vector2 = KegTunnel.OPENING_CENTER + Vector2(0, 100)

var session : KegWashSession

var _tool : Tool = Tool.NONE
var _using : bool = false
var _pointer : Vector2 = Vector2.ZERO
var _brush : Vector2 = BRUSH_REST
var _brush_velocity : Vector2 = Vector2.ZERO
var _hose : HoseRope = HoseRope.new(TAP_SPOUT, HOSE_REST + NOZZLE_GRIP)
var _drops : Array[Dictionary] = []
var _flashes : Dictionary = {} # KegWashSpot -> seconds left
var _puddle : float = 0.0
var _time : float = 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_add_label(Tool.BRUSH, Vector2(BRUSH_REST_RECT.position.x, BRUSH_REST_RECT.end.y + 2), BRUSH_REST_RECT.size.x)
	_add_label(Tool.HOSE, Vector2(HOSE_REST_RECT.position.x - 6, HOSE_REST_RECT.end.y + 2), HOSE_REST_RECT.size.x + 12)
	_add_label(Tool.SPRAY, Vector2(SPRAY_REST_RECT.position.x, BENCH_POSITION.y + 18), SPRAY_REST_RECT.size.x)


## Every tool back in its place, for a fresh keg.
func reset() -> void:
	_set_tool(Tool.NONE)
	_brush = BRUSH_REST
	_brush_velocity = Vector2.ZERO
	_drops.clear()
	_flashes.clear()
	_puddle = 0.0


func tool() -> Tool:
	return _tool


func flash(spot : KegWashSpot) -> void:
	_flashes[spot] = FLASH_SECONDS


func _gui_input(event : InputEvent) -> void:
	if event is InputEventMouseMotion:
		_pointer = event.position
	elif event is InputEventMouseButton:
		_pointer = event.position
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_set_tool(Tool.NONE)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_press(event.position)
			else:
				_using = false
		accept_event()


func _press(at : Vector2) -> void:
	var picked : Tool = _tool_at(at)
	if picked == _tool and picked != Tool.NONE:
		_set_tool(Tool.NONE)
		return
	if picked != Tool.NONE:
		_set_tool(picked)
	# Grabbing a tool and keeping the button down uses it at once.
	_using = _tool != Tool.NONE


func _tool_at(at : Vector2) -> Tool:
	if BRUSH_REST_RECT.has_point(at):
		return Tool.BRUSH
	if HOSE_REST_RECT.has_point(at):
		return Tool.HOSE
	if SPRAY_REST_RECT.has_point(at):
		return Tool.SPRAY
	return Tool.NONE


func _set_tool(new_tool : Tool) -> void:
	_using = false
	if new_tool == _tool:
		return
	_tool = new_tool
	if _tool == Tool.BRUSH:
		_brush_velocity = Vector2.ZERO
	tool_changed.emit(_tool)


func _process(delta : float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	_step_brush(delta)
	_step_hose(delta)
	_step_spray(delta)
	if session != null:
		session.update(delta)
	_step_drops(delta)
	for spot : Variant in _flashes.keys():
		_flashes[spot] -= delta
		if _flashes[spot] <= 0.0:
			_flashes.erase(spot)
	queue_redraw()


func _step_brush(delta : float) -> void:
	var goal : Vector2 = _pointer if _tool == Tool.BRUSH else BRUSH_REST
	var before : Vector2 = _brush
	_brush_velocity += (BRUSH_SPRING * (goal - _brush) - BRUSH_DAMPING * _brush_velocity) * delta
	_brush += _brush_velocity * delta
	if _tool != Tool.BRUSH:
		_brush = _brush.lerp(BRUSH_REST, minf(1.0, delta * 12.0))
	elif _using and session != null and KegTunnel.is_inside(_brush):
		session.scrub(before, _brush, delta)


func _step_hose(delta : float) -> void:
	var tip_goal : Vector2 = _pointer if _tool == Tool.HOSE else HOSE_REST
	_hose.step(delta, tip_goal + NOZZLE_GRIP)
	var tip : Vector2 = _nozzle_tip()
	var spraying : bool = _tool == Tool.HOSE and _using and KegTunnel.is_inside(tip)
	if spraying:
		if session != null:
			session.rinse(tip, delta)
		_puddle = minf(1.0, _puddle + delta * 0.25)
		for i : int in 3:
			_drops.append({"position": tip, "velocity": Vector2(randf_range(-60, 60), randf_range(-90, -20)), "life": 0.35, "mist": false})
		_drops.append({"position": RIM_BOTTOM + Vector2(randf_range(-30, 30), 0), "velocity": Vector2(randf_range(-10, 10), 40), "life": 0.5, "mist": false})


func _step_spray(delta : float) -> void:
	if _tool != Tool.SPRAY or not _using:
		return
	var at : Vector2 = _spray_tip()
	if not KegTunnel.is_inside(at):
		return
	if session != null:
		session.sanitize(at, delta)
	for i : int in 2:
		var offset : Vector2 = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * KegWashRules.SPRAY_RADIUS * 0.7
		_drops.append({"position": at + offset, "velocity": offset * 0.6, "life": 0.5, "mist": true})


func _step_drops(delta : float) -> void:
	for drop : Dictionary in _drops:
		drop.life -= delta
		drop.position += drop.velocity * delta
		if not drop.mist:
			drop.velocity.y += 400.0 * delta
	_drops = _drops.filter(func(drop : Dictionary) -> bool: return drop.life > 0.0)


func _nozzle_tip() -> Vector2:
	return _hose.nozzle() - NOZZLE_GRIP


func _spray_tip() -> Vector2:
	return (_pointer if _tool == Tool.SPRAY else SPRAY_REST) + SPRAY_NOZZLE


func _draw() -> void:
	var prop : float = KegWashArt.PROP_SCALE
	_draw_sprite(ART.bench, BENCH_POSITION, prop)
	_draw_sprite(ART.hook, HOOK_POSITION, prop)
	_draw_sprite(ART.tap, TAP_POSITION, prop)
	_draw_sprite(ART.tunnel, TUNNEL_POSITION, KegWashArt.TUNNEL_SCALE)
	if session != null:
		_draw_coverage()
		_draw_spots()
	if _puddle > 0.0:
		draw_rect(Rect2(RIM_BOTTOM + Vector2(-60 * _puddle, 36), Vector2(120 * _puddle, 4)), Color(WATER_COLOR, 0.5))
	for drop : Dictionary in _drops:
		draw_rect(Rect2((drop.position as Vector2).round(), Vector2(2, 2)), MIST_COLOR if drop.mist else WATER_COLOR)
	_draw_hose()
	_draw_tool_sprite(ART.nozzle, _nozzle_tip() - Vector2(ART.nozzle.get_width() * prop / 2.0, 0), _tool == Tool.HOSE)
	_draw_tool_sprite(ART.spray, _spray_tip() - SPRAY_NOZZLE, _tool == Tool.SPRAY)
	var brush_size : Vector2 = Vector2(ART.brush.get_size()) * prop
	_draw_tool_sprite(ART.brush, _brush - Vector2(brush_size.x / 2.0, brush_size.y), _tool == Tool.BRUSH)


func _draw_coverage() -> void:
	for i : int in session.cells.size():
		var value : float = session.cell_coverage[i]
		if value <= 0.0:
			continue
		var cell : Vector2 = session.cells[i]
		var half : float = KegWashRules.COVERAGE_CELL / 2.0
		draw_rect(Rect2(cell - Vector2(half, half), Vector2(half, half) * 2.0), Color(SHEEN_COLOR, SHEEN_COLOR.a * value))
		# A few covered cells glint at a time.
		if value >= 1.0 and fmod(_time * 1.7 + i * 0.37, 3.0) < 0.12:
			draw_rect(Rect2(cell.round() - Vector2(1, 3), Vector2(2, 6)), SPARKLE_COLOR)
			draw_rect(Rect2(cell.round() - Vector2(3, 1), Vector2(6, 2)), SPARKLE_COLOR)


func _draw_spots() -> void:
	var size : Vector2 = Vector2(SPOT_FRAME, SPOT_FRAME) * KegWashArt.PROP_SCALE
	for spot : KegWashSpot in session.spots:
		if spot.is_gone():
			continue
		var frame : int = LOOSE_FRAME if spot.state == KegWashSpot.State.LOOSE else int(spot.kind)
		var at : Vector2 = spot.position
		if KegWashRules.is_critter(spot.kind):
			at += Vector2(sin(_time * 23.0 + at.x), cos(_time * 19.0 + at.y)) * 2.0
			if spot.state == KegWashSpot.State.FLEEING:
				var gone_share : float = 1.0 - spot.flee_left / KegWashRules.FLEE_SECONDS[spot.kind]
				at += Vector2(sin(_time * 9.0) * 20.0, -160.0 * gone_share * gone_share)
		var tint : Color = Color.WHITE.darkened(KegTunnel.depth(spot.position) * 0.35)
		if _flashes.has(spot):
			tint = Color(1.6, 1.6, 1.6)
		draw_texture_rect_region(ART.spots, Rect2((at - size / 2.0).round(), size), Rect2(frame * SPOT_FRAME, 0, SPOT_FRAME, SPOT_FRAME), tint)


func _draw_hose() -> void:
	draw_polyline(_hose.points, HOSE_COLOR, 6.0)
	draw_polyline(_hose.points, HOSE_SHINE, 2.0)


func _draw_sprite(texture : Texture2D, at : Vector2, scale_by : float, tint : Color = Color.WHITE) -> void:
	draw_texture_rect(texture, Rect2(at.round(), Vector2(texture.get_size()) * scale_by), false, tint)


## A tool waiting in its place glows faintly when nothing is in hand, so the player
## sees what to pick up.
func _draw_tool_sprite(texture : Texture2D, at : Vector2, carried : bool) -> void:
	var tint : Color = READY_GLOW if _tool == Tool.NONE and not carried else Color.WHITE
	_draw_sprite(texture, at, KegWashArt.PROP_SCALE, tint)


func _add_label(for_tool : Tool, at : Vector2, width : float) -> void:
	var label := Label.new()
	label.text = TOOL_LABELS[for_tool]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = at
	label.size = Vector2(width, 14)
	label.add_theme_color_override("font_color", LABEL_COLOR)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
