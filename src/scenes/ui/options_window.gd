class_name OptionsWindow
extends Panel

## Sound, display, input and credits tabs; rows the scene lacks are built here. Pauses the
## tree, so PROCESS_MODE_ALWAYS.

const WINDOW_TITLE : String = "Asetukset"
const CLOSE_BUTTON_TEXT : String = "Sulje"
const MAIN_MENU_BUTTON_TEXT : String = "Päävalikkoon"
const MAIN_MENU_SCENE_PATH : String = "res://src/scenes/ui/main_menu.tscn"

const TAB_TITLES : Array[String] = ["Ääni", "Näyttö", "Ohjaus", "Tietoja"]
const INPUT_TAB_INDEX : int = 2
const LANGUAGE_LABEL_TEXT : String = "Kieli"
## Each language in its own name, so a player can find theirs whatever is showing.
const LANGUAGE_NAMES : Dictionary = {"fi": "Suomi", "en": "English"}
const VOICES_LABEL_TEXT : String = "Puheäänet"
const MUTE_CHECK_TEXT : String = "Pois"
const PIXEL_PERFECT_LABEL_TEXT : String = "Terävät pikselit"
const PIXEL_PERFECT_TOOLTIP : String = "Kuva suurenee vain kokonaisin askelin, joten pikselit pysyvät tasakokoisina. Reunoille voi jäädä mustat palkit."
const SCREEN_SHAKE_LABEL_TEXT : String = "Ruudun tärinä"
const SCREEN_SHAKE_TOOLTIP : String = "Tappelut ja särkyvät lasit tärisyttävät ruutua."
const FOCUS_PAUSE_LABEL_TEXT : String = "Tauko taustalla"
const FOCUS_PAUSE_TOOLTIP : String = "Peli pysähtyy, kun siirryt toiseen ikkunaan tai välilehteen."
## Matches the label width of the rows built in the scene.
const ROW_LABEL_WIDTH : float = 120.0

## False on the instance inside the main menu itself: there is nothing to return to.
@export var show_main_menu_button : bool = true

@onready var title_label : Label = %TitleLabel
@onready var close_button : Button = %CloseButton
@onready var main_menu_button : Button = %MainMenuButton
@onready var tab_container : TabContainer = %TabContainer

@onready var master_slider : HSlider = %MasterSlider
@onready var music_slider : HSlider = %MusicSlider
@onready var sfx_slider : HSlider = %SfxSlider
@onready var music_mute_check : CheckButton = %MusicMuteCheck
@onready var sfx_mute_check : CheckButton = %SfxMuteCheck
@onready var fullscreen_check : CheckButton = %FullscreenCheck
@onready var display_tab : VBoxContainer = %DisplayTab
@onready var sound_tab : VBoxContainer = $MarginContainer/MainVBox/TabContainer/SoundTab

var _key_bindings : KeyBindingsTab
var _language_option : OptionButton
var _voices_slider : HSlider
var _voices_mute_check : CheckButton
var _pixel_perfect_check : CheckButton
var _screen_shake_check : CheckButton
var _focus_pause_check : CheckButton


func _ready() -> void:
	title_label.text = WINDOW_TITLE
	close_button.text = CLOSE_BUTTON_TEXT
	main_menu_button.text = MAIN_MENU_BUTTON_TEXT
	main_menu_button.visible = show_main_menu_button
	_build_input_tab()
	_build_voices_row()
	_build_display_rows()
	_build_language_row()
	for i : int in TAB_TITLES.size():
		tab_container.set_tab_title(i, TAB_TITLES[i])

	_load_current_values()
	_connect_signals()
	hide()


## Esc is handled here: the paused tree stops delivering it to gui.gd. Only while visible,
## so otherwise it falls through to gui.gd, which opens this window.
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
	_key_bindings.setup(InputManager)
	_key_bindings.name = "InputTab"
	tab_container.add_child(_key_bindings)
	tab_container.move_child(_key_bindings, INPUT_TAB_INDEX)


func _build_voices_row() -> void:
	_voices_slider = HSlider.new()
	_voices_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_voices_slider.max_value = 1.0
	_voices_slider.step = 0.05
	_voices_mute_check = CheckButton.new()
	_voices_mute_check.text = MUTE_CHECK_TEXT
	_add_row(sound_tab, VOICES_LABEL_TEXT, "", [_voices_slider, _voices_mute_check])


func _build_display_rows() -> void:
	_pixel_perfect_check = CheckButton.new()
	_add_row(display_tab, PIXEL_PERFECT_LABEL_TEXT, PIXEL_PERFECT_TOOLTIP, [_pixel_perfect_check])
	_screen_shake_check = CheckButton.new()
	_add_row(display_tab, SCREEN_SHAKE_LABEL_TEXT, SCREEN_SHAKE_TOOLTIP, [_screen_shake_check])
	_focus_pause_check = CheckButton.new()
	_add_row(display_tab, FOCUS_PAUSE_LABEL_TEXT, FOCUS_PAUSE_TOOLTIP, [_focus_pause_check])


