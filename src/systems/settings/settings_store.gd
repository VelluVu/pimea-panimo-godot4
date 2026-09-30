class_name SettingsStore
extends Node

## Persisted player preferences: a volume and mute per audio bus, and fullscreen. Applies
## them straight to AudioServer and DisplayServer. The project lists its buses and
## defaults in its wiring subclass.

const SECTION_AUDIO: String = "audio"
const SECTION_VIDEO: String = "video"
const KEY_FULLSCREEN: String = "fullscreen"
const VOLUME_SUFFIX: String = "_volume"
const MUTED_SUFFIX: String = "_muted"

## Buses that exist in the project's bus layout; a missing bus is skipped.
var audio_buses: Array[StringName] = [&"Master"]
var default_volume: float = 0.8
## Buses that start muted on a fresh install. Volume is kept separately, so unmuting
## later restores the last level instead of snapping to full.
var default_muted_buses: Array[StringName] = []
var fullscreen: bool = false
var save_path: String = "user://settings.cfg"

var _volumes: Dictionary = {}  # bus -> linear 0..1
var _muted: Dictionary = {}    # bus -> bool


func _ready() -> void:
	load_settings()
	apply_all()


func get_volume(bus: StringName) -> float:
	return _volumes.get(bus, default_volume)


func is_muted(bus: StringName) -> bool:
	return _muted.get(bus, default_muted_buses.has(bus))


## Applies at once but does not save: sliders save on drag end via save_settings().
func set_volume(bus: StringName, value: float) -> void:
	_volumes[bus] = clampf(value, 0.0, 1.0)
	_apply_bus(bus)


## Toggles save at once, since a click is already one discrete action.
func set_muted(bus: StringName, value: bool) -> void:
	_muted[bus] = value
	_apply_bus(bus)
	save_settings()


func set_fullscreen(value: bool) -> void:
	fullscreen = value
	_apply_fullscreen()
	save_settings()


func load_settings() -> void:
	var config := ConfigFile.new()
	var loaded: bool = config.load(save_path) == OK
	for bus: StringName in audio_buses:
		var key: String = String(bus).to_lower()
		_volumes[bus] = config.get_value(SECTION_AUDIO, key + VOLUME_SUFFIX, default_volume) if loaded else default_volume
		_muted[bus] = config.get_value(SECTION_AUDIO, key + MUTED_SUFFIX, default_muted_buses.has(bus)) if loaded else default_muted_buses.has(bus)
	fullscreen = config.get_value(SECTION_VIDEO, KEY_FULLSCREEN, false) if loaded else false


func save_settings() -> void:
	var config := ConfigFile.new()
	for bus: StringName in audio_buses:
		var key: String = String(bus).to_lower()
		config.set_value(SECTION_AUDIO, key + VOLUME_SUFFIX, get_volume(bus))
		config.set_value(SECTION_AUDIO, key + MUTED_SUFFIX, is_muted(bus))
	config.set_value(SECTION_VIDEO, KEY_FULLSCREEN, fullscreen)
	config.save(save_path)


func apply_all() -> void:
	for bus: StringName in audio_buses:
		_apply_bus(bus)
	_apply_fullscreen()


func _apply_bus(bus: StringName) -> void:
	var bus_idx := AudioServer.get_bus_index(bus)
	if bus_idx == -1:
		return
	var volume: float = get_volume(bus)
	AudioServer.set_bus_mute(bus_idx, is_muted(bus) or volume <= 0.0)
	if volume > 0.0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(volume))


func _apply_fullscreen() -> void:
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)
