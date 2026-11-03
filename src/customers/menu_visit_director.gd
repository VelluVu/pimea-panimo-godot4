class_name MenuVisitDirector
extends Node

## A rare late guest in the closed cellar of the main menu: once in a while one customer
## walks down the stairs, gets a pint from the bartender and walks out with it, without
## speech bubbles over the menu. Rare, so the menu stays calm. Nothing is sold or saved.

const CUSTOMER_SCENE : PackedScene = preload("res://src/scenes/customer.tscn")
const FIRST_VISIT_SECONDS : float = 15.0
const MIN_GAP_SECONDS : float = 40.0
const MAX_GAP_SECONDS : float = 80.0
const ARRIVAL_POLL_SECONDS : float = 0.2
## At the counter before the pour, and with the pint before leaving.
const ORDER_SECONDS : float = 1.5
const PINT_SECONDS : float = 1.2

## Customers are added here: the top of the stairs, inside the cellar's Y sort.
@export var entrance : Node2D
@export var stairs_bottom : Marker2D
@export var room_center : Marker2D
@export var counter_spot : Marker2D
@export var bartender : Bartender


func _ready() -> void:
	_run_visits()


func _run_visits() -> void:
	await _wait(FIRST_VISIT_SECONDS)
	while is_inside_tree():
		await _visit()
		await _wait(randf_range(MIN_GAP_SECONDS, MAX_GAP_SECONDS))


func _visit() -> void:
	var data : CustomerData = _pick_customer()
	if data == null:
		return
	var customer : Customer = CUSTOMER_SCENE.instantiate()
	entrance.add_child(customer)
	customer.global_position = entrance.global_position
	customer.customer_data = data
	customer.walk_complex_route(stairs_bottom.global_position, room_center.global_position, counter_spot.global_position, true)
	BrewerySignals.customer_entered.emit(entrance.global_position)
	while is_instance_valid(customer) and customer.is_walking_in():
		await _wait(ARRIVAL_POLL_SECONDS)
	if not is_instance_valid(customer):
		return

	await _wait(ORDER_SECONDS)
	if not is_instance_valid(customer):
		return
	await _wait(bartender.play_serve_beer(Bartender.SOLO_POUR_SPEED_SCALE))
	if not is_instance_valid(customer):
		return
	customer.made_purchase = true
	await _wait(PINT_SECONDS)
	if is_instance_valid(customer):
		customer.leave_counter()


func _pick_customer() -> CustomerData:
	var season : SeasonRules.Season = SeasonRules.now()
	var met : Array = CustomerRegistry.get_met_titles()
	var candidates : Array[CustomerData] = MenuVisitorRules.candidates(CustomerRegistry.customer_pool, met, CustomerRegistry.is_eligible, season)
	var weights : Array[float] = []
	for customer : CustomerData in candidates:
		weights.append(MenuVisitorRules.weight(customer, season, met.has(customer.title)))
	return WeightedPicker.pick(candidates, weights) as CustomerData


## A child Timer, not a SceneTreeTimer: when Start leaves the menu it goes with this node,
## so no visit wakes up in a freed scene.
func _wait(seconds : float) -> void:
	var timer := Timer.new()
	timer.one_shot = true
	add_child(timer)
	timer.start(seconds)
	await timer.timeout
	timer.queue_free()
