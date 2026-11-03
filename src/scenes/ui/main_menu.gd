class_name MainMenu
extends Control


const TITLE_TEXT: String = "Pimeä Panimo"
const START_BUTTON_TEXT: String = "Aloita peli"
const OLUTOPPI_BUTTON_TEXT: String = "Olutoppi"
const ACHIEVEMENTS_BUTTON_TEXT: String = "Saavutukset"
const OPTIONS_BUTTON_TEXT: String = "Asetukset"
const QUIT_BUTTON_TEXT: String = "Lopeta peli"
const CONTINUE_BUTTON_TEXT: String = "Jatka peliä"
const NEW_GAME_BUTTON_TEXT: String = "Aloita uusi peli"
## The main list's start button while a run is saved; it asks first (NEW_GAME_NOTICE_TEXT).
const NEW_RUN_BUTTON_TEXT: String = "Uusi peli"
const NEW_GAME_NOTICE_TEXT: String = "Uusi peli korvaa tallennetun pelin."
const BACK_BUTTON_TEXT: String = "Takaisin"

const GAME_SCENE_PATH: String = "res://src/scenes/main.tscn"

const TOUCH_BUTTON_SIZE : Vector2 = Vector2(240, 40)
const TOUCH_FONT_SIZE : int = 32

@onready var title_label: Label = %TitleLabel
@onready var save_summary: Label = %SaveSummary
@onready var new_game_warning: Label = %NewGameWarning
@onready var backdrop: MenuBackdrop = $MenuBackdrop
@onready var menu_panel: PanelContainer = $MenuPanel

var _language_switch: LanguageSwitch
## The saved run as SaveManager.peek() read it, for the summary line; null without a save.
var _saved: Brewery = null

@onready var root_menu_view: VBoxContainer = %RootMenuView
@onready var start_game_view: VBoxContainer = %StartGameView

@onready var start_button: Button = %StartButton
@onready var leaderboard_button: Button = %LeaderboardButton
@onready var achievements_button: Button = %AchievementsButton
@onready var olutoppi_button: Button = %OlutoppiButton
@onready var options_button: Button = %OptionsButton
@onready var quit_button: Button = %QuitButton

@onready var continue_button: Button = %ContinueButton
@onready var new_game_button: Button = %NewGameButton
@onready var back_button: Button = %BackButton



