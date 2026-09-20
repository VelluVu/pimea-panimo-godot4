#CustomerRegistry (Autoload)
extends Node

## Fired the first moment ANY CustomerData's appearance gates (reputation,
## style discovery, achievement) are ALL met, once per distinct title
## across every run ever played — see _check_for_newly_unlocked_customers().
## Gendered variants sharing one title (e.g. Saksalainen turisti/_naaras)
## count as a single reveal. Persisted the same ConfigFile way as
## AchievementManager/MetaProgressManager, since a reputation-gated
## customer's underlying availability resets every run but this
## announcement must never repeat.
signal customer_unlocked(title : String)

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

const TITLE_AGENTTI : String = "Agentti"
const TITLE_MAFIOSO : String = "Mafioso"

const SAVE_PATH : String = "user://customer_unlocks.cfg"
const SECTION : String = "customer_unlocks"
const KEY_ANNOUNCED_TITLES : String = "announced_titles"

var _config : ConfigFile = ConfigFile.new()
## Overridable so tests can redirect persistence to a throwaway path
## instead of the real user://customer_unlocks.cfg — same reasoning as
## AchievementManager._save_path/MetaProgressManager._save_path.
var _save_path : String = SAVE_PATH


func _ready() -> void:
	_config.load(_save_path) # missing file just leaves _config empty, fine
	_load_resources()
	BrewerySignals.brewery_state_changed.connect(_on_customer_unlock_trigger)
	BrewerySignals.style_discovered.connect(_on_style_discovered_for_customer_unlocks)
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked_for_customer_unlocks)
	_check_for_newly_unlocked_customers()


## Three independent triggers, one shared re-scan — any of a reputation
## change, a style discovery, or an achievement unlock could newly satisfy
## a customer's gate (see is_eligible()'s three conditions).
func _on_customer_unlock_trigger(_brewery : Brewery) -> void:
	_check_for_newly_unlocked_customers()


func _on_style_discovered_for_customer_unlocks(_style : int) -> void:
	_check_for_newly_unlocked_customers()


func _on_achievement_unlocked_for_customer_unlocks(_achievement_id : String, _title : String) -> void:
	_check_for_newly_unlocked_customers()


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

	var eligible_customers : Array[CustomerData] = []
	for customer in customer_pool:
		if is_eligible(customer):
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

	return _pick_weighted_customer(eligible_customers)


## Flat pick_random() weighted by Brewery.get_agentti_appearance_multiplier()/
## get_mafioso_appearance_multiplier() when a customer's title matches — see
## MetaUnlockData's "Terävä silmä" bar-work node. Every other title stays
## weight 1.0, so this is identical to a plain pick_random() whenever
## neither perk is active (or no run is in progress at all).
func _pick_weighted_customer(customers : Array[CustomerData]) -> CustomerData:
	var brewery : Brewery = BrewEngine.current_brewery
	if brewery == null:
		return customers.pick_random()

	var weights : Array[float] = []
	var total_weight : float = 0.0
	for customer : CustomerData in customers:
		var weight : float = 1.0
		if customer.title == TITLE_AGENTTI:
			weight = brewery.stats.multiplier(PerkStats.AGENTTI_APPEARANCE)
		elif customer.title == TITLE_MAFIOSO:
			weight = brewery.stats.multiplier(PerkStats.MAFIOSO_APPEARANCE)
		weights.append(weight)
		total_weight += weight

	if total_weight <= 0.0:
		return customers.pick_random()

	var roll : float = randf() * total_weight
	var cumulative : float = 0.0
	for i in range(customers.size()):
		cumulative += weights[i]
		if roll < cumulative:
			return customers[i]

	return customers.back()


## Picks a customer who genuinely wants the given style (primary preferred,
## secondary as fallback), for the instant walk-in triggered right after a
## matching brew completes. Customers with randomizes_preference are
## excluded — their preference gets rerolled on spawn, so picking them here
## wouldn't guarantee they actually want this style. Falls back to any
## random customer if no static fan of this style exists.
func get_customer_for_style(style: BeerStyle.Style) -> CustomerData:
	var primary_matches : Array[CustomerData] = []
	var secondary_matches : Array[CustomerData] = []

	for customer in customer_pool:
		if customer.randomizes_preference:
			continue
		if not is_eligible(customer):
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


## True only once ALL of a customer's appearance gates are satisfied —
## reputation (resets every run), permanent style discovery, and permanent
## achievement unlock. The single source of truth for "can this customer
## currently appear", shared by get_random_customer_data(),
## get_customer_for_style(), and _check_for_newly_unlocked_customers()
## below, so the three gates are never checked three slightly different ways.
func is_eligible(customer : CustomerData) -> bool:
	var current_reputation : int = 0
	if BrewEngine.current_brewery != null:
		current_reputation = BrewEngine.current_brewery.reputation

	return current_reputation >= customer.min_reputation_to_appear \
		and _meets_style_discovery_requirement(customer) \
		and _meets_achievement_requirement(customer)


## -1 (no requirement, the default) always passes. See CustomerData.
## required_discovered_style's own docstring — MetaProgressManager persists
## style discovery across runs, so this gate is permanent progress, not
## something reset at the start of a new run.
func _meets_style_discovery_requirement(customer : CustomerData) -> bool:
	if customer.required_discovered_style < 0:
		return true
	return MetaProgressManager.has_style(customer.required_discovered_style)


## Empty (no requirement, the default) always passes — see
## CustomerData.required_achievement_id's own docstring.
func _meets_achievement_requirement(customer : CustomerData) -> bool:
	if customer.required_achievement_id == "":
		return true
	return AchievementManager.is_unlocked(customer.required_achievement_id)


## Permanently announces each customer archetype (keyed by title, so
## gendered variants sharing one title — e.g. Saksalainen turisti/_naaras —
## count as a single reveal) the first moment is_eligible() is true for it,
## exactly once across every run ever played. A reputation-gated customer's
## actual in-run availability still resets every run like normal; only this
## announcement is permanent, so the player is celebrated for reaching a
## reputation threshold once, not re-congratulated every single run.
func _check_for_newly_unlocked_customers() -> void:
	var announced := _get_announced_titles()
	for customer : CustomerData in customer_pool:
		if announced.has(customer.title):
			continue
		if not is_eligible(customer):
			continue

		announced.append(customer.title)
		_config.set_value(SECTION, KEY_ANNOUNCED_TITLES, announced)
		_config.save(_save_path)

		AchievementManager.report_customer_unlocked()
		customer_unlocked.emit(customer.title)


func _get_announced_titles() -> Array:
	return _config.get_value(SECTION, KEY_ANNOUNCED_TITLES, [])


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

## Forgets which customers were announced as unlocked, in memory and on disk.
func reset_progress() -> void:
	_config.clear()
	_config.save(_save_path)
