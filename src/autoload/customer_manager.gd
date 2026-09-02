#CustomerManager (Autoload)
extends Node


const KEY_INCOME = "income"
const KEY_REPUTATION = "reputation"
const KEY_RISK = "risk"
const KEY_RESPONSE = "response"

const BOTTLES_SOLD_PER_TRANSACTION = 1
const QUALITY_BONUS_WEIGHT = 0.2

const DELAY_AUTO_SALE_SECONDS = 2.0
const DELAY_CLEAR_REFS_SECONDS = 3.5

const WARNING_TIME_MANAGER_NOT_FOUND = "CustomerManager: TimeManager Autoload not found!"
const WARNING_DIALOG_VIEW_NOT_FOUND = "CustomerManager: DialogView not found for positioning!"

var occupied_slots: Array[bool] = [false, false, false, false, false]
var active_customers: Dictionary = {}
var active_spawner: CustomerSpawner = null


func _ready() -> void:

	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)


func register_spawner(spawner: CustomerSpawner) -> void:
	active_spawner = spawner
	if BrewEngine.current_brewery and not BrewEngine.current_brewery.inventory.brew_batches.is_empty():
		active_spawner.start_spawning()


func get_free_slot_index() -> int:
	for i in range(occupied_slots.size()):
		if not occupied_slots[i]:
			return i
	return -1


func get_random_customer_data() -> CustomerData:
	return CustomerRegistry.get_random_customer_data()


func register_active_customer(slot: int, node: Node2D) -> void:
	occupied_slots[slot] = true
	active_customers[slot] = node


func free_slot_index(slot: int) -> void:
	if active_customers.has(slot):
		active_customers.erase(slot)
	occupied_slots[slot] = false


func _on_brewery_state_changed(brewery: Brewery) -> void:
	if active_spawner and not brewery.inventory.brew_batches.is_empty():
		active_spawner.start_spawning()
	

func process_auto_sale(data: CustomerData) -> String:
	if BrewEngine.current_brewery == null: 
		return ""
		
	var brewery = BrewEngine.current_brewery
	var best_batch = _find_best_batch(brewery.inventory.brew_batches, data)
	if best_batch == null:
		best_batch = brewery.inventory.brew_batches
		
	if best_batch == null or best_batch.amount_bottles < BOTTLES_SOLD_PER_TRANSACTION:
		return ""
		
	var results: Dictionary
	if data.has_method("evaluate_brew_batch"):
		results = data.evaluate_brew_batch(best_batch)
	else:
		results = data.call("evaluate_brew_batch", best_batch)
		
	brewery.money += results[KEY_INCOME]
	brewery.reputation = max(0, brewery.reputation + results[KEY_REPUTATION])
	brewery.risk += results[KEY_RISK]
	
	best_batch.amount_bottles -= BOTTLES_SOLD_PER_TRANSACTION
	if best_batch.amount_bottles <= 0:
		brewery.inventory.brew_batches.erase(best_batch)
		
	BrewerySignals.brewery_state_changed.emit(brewery)
	return results[KEY_RESPONSE]


func _find_best_batch(batches: Array[BrewBatch], data: CustomerData) -> BrewBatch:
	var best_batch: BrewBatch = null
	var best_score: float = -1.0
	
	for batch in batches:
		if batch.amount_bottles <= 0: continue
		var score = data.get_preference_score(batch.beer_style.style)
		if batch.current_quality >= data.min_quality:
			score += QUALITY_BONUS_WEIGHT
		if score > best_score:
			best_score = score
			best_batch = batch
	return best_batch


func spawn_normal_customer() -> void:
	active_spawner._on_walk_in_timer_timeout()