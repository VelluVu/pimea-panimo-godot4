class_name OptionsWindow
extends Panel


const TAB_TITLE_SOUND: String = "Ääni"
const TAB_TITLE_DISPLAY: String = "Näyttö"
const TAB_TITLE_CREDITS: String = "Tietoja"
const WINDOW_TITLE: String = "Asetukset"
const CLOSE_BUTTON_TEXT: String = "Sulje"
const MAIN_MENU_BUTTON_TEXT: String = "Päävalikkoon"
const MAIN_MENU_SCENE_PATH: String = "res://scenes/ui/main_menu.tscn"

## False on the instance that already lives inside the main menu itself —
## there's nothing to "return to" from there.
@export var show_main_menu_button: bool = true

@onready var title_label: Label = $MarginContainer/MainVBox/HeaderHBox/TitleLabel
@onready var close_button: Button = $MarginContainer/MainVBox/HeaderHBox/CloseButton
@onready var main_menu_button: Button = $MarginContainer/MainVBox/HeaderHBox/MainMenuButton
@onready var tab_container: TabContainer = $MarginContainer/MainVBox/TabContainer

@onready var master_slider: HSlider = $MarginContainer/MainVBox/TabContainer/SoundTab/MasterRow/MasterSlider
@onready var music_slider: HSlider = $MarginContainer/MainVBox/TabContainer/SoundTab/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $MarginContainer/MainVBox/TabContainer/SoundTab/SfxRow/SfxSlider
@onready var music_mute_check: CheckButton = $MarginContainer/MainVBox/TabContainer/SoundTab/MusicRow/MusicMuteCheck
@onready var sfx_mute_check: CheckButton = $MarginContainer/MainVBox/TabContainer/SoundTab/SfxRow/SfxMuteCheck

@onready var fullscreen_check: CheckButton = $MarginContainer/MainVBox/TabContainer/DisplayTab/FullscreenRow/FullscreenCheck


func _ready() -> void:
	title_label.text = WINDOW_TITLE
	close_button.text = CLOSE_BUTTON_TEXT
	main_menu_button.text = MAIN_MENU_BUTTON_TEXT
	main_menu_button.visible = show_main_menu_button
	tab_container.set_tab_title(0, TAB_TITLE_SOUND)
	tab_container.set_tab_title(1, TAB_TITLE_DISPLAY)
	tab_container.set_tab_title(2, TAB_TITLE_CREDITS)

	_load_current_values()

	close_button.pressed.connect(_on_close_button_pressed)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	master_slider.value_changed.connect(_on_master_slider_changed)
	music_slider.value_changed.connect(_on_music_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	master_slider.drag_ended.connect(_on_slider_drag_ended)
	music_slider.drag_ended.connect(_on_slider_drag_ended)
	sfx_slider.drag_ended.connect(_on_slider_drag_ended)
	music_mute_check.toggled.connect(_on_music_mute_toggled)
	sfx_mute_check.toggled.connect(_on_sfx_mute_toggled)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)

	GUISignals.options_requested.connect(_on_options_requested)

	hide()


func _load_current_values() -> void:
	master_slider.value = SettingsManager.master_volume
	music_slider.value = SettingsManager.music_volume
	sfx_slider.value = SettingsManager.sfx_volume
	music_mute_check.button_pressed = SettingsManager.music_muted
	sfx_mute_check.button_pressed = SettingsManager.sfx_muted
	fullscreen_check.button_pressed = SettingsManager.fullscreen


func _on_options_requested() -> void:
	_load_current_values()
	show()


func _on_close_button_pressed() -> void:
	GUISignals.options_closed.emit()
	hide()


func _on_main_menu_button_pressed() -> void:
	GUISignals.menu_button_pressed.emit()
	SaveManager.save_game()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)


func _on_master_slider_changed(value: float) -> void:
	SettingsManager.set_master_volume(value)


func _on_music_slider_changed(value: float) -> void:
	SettingsManager.set_music_volume(value)


func _on_sfx_slider_changed(value: float) -> void:
	SettingsManager.set_sfx_volume(value)


func _on_slider_drag_ended(_value_changed: bool) -> void:
	SettingsManager.save_settings()


func _on_music_mute_toggled(pressed: bool) -> void:
	SettingsManager.set_music_muted(pressed)


func _on_sfx_mute_toggled(pressed: bool) -> void:
	SettingsManager.set_sfx_muted(pressed)


func _on_fullscreen_toggled(pressed: bool) -> void:
	SettingsManager.set_fullscreen(pressed)
