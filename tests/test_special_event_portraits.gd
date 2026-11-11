@tool
extends McpTestSuite

## Every special event caller has a portrait sheet, the stray cat excepted.

const EVENT_FOLDER : String = "res://src/resources/special_events/"
const NO_PORTRAIT : Array[String] = ["stray_cat.tres"]
## Two 48 px frames side by side.
const PORTRAIT_SIZE : Vector2i = Vector2i(96, 48)


func suite_name() -> String:
	return "special_event_portraits"


func test_callers_have_their_portraits() -> void:
	var checked : int = 0
	for file : String in DirAccess.get_files_at(EVENT_FOLDER):
		if not file.ends_with(".tres"):
			continue
		var event : SpecialEventData = load(EVENT_FOLDER + file)
		if NO_PORTRAIT.has(file):
			assert_true(event.portrait == null, file)
			continue
		assert_true(event.portrait != null, file)
		if event.portrait != null:
			assert_eq(Vector2i(event.portrait.get_size()), PORTRAIT_SIZE, file)
		checked += 1
	assert_gt(checked, 17)
