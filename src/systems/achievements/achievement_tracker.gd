class_name AchievementTracker
extends Node

## Lifetime stats and the achievements watching them, in one ConfigFile that outlives
## every run. A stat counts up (increment_stat()) or ratchets (set_stat_if_higher()), and
## every write unlocks what reached its target. The wiring subclass feeds the stats.

signal achievement_unlocked(achievement_id : String, title : String)

const SECTION_STATS : String = "stats"
const SECTION_UNLOCKS : String = "unlocks"
const KEY_UNLOCKED_IDS : String = "unlocked_ids"

## Tests point this at a throwaway file before writing.
var save_path : String = "user://achievements.cfg"
var achievement_pool : Array[AchievementData] = []

var _config : ConfigFile = ConfigFile.new()


func _ready() -> void:
	_config.load(save_path) # a missing file just leaves the config empty


func get_stat(stat_key : StringName) -> int:
	return _config.get_value(SECTION_STATS, stat_key, 0)


func get_unlocked_ids() -> Array:
	return _config.get_value(SECTION_UNLOCKS, KEY_UNLOCKED_IDS, [])


func is_unlocked(achievement_id : String) -> bool:
	return get_unlocked_ids().has(achievement_id)


## The pool's achievement with this id, or null.
func get_achievement(achievement_id : String) -> AchievementData:
	for achievement : AchievementData in achievement_pool:
		if achievement.achievement_id == achievement_id:
			return achievement
	return null


func increment_stat(stat_key : StringName, amount : int = 1) -> void:
	var current : int = get_stat(stat_key) + amount
	_config.set_value(SECTION_STATS, stat_key, current)
	_config.save(save_path)
	_check_unlocks(stat_key, current)


## For a stat recomputed from live state that can drop again (money,
## reputation): only a new high is written, so its achievements stay unlocked.
func set_stat_if_higher(stat_key : StringName, value : int) -> void:
	if value <= get_stat(stat_key):
		return
	_config.set_value(SECTION_STATS, stat_key, value)
	_config.save(save_path)
	_check_unlocks(stat_key, value)


## Forgets every stat and unlocked achievement, in memory and on disk.
func reset_progress() -> void:
	_config.clear()
	_config.save(save_path)


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
	_config.save(save_path)
	achievement_unlocked.emit(achievement.achievement_id, achievement.title)
