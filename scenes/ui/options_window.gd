class_name OptionsWindow
extends Panel


const TAB_TITLE_SOUND: String = "Ääni"
const TAB_TITLE_DISPLAY: String = "Näyttö"
const TAB_TITLE_CREDITS: String = "Tietoja"
const WINDOW_TITLE: String = "Asetukset"
const CLOSE_BUTTON_TEXT: String = "Sulje"

@onready var title_label: Label = $MarginContainer/MainVBox/HeaderHBox/TitleLabel
@onready var close_button: Button = $MarginContainer/MainVBox/HeaderHBox/CloseButton
@onready var tab_container: TabContainer = $MarginContainer/MainVBox/TabContainer

@onready var master_slider: HSlider = $MarginContainer/MainVBox/TabContainer/SoundTab/MasterRow/MasterSlider
@onready var music_slider: HSlider = $MarginContainer/MainVBox/TabContainer/SoundTab/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $MarginContainer/MainVBox/TabContainer/SoundTab/SfxRow/SfxSlider

@onready var fullscreen_check: CheckButton = $MarginContainer/MainVBox/TabContainer/DisplayTab/FullscreenRow/FullscreenCheck


func _ready() -> void:
	title_label.text = WINDOW_TITLE
	close_button.text = CLOSE_BUTTON_TEXT
	tab_container.set_tab_title(0, TAB_TITLE_SOUND)
	tab_container.set_tab_title(1, TAB_TITLE_DISPLAY)
	tab_container.set_tab_title(2, TAB_TITLE_CREDITS)

	_load_current_values()

	close_button.pressed.connect(_on_close_button_pressed)
	master_slider.value_changed.connect(_on_master_slider_changed)
	music_slider.value_changed.connect(_on_music_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	master_slider.drag_ended.connect(_on_slider_drag_ended)
	music_slider.drag_ended.connect(_on_slider_drag_ended)
	sfx_slider.drag_ended.connect(_on_slider_drag_ended)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)

	GUISignals.options_requested.connect(_on_options_requested)

	hide()


func _load_current_values() -> void:
	master_slider.value = SettingsManager.master_volume
	music_slider.value = SettingsManager.music_volume
	sfx_slider.value = SettingsManager.sfx_volume
	fullscreen_check.button_pressed = SettingsManager.fullscreen


func _on_options_requested() -> void:
	_load_current_values()
	show()


func _on_close_button_pressed() -> void:
	hide()


func _on_master_slider_changed(value: float) -> void:
	SettingsManager.set_master_volume(value)


func _on_music_slider_changed(value: float) -> void:
	SettingsManager.set_music_volume(value)


func _on_sfx_slider_changed(value: float) -> void:
	SettingsManager.set_sfx_volume(value)


func _on_slider_drag_ended(_value_changed: bool) -> void:
	SettingsManager.save_settings()


func _on_fullscreen_toggled(pressed: bool) -> void:
	SettingsManager.set_fullscreen(pressed)
