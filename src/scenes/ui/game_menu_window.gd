class_name GameMenuWindow
extends Panel

## In-game pause menu: resume, settings, achievements, leaderboard, a new run and
## back to the main menu (the last two behind a confirmation). The only place a run
## is left from, so GameEndWindow can stay informative. Pauses the SceneTree while
## open, so the instance needs process_mode = ALWAYS. While the settings,
## achievements or leaderboard window is up this menu hides itself and comes back
## when that window closes.

const MAIN_MENU_SCENE_PATH: String = "res://src/scenes/ui/main_menu.tscn"
const GAME_SCENE_PATH: String = "res://src/scenes/main.tscn"
const TITLE_TEXT: String = "Valikko"
const RESUME_BUTTON_TEXT: String = "Jatka"
const OPTIONS_BUTTON_TEXT: String = "Asetukset"
const ACHIEVEMENTS_BUTTON_TEXT: String = "Saavutukset"
const NEW_RUN_BUTTON_TEXT: String = "Uusi kausi"
const MAIN_MENU_BUTTON_TEXT: String = "Päävalikkoon"
const CONFIRM_MAIN_MENU_TEXT: String = "Palataanko päävalikkoon? Peli tallennetaan."
const CONFIRM_NEW_RUN_TEXT: String = "Aloitetaanko uusi kausi? Tämä kausi jää kesken."
const CONFIRM_YES_TEXT: String = "Kyllä"
const CONFIRM_NO_TEXT: String = "Ei"

@onready var title_label: Label = %TitleLabel
@onready var buttons_vbox: VBoxContainer = %ButtonsVBox
@onready var resume_button: Button = %ResumeButton
@onready var options_button: Button = %OptionsButton
@onready var achievements_button: Button = %AchievementsButton
@onready var leaderboard_button: Button = %LeaderboardButton
@onready var new_run_button: Button = %NewRunButton
@onready var main_menu_button: Button = %MainMenuButton
@onready var confirm_vbox: VBoxContainer = %ConfirmVBox
@onready var confirm_label: Label = %ConfirmLabel
@onready var yes_button: Button = %YesButton
@onready var no_button: Button = %NoButton
@onready var modifier_select_window: ModifierSelectWindow = $"../ModifierSelectWindow"

## True from opening until resuming or leaving, including while a sub-window
## (settings, achievements, leaderboard) has this menu hidden.
var _is_open: bool = false
## What the confirmation's yes button does.
var _confirmed_action: Callable


func _ready() -> void:
	title_label.text = TITLE_TEXT
	resume_button.text = RESUME_BUTTON_TEXT
	options_button.text = OPTIONS_BUTTON_TEXT
	achievements_button.text = ACHIEVEMENTS_BUTTON_TEXT
	leaderboard_button.text = StringContainer.LEADERBOARD_BUTTON_TEXT
	new_run_button.text = NEW_RUN_BUTTON_TEXT
	main_menu_button.text = MAIN_MENU_BUTTON_TEXT
	yes_button.text = CONFIRM_YES_TEXT
	no_button.text = CONFIRM_NO_TEXT

	resume_button.pressed.connect(_close)
	options_button.pressed.connect(_open_sub_window.bind(GUISignals.options_requested))
	achievements_button.pressed.connect(_open_sub_window.bind(GUISignals.achievements_requested))
	leaderboard_button.pressed.connect(_open_sub_window.bind(GUISignals.leaderboard_requested))
	new_run_button.pressed.connect(_confirm.bind(CONFIRM_NEW_RUN_TEXT, _start_new_run))
	main_menu_button.pressed.connect(_confirm.bind(CONFIRM_MAIN_MENU_TEXT, _go_to_main_menu))
	yes_button.pressed.connect(func() -> void: _confirmed_action.call())
	no_button.pressed.connect(_show_confirm.bind(false))
	modifier_select_window.modifier_chosen.connect(_on_modifier_chosen)

	GUISignals.game_menu_requested.connect(_open)
	GUISignals.options_closed.connect(_on_sub_window_closed)
	GUISignals.achievements_closed.connect(_on_sub_window_closed)
	GUISignals.leaderboard_closed.connect(_on_sub_window_closed)

	hide()


func _open() -> void:
	if _is_open:
		return
	_is_open = true
	get_tree().paused = true
	# After a bust or bankruptcy there is nothing to resume: only a new run or the main menu.
	resume_button.visible = not _is_run_over()
	_show_confirm(false)
	show()


func _close() -> void:
	if _is_run_over():
		return
	_is_open = false
	get_tree().paused = false
	hide()
	GUISignals.game_menu_closed.emit()


func _is_run_over() -> bool:
	var brewery: Brewery = BrewEngine.current_brewery
	return brewery != null and brewery.game_has_ended


## Esc resumes, or backs out of the confirmation first. Only while visible, so
## an open sub-window (which hides this menu) gets its own Esc.
func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(InputManager.ACTION_CANCEL):
		if confirm_vbox.visible:
			_show_confirm(false)
		else:
			_close()
		get_viewport().set_input_as_handled()


func _open_sub_window(request: Signal) -> void:
	hide()
	request.emit()


func _on_sub_window_closed() -> void:
	if _is_open:
		show()


## A run that is already over has nothing to lose, so it skips the question.
func _confirm(text: String, action: Callable) -> void:
	if _is_run_over():
		action.call()
		return
	_confirmed_action = action
	confirm_label.text = text
	_show_confirm(true)


func _show_confirm(confirming: bool) -> void:
	confirm_vbox.visible = confirming
	buttons_vbox.visible = not confirming


## Stays paused while the modifier is picked; _on_modifier_chosen starts the run.
func _start_new_run() -> void:
	hide()
	modifier_select_window.open()


func _on_modifier_chosen(modifier: RunModifier) -> void:
	_is_open = false
	get_tree().paused = false
	BrewEngine.start_new_game(modifier)
	TimeManager.resume_time()
	get_tree().change_scene_to_file(GAME_SCENE_PATH)


func _go_to_main_menu() -> void:
	GUISignals.menu_button_pressed.emit()
	SaveManager.save_game()
	_is_open = false
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
