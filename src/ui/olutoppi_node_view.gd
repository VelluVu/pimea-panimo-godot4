class_name OlutoppiNodeView
extends RefCounted

## The labels inside one Olutoppi node square.

var button : Button
var icon_label : Label
var level_bonus_label : Label


func _init(node_button : Button) -> void:
	button = node_button
	icon_label = node_button.get_node("VBox/IconLabel")
	level_bonus_label = node_button.get_node("VBox/LevelBonusLabel")
