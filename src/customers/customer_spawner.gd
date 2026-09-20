class_name CustomerSpawner
extends Node2D


const WALK_IN_INTERVAL_MIN_SECONDS = 30.0
const WALK_IN_INTERVAL_MAX_SECONDS = 90.0
const WALK_IN_INTERVAL_FLOOR_SECONDS = 10.0
const REPUTATION_SPAWN_SOFT_CAP = 100.0

## Group visits are rarer than walk-ins and scale with reputation the same way,
## kept above GROUP_EVENT_FLOOR_SECONDS.
const GROUP_EVENT_INTERVAL_MIN_SECONDS = 150.0
const GROUP_EVENT_INTERVAL_MAX_SECONDS = 300.0
const GROUP_EVENT_FLOOR_SECONDS = 120.0


const CUSTOMER_SCENE = preload("res://scenes/customer.tscn")

@onready var counter_positions_parent: Node2D = $CounterPositionsParent
@onready var stairs_bottom_marker: Marker2D = $StairsBottomMarker
@onready var room_center_marker: Marker2D = $RoomCenterMarker

var walk_in_timer: Timer
var group_event_timer: Timer
var counter_markers: Array[Node2D] = []
var _group_visit : GroupVisitDirector


func _ready() -> void:
	_setup_timer()
	_setup_group_timer()
	_setup_positions()
	_group_visit = GroupVisitDirector.new(self, stairs_bottom_marker, room_center_marker, _active_styles)
	CustomerManager.register_spawner(self)


func _setup_timer() -> void:
	walk_in_timer = Timer.new()
	walk_in_timer.process_callback = Timer.TIMER_PROCESS_IDLE
	walk_in_timer.one_shot = true
	walk_in_timer.timeout.connect(_on_walk_in_timer_timeout)
	add_child(walk_in_timer)


func _setup_group_timer() -> void:
	group_event_timer = Timer.new()
	group_event_timer.process_callback = Timer.TIMER_PROCESS_IDLE
	group_event_timer.one_shot = true
	group_event_timer.timeout.connect(_on_group_event_timer_timeout)
	add_child(group_event_timer)


func _setup_positions() -> void:
	if counter_positions_parent:
		for child in counter_positions_parent.get_children():
			if child is Node2D:
				counter_markers.append(child)


func start_spawning() -> void:
	if walk_in_timer.is_stopped():
		_start_next_walk_in_timer()
	if group_event_timer.is_stopped():
		_start_next_group_event_timer()


## Stops scheduling new visits (used while a raid squad walks through). Customers
## already at the counter finish; start_spawning() rolls fresh intervals.
func pause_spawning() -> void:
	walk_in_timer.stop()
	group_event_timer.stop()


## The (min, max) wait for the next spawn: the base range scaled by `factor`,
## never below `floor_seconds`.
static func interval_bounds(base_min : float, base_max : float, floor_seconds : float, factor : float) -> Vector2:
	var min_time := maxf(floor_seconds, base_min * factor)
	return Vector2(min_time, maxf(min_time, base_max * factor))


func _start_next_walk_in_timer() -> void:
	var factor := _get_reputation_spawn_factor() * _get_perk_spawn_interval_multiplier()
	var bounds := interval_bounds(WALK_IN_INTERVAL_MIN_SECONDS, WALK_IN_INTERVAL_MAX_SECONDS, WALK_IN_INTERVAL_FLOOR_SECONDS, factor)
	walk_in_timer.start(randf_range(bounds.x, bounds.y))


func _start_next_group_event_timer() -> void:
	var factor := _get_reputation_spawn_factor() * _get_perk_spawn_interval_multiplier() * _get_perk_group_event_interval_multiplier()
	var bounds := interval_bounds(GROUP_EVENT_INTERVAL_MIN_SECONDS, GROUP_EVENT_INTERVAL_MAX_SECONDS, GROUP_EVENT_FLOOR_SECONDS, factor)
	group_event_timer.start(randf_range(bounds.x, bounds.y))



