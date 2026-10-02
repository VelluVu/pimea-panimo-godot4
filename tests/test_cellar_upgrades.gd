@tool
extends McpTestSuite

## Unit tests for CellarUpgrades' perk scaling and the shipped upgrade files.

const UpgradesScript := preload("res://src/brewery/cellar_upgrades.gd")
const UpgradeScript := preload("res://src/brewery/cellar_upgrade_data.gd")


func suite_name() -> String:
	return "cellar_upgrades"


func _upgrade(upgrade_id : String) -> CellarUpgradeData:
	var upgrade : CellarUpgradeData = UpgradeScript.new()
	upgrade.upgrade_id = upgrade_id
	upgrade.max_level = 5
	upgrade.brew_yield_multiplier = 1.06
	upgrade.extra_counter_slots = 1
	return upgrade


func test_unbought_upgrades_add_no_perk() -> void:
	var upgrades : Array[CellarUpgradeData] = [_upgrade("a")]
	assert_eq(UpgradesScript.perks_for({}, upgrades).size(), 0)


func test_perk_scales_with_the_level() -> void:
	var upgrades : Array[CellarUpgradeData] = [_upgrade("a")]
	var perk : RunPerk = UpgradesScript.perks_for({"a": 3}, upgrades)[0]
	assert_true(is_equal_approx(perk.brew_yield_multiplier, 1.18))
	assert_eq(perk.extra_counter_slots, 3)


func test_level_is_capped_at_the_max() -> void:
	var upgrades : Array[CellarUpgradeData] = [_upgrade("a")]
	assert_eq(UpgradesScript.perks_for({"a": 9}, upgrades)[0].extra_counter_slots, 5)


func test_find_by_id() -> void:
	var upgrades : Array[CellarUpgradeData] = [_upgrade("a"), _upgrade("b")]
	assert_eq(UpgradesScript.find("b", upgrades), upgrades[1])
	assert_eq(UpgradesScript.find("x", upgrades), null)


func test_shipped_upgrades_have_unique_ids_and_five_levels() -> void:
	var upgrades : Array[CellarUpgradeData] = UpgradesScript.all()
	assert_gt(upgrades.size(), 0)
	var ids : Dictionary = {}
	for upgrade : CellarUpgradeData in upgrades:
		assert_false(ids.has(upgrade.upgrade_id), "duplicate id %s" % upgrade.upgrade_id)
		ids[upgrade.upgrade_id] = true
		assert_eq(upgrade.max_level, 5)
		assert_ne(CellarUpgradeText.effect(upgrade, 1), "", "%s has no stat" % upgrade.upgrade_id)
