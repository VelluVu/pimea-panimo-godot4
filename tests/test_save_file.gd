@tool
extends McpTestSuite

## Unit tests for SaveFile's crash-safe write/read/backup logic. Uses a plain
## RunModifier as the saved Resource and its own scratch path under user://,
## never the real savegame.tres. Loaded by path so the suite always runs the
## script as it is on disk.

const SaveFileScript := preload("res://src/classes/save_file.gd")
const TEST_PATH : String = "user://_test_save_file.tres"


func suite_name() -> String:
	return "save_file"


func teardown() -> void:
	SaveFileScript.delete(TEST_PATH)


func _make(label : String) -> RunModifier:
	var modifier := RunModifier.new()
	modifier.modifier_name = label
	return modifier


func _corrupt(path : String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("this is not a resource")
	file.close()


func test_missing_save_reads_as_null_and_does_not_exist() -> void:
	SaveFileScript.delete(TEST_PATH)
	assert_false(SaveFileScript.exists(TEST_PATH))
	assert_eq(SaveFileScript.read(TEST_PATH), null)


func test_write_then_read_round_trips() -> void:
	assert_eq(SaveFileScript.write(_make("first"), TEST_PATH), OK)
	assert_true(SaveFileScript.exists(TEST_PATH))
	assert_eq((SaveFileScript.read(TEST_PATH) as RunModifier).modifier_name, "first")


func test_write_leaves_no_temp_file_behind() -> void:
	SaveFileScript.write(_make("first"), TEST_PATH)
	assert_false(FileAccess.file_exists(SaveFileScript.temp_path(TEST_PATH)))


func test_second_write_keeps_the_previous_save_as_backup() -> void:
	SaveFileScript.write(_make("first"), TEST_PATH)
	SaveFileScript.write(_make("second"), TEST_PATH)
	assert_eq((SaveFileScript.read(TEST_PATH) as RunModifier).modifier_name, "second")
	var backup := ResourceLoader.load(SaveFileScript.backup_path(TEST_PATH), "", ResourceLoader.CACHE_MODE_IGNORE) as RunModifier
	assert_eq(backup.modifier_name, "first")


func test_read_falls_back_to_backup_when_main_file_is_corrupt() -> void:
	SaveFileScript.write(_make("first"), TEST_PATH)
	SaveFileScript.write(_make("second"), TEST_PATH)
	_corrupt(TEST_PATH)
	assert_eq((SaveFileScript.read(TEST_PATH) as RunModifier).modifier_name, "first")


func test_read_is_null_when_main_and_backup_are_both_corrupt() -> void:
	SaveFileScript.write(_make("first"), TEST_PATH)
	SaveFileScript.write(_make("second"), TEST_PATH)
	_corrupt(TEST_PATH)
	_corrupt(SaveFileScript.backup_path(TEST_PATH))
	assert_eq(SaveFileScript.read(TEST_PATH), null)


func test_a_backup_alone_still_counts_as_a_save() -> void:
	SaveFileScript.write(_make("first"), TEST_PATH)
	SaveFileScript.write(_make("second"), TEST_PATH)
	DirAccess.remove_absolute(TEST_PATH)
	assert_true(SaveFileScript.exists(TEST_PATH))
	assert_eq((SaveFileScript.read(TEST_PATH) as RunModifier).modifier_name, "first")


func test_failed_write_reports_an_error_and_keeps_the_existing_save() -> void:
	SaveFileScript.write(_make("first"), TEST_PATH)
	var err : Error = SaveFileScript.write(_make("second"), "user://_no_such_dir_for_test/save.tres")
	assert_ne(err, OK)
	assert_eq((SaveFileScript.read(TEST_PATH) as RunModifier).modifier_name, "first")


func test_delete_removes_save_backup_and_temp() -> void:
	SaveFileScript.write(_make("first"), TEST_PATH)
	SaveFileScript.write(_make("second"), TEST_PATH)
	SaveFileScript.delete(TEST_PATH)
	assert_false(SaveFileScript.exists(TEST_PATH))
	assert_false(FileAccess.file_exists(SaveFileScript.backup_path(TEST_PATH)))
