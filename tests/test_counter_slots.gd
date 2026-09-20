@tool
extends McpTestSuite

## Unit tests for CounterSlots, the counter-position bookkeeping behind
## CustomerManager. Loaded by path so the suite always runs the script as it is
## on disk.

const CounterSlotsScript := preload("res://src/customers/counter_slots.gd")


func suite_name() -> String:
	return "counter_slots"


func _customer() -> Node2D:
	return track(Node2D.new())


func test_new_slots_are_all_free() -> void:
	var slots = CounterSlotsScript.new(3)
	assert_eq(slots.size(), 3)
	assert_eq(slots.first_free(), 0)
	assert_false(slots.has_customers())


func test_registering_takes_the_slot_and_the_next_free_moves_on() -> void:
	var slots = CounterSlotsScript.new(3)
	slots.register(0, _customer())
	assert_eq(slots.first_free(), 1)
	assert_true(slots.has_customers())


func test_releasing_frees_the_slot_again() -> void:
	var slots = CounterSlotsScript.new(3)
	slots.register(0, _customer())
	slots.release(0)
	assert_eq(slots.first_free(), 0)
	assert_false(slots.has_customers())


func test_a_full_counter_has_no_free_slot() -> void:
	var slots = CounterSlotsScript.new(2)
	slots.register(0, _customer())
	slots.register(1, _customer())
	assert_eq(slots.first_free(), -1)


func test_a_shared_slot_is_freed_only_when_its_last_occupant_leaves() -> void:
	var slots = CounterSlotsScript.new(2)
	slots.register(0, _customer())
	slots.register(0, _customer())
	slots.release(0)
	assert_eq(slots.first_free(), 1, "one member is still standing at slot 0")
	assert_true(slots.has_customers())
	slots.release(0)
	assert_eq(slots.first_free(), 0)
	assert_false(slots.has_customers())


func test_releasing_an_empty_slot_stays_free() -> void:
	var slots = CounterSlotsScript.new(2)
	slots.release(1)
	slots.release(1)
	assert_eq(slots.first_free(), 0)
	slots.register(1, _customer())
	slots.release(1)
	assert_eq(slots.first_free(), 0)


func test_customers_lists_one_node_per_occupied_slot() -> void:
	var slots = CounterSlotsScript.new(3)
	var first := _customer()
	var second := _customer()
	slots.register(0, first)
	slots.register(2, second)
	var listed : Array = slots.customers()
	assert_eq(listed.size(), 2)
	assert_true(listed.has(first) and listed.has(second))


func test_reset_frees_everything_and_resizes() -> void:
	var slots = CounterSlotsScript.new(2)
	slots.register(0, _customer())
	slots.reset(4)
	assert_eq(slots.size(), 4)
	assert_eq(slots.first_free(), 0)
	assert_false(slots.has_customers())
