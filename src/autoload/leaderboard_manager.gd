#LeaderboardManager (Autoload)
extends Node

## Past-run results in their own ConfigFile, one entry per run, scored by RunScore.

const SAVE_PATH : String = "user://leaderboard.cfg"
const SECTION : String = "leaderboard"
const KEY_ENTRIES : String = "entries"
const MAX_ENTRIES : int = 20

## Entries scored with an older formula are moved out of the list, not mixed into it,
## unless they keep every part of their score (RESCORABLE_VERSION and later): those are
## scored again with RunScore.rescore(). Entries from before the brewery's worth was
## stored rescore without it.
const SCORE_VERSION : int = 4
const RESCORABLE_VERSION : int = 2
const KEY_ARCHIVED_ENTRIES : String = "archived_entries"

var _config : ConfigFile = ConfigFile.new()
## The entry recorded in this session's latest run, so the list can tag it as new.
var last_entry : Dictionary = {}


func _ready() -> void:
	_config.load(SAVE_PATH) # missing file just leaves _config empty, fine
	_archive_old_entries()
	BrewerySignals.game_ended.connect(_on_game_ended)


## Records the first ending only: endings after the player chose to continue past the
## season are off the record (Brewery.has_continued_past_survival).
func _on_game_ended(ending_type : String) -> void:
	var brewery := BrewEngine.current_brewery
	if brewery == null or brewery.has_continued_past_survival:
		return
	last_entry = RunScore.entry_for(brewery, ending_type)
	last_entry["score_version"] = SCORE_VERSION
	last_entry["date"] = Time.get_datetime_string_from_system()
	_insert_entry(last_entry)


func _archive_old_entries() -> void:
	var current : Array = []
	var archived : Array = _config.get_value(SECTION, KEY_ARCHIVED_ENTRIES, [])
	var changed : bool = false
	for entry : Dictionary in get_entries():
		var version : int = entry.get("score_version", 1)
		if version == SCORE_VERSION:
			current.append(entry)
		elif version >= RESCORABLE_VERSION:
			entry["score"] = RunScore.rescore(entry)
			entry["score_version"] = SCORE_VERSION
			current.append(entry)
			changed = true
		else:
			archived.append(entry)
			changed = true
	if not changed:
		return
	current.sort_custom(func(a, b): return a["score"] > b["score"])
	_config.set_value(SECTION, KEY_ENTRIES, current)
	_config.set_value(SECTION, KEY_ARCHIVED_ENTRIES, archived)
	_config.save(SAVE_PATH)


func _insert_entry(entry : Dictionary) -> void:
	var entries : Array = get_entries()
	entries.append(entry)
	entries.sort_custom(func(a, b): return a["score"] > b["score"])
	if entries.size() > MAX_ENTRIES:
		entries.resize(MAX_ENTRIES)

	_config.set_value(SECTION, KEY_ENTRIES, entries)
	_config.save(SAVE_PATH)


func get_entries() -> Array:
	return _config.get_value(SECTION, KEY_ENTRIES, [])


## 1-based position `score` would land at among the currently saved
## entries (not counting itself) — used right after a run is recorded to
## show "Sijoitus: #N" / "UUSI ENNÄTYS!" on the end screen.
func get_rank(score : int) -> int:
	var entries : Array = get_entries()
	var rank : int = 1
	for entry : Dictionary in entries:
		if entry["score"] > score:
			rank += 1
	return rank
