#BrewEngine (autoload)
extends Node

var current_brewery: Brewery = null


func _init() -> void:
	_on_start_game()

#tapahtuu lopulta main menusta ammutusta signaalista
func _on_start_game() -> void:
	current_brewery = Brewery.new()
	current_brewery._ready()
	
	print(StringContainer.NEW_GAME_MESSAGE)
