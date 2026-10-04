class_name LeaderboardWindow
extends Panel

## The leaderboard as a table, rebuilt from LeaderboardManager each time it opens:
## podium colors for the top three, the ending in its own color, the score breakdown
## in each row's tooltip and a tag on the run recorded this session. Opened by
## GUISignals.leaderboard_requested from the main menu and the in-game menu;
## process_mode is ALWAYS so it works while the game menu pauses the tree.

const TITLE_TEXT : String = "Ennätykset"
const CLOSE_BUTTON_TEXT : String = "Sulje"
const EMPTY_TEXT : String = "Ei vielä ennätyksiä. Pelaa ensimmäinen kausi!"
const CURRENT_RUN_FORMAT : String = "Tämä kausi nyt: sijoittuisi #%d"
const NEW_TAG : String = "UUSI!"
const HEADERS : PackedStringArray = ["#", "Tulos", "Pisteet", "Pv", "Maine", "Annokset", "Olosuhteet"]
## Minimum widths of the columns above; the last one takes the rest.
const COLUMN_WIDTHS : Array[int] = [30, 74, 62, 28, 46, 66, 0]
const ROW_FONT_SIZE : int = 14
const SCORE_FONT_SIZE : int = 16
const HEADER_FONT_SIZE : int = 12
const STRIPE_COLOR : Color = Color(1, 1, 1, 0.05)
const HIGHLIGHT_COLOR : Color = Color(0.97, 0.46, 0.13, 0.18)
const MUTED_COLOR : Color = Color(0.75, 0.73, 0.67, 1)

## Set on the in-game instance: shows where the run in progress would rank.
@export var show_current_run : bool = false

@onready var title_label : Label = %TitleLabel
@onready var close_button : Button = %CloseButton
@onready var current_run_vbox : VBoxContainer = %CurrentRunVBox
@onready var current_run_caption : Label = %CurrentRunCaption
@onready var current_run_holder : VBoxContainer = %CurrentRunHolder
@onready var columns_holder : VBoxContainer = %ColumnsHolder
@onready var rows_vbox : VBoxContainer = %RowsVBox


func _ready() -> void:
	title_label.text = TITLE_TEXT
	close_button.text = CLOSE_BUTTON_TEXT
	close_button.pressed.connect(_on_close_button_pressed)
	GUISignals.leaderboard_requested.connect(_on_leaderboard_requested)
	columns_holder.add_child(_build_header_row())
	hide()


func _on_leaderboard_requested() -> void:
	_refresh_current_run()
	_refresh_rows()
	show()


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
	current_run_holder.add_child(_build_row(rank, entry, HIGHLIGHT_COLOR, false))


func _refresh_rows() -> void:
	_clear(rows_vbox)
	var entries : Array = LeaderboardManager.get_entries()
	if entries.is_empty():
		var empty_label := Label.new()
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.text = EMPTY_TEXT
		rows_vbox.add_child(empty_label)
		return

	for i : int in entries.size():
		var entry : Dictionary = entries[i]
		var is_new : bool = _is_last_entry(entry)
		var background : Color = HIGHLIGHT_COLOR if is_new else (STRIPE_COLOR if i % 2 == 0 else Color.TRANSPARENT)
		rows_vbox.add_child(_build_row(i + 1, entry, background, is_new))


func _is_last_entry(entry : Dictionary) -> bool:
	var last : Dictionary = LeaderboardManager.last_entry
	return not last.is_empty() and entry.get("date", "") == last.get("date", "") and entry.get("score", -1) == last.get("score", -2)


func _build_header_row() -> PanelContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i : int in HEADERS.size():
		var label : Label = _cell(row, i, HEADERS[i], HEADER_FONT_SIZE, MUTED_COLOR)
		label.horizontal_alignment = _column_alignment(i)
	return _padded(row, Color.TRANSPARENT)


func _build_row(rank : int, entry : Dictionary, background : Color, is_new : bool) -> PanelContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ending : String = entry.get("ending_type", "")
	var values : Array = [
		"%d" % rank,
		LeaderboardText.ending_label(ending),
		"%d" % entry.get("score", 0),
		"%d" % entry.get("days_survived", 0),
		"%d" % entry.get("reputation", 0),
		"%d" % entry.get("lifetime_bottles_sold", 0),
		tr(entry.get("modifier_name", "")) + (" " + tr(NEW_TAG) if is_new else ""),
	]
	var colors : Array[Color] = [LeaderboardText.rank_color(rank), LeaderboardText.ending_color(ending), LeaderboardText.rank_color(rank),
		LeaderboardText.DEFAULT_COLOR, LeaderboardText.DEFAULT_COLOR, LeaderboardText.DEFAULT_COLOR, MUTED_COLOR]
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
