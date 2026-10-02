@tool
extends McpTestSuite

## SettingsStore persistence on a throwaway file. The bus names do not exist in the
## editor's bus layout, so nothing is applied to its audio; set_fullscreen() is never
## called because it would resize the editor window.

const TEST_SAVE_PATH: String = "user://test_settings_store.cfg"
const BUS_A: StringName = &"TestBusA"
const BUS_B: StringName = &"TestBusB"


func suite_name() -> String:
	return "settings_store"


func _make_store() -> SettingsStore:
	var store: SettingsStore = track(SettingsStore.new())
	store.audio_buses = [BUS_A, BUS_B]
	store.default_muted_buses = [BUS_B]
	store.save_path = TEST_SAVE_PATH
	return store


func _cleanup() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(TEST_SAVE_PATH)


func test_defaults_without_a_file() -> void:
	_cleanup()
	var store := _make_store()
	store.load_settings()
	assert_eq(store.get_volume(BUS_A), store.default_volume)
	assert_false(store.is_muted(BUS_A))
	assert_true(store.is_muted(BUS_B))
	assert_false(store.fullscreen)


func test_volume_is_clamped() -> void:
	var store := _make_store()
	store.set_volume(BUS_A, 3.0)
	assert_eq(store.get_volume(BUS_A), 1.0)
	store.set_volume(BUS_A, -1.0)
	assert_eq(store.get_volume(BUS_A), 0.0)


func test_values_survive_a_save_and_load() -> void:
	var store := _make_store()
	store.set_volume(BUS_A, 0.3)
	store.set_muted(BUS_B, false)
	store.save_settings()

	var reloaded := _make_store()
	reloaded.load_settings()
	assert_true(is_equal_approx(reloaded.get_volume(BUS_A), 0.3))
	assert_false(reloaded.is_muted(BUS_B))
	_cleanup()


## Keys are "<bus>_volume" and "<bus>_muted" in [audio], the layout the game's
## settings.cfg has always used, so existing player files keep loading.
func test_reads_the_existing_file_layout() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "testbusa_volume", 0.25)
	config.set_value("audio", "testbusb_muted", false)
	config.set_value("video", "fullscreen", true)
	config.save(TEST_SAVE_PATH)

	var store := _make_store()
	store.load_settings()
	assert_true(is_equal_approx(store.get_volume(BUS_A), 0.25))
	assert_false(store.is_muted(BUS_B))
	assert_true(store.fullscreen)
	_cleanup()


func test_pick_locale_prefers_saved_then_system_then_fallback() -> void:
	var supported: Array[String] = ["fi", "en"]
	assert_eq(SettingsStore.pick_locale("en", "fi", supported, "en"), "en")
	assert_eq(SettingsStore.pick_locale("", "fi", supported, "en"), "fi")
	assert_eq(SettingsStore.pick_locale("", "de", supported, "en"), "en")
	assert_eq(SettingsStore.pick_locale("sv", "de", supported, "en"), "en", "an unsupported saved choice is ignored")


func test_language_survives_a_save_and_load() -> void:
	var store := _make_store()
	store.language = "en"
	store.save_settings()

	var reloaded := _make_store()
	reloaded.load_settings()
	assert_eq(reloaded.language, "en")
	_cleanup()
