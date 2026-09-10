#class_name BrewEngine (autoload)
extends Node

var current_brewery: Brewery = null
const DEVELOPER_MODE : bool = false


func _init() -> void:
	start_new_game()


## Public so the main menu's "Aloita uusi peli" can force a fresh Brewery
## explicitly instead of relying on the one created at process boot.
func start_new_game() -> void:
	if current_brewery != null:
		current_brewery.disconnect_signals()
	current_brewery = Brewery.new()
	current_brewery._ready()
	print(StringContainer.NEW_GAME_MESSAGE)