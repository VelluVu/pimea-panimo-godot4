@tool
extends McpTestSuite

## Unit tests for PerkStack: RunEffectsWindow's perk rows.

const PerkStackScript := preload("res://src/ui/perk_stack.gd")


func suite_name() -> String:
	return "perk_stack"


func _perk(perk_name : String, permanent : bool = false) -> RunPerk:
	var perk := RunPerk.new()
	perk.perk_name = perk_name
	perk.is_permanent = permanent
	return perk


func test_repeat_picks_stack_into_one_row_in_first_taken_order() -> void:
	var perks : Array[RunPerk] = [_perk("B"), _perk("A"), _perk("B")]
	var rows : Array[Dictionary] = PerkStackScript.rows(perks, false)
	assert_eq(rows.size(), 2)
	assert_eq(rows[0][PerkStackScript.KEY_PERK].perk_name, "B")
	assert_eq(rows[0][PerkStackScript.KEY_COUNT], 2)
	assert_eq(rows[1][PerkStackScript.KEY_COUNT], 1)


func test_permanent_and_run_perks_are_kept_apart() -> void:
	var perks : Array[RunPerk] = [_perk("Olutoppi", true), _perk("Nosto"), _perk("Olutoppi", true)]
	var permanent : Array[Dictionary] = PerkStackScript.rows(perks, true)
	var run : Array[Dictionary] = PerkStackScript.rows(perks, false)
	assert_eq(permanent.size(), 1)
	assert_eq(permanent[0][PerkStackScript.KEY_COUNT], 2)
	assert_eq(run.size(), 1)
	assert_eq(run[0][PerkStackScript.KEY_PERK].perk_name, "Nosto")


func test_scaled_olutoppi_perk_is_permanent() -> void:
	var unlock := MetaUnlockData.new()
	unlock.perk_name = "Testi"
	assert_true(unlock.get_scaled_perk(1).is_permanent)
	assert_false(RunPerk.new().is_permanent)
