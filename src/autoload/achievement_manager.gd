#AchievementManager (Autoload)
extends Node

## Persists lifetime achievement progress across every run, same
## load/mutate/save ConfigFile shape as MetaProgressManager (see that
## file's own docstring for why that's this project's established pattern
## for anything outliving SaveManager's single active-run save slot).
##
## AchievementManager owns two things: a set of named lifetime stat
## counters (STAT_*), incremented by hooking BrewerySignals directly rather
## than being told about them by whichever system fired the signal, and the
## AchievementData pool loaded from res://src/resources/achievements/, each
## entry watching one counter for a target_value. CustomerData's
## required_achievement_id (checked via is_unlocked() in
## CustomerRegistry) is the first consumer, gating Lähettirobotti behind
## STAT_BAR_SHIPMENTS reaching 3 (kolme_vientieraa.tres) and Tarkastusdrooni
## behind STAT_LVV_BRIBES_SUCCEEDED reaching 3 (kolme_lvv_lahjusta.tres).

signal achievement_unlocked(achievement_id : String, title : String)

## Fired once per BrewerySignals.keg_shipped_to_bar, regardless of the
## shipment's bottle count — an achievement counting shipments, not
## bottles moved.
const STAT_BAR_SHIPMENTS : StringName = &"bar_shipments"

## Fired once per BrewerySignals.special_event_resolved where the resolved
## event was specifically a RiskBribeEventData (the only "LVV" special
## event shipped so far — see lvv_bribe.tres) and it succeeded.
const STAT_LVV_BRIBES_SUCCEEDED : StringName = &"lvv_bribes_succeeded"

## Not a counter, a ratchet: set to the CURRENT count of hop IngredientData
## whose min_reputation is at or below Brewery.reputation, recomputed on
## every BrewerySignals.brewery_state_changed — but only ever written when
## that recomputed count is higher than what's already stored (see
## _set_stat_if_higher()), so a reputation drop (e.g. an LVV raid) can never
## un-unlock this stat's achievements. Only hops use min_reputation (see
## IngredientData's own docstring), so this never needs an ingredient-type
## filter beyond IngredientType.HOP.
const STAT_HOPS_UNLOCKED : StringName = &"hops_unlocked"

## Reported by CustomerRegistry.report_customer_unlocked() the first moment
## ANY CustomerData's appearance gates are all met, across every run ever
## played — see CustomerRegistry._check_for_newly_unlocked_customers().
const STAT_CUSTOMERS_UNLOCKED : StringName = &"customers_unlocked"

const SAVE_PATH : String = "user://achievements.cfg"
const SECTION_STATS : String = "stats"
const SECTION_UNLOCKS : String = "unlocks"
const KEY_UNLOCKED_IDS : String = "unlocked_ids"

const ACHIEVEMENT_FOLDER_PATH : String = "res://src/resources/achievements/"
const WARNING_FOLDER_OPEN_FAILED : String = "AchievementManager: Failed to open path: "

var _config : ConfigFile = ConfigFile.new()
## Overridable so tests can redirect persistence to a throwaway path
## instead of the real user://achievements.cfg — same reasoning as
## MetaProgressManager._save_path.
var _save_path : String = SAVE_PATH
var achievement_pool : Array[AchievementData] = []


func _ready() -> void:
	_config.load(_save_path) # missing file just leaves _config empty, fine
	_load_achievement_pool()
	BrewerySignals.keg_shipped_to_bar.connect(_on_keg_shipped_to_bar)
	BrewerySignals.style_discovered.connect(_on_style_discovered)
	BrewerySignals.special_event_resolved.connect(_on_special_event_resolved)
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)


func _load_achievement_pool() -> void:
	var dir := DirAccess.open(ACHIEVEMENT_FOLDER_PATH)
	if dir == null:
		push_warning(WARNING_FOLDER_OPEN_FAILED + ACHIEVEMENT_FOLDER_PATH)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res := load(ACHIEVEMENT_FOLDER_PATH + file_name)
			if res is AchievementData:
				achievement_pool.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()


