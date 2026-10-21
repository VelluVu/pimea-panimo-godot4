class_name SettingsWiring
extends SettingsStore

## This project's audio buses, languages and defaults: the one file to edit after
## copying the settings system. The game's SettingsManager autoload extends this.

const BUS_MASTER: StringName = &"Master"
const BUS_MUSIC: StringName = &"Music"
const BUS_SFX: StringName = &"SFX"
## Customer babble, apart from the effects: the sound players most often want quieter.
const BUS_VOICES: StringName = &"Voices"
const OPTION_SCREEN_SHAKE: String = "screen_shake"
## Alt-tab or another browser tab would otherwise let customers walk out unserved.
const OPTION_PAUSE_ON_FOCUS_LOSS: String = "pause_on_focus_loss"


func _init() -> void:
	audio_buses = [BUS_MASTER, BUS_MUSIC, BUS_SFX, BUS_VOICES]
	option_defaults = {
		OPTION_SCREEN_SHAKE: true,
		OPTION_PAUSE_ON_FOCUS_LOSS: true,
	}
	default_volume = 0.8
	save_path = "user://settings.cfg"
	# The texts are written in Finnish and are their own translation keys, so Finnish
	# needs no file; English comes from dev/tools/i18n.py's en.po.
	supported_locales = ["fi", "en"]
	# Finnish for a Finnish system or browser, English for everyone else, until the
	# player picks one on the main menu or in Options.
	fallback_locale = "en"
	follow_system_language = true
	translation_paths = ["res://src/resources/translations/en.po"]
	# Text built in code (the HUD, the goals panel) is rebuilt from the brewery state.
	language_changed.connect(func(_locale: String) -> void:
		if BrewEngine.current_brewery != null:
			BrewerySignals.brewery_state_changed.emit(BrewEngine.current_brewery))
