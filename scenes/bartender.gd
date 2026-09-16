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

## A group order's whole round stacks together right on the counter (see
## get_stack_position()) instead of each glass sliding out to its own,
## now far-back member — STACK_ROW_SIZE wraps the stack into a new row
## every 4 glasses so a big lauma's round grows into a compact pile
## instead of sprawling sideways across the whole bar top. Anchored left of
## serve_marker (camera-left, i.e. negative x) and growing further left
## from there, so the pile sits over open counter space to the bartender's
## own left instead of overlapping his sprite or the till further right.
const STACK_ROW_SIZE : int = 4
const STACK_BASE_OFFSET_PX : Vector2 = Vector2(-20, 0)
const STACK_COLUMN_OFFSET_PX : Vector2 = Vector2(-7, 0)
const STACK_ROW_OFFSET_PX : Vector2 = Vector2(0, -6)


func _ready() -> void:
	add_to_group(BARTENDER_GROUP)
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.play(ANIM_IDLE)


## Plays the one-shot serving animation, then returns to idle on its own.
## speed_scale lets a group order (CustomerSpawner._run_shared_group_order())
## visibly speed the pour up for its rapid-fire one-by-one serving burst
## without that lingering into the next solo customer's pour — reset back to
## 1.0 the moment this returns to idle, below.
func play_serve_beer(speed_scale: float = 1.0) -> void:
	animated_sprite.speed_scale = speed_scale
	animated_sprite.play(ANIM_SERVE_BEER)


func _on_animation_finished() -> void:
	if animated_sprite.animation == ANIM_SERVE_BEER:
		animated_sprite.speed_scale = 1.0
		animated_sprite.play(ANIM_IDLE)


## Global position for the Nth glass in a group order's on-counter stack —
## see CustomerSpawner._run_shared_group_order()'s serving burst.
func get_stack_position(index: int) -> Vector2:
	var column := index % STACK_ROW_SIZE
	@warning_ignore("integer_division")
	var row := index / STACK_ROW_SIZE
	return serve_marker.global_position + STACK_BASE_OFFSET_PX + STACK_COLUMN_OFFSET_PX * column + STACK_ROW_OFFSET_PX * row
