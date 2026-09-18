class_name OlutoppiWindow
extends Panel

## Main-menu "talent tree" screen for MetaProgressManager's renown
## currency — see that autoload and MetaUnlockData for the backing data.
## Self-subscribes to GUISignals.olutoppi_requested (emitted by
## main_menu.gd's OlutoppiButton), same "who owns the window, not who
## asks" decoupling as LeaderboardWindow.
##
## Node discovery is fully dynamic: every Button child of a TreeArea IS a
## node square, named after its MetaUnlockData.unlock_id (see
## olutoppi_window.tscn) — no separate hardcoded id list to keep in sync
## with the scene. Connector lines (TreeConnectorLayer) are derived the
## same way, straight from each node's own MetaUnlockData.prerequisite_ids,
## not a separately authored edge list — a node with 2+ prerequisite_ids
## (a capstone) just gets 2+ lines converging on it.

const TITLE_TEXT : String = "Olutoppi"
const CLOSE_BUTTON_TEXT : String = "Sulje"
const RENOWN_FORMAT : String = "Maine: %d"
const LEVEL_BONUS_FORMAT : String = "%d/%d %s"
const BONUS_NEUTRAL_TEXT : String = "-"
const LOCKED_ICON : String = "🔒"
const TOOLTIP_CURRENT_FORMAT : String = "Nyt:\n%s"
const TOOLTIP_NEXT_LEVEL_FORMAT : String = "Seuraava taso: %d maine"
const TOOLTIP_MAXED_TEXT : String = "Taso enimmillään"
const TOOLTIP_LOCKED_FORMAT : String = "Vaatii ensin: %s"

@onready var title_label : Label = $MarginContainer/MainVBox/HeaderHBox/TitleLabel
@onready var renown_label : Label = $MarginContainer/MainVBox/HeaderHBox/RenownLabel
@onready var close_button : Button = $MarginContainer/MainVBox/HeaderHBox/CloseButton
@onready var tree_areas : Array[Control] = [
	$MarginContainer/MainVBox/PathsHBox/BarWorkColumn/TreeArea,
	$MarginContainer/MainVBox/PathsHBox/BrewingColumn/TreeArea,
	$MarginContainer/MainVBox/PathsHBox/MarketingColumn/TreeArea,
]

## unlock_id : String -> {button, icon_label, level_bonus_label}
var _node_refs : Dictionary = {}
## TreeConnectorLayer -> Array[{from: Vector2, to: Vector2, prereq_id: String}]
## (static geometry + which node gates each line — "unlocked" is
## recomputed fresh every _refresh(), not stored here).
var _connector_edges : Dictionary = {}


func _ready() -> void:
	title_label.text = TITLE_TEXT
	close_button.text = CLOSE_BUTTON_TEXT

	for tree_area : Control in tree_areas:
		_setup_tree_area(tree_area)

	close_button.pressed.connect(_on_close_button_pressed)
	GUISignals.olutoppi_requested.connect(_on_olutoppi_requested)
	hide()


## Discovers every Button child as a node square (caching its refs and
## connecting its press), then derives that path's connector edges from
## each discovered node's own prerequisite_ids — two passes so a node
## whose prerequisite happens to be declared later in the scene tree
## still resolves correctly (centers are all known before edges are built).
func _setup_tree_area(tree_area : Control) -> void:
	var connector : TreeConnectorLayer = tree_area.get_node("ConnectorLayer")
	var centers : Dictionary = {}

	for child : Node in tree_area.get_children():
		if not child is Button:
			continue
		var button : Button = child
		var id : String = button.name
		_node_refs[id] = {
			"button": button,
			"icon_label": button.get_node("VBox/IconLabel"),
			"level_bonus_label": button.get_node("VBox/LevelBonusLabel"),
		}
		centers[id] = button.position + button.size * 0.5
		button.pressed.connect(_on_node_pressed.bind(id))

	var edges : Array[Dictionary] = []
	for child : Node in tree_area.get_children():
		if not child is Button:
			continue
		var id : String = child.name
		var unlock : MetaUnlockData = MetaProgressManager.find_unlock(id)
		if unlock == null:
			continue
		for prereq_id : String in unlock.prerequisite_ids:
			if not centers.has(prereq_id):
				continue
			edges.append({"from": centers[prereq_id], "to": centers[id], "prereq_id": prereq_id})

	_connector_edges[connector] = edges


func _on_olutoppi_requested() -> void:
	_refresh()
	show()


func _on_close_button_pressed() -> void:
	GUISignals.olutoppi_closed.emit()
	hide()


func _on_node_pressed(unlock_id : String) -> void:
	MetaProgressManager.purchase_next_level(unlock_id)
	_refresh()


