#SettingsManager (Autoload)
extends Node

## Persisted user preferences (audio volumes, display mode). Applies them
## directly to the engine (AudioServer buses, DisplayServer window mode) —
## it does not know about AudioManager or any gameplay system, and nothing
## needs to know about it beyond calling its setters from options UI.

const SETTINGS_FILE_PATH: String = "user://settings.cfg"

const SECTION_AUDIO: String = "audio"
const KEY_MASTER_VOLUME: String = "master_volume"
const KEY_MUSIC_VOLUME: String = "music_volume"
const KEY_SFX_VOLUME: String = "sfx_volume"
const KEY_MUSIC_MUTED: String = "music_muted"
const KEY_SFX_MUTED: String = "sfx_muted"

const SECTION_VIDEO: String = "video"
const KEY_FULLSCREEN: String = "fullscreen"

const BUS_MASTER: StringName = &"Master"
const BUS_MUSIC: StringName = &"Music"
const BUS_SFX: StringName = &"SFX"

const DEFAULT_VOLUME: float = 0.8
const MUTED_VOLUME_DB: float = -80.0

## Shipped default is muted (per current request) — the slider/volume
## values are preserved independently, so switching a mute off later
## restores whatever level was last set instead of snapping to full volume.
const DEFAULT_MUTED: bool = true

var master_volume: float = DEFAULT_VOLUME
var music_volume: float = DEFAULT_VOLUME
var sfx_volume: float = DEFAULT_VOLUME
var music_muted: bool = DEFAULT_MUTED
var sfx_muted: bool = DEFAULT_MUTED
var fullscreen: bool = false

var _config: ConfigFile = ConfigFile.new()


func _ready() -> void:
	_load_settings()
	_apply_bus_volume(BUS_MASTER, master_volume)
	_apply_bus_volume(BUS_MUSIC, music_volume, music_muted)
	_apply_bus_volume(BUS_SFX, sfx_volume, sfx_muted)
	_apply_fullscreen()


func _load_settings() -> void:
	if _config.load(SETTINGS_FILE_PATH) != OK:
		return

	master_volume = _config.get_value(SECTION_AUDIO, KEY_MASTER_VOLUME, DEFAULT_VOLUME)
	music_volume = _config.get_value(SECTION_AUDIO, KEY_MUSIC_VOLUME, DEFAULT_VOLUME)
	sfx_volume = _config.get_value(SECTION_AUDIO, KEY_SFX_VOLUME, DEFAULT_VOLUME)
	music_muted = _config.get_value(SECTION_AUDIO, KEY_MUSIC_MUTED, DEFAULT_MUTED)
	sfx_muted = _config.get_value(SECTION_AUDIO, KEY_SFX_MUTED, DEFAULT_MUTED)
	fullscreen = _config.get_value(SECTION_VIDEO, KEY_FULLSCREEN, false)


## Public so options UI can trigger a save explicitly (e.g. on slider
## drag_ended) instead of writing to disk on every value_changed tick.
func save_settings() -> void:
	_config.set_value(SECTION_AUDIO, KEY_MASTER_VOLUME, master_volume)
	_config.set_value(SECTION_AUDIO, KEY_MUSIC_VOLUME, music_volume)
	_config.set_value(SECTION_AUDIO, KEY_SFX_VOLUME, sfx_volume)
	_config.set_value(SECTION_AUDIO, KEY_MUSIC_MUTED, music_muted)
	_config.set_value(SECTION_AUDIO, KEY_SFX_MUTED, sfx_muted)
	_config.set_value(SECTION_VIDEO, KEY_FULLSCREEN, fullscreen)
	_config.save(SETTINGS_FILE_PATH)


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volume(BUS_MASTER, master_volume)


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volume(BUS_MUSIC, music_volume, music_muted)


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volume(BUS_SFX, sfx_volume, sfx_muted)


## Toggles apply and save immediately (unlike the sliders, which only save
## on drag_ended) since a checkbox click is already a single discrete action.
func set_music_muted(value: bool) -> void:
	music_muted = value
	_apply_bus_volume(BUS_MUSIC, music_volume, music_muted)
	save_settings()


func set_sfx_muted(value: bool) -> void:
	sfx_muted = value
	_apply_bus_volume(BUS_SFX, sfx_volume, sfx_muted)
	save_settings()


func set_fullscreen(value: bool) -> void:
	fullscreen = value
	_apply_fullscreen()
	save_settings()


func _apply_bus_volume(bus_name: StringName, linear_volume: float, muted: bool = false) -> void:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		return
	AudioServer.set_bus_mute(bus_idx, muted or linear_volume <= 0.0)
	if linear_volume > 0.0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(linear_volume))


func _apply_fullscreen() -> void:
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)
