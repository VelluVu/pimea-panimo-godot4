class_name ChristmasGiftRules
extends RefCounted

## What Joulupukki can wrap: a cellar upgrade with a level left (not a machine owned from an
## earlier season), or an event perk the run does not have yet.


## Up to `count` different gifts in random order.
static func roll(upgrades : Array[CellarUpgradeData], levels : Dictionary, owned_machines : Array[String], perks : Array[RunPerk], active_perks : Array[RunPerk], count : int) -> Array[ChristmasGift]:
	var gifts : Array[ChristmasGift] = []
	for upgrade : CellarUpgradeData in upgrades:
		if can_wrap_upgrade(upgrade, levels.get(upgrade.upgrade_id, 0), owned_machines):
			gifts.append(ChristmasGift.of_upgrade(upgrade))
	for perk : RunPerk in perks:
		if not has_perk(active_perks, perk):
			gifts.append(ChristmasGift.of_perk(perk))
	gifts.shuffle()
	return gifts.slice(0, mini(count, gifts.size()))


static func can_wrap_upgrade(upgrade : CellarUpgradeData, level : int, owned_machines : Array[String]) -> bool:
	return level < upgrade.max_level and not (upgrade.is_machine and owned_machines.has(upgrade.upgrade_id))


## By name, since a loaded save holds copies of the perk resources.
static func has_perk(active_perks : Array[RunPerk], perk : RunPerk) -> bool:
	return active_perks.any(func(owned : RunPerk) -> bool: return owned.perk_name == perk.perk_name)
