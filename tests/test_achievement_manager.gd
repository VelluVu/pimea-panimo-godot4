@tool
extends McpTestSuite

## Unit tests for AchievementManager's stat-counter/unlock state machine —
## same fresh-instance-via-preload() isolation as test_meta_progress_manager.gd
## (never touches the real user://achievements.cfg, _ready() is never
## called so no autoload signals get connected on these instances, and
## every instance gets _save_path redirected to a throwaway file since
## _increment_stat()/_unlock() genuinely call _config.save() — see
## feedback_configfile_test_isolation memory).

const AchievementManagerScript := preload("res://src/autoload/achievement_manager.gd")
const TEST_SAVE_PATH : String = "user://test_achievement_manager.cfg"


func suite_name() -> String:
	return "achievement_manager"


func _make_manager() -> AchievementManagerScript:
	var manager := AchievementManagerScript.new()
	manager._save_path = TEST_SAVE_PATH
	return manager


func _make_achievement(id : String, stat_key : StringName, target : int) -> AchievementData:
	var achievement := AchievementData.new()
	achievement.achievement_id = id
	achievement.stat_key = stat_key
	achievement.target_value = target
	return achievement


func test_get_stat_defaults_to_zero() -> void:
	var manager := _make_manager()
	assert_eq(manager.get_stat(&"bar_shipments"), 0)


func test_is_unlocked_false_for_unknown_id() -> void:
	var manager := _make_manager()
	assert_false(manager.is_unlocked("does_not_exist"))


func test_on_keg_shipped_to_bar_increments_bar_shipments_stat() -> void:
	var manager := _make_manager()
	manager._on_keg_shipped_to_bar("Kotikalja", "Testibaari", 24, 12.0, 5)
	assert_eq(manager.get_stat(AchievementManagerScript.STAT_BAR_SHIPMENTS), 1)


func test_achievement_does_not_unlock_before_target() -> void:
	var manager := _make_manager()
	manager.achievement_pool = [_make_achievement("three_shipments", AchievementManagerScript.STAT_BAR_SHIPMENTS, 3)]

	manager._on_keg_shipped_to_bar("Kotikalja", "Testibaari", 24, 12.0, 5)
	manager._on_keg_shipped_to_bar("Kotikalja", "Testibaari", 24, 12.0, 5)

	assert_false(manager.is_unlocked("three_shipments"))


func test_achievement_unlocks_when_stat_reaches_target() -> void:
	var manager := _make_manager()
	manager.achievement_pool = [_make_achievement("three_shipments", AchievementManagerScript.STAT_BAR_SHIPMENTS, 3)]

	for i in range(3):
		manager._on_keg_shipped_to_bar("Kotikalja", "Testibaari", 24, 12.0, 5)

	assert_true(manager.is_unlocked("three_shipments"))


func test_achievement_unlock_emits_signal_with_id_and_title() -> void:
	var manager := _make_manager()
	var achievement := _make_achievement("three_shipments", AchievementManagerScript.STAT_BAR_SHIPMENTS, 1)
	achievement.title = "Vakiotoimittaja"
	manager.achievement_pool = [achievement]

	var captured : Dictionary = {}
	manager.achievement_unlocked.connect(func(id : String, title : String) -> void:
		captured["id"] = id
		captured["title"] = title
	)

	manager._on_keg_shipped_to_bar("Kotikalja", "Testibaari", 24, 12.0, 5)

	assert_eq(captured.get("id"), "three_shipments")
	assert_eq(captured.get("title"), "Vakiotoimittaja")


## Unrelated stat keys must never cross-trigger an achievement watching a
## different one — a bug here would let any signal hook accidentally
## unlock every achievement at once.
func test_unrelated_stat_increment_does_not_unlock_achievement() -> void:
	var manager := _make_manager()
	manager.achievement_pool = [_make_achievement("three_shipments", AchievementManagerScript.STAT_BAR_SHIPMENTS, 1)]

	manager._increment_stat(&"some_other_stat")

	assert_false(manager.is_unlocked("three_shipments"))


## One independent stat per style — style_discovered_<id> — not a single
## shared counter, so discovering one style never nudges another style's
## own achievement toward unlocking.
func test_on_style_discovered_increments_only_that_style_stat() -> void:
	var manager := _make_manager()
	manager._on_style_discovered(BeerStyle.Style.MARZEN)
	assert_eq(manager.get_stat(manager._style_stat_key(BeerStyle.Style.MARZEN)), 1)
	assert_eq(manager.get_stat(manager._style_stat_key(BeerStyle.Style.KOTIKALJA)), 0)


