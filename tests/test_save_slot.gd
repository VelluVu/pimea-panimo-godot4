@tool
extends McpTestSuite

## SaveSlot's version stamp, newer-version guard and delete on a throwaway file.
## AchievementData stands in for a saved resource: version_property points at
## its int target_value. Never touches the real savegame.tres.

const TEST_PATH: String = "user://_test_save_slot.tres"


func suite_name() -> String:
	return "save_slot"


func teardown() -> void:
	SaveFile.delete(TEST_PATH)


func _make_slot(slot_version: int) -> SaveSlot:
	var slot: SaveSlot = track(SaveSlot.new())
	slot.save_path = TEST_PATH
	slot.version = slot_version
	slot.version_property = &"target_value"
	return slot


func _make_resource(label: String) -> AchievementData:
	var resource := AchievementData.new()
	resource.achievement_id = label
	return resource


func test_write_stamps_the_current_version() -> void:
	var resource := _make_resource("a")
	assert_true(_make_slot(3).write(resource))
	assert_eq(resource.target_value, 3)


func test_write_of_null_saves_nothing() -> void:
	SaveFile.delete(TEST_PATH)
	var slot := _make_slot(1)
	assert_false(slot.write(null))
	assert_false(slot.has_save())


func test_read_returns_an_older_save_at_the_current_version() -> void:
	_make_slot(1).write(_make_resource("old"))
	var loaded := _make_slot(2).read() as AchievementData
	assert_eq(loaded.achievement_id, "old")
	assert_eq(loaded.target_value, 2)


func test_read_refuses_a_save_from_a_newer_version() -> void:
	_make_slot(5).write(_make_resource("future"))
	assert_eq(_make_slot(4).read(), null)


func test_read_without_a_save_is_null() -> void:
	SaveFile.delete(TEST_PATH)
	assert_eq(_make_slot(1).read(), null)


func test_a_resource_without_the_version_property_is_version_zero() -> void:
	var slot := _make_slot(1)
	slot.version_property = &"no_such_property"
	assert_eq(slot.version_of(_make_resource("a")), 0)


func test_delete_save_removes_it() -> void:
	var slot := _make_slot(1)
	slot.write(_make_resource("a"))
	slot.delete_save()
	assert_false(slot.has_save())
