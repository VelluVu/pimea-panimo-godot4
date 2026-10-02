class_name OptionsWindow
extends Panel

## Sound, display, input and credits tabs. Pauses the SceneTree while open, so the
## instance needs process_mode = PROCESS_MODE_ALWAYS to keep its own controls working.

const WINDOW_TITLE : String = "Asetukset"
const CLOSE_BUTTON_TEXT : String = "Sulje"
const MAIN_MENU_BUTTON_TEXT : String = "Päävalikkoon"
const MAIN_MENU_SCENE_PATH : String = "res://src/scenes/ui/main_menu.tscn"

const TAB_TITLES : Array[String] = ["Ääni", "Näyttö", "Ohjaus", "Tietoja"]
const INPUT_TAB_INDEX : int = 2
const LANGUAGE_LABEL_TEXT : String = "Kieli"
## Each language in its own name, so a player can find theirs whatever is showing.
const LANGUAGE_NAMES : Dictionary = {"fi": "Suomi", "en": "English"}

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

## Whether the tree was already paused (by the game menu) when this opened, so closing
## restores that instead of always unpausing.
var _was_paused_before : bool = false
var _key_bindings : KeyBindingsTab
var _language_option : OptionButton


func _ready() -> void:
	title_label.text = WINDOW_TITLE
	close_button.text = CLOSE_BUTTON_TEXT
	main_menu_button.text = MAIN_MENU_BUTTON_TEXT
	main_menu_button.visible = show_main_menu_button
	_build_input_tab()
	_build_language_row()
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
	_key_bindings.setup(InputManager)
	_key_bindings.name = "InputTab"
	tab_container.add_child(_key_bindings)
	tab_container.move_child(_key_bindings, INPUT_TAB_INDEX)


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
	for slider : HSlider in [master_slider, music_slider, sfx_slider]:
		slider.drag_ended.connect(_on_slider_drag_ended)
	music_mute_check.toggled.connect(func(muted : bool) -> void: SettingsManager.set_muted(SettingsManager.BUS_MUSIC, muted))
	sfx_mute_check.toggled.connect(func(muted : bool) -> void: SettingsManager.set_muted(SettingsManager.BUS_SFX, muted))
	fullscreen_check.toggled.connect(SettingsManager.set_fullscreen)
	_language_option.item_selected.connect(func(index : int) -> void: SettingsManager.set_language(SettingsManager.supported_locales[index]))
	GUISignals.options_requested.connect(_on_options_requested)
	tab_container.tab_changed.connect(GUISignals.tab_switched.emit.unbind(1))


func _load_current_values() -> void:
	master_slider.value = SettingsManager.get_volume(SettingsManager.BUS_MASTER)
	music_slider.value = SettingsManager.get_volume(SettingsManager.BUS_MUSIC)
	sfx_slider.value = SettingsManager.get_volume(SettingsManager.BUS_SFX)
	music_mute_check.button_pressed = SettingsManager.is_muted(SettingsManager.BUS_MUSIC)
	sfx_mute_check.button_pressed = SettingsManager.is_muted(SettingsManager.BUS_SFX)
	fullscreen_check.button_pressed = SettingsManager.fullscreen
	_language_option.select(SettingsManager.supported_locales.find(SettingsManager.get_language()))


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
