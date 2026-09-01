#class_name BrewEngine (autoload)
extends Node

var current_brewery: Brewery = null
const DEVELOPER_MODE : bool = true


func _init() -> void:
	_on_start_game()


func _on_start_game() -> void:
	current_brewery = Brewery.new()
	current_brewery._ready()
	print(StringContainer.NEW_GAME_MESSAGE)
