class_name AudioBank
extends Resource

## Every sound the game plays. AudioWiring (the AudioManager autoload) holds one and
## never hardcodes asset paths, so swapping a sound is a matter of reassigning it here.


@export_group("Music")
## Always this one track, looping, in the main menu.
@export var menu_music: AudioStream
## Shuffled playlist during a run.
@export var music_tracks: Array[AudioStream] = []

@export_group("Economy")
@export var sfx_coin_success: AudioStream

@export_group("UI")
@export var sfx_ui_click: AudioStream

@export_group("Brewing")
@export var sfx_brew_start: AudioStream

@export_group("Special Events")
@export var sfx_notification_ping: AudioStream

@export_group("LVV Risk")
@export var sfx_lvv_alarm: AudioStream
@export var sfx_risk_tension_drone: AudioStream

@export_group("Progression")
@export var sfx_style_discovered: AudioStream
## An Olutoppi talent level was bought.
@export var sfx_talent_purchased: AudioStream
