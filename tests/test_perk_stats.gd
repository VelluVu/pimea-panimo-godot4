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
		if typeof(constants[constant]) != TYPE_STRING_NAME:
			continue
		var stat : StringName = constants[constant]
		assert_true(stat in perk, "RunPerk has no field %s" % stat)


func test_every_numeric_perk_field_is_in_the_definitions_table() -> void:
	var registered : Array = PerkStatsScript.definitions().map(func(entry : Dictionary) -> StringName: return entry.stat)
	for property : Dictionary in RunPerk.new().get_property_list():
		if not (property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		if property.type != TYPE_FLOAT and property.type != TYPE_INT:
			continue
		if property.name == "tier":
			continue
		assert_true(StringName(property.name) in registered, "%s is a RunPerk stat missing from PerkStats.definitions()" % property.name)


func test_definitions_have_no_duplicate_stats() -> void:
	var seen : Dictionary = {}
	for entry : Dictionary in PerkStatsScript.definitions():
		assert_false(seen.has(entry.stat), "%s is listed twice" % entry.stat)
		seen[entry.stat] = true


func test_display_number_per_kind() -> void:
	assert_eq(PerkStatsScript.display_number(PerkStatsScript.Kind.MULTIPLIER, 1.15), 15)
	assert_eq(PerkStatsScript.display_number(PerkStatsScript.Kind.MULTIPLIER, 0.85), -15)
	assert_eq(PerkStatsScript.display_number(PerkStatsScript.Kind.PERCENT_ADD, 0.24), 24)
	assert_eq(PerkStatsScript.display_number(PerkStatsScript.Kind.COUNT, 2.0), 2)


func test_scale_per_level_per_kind() -> void:
	assert_true(is_equal_approx(PerkStatsScript.scale_per_level(PerkStatsScript.Kind.MULTIPLIER, 1.03, 2), 1.06))
	assert_true(is_equal_approx(PerkStatsScript.scale_per_level(PerkStatsScript.Kind.PERCENT_ADD, 0.02, 2), 0.04))
	assert_eq(PerkStatsScript.scale_per_level(PerkStatsScript.Kind.COUNT, 1.0, 3), 3)

