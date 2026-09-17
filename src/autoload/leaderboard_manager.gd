#LeaderboardManager (Autoload)
extends Node

## Persists past-run results to a single ConfigFile, mirroring
## SettingsManager's load/mutate/save shape (the only persistence pattern
## in this project besides SaveManager's single-Brewery save slot — see
## that file for the precedent). One entry is recorded per genuine ending
## (see _on_game_ended's has_continued_past_survival guard, honoring the
## contract documented on that flag in brewery.gd).

const SAVE_PATH : String = "user://leaderboard.cfg"
const SECTION : String = "leaderboard"
const KEY_ENTRIES : String = "entries"
const MAX_ENTRIES : int = 20

var _config : ConfigFile = ConfigFile.new()


func _ready() -> void:
	_config.load(SAVE_PATH) # missing file just leaves _config empty, fine
	BrewerySignals.game_ended.connect(_on_game_ended)


## Skips recording while has_continued_past_survival is true — that flag
## is false at the moment "survived" first fires (it's only set true
## afterward, by GameEndWindow's continue button), so the win itself is
## always recorded; only a later ending fired during the off-the-record
## continued epilogue is excluded, exactly matching that flag's own
## documented contract in brewery.gd.
func _on_game_ended(ending_type : String) -> void:
	var brewery := BrewEngine.current_brewery
	if brewery == null or brewery.has_continued_past_survival:
		return

	var entry : Dictionary = {
		"ending_type": ending_type,
		"days_survived": brewery.current_day,
		"reputation": brewery.reputation,
		"lifetime_bottles_sold": brewery.lifetime_bottles_sold,
		"modifier_name": brewery.run_modifier.modifier_name if brewery.run_modifier != null else "",
		"date": Time.get_datetime_string_from_system(),
		"score": calculate_score(brewery.current_day, brewery.reputation, brewery.lifetime_bottles_sold, brewery.run_modifier),
	}
	_insert_entry(entry)


## Modifiers whose stats trend harder than baseline (see
## RunModifier.get_difficulty_score()) earn a proportionally higher score
## for the same raw run stats, so picking a harder modifier and surviving
## just as long as an easy run is rewarded instead of scored identically.
## Kept modest so difficulty nudges the score rather than dominating it —
## raw survival/reputation/sales still matter most. Floored at 1.0 so an
## easier-than-baseline modifier never scores below the unweighted stats.
const DIFFICULTY_SCORE_WEIGHT : float = 0.5

## Pure and static specifically so it's directly unit-testable, following
## this project's "pure-logic-only" test convention (see
## tests/test_leaderboard_manager.gd, tests/test_brew_resolver.gd).
## run_modifier defaults to null (no difficulty weighting applied) so
## existing callers/scores from before this field existed still compute
## the same base value.
static func calculate_score(days_survived : int, reputation : int, lifetime_bottles_sold : int, run_modifier : RunModifier = null) -> int:
	var base_score : int = days_survived * 100 + reputation * 10 + lifetime_bottles_sold
	var difficulty : float = run_modifier.get_difficulty_score() if run_modifier != null else 0.0
	var multiplier : float = maxf(1.0, 1.0 + difficulty * DIFFICULTY_SCORE_WEIGHT)
	return roundi(base_score * multiplier)


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


## Instance-method wrapper so callers (GameEndWindow) can get a rank
## straight from run stats without calling the static calculate_score()
## through this autoload's instance, which GDScript warns on — same
## reasoning as get_random_modifier() above.
func get_rank_for_stats(days_survived : int, reputation : int, lifetime_bottles_sold : int, run_modifier : RunModifier = null) -> int:
	return get_rank(calculate_score(days_survived, reputation, lifetime_bottles_sold, run_modifier))
