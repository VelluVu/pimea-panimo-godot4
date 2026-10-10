class_name CustomerSpawner
extends Node2D

## Schedules walk-ins and group visits on two timers and sends each new customer to a
## free counter slot. The sales themselves happen in CustomerManager.

const CUSTOMER_SCENE: PackedScene = preload("res://src/scenes/customer.tscn")
## Sent in once a season when LVV risk reaches Brewery.LVV_INSPECTOR_VISIT_RISK.
const LVV_INSPECTOR: CustomerData = preload("res://src/resources/visitors/lvv_inspector.tres")

@onready var counter_positions_parent: Node2D = $CounterPositionsParent
@onready var stairs_bottom_marker: Marker2D = $StairsBottomMarker
@onready var room_center_marker: Marker2D = $RoomCenterMarker

var walk_in_timer: Timer
var group_event_timer: Timer
var counter_markers: Array[Node2D] = []
## Global counter spots in slot order, see layout_counter().
var counter_positions: Array[Vector2] = []
var _group_visit: GroupVisitDirector
## Set during a raid. Brewery state changes call start_spawning() all the time, so the
## timers alone cannot hold a pause.
var _paused: bool = false
## Walk-ins already on their way: {"data": CustomerData or null, "timer": SceneTreeTimer}.
var _scheduled: Array[Dictionary] = []


func _ready() -> void:
	walk_in_timer = _make_timer(spawn_walk_in)
	group_event_timer = _make_timer(spawn_group_visit)
	_setup_positions()
	_group_visit = GroupVisitDirector.new(self, stairs_bottom_marker, room_center_marker, _active_styles)
	CustomerManager.register_spawner(self)
	BrewerySignals.friend_recommended.connect(_on_friend_recommended)
	BrewerySignals.bad_review_spread.connect(_on_bad_review_spread)
	BrewerySignals.lvv_inspector_visit_due.connect(_on_lvv_inspector_visit_due)
	BrewEngine.brewery_about_to_save.connect(_record_cellar_customers)
	_resume_cellar_customers.call_deferred()


func _make_timer(on_timeout: Callable) -> Timer:
	var timer := Timer.new()
	timer.process_callback = Timer.TIMER_PROCESS_IDLE
	timer.one_shot = true
	timer.timeout.connect(on_timeout)
	add_child(timer)
	return timer


func _setup_positions() -> void:
	if counter_positions_parent:
		for child: Node in counter_positions_parent.get_children():
			if child is Node2D:
				counter_markers.append(child)
	layout_counter(counter_markers.size())


## Spreads `count` counter spots over the markers' span, see CounterLayout.
func layout_counter(count: int) -> void:
	var markers: Array[Vector2] = []
	for marker: Node2D in counter_markers:
		markers.append(marker.global_position)
	counter_positions = CounterLayout.positions(markers, count)


func start_spawning() -> void:
	if _paused:
		return
	if walk_in_timer.is_stopped():
		_start_next_walk_in_timer()
	if group_event_timer.is_stopped():
		_start_next_group_event_timer()


## Stops new visits, forced ones too, while a raid squad walks through. Customers
## already at the counter finish; resume_spawning() rolls fresh intervals.
func pause_spawning() -> void:
	_paused = true
	walk_in_timer.stop()
	group_event_timer.stop()


func resume_spawning() -> void:
	_paused = false
	start_spawning()


## No empty-inventory check on purpose: the first-brew gate lives in CustomerManager.
## Later, running out of stock means customers are turned away, costing reputation and
## risk.
func spawn_walk_in(forced_data: CustomerData = null) -> void:
	if _paused:
		return
	_try_spawn_walk_in(forced_data)
	_start_next_walk_in_timer()
	# A forced walk-in (a recommended friend, a console command) comes alone.
	if forced_data == null:
		_spawn_company()


## Now and then a walk-in brings company, see WalkInRules. Each companion is its own
## random customer and needs its own free counter spot.
func _spawn_company() -> void:
	var brewery: Brewery = BrewEngine.current_brewery
	if brewery == null:
		return
	var chance: float = WalkInRules.company_chance(brewery.stats.chance(PerkStats.WALK_IN_COMPANY_CHANCE))
	var count: int = WalkInRules.customer_count(randf(), chance, int(brewery.stats.total(PerkStats.WALK_IN_COMPANY_BONUS)))
	var delay: float = 0.0
	for i: int in count - 1:
		delay += randf_range(WalkInRules.COMPANY_GAP_SECONDS.x, WalkInRules.COMPANY_GAP_SECONDS.y)
		_schedule_walk_in(null, delay)


