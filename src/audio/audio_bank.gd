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
## A critical tip or quality gain popped off a customer, on top of the coin.
@export var sfx_critical_gain: AudioStream

@export_group("UI")
@export var sfx_ui_click: AudioStream
@export var sfx_toast: AudioStream
@export var sfx_group_banner: AudioStream
## Day events without an announcement_sound of their own.
@export var sfx_day_event: AudioStream

@export_group("World")
## World sounds play at their place in the cellar, heard from the bartender.
@export var sfx_footstep: AudioStream
## One is picked at random each time someone speaks.
@export var sfx_babbles: Array[AudioStream] = []
@export var sfx_pour: AudioStream

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

@export_group("Bar Fights")
## A glass thrown in a bar fight hits the floor (played at a lowered, varied pitch).
@export var sfx_glass_shatter: AudioStream