## A row like the scene's own: a fixed-width label, then the controls.
func _add_row(tab : Control, label_text : String, tooltip : String, controls : Array[Control]) -> void:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(ROW_LABEL_WIDTH, 0.0)
	label.tooltip_text = tooltip
	label.mouse_filter = Control.MOUSE_FILTER_PASS if tooltip != "" else Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	for control : Control in controls:
		control.tooltip_text = tooltip
		row.add_child(control)
	tab.add_child(row)


func _build_language_row() -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = LANGUAGE_LABEL_TEXT
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	_language_option = OptionButton.new()
	# Language names stay in their own language whichever one is active.
	_language_option.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	for locale : String in SettingsManager.supported_locales:
		_language_option.add_item(LANGUAGE_NAMES.get(locale, locale))
	row.add_child(_language_option)
	display_tab.add_child(row)


func _connect_signals() -> void:
	close_button.pressed.connect(_on_close_button_pressed)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	master_slider.value_changed.connect(func(value : float) -> void: SettingsManager.set_volume(SettingsManager.BUS_MASTER, value))
	music_slider.value_changed.connect(func(value : float) -> void: SettingsManager.set_volume(SettingsManager.BUS_MUSIC, value))
	sfx_slider.value_changed.connect(func(value : float) -> void: SettingsManager.set_volume(SettingsManager.BUS_SFX, value))
	_voices_slider.value_changed.connect(func(value : float) -> void: SettingsManager.set_volume(SettingsManager.BUS_VOICES, value))
	for slider : HSlider in [master_slider, music_slider, sfx_slider, _voices_slider]:
		slider.drag_ended.connect(_on_slider_drag_ended)
	music_mute_check.toggled.connect(func(muted : bool) -> void: SettingsManager.set_muted(SettingsManager.BUS_MUSIC, muted))
	sfx_mute_check.toggled.connect(func(muted : bool) -> void: SettingsManager.set_muted(SettingsManager.BUS_SFX, muted))
	_voices_mute_check.toggled.connect(func(muted : bool) -> void: SettingsManager.set_muted(SettingsManager.BUS_VOICES, muted))
	fullscreen_check.toggled.connect(SettingsManager.set_fullscreen)
	_pixel_perfect_check.toggled.connect(SettingsManager.set_pixel_perfect)
	_screen_shake_check.toggled.connect(func(on : bool) -> void: SettingsManager.set_option(SettingsManager.OPTION_SCREEN_SHAKE, on))
	_focus_pause_check.toggled.connect(func(on : bool) -> void: SettingsManager.set_option(SettingsManager.OPTION_PAUSE_ON_FOCUS_LOSS, on))
	_language_option.item_selected.connect(func(index : int) -> void: SettingsManager.set_language(SettingsManager.supported_locales[index]))
	GUISignals.options_requested.connect(_on_options_requested)
	tab_container.tab_changed.connect(GUISignals.tab_switched.emit.unbind(1))


func _load_current_values() -> void:
	master_slider.value = SettingsManager.get_volume(SettingsManager.BUS_MASTER)
	music_slider.value = SettingsManager.get_volume(SettingsManager.BUS_MUSIC)
	sfx_slider.value = SettingsManager.get_volume(SettingsManager.BUS_SFX)
	music_mute_check.button_pressed = SettingsManager.is_muted(SettingsManager.BUS_MUSIC)
	sfx_mute_check.button_pressed = SettingsManager.is_muted(SettingsManager.BUS_SFX)
	_voices_slider.value = SettingsManager.get_volume(SettingsManager.BUS_VOICES)
	_voices_mute_check.button_pressed = SettingsManager.is_muted(SettingsManager.BUS_VOICES)
	fullscreen_check.button_pressed = SettingsManager.fullscreen
	_pixel_perfect_check.button_pressed = SettingsManager.pixel_perfect
	_screen_shake_check.button_pressed = SettingsManager.get_option(SettingsManager.OPTION_SCREEN_SHAKE)
	_focus_pause_check.button_pressed = SettingsManager.get_option(SettingsManager.OPTION_PAUSE_ON_FOCUS_LOSS)
	_language_option.select(SettingsManager.supported_locales.find(SettingsManager.get_language()))


func _on_options_requested() -> void:
	_load_current_values()
	_key_bindings.cancel_capture()
	PauseLock.hold(self)
	move_to_front()
	# The web export dropped the scene's offsets and opened this in the corner.
	set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
	show()


func _on_close_button_pressed() -> void:
	GUISignals.options_closed.emit()
	PauseLock.release(self)
	hide()


func _on_main_menu_button_pressed() -> void:
	GUISignals.menu_button_pressed.emit()
	SaveManager.save_game()
	PauseLock.release_all(get_tree())
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)


func _on_slider_drag_ended(_value_changed : bool) -> void:
	SettingsManager.save_settings()
