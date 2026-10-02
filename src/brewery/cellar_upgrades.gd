class_name CellarUpgrades
extends RefCounted

## Loads the cellar upgrades and turns a run's purchased levels into perks for
## PerkStats. The lookups take the upgrade list as a parameter so tests can pass their own.

const FOLDER_PATH : String = "res://src/resources/cellar_upgrades/"

static var _loaded : Array[CellarUpgradeData] = []


## Every upgrade in window order. Loaded once.
static func all() -> Array[CellarUpgradeData]:
	if _loaded.is_empty():
		_loaded.assign(ResourceFolder.load_all(FOLDER_PATH, CellarUpgradeData))
		_loaded.sort_custom(func(a : CellarUpgradeData, b : CellarUpgradeData) -> bool: return a.sort_order < b.sort_order)
	return _loaded


static func find(upgrade_id : String, upgrades : Array[CellarUpgradeData]) -> CellarUpgradeData:
	for upgrade : CellarUpgradeData in upgrades:
		if upgrade.upgrade_id == upgrade_id:
			return upgrade
	return null


## One scaled perk per upgrade bought at least once. `levels` maps upgrade_id to level.
static func perks_for(levels : Dictionary, upgrades : Array[CellarUpgradeData]) -> Array[RunPerk]:
	var perks : Array[RunPerk] = []
	for upgrade : CellarUpgradeData in upgrades:
		var level : int = mini(levels.get(upgrade.upgrade_id, 0), upgrade.max_level)
		if level > 0:
			perks.append(upgrade.scaled_copy(level))
	return perks
