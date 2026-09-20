class_name GameMenuWindow
extends Panel

## In-game pause menu: resume, settings, achievements, and back to the main
## menu (behind a confirmation). Pauses the SceneTree while open, so the
## instance needs process_mode = ALWAYS. While the settings or achievements
## window is up this menu hides itself and comes back when that window closes.

const MAIN_MENU_SCENE_PATH: String = "res://scenes/ui/main_menu.tscn"
const TITLE_TEXT: String = "Valikko"
const RESUME_BUTTON_TEXT: String = "Jatka"
const OPTIONS_BUTTON_TEXT: String = "Asetukset"
const ACHIEVEMENTS_BUTTON_TEXT: String = "Saavutukset"
const MAIN_MENU_BUTTON_TEXT: String = "Päävalikkoon"
const CONFIRM_TEXT: String = "Palataanko päävalikkoon? Peli tallennetaan."
const CONFIRM_YES_TEXT: String = "Kyllä"
const CONFIRM_NO_TEXT: String = "Ei"

@onready var title_label: Label = $MarginContainer/MainVBox/TitleLabel
@onready var buttons_vbox: VBoxContainer = $MarginContainer/MainVBox/ButtonsVBox
@onready var resume_button: Button = $MarginContainer/MainVBox/ButtonsVBox/ResumeButton
@onready var options_button: Button = $MarginContainer/MainVBox/ButtonsVBox/OptionsButton
@onready var achievements_button: Button = $MarginContainer/MainVBox/ButtonsVBox/AchievementsButton
@onready var main_menu_button: Button = $MarginContainer/MainVBox/ButtonsVBox/MainMenuButton
@onready var confirm_vbox: VBoxContainer = $MarginContainer/MainVBox/ConfirmVBox
@onready var confirm_label: Label = $MarginContainer/MainVBox/ConfirmVBox/ConfirmLabel
@onready var yes_button: Button = $MarginContainer/MainVBox/ConfirmVBox/ConfirmButtonsHBox/YesButton
@onready var no_button: Button = $MarginContainer/MainVBox/ConfirmVBox/ConfirmButtonsHBox/NoButton

## True from opening until resuming or leaving, including while a sub-window
## (settings, achievements) has this menu hidden.
var _is_open: bool = false


func _ready() -> void:
	title_label.text = TITLE_TEXT
	resume_button.text = RESUME_BUTTON_TEXT
	options_button.text = OPTIONS_BUTTON_TEXT
	achievements_button.text = ACHIEVEMENTS_BUTTON_TEXT
	main_menu_button.text = MAIN_MENU_BUTTON_TEXT
	confirm_label.text = CONFIRM_TEXT
	yes_button.text = CONFIRM_YES_TEXT
	no_button.text = CONFIRM_NO_TEXT

	resume_button.pressed.connect(_close)
	options_button.pressed.connect(_open_sub_window.bind(GUISignals.options_requested))
	achievements_button.pressed.connect(_open_sub_window.bind(GUISignals.achievements_requested))
	main_menu_button.pressed.connect(_show_confirm.bind(true))
	yes_button.pressed.connect(_on_confirm_yes_pressed)
	no_button.pressed.connect(_show_confirm.bind(false))

	GUISignals.game_menu_requested.connect(_open)
	GUISignals.options_closed.connect(_on_sub_window_closed)
	GUISignals.achievements_closed.connect(_on_sub_window_closed)

	hide()


func _open() -> void:
	if _is_open:
		return
	_is_open = true
	get_tree().paused = true
	_show_confirm(false)
	show()


func _close() -> void:
	_is_open = false
	get_tree().paused = false
	hide()
	GUISignals.game_menu_closed.emit()


## Esc resumes, or backs out of the confirmation first. Only while visible, so
## an open sub-window (which hides this menu) gets its own Esc.
func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
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


func _show_confirm(confirming: bool) -> void:
	confirm_vbox.visible = confirming
	buttons_vbox.visible = not confirming


func _on_confirm_yes_pressed() -> void:
	GUISignals.menu_button_pressed.emit()
	SaveManager.save_game()
	_is_open = false
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
