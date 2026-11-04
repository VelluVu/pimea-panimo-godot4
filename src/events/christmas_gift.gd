class_name ChristmasGift
extends Resource

## One of Joulupukki's wrapped gifts: a free level of a cellar upgrade, or an event perk. A
## Resource, so unopened gifts are saved with the Brewery.

@export var upgrade : CellarUpgradeData = null
@export var perk : RunPerk = null


static func of_upgrade(data : CellarUpgradeData) -> ChristmasGift:
	var gift := ChristmasGift.new()
	gift.upgrade = data
	return gift


static func of_perk(data : RunPerk) -> ChristmasGift:
	var gift := ChristmasGift.new()
	gift.perk = data
	return gift


func display_name() -> String:
	return upgrade.perk_name if upgrade != null else perk.perk_name
