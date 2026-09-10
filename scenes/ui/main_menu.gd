class_name MainMenu
extends Control


const TITLE_TEXT: String = "Pimeä Panimo"
const START_BUTTON_TEXT: String = "Aloita Peli"
const OPTIONS_BUTTON_TEXT: String = "Asetukset"
const QUIT_BUTTON_TEXT: String = "Lopeta Peli"
const CONTINUE_BUTTON_TEXT: String = "Jatka Peliä"
const NEW_GAME_BUTTON_TEXT: String = "Aloita uusi peli"
const BACK_BUTTON_TEXT: String = "Takaisin"

const GAME_SCENE_PATH: String = "res://scenes/main.tscn"

@onready var title_label: Label = $TitleLabel

@onready var root_menu_view: VBoxContainer = $CenterContainer/RootMenuView
@onready var start_game_view: VBoxContainer = $CenterContainer/StartGameView

@onready var start_button: Button = $CenterContainer/RootMenuView/StartButton
@onready var options_button: Button = $CenterContainer/RootMenuView/OptionsButton
@onready var quit_button: Button = $CenterContainer/RootMenuView/QuitButton

@onready var continue_button: Button = $CenterContainer/StartGameView/ContinueButton
@onready var new_game_button: Button = $CenterContainer/StartGameView/NewGameButton
@onready var back_button: Button = $CenterContainer/StartGameView/BackButton


func _ready() -> void:
	title_label.text = TITLE_TEXT
	start_button.text = START_BUTTON_TEXT
	options_button.text = OPTIONS_BUTTON_TEXT
	quit_button.text = QUIT_BUTTON_TEXT
	continue_button.text = CONTINUE_BUTTON_TEXT
	new_game_button.text = NEW_GAME_BUTTON_TEXT
	back_button.text = BACK_BUTTON_TEXT

	start_button.pressed.connect(_on_start_button_pressed)
	options_button.pressed.connect(_on_options_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	new_game_button.pressed.connect(_on_new_game_button_pressed)
	continue_button.pressed.connect(_on_continue_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)

	continue_button.visible = SaveManager.has_save()

	# Nothing should simulate (least of all autosave-on-day-change) while
	# the player is just sitting at the menu — otherwise a stray day
	# rollover here would silently overwrite a real save with whatever
	# fresh/idle Brewery happens to be current at that moment.
	TimeManager.pause_time()

	_show_root_menu_view()


func _show_root_menu_view() -> void:
	root_menu_view.show()
	start_game_view.hide()


func _show_start_game_view() -> void:
	root_menu_view.hide()
	start_game_view.show()


func _on_start_button_pressed() -> void:
	GUISignals.menu_button_pressed.emit()
	_show_start_game_view()


func _on_back_button_pressed() -> void:
	GUISignals.menu_button_pressed.emit()
	_show_root_menu_view()


func _on_new_game_button_pressed() -> void:
	GUISignals.menu_button_pressed.emit()
	BrewEngine.start_new_game()
	TimeManager.resume_time()
	get_tree().change_scene_to_file(GAME_SCENE_PATH)


func _on_continue_button_pressed() -> void:
	GUISignals.menu_button_pressed.emit()
	SaveManager.load_game()
	TimeManager.resume_time()
	get_tree().change_scene_to_file(GAME_SCENE_PATH)


func _on_options_button_pressed() -> void:
	GUISignals.options_requested.emit()


func _on_quit_button_pressed() -> void:
	GUISignals.menu_button_pressed.emit()
	get_tree().quit()
