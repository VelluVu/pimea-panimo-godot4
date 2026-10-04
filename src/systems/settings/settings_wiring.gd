class_name SettingsWiring
extends SettingsStore

## This project's audio buses, languages and defaults: the one file to edit after
## copying the settings system. The game's SettingsManager autoload extends this.

const BUS_MASTER: StringName = &"Master"
const BUS_MUSIC: StringName = &"Music"
const BUS_SFX: StringName = &"SFX"


func _init() -> void:
	audio_buses = [BUS_MASTER, BUS_MUSIC, BUS_SFX]
	default_volume = 0.8
	# Music and effects ship muted.
	default_muted_buses = [BUS_MUSIC, BUS_SFX]
	save_path = "user://settings.cfg"
	# The texts are written in Finnish and are their own translation keys, so Finnish
	# needs no file; English comes from dev/tools/i18n.py's en.po.
	supported_locales = ["fi", "en"]
	# Finnish until the player picks English in Options.
	fallback_locale = "fi"
	follow_system_language = false
	translation_paths = ["res://src/resources/translations/en.po"]
	# Text built in code (the HUD, the goals panel) is rebuilt from the brewery state.
	language_changed.connect(func(_locale: String) -> void:
		if BrewEngine.current_brewery != null:
			BrewerySignals.brewery_state_changed.emit(BrewEngine.current_brewery))
