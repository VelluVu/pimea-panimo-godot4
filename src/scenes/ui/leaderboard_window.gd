class_name LeaderboardWindow
extends Panel

## Mirrors RecipeLibraryWindow's shape: a Panel with a header (title +
## close), a ScrollContainer/RowsVBox rebuilt in code from
## LeaderboardManager.get_entries() each time the window opens. Only
## instanced in main_menu.tscn — GameEndWindow (src/scenes/main.tscn) shows
## just an inline rank line instead of the full browsable list.

@onready var title_label : Label = $MarginContainer/MainVBox/HeaderHBox/TitleLabel
@onready var close_button : Button = $MarginContainer/MainVBox/HeaderHBox/CloseButton
@onready var rows_vbox : VBoxContainer = $MarginContainer/MainVBox/ScrollContainer/RowsVBox


func _ready() -> void:
	title_label.text = StringContainer.LEADERBOARD_TITLE
	close_button.text = StringContainer.LEADERBOARD_CLOSE_TEXT

	close_button.pressed.connect(_on_close_button_pressed)
	GUISignals.leaderboard_requested.connect(_on_leaderboard_requested)

	hide()


func _on_leaderboard_requested() -> void:
	_refresh_rows()
	show()


func _on_close_button_pressed() -> void:
	GUISignals.leaderboard_closed.emit()
	hide()


func _refresh_rows() -> void:
	for child in rows_vbox.get_children():
		child.queue_free()

	var entries : Array = LeaderboardManager.get_entries()

	if entries.is_empty():
		var empty_label := Label.new()
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.text = StringContainer.LEADERBOARD_EMPTY_STRING
		rows_vbox.add_child(empty_label)
		return

	for i in range(entries.size()):
		rows_vbox.add_child(_build_row(i + 1, entries[i]))


func _build_row(rank : int, entry : Dictionary) -> Label:
	var row_label := Label.new()
	row_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row_label.add_theme_font_size_override("font_size", 14)
	row_label.text = StringContainer.LEADERBOARD_ROW_FORMAT % [
		rank,
		_ending_type_label(entry.get("ending_type", "")),
		entry.get("days_survived", 0),
		entry.get("reputation", 0),
		entry.get("lifetime_bottles_sold", 0),
		_format_date(entry.get("date", "")),
		entry.get("modifier_name", ""),
		entry.get("score", 0),
	]
	return row_label


## Reformats LeaderboardManager's stored ISO 8601 timestamp
## ("2026-09-13T10:27:33") into a Finnish "pp.kk.vvvv" date for display,
## dropping the time-of-day a trophy list has no use for.
func _format_date(iso_datetime : String) -> String:
	if iso_datetime.is_empty():
		return ""
	var parts : Dictionary = Time.get_datetime_dict_from_datetime_string(iso_datetime, false)
	return "%02d.%02d.%04d" % [parts["day"], parts["month"], parts["year"]]


func _ending_type_label(ending_type : String) -> String:
	match ending_type:
		"busted":
			return StringContainer.LEADERBOARD_ENDING_BUSTED
		"bankrupt":
			return StringContainer.LEADERBOARD_ENDING_BANKRUPT
		"survived":
			return StringContainer.LEADERBOARD_ENDING_SURVIVED
		_:
			return ending_type
