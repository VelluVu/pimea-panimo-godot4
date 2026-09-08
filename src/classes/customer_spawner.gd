class_name CustomerSpawner
extends Node2D


const WALK_IN_INTERVAL_MIN_SECONDS = 30.0
const WALK_IN_INTERVAL_MAX_SECONDS = 90.0
const WALK_IN_INTERVAL_FLOOR_SECONDS = 10.0
const REPUTATION_SPAWN_SOFT_CAP = 100.0

const CUSTOMER_SCENE = preload("res://scenes/customer.tscn")

@onready var counter_positions_parent: Node2D = $CounterPositionsParent
@onready var stairs_bottom_marker: Marker2D = $StairsBottomMarker
@onready var room_center_marker: Marker2D = $RoomCenterMarker

var walk_in_timer: Timer
var counter_markers: Array[Node2D] = []


func _ready() -> void:
	CustomerManager.register_spawner(self)
	_setup_timer()
	_setup_positions()


func _setup_timer() -> void:
	walk_in_timer = Timer.new()
	walk_in_timer.process_callback = Timer.TIMER_PROCESS_IDLE
	walk_in_timer.one_shot = true
	walk_in_timer.timeout.connect(_on_walk_in_timer_timeout)
	add_child(walk_in_timer)


func _setup_positions() -> void:
	if counter_positions_parent:
		for child in counter_positions_parent.get_children():
			if child is Node2D:
				counter_markers.append(child)


func start_spawning() -> void:
	if walk_in_timer.is_stopped():
		_start_next_walk_in_timer()


func _start_next_walk_in_timer() -> void:
	var factor := _get_reputation_spawn_factor()
	var min_time := maxf(WALK_IN_INTERVAL_FLOOR_SECONDS, WALK_IN_INTERVAL_MIN_SECONDS * factor)
	var max_time := maxf(min_time, WALK_IN_INTERVAL_MAX_SECONDS * factor)
	var next_time = randf_range(min_time, max_time)
	walk_in_timer.start(next_time)


func _get_reputation_spawn_factor() -> float:
	var brewery = BrewEngine.current_brewery
	if brewery == null:
		return 1.0
	return REPUTATION_SPAWN_SOFT_CAP / (REPUTATION_SPAWN_SOFT_CAP + brewery.reputation)


func _on_walk_in_timer_timeout(forced_data: CustomerData = null) -> void:
	if BrewEngine.current_brewery == null or counter_markers.is_empty():
		_start_next_walk_in_timer()
		return

	var brewery = BrewEngine.current_brewery
	if brewery.inventory.brew_batches.is_empty():
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

	var filename = data.resource_path.get_file()

	if data.randomizes_preference:
		data = data.duplicate()
		data.reroll_preference()

	var new_customer = CUSTOMER_SCENE.instantiate()
	add_child(new_customer)
	new_customer.generated_name = CustomerRegistry.generate_random_name(filename)
	new_customer.global_position = global_position
	new_customer.customer_data = data
	new_customer.assigned_slot = free_slot
	
	CustomerManager.register_active_customer(free_slot, new_customer)
	
	var marker = counter_markers[free_slot]
	new_customer.walk_complex_route(stairs_bottom_marker.global_position, room_center_marker.global_position, marker.global_position)
	
	_start_next_walk_in_timer()
