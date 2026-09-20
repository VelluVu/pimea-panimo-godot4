@tool
extends McpTestSuite

## Unit tests for PerkStats, the view that replaced Brewery's hand-written
## get_X_multiplier() getters. Loaded by path so the suite always runs the
## script as it is on disk.

const PerkStatsScript := preload("res://src/classes/perk_stats.gd")


func suite_name() -> String:
	return "perk_stats"


func _stats(modifier : RunModifier, perks : Array[RunPerk]) -> PerkStatsScript:
	return PerkStatsScript.new(modifier, perks)


func test_multiplier_is_neutral_with_nothing_active() -> void:
	assert_eq(_stats(RunModifier.new(), []).multiplier(PerkStatsScript.TIP_INCOME), 1.0)


func test_multiplier_starts_from_the_modifier_field() -> void:
	var modifier := RunModifier.new()
	modifier.tip_income_multiplier = 1.5
	var perk := RunPerk.new()
	perk.tip_income_multiplier = 2.0
	assert_true(is_equal_approx(_stats(modifier, [perk]).multiplier(PerkStatsScript.TIP_INCOME), 3.0))


func test_multiplier_without_modifier_counterpart_starts_at_one() -> void:
	var perk := RunPerk.new()
	perk.counter_price_multiplier = 1.2
	assert_true(is_equal_approx(_stats(RunModifier.new(), [perk]).multiplier(PerkStatsScript.COUNTER_PRICE), 1.2))


func test_multiplier_honours_additive_stacking() -> void:
	var a := RunPerk.new()
	a.spawn_interval_multiplier = 0.9
	a.stacks_additively = true
	var b := RunPerk.new()
	b.spawn_interval_multiplier = 0.9
	b.stacks_additively = true
	assert_true(is_equal_approx(_stats(RunModifier.new(), [a, b]).multiplier(PerkStatsScript.SPAWN_INTERVAL), 0.8))


func test_total_adds_modifier_and_perk_quality_bonus() -> void:
	var modifier := RunModifier.new()
	modifier.quality_bonus = 0.05
	var perk := RunPerk.new()
	perk.quality_bonus = 0.10
	assert_true(is_equal_approx(_stats(modifier, [perk, perk]).total(PerkStatsScript.QUALITY_BONUS), 0.25))


func test_total_sums_integer_stats() -> void:
	var perk := RunPerk.new()
	perk.extra_raid_strikes = 2
	assert_eq(int(_stats(RunModifier.new(), [perk, perk]).total(PerkStatsScript.EXTRA_RAID_STRIKES)), 4)


func test_chance_is_clamped_to_one() -> void:
	var perk := RunPerk.new()
	perk.ingredient_refund_chance = 0.7
	assert_eq(_stats(RunModifier.new(), [perk, perk]).chance(PerkStatsScript.INGREDIENT_REFUND_CHANCE), 1.0)


func test_raid_threshold_scales_by_modifier_and_perks() -> void:
	var modifier := RunModifier.new()
	modifier.lvv_threshold_multiplier = 0.5
	var perk := RunPerk.new()
	perk.raid_threshold_multiplier = 1.2
	assert_eq(_stats(modifier, [perk]).raid_threshold(100), 60)


func test_null_modifier_is_treated_as_neutral() -> void:
	var stats := _stats(null, [])
	assert_eq(stats.multiplier(PerkStatsScript.TIP_INCOME), 1.0)
	assert_eq(stats.raid_threshold(100), 100)


func test_every_stat_constant_names_a_real_perk_field() -> void:
	var perk := RunPerk.new()
	var script : Script = PerkStatsScript
	var constants : Dictionary = script.get_script_constant_map()
	assert_gt(constants.size(), 0)
	for constant : String in constants:
		var stat : StringName = constants[constant]
		assert_true(stat in perk, "RunPerk has no field %s" % stat)
