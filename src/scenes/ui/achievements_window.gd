class_name AchievementsWindow
extends Panel

## Every achievement as a tile grid, unlocked first; rebuilt on open. process_mode ALWAYS,
## so it works under the paused game menu.

const TITLE_FORMAT: String = "Saavutukset (%d/%d)"

@onready var title_label: Label = %TitleLabel
@onready var tiles_grid: GridContainer = %TilesGrid


func _ready() -> void:
	WindowCloseButton.attach(self, _on_close_button_pressed)
	GUISignals.achievements_requested.connect(_on_achievements_requested)
	hide()


func _on_achievements_requested() -> void:
	_refresh_tiles()
	move_to_front()
	show()


func _on_close_button_pressed() -> void:
	GUISignals.achievements_closed.emit()
	hide()


## Closes on Esc before the game menu sees it, so Esc peels one layer at a time.
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

	title_label.text = tr(TITLE_FORMAT) % [unlocked.size(), pool.size()]

	for achievement in unlocked:
		_add_tile(achievement, true)
	for achievement in locked:
		_add_tile(achievement, false)


func _add_tile(achievement: AchievementData, unlocked: bool) -> void:
	var progress: int = mini(AchievementManager.get_stat(achievement.stat_key), achievement.target_value)
	var tile := AchievementTile.new()
	tiles_grid.add_child(tile)
	tile.setup(achievement, unlocked, progress)
