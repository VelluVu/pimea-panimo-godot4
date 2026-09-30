class_name SettingsWiring
extends SettingsStore

## This project's audio buses and defaults: the one file to edit after copying the
## settings system. The game's SettingsManager autoload extends this.

const BUS_MASTER: StringName = &"Master"
const BUS_MUSIC: StringName = &"Music"
const BUS_SFX: StringName = &"SFX"


func _init() -> void:
	audio_buses = [BUS_MASTER, BUS_MUSIC, BUS_SFX]
	default_volume = 0.8
	# Music and effects ship muted.
	default_muted_buses = [BUS_MUSIC, BUS_SFX]
	save_path = "user://settings.cfg"
