class_name AchievementData
extends Resource

## One permanently unlockable achievement. AchievementTracker unlocks it the
## moment the lifetime stat named stat_key reaches target_value.

## Persistence key in the tracker's ConfigFile; must be unique across the pool.
@export var achievement_id : String = ""

@export var title : String = ""
@export_multiline var description : String = ""

## The lifetime stat this achievement watches. The project's wiring decides
## which events feed which stat.
@export var stat_key : StringName = &""

## Unlocks at >= this value, so a stat that jumps past it in one step still unlocks.
@export var target_value : int = 1
