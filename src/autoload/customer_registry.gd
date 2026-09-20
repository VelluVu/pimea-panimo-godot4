#CustomerRegistry (Autoload)
extends Node

## Fired once per customer title, the first time all of its appearance gates are
## met, across every run ever played. Gendered variants sharing a title count as one.
## Persisted like AchievementManager/MetaProgressManager, since the gates' underlying
## availability resets each run but the announcement must never repeat.
signal customer_unlocked(title : String)

const WARNING_POOL_EMPTY = "CustomerRegistry: Customer pool is empty!"
const WARNING_EVENTS_EMPTY = "CustomerRegistry: Special events pool is empty!"

@export var customer_folder_path: String = "res://src/resources/customers/"
@export var special_event_folder_path: String = "res://src/resources/special_events/"
@export var group_event_folder_path: String = "res://src/resources/group_events/"
@export var bar_contact_folder_path: String = "res://src/resources/bars/"

var customer_pool: Array[CustomerData] = []
var special_events_pool: Array[SpecialEventData] = []
var group_events_pool: Array[GroupVisitEventData] = []
## Destinations for shipping a batch to a bar. Not reputation-filtered here: the
## picker lists every entry and disables the locked ones, like the ingredient picker.
var bar_contact_pool: Array[BarContact] = []

const TITLE_AGENTTI : String = "Agentti"
const TITLE_MAFIOSO : String = "Mafioso"

const SAVE_PATH : String = "user://customer_unlocks.cfg"
const SECTION : String = "customer_unlocks"
const KEY_ANNOUNCED_TITLES : String = "announced_titles"

var _config : ConfigFile = ConfigFile.new()
## Overridable so tests never touch the real user://customer_unlocks.cfg.
var _save_path : String = SAVE_PATH


func _ready() -> void:
	_config.load(_save_path) # missing file just leaves _config empty, fine
	_load_resources()
	BrewerySignals.brewery_state_changed.connect(_on_customer_unlock_trigger)
	BrewerySignals.style_discovered.connect(_on_style_discovered_for_customer_unlocks)
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked_for_customer_unlocks)
	_check_for_newly_unlocked_customers()


## Reputation change, style discovery and achievement unlock can each satisfy a
## customer's gate, so all three trigger the same re-scan.
func _on_customer_unlock_trigger(_brewery : Brewery) -> void:
	_check_for_newly_unlocked_customers()


func _on_style_discovered_for_customer_unlocks(_style : int) -> void:
	_check_for_newly_unlocked_customers()


func _on_achievement_unlocked_for_customer_unlocks(_achievement_id : String, _title : String) -> void:
	_check_for_newly_unlocked_customers()


## During an active day event, rerolls toward its featured titles at the event's own
## bias chance. Falls back to the normal eligible pool if the roll misses, no event is
## active, or no featured title is currently eligible.
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


## Weighted by the agentti/mafioso appearance perks ("Terävä silmä"); every other
## title weighs 1.0, so without those perks this is a plain uniform pick.
func _pick_weighted_customer(customers : Array[CustomerData]) -> CustomerData:
	var brewery : Brewery = BrewEngine.current_brewery
	if brewery == null:
		return customers.pick_random()

	var weights : Array[float] = []
	for customer : CustomerData in customers:
		var weight : float = 1.0
		if customer.title == TITLE_AGENTTI:
			weight = brewery.stats.multiplier(PerkStats.AGENTTI_APPEARANCE)
		elif customer.title == TITLE_MAFIOSO:
			weight = brewery.stats.multiplier(PerkStats.MAFIOSO_APPEARANCE)
		weights.append(weight)

	return WeightedPicker.pick(customers, weights) as CustomerData


## Picks a customer who wants this style (primary preferred, then secondary) for the
## instant walk-in after a matching brew. Skips randomizes_preference customers, whose
## preference is rerolled on spawn. Falls back to any random customer.
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


## Weighted by each event's get_weight(brewery); the default 1.0 keeps flat odds.
func get_random_special_event(brewery: Brewery) -> SpecialEventData:
	var weights: Array[float] = []
	for event: SpecialEventData in special_events_pool:
		weights.append(event.get_weight(brewery))
	return WeightedPicker.pick(special_events_pool, weights) as SpecialEventData


func get_random_group_event() -> GroupVisitEventData:
	if group_events_pool.is_empty():
		return null
	return group_events_pool.pick_random()


## True once all appearance gates pass: reputation (per run), style discovery and
## achievement unlock (both permanent). The single source of truth for "can this
## customer appear".
func is_eligible(customer : CustomerData) -> bool:
	var current_reputation : int = 0
	if BrewEngine.current_brewery != null:
		current_reputation = BrewEngine.current_brewery.reputation

	return current_reputation >= customer.min_reputation_to_appear \
		and _meets_style_discovery_requirement(customer) \
		and _meets_achievement_requirement(customer)


## -1 (the default) means no requirement. Style discovery is permanent progress.
func _meets_style_discovery_requirement(customer : CustomerData) -> bool:
	if customer.required_discovered_style < 0:
		return true
	return MetaProgressManager.has_style(customer.required_discovered_style)


## An empty id (the default) means no requirement.
func _meets_achievement_requirement(customer : CustomerData) -> bool:
	if customer.required_achievement_id == "":
		return true
	return AchievementManager.is_unlocked(customer.required_achievement_id)


## Announces each customer title once, ever, the first time is_eligible() is true for
## it. In-run availability still resets each run; only the announcement is permanent.
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
	customer_pool.assign(ResourceFolder.load_all(customer_folder_path, CustomerData))
	special_events_pool.assign(ResourceFolder.load_all(special_event_folder_path, SpecialEventData))
	group_events_pool.assign(ResourceFolder.load_all(group_event_folder_path, GroupVisitEventData))
	bar_contact_pool.assign(ResourceFolder.load_all(bar_contact_folder_path, BarContact))

	if customer_pool.is_empty():
		push_warning(WARNING_POOL_EMPTY)
	if special_events_pool.is_empty():
		push_warning(WARNING_EVENTS_EMPTY)


## Forgets which customers were announced as unlocked, in memory and on disk.
func reset_progress() -> void:
	_config.clear()
	_config.save(_save_path)