func _ready() -> void:
	title_label.text = TITLE_TEXT
	leaderboard_button.text = StringContainer.LEADERBOARD_BUTTON_TEXT
	achievements_button.text = ACHIEVEMENTS_BUTTON_TEXT
	olutoppi_button.text = OLUTOPPI_BUTTON_TEXT
	options_button.text = OPTIONS_BUTTON_TEXT
	quit_button.text = QUIT_BUTTON_TEXT
	continue_button.text = CONTINUE_BUTTON_TEXT
	new_game_button.text = NEW_GAME_BUTTON_TEXT
	back_button.text = BACK_BUTTON_TEXT

	start_button.pressed.connect(_on_start_button_pressed)
	leaderboard_button.pressed.connect(_on_leaderboard_button_pressed)
	achievements_button.pressed.connect(_on_achievements_button_pressed)
	olutoppi_button.pressed.connect(_on_olutoppi_button_pressed)
	options_button.pressed.connect(_on_options_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	# A browser tab cannot be closed by the game.
	quit_button.visible = not OS.has_feature("web")
	add_child(TouchTooltip.new())
	add_child(PortraitNotice.new())
	_add_language_switch()
	# Typing commands needs a keyboard, and the button takes a corner of a small screen.
	# The console shows itself once its key is pressed (DevConsole.hidden_until_opened).
	if DisplayServer.is_touchscreen_available():
		$DevConsole.hide()
	if DisplayServer.is_touchscreen_available():
		_enlarge_buttons_for_touch()
	new_game_button.pressed.connect(_on_new_game_button_pressed)
	continue_button.pressed.connect(_on_continue_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)

	new_game_warning.text = NEW_GAME_NOTICE_TEXT
	_show_save(SaveManager.peek())

	# Nothing may simulate at the menu: a day rollover here would autosave an idle Brewery over
	# the real save.
	TimeManager.pause_time()

	FirstFocus.attach(root_menu_view)
	FirstFocus.attach(start_game_view)
	# Enter must not wipe the save by surprise.
	FirstFocus.prefer(back_button)
	_show_root_menu_view()
	FirstFocus.focus_now.call_deferred(root_menu_view)


## The summary line is built from translated parts, so a language switch rebuilds it.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready() and _saved != null:
		save_summary.text = SaveSummaryText.line(_saved.current_day, _saved.money)


func _show_root_menu_view() -> void:
	root_menu_view.show()
	start_game_view.hide()
	_fit_panel.call_deferred()


func _show_start_game_view() -> void:
	root_menu_view.hide()
	start_game_view.show()
	_fit_panel.call_deferred()


## The two lists differ in height; the panel keeps to the shown one, centred on whole pixels.
func _fit_panel() -> void:
	var height: float = menu_panel.get_combined_minimum_size().y
	menu_panel.offset_top = -floorf(height / 2.0)
	menu_panel.offset_bottom = menu_panel.offset_top + height


## With a save, "Jatka peliä" leads and its line says where the run stands; a new game then
## asks first, since it replaces the save. Without one, Start begins at once.
func _show_save(saved : Brewery) -> void:
	_saved = saved
	var has_save : bool = saved != null
	continue_button.visible = has_save
	save_summary.visible = has_save
	if has_save:
		save_summary.text = SaveSummaryText.line(saved.current_day, saved.money)
	start_button.text = NEW_RUN_BUTTON_TEXT if has_save else START_BUTTON_TEXT
	start_button.theme_type_variation = &"" if has_save else &"PrimaryButton"
	backdrop.show_save(saved)
	_fit_panel.call_deferred()


func _on_start_button_pressed() -> void:
	if not continue_button.visible:
		_on_new_game_button_pressed()
		return
	GUISignals.menu_button_pressed.emit()
	_show_start_game_view()


func _on_back_button_pressed() -> void:
	GUISignals.menu_button_pressed.emit()
	_show_root_menu_view()


func _on_new_game_button_pressed() -> void:
	GUISignals.menu_button_pressed.emit()
	BrewEngine.start_new_game()
	_enter_cellar()


func _on_continue_button_pressed() -> void:
	GUISignals.menu_button_pressed.emit()
	# A save that can't be loaded must not silently start a fresh run as if
	# it had been continued: stay on the menu and take the button away.
	if not SaveManager.load_game():
		_show_save(null)
		return
	_enter_cellar()


## The panel steps aside and the lamps come on before the fade, so the run opens with light.
func _enter_cellar() -> void:
	menu_panel.hide()
	_language_switch.hide()
	await backdrop.lights_on()
	TimeManager.resume_time()
	SceneFade.change_to(get_tree(), GAME_SCENE_PATH)


func _on_leaderboard_button_pressed() -> void:
	GUISignals.leaderboard_requested.emit()


func _on_achievements_button_pressed() -> void:
	GUISignals.achievements_requested.emit()


func _on_olutoppi_button_pressed() -> void:
	GUISignals.olutoppi_requested.emit()


func _on_options_button_pressed() -> void:
	GUISignals.options_requested.emit()


func _on_quit_button_pressed() -> void:
	GUISignals.menu_button_pressed.emit()
	get_tree().quit()


## The windows reach the top corner, so the switch steps aside while one is open.
## The menu panel goes too: it would peek out from behind the window.
func _add_language_switch() -> void:
	var language_switch := LanguageSwitch.new()
	_language_switch = language_switch
	add_child(language_switch)
	var windows : Array[Control] = [$OptionsWindow, $LeaderboardWindow, $OlutoppiWindow, $AchievementsWindow]
	var refresh := func() -> void:
		var no_window : bool = windows.all(func(window : Control) -> bool: return not window.visible)
		language_switch.visible = no_window
		menu_panel.visible = no_window
	for window : Control in windows:
		window.visibility_changed.connect(refresh)
	refresh.call()


## Finger-sized buttons; 32 is twice the pixel font's size, so the text stays sharp.
func _enlarge_buttons_for_touch() -> void:
	for view : VBoxContainer in [root_menu_view, start_game_view]:
		for button : Node in view.get_children():
			if button is Button:
				(button as Button).custom_minimum_size = TOUCH_BUTTON_SIZE
				(button as Button).add_theme_font_size_override("font_size", TOUCH_FONT_SIZE)
