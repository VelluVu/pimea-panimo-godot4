extends Node

## Progress that survives a single run, in its own ConfigFile like LeaderboardManager: the
## styles ever discovered, the renown currency earned per run, and which MetaUnlockData
## nodes were bought with it. See StyleDiscovery.seed_from_meta() and
## Brewery._seed_meta_perks() for how it feeds a new run. The tree's rules are in
## MetaUnlockRules.

## Renown went up or was spent, so open views can redraw.
signal renown_changed(renown : int)
signal talent_purchased(unlock_id : String)

const SAVE_PATH : String = "user://meta_progress.cfg"
const SECTION : String = "meta_progress"
const KEY_DISCOVERED_STYLES : String = "discovered_styles"
const KEY_RENOWN : String = "renown"
const KEY_UNLOCKED_LEVELS : String = "unlocked_levels"

const UNLOCK_FOLDER_PATH : String = "res://src/resources/meta_unlocks/"

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
	TimeManager.day_changed.connect(_on_day_changed)


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
		renown_changed.emit(get_renown())


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
	talent_purchased.emit(unlock_id)
	renown_changed.emit(get_renown())
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


## The run's score pays out in full once, at its first ending (same guard as
## LeaderboardManager); continued play only earns the nightly share below.
func _on_game_ended(ending_type : String) -> void:
	var brewery : Brewery = BrewEngine.current_brewery
	if brewery == null or brewery.has_continued_past_survival:
		return
	brewery.renown_bottles_counted = brewery.lifetime_bottles_sold
	add_renown(RunScore.renown(RunScore.entry_for(brewery, ending_type)["score"]))


func _on_day_changed(_day : int) -> void:
	var brewery : Brewery = BrewEngine.current_brewery
	if brewery == null or not brewery.has_continued_past_survival or brewery.game_has_ended:
		return
	var bottles : int = brewery.lifetime_bottles_sold - brewery.renown_bottles_counted
	brewery.renown_bottles_counted = brewery.lifetime_bottles_sold
	add_renown(RunScore.continued_day_renown(bottles, brewery.run_modifier))


func _save() -> void:
	_config.save(_save_path)
