class_name OptionsWindow
extends Panel

## Sound, display, input and credits tabs. Pauses the SceneTree while open, so the
## instance needs process_mode = PROCESS_MODE_ALWAYS to keep its own controls working.

const WINDOW_TITLE : String = "Asetukset"
const CLOSE_BUTTON_TEXT : String = "Sulje"
const MAIN_MENU_BUTTON_TEXT : String = "Päävalikkoon"
const MAIN_MENU_SCENE_PATH : String = "res://scenes/ui/main_menu.tscn"

const TAB_TITLES : Array[String] = ["Ääni", "Näyttö", "Ohjaus", "Tietoja"]
const INPUT_TAB_INDEX : int = 2

## False on the instance inside the main menu itself: there is nothing to return to.
@export var show_main_menu_button : bool = true

@onready var title_label : Label = $MarginContainer/MainVBox/HeaderHBox/TitleLabel
@onready var close_button : Button = $MarginContainer/MainVBox/HeaderHBox/CloseButton
@onready var main_menu_button : Button = $MarginContainer/MainVBox/HeaderHBox/MainMenuButton
@onready var tab_container : TabContainer = $MarginContainer/MainVBox/TabContainer

@onready var master_slider : HSlider = $MarginContainer/MainVBox/TabContainer/SoundTab/MasterRow/MasterSlider
@onready var music_slider : HSlider = $MarginContainer/MainVBox/TabContainer/SoundTab/MusicRow/MusicSlider
@onready var sfx_slider : HSlider = $MarginContainer/MainVBox/TabContainer/SoundTab/SfxRow/SfxSlider
@onready var music_mute_check : CheckButton = $MarginContainer/MainVBox/TabContainer/SoundTab/MusicRow/MusicMuteCheck
@onready var sfx_mute_check : CheckButton = $MarginContainer/MainVBox/TabContainer/SoundTab/SfxRow/SfxMuteCheck
@onready var fullscreen_check : CheckButton = $MarginContainer/MainVBox/TabContainer/DisplayTab/FullscreenRow/FullscreenCheck

## Whether the tree was already paused (by the game menu) when this opened, so closing
## restores that instead of always unpausing.
var _was_paused_before : bool = false
var _key_bindings : KeyBindingsTab


func _ready() -> void:
	title_label.text = WINDOW_TITLE
	close_button.text = CLOSE_BUTTON_TEXT
	main_menu_button.text = MAIN_MENU_BUTTON_TEXT
	main_menu_button.visible = show_main_menu_button
	_build_input_tab()
	for i : int in TAB_TITLES.size():
		tab_container.set_tab_title(i, TAB_TITLES[i])

	_load_current_values()
	_connect_signals()
	hide()


## Esc is handled here, not in gui.gd's global handler: this node is PROCESS_MODE_ALWAYS
## and keeps receiving input while the paused tree stops delivering it to gui.gd. The
## visible guard lets Esc fall through to gui.gd (which opens this window) otherwise.
func _input(event : InputEvent) -> void:
	if not visible:
		return
	if _key_bindings.try_capture(event):
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(InputManager.ACTION_CANCEL):
		_on_close_button_pressed()
		get_viewport().set_input_as_handled()


func _build_input_tab() -> void:
	_key_bindings = KeyBindingsTab.new()
	_key_bindings.name = "InputTab"
	tab_container.add_child(_key_bindings)
	tab_container.move_child(_key_bindings, INPUT_TAB_INDEX)


func _connect_signals() -> void:
	close_button.pressed.connect(_on_close_button_pressed)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	master_slider.value_changed.connect(SettingsManager.set_master_volume)
	music_slider.value_changed.connect(SettingsManager.set_music_volume)
	sfx_slider.value_changed.connect(SettingsManager.set_sfx_volume)
	for slider : HSlider in [master_slider, music_slider, sfx_slider]:
		slider.drag_ended.connect(_on_slider_drag_ended)
	music_mute_check.toggled.connect(SettingsManager.set_music_muted)
	sfx_mute_check.toggled.connect(SettingsManager.set_sfx_muted)
	fullscreen_check.toggled.connect(SettingsManager.set_fullscreen)
	GUISignals.options_requested.connect(_on_options_requested)


func _load_current_values() -> void:
	master_slider.value = SettingsManager.master_volume
	music_slider.value = SettingsManager.music_volume
	sfx_slider.value = SettingsManager.sfx_volume
	music_mute_check.button_pressed = SettingsManager.music_muted
	sfx_mute_check.button_pressed = SettingsManager.sfx_muted
	fullscreen_check.button_pressed = SettingsManager.fullscreen


func _on_options_requested() -> void:
	_load_current_values()
	_key_bindings.cancel_capture()
	_was_paused_before = get_tree().paused
	get_tree().paused = true
	show()


func _on_close_button_pressed() -> void:
	GUISignals.options_closed.emit()
	get_tree().paused = _was_paused_before
	hide()


func _on_main_menu_button_pressed() -> void:
	GUISignals.menu_button_pressed.emit()
	SaveManager.save_game()
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)


func _on_slider_drag_ended(_value_changed : bool) -> void:
	SettingsManager.save_settings()
