@tool
extends McpTestSuite

## WeightedPicker's odds, using the injectable roll instead of real randomness,
## and ResourceFolder's type filtering over a real shipped folder.

const WeightedPickerScript := preload("res://systems/toolkit/weighted_picker.gd")
const ResourceFolderScript := preload("res://systems/toolkit/resource_folder.gd")


func suite_name() -> String:
	return "weighted_picker"


func test_roll_selects_by_cumulative_weight() -> void:
	var items: Array = ["a", "b", "c"]
	var weights: Array[float] = [1.0, 2.0, 1.0]
	assert_eq(WeightedPickerScript.pick(items, weights, 0.0), "a")
	assert_eq(WeightedPickerScript.pick(items, weights, 0.3), "b")
	assert_eq(WeightedPickerScript.pick(items, weights, 0.7), "b")
	assert_eq(WeightedPickerScript.pick(items, weights, 0.9), "c")


func test_zero_weight_item_is_never_picked() -> void:
	var items: Array = ["a", "b"]
	var weights: Array[float] = [0.0, 1.0]
	for roll: float in [0.0, 0.5, 0.99]:
		assert_eq(WeightedPickerScript.pick(items, weights, roll), "b")


func test_empty_items_returns_null() -> void:
	var weights: Array[float] = []
	assert_eq(WeightedPickerScript.pick([], weights), null)


func test_all_zero_weights_still_returns_an_item() -> void:
	var items: Array = ["a", "b"]
	var weights: Array[float] = [0.0, 0.0]
	assert_true(items.has(WeightedPickerScript.pick(items, weights)))


func test_resource_folder_loads_only_the_requested_type() -> void:
	var contacts: Array = ResourceFolderScript.load_all("res://src/resources/bars/", BarContact)
	assert_true(contacts.size() > 0)
	for contact in contacts:
		assert_true(contact is BarContact)
	assert_eq(ResourceFolderScript.load_all("res://src/resources/bars/", CustomerData).size(), 0)
