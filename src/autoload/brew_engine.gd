#class_name BrewEngine (autoload)
extends Node

## A different Brewery just became current (new game or load). Autoloads that
## track per-run state reload it from `brewery` here.
signal brewery_changed(brewery: Brewery)
## SaveManager is about to serialize `brewery`. Autoloads that keep run state
## outside Brewery write it onto `brewery` here, so it lands in the save.
@warning_ignore("unused_signal") # emitted by SaveWiring
signal brewery_about_to_save(brewery: Brewery)

const LOG_NEW_GAME : String = "New game started! Brewery established."

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


## Brewery and its services point at each other, so the last one is never freed on its
## own: without this the whole season leaks into the engine's shutdown.
func _exit_tree() -> void:
	if current_brewery != null:
		current_brewery.disconnect_signals()
		current_brewery = null


func start_new_game() -> void:
	set_brewery(Brewery.new())
	print(LOG_NEW_GAME)
