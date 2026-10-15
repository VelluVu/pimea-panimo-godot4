class_name KegWasher
extends RefCounted

## Applies a finished keg wash (the minigame, or a bot) to the cellar's empty kegs. With
## the Tynnyrinpesukone switched on, every dirty keg is washed spotless at once.

var brewery : Brewery


func _init(owner : Brewery) -> void:
	brewery = owner


func connect_signals() -> void:
	GUISignals.keg_wash_finished.connect(_on_keg_wash_finished)
	BrewerySignals.kegs_emptied.connect(_on_kegs_emptied)
	BrewerySignals.cellar_upgrade_purchased.connect(_on_cellar_upgrade_purchased)
	BrewerySignals.machine_switched.connect(_on_machine_switched)


func disconnect_signals() -> void:
	GUISignals.keg_wash_finished.disconnect(_on_keg_wash_finished)
	BrewerySignals.kegs_emptied.disconnect(_on_kegs_emptied)
	BrewerySignals.cellar_upgrade_purchased.disconnect(_on_cellar_upgrade_purchased)
	BrewerySignals.machine_switched.disconnect(_on_machine_switched)


func _on_keg_wash_finished(cleanliness : float) -> void:
	if not KegRules.wash_dirtiest(brewery.inventory.free_kegs, cleanliness):
		return
	BrewerySignals.keg_washed.emit(cleanliness)
	BrewerySignals.brewery_state_changed.emit(brewery)


func _on_kegs_emptied(_count : int) -> void:
	_machine_wash()


func _on_cellar_upgrade_purchased(upgrade : CellarUpgradeData, _level : int) -> void:
	if upgrade.upgrade_id == CellarMachines.KEG_WASHER:
		_machine_wash()


func _on_machine_switched(upgrade_id : String, enabled : bool) -> void:
	if enabled and upgrade_id == CellarMachines.KEG_WASHER:
		_machine_wash()


## One keg_washed per keg, the same as washing it by hand.
func _machine_wash() -> void:
	if not brewery.machine_active(CellarMachines.KEG_WASHER):
		return
	var washed : int = 0
	while KegRules.wash_dirtiest(brewery.inventory.free_kegs, KegRules.CLEAN):
		washed += 1
		BrewerySignals.keg_washed.emit(KegRules.CLEAN)
	if washed > 0:
		BrewerySignals.brewery_state_changed.emit(brewery)