## Sends a walk-in (`data`, or a random one when null) in after `seconds`. The timer
## pauses with the tree, so no one walks in behind a level-up window; a raid cancels it.
func _schedule_walk_in(data: CustomerData, seconds: float) -> void:
	var brewery: Brewery = BrewEngine.current_brewery
	var entry: Dictionary = {"data": data, "timer": get_tree().create_timer(seconds, false)}
	_scheduled.append(entry)
	await entry.timer.timeout
	_scheduled.erase(entry)
	if not _paused and BrewEngine.current_brewery == brewery:
		_try_spawn_walk_in(data)


## A crowd shares one counter slot and spawns staggered so it floods in. Like a
## walk-in there is no stock check: a group that finds nothing leaves empty-handed.
func spawn_group_visit(forced_event_data: GroupVisitEventData = null) -> void:
	if _paused:
		return
	_try_spawn_group_visit(forced_event_data)
	_start_next_group_event_timer()


## The friend comes on its own clock, so the regular walk-in timer is untouched.
func _on_friend_recommended(data: CustomerData) -> void:
	_schedule_walk_in(data, randf_range(WordOfMouthRules.FRIEND_DELAY_MIN_SECONDS, WordOfMouthRules.FRIEND_DELAY_MAX_SECONDS))


## Walks in alone and leaves the walk-in timer alone. With the counter full or the doors
## shut he tries again on the next rise in risk.
func _on_lvv_inspector_visit_due(brewery: Brewery) -> void:
	if not _paused and _try_spawn_walk_in(LVV_INSPECTOR):
		brewery.lvv_inspector_visited = true


func _on_bad_review_spread() -> void:
	if not walk_in_timer.is_stopped():
		walk_in_timer.start(walk_in_timer.time_left + WordOfMouthRules.BAD_REVIEW_DELAY_SECONDS)


## Everyone in the cellar goes into the save, frozen mid-visit; group members go in with
## their group.
func _record_cellar_customers(brewery: Brewery) -> void:
	brewery.cellar_customers.clear()
	for node: Node in get_children():
		var customer := node as Customer
		if customer != null and not customer.is_queued_for_deletion() and not customer.is_group_member():
			brewery.cellar_customers.append(customer.snapshot())
	brewery.cellar_groups = _group_visit.snapshots()
	brewery.scheduled_walk_ins.clear()
	for entry: Dictionary in _scheduled:
		brewery.scheduled_walk_ins.append({"data": entry.data, "seconds": entry.timer.time_left})
	brewery.walk_in_time_left = -1.0 if walk_in_timer.is_stopped() else walk_in_timer.time_left
	brewery.group_visit_time_left = -1.0 if group_event_timer.is_stopped() else group_event_timer.time_left


## After a load, puts the saved customers and crowds back and lets each carry on its
## visit. A solo customer already walking out holds no counter spot.
func _resume_cellar_customers() -> void:
	var brewery: Brewery = BrewEngine.current_brewery
	if brewery == null:
		return
	var taken: Dictionary = {}
	for snap: CustomerSnapshot in brewery.cellar_customers:
		var slot: int = -1
		if snap.phase != CustomerSnapshot.Phase.LEAVING:
			slot = _resume_slot(snap.slot, taken)
			if slot == -1:
				continue
			if snap.route.size() == 4:
				snap.route[3] = counter_positions[slot]
		var customer: Customer = CUSTOMER_SCENE.instantiate()
		add_child(customer)
		customer.customer_data = snap.data
		customer.generated_name = snap.generated_name
		customer.assigned_slot = slot
		customer.dialogue_slot = slot
		if slot != -1:
			CustomerManager.register_active_customer(slot, customer)
		customer.resume(snap)
	brewery.cellar_customers.clear()

	for group_snap: GroupVisitSnapshot in brewery.cellar_groups:
		var slot: int = _resume_slot(group_snap.slot, taken)
		if slot != -1:
			_group_visit.resume(group_snap, slot, counter_positions[slot])
	brewery.cellar_groups.clear()

	for entry: Dictionary in brewery.scheduled_walk_ins:
		_schedule_walk_in(entry.get("data"), entry.get("seconds", 0.0))
	brewery.scheduled_walk_ins.clear()
	_resume_timer(walk_in_timer, brewery.walk_in_time_left)
	_resume_timer(group_event_timer, brewery.group_visit_time_left)


