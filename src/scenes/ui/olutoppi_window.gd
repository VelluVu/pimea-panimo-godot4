class_name OlutoppiWindow
extends Panel

## The main-menu talent tree, one tab per path. Each TreeArea Button is a node named after
## its unlock_id, and lines come from prerequisite_ids, so the scene needs no id or edge list.
## The panel beside the tree shows the talent under the mouse or focus, so touch players
## and keyboard players read it too.

const TITLE_TEXT : String = "Olutoppi"
const RENOWN_FORMAT : String = "Maine: %d"
## The browser demo shows the tree but sells nothing from it (DemoRules).
const DEMO_RENOWN_FORMAT : String = "Maine: %d. Kykyjä voi ostaa koko pelissä."
const LEVEL_FORMAT : String = "%d/%d"
const LOCKED_ICON : String = "🔒"
const BAR_WORK_TAB_TEXT : String = "Baarityöskentely"
const BREWING_TAB_TEXT : String = "Oluenpanotaito"
const MARKETING_TAB_TEXT : String = "Markkinointi"
## In the order of the PathTabs pages.
const PATH_TAB_TEXTS : Array[String] = [BAR_WORK_TAB_TEXT, BREWING_TAB_TEXT, MARKETING_TAB_TEXT]
const INFO_HINT_TEXT : String = "Valitse kyky, niin näet sen tiedot."

@onready var title_label : Label = %TitleLabel
@onready var renown_label : Label = %RenownLabel
@onready var path_tabs : TabContainer = %PathTabs
@onready var info_name_label : Label = %InfoNameLabel
@onready var info_label : Label = %InfoLabel
@onready var tree_areas : Array[Control] = [
	%BarWorkTreeArea,
	%BrewingTreeArea,
	%MarketingTreeArea,
]

var _node_views : Dictionary = {} # unlock_id -> OlutoppiNodeView
var _connector_edges : Dictionary = {} # TreeConnectorLayer -> Array[OlutoppiEdge]
var _info_texts : Dictionary = {} # unlock_id -> String, as last refreshed
## The talent the panel shows; "" shows the hint.
var _info_id : String = ""


func _ready() -> void:
	title_label.text = TITLE_TEXT
	for i : int in PATH_TAB_TEXTS.size():
		path_tabs.set_tab_title(i, PATH_TAB_TEXTS[i])
	path_tabs.tab_changed.connect(_show_info.bind("").unbind(1))
	for tree_area : Control in tree_areas:
		_setup_tree_area(tree_area)

	# The renown counter sits at the header's right end, under the X without a gap.
	WindowCloseButton.attach(self, _on_close_button_pressed, $MarginContainer/MainVBox/HeaderHBox)
	GUISignals.olutoppi_requested.connect(_on_olutoppi_requested)
	MetaProgressManager.renown_changed.connect(_on_renown_changed)
	hide()


func _on_olutoppi_requested() -> void:
	_info_id = ""
	_refresh()
	show()


func _on_renown_changed(_renown : int) -> void:
	if visible:
		_refresh()


func _on_close_button_pressed() -> void:
	GUISignals.olutoppi_closed.emit()
	hide()


func _on_node_pressed(unlock_id : String) -> void:
	MetaProgressManager.purchase_next_level(unlock_id)
	_refresh()


## Two passes, so a prerequisite declared later in the tree still resolves.
func _setup_tree_area(tree_area : Control) -> void:
	var buttons : Array[Button] = []
	for child : Node in tree_area.get_children():
		if child is Button:
			buttons.append(child)

	var centers : Dictionary = {}
	for button : Button in buttons:
		var id : String = button.name
		_node_views[id] = OlutoppiNodeView.new(button)
		centers[id] = button.position + button.size * 0.5
		button.pressed.connect(_on_node_pressed.bind(id))
		button.mouse_entered.connect(_show_info.bind(id))
		button.focus_entered.connect(_show_info.bind(id))

	var connector : TreeConnectorLayer = tree_area.get_node("ConnectorLayer")
	_connector_edges[connector] = _build_edges(buttons, centers)


