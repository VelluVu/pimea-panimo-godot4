class_name AudioBank
extends Resource

## Every sound the game plays, so swapping one means reassigning it here.


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

@export_group("Brew day")
## Loops: the burner while heating, the rolling boil, hops trickling from a held sack.
@export var sfx_brew_burner_loop: AudioStream
@export var sfx_brew_boil_loop: AudioStream
@export var sfx_brew_hop_pour_loop: AudioStream
@export var sfx_brew_malt_pour: AudioStream
## Something landing in the kettle: a hop or spice pour starting.
@export var sfx_brew_plop: AudioStream
@export var sfx_brew_clump_hit: AudioStream
@export var sfx_brew_clump_break: AudioStream
## The paddle hitting the kettle wall.
@export var sfx_brew_paddle_knock: AudioStream
@export var sfx_brew_boil_over: AudioStream
## A mash step done, or a hop mark hit.
@export var sfx_brew_step_done: AudioStream
@export var sfx_brew_result_good: AudioStream
## A low result, or a hop mark missed.
@export var sfx_brew_result_low: AudioStream

@export_group("Keg wash")
## Grime loosened by the brush, grime or a stain rinsed off, a critter fleeing the keg.
@export var sfx_keg_scrub: AudioStream
@export var sfx_keg_splash: AudioStream
@export var sfx_keg_skitter: AudioStream
## A tool knocking the keg as it is picked up.
@export var sfx_keg_clank: AudioStream
## A keg washed spotless.
@export var sfx_keg_shine: AudioStream

@export_group("Fermentation")
@export var sfx_ferment_bubble: AudioStream
@export var sfx_soured: AudioStream

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
