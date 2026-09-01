#CustomerManager (Autoload)
extends Node


signal customer_arrived(customer: CustomerData, is_special_request: bool, slot_index: int)
signal dialogue_pushed(text: String, is_special: bool, slot_index: int)
signal special_request_resolved(success: bool)


const DIALOGUE_WRONG_STYLE = "Ei tää sitäkään ollu, mut menköön..."
const DIALOGUE_MC_INTRO = "⚠️ TUKKUPYYNTÖ: Paikallinen moottoripyöräkerho tarvitsee 20 pulloa IPAa heti. Maksavat tuplahinnan käteisenä!"
const DIALOGUE_MC_SUCCESS = "Jengi kiittää. Rahat on pussissa takahuoneessa."
const DIALOGUE_MC_FAIL = "Sinulla ei ole tarpeeksi (20kpl) IPAa kellarissa!"
const DIALOGUE_INSPECTOR_INTRO = "⚠️ SOPIMUS: Voitelurahapyyntö. Anna tarkastajalle 10 pulloa parasta Bulkkilageria ilmaiseksi, niin AVI-riskisi nollataan."
const DIALOGUE_INSPECTOR_SUCCESS = "Tarkastaja hymyilee ja pyyhkii nimesi kansioista. AVI-riski puhtaana."
const DIALOGUE_INSPECTOR_FAIL = "Sinulla ei ole antaa 10 pulloa Bulkkilageria!"
const DIALOGUE_SPECIAL_REJECT = "Päätit olla tarttumatta tarjoukseen. Jatketaan pimeää bisnestä."

const SPECIAL_EVENT_INTERVAL_SECONDS = 300.0
const SPECIAL_EVENT_TIMEOUT_SECONDS = 10.0
const WALK_IN_INTERVAL_MIN_SECONDS = 30.0
const WALK_IN_INTERVAL_MAX_SECONDS = 90.0

const PATH_TIME_MANAGER = "/root/TimeManager"
const WARNING_TIME_MANAGER_NOT_FOUND = "CustomerManager: TimeManager Autoload not found!"
const WARNING_FOLDER_OPEN_FAILED = "CustomerManager: Failed to open customer folder path: "
const WARNING_POOL_EMPTY = "CustomerManager: Customer pool is empty! Ensure .tres files exist in the target directory."
const WARNING_SPECIAL_INVALID_STATE = "CustomerManager: Cannot accept special request, invalid state!"

@export var customer_folder_path: String = "res://src/resources/customers/"

var customer_pool: Array[CustomerData] = []
var is_handling_special: bool = false
var active_special_batch_type: BeerStyle.Style
var special_event_timer: Timer
var special_timeout_timer: Timer
var walk_in_timer: Timer
var occupied_slots: Array[bool] = [false, false, false, false, false]


func _ready() -> void:
	_load_customer_resources()
	_setup_timers()
	
	if has_node(PATH_TIME_MANAGER):
		get_node(PATH_TIME_MANAGER).day_changed.connect(_on_day_changed)
	else:
		push_warning(WARNING_TIME_MANAGER_NOT_FOUND)
	
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)


func _setup_timers() -> void:
	special_event_timer = Timer.new()
	special_event_timer.process_callback = Timer.TIMER_PROCESS_IDLE
	special_event_timer.wait_time = SPECIAL_EVENT_INTERVAL_SECONDS
	special_event_timer.autostart = true
	special_event_timer.one_shot = false
	special_event_timer.timeout.connect(_on_special_event_timer_timeout)
	add_child(special_event_timer)
	
	special_timeout_timer = Timer.new()
	special_timeout_timer.process_callback = Timer.TIMER_PROCESS_IDLE
	special_timeout_timer.wait_time = SPECIAL_EVENT_TIMEOUT_SECONDS
	special_timeout_timer.one_shot = true
	special_timeout_timer.timeout.connect(_on_special_timeout)
	add_child(special_timeout_timer)
	
	walk_in_timer = Timer.new()
	walk_in_timer.process_callback = Timer.TIMER_PROCESS_IDLE
	walk_in_timer.one_shot = true
	walk_in_timer.timeout.connect(_on_walk_in_timer_timeout)
	add_child(walk_in_timer)


