@tool
extends McpTestSuite

## Unit tests for CellarMachines: owned from an earlier season or bought now, and the switch.

const CellarMachinesScript := preload("res://src/brewery/cellar_machines.gd")
const WASHER : String = "tynnyrinpesukone"


func suite_name() -> String:
	return "cellar_machines"


func test_a_machine_nobody_bought_is_not_owned() -> void:
	assert_false(CellarMachinesScript.is_owned(WASHER, {}, [] as Array[String]))


func test_a_machine_bought_this_season_is_owned() -> void:
	assert_true(CellarMachinesScript.is_owned(WASHER, {WASHER: 1}, [] as Array[String]))


func test_a_machine_from_an_earlier_season_is_owned() -> void:
	assert_true(CellarMachinesScript.is_owned(WASHER, {}, [WASHER] as Array[String]))


func test_an_owned_machine_runs_until_switched_off() -> void:
	var owned : Array[String] = [WASHER]
	assert_true(CellarMachinesScript.is_active(WASHER, {}, owned, [] as Array[String]))
	assert_false(CellarMachinesScript.is_active(WASHER, {}, owned, [WASHER] as Array[String]))


func test_an_earlier_machine_adds_no_worth_this_season() -> void:
	var upgrade := CellarUpgradeData.new()
	upgrade.upgrade_id = WASHER
	upgrade.is_machine = true
	upgrade.max_level = 1
	upgrade.base_cost = 400
	var upgrades : Array[CellarUpgradeData] = [upgrade]
	assert_eq(CellarUpgrades.invested_value({}, upgrades), 0)
	assert_eq(CellarUpgrades.invested_value({WASHER: 1}, upgrades), 400)
