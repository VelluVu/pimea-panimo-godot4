class_name LeaderboardWindow
extends Panel

## The leaderboard as a table, rebuilt from LeaderboardManager each time it opens:
## podium colors for the top three, the ending in its own color, the score breakdown
## in each row's tooltip and a tag on the run recorded this session. Opened by
## GUISignals.leaderboard_requested from the main menu and the in-game menu;
## process_mode is ALWAYS so it works while the game menu pauses the tree.
## Where the shared demo list exists (OnlineLeaderboardWiring), tabs switch between
## this player's runs and everyone's top runs.

const TITLE_TEXT : String = "Ennätykset"
const CLOSE_BUTTON_TEXT : String = "Sulje"
const EMPTY_TEXT : String = "Ei vielä ennätyksiä. Pelaa ensimmäinen kausi!"
const CURRENT_RUN_FORMAT : String = "Tämä kausi nyt: sijoittuisi #%d"
const NEW_TAG : String = "UUSI!"
const HEADERS : PackedStringArray = ["#", "Tulos", "Pisteet", "Pv", "Maine", "Annokset", ""]
const GLOBAL_LAST_HEADER : String = "Nimi"
const LOCAL_TAB_TEXT : String = "Paikallinen"
const GLOBAL_TAB_TEXT : String = "Maailmanlaajuinen"
const LOADING_TEXT : String = "Ladataan..."
const GLOBAL_EMPTY_TEXT : String = "Ei vielä tuloksia. Ole ensimmäinen!"
const GLOBAL_TOP_COUNT : int = 50
## Minimum widths of the columns above; the last one takes the rest.
const COLUMN_WIDTHS : Array[int] = [30, 74, 62, 28, 46, 66, 0]
const ROW_FONT_SIZE : int = 14
const COLUMN_SEPARATION : int = 10
const SCORE_FONT_SIZE : int = 16
const HEADER_FONT_SIZE : int = 12
const STRIPE_COLOR : Color = Color(1, 1, 1, 0.05)
const HIGHLIGHT_COLOR : Color = Color(0.97, 0.46, 0.13, 0.18)
const MUTED_COLOR : Color = Color(0.75, 0.73, 0.67, 1)

## Set on the in-game instance: shows where the run in progress would rank.
@export var show_current_run : bool = false

@onready var title_label : Label = %TitleLabel
@onready var tabs_hbox : HBoxContainer = %TabsHBox
@onready var local_tab_button : Button = %LocalTabButton
@onready var global_tab_button : Button = %GlobalTabButton
@onready var close_button : Button = %CloseButton
@onready var current_run_vbox : VBoxContainer = %CurrentRunVBox
@onready var current_run_caption : Label = %CurrentRunCaption
@onready var current_run_holder : VBoxContainer = %CurrentRunHolder
@onready var columns_holder : VBoxContainer = %ColumnsHolder
@onready var rows_vbox : VBoxContainer = %RowsVBox

var _online : OnlineLeaderboardWiring
var _global_tab : bool = false


func _ready() -> void:
	title_label.text = TITLE_TEXT
	close_button.text = CLOSE_BUTTON_TEXT
	close_button.pressed.connect(_on_close_button_pressed)
	GUISignals.leaderboard_requested.connect(_on_leaderboard_requested)
	_online = OnlineLeaderboardWiring.new()
	add_child(_online)
	_online.top_received.connect(_on_global_rows_received)
	_online.request_failed.connect(_on_global_request_failed)
	local_tab_button.text = LOCAL_TAB_TEXT
	global_tab_button.text = GLOBAL_TAB_TEXT
	var tab_group := ButtonGroup.new()
	local_tab_button.button_group = tab_group
	global_tab_button.button_group = tab_group
	local_tab_button.pressed.connect(_show_tab.bind(false))
	global_tab_button.pressed.connect(_show_tab.bind(true))
	hide()


## Opens on this player's own runs.
func _on_leaderboard_requested() -> void:
	tabs_hbox.visible = _online.is_enabled()
	local_tab_button.button_pressed = true
	_show_tab(false)
	move_to_front()
	show()


func _show_tab(global : bool) -> void:
	_global_tab = global
	_clear(columns_holder)
	columns_holder.add_child(_build_header_row())
	if global:
		current_run_vbox.hide()
		_show_message(LOADING_TEXT)
		_online.fetch_top(GLOBAL_TOP_COUNT)
	else:
		_refresh_current_run()
		_refresh_rows()


## A reply for a tab no longer open is dropped.
func _on_global_rows_received(rows : Array) -> void:
	if not _global_tab:
		return
	if rows.is_empty():
		_show_message(GLOBAL_EMPTY_TEXT)
		return
	_clear(rows_vbox)
	var own_row_id : int = _online.last_row_id()
	for i : int in rows.size():
		var entry : Dictionary = OnlineLeaderboardWiring.entry_from_row(rows[i])
		var is_own : bool = own_row_id != 0 and entry["id"] == own_row_id
		var background : Color = HIGHLIGHT_COLOR if is_own else (STRIPE_COLOR if i % 2 == 0 else Color.TRANSPARENT)
		rows_vbox.add_child(_build_row(i + 1, entry, background, entry["nickname"], LeaderboardText.DEFAULT_COLOR))


