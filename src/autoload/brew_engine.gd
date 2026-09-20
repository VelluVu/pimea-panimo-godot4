#class_name BrewEngine (autoload)
extends Node

## A different Brewery just became current (new game or load). Autoloads that
## track per-run state reload it from `brewery` here.
signal brewery_changed(brewery: Brewery)
## SaveManager is about to serialize `brewery`. Autoloads that keep run state
## outside Brewery write it onto `brewery` here, so it lands in the save.
signal brewery_about_to_save(brewery: Brewery)

var current_brewery: Brewery = null
var _developer_mode : bool = false


func is_developer_mode() -> bool:
	return _developer_mode


func toggle_developer_mode() -> bool:
	_developer_mode = not _developer_mode
	return _developer_mode


func _init() -> void:
	start_new_game()


## The one place a Brewery becomes current. Disconnects the outgoing one first,
## otherwise it keeps handling GUISignals.
func set_brewery(brewery : Brewery) -> void:
	if current_brewery != null:
		current_brewery.disconnect_signals()
	current_brewery = brewery
	current_brewery._ready()
	brewery_changed.emit(current_brewery)


## Starts a fresh run. `chosen_modifier` is the player's pick; null rolls a random
## one (used for the boot-time Brewery).
func start_new_game(chosen_modifier : RunModifier = null) -> void:
	set_brewery(Brewery.new(chosen_modifier))
	print(StringContainer.NEW_GAME_MESSAGE)
