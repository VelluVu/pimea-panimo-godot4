class_name HalloweenDecor
extends Node2D

## The pumpkins and their glow, shown only in the Halloween season.


func _ready() -> void:
	visible = HalloweenRules.is_season(Time.get_date_dict_from_system())