func _on_global_request_failed(action : StringName, message : String) -> void:
	if _global_tab and action == OnlineLeaderboard.ACTION_FETCH:
		_show_message(OnlineLeaderboardWiring.failure_text(action, message))


func _on_close_button_pressed() -> void:
	GUISignals.leaderboard_closed.emit()
	hide()


## Closes on Esc before the game menu (also ALWAYS) sees it.
func _input(event : InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(InputManager.ACTION_CANCEL):
		_on_close_button_pressed()
		get_viewport().set_input_as_handled()


## Hidden once the season is scored: the run is then already on the list.
func _refresh_current_run() -> void:
	_clear(current_run_holder)
	var brewery : Brewery = BrewEngine.current_brewery
	current_run_vbox.visible = show_current_run and brewery != null and not brewery.has_continued_past_survival and not brewery.game_has_ended
	if not current_run_vbox.visible:
		return
	var entry : Dictionary = RunScore.entry_for(brewery, "")
	var rank : int = LeaderboardManager.get_rank(entry["score"])
	current_run_caption.text = tr(CURRENT_RUN_FORMAT) % rank
	current_run_holder.add_child(_build_row(rank, entry, HIGHLIGHT_COLOR, "", MUTED_COLOR))


func _refresh_rows() -> void:
	var entries : Array = LeaderboardManager.get_entries()
	if entries.is_empty():
		_show_message(EMPTY_TEXT)
		return
	_clear(rows_vbox)

	for i : int in entries.size():
		var entry : Dictionary = entries[i]
		var is_new : bool = _is_last_entry(entry)
		var background : Color = HIGHLIGHT_COLOR if is_new else (STRIPE_COLOR if i % 2 == 0 else Color.TRANSPARENT)
		rows_vbox.add_child(_build_row(i + 1, entry, background, tr(NEW_TAG) if is_new else "", MUTED_COLOR))


func _show_message(text : String) -> void:
	_clear(rows_vbox)
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = text
	rows_vbox.add_child(label)


func _is_last_entry(entry : Dictionary) -> bool:
	var last : Dictionary = LeaderboardManager.last_entry
	return not last.is_empty() and entry.get("date", "") == last.get("date", "") and entry.get("score", -1) == last.get("score", -2)


func _build_header_row() -> PanelContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", COLUMN_SEPARATION)
	var headers : PackedStringArray = HEADERS.duplicate()
	if _global_tab:
		headers[headers.size() - 1] = tr(GLOBAL_LAST_HEADER)
	for i : int in headers.size():
		var label : Label = _cell(row, i, headers[i], HEADER_FONT_SIZE, MUTED_COLOR)
		label.horizontal_alignment = _column_alignment(i)
	return _padded(row, Color.TRANSPARENT)


## `last_text` fills the wide last column: the new-run tag, or a player's name.
func _build_row(rank : int, entry : Dictionary, background : Color, last_text : String, last_color : Color) -> PanelContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", COLUMN_SEPARATION)
	var ending : String = entry.get("ending_type", "")
	var values : Array = [
		"%d" % rank,
		LeaderboardText.ending_label(ending),
		"%d" % entry.get("score", 0),
		"%d" % entry.get("days_survived", 0),
		"%d" % entry.get("reputation", 0),
		"%d" % entry.get("lifetime_bottles_sold", 0),
		last_text,
	]
	var colors : Array[Color] = [LeaderboardText.rank_color(rank), LeaderboardText.ending_color(ending), LeaderboardText.rank_color(rank),
		LeaderboardText.DEFAULT_COLOR, LeaderboardText.DEFAULT_COLOR, LeaderboardText.DEFAULT_COLOR, last_color]
	for i : int in values.size():
		var font_size : int = SCORE_FONT_SIZE if i == 2 else ROW_FONT_SIZE
		var label : Label = _cell(row, i, values[i], font_size, colors[i])
		label.horizontal_alignment = _column_alignment(i)

	var panel : PanelContainer = _padded(row, background)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.tooltip_text = _tooltip(entry)
	return panel


func _cell(row : HBoxContainer, column : int, text : String, font_size : int, color : Color) -> Label:
	var label := Label.new()
	# Already translated, and a player's name must not be.
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if COLUMN_WIDTHS[column] > 0:
		label.custom_minimum_size.x = COLUMN_WIDTHS[column]
	else:
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(label)
	return label


## Numbers line up on the right, text on the left.
func _column_alignment(column : int) -> HorizontalAlignment:
	return HORIZONTAL_ALIGNMENT_RIGHT if column in [2, 3, 4, 5] else HORIZONTAL_ALIGNMENT_LEFT


func _padded(row : HBoxContainer, background : Color) -> PanelContainer:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", style)
	panel.add_child(row)
	return panel


func _tooltip(entry : Dictionary) -> String:
	var date : String = LeaderboardText.format_date(entry.get("date", ""))
	var text : String = LeaderboardText.breakdown(entry)
	return text if date.is_empty() else "%s\n%s" % [text, date]


func _clear(container : Node) -> void:
	for child : Node in container.get_children():
		child.queue_free()
