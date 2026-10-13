class_name KegWasher
extends RefCounted

## Applies a finished keg wash (the minigame, or a bot) to the cellar's empty kegs.

var brewery : Brewery


func _init(owner : Brewery) -> void:
	brewery = owner


func connect_signals() -> void:
	GUISignals.keg_wash_finished.connect(_on_keg_wash_finished)


func disconnect_signals() -> void:
	GUISignals.keg_wash_finished.disconnect(_on_keg_wash_finished)


func _on_keg_wash_finished(cleanliness : float) -> void:
	if not KegRules.wash_dirtiest(brewery.inventory.free_kegs, cleanliness):
		return
	BrewerySignals.keg_washed.emit(cleanliness)
	BrewerySignals.brewery_state_changed.emit(brewery)