func _refresh() -> void:
	var renown : int = MetaProgressManager.get_renown()
	renown_label.text = RENOWN_FORMAT % renown

	for id : String in _node_refs:
		_refresh_node(id, renown)

	for connector : TreeConnectorLayer in _connector_edges:
		var edges : Array[Dictionary] = []
		for edge : Dictionary in _connector_edges[connector]:
			var unlocked : bool = MetaProgressManager.get_node_level(edge["prereq_id"]) > 0
			edges.append({"from": edge["from"], "to": edge["to"], "unlocked": unlocked})
		connector.set_connections(edges)


func _refresh_node(id : String, renown : int) -> void:
	var unlock : MetaUnlockData = MetaProgressManager.find_unlock(id)
	var refs : Dictionary = _node_refs[id]
	var button : Button = refs["button"]
	if unlock == null:
		button.visible = false
		return

	var level : int = MetaProgressManager.get_node_level(id)
	var maxed : bool = MetaProgressManager.is_maxed(id)
	var unlockable : bool = MetaProgressManager.meets_prerequisites(id)
	var locked : bool = not unlockable and level <= 0

	refs["icon_label"].text = LOCKED_ICON if locked else unlock.icon_placeholder
	refs["level_bonus_label"].text = "" if locked else LEVEL_BONUS_FORMAT % [level, unlock.max_level, _format_bonus_short(unlock, level)]

	button.disabled = locked or maxed or renown < unlock.renown_cost_per_level
	button.tooltip_text = _build_tooltip(unlock, level, maxed, locked)


## A short "current total effect" number for the square itself (the full
## sentence-form stat line already lives in RunPerk.get_stat_summary(),
## used in the tooltip below instead — too long to fit here). Every
## shipped non-capstone MetaUnlockData only sets ONE axis, and a capstone
## setting two just shows the first — acceptable for a square this small.
func _format_bonus_short(unlock : MetaUnlockData, level : int) -> String:
	if level <= 0:
		return BONUS_NEUTRAL_TEXT

	if unlock.quality_bonus != 0.0:
		return "+%.2f" % (unlock.quality_bonus * level)
	if unlock.ingredient_refund_chance != 0.0:
		return "%d%%" % roundi(unlock.ingredient_refund_chance * level * 100)
	if unlock.tip_double_chance != 0.0:
		return "%d%%" % roundi(unlock.tip_double_chance * level * 100)
	if unlock.extra_raid_strikes != 0:
		return "+%d" % (unlock.extra_raid_strikes * level)
	if unlock.raid_hidden_batch_count != 0:
		return "%d" % (unlock.raid_hidden_batch_count * level)

	var scaled : RunPerk = unlock.get_scaled_perk(level)
	for value : float in [
		scaled.reputation_gain_multiplier,
		scaled.tip_income_multiplier,
		scaled.raid_threshold_multiplier,
		scaled.distribution_income_multiplier,
		scaled.ingredient_price_multiplier,
		scaled.brew_yield_multiplier,
		scaled.peak_speed_multiplier,
		scaled.decline_rate_multiplier,
		scaled.spawn_interval_multiplier,
		scaled.agentti_appearance_multiplier,
		scaled.mafioso_appearance_multiplier,
		scaled.bar_fight_chance_multiplier,
		scaled.counter_price_multiplier,
		scaled.group_event_interval_multiplier,
	]:
		if value != 1.0:
			return "%+d%%" % roundi((value - 1.0) * 100)

	return BONUS_NEUTRAL_TEXT


func _build_tooltip(unlock : MetaUnlockData, level : int, maxed : bool, locked : bool) -> String:
	var lines : PackedStringArray = [unlock.perk_name, unlock.description]

	if locked:
		var prereq_names : PackedStringArray = []
		for prereq_id : String in unlock.prerequisite_ids:
			var prereq : MetaUnlockData = MetaProgressManager.find_unlock(prereq_id)
			if prereq != null and MetaProgressManager.get_node_level(prereq_id) <= 0:
				prereq_names.append(prereq.perk_name)
		lines.append(TOOLTIP_LOCKED_FORMAT % ", ".join(prereq_names))
		return "\n".join(lines)

	if level > 0:
		var current_summary : String = unlock.get_scaled_perk(level).get_stat_summary()
		if not current_summary.is_empty():
			lines.append(TOOLTIP_CURRENT_FORMAT % current_summary)

	lines.append(TOOLTIP_MAXED_TEXT if maxed else TOOLTIP_NEXT_LEVEL_FORMAT % unlock.renown_cost_per_level)

	return "\n".join(lines)