func test_special_event_resolved_ignores_a_failed_bribe() -> void:
	var manager := _make_manager()
	manager._on_special_event_resolved(false, RiskBribeEventData.new())
	assert_eq(manager.get_stat(AchievementManagerScript.STAT_LVV_BRIBES_SUCCEEDED), 0)


## Only a RiskBribeEventData counts as an "LVV" special event — a
## succeeded non-bribe event (any other SpecialEventData) must never
## nudge this stat, or every ordinary special event would silently count
## toward a bribery achievement.
func test_special_event_resolved_ignores_a_succeeded_non_bribe_event() -> void:
	var manager := _make_manager()
	manager._on_special_event_resolved(true, SpecialEventData.new())
	assert_eq(manager.get_stat(AchievementManagerScript.STAT_LVV_BRIBES_SUCCEEDED), 0)


func test_special_event_resolved_counts_a_succeeded_bribe() -> void:
	var manager := _make_manager()
	manager._on_special_event_resolved(true, RiskBribeEventData.new())
	assert_eq(manager.get_stat(AchievementManagerScript.STAT_LVV_BRIBES_SUCCEEDED), 1)


## Hand-built ingredients so the counting rule is tested without the live
## IngredientDatabase autoload or a Brewery (neither is available under the
## @tool test runner — see AchievementManager.count_unlocked_hops()).
func _make_ingredient(type : IngredientData.IngredientType, min_reputation : int) -> IngredientData:
	var ingredient := IngredientData.new()
	ingredient.type = type
	ingredient.min_reputation = min_reputation
	return ingredient


func test_count_unlocked_hops_counts_only_hops_within_reputation() -> void:
	var ingredients : Array = [
		_make_ingredient(IngredientData.IngredientType.HOP, 0),
		_make_ingredient(IngredientData.IngredientType.HOP, 10),
		_make_ingredient(IngredientData.IngredientType.HOP, 50),
		_make_ingredient(IngredientData.IngredientType.MALT, 0),
		_make_ingredient(IngredientData.IngredientType.YEAST, 0),
	]
	assert_eq(AchievementManagerScript.count_unlocked_hops(ingredients, 10), 2)
	assert_eq(AchievementManagerScript.count_unlocked_hops(ingredients, 999999), 3)
	assert_eq(AchievementManagerScript.count_unlocked_hops(ingredients, -1), 0)


## _set_stat_if_higher() is a ratchet: a later, lower hop count (e.g. after an
## LVV raid reputation penalty) must never claw back an already-recorded
## count — permanent-once-unlocked, same as every other stat here.
func test_hops_unlocked_stat_never_decreases() -> void:
	var manager := _make_manager()
	manager._set_stat_if_higher(AchievementManagerScript.STAT_HOPS_UNLOCKED, 5)
	manager._set_stat_if_higher(AchievementManagerScript.STAT_HOPS_UNLOCKED, 2)
	assert_eq(manager.get_stat(AchievementManagerScript.STAT_HOPS_UNLOCKED), 5)


func test_report_customer_unlocked_increments_customers_unlocked_stat() -> void:
	var manager := _make_manager()
	manager.report_customer_unlocked()
	manager.report_customer_unlocked()
	assert_eq(manager.get_stat(AchievementManagerScript.STAT_CUSTOMERS_UNLOCKED), 2)


## Every shipped AchievementData needs a non-empty, unique achievement_id —
## same reasoning as test_meta_progress_manager.gd's unlock_id check: a
## duplicate would let two achievements silently share one unlock flag.
func test_shipped_achievements_have_unique_nonempty_ids() -> void:
	var dir := DirAccess.open("res://src/resources/achievements/")
	assert_true(dir != null, "achievements folder should exist")

	var seen_ids : Array[String] = []
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var achievement : AchievementData = load("res://src/resources/achievements/" + file_name)
			assert_false(achievement.achievement_id.is_empty(), "%s: achievement_id is empty" % file_name)
			assert_false(seen_ids.has(achievement.achievement_id), "%s: duplicate achievement_id '%s'" % [file_name, achievement.achievement_id])
			seen_ids.append(achievement.achievement_id)
			assert_true(achievement.target_value > 0, "%s: target_value should be positive" % file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	assert_true(seen_ids.size() >= 29, "expected at least the 29 shipped achievements, found %d" % seen_ids.size())
