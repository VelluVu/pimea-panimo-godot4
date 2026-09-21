class_name OlutoppiWindow
extends Panel

## Main-menu talent tree for MetaProgressManager's renown currency. Every Button child of
## a TreeArea is a node square named after its MetaUnlockData.unlock_id, and the connector
## lines come from each node's prerequisite_ids, so the scene needs no id or edge list.
## Self-subscribes to GUISignals.olutoppi_requested, like LeaderboardWindow.

const TITLE_TEXT : String = "Olutoppi"
const CLOSE_BUTTON_TEXT : String = "Sulje"
const RENOWN_FORMAT : String = "Maine: %d"
const LEVEL_BONUS_FORMAT : String = "%d/%d %s"
const LOCKED_ICON : String = "🔒"


## The labels inside one node square.
class NodeView:
	var button : Button
	var icon_label : Label
	var level_bonus_label : Label

	func _init(node_button : Button) -> void:
		button = node_button
		icon_label = node_button.get_node("VBox/IconLabel")
		level_bonus_label = node_button.get_node("VBox/LevelBonusLabel")


## Static geometry of one connector line and the node that gates it. Whether it is
## unlocked is recomputed on every refresh.
class Edge:
	var from : Vector2
	var to : Vector2
	var prerequisite_id : String

	func _init(from_center : Vector2, to_center : Vector2, prerequisite : String) -> void:
		from = from_center
		to = to_center
		prerequisite_id = prerequisite


@onready var title_label : Label = $MarginContainer/MainVBox/HeaderHBox/TitleLabel
@onready var renown_label : Label = $MarginContainer/MainVBox/HeaderHBox/RenownLabel
@onready var close_button : Button = $MarginContainer/MainVBox/HeaderHBox/CloseButton
@onready var tree_areas : Array[Control] = [
	$MarginContainer/MainVBox/PathsHBox/BarWorkColumn/TreeArea,
	$MarginContainer/MainVBox/PathsHBox/BrewingColumn/TreeArea,
	$MarginContainer/MainVBox/PathsHBox/MarketingColumn/TreeArea,
]

var _node_views : Dictionary = {} # unlock_id -> NodeView
var _connector_edges : Dictionary = {} # TreeConnectorLayer -> Array[Edge]


func _ready() -> void:
	title_label.text = TITLE_TEXT
	close_button.text = CLOSE_BUTTON_TEXT
	for tree_area : Control in tree_areas:
		_setup_tree_area(tree_area)

	close_button.pressed.connect(_on_close_button_pressed)
	GUISignals.olutoppi_requested.connect(_on_olutoppi_requested)
	hide()


func _on_olutoppi_requested() -> void:
	_refresh()
	show()


func _on_close_button_pressed() -> void:
	GUISignals.olutoppi_closed.emit()
	hide()


func _on_node_pressed(unlock_id : String) -> void:
	MetaProgressManager.purchase_next_level(unlock_id)
	_refresh()


## Two passes: every node center is known before edges are built, so a prerequisite
## declared later in the scene tree still resolves.
func _setup_tree_area(tree_area : Control) -> void:
	var buttons : Array[Button] = []
	for child : Node in tree_area.get_children():
		if child is Button:
			buttons.append(child)

	var centers : Dictionary = {}
	for button : Button in buttons:
		var id : String = button.name
		_node_views[id] = NodeView.new(button)
		centers[id] = button.position + button.size * 0.5
		button.pressed.connect(_on_node_pressed.bind(id))

	var connector : TreeConnectorLayer = tree_area.get_node("ConnectorLayer")
	_connector_edges[connector] = _build_edges(buttons, centers)


func _build_edges(buttons : Array[Button], centers : Dictionary) -> Array[Edge]:
	var edges : Array[Edge] = []
	for button : Button in buttons:
		var id : String = button.name
		var unlock : MetaUnlockData = MetaProgressManager.find_unlock(id)
		if unlock == null:
			continue
		for prerequisite_id : String in unlock.prerequisite_ids:
			if centers.has(prerequisite_id):
				edges.append(Edge.new(centers[prerequisite_id], centers[id], prerequisite_id))
	return edges


func _refresh() -> void:
	var renown : int = MetaProgressManager.get_renown()
	renown_label.text = RENOWN_FORMAT % renown

	for id : String in _node_views:
		_refresh_node(id, renown)
	for connector : TreeConnectorLayer in _connector_edges:
		connector.set_connections(_connections_for(_connector_edges[connector]))


func _connections_for(edges : Array[Edge]) -> Array[Dictionary]:
	var connections : Array[Dictionary] = []
	for edge : Edge in edges:
		var unlocked : bool = MetaProgressManager.get_node_level(edge.prerequisite_id) > 0
		connections.append({"from": edge.from, "to": edge.to, "unlocked": unlocked})
	return connections


func _refresh_node(id : String, renown : int) -> void:
	var view : NodeView = _node_views[id]
	var unlock : MetaUnlockData = MetaProgressManager.find_unlock(id)
	if unlock == null:
		view.button.visible = false
		return

	var level : int = MetaProgressManager.get_node_level(id)
	var maxed : bool = MetaProgressManager.is_maxed(id)
	var locked : bool = not MetaProgressManager.meets_prerequisites(id) and level <= 0

	view.icon_label.text = LOCKED_ICON if locked else unlock.icon_placeholder
	view.level_bonus_label.text = "" if locked else LEVEL_BONUS_FORMAT % [level, unlock.max_level, OlutoppiText.short_bonus(unlock, level)]
	view.button.disabled = locked or maxed or renown < unlock.renown_cost_per_level
	view.button.tooltip_text = OlutoppiText.locked_tooltip(unlock, _unmet_prerequisite_names(unlock)) if locked else OlutoppiText.tooltip(unlock, level, maxed)


func _unmet_prerequisite_names(unlock : MetaUnlockData) -> PackedStringArray:
	var names : PackedStringArray = []
	for prerequisite_id : String in unlock.prerequisite_ids:
		var prerequisite : MetaUnlockData = MetaProgressManager.find_unlock(prerequisite_id)
		if prerequisite != null and MetaProgressManager.get_node_level(prerequisite_id) <= 0:
			names.append(prerequisite.perk_name)
	return names
