class_name AchievementData
extends Resource

## A single permanently-unlockable achievement, tracked by AchievementManager
## against one of its persisted lifetime stat counters — same
## folder-loaded-Resource pattern CustomerData/BarContact/MetaUnlockData
## already use (see CustomerRegistry/MetaProgressManager's own
## _load_resources()). AchievementManager increments stat_key's counter as
## gameplay signals fire, and unlocks this achievement the moment that
## counter reaches target_value.

## Stable persistence key for AchievementManager's ConfigFile — must be
## unique across every shipped AchievementData, same role unlock_id plays
## for MetaUnlockData.
@export var achievement_id : String = ""

@export var title : String = ""
@export_multiline var description : String = ""

## Which lifetime counter this achievement watches — see
## AchievementManager's STAT_* constants for the full set of keys gameplay
## signals actually feed.
@export var stat_key : StringName = &""

## This achievement unlocks the instant its stat_key counter reaches this
## value (>=, so a counter that jumps past it in one step still unlocks).
@export var target_value : int = 1
