# Goals system

A few concurrent goals rolled from a pool, one per slot, never two of the same kind at once.
Progress events advance matching slots. An "achieve" goal settles when it reaches its target,
an "avoid" goal fails the moment it passes its target, and `end_period()` settles the rest
(avoid goals succeed, unfinished achieve goals fail). Settling always rolls a replacement.

## Interface (`GoalBoard`)

| Call | What it does |
|---|---|
| `add_progress(kind, amount, detail = -1)` | Advances every slot whose goal `matches(kind, detail)` |
| `set_progress(slot, value)` | For progress derived from live state |
| `fail_kind_without_penalty(kind)` | Fails the first goal of a kind, telling the hooks not to penalise |
| `end_period()`, `fill_empty_slots()` | Settle everything; roll goals into empty slots |
| `active_goals`, `get_progress(slot)`, `get_effective_target(slot)`, `get_baseline(slot)` | Reads, index-aligned |
| `load_slot(...)`, `notify_changed()` | Restore slots, e.g. from a save |
| `goal_progress_changed`, `goal_resolved(goal, succeeded)` | Signals |

Hooks to override: `_can_roll_goals()`, `_current_day()`, `_baseline_for(goal)`,
`_before_replace(...)` (pay rewards that a new goal should snapshot) and `_after_replace(...)`
(anything that can feed progress back into the board).

`GoalData` is the base resource: name, target, progress text and day scaling. Extend it with
your own kinds and rewards and override `get_kind()`, `is_avoid()` and `matches()`.
`GoalRules` holds the pure decisions, `GoalSlot` one slot's state.

## Use it in a new project

1. Copy this folder (keep the `.uid` files).
2. Extend `GoalData` with your goal kinds and rewards, and make a `.tres` per goal.
3. Edit **`goal_wiring.gd`**: the slot count, where the pool is loaded from, the signals that
   feed progress and end the period, the reward hooks and where the slots are saved.
4. Register an autoload whose script is `goal_wiring.gd`, or a two-line script that extends
   `GoalWiring` (this game's `src/autoload/daily_goal_manager.gd`).

## Files

`goal_data.gd`, `goal_slot.gd`, `goal_rules.gd`, `goal_board.gd` the system, `goal_wiring.gd`
this game's daily goals. Tests: `tests/test_goal_rules.gd`, `tests/test_goal_slot.gd`,
`tests/test_goal_board.gd`; the game's goal maths in `tests/test_daily_goal_rules.gd`.
