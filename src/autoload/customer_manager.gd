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
	BrewerySignals.beer_brewed.connect(_on_beer_brewed)


## A matching brew just finished — reward the player with an immediate
## walk-in who specifically wants that style, instead of waiting on the
## ambient spawn timer to eventually roll one who happens to want it.
func _on_beer_brewed(style: int) -> void:
	spawn_normal_customer(CustomerRegistry.get_customer_for_style(style))


func register_spawner(spawner: CustomerSpawner) -> void:
	active_spawner = spawner

	# A fresh CustomerSpawner means a fresh main.tscn — any customer nodes
	# from a previous session are already gone (freed with the old scene),
	# so slots they never got to vacate (e.g. the player left mid-visit via
	# the main menu) must not stay marked occupied forever.
	occupied_slots = [false, false, false, false, false]
	active_customers.clear()

	if BrewEngine.current_brewery and not BrewEngine.current_brewery.inventory.brew_batches.is_empty():
		active_spawner.start_spawning()


## Used to warn before closing the day — a customer who's walked in but
## hasn't finished their interaction yet would otherwise lose their sale
## with no feedback when the day advances out from under them.
func has_active_customers() -> bool:
	return not active_customers.is_empty()


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
	

## Public so a customer can preview what it's about to pick (shown as a
## dialogue beat) before process_auto_sale() actually resolves the sale —
## the decision itself stays entirely the customer's, this just makes it
## visible instead of an invisible dice roll.
func find_best_batch_for(data: CustomerData) -> BrewBatch:
	if BrewEngine.current_brewery == null:
		return null
	return _find_best_batch(BrewEngine.current_brewery.inventory.brew_batches, data)


func process_auto_sale(data: CustomerData) -> String:
	var best_batch = find_best_batch_for(data)

	if best_batch == null or best_batch.amount_bottles < BOTTLES_SOLD_PER_TRANSACTION:
		return ""

	var brewery = BrewEngine.current_brewery

	var results: Dictionary = data.evaluate_brew_batch(best_batch)

	var bottles_sold : int = randi_range(data.min_bottles_per_visit, data.max_bottles_per_visit)
	bottles_sold = min(bottles_sold, best_batch.amount_bottles)

	brewery.money += results[KEY_INCOME] * bottles_sold
	brewery.reputation = max(0, brewery.reputation + results[KEY_REPUTATION])
	brewery.add_risk(results[KEY_RISK])

	best_batch.amount_bottles -= bottles_sold
	if best_batch.amount_bottles <= 0:
		brewery.inventory.brew_batches.erase(best_batch)

	brewery.bottles_sold_today += bottles_sold
	BrewerySignals.bottles_sold.emit(bottles_sold)
	_check_bottles_goal_reward(brewery)

	var response_text : String = results[KEY_RESPONSE]

	if data.bar_fight_chance > 0.0 and randf() < data.bar_fight_chance:
		response_text += "\n" + _trigger_bar_fight(brewery, data, best_batch)

	BrewerySignals.brewery_state_changed.emit(brewery)
	return response_text


const BOTTLES_GOAL_REWARD_NAME : String = "Pullotavoite"

## Instant payout the moment the daily bottles-sold target is crossed —
## rewarding "reach X" goals right when they happen (rather than batching
## them into the end-of-day recap) keeps the feedback close to the action
## that earned it. The risk goal is the opposite case (a "stay under X"
## goal that can only be confirmed at day's end) and is rewarded from
## TimeManager._advance_day() instead.
func _check_bottles_goal_reward(brewery: Brewery) -> void:
	if not brewery.tutorial_complete() or brewery.bottles_goal_rewarded_today:
		return
	if brewery.bottles_sold_today < DailyGoalsPanel.BOTTLES_TARGET:
		return

	brewery.bottles_goal_rewarded_today = true
	brewery.money += DailyGoalsPanel.BOTTLES_GOAL_REWARD_MONEY
	brewery.reputation += DailyGoalsPanel.BOTTLES_GOAL_REWARD_REPUTATION
	BrewerySignals.daily_goal_reward_granted.emit(BOTTLES_GOAL_REWARD_NAME, DailyGoalsPanel.BOTTLES_GOAL_REWARD_MONEY, DailyGoalsPanel.BOTTLES_GOAL_REWARD_REPUTATION)


func _trigger_bar_fight(brewery: Brewery, data: CustomerData, batch: BrewBatch) -> String:
	brewery.reputation = max(0, brewery.reputation - data.bar_fight_reputation_penalty)
	brewery.add_risk(data.bar_fight_risk_penalty)

	if data.bar_fight_max_bottles_broken > 0 and brewery.inventory.brew_batches.has(batch):
		var broken_bottles : int = randi_range(1, data.bar_fight_max_bottles_broken)
		batch.amount_bottles = max(0, batch.amount_bottles - broken_bottles)

		if batch.amount_bottles <= 0:
			brewery.inventory.brew_batches.erase(batch)

	return data.dialogue_bar_fight


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


func spawn_normal_customer(forced_data: CustomerData = null) -> void:
	active_spawner._on_walk_in_timer_timeout(forced_data)