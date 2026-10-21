class_name Keg
extends Node2D

## A keg behind the counter. A soured batch tints it green and bubbles out of the bung,
## the more the worse it soured, so a dirty keg shows before the customers say so.

## Indexed by FermentationRules.SourLevel: NONE, LIGHT, CLEAR, STRONG.
const SOUR_TINTS : Array[Color] = [Color(1.0, 1.0, 1.0), Color(0.94, 1.0, 0.9), Color(0.86, 1.0, 0.78), Color(0.78, 0.98, 0.68)]
const SOUR_BUBBLES : Array[int] = [0, 2, 4, 7]

@onready var sprite : Sprite2D = $Sprite2D
@onready var bubbles : CPUParticles2D = $Bubbles


func show_sour(level : FermentationRules.SourLevel) -> void:
	sprite.self_modulate = SOUR_TINTS[level]
	var count : int = SOUR_BUBBLES[level]
	if count > 0 and bubbles.amount != count:
		bubbles.amount = count
	bubbles.emitting = count > 0
