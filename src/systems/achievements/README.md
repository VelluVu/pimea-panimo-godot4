# Achievements system

Lifetime stat counters and the achievements that watch them. Progress lives in one
`ConfigFile` that outlives every run; unlocks are permanent until `reset_progress()`.

## Interface (`AchievementTracker`)

| Call | What it does |
|---|---|
| `increment_stat(key, amount = 1)` | Counts up and saves |
| `set_stat_if_higher(key, value)` | Ratchet: writes only a new high, for stats that can drop (money, reputation) |
| `get_stat(key)`, `is_unlocked(id)`, `get_unlocked_ids()` | Reads |
| `reset_progress()` | Forgets every stat and unlock, in memory and on disk |
| `achievement_unlocked(id, title)` | Signal, once per achievement |
| `achievement_pool` | The `AchievementData` to check; fill it in the wiring |

Every write checks the pool: an `AchievementData` unlocks when the stat named by its
`stat_key` reaches `target_value` (or jumps past it). The file keeps the stats in `[stats]`
and the unlocked ids in `[unlocks]`.

## Use it in a new project

1. Copy this folder (keep the `.uid` files).
2. Edit **`achievement_wiring.gd`**: the save path, where the `AchievementData` files are
   loaded from, your `STAT_*` keys and the signals that feed them.
3. Make an `AchievementData` `.tres` per achievement.
4. Register an autoload whose script is `achievement_wiring.gd`, or a two-line script that
   extends `AchievementWiring` (this game's `src/autoload/achievement_manager.gd`).

## Files

`achievement_data.gd` one achievement, `achievement_tracker.gd` the interface,
`achievement_wiring.gd` the project's stats. Tests: `tests/test_achievement_tracker.gd` (the
rules), `tests/test_achievement_manager.gd` (this game's stats and files).
