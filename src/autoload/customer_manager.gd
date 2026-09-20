#CustomerManager (Autoload)
extends Node


const KEY_INCOME = "income"
const KEY_TIP = "tip"
const KEY_REPUTATION = "reputation"
const KEY_RISK = "risk"
const KEY_RESPONSE = "response"

## Default cost of turning a customer away with nothing to sell them: small,
## but not free, since they complain on the way out.
const NO_MATCH_REPUTATION_PENALTY : int = 1
const NO_MATCH_RISK_PENALTY : int = 1

## Used until a spawner reports how many counter positions it really has.
const DEFAULT_SLOT_COUNT : int = 5

var slots : CounterSlots = CounterSlots.new(DEFAULT_SLOT_COUNT)
var active_spawner: CustomerSpawner = null


func _ready() -> void:
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)
	BrewerySignals.beer_brewed.connect(_on_beer_brewed)


## A matching brew brings an immediate walk-in who wants that style, instead of
## waiting for the ambient timer to roll one.
func _on_beer_brewed(style: int) -> void:
	spawn_normal_customer(CustomerRegistry.get_customer_for_style(style))


func register_spawner(spawner: CustomerSpawner) -> void:
	active_spawner = spawner

	# A new spawner means a new main scene: customers from the old one are gone,
	# so their slots must not stay occupied.
	slots.reset(spawner.counter_markers.size() if not spawner.counter_markers.is_empty() else DEFAULT_SLOT_COUNT)

	if BrewEngine.current_brewery and not BrewEngine.current_brewery.inventory.brew_batches.is_empty():
		active_spawner.start_spawning()


## Used to warn before closing the day: someone mid-visit would lose their sale.
func has_active_customers() -> bool:
	return slots.has_customers()


## Throws out everyone still being served when the day is force-closed.
## queue_free() cancels a solo customer's sale: their whole sequence is a chain
## of timers and tweens bound to the node. A group order is one coroutine
## instead, cancelled by its own member-validity check in
## GroupVisitDirector._run_shared_group_order().
func evict_active_customers() -> void:
	if not slots.has_customers():
		return

	for customer : Node2D in slots.customers():
		if is_instance_valid(customer):
			BrewerySignals.customer_evicted.emit(customer.dialogue_slot)
			customer.queue_free()

	slots.reset(slots.size())


func get_free_slot_index() -> int:
	return slots.first_free()


func get_random_customer_data() -> CustomerData:
	return CustomerRegistry.get_random_customer_data()


## A group registers every member against one shared slot, see CounterSlots.
func register_active_customer(slot: int, node: Node2D) -> void:
	slots.register(slot, node)


func free_slot_index(slot: int) -> void:
	slots.release(slot)


func _on_brewery_state_changed(brewery: Brewery) -> void:
	if active_spawner and not brewery.inventory.brew_batches.is_empty():
		active_spawner.start_spawning()
	

## What the customer would buy, so it can preview its pick before the sale.
func find_best_batch_for(data: CustomerData) -> BrewBatch:
	return SaleProcessor.new(BrewEngine.current_brewery).find_best_batch_for(data)


## Resolves the customer's purchase and returns their spoken response.
func process_auto_sale(data: CustomerData) -> String:
	return SaleProcessor.new(BrewEngine.current_brewery).process(data)


func spawn_normal_customer(forced_data: CustomerData = null) -> void:
	if active_spawner == null:
		return
	active_spawner._on_walk_in_timer_timeout(forced_data)


func spawn_group_event(forced_event_data: GroupVisitEventData = null) -> void:
	if active_spawner == null:
		return
	active_spawner._on_group_event_timer_timeout(forced_event_data)


## Used by LvvRaidSpawner around a raid squad's walk-in and walk-out.
func pause_spawning() -> void:
	if active_spawner:
		active_spawner.pause_spawning()


func resume_spawning() -> void:
	if active_spawner:
		active_spawner.start_spawning()
