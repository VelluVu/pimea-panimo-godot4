class_name AchievementsWindow
extends Panel

## Shows every achievement as a grid of tiles, unlocked ones first. Details
## and progress are in each tile's tooltip. Rebuilt from AchievementManager
## each time the window opens.
## Opened by GUISignals.achievements_requested from the main menu and the
## in-game menu; process_mode must be ALWAYS on the instance so it still works
## while the tree is paused behind the game menu.

const TITLE_FORMAT: String = "Saavutukset (%d/%d)"
const CLOSE_BUTTON_TEXT: String = "Sulje"

@onready var title_label: Label = $MarginContainer/MainVBox/HeaderHBox/TitleLabel
@onready var close_button: Button = $MarginContainer/MainVBox/HeaderHBox/CloseButton
@onready var tiles_grid: GridContainer = $MarginContainer/MainVBox/ScrollContainer/TilesGrid


func _ready() -> void:
	close_button.text = CLOSE_BUTTON_TEXT
	close_button.pressed.connect(_on_close_button_pressed)
	GUISignals.achievements_requested.connect(_on_achievements_requested)
	hide()


func _on_achievements_requested() -> void:
	_refresh_tiles()
	show()


func _on_close_button_pressed() -> void:
	GUISignals.achievements_closed.emit()
	hide()


## Closes on Esc before the game menu (also ALWAYS) sees it, so Esc peels off
## one layer at a time.
func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(InputManager.ACTION_CANCEL):
		_on_close_button_pressed()
		get_viewport().set_input_as_handled()


func _refresh_tiles() -> void:
	for child in tiles_grid.get_children():
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

	for achievement in unlocked:
		_add_tile(achievement, true)
	for achievement in locked:
		_add_tile(achievement, false)


func _add_tile(achievement: AchievementData, unlocked: bool) -> void:
	var progress: int = mini(AchievementManager.get_stat(achievement.stat_key), achievement.target_value)
	var tile := AchievementTile.new()
	tiles_grid.add_child(tile)
	tile.setup(achievement, unlocked, progress)
