class_name TreeConnectorLayer
extends Control

## Draws a line from each node to each of its prerequisites, behind the buttons in
## TreeArea's space (mouse_filter IGNORE in the scene). OlutoppiWindow computes the
## endpoints once and resends the unlocked flags on every refresh.

const LINE_COLOR_LOCKED : Color = Color(0.55, 0.47, 0.38, 0.8)
const LINE_COLOR_UNLOCKED : Color = Color(0.949, 0.788, 0.42, 1.0)
const LINE_WIDTH : float = 3.0

## Array of {from: Vector2, to: Vector2, unlocked: bool}
var _connections : Array[Dictionary] = []


func set_connections(connections : Array[Dictionary]) -> void:
	_connections = connections
	queue_redraw()


func _draw() -> void:
	for connection : Dictionary in _connections:
		var color : Color = LINE_COLOR_UNLOCKED if connection["unlocked"] else LINE_COLOR_LOCKED
		draw_line(connection["from"], connection["to"], color, LINE_WIDTH)
