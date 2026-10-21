@tool
extends McpTestSuite

## Unit tests for CellarCustomerSave.resume_slot: which counter spot a loaded customer gets.

const CellarCustomerSaveScript := preload("res://src/customers/cellar_customer_save.gd")


func suite_name() -> String:
	return "cellar_customer_save"


func test_keeps_the_saved_slot_when_free() -> void:
	var taken : Dictionary = {}
	assert_eq(CellarCustomerSaveScript.resume_slot(2, 5, taken, 0), 2)
	assert_true(taken.has(2))


func test_a_taken_slot_falls_back_to_the_free_one() -> void:
	var taken : Dictionary = {2: true}
	assert_eq(CellarCustomerSaveScript.resume_slot(2, 5, taken, 4), 4)
	assert_true(taken.has(4))


func test_a_slot_that_no_longer_exists_falls_back() -> void:
	assert_eq(CellarCustomerSaveScript.resume_slot(6, 3, {}, 1), 1)


func test_no_saved_slot_falls_back() -> void:
	assert_eq(CellarCustomerSaveScript.resume_slot(-1, 3, {}, 0), 0)


func test_nothing_free_gives_minus_one_and_takes_nothing() -> void:
	var taken : Dictionary = {0: true}
	assert_eq(CellarCustomerSaveScript.resume_slot(0, 1, taken, -1), -1)
	assert_eq(taken.size(), 1)
