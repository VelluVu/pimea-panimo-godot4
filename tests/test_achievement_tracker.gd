@tool
extends McpTestSuite

## AchievementTracker on its own, with no game stats or signals: counting,
## ratcheting, unlocking and reset on a throwaway file, never the real
## user://achievements.cfg. _ready() is never called.

const TEST_SAVE_PATH : String = "user://test_achievement_tracker.cfg"
const STAT : StringName = &"test_stat"


func suite_name() -> String:
	return "achievement_tracker"


func teardown() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(TEST_SAVE_PATH)


func _make_tracker(pool : Array[AchievementData] = []) -> AchievementTracker:
	var tracker : AchievementTracker = track(AchievementTracker.new())
	tracker.save_path = TEST_SAVE_PATH
	tracker.achievement_pool = pool
	return tracker


func _make_achievement(id : String, stat_key : StringName, target : int) -> AchievementData:
	var achievement := AchievementData.new()
	achievement.achievement_id = id
	achievement.stat_key = stat_key
	achievement.target_value = target
	return achievement


func test_get_stat_defaults_to_zero() -> void:
	assert_eq(_make_tracker().get_stat(STAT), 0)


func test_is_unlocked_false_for_unknown_id() -> void:
	assert_false(_make_tracker().is_unlocked("does_not_exist"))


func test_increment_stat_adds_the_amount() -> void:
	var tracker := _make_tracker()
	tracker.increment_stat(STAT)
	tracker.increment_stat(STAT, 4)
	assert_eq(tracker.get_stat(STAT), 5)


func test_achievement_does_not_unlock_before_target() -> void:
	var tracker := _make_tracker([_make_achievement("three", STAT, 3)])
	tracker.increment_stat(STAT, 2)
	assert_false(tracker.is_unlocked("three"))


func test_achievement_unlocks_when_stat_reaches_target() -> void:
	var tracker := _make_tracker([_make_achievement("three", STAT, 3)])
	tracker.increment_stat(STAT, 2)
	tracker.increment_stat(STAT)
	assert_true(tracker.is_unlocked("three"))


func test_a_jump_past_the_target_still_unlocks() -> void:
	var tracker := _make_tracker([_make_achievement("three", STAT, 3)])
	tracker.increment_stat(STAT, 10)
	assert_true(tracker.is_unlocked("three"))


func test_unlock_emits_signal_with_id_and_title() -> void:
	var achievement := _make_achievement("one", STAT, 1)
	achievement.title = "Vakiotoimittaja"
	var tracker := _make_tracker([achievement])
	var captured : Dictionary = {}
	tracker.achievement_unlocked.connect(func(id : String, title : String) -> void:
		captured["id"] = id
		captured["title"] = title
	)
	tracker.increment_stat(STAT)
	assert_eq(captured.get("id"), "one")
	assert_eq(captured.get("title"), "Vakiotoimittaja")


func test_unlock_fires_only_once() -> void:
	var tracker := _make_tracker([_make_achievement("one", STAT, 1)])
	var count : Array[int] = [0]
	tracker.achievement_unlocked.connect(func(_id : String, _title : String) -> void: count[0] += 1)
	tracker.increment_stat(STAT)
	tracker.increment_stat(STAT)
	assert_eq(count[0], 1)


## A bug here would let any stat unlock every achievement at once.
func test_unrelated_stat_does_not_unlock_achievement() -> void:
	var tracker := _make_tracker([_make_achievement("one", STAT, 1)])
	tracker.increment_stat(&"some_other_stat")
	assert_false(tracker.is_unlocked("one"))


func test_set_stat_if_higher_never_decreases() -> void:
	var tracker := _make_tracker()
	tracker.set_stat_if_higher(STAT, 5)
	tracker.set_stat_if_higher(STAT, 2)
	assert_eq(tracker.get_stat(STAT), 5)


func test_set_stat_if_higher_unlocks_at_target() -> void:
	var tracker := _make_tracker([_make_achievement("five", STAT, 5)])
	tracker.set_stat_if_higher(STAT, 5)
	assert_true(tracker.is_unlocked("five"))


func test_progress_persists_to_the_save_file() -> void:
	_make_tracker([_make_achievement("one", STAT, 1)]).increment_stat(STAT, 2)
	var reloaded := _make_tracker()
	reloaded._ready()
	assert_eq(reloaded.get_stat(STAT), 2)
	assert_true(reloaded.is_unlocked("one"))


func test_reset_progress_clears_stats_and_unlocks() -> void:
	var tracker := _make_tracker([_make_achievement("one", STAT, 1)])
	tracker.increment_stat(STAT)
	tracker.reset_progress()
	assert_eq(tracker.get_stat(STAT), 0)
	assert_false(tracker.is_unlocked("one"))
