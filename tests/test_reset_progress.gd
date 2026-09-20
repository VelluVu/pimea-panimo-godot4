@tool
extends McpTestSuite

## reset_progress() on the persistent-progress managers. Fresh instances with
## _save_path redirected to throwaway files, so the player's real progress is never touched.

const MetaProgressManagerScript := preload("res://src/autoload/meta_progress_manager.gd")
const AchievementManagerScript := preload("res://src/autoload/achievement_manager.gd")
const CustomerRegistryScript := preload("res://src/autoload/customer_registry.gd")
const TEST_PATH_FORMAT : String = "user://test_reset_progress_%s.cfg"


func suite_name() -> String:
	return "reset_progress"


func _cleanup(path : String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func test_meta_progress_reset_clears_renown_and_file() -> void:
	var path : String = TEST_PATH_FORMAT % "meta"
	var manager := MetaProgressManagerScript.new()
	manager._save_path = path
	manager.add_renown(50)
	assert_true(manager.get_renown() > 0)

	manager.reset_progress()

	assert_eq(manager.get_renown(), 0)
	var reloaded := ConfigFile.new()
	reloaded.load(path)
	assert_eq(reloaded.get_sections().size(), 0)
	_cleanup(path)


func test_achievement_reset_clears_stats() -> void:
	var path : String = TEST_PATH_FORMAT % "achievements"
	var manager := AchievementManagerScript.new()
	manager._save_path = path
	manager._increment_stat(&"test_stat", 3)
	assert_eq(manager.get_stat(&"test_stat"), 3)

	manager.reset_progress()

	assert_eq(manager.get_stat(&"test_stat"), 0)
	_cleanup(path)


func test_customer_registry_reset_forgets_announced_titles() -> void:
	var path : String = TEST_PATH_FORMAT % "customers"
	var registry := CustomerRegistryScript.new()
	registry._save_path = path
	registry._config.set_value(registry.SECTION, registry.KEY_ANNOUNCED_TITLES, ["Testi"])

	registry.reset_progress()

	assert_eq(registry._get_announced_titles().size(), 0)
	_cleanup(path)
