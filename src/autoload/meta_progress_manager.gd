#MetaProgressManager (Autoload)
extends Node

## Persists progress that survives past a single run — styles ever
## discovered, "renown" currency earned per run, and which MetaUnlockData
## nodes have been bought with it — to its own ConfigFile, same
## load/mutate/save shape as LeaderboardManager (see that file's own
## docstring for why that's this project's established pattern for
## anything outliving SaveManager's single active-run save slot).
##
## Style discovery was the cheap first step of the larger meta-progression
## idea; renown + MetaUnlockData is the second step, the actual spendable
## "talent tree" — see Brewery._seed_meta_discovered_styles()/
## _seed_meta_perks() for how both feed into a brand new run.

const SAVE_PATH : String = "user://meta_progress.cfg"
const SECTION : String = "meta_progress"
const KEY_DISCOVERED_STYLES : String = "discovered_styles"
const KEY_RENOWN : String = "renown"
const KEY_UNLOCKED_LEVELS : String = "unlocked_levels"

const UNLOCK_FOLDER_PATH : String = "res://src/resources/meta_unlocks/"
const WARNING_UNLOCK_FOLDER_OPEN_FAILED : String = "MetaProgressManager: Failed to open path: "

## LeaderboardManager has no class_name (it's only ever addressed as the
## autoload singleton), so calling its static calculate_score() through
## the bare identifier resolves as an instance call and warns
## (STATIC_CALLED_ON_INSTANCE) — same avoidance-via-preload() this
## project's own test_leaderboard_manager.gd already uses.
const LeaderboardManagerScript := preload("res://src/autoload/leaderboard_manager.gd")

## Same difficulty-weighted score LeaderboardManager already records for
## the leaderboard (LeaderboardManager.calculate_score()), scaled down
## into a much smaller currency range — reusing it instead of a second
## from-scratch formula keeps "what makes a run score well" consistent
## between the leaderboard and renown. Floored so even a run that ends in
## a bust/bankruptcy still earns a little: the run's own outcome already
## punishes the player once (lost progress, a bad leaderboard entry), it
## shouldn't also zero out that run's entire contribution to permanent
## progress.
const RENOWN_SCORE_DIVISOR : float = 20.0
const RENOWN_FLOOR : int = 5

var _config : ConfigFile = ConfigFile.new()
## Overridable so tests can redirect persistence to a throwaway path
## instead of the real user://meta_progress.cfg — see
## test_meta_progress_manager.gd, which (unlike test_leaderboard_manager.gd's
## read-only tests over manually-seeded _config state) calls methods that
## actually write to disk (purchase_unlock(), add_renown()).
var _save_path : String = SAVE_PATH
var unlock_pool : Array[MetaUnlockData] = []


func _ready() -> void:
	_config.load(_save_path) # missing file just leaves _config empty, fine
	_load_unlock_pool()
	BrewerySignals.style_discovered.connect(_on_style_discovered)
	BrewerySignals.game_ended.connect(_on_game_ended)


func _load_unlock_pool() -> void:
	var dir := DirAccess.open(UNLOCK_FOLDER_PATH)
	if dir == null:
		push_warning(WARNING_UNLOCK_FOLDER_OPEN_FAILED + UNLOCK_FOLDER_PATH)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res := load(UNLOCK_FOLDER_PATH + file_name)
			if res is MetaUnlockData:
				unlock_pool.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()


func _on_style_discovered(style : int) -> void:
	if has_style(style):
		return

	var styles : Array = get_discovered_styles()
	styles.append(style)
	_config.set_value(SECTION, KEY_DISCOVERED_STYLES, styles)
	_config.save(_save_path)


func has_style(style : int) -> bool:
	return get_discovered_styles().has(style)


func get_discovered_styles() -> Array:
	return _config.get_value(SECTION, KEY_DISCOVERED_STYLES, [])


