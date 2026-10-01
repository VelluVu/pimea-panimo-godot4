class_name CustomerSpawner
extends Node2D

## Schedules walk-ins and group visits on two timers and sends each new customer to a
## free counter slot. The sales themselves happen in CustomerManager.

const CUSTOMER_SCENE: PackedScene = preload("res://src/scenes/customer.tscn")

@onready var counter_positions_parent: Node2D = $CounterPositionsParent
@onready var stairs_bottom_marker: Marker2D = $StairsBottomMarker
@onready var room_center_marker: Marker2D = $RoomCenterMarker

var walk_in_timer: Timer
var group_event_timer: Timer
var counter_markers: Array[Node2D] = []
var _group_visit: GroupVisitDirector
## Set during a raid. Brewery state changes call start_spawning() all the time, so the
## timers alone cannot hold a pause.
var _paused: bool = false


func _ready() -> void:
	walk_in_timer = _make_timer(spawn_walk_in)
	group_event_timer = _make_timer(spawn_group_visit)
	_setup_positions()
	_group_visit = GroupVisitDirector.new(self, stairs_bottom_marker, room_center_marker, _active_styles)
	CustomerManager.register_spawner(self)
	BrewerySignals.friend_recommended.connect(_on_friend_recommended)
	BrewerySignals.bad_review_spread.connect(_on_bad_review_spread)


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


## A crowd shares one counter slot and spawns staggered so it floods in. Like a
## walk-in there is no stock check: a group that finds nothing leaves empty-handed.
func spawn_group_visit(forced_event_data: GroupVisitEventData = null) -> void:
	if _paused:
		return
	_try_spawn_group_visit(forced_event_data)
	_start_next_group_event_timer()


## The friend comes on its own clock, so the regular walk-in timer is untouched. The
## timer pauses with the tree, so no friend walks in behind a level-up window.
func _on_friend_recommended(data: CustomerData) -> void:
	var delay: float = randf_range(WordOfMouthRules.FRIEND_DELAY_MIN_SECONDS, WordOfMouthRules.FRIEND_DELAY_MAX_SECONDS)
	await get_tree().create_timer(delay, false).timeout
	if not _paused:
		_try_spawn_walk_in(data)


func _on_bad_review_spread() -> void:
	if not walk_in_timer.is_stopped():
		walk_in_timer.start(walk_in_timer.time_left + WordOfMouthRules.BAD_REVIEW_DELAY_SECONDS)


func _try_spawn_walk_in(forced_data: CustomerData) -> void:
	var free_slot: int = _free_slot()
	if free_slot == -1:
		return
	var data: CustomerData = forced_data if forced_data != null else CustomerManager.get_random_customer_data()
	if data == null:
		return
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
	new_customer.walk_complex_route(stairs_bottom_marker.global_position, room_center_marker.global_position, counter_markers[free_slot].global_position)


func _try_spawn_group_visit(forced_event_data: GroupVisitEventData) -> void:
	var free_slot: int = _free_slot()
	if free_slot == -1:
		return
	var event_data: GroupVisitEventData = forced_event_data if forced_event_data != null else _pick_group_event()
	if event_data == null or event_data.customer_data_options.is_empty():
		return
	BrewerySignals.group_visit_announced.emit(event_data.banner_text)
	_group_visit.run(event_data, free_slot, counter_markers[free_slot].global_position)


## A free counter slot that has a marker, or -1 (also when no run is active).
func _free_slot() -> int:
	if BrewEngine.current_brewery == null or counter_markers.is_empty():
		return -1
	var free_slot: int = CustomerManager.get_free_slot_index()
	return free_slot if free_slot < counter_markers.size() else -1


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