func _load_customer_resources() -> void:
	var dir = DirAccess.open(customer_folder_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(StringContainer.RESOURCE_END):
				var res = load(customer_folder_path + file_name)
				if res is CustomerData:
					customer_pool.append(res)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		push_warning(WARNING_FOLDER_OPEN_FAILED + customer_folder_path)
	
	if customer_pool.is_empty():
		push_warning(WARNING_POOL_EMPTY)


func _on_brewery_state_changed(brewery: Brewery) -> void:
	if not brewery.inventory.brew_batches.is_empty() and walk_in_timer.is_stopped():
		_start_next_walk_in_timer()


func _on_day_changed() -> void:
	pass


func _on_special_event_timer_timeout() -> void:
	_trigger_special_request()


func _on_special_timeout() -> void:
	reject_special_request()


func _on_walk_in_timer_timeout() -> void:
	if BrewEngine.current_brewery == null:
		return
		
	var brewery = BrewEngine.current_brewery
	if brewery.inventory.brew_batches.is_empty():
		return
		
	_handle_standard_walk_in(brewery)


func _start_next_walk_in_timer() -> void:
	var next_time = randf_range(WALK_IN_INTERVAL_MIN_SECONDS, WALK_IN_INTERVAL_MAX_SECONDS)
	walk_in_timer.start(next_time)


func _handle_standard_walk_in(brewery: Brewery) -> void:
	if customer_pool.is_empty(): 
		_start_next_walk_in_timer()
		return
		
	var free_slots: Array[int] = []
	for i in range(occupied_slots.size()):
		if not occupied_slots[i]:
			free_slots.append(i)
			
	if free_slots.is_empty():
		_start_next_walk_in_timer()
		return
		
	var chosen_slot = free_slots.pick_random()
	occupied_slots[chosen_slot] = true
	
	var customer = customer_pool.pick_random()
	customer_arrived.emit(customer, false, chosen_slot)
	dialogue_pushed.emit(customer.dialogue_intro, false, chosen_slot)
	
	var best_batch = _find_best_batch(brewery.inventory.brew_batches, customer)
	if best_batch == null:
		best_batch = brewery.inventory.brew_batches
		
	var bottles_to_buy = 1
	bottles_to_buy = min(bottles_to_buy, best_batch.amount_bottles)
	
	_start_next_walk_in_timer()
	
	await get_tree().create_timer(2.0).timeout
	
	if is_instance_valid(brewery) and is_instance_valid(best_batch) and best_batch.amount_bottles >= bottles_to_buy:
		_execute_auto_sale(brewery, best_batch, bottles_to_buy, customer, chosen_slot)


func _find_best_batch(batches: Array[BrewBatch], customer: CustomerData) -> BrewBatch:
	var best_batch: BrewBatch = null
	var best_score: float = -1.0
	
	for batch in batches:
		if batch.amount_bottles <= 0: continue
		var score = customer.get_preference_score(batch.beer_style.style)
		if batch.current_quality >= customer.min_quality:
			score += 0.2
		if score > best_score:
			best_score = score
			best_batch = batch
	return best_batch


func _execute_auto_sale(brewery: Brewery, batch: BrewBatch, bottles_sold: int, customer: CustomerData, slot: int) -> void:
	var style = batch.beer_style.style
	var quality = batch.current_quality
	var score = customer.get_preference_score(style)
	
	var price_modifier = 1.0
	var rep_change = 0
	var avi_change = 1
	var response_text = ""
	
	if quality < customer.min_quality:
		price_modifier = 0.4
		rep_change = -3
		avi_change = 1
		response_text = customer.dialogue_reject
	elif score >= 1.0:
		price_modifier = 1.2
		rep_change = +10
		avi_change = 3
		response_text = customer.dialogue_success
	elif score >= 0.5:
		price_modifier = 0.9
		rep_change = 0
		avi_change = 1
		response_text = customer.dialogue_fallback
	else:
		price_modifier = 0.5
		rep_change = -1
		avi_change = 2
		response_text = DIALOGUE_WRONG_STYLE
		
	var base_price = 3.0
	var income = roundi(bottles_sold * base_price * quality * customer.budget_multiplier * price_modifier)
	
	brewery.money += income
	brewery.reputation = max(0, brewery.reputation + rep_change)
	brewery.risk += avi_change
	
	batch.amount_bottles -= bottles_sold
	if batch.amount_bottles <= 0:
		brewery.inventory.brew_batches.erase(batch)
		
	dialogue_pushed.emit(response_text, false, slot)
	BrewerySignals.brewery_state_changed.emit(brewery)
	
	await get_tree().create_timer(3.5).timeout
	occupied_slots[slot] = false


func _trigger_special_request() -> void:
	is_handling_special = true
	special_timeout_timer.start()
	
	var event_type = randi_range(0, 1)
	if event_type == 0:
		active_special_batch_type = BeerStyle.Style.IPA
		customer_arrived.emit(null, true, -1)
		dialogue_pushed.emit(DIALOGUE_MC_INTRO, true, -1)
	else:
		active_special_batch_type = BeerStyle.Style.BULKKILAGER
		customer_arrived.emit(null, true, -1)
		dialogue_pushed.emit(DIALOGUE_INSPECTOR_INTRO, true, -1)


func accept_special_request() -> void:
	if not is_handling_special or BrewEngine.current_brewery == null: 
		push_warning(WARNING_SPECIAL_INVALID_STATE)
		return
	var brewery = BrewEngine.current_brewery
	
	var matching_batch: BrewBatch = null
	for batch in brewery.inventory.brew_batches:
		if batch.beer_style.style == active_special_batch_type:
			matching_batch = batch
			break
			
	if active_special_batch_type == BeerStyle.Style.IPA:
		if matching_batch and matching_batch.amount_bottles >= 20:
			special_timeout_timer.stop()
			matching_batch.amount_bottles -= 20
			brewery.money += 200
			brewery.reputation += 15
			brewery.risk += 5
			dialogue_pushed.emit(DIALOGUE_MC_SUCCESS, true, -1)
			if matching_batch.amount_bottles <= 0: brewery.inventory.brew_batches.erase(matching_batch)
			special_request_resolved.emit(true)
			_clear_special_turn()
		else:
			dialogue_pushed.emit(DIALOGUE_MC_FAIL, true, -1)
			special_request_resolved.emit(false)
			
	elif active_special_batch_type == BeerStyle.Style.BULKKILAGER:
		if matching_batch and matching_batch.amount_bottles >= 10:
			special_timeout_timer.stop()
			matching_batch.amount_bottles -= 10
			brewery.risk = 0
			dialogue_pushed.emit(DIALOGUE_INSPECTOR_SUCCESS, true, -1)
			if matching_batch.amount_bottles <= 0: brewery.inventory.brew_batches.erase(matching_batch)
			special_request_resolved.emit(true)
			_clear_special_turn()
		else:
			dialogue_pushed.emit(DIALOGUE_INSPECTOR_FAIL, true, -1)
			special_request_resolved.emit(false)
			
	BrewerySignals.brewery_state_changed.emit(brewery)


func reject_special_request() -> void:
	special_timeout_timer.stop()
	dialogue_pushed.emit(DIALOGUE_SPECIAL_REJECT, true, -1)
	_clear_special_turn()


func _clear_special_turn() -> void:
	is_handling_special = false



func spawn_normal_customer() -> void:
	_on_walk_in_timer_timeout()


func spawn_special_customer() -> void:
	_on_special_event_timer_timeout()
