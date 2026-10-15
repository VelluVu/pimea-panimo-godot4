class_name CellarMachines
extends RefCounted

## Machines are cellar upgrades bought once with a season's money. Every later season
## starts with them owned (MetaProgressManager keeps them), and each has an on/off
## switch in the cellar upgrades window. See CellarUpgradeData.is_machine.

## Washes every emptied keg spotless, so the keg wash minigame is never needed.
const KEG_WASHER : String = "tynnyrinpesukone"
## Brews without the brew day minigame, at the perfect result.
const AUTO_KETTLE : String = "automaattikattila"


## Owned from an earlier season, or bought this season.
static func is_owned(upgrade_id : String, levels : Dictionary, owned_before : Array[String]) -> bool:
	return owned_before.has(upgrade_id) or levels.get(upgrade_id, 0) > 0


static func is_active(upgrade_id : String, levels : Dictionary, owned_before : Array[String], switched_off : Array[String]) -> bool:
	return is_owned(upgrade_id, levels, owned_before) and not switched_off.has(upgrade_id)
