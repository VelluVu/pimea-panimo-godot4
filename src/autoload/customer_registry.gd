#CustomerRegistry (Autoload)
extends Node


const WARNING_FOLDER_OPEN_FAILED = "CustomerRegistry: Failed to open path: "
const WARNING_POOL_EMPTY = "CustomerRegistry: Customer pool is empty!"
const WARNING_EVENTS_EMPTY = "CustomerRegistry: Special events pool is empty!"

@export var customer_folder_path: String = "res://src/resources/customers/"
@export var special_event_folder_path: String = "res://src/resources/special_events/"

var customer_pool: Array[CustomerData] = []
var special_events_pool: Array[SpecialEventData] = []


func _ready() -> void:
	_load_resources()


func get_random_customer_data() -> CustomerData:
	if customer_pool.is_empty():
		return null

	var current_reputation : int = 0
	if BrewEngine.current_brewery != null:
		current_reputation = BrewEngine.current_brewery.reputation

	var eligible_customers : Array[CustomerData] = []
	for customer in customer_pool:
		if current_reputation >= customer.min_reputation_to_appear:
			eligible_customers.append(customer)

	if eligible_customers.is_empty():
		eligible_customers = customer_pool

	return eligible_customers.pick_random()


func get_random_special_event() -> SpecialEventData:
	if special_events_pool.is_empty(): 
		return null
	return special_events_pool.pick_random()


func _load_resources() -> void:
	var dir_cust = DirAccess.open(customer_folder_path)
	if dir_cust:
		dir_cust.list_dir_begin()
		var file_name = dir_cust.get_next()
		while file_name != "":
			if not dir_cust.current_is_dir() and file_name.ends_with(".tres"):
				var res = load(customer_folder_path + file_name)
				if res is CustomerData:
					customer_pool.append(res)
			file_name = dir_cust.get_next()
		dir_cust.list_dir_end()
	else:
		push_warning(WARNING_FOLDER_OPEN_FAILED + customer_folder_path)
		
	var dir_ev = DirAccess.open(special_event_folder_path)
	if dir_ev:
		dir_ev.list_dir_begin()
		var file_name = dir_ev.get_next()
		while file_name != "":
			if not dir_ev.current_is_dir() and file_name.ends_with(".tres"):
				var res = load(special_event_folder_path + file_name)
				if res is SpecialEventData:
					special_events_pool.append(res)
			file_name = dir_ev.get_next()
		dir_ev.list_dir_end()
	else:
		push_warning(WARNING_FOLDER_OPEN_FAILED + special_event_folder_path)
		
	if customer_pool.is_empty():
		push_warning(WARNING_POOL_EMPTY)
	if special_events_pool.is_empty():
		push_warning(WARNING_EVENTS_EMPTY)
