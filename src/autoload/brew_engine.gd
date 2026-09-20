#class_name BrewEngine (autoload)
extends Node

var current_brewery: Brewery = null
var _developer_mode : bool = false


func is_developer_mode() -> bool:
	return _developer_mode


## Flipped by the "iddqd" console cheat code — returns the new state so the
## caller can report it without a separate is_developer_mode() round trip.
## Turning it ON also skips the beginner tutorial outright and starts the
## day clock immediately if it hadn't already (see _skip_tutorial_and_start_clock())
## — the whole point of dev mode is testing the real game, not re-doing the
## tutorial gate every time. Turning it back OFF deliberately leaves both
## alone: un-completing the tutorial or stopping a clock that's already
## running would be destructive, not a real "off" state.
func toggle_developer_mode() -> bool:
	_developer_mode = not _developer_mode
	if _developer_mode:
		_skip_tutorial_and_start_clock()
	return _developer_mode


func _skip_tutorial_and_start_clock() -> void:
	if current_brewery == null:
		return

	current_brewery.lifetime_malt_kg_bought = Brewery.TUTORIAL_MALT_TARGET_KG
	current_brewery.tutorial_bought_yeast = true
	current_brewery.tutorial_brewed_kotikalja = true

	TimeManager.start_clock_immediately()
	BrewerySignals.brewery_state_changed.emit(current_brewery)


func _init() -> void:
	start_new_game()


## The one place a Brewery becomes the current one (new game, load game).
## Disconnects the outgoing instance first, otherwise it stays connected to
## GUISignals and keeps handling player actions instead of the new one.
func set_brewery(brewery : Brewery) -> void:
	if current_brewery != null:
		current_brewery.disconnect_signals()
	current_brewery = brewery
	current_brewery._ready()


## Public so the main menu's "Aloita uusi peli" can force a fresh Brewery
## explicitly instead of relying on the one created at process boot.
## chosen_modifier carries the player's pick from ModifierSelectWindow;
## left null wherever no choice was made (e.g. the very first Brewery
## created at process boot, before any menu exists to choose from) so
## Brewery._init() falls back to its own random roll.
func start_new_game(chosen_modifier : RunModifier = null) -> void:
	set_brewery(Brewery.new(chosen_modifier))
	print(StringContainer.NEW_GAME_MESSAGE)