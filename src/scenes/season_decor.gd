class_name SeasonDecor
extends Node2D

## Decorations shown only in their season: the Halloween pumpkins, the Black Month sale signs
## (which stay up through Cyber Week, see SeasonRules.includes()).

@export var season : SeasonRules.Season = SeasonRules.Season.HALLOWEEN


func _ready() -> void:
	_show_for(SeasonRules.now())
	BrewerySignals.season_forced.connect(_show_for)


func _show_for(current : SeasonRules.Season) -> void:
	visible = SeasonRules.includes(current, season)
