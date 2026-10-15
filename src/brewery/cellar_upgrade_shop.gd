class_name CellarUpgradeShop
extends RefCounted

## Buys cellar upgrades with the run's money, one level at a time.

var brewery : Brewery


func _init(owner : Brewery) -> void:
	brewery = owner


func connect_signals() -> void:
	GUISignals.cellar_upgrade_requested.connect(_on_cellar_upgrade_requested)
	GUISignals.machine_switch_requested.connect(_on_machine_switch_requested)


func disconnect_signals() -> void:
	GUISignals.cellar_upgrade_requested.disconnect(_on_cellar_upgrade_requested)
	GUISignals.machine_switch_requested.disconnect(_on_machine_switch_requested)


func level_of(upgrade : CellarUpgradeData) -> int:
	return brewery.cellar_upgrade_levels.get(upgrade.upgrade_id, 0)


## The UI only offers affordable levels, so a refused purchase is just ignored.
func _on_cellar_upgrade_requested(upgrade_id : String) -> void:
	var upgrade : CellarUpgradeData = CellarUpgrades.find(upgrade_id, CellarUpgrades.all())
	if upgrade == null:
		return
	var level : int = level_of(upgrade)
	var cost : int = upgrade.cost_for_next_level(level)
	if not CellarUpgradeRules.can_buy(level, upgrade.max_level, cost, brewery.money):
		return
	if upgrade.is_machine and brewery.owns_machine(upgrade_id):
		return

	brewery.change_money(-cost, MoneyLedger.Source.UPGRADES)
	brewery.cellar_upgrade_levels[upgrade_id] = level + 1
	brewery.inventory.add_clean_kegs(upgrade.kegs_per_level)
	BrewerySignals.cellar_upgrade_purchased.emit(upgrade, level + 1)
	BrewerySignals.brewery_state_changed.emit(brewery)
	brewery.check_bankruptcy()


func _on_machine_switch_requested(upgrade_id : String) -> void:
	if not brewery.owns_machine(upgrade_id):
		return
	var enabled : bool = brewery.machines_off.has(upgrade_id)
	brewery.machines_off.erase(upgrade_id)
	if not enabled:
		brewery.machines_off.append(upgrade_id)
	BrewerySignals.machine_switched.emit(upgrade_id, enabled)
	BrewerySignals.brewery_state_changed.emit(brewery)
