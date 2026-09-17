#CustomerRegistry (Autoload)
extends Node


const WARNING_FOLDER_OPEN_FAILED = "CustomerRegistry: Failed to open path: "
const WARNING_POOL_EMPTY = "CustomerRegistry: Customer pool is empty!"
const WARNING_EVENTS_EMPTY = "CustomerRegistry: Special events pool is empty!"

@export var customer_folder_path: String = "res://src/resources/customers/"
@export var special_event_folder_path: String = "res://src/resources/special_events/"
@export var group_event_folder_path: String = "res://src/resources/group_events/"
@export var bar_contact_folder_path: String = "res://src/resources/bars/"

var customer_pool: Array[CustomerData] = []
var special_events_pool: Array[SpecialEventData] = []
var group_events_pool: Array[GroupVisitEventData] = []
## BarContact destinations for BeerPatchPanel's "ship a batch to a bar"
## action (see Brewery.ship_batch_to_bar()) — loaded the same way as the
## pools above. Not reputation-filtered here; BarContactOptionButton
## mirrors IngredientOptionButton's own pattern of listing every entry and
## disabling the locked ones in place, so the picker itself communicates
## what's coming rather than hiding it entirely.
var bar_contact_pool: Array[BarContact] = []


func _ready() -> void:
	_load_resources()


## During an active DayEventData window (see DayEventManager), rerolls
## toward featured_customer_titles at that event's own
## solo_customer_bias_chance instead of always using the plain eligible
## pool — same "weighted, not forced" reasoning DayEventData's own
## featured_group_event_chance uses for group visits, so a themed day's
## walk-ins skew toward its archetype without every single one being it.
## Falls back to the normal eligible pool if the bias roll misses, if no
## event is active, or if the featured titles happen to match nothing
## currently eligible (e.g. reputation-gated out).
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

	var day_event : DayEventData = DayEventManager.get_active_event()
	if day_event != null and not day_event.featured_customer_titles.is_empty() and randf() < day_event.solo_customer_bias_chance:
		var featured : Array[CustomerData] = []
		for customer in eligible_customers:
			if day_event.featured_customer_titles.has(customer.title):
				featured.append(customer)
		if not featured.is_empty():
			return featured.pick_random()

	return eligible_customers.pick_random()


## Picks a customer who genuinely wants the given style (primary preferred,
## secondary as fallback), for the instant walk-in triggered right after a
## matching brew completes. Customers with randomizes_preference are
## excluded — their preference gets rerolled on spawn, so picking them here
## wouldn't guarantee they actually want this style. Falls back to any
## random customer if no static fan of this style exists.
func get_customer_for_style(style: BeerStyle.Style) -> CustomerData:
	var current_reputation : int = 0
	if BrewEngine.current_brewery != null:
		current_reputation = BrewEngine.current_brewery.reputation

	var primary_matches : Array[CustomerData] = []
	var secondary_matches : Array[CustomerData] = []

	for customer in customer_pool:
		if customer.randomizes_preference:
			continue
		if current_reputation < customer.min_reputation_to_appear:
			continue
		if customer.primary_style == style:
			primary_matches.append(customer)
		elif customer.secondary_style == style:
			secondary_matches.append(customer)

	if not primary_matches.is_empty():
		return primary_matches.pick_random()
	if not secondary_matches.is_empty():
		return secondary_matches.pick_random()
	return get_random_customer_data()


## Weighted by each event's own get_weight(brewery) instead of a flat
## pick_random() — see SpecialEventData.get_weight()'s docstring. Every
## event with the default weight (1.0) keeps exactly the same odds as
## before; only an event that overrides get_weight() (currently just
## RiskBribeEventData) shifts the distribution, and only when the state it
## cares about actually changes.
func get_random_special_event(brewery: Brewery) -> SpecialEventData:
	if special_events_pool.is_empty():
		return null

	var total_weight: float = 0.0
	for event: SpecialEventData in special_events_pool:
		total_weight += event.get_weight(brewery)

	var roll: float = randf() * total_weight
	var cumulative: float = 0.0
	for event: SpecialEventData in special_events_pool:
		cumulative += event.get_weight(brewery)
		if roll < cumulative:
			return event

	return special_events_pool.back()


func get_random_group_event() -> GroupVisitEventData:
	if group_events_pool.is_empty():
		return null
	return group_events_pool.pick_random()


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

	var dir_group = DirAccess.open(group_event_folder_path)
	if dir_group:
		dir_group.list_dir_begin()
		var file_name = dir_group.get_next()
		while file_name != "":
			if not dir_group.current_is_dir() and file_name.ends_with(".tres"):
				var res = load(group_event_folder_path + file_name)
				if res is GroupVisitEventData:
					group_events_pool.append(res)
			file_name = dir_group.get_next()
		dir_group.list_dir_end()
	else:
		push_warning(WARNING_FOLDER_OPEN_FAILED + group_event_folder_path)

	var dir_bars = DirAccess.open(bar_contact_folder_path)
	if dir_bars:
		dir_bars.list_dir_begin()
		var file_name = dir_bars.get_next()
		while file_name != "":
			if not dir_bars.current_is_dir() and file_name.ends_with(".tres"):
				var res = load(bar_contact_folder_path + file_name)
				if res is BarContact:
					bar_contact_pool.append(res)
			file_name = dir_bars.get_next()
		dir_bars.list_dir_end()
	else:
		push_warning(WARNING_FOLDER_OPEN_FAILED + bar_contact_folder_path)

	if customer_pool.is_empty():
		push_warning(WARNING_POOL_EMPTY)
	if special_events_pool.is_empty():
		push_warning(WARNING_EVENTS_EMPTY)
