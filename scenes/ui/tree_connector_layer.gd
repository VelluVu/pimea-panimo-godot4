class_name TreeConnectorLayer
extends Control

## Draws a straight line between each node and every one of its
## prerequisites, in the same local coordinate space the node Buttons are
## absolutely positioned in (see olutoppi_window.tscn's TreeArea — this
## layer is that area's first child, so it draws behind the buttons).
## Purely decorative: mouse_filter is set to IGNORE in the .tscn so it
## never intercepts clicks meant for the buttons on top of it.
##
## OlutoppiWindow computes each connection's endpoints once in _ready()
## (node centers never move — geometry comes straight from the buttons'
## own hand-authored positions in the .tscn) but rebuilds the "unlocked"
## flags fresh on every _refresh() and calls set_connections() again —
## simplest correct option given each path only has a handful of edges.

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
