#class_name BrewEngine (autoload)
extends Node

var current_brewery: Brewery = null
var _developer_mode : bool = false


func is_developer_mode() -> bool:
	return _developer_mode


## Flipped by the "iddqd" console cheat code — returns the new state so the
## caller can report it without a separate is_developer_mode() round trip.
func toggle_developer_mode() -> bool:
	_developer_mode = not _developer_mode
	return _developer_mode


func _init() -> void:
	start_new_game()


## Public so the main menu's "Aloita uusi peli" can force a fresh Brewery
## explicitly instead of relying on the one created at process boot.
## chosen_modifier carries the player's pick from ModifierSelectWindow;
## left null wherever no choice was made (e.g. the very first Brewery
## created at process boot, before any menu exists to choose from) so
## Brewery._init() falls back to its own random roll.
func start_new_game(chosen_modifier : RunModifier = null) -> void:
	if current_brewery != null:
		current_brewery.disconnect_signals()
	current_brewery = Brewery.new(chosen_modifier)
	current_brewery._ready()
	print(StringContainer.NEW_GAME_MESSAGE)