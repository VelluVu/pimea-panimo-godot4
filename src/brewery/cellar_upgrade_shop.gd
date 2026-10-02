class_name CellarUpgradeShop
extends RefCounted

## Buys cellar upgrades with the run's money, one level at a time.

var brewery : Brewery


func _init(owner : Brewery) -> void:
	brewery = owner


func connect_signals() -> void:
	GUISignals.cellar_upgrade_requested.connect(_on_cellar_upgrade_requested)


func disconnect_signals() -> void:
	GUISignals.cellar_upgrade_requested.disconnect(_on_cellar_upgrade_requested)


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

	brewery.money -= cost
	brewery.cellar_upgrade_levels[upgrade_id] = level + 1
	BrewerySignals.cellar_upgrade_purchased.emit(upgrade, level + 1)
	BrewerySignals.brewery_state_changed.emit(brewery)
	brewery.check_bankruptcy()
