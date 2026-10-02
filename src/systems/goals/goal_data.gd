class_name GoalData
extends Resource

## One goal a GoalBoard can roll into a slot. An "achieve" goal succeeds when its
## progress reaches the target and fails if the period ends first; an "avoid" goal
## fails the moment progress passes the target and succeeds if it never does.
## A project extends this with its own kinds and rewards, overriding get_kind(),
## is_avoid() and matches().

@export var goal_name : String = ""
@export var target_amount : int = 1
## Always takes (progress, target) as %d %d, so every goal reads the same way.
@export var progress_format : String = "%d/%d"

@export_group("Päiväskaalaus")
## Grows target_amount per day after day 1, so a quantity goal stays meaningful
## late in a run. Leave it off for one-shot goals and avoid goals, where a
## rising target would make the goal easier, not harder.
@export var scales_with_day : bool = false
@export var target_scale_per_day : float = 0.08


## Which kind of goal this is. A board never shows two goals of one kind at once.
func get_kind() -> int:
	return 0


func is_avoid() -> bool:
	return false


## Whether a progress event of `kind` with `detail` (say, which item) counts for this goal.
func matches(kind : int, _detail : int) -> bool:
	return kind == get_kind()


func scale_multiplier(day : int) -> float:
	if not scales_with_day:
		return 1.0
	return 1.0 + target_scale_per_day * float(maxi(0, day - 1))


## An avoid goal keeps its own target: 0 is a real limit ("no misses at all"), and
## raising it to 1 let the goal read as failed at 1/1 without ever settling.
func get_effective_target(day : int) -> int:
	if is_avoid():
		return target_amount
	return maxi(1, roundi(target_amount * scale_multiplier(day)))


## target defaults to the unscaled target_amount, for a preview outside a run.
func get_progress_text(progress : int, target : int = -1) -> String:
	var effective_target := target_amount if target < 0 else target
	return progress_format % [progress, effective_target]
