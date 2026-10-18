class_name LanguageSwitch
extends HBoxContainer

## A button per language in a main menu corner, so a player who cannot read the menu's
## language need not find Options.

const MARGIN : float = 6.0
## Twice the pixel font's size on touch screens, like the menu buttons.
const TOUCH_FONT_SIZE : int = 32
## The language not in use fades back; the theme's pressed look is too close to normal.
const INACTIVE_MODULATE : Color = Color(1, 1, 1, 0.45)

var _buttons : Dictionary = {}


func _ready() -> void:
	for locale : String in SettingsManager.supported_locales:
		var button := Button.new()
		# Language codes are the same in every language.
		button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		button.text = locale.to_upper()
		button.focus_mode = Control.FOCUS_NONE
		if DisplayServer.is_touchscreen_available():
			button.add_theme_font_size_override("font_size", TOUCH_FONT_SIZE)
		button.pressed.connect(_on_language_pressed.bind(locale))
		add_child(button)
		_buttons[locale] = button
	set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, int(MARGIN))
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	SettingsManager.language_changed.connect(_on_language_changed)
	_on_language_changed(SettingsManager.get_language())


func _on_language_pressed(locale : String) -> void:
	GUISignals.menu_button_pressed.emit()
	SettingsManager.set_language(locale)


func _on_language_changed(locale : String) -> void:
	for code : String in _buttons:
		(_buttons[code] as Button).modulate = Color.WHITE if code == locale else INACTIVE_MODULATE