## A raid already under way (LvvRaidSpawner) keeps the timers stopped.
func _resume_timer(timer: Timer, seconds_left: float) -> void:
	if seconds_left > 0.0 and not _paused:
		timer.start(seconds_left)


## The saved counter slot if it is still there and free, else any free one (or -1).
func _resume_slot(saved_slot: int, taken: Dictionary) -> int:
	var slot: int = saved_slot if saved_slot >= 0 and saved_slot < counter_positions.size() and not taken.has(saved_slot) else _free_slot()
	if slot != -1:
		taken[slot] = true
	return slot


## Whether someone walked in.
func _try_spawn_walk_in(forced_data: CustomerData) -> bool:
	var free_slot: int = _free_slot()
	if free_slot == -1:
		return false
	var data: CustomerData = forced_data if forced_data != null else CustomerManager.get_random_customer_data()
	if data == null:
		return false
	if data.randomizes_preference:
		data = data.duplicate()
		data.reroll_preference(_active_styles())

	var new_customer: Customer = CUSTOMER_SCENE.instantiate()
	add_child(new_customer)
	new_customer.generated_name = data.generate_display_name()
	new_customer.global_position = global_position
	new_customer.customer_data = data
	new_customer.assigned_slot = free_slot
	new_customer.dialogue_slot = free_slot
	CustomerManager.register_active_customer(free_slot, new_customer)
	new_customer.walk_complex_route(stairs_bottom_marker.global_position, room_center_marker.global_position, counter_positions[free_slot])
	return true


func _try_spawn_group_visit(forced_event_data: GroupVisitEventData) -> void:
	var free_slot: int = _free_slot()
	if free_slot == -1:
		return
	var event_data: GroupVisitEventData = forced_event_data if forced_event_data != null else _pick_group_event()
	if event_data == null or event_data.customer_data_options.is_empty():
		return
	if forced_event_data == null and CustomerRegistry.keeps_group_away(event_data):
		return
	BrewerySignals.group_visit_announced.emit(event_data.banner_text)
	_group_visit.run(event_data, free_slot, counter_positions[free_slot])


## A free counter slot that has a spot, or -1 (also when no run is active).
func _free_slot() -> int:
	if BrewEngine.current_brewery == null or counter_positions.is_empty():
		return -1
	var free_slot: int = CustomerManager.get_free_slot_index()
	return free_slot if free_slot < counter_positions.size() else -1


func _start_next_walk_in_timer() -> void:
	var bounds := SpawnPacing.walk_in_bounds(_reputation(), _perk_multiplier(PerkStats.SPAWN_INTERVAL))
	walk_in_timer.start(randf_range(bounds.x, bounds.y))


func _start_next_group_event_timer() -> void:
	var bounds := SpawnPacing.group_bounds(_reputation(), _perk_multiplier(PerkStats.SPAWN_INTERVAL), _perk_multiplier(PerkStats.GROUP_EVENT_INTERVAL))
	group_event_timer.start(randf_range(bounds.x, bounds.y))


func _reputation() -> float:
	var brewery: Brewery = BrewEngine.current_brewery
	return 0.0 if brewery == null else float(brewery.reputation)


func _perk_multiplier(stat: StringName) -> float:
	var brewery: Brewery = BrewEngine.current_brewery
	return 1.0 if brewery == null else brewery.stats.multiplier(stat)


## The current run's beer styles, for customers that roll a random preference.
## Empty when no run is active, which makes reroll_preference() a no-op.
func _active_styles() -> Array[BeerStyle]:
	var brewery: Brewery = BrewEngine.current_brewery
	if brewery == null:
		return []
	return brewery.resolver.active_styles


## During a day event, leans toward that event's featured group visit at its own
## chance.
func _pick_group_event() -> GroupVisitEventData:
	var day_event: DayEventData = DayEventManager.get_active_event()
	if day_event != null and day_event.featured_group_event != null and randf() < day_event.featured_group_event_chance:
		return day_event.featured_group_event
	return CustomerRegistry.get_random_group_event()
