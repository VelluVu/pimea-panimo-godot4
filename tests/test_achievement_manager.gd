@tool
extends McpTestSuite

## The game's side of achievements (AchievementWiring): which events feed which
## stat, and the shipped achievement files. The counting and unlocking rules are
## in test_achievement_tracker.gd. Fresh instances via preload(), _ready() never
## called, save_path redirected to a throwaway file.

const AchievementManagerScript := preload("res://src/autoload/achievement_manager.gd")
const TEST_SAVE_PATH : String = "user://test_achievement_manager.cfg"


func suite_name() -> String:
	return "achievement_manager"


func teardown() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(TEST_SAVE_PATH)


func _make_manager() -> AchievementManagerScript:
	var manager : AchievementManagerScript = track(AchievementManagerScript.new())
	manager.save_path = TEST_SAVE_PATH
	return manager


func _make_achievement(id : String, stat_key : StringName, target : int) -> AchievementData:
	var achievement := AchievementData.new()
	achievement.achievement_id = id
	achievement.stat_key = stat_key
	achievement.target_value = target
	return achievement




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




## One independent stat per style — style_discovered_<id> — not a single
## shared counter, so discovering one style never nudges another style's
## own achievement toward unlocking.
func test_on_style_discovered_increments_only_that_style_stat() -> void:
	var manager := _make_manager()
	manager._on_style_discovered(BeerStyle.Style.MARZEN)
	assert_eq(manager.get_stat(AchievementManagerScript.style_stat_key(BeerStyle.Style.MARZEN)), 1)
	assert_eq(manager.get_stat(AchievementManagerScript.style_stat_key(BeerStyle.Style.KOTIKALJA)), 0)


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
## @tool test runner — see AchievementWiring.count_unlocked_hops()).
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


## A stat_key nothing feeds would leave its achievement impossible to unlock, with no error.
func test_shipped_achievements_watch_a_stat_the_manager_feeds() -> void:
	var fed : Array[StringName] = []
	var script : Script = AchievementManagerScript
	while script != null:
		var constants : Dictionary = script.get_script_constant_map()
		for constant_name : String in constants:
			if constant_name.begins_with("STAT_"):
				fed.append(constants[constant_name])
		script = script.get_base_script()
	var ids : Dictionary = {}
	for achievement : AchievementData in ResourceFolder.load_all("res://src/resources/achievements/", AchievementData):
		var style_stat : bool = String(achievement.stat_key).begins_with("style_discovered_")
		assert_true(style_stat or fed.has(achievement.stat_key), "%s watches unfed stat %s" % [achievement.achievement_id, achievement.stat_key])
		assert_false(ids.has(achievement.achievement_id), "duplicate id %s" % achievement.achievement_id)
		ids[achievement.achievement_id] = true
	assert_true(ids.size() >= 41, "expected every shipped achievement, found %d" % ids.size())


func test_tips_are_counted_in_cents() -> void:
	var manager : AchievementManagerScript = track(_make_manager())
	manager._on_sale_tip_gained(1.25)
	manager._on_sale_tip_gained(0.0)
	assert_eq(manager.get_stat(AchievementManagerScript.STAT_TIPS_CENTS), 125)


func test_only_a_survived_ending_counts_as_a_survived_run() -> void:
	var manager : AchievementManagerScript = track(_make_manager())
	manager._on_game_ended("busted")
	manager._on_game_ended("bankrupt")
	assert_eq(manager.get_stat(AchievementManagerScript.STAT_RUNS_SURVIVED), 0)
	manager._on_game_ended(AchievementManagerScript.ENDING_SURVIVED)
	assert_eq(manager.get_stat(AchievementManagerScript.STAT_RUNS_SURVIVED), 1)
