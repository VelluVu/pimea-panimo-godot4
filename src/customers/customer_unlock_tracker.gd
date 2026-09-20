class_name CustomerUnlockTracker
extends RefCounted

## Decides which customers may appear and announces each customer title once,
## ever. In-run availability resets every run (reputation), but the announcement
## is permanent progress, persisted like AchievementManager and
## MetaProgressManager so it never repeats.

## A customer title's appearance gates were all met for the first time.
signal customer_unlocked(title: String)

const DEFAULT_SAVE_PATH: String = "user://customer_unlocks.cfg"
const SECTION: String = "customer_unlocks"
const KEY_ANNOUNCED_TITLES: String = "announced_titles"

var _config: ConfigFile = ConfigFile.new()
var _save_path: String


## `save_path` is overridable so tests never touch the real save file.
func _init(save_path: String = DEFAULT_SAVE_PATH) -> void:
	_save_path = save_path
	_config.load(_save_path) # a missing file just leaves the config empty


## True once all appearance gates pass: reputation (per run), style discovery and
## achievement unlock (both permanent). The single source of truth for "can this
## customer appear".
func is_eligible(customer: CustomerData) -> bool:
	var current_reputation: int = 0
	if BrewEngine.current_brewery != null:
		current_reputation = BrewEngine.current_brewery.reputation

	return current_reputation >= customer.min_reputation_to_appear \
		and _meets_style_discovery_requirement(customer) \
		and _meets_achievement_requirement(customer)


## Announces every eligible customer whose title has not been announced yet.
## Gendered variants sharing a title count as one reveal.
func announce_newly_unlocked(customers: Array[CustomerData]) -> void:
	var announced: Array = get_announced_titles()
	for customer: CustomerData in customers:
		if announced.has(customer.title):
			continue
		if not is_eligible(customer):
			continue

		announced.append(customer.title)
		_config.set_value(SECTION, KEY_ANNOUNCED_TITLES, announced)
		_config.save(_save_path)
		customer_unlocked.emit(customer.title)


func get_announced_titles() -> Array:
	return _config.get_value(SECTION, KEY_ANNOUNCED_TITLES, [])


## Forgets every announcement, in memory and on disk.
func reset() -> void:
	_config.clear()
	_config.save(_save_path)


## -1 (the default) means no requirement. Style discovery is permanent progress.
func _meets_style_discovery_requirement(customer: CustomerData) -> bool:
	if customer.required_discovered_style < 0:
		return true
	return MetaProgressManager.has_style(customer.required_discovered_style)


## An empty id (the default) means no requirement.
func _meets_achievement_requirement(customer: CustomerData) -> bool:
	if customer.required_achievement_id == "":
		return true
	return AchievementManager.is_unlocked(customer.required_achievement_id)
