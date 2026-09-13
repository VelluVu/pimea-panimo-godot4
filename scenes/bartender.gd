class_name Bartender
extends Node2D

## Static fixture standing behind the bar counter — unlike Customer, never
## walks or rotates (only a south-facing sprite exists), so this is just an
## idle/serve_beer animation player with a public method-down API. No
## signals of its own: nothing needs to react to the bartender, callers
## (see main.tscn) just tell it what to play.

const ANIM_IDLE : StringName = &"idle"
const ANIM_SERVE_BEER : StringName = &"serve_beer"

@onready var animated_sprite : AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.play(ANIM_IDLE)


## Plays the one-shot serving animation, then returns to idle on its own.
func play_serve_beer() -> void:
	animated_sprite.play(ANIM_SERVE_BEER)


func _on_animation_finished() -> void:
	if animated_sprite.animation == ANIM_SERVE_BEER:
		animated_sprite.play(ANIM_IDLE)
