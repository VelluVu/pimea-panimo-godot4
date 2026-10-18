class_name ImmersionActorData
extends Resource

## One critter or person in a vignette: its look and walk, nothing else.

@export var sprite_frames : SpriteFrames
## Played for the whole crossing. Art faces left; legs heading right are mirrored.
@export var animation : StringName = &"walk_left"
## Scale at the depth reference line (VignettePath); shrinks and grows with screen y.
@export var base_scale : Vector2 = Vector2(4, 4)
## Seconds before this actor appears. Equal crossing times keep the gap the whole way, a
## steady chase.
@export var start_delay_seconds : float = 0.0
## Time to walk the whole path, start to end.
@export var crossing_seconds : float = 6.0
## Flies above the room (a bat): no depth scaling, drawn over the counter and customers.
@export var flying : bool = false
## One of these plays at a random moment of the crossing (a meow, a squeak).
@export var sounds : Array[AudioStream] = []
## Chance that this actor makes its sound on a crossing, so it doesn't get old.
@export_range(0.0, 1.0) var sound_chance : float = 1.0
