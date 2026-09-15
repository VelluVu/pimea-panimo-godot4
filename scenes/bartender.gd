class_name Bartender
extends Node2D

## Static fixture standing behind the bar counter — unlike Customer, never
## walks or rotates (only a south-facing sprite exists), so this is just an
## idle/serve_beer animation player with a public method-down API. No
## signals of its own: nothing needs to react to the bartender, callers
## (see main.tscn) just tell it what to play.

const ANIM_IDLE : StringName = &"idle"
const ANIM_SERVE_BEER : StringName = &"serve_beer"

## Only one Bartender ever exists, so a group is a simpler way for Customer
## to find "where the bartender is" (for the counter-glass slide-in) than
## threading a direct reference through main.gd/CustomerManager — nothing
## upstream of Bartender needs to know Customer looks it up this way.
const BARTENDER_GROUP : StringName = &"bartender"

@onready var animated_sprite : AnimatedSprite2D = $AnimatedSprite2D
## Hand-off point for the counter-glass slide-in (see Customer.
## show_counter_glass()) — roughly where the bartender's hands are, not
## his Node2D origin, so the glass starts sliding from a believable spot
## instead of his general body position. Separate Marker2D rather than
## just tuning the origin so it stays adjustable without touching
## AnimatedSprite2D's own transform.
@onready var serve_marker : Marker2D = $ServeMarker


func _ready() -> void:
	add_to_group(BARTENDER_GROUP)
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.play(ANIM_IDLE)


## Plays the one-shot serving animation, then returns to idle on its own.
func play_serve_beer() -> void:
	animated_sprite.play(ANIM_SERVE_BEER)


func _on_animation_finished() -> void:
	if animated_sprite.animation == ANIM_SERVE_BEER:
		animated_sprite.play(ANIM_IDLE)
