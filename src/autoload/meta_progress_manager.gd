extends Node

## Progress that survives a single run, in its own ConfigFile like LeaderboardManager: the
## styles ever discovered, the renown currency earned per run, and which MetaUnlockData
## nodes were bought with it. See StyleDiscovery.seed_from_meta() and
## Brewery._seed_meta_perks() for how it feeds a new run. The tree's rules are in
## MetaUnlockRules.

const SAVE_PATH : String = "user://meta_progress.cfg"
const SECTION : String = "meta_progress"
const KEY_DISCOVERED_STYLES : String = "discovered_styles"
const KEY_RENOWN : String = "renown"
const KEY_UNLOCKED_LEVELS : String = "unlocked_levels"

const UNLOCK_FOLDER_PATH : String = "res://src/resources/meta_unlocks/"

## LeaderboardManager has no class_name, so its static function is reached through the
## script (as test_leaderboard_manager.gd does) to avoid STATIC_CALLED_ON_INSTANCE.
const LeaderboardManagerScript := preload("res://src/autoload/leaderboard_manager.gd")

## The leaderboard's difficulty-weighted score scaled into a small currency, so the two
## agree on what a good run is. Floored: a bust already costs the player its progress, so
## it should still contribute a little.
const RENOWN_SCORE_DIVISOR : float = 20.0
const RENOWN_FLOOR : int = 5

var unlock_pool : Array[MetaUnlockData] = []

var _config : ConfigFile = ConfigFile.new()
## Overridable so tests that really write (add_renown(), purchase_next_level()) can use a
## throwaway file instead of user://meta_progress.cfg.
var _save_path : String = SAVE_PATH


func _ready() -> void:
	_config.load(_save_path) # a missing file just leaves the config empty
	unlock_pool.assign(ResourceFolder.load_all(UNLOCK_FOLDER_PATH, MetaUnlockData))
	BrewerySignals.style_discovered.connect(_on_style_discovered)
	BrewerySignals.game_ended.connect(_on_game_ended)


static func calculate_renown(days_survived : int, reputation : int, lifetime_bottles_sold : int, run_modifier : RunModifier = null) -> int:
	var score : int = LeaderboardManagerScript.calculate_score(days_survived, reputation, lifetime_bottles_sold, run_modifier)
	return maxi(RENOWN_FLOOR, roundi(score / RENOWN_SCORE_DIVISOR))


func has_style(style : int) -> bool:
	return get_discovered_styles().has(style)


func get_discovered_styles() -> Array:
	return _config.get_value(SECTION, KEY_DISCOVERED_STYLES, [])


func get_renown() -> int:
	return _config.get_value(SECTION, KEY_RENOWN, 0)


func add_renown(amount : int) -> void:
	if amount > 0:
		_config.set_value(SECTION, KEY_RENOWN, get_renown() + amount)
		_save()


func get_unlocked_levels() -> Dictionary:
	return _config.get_value(SECTION, KEY_UNLOCKED_LEVELS, {})


func get_node_level(unlock_id : String) -> int:
	return get_unlocked_levels().get(unlock_id, 0)


func is_maxed(unlock_id : String) -> bool:
	var unlock : MetaUnlockData = find_unlock(unlock_id)
	return unlock != null and MetaUnlockRules.is_maxed(unlock, get_node_level(unlock_id))


## False for an unknown id.
func meets_prerequisites(unlock_id : String) -> bool:
	var unlock : MetaUnlockData = find_unlock(unlock_id)
	return unlock != null and MetaUnlockRules.meets_prerequisites(unlock, get_unlocked_levels())


## Public because OlutoppiWindow needs the same by-id lookup.
func find_unlock(unlock_id : String) -> MetaUnlockData:
	for candidate : MetaUnlockData in unlock_pool:
		if candidate.unlock_id == unlock_id:
			return candidate
	return null


## Every invested node's level scaled into a fresh RunPerk, ready to fold into a new
## Brewery's active_perks.
func get_active_perks() -> Array[RunPerk]:
	var active : Array[RunPerk] = []
	var levels : Dictionary = get_unlocked_levels()
	for unlock : MetaUnlockData in unlock_pool:
		var level : int = levels.get(unlock.unlock_id, 0)
		if level > 0:
			active.append(unlock.get_scaled_perk(level))
	return active


## Spends renown on a node's next level. False, with nothing spent, when it cannot be
## bought (see MetaUnlockRules.can_purchase()); callers should still check that first to
## keep a node's square disabled.
func purchase_next_level(unlock_id : String) -> bool:
	var unlock : MetaUnlockData = find_unlock(unlock_id)
	if unlock == null or not MetaUnlockRules.can_purchase(unlock, get_unlocked_levels(), get_renown()):
		return false

	var levels : Dictionary = get_unlocked_levels()
	levels[unlock_id] = get_node_level(unlock_id) + 1
	_config.set_value(SECTION, KEY_RENOWN, get_renown() - unlock.renown_cost_per_level)
	_config.set_value(SECTION, KEY_UNLOCKED_LEVELS, levels)
	_save()
	return true


## Wipes renown, purchased talents and discovered styles, in memory and on disk.
func reset_progress() -> void:
	_config.clear()
	_save()


func _on_style_discovered(style : int) -> void:
	if has_style(style):
		return
	var styles : Array = get_discovered_styles()
	styles.append(style)
	_config.set_value(SECTION, KEY_DISCOVERED_STYLES, styles)
	_save()


## A run pays out renown once, at its first genuine ending, never during the
## off-the-record continued-play epilogue (same guard as LeaderboardManager).
func _on_game_ended(_ending_type : String) -> void:
	var brewery : Brewery = BrewEngine.current_brewery
	if brewery == null or brewery.has_continued_past_survival:
		return
	add_renown(calculate_renown(brewery.current_day, brewery.reputation, brewery.lifetime_bottles_sold, brewery.run_modifier))


func _save() -> void:
	_config.save(_save_path)