func _on_keg_shipped_to_bar(_style_name : String, _bar_name : String, _bottles : int, _payout : float, _risk_added : int) -> void:
	_increment_stat(STAT_BAR_SHIPMENTS)


## One stat per style (style_discovered_<id>) rather than a single shared
## counter — lets each style ship its own dedicated AchievementData
## (tyyli_kotikalja.tres etc.) instead of one vague "discover N styles"
## achievement, matching "every beer style unlock is achievement".
func _on_style_discovered(style : int) -> void:
	_increment_stat(_style_stat_key(style))


func _style_stat_key(style : int) -> StringName:
	return StringName("style_discovered_%d" % style)


func _on_special_event_resolved(succeeded : bool, event_data : SpecialEventData) -> void:
	if succeeded and event_data is RiskBribeEventData:
		_increment_stat(STAT_LVV_BRIBES_SUCCEEDED)


func _on_brewery_state_changed(brewery : Brewery) -> void:
	var unlocked_hop_count : int = count_unlocked_hops(IngredientDatabase.database.values(), brewery.reputation)
	_set_stat_if_higher(STAT_HOPS_UNLOCKED, unlocked_hop_count)


## Pure counting rule split out of _on_brewery_state_changed() so it can be
## unit-tested with hand-built IngredientData: the handler itself needs the
## live IngredientDatabase autoload and a live Brewery, neither of which
## exists inside the editor's test runner.
static func count_unlocked_hops(ingredients : Array, reputation : int) -> int:
	var unlocked_hop_count : int = 0
	for ingredient : IngredientData in ingredients:
		if ingredient.type == IngredientData.IngredientType.HOP and ingredient.min_reputation <= reputation:
			unlocked_hop_count += 1
	return unlocked_hop_count


## Called by CustomerRegistry, never by a BrewerySignals hook directly —
## unlike every other STAT_* above, "a customer archetype just became
## eligible" isn't something AchievementManager can derive on its own
## without duplicating CustomerRegistry's own eligibility rules
## (reputation + style + achievement gates all at once).
func report_customer_unlocked() -> void:
	_increment_stat(STAT_CUSTOMERS_UNLOCKED)


func get_stat(stat_key : StringName) -> int:
	return _config.get_value(SECTION_STATS, stat_key, 0)


func get_unlocked_ids() -> Array:
	return _config.get_value(SECTION_UNLOCKS, KEY_UNLOCKED_IDS, [])


func is_unlocked(achievement_id : String) -> bool:
	return get_unlocked_ids().has(achievement_id)


func _increment_stat(stat_key : StringName, amount : int = 1) -> void:
	var current : int = get_stat(stat_key) + amount
	_config.set_value(SECTION_STATS, stat_key, current)
	_config.save(_save_path)
	_check_unlocks(stat_key, current)


## For a stat that's recomputed from live state each time (STAT_HOPS_UNLOCKED)
## rather than incremented per-event — writes (and checks unlocks) only when
## value is a new high, so a stat derived from something reversible (like
## Brewery.reputation, which an LVV raid can knock back down) still only
## ever ratchets forward, same permanent-once-unlocked feel as every
## event-driven stat above.
func _set_stat_if_higher(stat_key : StringName, value : int) -> void:
	if value <= get_stat(stat_key):
		return
	_config.set_value(SECTION_STATS, stat_key, value)
	_config.save(_save_path)
	_check_unlocks(stat_key, value)


func _check_unlocks(stat_key : StringName, current_value : int) -> void:
	for achievement : AchievementData in achievement_pool:
		if achievement.stat_key != stat_key:
			continue
		if is_unlocked(achievement.achievement_id):
			continue
		if current_value >= achievement.target_value:
			_unlock(achievement)


func _unlock(achievement : AchievementData) -> void:
	var unlocked := get_unlocked_ids()
	unlocked.append(achievement.achievement_id)
	_config.set_value(SECTION_UNLOCKS, KEY_UNLOCKED_IDS, unlocked)
	_config.save(_save_path)
	achievement_unlocked.emit(achievement.achievement_id, achievement.title)