## Pure and static for the same direct-testability reasoning as
## LeaderboardManager.calculate_score() itself (which this wraps).
static func calculate_renown(days_survived : int, reputation : int, lifetime_bottles_sold : int, run_modifier : RunModifier = null) -> int:
	var score : int = LeaderboardManagerScript.calculate_score(days_survived, reputation, lifetime_bottles_sold, run_modifier)
	return maxi(RENOWN_FLOOR, roundi(score / RENOWN_SCORE_DIVISOR))


## Same has_continued_past_survival guard as LeaderboardManager.
## _on_game_ended() — a run only ever pays out renown once, at its first
## genuine ending, never again during the off-the-record continued-play
## epilogue. See that flag's own contract in brewery.gd.
func _on_game_ended(_ending_type : String) -> void:
	var brewery : Brewery = BrewEngine.current_brewery
	if brewery == null or brewery.has_continued_past_survival:
		return

	var renown : int = calculate_renown(brewery.current_day, brewery.reputation, brewery.lifetime_bottles_sold, brewery.run_modifier)
	add_renown(renown)


func add_renown(amount : int) -> void:
	if amount <= 0:
		return
	_config.set_value(SECTION, KEY_RENOWN, get_renown() + amount)
	_config.save(_save_path)


func get_renown() -> int:
	return _config.get_value(SECTION, KEY_RENOWN, 0)


func get_unlocked_levels() -> Dictionary:
	return _config.get_value(SECTION, KEY_UNLOCKED_LEVELS, {})


func get_node_level(unlock_id : String) -> int:
	return get_unlocked_levels().get(unlock_id, 0)


func is_maxed(unlock_id : String) -> bool:
	var unlock : MetaUnlockData = find_unlock(unlock_id)
	return unlock != null and get_node_level(unlock_id) >= unlock.max_level


## True when every one of unlock_id's prerequisite_ids has at least 1
## invested level — false for an unknown id (nothing to check against).
## A root node (empty prerequisite_ids) is trivially always true.
func meets_prerequisites(unlock_id : String) -> bool:
	var unlock : MetaUnlockData = find_unlock(unlock_id)
	if unlock == null:
		return false
	for prereq_id : String in unlock.prerequisite_ids:
		if get_node_level(prereq_id) <= 0:
			return false
	return true


## Public (not just an internal helper) since OlutoppiWindow needs the
## same by-id lookup to render a node's name/description/icon/cost —
## no reason to make it duplicate this linear scan over unlock_pool.
func find_unlock(unlock_id : String) -> MetaUnlockData:
	for candidate : MetaUnlockData in unlock_pool:
		if candidate.unlock_id == unlock_id:
			return candidate
	return null


## Every invested node's level, scaled into a fresh RunPerk (see
## MetaUnlockData.get_scaled_perk()) — ready to fold straight into a
## fresh Brewery's active_perks (see Brewery._seed_meta_perks()).
func get_active_perks() -> Array[RunPerk]:
	var active : Array[RunPerk] = []
	var levels : Dictionary = get_unlocked_levels()
	for unlock : MetaUnlockData in unlock_pool:
		var level : int = levels.get(unlock.unlock_id, 0)
		if level > 0:
			active.append(unlock.get_scaled_perk(level))
	return active


## Spends renown.cost_per_level on a node's NEXT level. False (no-op, no
## partial spend) on an unknown id, an already-maxed node, unmet
## prerequisites, or insufficient renown — callers (OlutoppiWindow) should
## check is_maxed()/meets_prerequisites()/get_renown() themselves
## beforehand to keep a node's square correctly disabled rather than
## relying on this return value alone.
func purchase_next_level(unlock_id : String) -> bool:
	var unlock : MetaUnlockData = find_unlock(unlock_id)
	if unlock == null or is_maxed(unlock_id) or not meets_prerequisites(unlock_id) or get_renown() < unlock.renown_cost_per_level:
		return false

	_config.set_value(SECTION, KEY_RENOWN, get_renown() - unlock.renown_cost_per_level)
	var levels : Dictionary = get_unlocked_levels()
	levels[unlock_id] = get_node_level(unlock_id) + 1
	_config.set_value(SECTION, KEY_UNLOCKED_LEVELS, levels)
	_config.save(_save_path)
	return true
