class_name CellarCustomerSave
extends RefCounted

## Puts CustomerSpawner's cellar into the save and back: the customers present (group
## members with their group), crowds, walk-ins already on their way and the visit timers.

var _spawner : CustomerSpawner
var _group_visit : GroupVisitDirector
## The spawner's own list, shared: {"data": CustomerData or null, "timer": SceneTreeTimer}.
var _scheduled : Array[Dictionary]
var _free_slot : Callable
var _schedule_walk_in : Callable


func _init(spawner : CustomerSpawner, group_visit : GroupVisitDirector, scheduled : Array[Dictionary], free_slot : Callable, schedule_walk_in : Callable) -> void:
	_spawner = spawner
	_group_visit = group_visit
	_scheduled = scheduled
	_free_slot = free_slot
	_schedule_walk_in = schedule_walk_in


func record(brewery : Brewery) -> void:
	brewery.cellar_customers.clear()
	for node : Node in _spawner.get_children():
		var customer := node as Customer
		if customer != null and not customer.is_queued_for_deletion() and not customer.is_group_member():
			brewery.cellar_customers.append(customer.snapshot())
	brewery.cellar_groups = _group_visit.snapshots()
	brewery.scheduled_walk_ins.clear()
	for entry : Dictionary in _scheduled:
		brewery.scheduled_walk_ins.append({"data": entry.data, "seconds": entry.timer.time_left})
	brewery.walk_in_time_left = _time_left(_spawner.walk_in_timer)
	brewery.group_visit_time_left = _time_left(_spawner.group_event_timer)


## After a load, puts the saved customers and crowds back to carry on. A solo customer
## already leaving holds no counter spot.
func resume(brewery : Brewery) -> void:
	var taken : Dictionary = {}
	for snap : CustomerSnapshot in brewery.cellar_customers:
		var slot : int = -1
		if snap.phase != CustomerSnapshot.Phase.LEAVING:
			slot = _take_slot(snap.slot, taken)
			if slot == -1:
				continue
			if snap.route.size() == 4:
				snap.route[3] = _spawner.counter_positions[slot]
		_resume_customer(snap, slot)
	brewery.cellar_customers.clear()

	for group_snap : GroupVisitSnapshot in brewery.cellar_groups:
		var slot : int = _take_slot(group_snap.slot, taken)
		if slot != -1:
			_group_visit.resume(group_snap, slot, _spawner.counter_positions[slot])
	brewery.cellar_groups.clear()

	for entry : Dictionary in brewery.scheduled_walk_ins:
		_schedule_walk_in.call(entry.get("data"), entry.get("seconds", 0.0))
	brewery.scheduled_walk_ins.clear()
	_resume_timer(_spawner.walk_in_timer, brewery.walk_in_time_left)
	_resume_timer(_spawner.group_event_timer, brewery.group_visit_time_left)


## The saved counter slot if it is still there and free, else `free_slot` (-1 for none);
## the slot chosen is marked in `taken`.
static func resume_slot(saved_slot : int, slot_count : int, taken : Dictionary, free_slot : int) -> int:
	var saved_fits : bool = saved_slot >= 0 and saved_slot < slot_count and not taken.has(saved_slot)
	var slot : int = saved_slot if saved_fits else free_slot
	if slot != -1:
		taken[slot] = true
	return slot


func _take_slot(saved_slot : int, taken : Dictionary) -> int:
	return resume_slot(saved_slot, _spawner.counter_positions.size(), taken, _free_slot.call())


func _resume_customer(snap : CustomerSnapshot, slot : int) -> void:
	var customer : Customer = CustomerSpawner.CUSTOMER_SCENE.instantiate()
	_spawner.add_child(customer)
	customer.customer_data = snap.data
	customer.generated_name = snap.generated_name
	customer.assigned_slot = slot
	customer.dialogue_slot = slot
	if slot != -1:
		CustomerManager.register_active_customer(slot, customer)
	customer.resume(snap)


## A raid already under way (LvvRaidSpawner) keeps the timers stopped.
func _resume_timer(timer : Timer, seconds_left : float) -> void:
	if seconds_left > 0.0 and not _spawner.is_paused():
		timer.start(seconds_left)


static func _time_left(timer : Timer) -> float:
	return -1.0 if timer.is_stopped() else timer.time_left
