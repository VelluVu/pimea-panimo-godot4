class_name AchievementsWindow
extends Panel

## Lists every achievement, unlocked ones first, with progress toward the
## locked ones. Rebuilt from AchievementManager each time the window opens.
## Opened by GUISignals.achievements_requested from the main menu and the
## in-game menu; process_mode must be ALWAYS on the instance so it still works
## while the tree is paused behind the game menu.

const TITLE_FORMAT: String = "Saavutukset (%d/%d)"
const CLOSE_BUTTON_TEXT: String = "Sulje"
const EMPTY_TEXT: String = "Ei saavutuksia."
const UNLOCKED_ROW_FORMAT: String = "[x] %s\n%s"
const LOCKED_ROW_FORMAT: String = "[ ] %s\n%s (%d/%d)"
const LOCKED_ROW_COLOR: Color = Color(0.6, 0.6, 0.6)
const UNLOCKED_ROW_COLOR: Color = Color(0.95, 0.79, 0.42)
const ROW_FONT_SIZE: int = 14

@onready var title_label: Label = $MarginContainer/MainVBox/HeaderHBox/TitleLabel
@onready var close_button: Button = $MarginContainer/MainVBox/HeaderHBox/CloseButton
@onready var rows_vbox: VBoxContainer = $MarginContainer/MainVBox/ScrollContainer/RowsVBox


func _ready() -> void:
	close_button.text = CLOSE_BUTTON_TEXT
	close_button.pressed.connect(_on_close_button_pressed)
	GUISignals.achievements_requested.connect(_on_achievements_requested)
	hide()


func _on_achievements_requested() -> void:
	_refresh_rows()
	show()


func _on_close_button_pressed() -> void:
	GUISignals.achievements_closed.emit()
	hide()


## Closes on Esc before the game menu (also ALWAYS) sees it, so Esc peels off
## one layer at a time.
func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_on_close_button_pressed()
		get_viewport().set_input_as_handled()


func _refresh_rows() -> void:
	for child in rows_vbox.get_children():
		child.queue_free()

	var pool: Array[AchievementData] = AchievementManager.achievement_pool
	var unlocked: Array[AchievementData] = []
	var locked: Array[AchievementData] = []
	for achievement in pool:
		if AchievementManager.is_unlocked(achievement.achievement_id):
			unlocked.append(achievement)
		else:
			locked.append(achievement)

	title_label.text = TITLE_FORMAT % [unlocked.size(), pool.size()]

	if pool.is_empty():
		rows_vbox.add_child(_build_row(EMPTY_TEXT, LOCKED_ROW_COLOR))
		return

	for achievement in unlocked:
		rows_vbox.add_child(_build_row(UNLOCKED_ROW_FORMAT % [achievement.title, achievement.description], UNLOCKED_ROW_COLOR))
	for achievement in locked:
		var progress: int = mini(AchievementManager.get_stat(achievement.stat_key), achievement.target_value)
		rows_vbox.add_child(_build_row(LOCKED_ROW_FORMAT % [achievement.title, achievement.description, progress, achievement.target_value], LOCKED_ROW_COLOR))


func _build_row(text: String, color: Color) -> Label:
	var row_label := Label.new()
	row_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row_label.add_theme_font_size_override("font_size", ROW_FONT_SIZE)
	row_label.add_theme_color_override("font_color", color)
	row_label.text = text
	return row_label