func _get_reputation_spawn_factor() -> float:
	var brewery = BrewEngine.current_brewery
	if brewery == null:
		return 1.0
	return REPUTATION_SPAWN_SOFT_CAP / (REPUTATION_SPAWN_SOFT_CAP + brewery.reputation)


## The current run's beer styles, for customers that roll a random preference.
## Empty when no run is active, which makes reroll_preference() a no-op.
func _active_styles() -> Array[BeerStyle]:
	var brewery : Brewery = BrewEngine.current_brewery
	if brewery == null:
		return []
	return brewery.resolver.active_styles


## Perk multiplier on both walk-in and group waits, still clamped by the floors.
func _get_perk_spawn_interval_multiplier() -> float:
	var brewery = BrewEngine.current_brewery
	if brewery == null:
		return 1.0
	return brewery.stats.multiplier(PerkStats.SPAWN_INTERVAL)


## Perk multiplier on group waits only.
func _get_perk_group_event_interval_multiplier() -> float:
	var brewery = BrewEngine.current_brewery
	if brewery == null:
		return 1.0
	return brewery.stats.multiplier(PerkStats.GROUP_EVENT_INTERVAL)


## No empty-inventory check on purpose: the first-brew gate lives in CustomerManager.
## Later, running out of stock means customers are turned away, costing reputation and
## risk.
func _on_walk_in_timer_timeout(forced_data: CustomerData = null) -> void:
	if BrewEngine.current_brewery == null or counter_markers.is_empty():
		_start_next_walk_in_timer()
		return

	var free_slot = CustomerManager.get_free_slot_index()
	if free_slot == -1 or free_slot >= counter_markers.size():
		_start_next_walk_in_timer()
		return

	var data = forced_data if forced_data != null else CustomerManager.get_random_customer_data()
	if data == null:
		_start_next_walk_in_timer()
		return

	if data.randomizes_preference:
		data = data.duplicate()
		data.reroll_preference(_active_styles())

	var new_customer = CUSTOMER_SCENE.instantiate()
	add_child(new_customer)
	new_customer.generated_name = data.generate_display_name()
	new_customer.global_position = global_position
	new_customer.customer_data = data
	new_customer.assigned_slot = free_slot
	new_customer.dialogue_slot = free_slot

	CustomerManager.register_active_customer(free_slot, new_customer)
	
	var marker = counter_markers[free_slot]
	new_customer.walk_complex_route(stairs_bottom_marker.global_position, room_center_marker.global_position, marker.global_position)

	_start_next_walk_in_timer()


## A crowd shares one counter slot and spawns staggered so it floods in. Like a
## walk-in there is no stock check: a group that finds nothing leaves empty-handed.
func _on_group_event_timer_timeout(forced_event_data: GroupVisitEventData = null) -> void:
	if BrewEngine.current_brewery == null or counter_markers.is_empty():
		_start_next_group_event_timer()
		return

	var free_slot = CustomerManager.get_free_slot_index()
	if free_slot == -1 or free_slot >= counter_markers.size():
		_start_next_group_event_timer()
		return

	var event_data = forced_event_data if forced_event_data != null else _pick_group_event()
	if event_data == null or event_data.customer_data_options.is_empty():
		_start_next_group_event_timer()
		return

	BrewerySignals.group_visit_announced.emit(event_data.banner_text)
	_group_visit.run(event_data, free_slot, counter_markers[free_slot].global_position)

	_start_next_group_event_timer()


## During a day event, leans toward that event's featured group visit at its own
## chance.
func _pick_group_event() -> GroupVisitEventData:
	var day_event : DayEventData = DayEventManager.get_active_event()
	if day_event != null and day_event.featured_group_event != null and randf() < day_event.featured_group_event_chance:
		return day_event.featured_group_event
	return CustomerRegistry.get_random_group_event()
