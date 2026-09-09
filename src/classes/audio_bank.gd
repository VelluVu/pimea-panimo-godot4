class_name AudioBank
extends Resource

## Data-driven catalogue of every sound the game can play. AudioManager
## (autoload) holds one of these and never hardcodes asset paths itself —
## swapping or re-recording a sound is a matter of reassigning it here.


@export_group("Music")
@export var music_tracks: Array[AudioStream] = []

@export_group("Economy")
@export var sfx_coin_success: AudioStream

@export_group("UI")
@export var sfx_ui_click: AudioStream

@export_group("Brewing")
@export var sfx_brew_start: AudioStream

@export_group("Special Events")
@export var sfx_notification_ping: AudioStream

@export_group("AVI Risk")
@export var sfx_avi_alarm: AudioStream
@export var sfx_risk_tension_drone: AudioStream

@export_group("Progression")
@export var sfx_style_discovered: AudioStream