func _build_edges(buttons : Array[Button], centers : Dictionary) -> Array[OlutoppiEdge]:
	var edges : Array[OlutoppiEdge] = []
	for button : Button in buttons:
		var id : String = button.name
		var unlock : MetaUnlockData = MetaProgressManager.find_unlock(id)
		if unlock == null:
			continue
		for prerequisite_id : String in unlock.prerequisite_ids:
			if centers.has(prerequisite_id):
				edges.append(OlutoppiEdge.new(centers[prerequisite_id], centers[id], prerequisite_id))
	return edges


func _refresh() -> void:
	var renown : int = MetaProgressManager.get_renown()
	renown_label.text = tr(DEMO_RENOWN_FORMAT if DemoRules.is_demo() else RENOWN_FORMAT) % renown

	for id : String in _node_views:
		_refresh_node(id, renown)
	for connector : TreeConnectorLayer in _connector_edges:
		connector.set_connections(_connections_for(_connector_edges[connector]))
	_show_info(_info_id)


## A purchase refreshes the texts, so the panel keeps showing the same talent, updated.
## OlutoppiText's first line is the name, which gets the gold heading.
func _show_info(id : String) -> void:
	_info_id = id
	var lines : PackedStringArray = (_info_texts[id] as String).split("\n", true, 1) if _info_texts.has(id) else PackedStringArray(["", tr(INFO_HINT_TEXT)])
	info_name_label.text = lines[0]
	info_name_label.visible = not lines[0].is_empty()
	info_label.text = lines[1] if lines.size() > 1 else ""


func _connections_for(edges : Array[OlutoppiEdge]) -> Array[Dictionary]:
	var connections : Array[Dictionary] = []
	for edge : OlutoppiEdge in edges:
		var unlocked : bool = MetaProgressManager.get_node_level(edge.prerequisite_id) > 0
		connections.append({"from": edge.from, "to": edge.to, "unlocked": unlocked})
	return connections


func _refresh_node(id : String, renown : int) -> void:
	var view : OlutoppiNodeView = _node_views[id]
	var unlock : MetaUnlockData = MetaProgressManager.find_unlock(id)
	if unlock == null:
		view.button.visible = false
		_info_texts.erase(id)
		return

	var level : int = MetaProgressManager.get_node_level(id)
	var maxed : bool = MetaProgressManager.is_maxed(id)
	var locked : bool = not MetaProgressManager.meets_prerequisites(id) and level <= 0

	view.icon_label.text = LOCKED_ICON if locked else unlock.icon_placeholder
	view.level_bonus_label.text = "" if locked else LEVEL_FORMAT % [level, unlock.max_level]
	view.button.disabled = locked or maxed or renown < unlock.renown_cost_per_level
	view.refresh_availability()
	_info_texts[id] = OlutoppiText.locked_tooltip(unlock, _unmet_prerequisite_names(unlock)) if locked else OlutoppiText.tooltip(unlock, level, maxed, renown)


func _unmet_prerequisite_names(unlock : MetaUnlockData) -> PackedStringArray:
	var names : PackedStringArray = []
	for prerequisite_id : String in unlock.prerequisite_ids:
		var prerequisite : MetaUnlockData = MetaProgressManager.find_unlock(prerequisite_id)
		if prerequisite != null and MetaProgressManager.get_node_level(prerequisite_id) <= 0:
			names.append(tr(prerequisite.perk_name))
	return names


## Esc does what the X does, and is used up here so the game menu does not open over it.
func _input(event : InputEvent) -> void:
	if visible and event.is_action_pressed(InputManager.ACTION_CANCEL):
		_on_close_button_pressed()
		get_viewport().set_input_as_handled()
